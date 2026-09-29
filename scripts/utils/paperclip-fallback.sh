#!/usr/bin/env bash
# Paperclip usage-limit fallback: when the Claude Pro subscription hits its
# limit, move claude_local agents to OpenRouter (cheap model) so work doesn't
# stall, and move them back when the subscription answers again.
#
#   paperclip-fallback.sh            # cron mode (every 5 min): detect → act
#   paperclip-fallback.sh --status   # show state + recent limit failures
#   paperclip-fallback.sh --switch   # force fallback now
#   paperclip-fallback.sh --restore  # probe subscription, restore agents
#   add --dry-run to any of them to print actions without changing anything
#
# Why OpenRouter and not Anthropic API credit: Paperclip strips ANTHROPIC_*
# auth env from agents that have a managed AI connection, and there is no
# Anthropic API-key connection — so the only switchable fallback is the
# shared OpenRouter connection with the opencode_local harness. It is also
# ~10x cheaper per run (deepseek-v3.2 vs Sonnet via API).
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
for arg in "$@"; do
  case "$arg" in
    --status) MODE=status ;;
    --switch) MODE=switch ;;
    --restore) MODE=restore ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

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
AUTO_SWITCH="${AUTO_SWITCH:-0}" FALLBACK_MODEL="${FALLBACK_MODEL:-openrouter/deepseek/deepseek-v3.2}" \
LOOKBACK_MIN="${LOOKBACK_MIN:-15}" PROBE_EVERY_MIN="${PROBE_EVERY_MIN:-60}" \
python3 - <<'PY'
import http.cookiejar, json, os, subprocess, sys, time, urllib.request
from datetime import datetime, timezone

BASE = "http://127.0.0.1:3100"
MODE, DRY = os.environ["MODE"], os.environ["DRY_RUN"] == "1"
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
        restored, failed = [], []
        for aid, rec in list(st["agents"].items()):
            if DRY:
                restored.append(rec["name"])
                continue
            code, res = api("PATCH", f"/api/agents/{aid}", rec["orig"])
            if code == 200 and (res or {}).get("adapterType") == rec["orig"]["adapterType"]:
                restored.append(rec["name"])
                del st["agents"][aid]
            else:
                failed.append(f"{rec['name']} ({(res or {}).get('error') or code})")
        if not st["agents"]:
            st.update(active=False, since=None)
        return restored, failed

    if MODE == "status":
        print(json.dumps({"active": st.get("active"), "since": st.get("since"),
                          "switched_agents": {k: v["name"] for k, v in st["agents"].items()},
                          "recent_limit_failures": [f"{comp[c]['name']}: run {r['id'][:8]} at {r['finishedAt']}" for c, r in limit_runs],
                          "companies_without_openrouter": [v["name"] for v in comp.values() if not v["openrouter"]],
                          "auto_switch": AUTO}, indent=1))
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
            if fl:
                notify("⚠️ Paperclip restore needs a click",
                       "Subscription answers again, but Paperclip refused to move these agents back: "
                       + ", ".join(fl) + ". Paperclip → agent → Configuration → adapter Claude + "
                       "'My Claude subscription' → Save. See services/paperclip/README.md → Usage-limit fallback.", "warn")
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
