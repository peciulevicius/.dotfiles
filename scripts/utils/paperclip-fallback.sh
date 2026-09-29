#!/usr/bin/env bash
# Paperclip usage-limit fallback: when the Claude Pro subscription hits its
# limit, move claude_local agents to OpenRouter (cheap model) so work doesn't
# stall, then reconcile a fresh approved Claude hire after the limit clears.
#
#   paperclip-fallback.sh            # cron mode (every 5 min): detect → act
#   paperclip-fallback.sh --status   # show state + recent limit failures
#   paperclip-fallback.sh --switch   # force fallback now
#   paperclip-fallback.sh --restore  # probe subscription, restore agents
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
# subscription runs Paperclip's Claude "hello probe", which currently reports
# a false "login is required" (real runs work). The API then refuses the
# change, and so does config-revision rollback. Until that is fixed, restore
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
import http.cookiejar, json, os, subprocess, sys, time, urllib.parse, urllib.request
from datetime import datetime, timezone

BASE = "http://127.0.0.1:3100"
MODE, DRY, APPLY = os.environ["MODE"], os.environ["DRY_RUN"] == "1", os.environ["APPLY"] == "1"
STATE_FILE = os.environ["STATE_FILE"]
AUTO = os.environ["AUTO_SWITCH"] == "1"
MODEL = os.environ["FALLBACK_MODEL"]
LOOKBACK = int(os.environ["LOOKBACK_MIN"]) * 60
PROBE_EVERY = int(os.environ["PROBE_EVERY_MIN"]) * 60
now = time.time()

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
        return json.load(open(STATE_FILE))
    except (OSError, ValueError):
        return {"active": False, "agents": {}, "notified_limit_at": 0, "last_probe": 0}

def save(st):
    if DRY:
        return
    tmp = STATE_FILE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(st, f, indent=1)
    os.chmod(tmp, 0o600)
    os.replace(tmp, STATE_FILE)

def ts(s):
    return datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()

def is_limit(run):
    err = (run.get("error") or "") + " " + json.dumps(run.get("resultJson") or "")
    e = err.lower()
    return run.get("status") == "failed" and "limit" in e and "access failure" not in e

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
        recent_limit = [r for r in runs if is_limit(r) and r.get("finishedAt") and now - ts(r["finishedAt"]) < LOOKBACK]
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
                full = api("GET", f"/api/agents/{a['id']}")[1]
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
                code, res = api("PATCH", f"/api/agents/{a['id']}", body)
                if code == 200 and (res or {}).get("adapterType") == "opencode_local":
                    st["agents"][a["id"]] = {"company": cid, "name": a["name"], "orig": orig}
                    switched.append(f"{v['name']}/{a['name']}")
                else:
                    skipped.append(f"{v['name']}/{a['name']} (PATCH {code}: {(res or {}).get('error')})")
        # Re-wake work that a limit failure interrupted: @mention wakes the assignee.
        rewoken = []
        for cid, r in limit_runs:
            snap = r.get("contextSnapshot") or {}
            issue = snap.get("issueId") or r.get("issueId")
            name = next((a["name"] for a in comp[cid]["agents"] if a["id"] == r["agentId"]), None)
            if issue and name and r["agentId"] in st["agents"] and issue not in rewoken:
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
                          "switched_agents": {k: v["name"] for k, v in st["agents"].items()},
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
                   "`~/.dotfiles/scripts/utils/paperclip-fallback.sh --switch` to move agents to OpenRouter.", "warn")
            st["notified_limit_at"] = now
            save(st)
finally:
    api("POST", "/api/auth/sign-out", {})
PY
