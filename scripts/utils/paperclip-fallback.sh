#!/usr/bin/env bash
# Paperclip usage-limit fallback: when the Claude Pro subscription hits its
# limit, move claude_local agents to OpenRouter (cheap model) so work doesn't
# stall, then reconcile a fresh approved Claude hire after the limit clears.
#
#   paperclip-fallback.sh            # cron mode (every 5 min): detect → act
#   paperclip-fallback.sh --status   # show state + recent limit failures
#   paperclip-fallback.sh --switch   # force fallback now
#   paperclip-fallback.sh --restore  # probe subscription, report recovery needed
#   paperclip-fallback.sh --reconcile # preview stale retired-ID remaps
#   paperclip-fallback.sh --reconcile --apply # apply the verified remaps
#   add --dry-run to any mutating mode to print actions without changing anything
#
# Why OpenRouter and not Anthropic API credit: Paperclip strips ANTHROPIC_*
# auth env from agents that have a managed AI connection, and there is no
# Anthropic API-key connection — so the only switchable fallback is the
# shared OpenRouter connection with the opencode_local harness. Returning to
# Claude requires a new approved agent; the same-record PATCH is not reliable.
#
# ⚠️ Restore limitation (found 2026-09-29): switching an agent BACK to the
# subscription runs a managed-connection "hello probe" that has reported
# "login is required" even while the separate host-login test passes. Those
# tests use different credential paths; a company test does not prove the
# managed login works. The API refuses the change. Until that is fixed, restore
# fails and this script alerts on Discord instead. That's why AUTO_SWITCH is
# off by default: in cron mode it only notifies. See services/paperclip/README.md
# → "Usage-limit fallback".
#
# Env: AUTO_SWITCH=1 to switch automatically in cron mode (default 0),
#      FALLBACK_MODEL (default openrouter/deepseek/deepseek-v3.2),
#      LOOKBACK_MIN (default 15), PROBE_EVERY_MIN (default 60).
set -euo pipefail

STATE_DIR="$HOME/.config/homelab/paperclip-fallback"
mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR"

MODE=cron
DRY_RUN=0
APPLY=0
for arg in "$@"; do
  case "$arg" in
    --status) MODE=status ;;
    --switch) MODE=switch ;;
    --restore) MODE=restore ;;
    --reconcile) MODE=reconcile ;;
    --apply) APPLY=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done
if [[ "$MODE" == "reconcile" && "$APPLY" != 1 ]]; then DRY_RUN=1; fi
if [[ "$MODE" != "reconcile" && "$APPLY" == 1 ]]; then
  echo "--apply is only valid with --reconcile" >&2
  exit 2
fi

probe_subscription() {
  # Tiny Haiku request through the container's Claude Code login.
  local out
  out=$(docker exec paperclip sh -c 'cd /tmp && timeout 90 claude -p "Reply with exactly: OK" --model claude-haiku-4-5 --max-turns 1 2>&1' || true)
  [[ "$(printf '%s' "$out" | tr -d '[:space:]')" == "OK" ]]
}

notify() {
  # shellcheck source=/dev/null
  source "$HOME/.dotfiles/scripts/lib/notify.sh"
  notify_discord "$1" "$2" "${3:-info}" || true
}
export -f notify probe_subscription

PW=$(grep '^PAPERCLIP_ADMIN_PASSWORD=' "$HOME/.config/homelab/paperclip-admin.env" | cut -d= -f2-)
export PAPERCLIP_PW="$PW"
unset PW

MODE="$MODE" DRY_RUN="$DRY_RUN" STATE_FILE="$STATE_DIR/state.json" \
APPLY="$APPLY" AUTO_SWITCH="${AUTO_SWITCH:-0}" FALLBACK_MODEL="${FALLBACK_MODEL:-openrouter/deepseek/deepseek-v3.2}" \
LOOKBACK_MIN="${LOOKBACK_MIN:-15}" PROBE_EVERY_MIN="${PROBE_EVERY_MIN:-60}" \
python3 - <<'PY'
import fcntl, http.cookiejar, json, os, re, subprocess, sys, time, urllib.parse, urllib.request
from datetime import datetime, timezone

BASE = "http://127.0.0.1:3100"
MODE, DRY, APPLY = os.environ["MODE"], os.environ["DRY_RUN"] == "1", os.environ["APPLY"] == "1"
STATE_FILE = os.environ["STATE_FILE"]
AUTO = os.environ["AUTO_SWITCH"] == "1"
MODEL = os.environ["FALLBACK_MODEL"]
LOOKBACK = int(os.environ["LOOKBACK_MIN"]) * 60
PROBE_EVERY = int(os.environ["PROBE_EVERY_MIN"]) * 60
now = time.time()

