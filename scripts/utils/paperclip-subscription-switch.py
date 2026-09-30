#!/usr/bin/env python3
"""Preview or temporarily move unbound Claude roles to the Codex subscription.

Preserves agent IDs and journals original configurations before every PATCH.
This intentionally excludes managed bindings, paused roles and paid API keys.
"""
import argparse
import copy
from datetime import datetime, timezone
import fcntl
import http.cookiejar
import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request

BASE = "http://127.0.0.1:3100"
STATE_DIR = Path.home() / ".config/homelab/paperclip-subscription-switch"
STATE_FILE = STATE_DIR / "state.json"
AUTH_KEYS = {"OPENAI_API_KEY", "ANTHROPIC_API_KEY", "CLAUDE_CODE_OAUTH_TOKEN"}
CONFIG_FIELDS = ("adapterType", "adapterConfig", "runtimeConfig")


def config(agent):
    return {key: copy.deepcopy(agent.get(key) or ({} if key != "adapterType" else ""))
            for key in CONFIG_FIELDS}


def identity(agent):
    return {key: agent.get(key) for key in
            ("id", "companyId", "name", "role", "reportsTo", "defaultEnvironmentId")}


def has_auth_env(agent):
    return bool(AUTH_KEYS.intersection((agent.get("adapterConfig") or {}).get("env") or {}))


