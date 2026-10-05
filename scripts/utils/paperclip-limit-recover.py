#!/usr/bin/env python3
# Auto-recover Paperclip agents that stopped on a usage limit. When Claude's
# session/weekly limit hits, a claude_local run fails with "terminal limit
# failure", the agent goes to `error` and its task is stranded until a board
# operator resumes it. This cron job (every 15 min) resumes such agents once the
# error is >= COOLDOWN_MIN old and @mentions it on its in-progress task (the
# run the limit interrupted; todo/blocked tasks are left alone), at most once
# per RETRY_MIN per agent, so a still-active limit isn't hammered. Only Claude
# subscription-quota failures are touched; any other error is left alone.
#   paperclip-limit-recover.py            # act
#   paperclip-limit-recover.py --dry-run  # print what it would do
import http.cookiejar, json, os, re, sys, time, urllib.request
from datetime import datetime
from pathlib import Path

BASE = "http://127.0.0.1:3100"
COOLDOWN_MIN = int(os.environ.get("COOLDOWN_MIN", "30"))
RETRY_MIN = int(os.environ.get("RETRY_MIN", "60"))
STATE = Path.home() / ".config/homelab/paperclip-limit-recover.json"
DRY = "--dry-run" in sys.argv

admin = (Path.home() / ".config/homelab/paperclip-admin.env").read_text()
password = re.search(r"^PAPERCLIP_ADMIN_PASSWORD=(.*)$", admin, re.M).group(1).strip().strip("'\"")
opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))


def api(method, path, body=None):
    req = urllib.request.Request(BASE + path, method=method, data=json.dumps(body).encode() if body is not None else None,
                                 headers={"Origin": BASE, "Content-Type": "application/json"})
    with opener.open(req, timeout=30) as r:
        return json.load(r)


QUOTA_MARKERS = ("terminal limit failure", "usage limit", "rate limit", "limit reached", "provider_quota")


def is_quota_failure(excerpt):
    text = (excerpt or "").lower()
    return any(marker in text for marker in QUOTA_MARKERS)


def attention(cid):
    items, cursor = [], None
    while True:
        page = api("GET", f"/api/companies/{cid}/attention?limit=100" + (f"&cursor={cursor}" if cursor else ""))
        items += page["items"]
        cursor = page.get("nextCursor")
        if not cursor:
            return items


def age_min(stamp):
    return (time.time() - datetime.fromisoformat(stamp.replace("Z", "+00:00")).timestamp()) / 60


STATE.parent.mkdir(parents=True, exist_ok=True)
try:
    state = json.loads(STATE.read_text())
except (FileNotFoundError, ValueError):
    state = {}

api("POST", "/api/auth/sign-in/email", {"email": "dziugas@peciulevicius.com", "password": password})
now = time.time()
failures = 0
RETRY_TEXT = "automatic retry: your last run stopped on a usage limit; the limit should have reset. Continue where you left off."
# Retry comments that failed on an earlier run (the agent is no longer in `error`).
def save_state():
    STATE.write_text(json.dumps(state))
    os.chmod(STATE, 0o600)


for p in list([] if DRY else state.get("pending", [])):
    try:
        issue = api("GET", f"/api/issues/{p['issue']}")
        # Only nudge if the same agent still owns an open, in-progress task.
        if issue.get("assigneeAgentId") == p.get("agent_id") and issue["status"] == "in_progress":
            api("POST", f"/api/issues/{p['issue']}/comments", {"body": f"@{p['agent']} {RETRY_TEXT}"})
        state["pending"].remove(p)
        save_state()  # persist each success, so a later failure can't cause a duplicate nudge
    except Exception as error:
        print(f"  pending comment on {p['issue']} failed again: {error}")
for company in api("GET", "/api/companies"):
    cid = company["id"]
    feed = attention(cid)
    alerts = {}
    for item in feed:
        detail = item.get("detail") or {}
        if item["sourceKind"] == "agent_error_alert" and is_quota_failure(detail.get("failureReasonExcerpt")):
            alerts[detail.get("agentName")] = item
    if not alerts:
        continue
    agents = {a["name"]: a for a in api("GET", f"/api/companies/{cid}/agents") if a["status"] != "terminated"}
    issues = None
    for name, item in alerts.items():
        agent = agents.get(name)
        if not agent or agent["status"] != "error" or agent.get("adapterType") != "claude_local":
            continue
        if age_min(item.get("activityAt") or item["createdAt"]) < COOLDOWN_MIN:
            print(f"{company['name']}/{name}: limit error too recent, waiting")
            continue
        if now - state.get(agent["id"], 0) < RETRY_MIN * 60:
            print(f"{company['name']}/{name}: retried < {RETRY_MIN} min ago, waiting")
            continue
        if issues is None:
            data = api("GET", f"/api/companies/{cid}/issues?limit=200")
            issues = data.get("items", data) if isinstance(data, dict) else data
        stranded = [i for i in issues if i.get("assigneeAgentId") == agent["id"] and i["status"] == "in_progress"]
        print(f"{company['name']}/{name}: resume + re-queue {[i['identifier'] for i in stranded]}")
        if DRY:
            continue
        api("POST", f"/api/agents/{agent['id']}/resume", {})
        state[agent["id"]] = now  # recorded before the comments: a failed comment must not cause a resume loop
        STATE.write_text(json.dumps(state))
        for i in stranded:
            try:
                api("POST", f"/api/issues/{i['id']}/comments", {"body": f"@{name} {RETRY_TEXT}"})
            except Exception as error:
                print(f"  comment on {i['identifier']} failed: {error}")
                failures += 1
                state.setdefault("pending", []).append({"issue": i["id"], "agent": name, "agent_id": agent["id"]})

if not DRY:
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(json.dumps(state))
    os.chmod(STATE, 0o600)
api("POST", "/api/auth/sign-out", {})
failures += len(state.get("pending", []))
if failures:
    sys.exit(f"{failures} retry comment(s) failed; the agent was resumed but may not wake — check the log")  # run-with-notify alerts