# Cron and a manual repair must never race over the saved original configs.
lock_fd = os.open(STATE_FILE + ".lock", os.O_CREAT | os.O_RDWR, 0o600)
try:
    fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
except BlockingIOError:
    print("Another Paperclip fallback operation is running; no changes.")
    sys.exit(0)

jar = http.cookiejar.CookieJar()
opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))

def api(method, path, body=None):
    req = urllib.request.Request(BASE + path, method=method,
                                 data=None if body is None else json.dumps(body).encode(),
                                 headers={"Origin": BASE, "Content-Type": "application/json"})
    try:
        with opener.open(req, timeout=60) as r:
            raw = r.read()
            return r.status, (json.loads(raw) if raw else None)
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read() or b"null")
        except ValueError:
            return e.code, None

def items(x, *keys):
    if isinstance(x, list):
        return x
    for k in keys:
        if isinstance(x, dict) and isinstance(x.get(k), list):
            return x[k]
    return []

def sh(cmd):
    return subprocess.run(["bash", "-c", cmd], capture_output=True, text=True)

def notify(title, body, level="info"):
    if DRY:
        print(f"[dry-run] notify: {title} — {body}")
        return
    subprocess.run(["bash", "-c", 'notify "$1" "$2" "$3"', "_", title, body, level])

def load():
    try:
        with open(STATE_FILE) as source:
            state = json.load(source)
    except FileNotFoundError:
        return {"active": False, "agents": {}, "notified_limit_at": 0, "last_probe": 0}
    except (OSError, ValueError):
        raise SystemExit("Fallback state is unreadable; preserve it and repair before retrying.")
    if not isinstance(state, dict) or not isinstance(state.get("agents"), dict):
        raise SystemExit("Unexpected fallback state shape; preserve it and review before retrying.")
    return state

def save(st):
    if DRY:
        return
    tmp = STATE_FILE + ".tmp"
    with open(tmp, "w", opener=lambda path, flags: os.open(path, flags, 0o600)) as f:
        os.chmod(tmp, 0o600)
        json.dump(st, f, indent=1)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, STATE_FILE)

def ts(s):
    return datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()

def is_limit(run):
    if run.get("status") != "failed":
        return False
    # Prefer Paperclip's own provider-quota classification. A generic 429,
    # max-turn cap, context-window failure or login error is not a spent
    # subscription and must not initiate provider switching.
    if run.get("errorCode") == "provider_quota":
        return True
    result = run.get("resultJson") or {}
    if not isinstance(result, dict):
        result = {}
    terminal = [run.get("error") or ""]
    terminal += [result.get(key) or "" for key in ("error", "errorMessage", "result", "errors", "subtype")]
    e = " ".join(value if isinstance(value, str) else json.dumps(value) for value in terminal).lower()
    if re.search(r"access failure|login.{0,20}required|not logged in|(?:max|maximum)[_ -]?turn|context.{0,20}(?:window|length)|max.{0,20}budget", e):
        return False
    return bool(re.search(r"you['’]ve hit your (?:\w+ )?limit|session limit (?:reached|exceeded)|out of extra usage|extra usage\b|claude usage limit reached|5[- ]?hour limit reached|weekly limit reached|usage limit reached|usage cap reached|servicequotaexceededexception", e))

def has_fallback_budget(company_id, agent_id):
    # The agent's budgetMonthlyCents field alone does not enforce a policy.
    # Require the real monthly hard stop, without increasing an existing cap.
    code, overview = api("GET", f"/api/companies/{company_id}/budgets/overview")
    if code != 200 or not isinstance(overview, dict) or not isinstance(overview.get("policies"), list):
        return False
    policies = [p for p in overview["policies"] if isinstance(p, dict)
        and p.get("scopeType") == "agent" and p.get("scopeId") == agent_id
        and p.get("metric") == "billed_cents" and p.get("windowKind") == "calendar_month_utc"]
    if len(policies) != 1:
        return False
    policy = policies[0]
    amount, spent = policy.get("amount"), policy.get("observedAmount")
    return (policy.get("isActive") is True and policy.get("hardStopEnabled") is True
        and type(amount) is int and 0 < amount <= 300
        and type(spent) in (int, float) and 0 <= spent < amount)

def matches_fallback(agent, fallback):
    return (isinstance(agent, dict) and agent.get("adapterType") == fallback["adapterType"]
        and (agent.get("adapterConfig") or {}).get("model") == fallback["model"]
        and (agent.get("runtimeConfig") or {}).get("aiConnection") == fallback["aiConnection"])