def save(state):
    descriptor, temporary = tempfile.mkstemp(dir=STATE_DIR, prefix="state-", suffix=".tmp")
    try:
        with os.fdopen(descriptor, "w") as output:
            json.dump(state, output, indent=2)
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, STATE_FILE)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def read_credentials():
    values = {}
    for line in (Path.home() / ".config/homelab/paperclip-admin.env").read_text().splitlines():
        if "=" in line and not line.lstrip().startswith("#"):
            key, value = line.split("=", 1)
            values[key.strip()] = value.strip().strip("\"'")
    return values


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--switch", action="store_true", help="preview Claude to Codex")
    mode.add_argument("--restore", action="store_true", help="preview exact original configs")
    mode.add_argument("--probe", action="store_true", help="one tiny Codex login probe")
    mode.add_argument("--status", action="store_true", help="show saved migration status")
    mode.add_argument("--restore-due", action="store_true", help="cron: restore after the saved reset time")
    mode.add_argument("--install-recovery", action="store_true", help="preview a staged recovery script and cron entry")
    mode.add_argument("--repair-notifications", action="store_true", help="preview missing Coach/Dietitian webhook bindings")
    parser.add_argument("--apply", action="store_true", help="apply switch/restore after a login probe")
    parser.add_argument("--restore-after", help="ISO timestamp with timezone; do not restore earlier")
    args = parser.parse_args()
    if args.apply and not (args.switch or args.restore or args.restore_due or args.install_recovery or args.repair_notifications):
        parser.error("--apply requires a switch, restore, recovery installation or notification repair")
    if args.restore_after and not (args.switch and args.apply):
        parser.error("--restore-after requires --switch --apply")
    reset_time = None
    if args.restore_after:
        reset = datetime.fromisoformat(args.restore_after)
        if reset.tzinfo is None:
            parser.error("--restore-after must include a timezone")
        reset_time = reset.timestamp()
    STATE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.chmod(STATE_DIR, 0o700)
    with open(STATE_DIR / "operation.lock", "a") as lock:
        os.chmod(STATE_DIR / "operation.lock", 0o600)
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise SystemExit("Another subscription switch is running; no changes.")
        try:
            state = json.loads(STATE_FILE.read_text())
        except FileNotFoundError:
            state = {"version": 1, "agents": {}}
        except (OSError, ValueError):
            raise SystemExit("Saved state is unreadable; preserve it before retrying.")
        if not isinstance(state, dict) or state.get("version") != 1 or not isinstance(state.get("agents"), dict):
            raise SystemExit("Unexpected saved state; refusing to overwrite it.")
        if args.status:
            print(json.dumps({"saved_agents": [{"name": r["identity"]["name"],
                "phase": r["phase"], "original_adapter": r["original"]["adapterType"],
                "original_model": r["original"]["adapterConfig"].get("model")}
                for r in state["agents"].values()], "restore_after": state.get("restore_after")}, indent=2))
            return
        if args.install_recovery:
            if not state["agents"] or not state.get("restore_after"):
                raise SystemExit("No scheduled takeover to recover; no installation needed.")
            staged = STATE_DIR / "restore.py"
            python = Path("/opt/homebrew/bin/python3")
            if not python.is_file():
                raise SystemExit("Expected Homebrew Python is missing; no crontab changes.")
            line = f"*/5 * * * * {shlex.quote(str(python))} {shlex.quote(str(staged))} --restore-due --apply >> {shlex.quote(str(Path.home() / 'logs/paperclip-subscription-switch.log'))} 2>&1"
            marker = "# Paperclip temporary subscription recovery (staged; survives Git branch changes)"
            current = subprocess.run(["crontab", "-l"], capture_output=True, text=True)
            if current.returncode != 0:
                raise SystemExit("Cannot read the existing crontab; no installation attempted.")
            if marker in current.stdout and marker + "\n" + line not in current.stdout:
                raise SystemExit("Recovery cron entry changed; preserve it and inspect before retrying.")
            print("Stage recovery helper and check every five minutes after the saved reset time.")
            if not args.apply:
                print("Preview only. Use --install-recovery --apply to install.")
                return
            descriptor, backup = tempfile.mkstemp(dir=STATE_DIR, prefix="crontab-", suffix=".bak")
            with os.fdopen(descriptor, "w") as output:
                output.write(current.stdout)
            if staged.exists():
                descriptor, backup = tempfile.mkstemp(dir=STATE_DIR, prefix="restore-", suffix=".bak")
                with os.fdopen(descriptor, "wb") as output:
                    output.write(staged.read_bytes())
                    output.flush()
                    os.fsync(output.fileno())
            temporary = STATE_DIR / "restore.py.tmp"
            descriptor = os.open(temporary, os.O_CREAT | os.O_WRONLY | os.O_TRUNC, 0o600)
            with os.fdopen(descriptor, "wb") as output:
                output.write(Path(__file__).resolve().read_bytes())
                output.flush()
                os.fsync(output.fileno())
            os.replace(temporary, staged)
            updated = current.stdout if marker in current.stdout else current.stdout.rstrip() + "\n\n" + marker + "\n" + line + "\n"
            again = subprocess.run(["crontab", "-l"], capture_output=True, text=True, check=True)
            if again.stdout != current.stdout:
                raise SystemExit("Crontab changed during preparation; no installation attempted.")
            subprocess.run(["crontab", "-"], input=updated, text=True, check=True)
            installed = subprocess.run(["crontab", "-l"], capture_output=True, text=True, check=True)
            if installed.stdout != updated:
                raise SystemExit("Crontab installation did not verify; preserve its private backup.")
            print("Installed and verified; existing cron jobs preserved. No agent wakes.")
            return
        if args.restore_due:
            if not state["agents"] or not state.get("restore_after") or time.time() < max(state["restore_after"], state.get("next_probe_at", 0)):
                return
            args.restore = True
            # A quota/auth failure is retried hourly, not every five minutes.
            if args.apply:
                state["next_probe_at"] = time.time() + 3600
                save(state)
        if reset_time is not None:
            state["restore_after"] = reset_time
            save(state)

        opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))

        def api(method, path, body=None):
            request = urllib.request.Request(BASE + path, method=method,
                headers={"Origin": BASE, "Content-Type": "application/json"},
                data=json.dumps(body).encode() if body is not None else None)
            try:
                with opener.open(request, timeout=120) as response:
                    return json.load(response)
            except urllib.error.HTTPError as error:
                raise RuntimeError(f"Paperclip {method} returned HTTP {error.code}") from None
            except urllib.error.URLError:
                raise RuntimeError("Paperclip request did not complete; saved intent is retained.") from None

        def probe(company, adapter, adapter_config):
            # Reject paid-key routes. The host has no OPENAI_API_KEY; Claude's
            # stored OAuth token is a subscription, not an Anthropic API key.
            if has_auth_env({"adapterConfig": adapter_config}):
                raise RuntimeError("Explicit credential environment is excluded from this helper")
            host_check = subprocess.run(["docker", "exec", "paperclip", "node", "-e",
                'process.stdout.write(JSON.stringify(Boolean(process.env.OPENAI_API_KEY || process.env.ANTHROPIC_API_KEY)))'],
                capture_output=True, text=True, check=True)
            if host_check.stdout.strip() != "false":
                raise RuntimeError("A host API key is configured; refusing a subscription-only probe")
            # ACP's environment test only checks credential presence. The CLI
            # engine performs a tiny real hello request and can detect quota.
            probe_config = {**adapter_config, "engine": "cli"}
            if adapter == "codex_local":
                extra = list(probe_config.get("extraArgs") or probe_config.get("args") or [])
                if "--skip-git-repo-check" not in extra:
                    extra.append("--skip-git-repo-check")
                probe_config["extraArgs"] = extra
            result = api("POST", f"/api/companies/{company}/adapters/{adapter}/test-environment",
                         {"adapterConfig": probe_config})
            checks = result.get("checks") or []
            print("Login probe:", adapter, result.get("status"),
                  ", ".join(check.get("code", "unknown") for check in checks))
            passed_code = adapter.removesuffix("_local") + "_hello_probe_passed"
            if result.get("status") != "pass" or not any(
                check.get("code") == passed_code for check in checks
            ):
                raise RuntimeError("Subscription probe did not pass; agent configurations were not changed.")

        def has_live_run(company, aid):
            # A company-wide recent-history limit can hide this agent's
            # queued run behind other agents' newer completed runs. This
            # pinned API supports an unbounded per-agent summary query.
            query = urllib.parse.urlencode({"agentId": aid, "summary": "true"})
            runs = api("GET", f"/api/companies/{company}/heartbeat-runs?{query}")
            if not isinstance(runs, list) or any(
                not isinstance(run, dict) or run.get("agentId") != aid
                or not isinstance(run.get("status"), str) for run in runs
            ):
                raise RuntimeError("Target run status is unreadable; no PATCH was sent.")
            return any(run["status"] in ("running", "queued") for run in runs)

        credentials = read_credentials()
        api("POST", "/api/auth/sign-in/email", {"email": "dziugas@peciulevicius.com",
            "password": credentials.pop("PAPERCLIP_ADMIN_PASSWORD")})
        try:
            companies = api("GET", "/api/companies")
            agents = {}
            for company in companies:
                for agent in api("GET", f"/api/companies/{company['id']}/agents"):
                    agents[agent["id"]] = agent
            if args.repair_notifications:
                coach_companies = [company for company in companies if company["name"] == "Coach"]
                if len(coach_companies) != 1:
                    raise RuntimeError("Coach company is missing or ambiguous; no repairs.")
                cid = coach_companies[0]["id"]
                secrets = api("GET", f"/api/companies/{cid}/secrets/catalog")
                backed_up = False
                failures = []
                for name, key in (("Coach", "COACH_DISCORD_WEBHOOK"),
                                  ("Dietitian", "DIETITIAN_DISCORD_WEBHOOK")):
                    matches = [agent for agent in agents.values() if agent["companyId"] == cid
                               and agent["name"] == name and agent["status"] not in
                               ("paused", "terminated", "pending_approval")]
                    secret_matches = [secret for secret in secrets if secret.get("status") == "active"
                        and any(str(secret.get(field) or "").replace("-", "_").upper() == key
                                for field in ("name", "key"))]
                    if len(matches) != 1 or len(secret_matches) != 1:
                        failures.append(name)
                        print("Skip missing/ambiguous role or secret:", name)
                        continue
                    agent = matches[0]
                    aid = agent["id"]
                    record = state["agents"].get(aid)
                    if not record or identity(agent) != record["identity"] or agent["adapterType"] != "codex_local":
                        failures.append(name)
                        print("Skip role outside the saved takeover:", name)
                        continue
                    reference = {"type": "secret_ref", "secretId": secret_matches[0]["id"], "version": "latest"}
                    pending = record.get("notification_repair_pending")
                    current = config(agent)
                    if pending:
                        if pending["key"] != key or pending["reference"] != reference:
                            raise RuntimeError("Pending notification repair changed; preserve its journal.")
                        target = pending["target"]
                        before = pending["before"]
                    else:
                        if current != record["expected"]:
                            failures.append(name)
                            print("Skip changed notification configuration:", name)
                            continue
                        target = copy.deepcopy(current)
                        env = target["adapterConfig"].setdefault("env", {})
                        original_env = record["original"]["adapterConfig"].get("env") or {}
                        if env.get(key) not in (None, reference) or original_env.get(key) not in (None, reference):
                            failures.append(name)
                            print("Skip an existing different notification binding:", name)
                            continue
                        env[key] = reference
                        before = current
                    if current not in (before, target):
                        failures.append(name)
                        print("Skip changed pending notification configuration:", name)
                        continue
                    if not pending and current == target and original_env.get(key) == reference:
                        print("Already bound:", name)
                        continue
                    print("Bind existing webhook secret:", name)
                    if not args.apply:
                        continue
                    if agent["status"] == "running" or has_live_run(cid, aid):
                        failures.append(name)
                        print("Skip active notification role:", name)
                        continue
                    fresh = api("GET", f"/api/agents/{aid}")
                    if config(fresh) != current or identity(fresh) != identity(agent) or fresh["status"] != agent["status"]:
                        failures.append(name)
                        print("Skip notification role changed during preview:", name)
                        continue
                    if has_live_run(cid, aid):
                        failures.append(name)
                        print("Skip notification role queued during preview:", name)
                        continue
                    if not backed_up:
                        descriptor, backup = tempfile.mkstemp(dir=STATE_DIR, prefix="notification-journal-", suffix=".bak")
                        with os.fdopen(descriptor, "wb") as output:
                            output.write(STATE_FILE.read_bytes())
                            output.flush()
                            os.fsync(output.fileno())
                        backed_up = True
                    if not pending:
                        record["notification_repair_pending"] = {
                            "key": key, "reference": reference, "before": before, "target": target}
                        save(state)
                    actual = current
                    if current != target:
                        updated = api("PATCH", f"/api/agents/{aid}", {**target, "replaceAdapterConfig": True})
                        if identity(updated) != identity(agent) or updated["status"] != agent["status"]:
                            raise RuntimeError("Notification role identity/status changed; preserve the journal.")
                        actual = config(updated)
                    if actual != target:
                        raise RuntimeError("Notification PATCH differs from intent; preserve the journal.")
                    record["original"]["adapterConfig"].setdefault("env", {})[key] = reference
                    record["target"] = target
                    record["expected"] = actual
                    del record["notification_repair_pending"]
                    save(state)
                    print("Verified webhook binding and saved Claude configuration:", name)
                if failures:
                    raise RuntimeError(f"{len(failures)} notification roles deferred; saved configs preserved.")
                if not args.apply:
                    print("Preview only. No agent writes or model probes.")
                return
            if args.probe:
                probe(companies[0]["id"], "codex_local",
                      {"dangerouslyBypassApprovalsAndSandbox": False})
                return
            failures = []
            probed = set()
            failed_probes = set()
            if args.restore:
                for aid, record in state["agents"].items():
                    if aid not in agents:
                        failures.append(record["identity"]["name"])
                        print("Skip unavailable saved agent:", record["identity"]["name"])
            for agent in agents.values():
                aid = agent["id"]
                record = state["agents"].get(aid)
                if record and record.get("notification_repair_pending"):
                    failures.append(agent["name"])
                    print("Skip unconfirmed notification repair:", agent["name"])
                    continue
                if record and identity(agent) != record["identity"]:
                    failures.append(agent["name"])
                    print("Skip changed saved identity:", agent["name"])
                    continue
                if args.restore:
                    if not record:
                        continue
                    current = config(agent)
                    if current == record["original"]:
                        if args.apply:
                            del state["agents"][aid]
                            save(state)
                        print("Already original:", agent["name"])
                        continue
                    if current != record.get("expected", record["target"]):
                        failures.append(agent["name"])
                        print("Skip changed configuration:", agent["name"])
                        continue
                    target = record["original"]
                else:
                    if record:
                        if config(agent) == record.get("expected", record["target"]):
                            print("Already switched:", agent["name"])
                            continue
                        if config(agent) != record["original"]:
                            failures.append(agent["name"])
                            print("Skip changed pending configuration:", agent["name"])
                            continue
                    if agent["adapterType"] != "claude_local" or agent["status"] in ("paused", "terminated", "pending_approval"):
                        continue
                    if any(word in agent["name"].lower() for word in ("retired", "duplicate hire")):
                        continue
                    if (agent.get("runtimeConfig") or {}).get("aiConnection") or has_auth_env(agent):
                        print("Skip managed/explicit credentials:", agent["name"])
                        continue
                    target = config(agent)
                    target["adapterType"] = "codex_local"
                    target["adapterConfig"].pop("model", None)
                    target["adapterConfig"]["engine"] = "cli"
                    extra = list(target["adapterConfig"].get("extraArgs") or target["adapterConfig"].get("args") or [])
                    if "--skip-git-repo-check" not in extra:
                        extra.append("--skip-git-repo-check")
                    target["adapterConfig"]["extraArgs"] = extra
                    # Keep the workspace sandbox and network access; do not
                    # inherit Codex's new-agent bypass default.
                    target["adapterConfig"]["dangerouslyBypassApprovalsAndSandbox"] = False
                if agent["status"] in ("paused", "terminated", "pending_approval", "running"):
                    print("Skip paused/retired role:", agent["name"])
                    failures.append(agent["name"])
                    continue
                if agent.get("defaultEnvironmentId"):
                    # These probes use the local host subscription. A selected
                    # execution environment can have separate credentials,
                    # including a paid API key, and must not borrow that proof.
                    print("Skip selected execution environment:", agent["name"])
                    failures.append(agent["name"])
                    continue
                print("Restore:" if args.restore else "Switch:", agent["name"], "→", target["adapterType"], target["adapterConfig"].get("model", "adapter default"))
                if not args.apply:
                    continue
                cid = agent["companyId"]
                if has_live_run(cid, aid):
                    failures.append(agent["name"])
                    print("Skip active or queued run:", agent["name"])
                    continue
                probe_key = (cid, target["adapterType"],
                             json.dumps(target["adapterConfig"], sort_keys=True))
                if probe_key in failed_probes:
                    failures.append(agent["name"])
                    print("Skip failed subscription probe:", agent["name"])
                    continue
                if probe_key not in probed:
                    try:
                        probe(cid, target["adapterType"], target["adapterConfig"])
                    except RuntimeError:
                        failed_probes.add(probe_key)
                        failures.append(agent["name"])
                        print("Skip unavailable subscription:", agent["name"])
                        continue
                    probed.add(probe_key)
                fresh = api("GET", f"/api/agents/{aid}")
                if config(fresh) != config(agent) or identity(fresh) != identity(agent) or fresh["status"] != agent["status"]:
                    failures.append(agent["name"])
                    print("Skip agent changed during preview:", agent["name"])
                    continue
                if has_live_run(cid, aid):
                    failures.append(agent["name"])
                    print("Skip run queued during probe:", agent["name"])
                    continue
                if not record:
                    record = {"identity": identity(agent), "original": config(agent),
                              "target": target, "created_at": datetime.now(timezone.utc).isoformat()}
                    state["agents"][aid] = record
                record["phase"] = "restore_pending" if args.restore else "switch_pending"
                save(state)
                updated = api("PATCH", f"/api/agents/{aid}", {**target, "replaceAdapterConfig": True})
                actual = config(updated)
                if identity(updated) != identity(agent) or updated["status"] != agent["status"]:
                    raise RuntimeError("Unexpected identity/status change; intent retained for recovery.")
                if (actual["adapterType"] != target["adapterType"]
                    or actual["runtimeConfig"] != target["runtimeConfig"]
                    or any(actual["adapterConfig"].get(key) != value for key, value in target["adapterConfig"].items())):
                    raise RuntimeError("PATCH response differs from target; intent retained for recovery.")
                if args.restore:
                    if actual != record["original"]:
                        raise RuntimeError("Exact original config was not restored; keep the recovery journal.")
                    del state["agents"][aid]
                else:
                    record["expected"] = actual
                    record["phase"] = "switched"
                save(state)
                print("Verified:", agent["name"], actual["adapterType"], actual["adapterConfig"].get("model", "default"))
            if failures:
                raise RuntimeError(f"{len(failures)} agents deferred; their originals remain saved.")
            if not args.apply:
                print("Preview only. No agent writes. Use --apply to perform the selected operation.")
        finally:
            api("POST", "/api/auth/sign-out", {})


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, ValueError, KeyError, TypeError) as error:
        # Never echo API bodies, credentials, config values or request URLs.
        if isinstance(error, RuntimeError):
            raise SystemExit(str(error)) from None
        raise SystemExit("Subscription switch failed; preserve the journal and inspect locally.") from None