code, _ = api("POST", "/api/auth/sign-in/email",
              {"email": "dziugas@peciulevicius.com", "password": os.environ.pop("PAPERCLIP_PW")})
if code != 200:
    print(f"Paperclip login failed ({code})", file=sys.stderr)
    sys.exit(1)

try:
    st = load()
    companies = api("GET", "/api/companies")[1] or []
    comp = {}
    for c in companies:
        cid = c["id"]
        conns = items(api("GET", f"/api/companies/{cid}/ai-connections")[1], "connections", "items", "data")
        orc = next((x for x in conns if x.get("provider") == "openrouter" and x.get("status") == "connected"), None)
        agents = api("GET", f"/api/companies/{cid}/agents")[1] or []
        runs = api("GET", f"/api/companies/{cid}/heartbeat-runs?limit=50")[1] or []
        current_claude = {a["id"] for a in agents
            if a.get("adapterType") == "claude_local" and a.get("status") not in ("paused", "terminated", "pending_approval")
            and "retired" not in a.get("name", "").lower() and "duplicate hire" not in a.get("name", "").lower()}
        recent_limit = [r for r in runs if r.get("agentId") in current_claude
            and r.get("adapterType", "claude_local") == "claude_local" and is_limit(r)
            and r.get("finishedAt") and 0 <= now - ts(r["finishedAt"]) < LOOKBACK]
        comp[cid] = {"name": c["name"], "openrouter": orc, "agents": agents, "limit_runs": recent_limit}
    limit_runs = [(cid, r) for cid, v in comp.items() for r in v["limit_runs"]]

    def switch():
        switched, skipped = [], []
        for cid, v in comp.items():
            orc = v["openrouter"]
            for a in v["agents"]:
                if a.get("adapterType") != "claude_local" or a["id"] in st["agents"]:
                    continue
                if a.get("status") in ("paused", "terminated", "pending_approval"):
                    continue
                if not orc:
                    skipped.append(f"{v['name']}/{a['name']} (no OpenRouter connection in company)")
                    continue
                code, full = api("GET", f"/api/agents/{a['id']}")
                if code != 200 or not isinstance(full, dict):
                    skipped.append(f"{v['name']}/{a['name']} (cannot verify current configuration)")
                    continue
                if full.get("adapterType") != "claude_local" or full.get("status") in ("running", "paused", "terminated", "pending_approval"):
                    skipped.append(f"{v['name']}/{a['name']} (configuration changed or agent is busy/paused)")
                    continue
                if not has_fallback_budget(cid, a["id"]):
                    skipped.append(f"{v['name']}/{a['name']} (requires an active monthly hard-stop policy of $3 or less, with remaining budget)")
                    continue
                orig = {"adapterType": full["adapterType"], "adapterConfig": full["adapterConfig"],
                        "runtimeConfig": full["runtimeConfig"]}
                body = {"adapterType": "opencode_local",
                        "adapterConfig": {**full["adapterConfig"], "model": MODEL},
                        "runtimeConfig": {**full["runtimeConfig"], "aiConnection": {
                            "mode": "shared", "method": "api_key", "provider": "openrouter",
                            "connectionId": orc["id"], "grantId": orc["grantId"]}}}
                if DRY:
                    switched.append(f"{v['name']}/{a['name']}")
                    continue
                # Journal intent before PATCH: a timeout, crash or failed disk
                # write after the server changes harness must not lose originals.
                st["agents"][a["id"]] = {"company": cid, "name": a["name"], "orig": orig,
                    "switch_pending": True, "fallback": {"adapterType": "opencode_local",
                    "model": MODEL, "aiConnection": body["runtimeConfig"]["aiConnection"]}}
                st.update(active=True, since=st.get("since") or now, last_probe=now)
                save(st)
                code, res = api("PATCH", f"/api/agents/{a['id']}", body)
                if code == 200 and matches_fallback(res, st["agents"][a["id"]]["fallback"]):
                    st["agents"][a["id"]].pop("switch_pending")
                    save(st)  # Preserve each successful switch if a later call fails.
                    switched.append(f"{v['name']}/{a['name']}")
                else:
                    skipped.append(f"{v['name']}/{a['name']} (PATCH {code}; originals retained, inspect with --reconcile)")
        # Re-wake work that a limit failure interrupted: @mention wakes the assignee.
        rewoken = []
        for cid, r in limit_runs:
            snap = r.get("contextSnapshot") or {}
            issue = snap.get("issueId") or r.get("issueId")
            name = next((a["name"] for a in comp[cid]["agents"] if a["id"] == r["agentId"]), None)
            if issue and name and r["agentId"] in st["agents"] and not st["agents"][r["agentId"]].get("switch_pending") and issue not in rewoken:
                if not DRY:
                    api("POST", f"/api/issues/{issue}/comments",
                        {"body": f"@{name} continuing after the Claude usage-limit fallback (now on {MODEL})."})
                rewoken.append(issue)
        if switched:
            st.update(active=True, since=st.get("since") or now, last_probe=now)
        return switched, skipped, rewoken

    def restore():
        # The same agent record cannot reliably cross back from OpenCode to
        # Claude. Never retry the known-broken PATCH; rehire is a board action.
        failed = [f"{rec['name']} (requires a fresh Claude hire; same-record restore is unsupported)"
                  for rec in st["agents"].values()]
        return [], failed

    def reconcile():
        """Repair references left behind by the incident's manual rehires.

        Only touch records explicitly marked retired and paused/terminated,
        and only when one live agent exactly matches the original name,
        adapter, and model. Never terminate or rename agents here.
        """
        reconciled, skipped, failed = [], [], []
        retired_ids = set()
        terminal_issues = {"done", "cancelled", "canceled", "rejected"}
        for old_id, rec in list(st["agents"].items()):
            if rec.get("switch_pending"):
                code, current = api("GET", f"/api/agents/{old_id}")
                if code != 200 or not isinstance(current, dict):
                    failed.append(f"{rec['name']} (unconfirmed switch; originals preserved)")
                    continue
                orig, fallback = rec["orig"], rec["fallback"]
                if all(current.get(key) == orig[key] for key in ("adapterType", "adapterConfig", "runtimeConfig")):
                    del st["agents"][old_id]
                    save(st)
                    reconciled.append(rec["name"] + " (switch did not apply; original configuration verified)")
                    continue
                if matches_fallback(current, fallback):
                    rec.pop("switch_pending")
                    save(st)
                else:
                    failed.append(f"{rec['name']} (configuration differs; originals preserved for review)")
                    continue
            cid = rec.get("company")
            company = comp.get(cid)
            if not company:
                skipped.append(f"{rec.get('name', old_id)} (company not found)")
                continue
            code, old = api("GET", f"/api/agents/{old_id}")
            if code != 200 or not isinstance(old, dict):
                skipped.append(f"{rec.get('name', old_id)} (old agent unavailable)")
                continue
            if ("retired" not in (old.get("name") or "").lower()
                    or old.get("status") not in ("paused", "terminated")):
                skipped.append(f"{rec.get('name', old_id)} (not a paused retired agent)")
                continue
            retired_ids.add(old_id)
            orig = rec.get("orig") or {}
            orig_model = (orig.get("adapterConfig") or {}).get("model")
            candidates = [a for a in company["agents"]
                          if a.get("id") != old_id
                          and a.get("name") == rec.get("name")
                          and a.get("adapterType") == orig.get("adapterType")
                          and (a.get("adapterConfig") or {}).get("model") == orig_model
                          and a.get("status") in ("active", "idle", "running")]
            if len(candidates) != 1:
                skipped.append(f"{rec.get('name', old_id)} (expected one matching live replacement; found {len(candidates)})")
                continue
            new = candidates[0]
            desired_skills = ((orig.get("adapterConfig") or {}).get("paperclipSkillSync") or {}).get("desiredSkills", [])
            reports = [a for a in company["agents"]
                       if a.get("reportsTo") == old_id
                       and "retired" not in (a.get("name") or "").lower()
                       and a.get("status") != "terminated"]
            query = urllib.parse.urlencode({"assigneeAgentId": old_id})
            code, result = api("GET", f"/api/companies/{cid}/issues?{query}")
            if code != 200:
                failed.append(f"{rec.get('name', old_id)} (could not list assigned issues: {code})")
                continue
            open_issues = [i for i in items(result, "issues", "items", "data")
                           if i.get("status") not in terminal_issues]
            issue_refs = [f"{i.get('identifier') or i['id']}:{i.get('status')}" for i in open_issues]
            print(f"{'[dry-run] ' if DRY else ''}{company['name']}/{rec['name']}: replacement {new['id']}; "
                  f"add {len(desired_skills)} saved skill(s), reports={[a.get('name') for a in reports]}, "
                  f"open issues={issue_refs}")
            if DRY:
                reconciled.append(rec["name"])
                continue
            errors = []
            if desired_skills:
                code, result = api("POST", f"/api/agents/{new['id']}/skills/sync",
                                   {"mode": "add", "desiredSkills": desired_skills})
                if code != 200:
                    errors.append(f"skills ({(result or {}).get('error') or code})")
            for agent in reports:
                code, result = api("PATCH", f"/api/agents/{agent['id']}", {"reportsTo": new["id"]})
                if code != 200:
                    errors.append(f"reportsTo {agent.get('name')} ({code})")
            for issue in open_issues:
                code, result = api("PATCH", f"/api/issues/{issue['id']}", {"assigneeAgentId": new["id"]})
                if code != 200:
                    errors.append(f"issue {issue.get('identifier') or issue['id']} ({code})")
            if errors:
                failed.append(f"{rec['name']} (partial; " + ", ".join(errors) + ")")
            else:
                reconciled.append(rec["name"])
                del st["agents"][old_id]
                save(st)  # Retain completed repairs across a later API failure.
        # Pending reference repairs are not agents still running on fallback.
        # Keep their saved configs for retry, without hourly subscription probes
        # and restore alerts for records that have already been retired.
        st["reconciliation_pending"] = sorted(retired_ids.intersection(st["agents"]))
        st["active"] = bool(set(st["agents"]) - retired_ids)
        if not st["active"]:
            st["since"] = None
        return reconciled, skipped, failed

    if MODE == "status":
        print(json.dumps({"active": st.get("active"), "since": st.get("since"),
                          "switched_agents": {k: v["name"] for k, v in st["agents"].items() if not v.get("switch_pending")},
                          "unconfirmed_switches": {k: v["name"] for k, v in st["agents"].items() if v.get("switch_pending")},
                          "recent_limit_failures": [f"{comp[c]['name']}: run {r['id'][:8]} at {r['finishedAt']}" for c, r in limit_runs],
                          "companies_without_openrouter": [v["name"] for v in comp.values() if not v["openrouter"]],
                          "auto_switch": AUTO}, indent=1))
    elif MODE == "reconcile":
        rs, sk, fl = reconcile()
        save(st)
        print("would reconcile:" if DRY else "reconciled:", rs,
              "\nskipped:", sk, "\nfailed:", fl, "\napplied:", APPLY and not DRY)
        if fl or sk:
            sys.exit(1)
    elif MODE == "switch" or (MODE == "cron" and limit_runs and not st.get("active") and AUTO):
        sw, sk, rw = switch()
        save(st)
        print("switched:", sw, "\nskipped:", sk, "\nre-woken issues:", rw)
        if sw:
            notify("⚡ Claude limit hit → agents on OpenRouter",
                   f"{len(sw)} agents moved to {MODEL}: {', '.join(sw)}." + (f" Skipped: {', '.join(sk)}." if sk else ""), "warn")
    elif MODE == "restore" or (MODE == "cron" and st.get("active") and now - st.get("last_probe", 0) >= PROBE_EVERY):
        if any(rec.get("switch_pending") for rec in st["agents"].values()):
            print("Unconfirmed provider switches; originals preserved. Run --reconcile before probing recovery.")
            sys.exit(1)
        st["last_probe"] = now
        ok = True if DRY else subprocess.run(["bash", "-c", "probe_subscription"]).returncode == 0
        if not ok:
            print("subscription still limited")
        else:
            rs, fl = restore()
            print("restored:", rs, "\nfailed:", fl)
            if rs:
                notify("✅ Claude subscription back", f"Restored {len(rs)} agents: {', '.join(rs)}.", "ok")
            if fl and st.get("restore_notice") != fl:
                notify("⚠️ Paperclip restore needs a click",
                       "Claude is available again, but these agents cannot switch harness in place: "
                       + ", ".join(fl) + ". Use --reconcile if a fresh matching hire already exists; "
                       "otherwise request and approve a new Claude hire. See services/paperclip/README.md "
                       "→ Usage-limit fallback.", "warn")
                st["restore_notice"] = fl
        save(st)
    elif MODE == "cron" and limit_runs and not st.get("active"):
        if now - st.get("notified_limit_at", 0) > 3 * 3600:
            notify("⚠️ Claude usage limit hit in Paperclip",
                   f"{len(limit_runs)} run(s) failed on the limit. Auto-switch is off; run "
                   "`~/.dotfiles/scripts/utils/paperclip-fallback.sh --switch --dry-run` to preview the budget-guarded fallback. "
                   "Same-agent restore remains unavailable; waiting for reset avoids another rehire.", "warn")
            st["notified_limit_at"] = now
            save(st)
finally:
    api("POST", "/api/auth/sign-out", {})
PY
