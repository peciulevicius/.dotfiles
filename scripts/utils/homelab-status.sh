#!/bin/bash
# Write a small JSON health snapshot for the Glance homepage.
#
#   homelab-status.sh            # write ~/services/glance/assets/status.json
#   homelab-status.sh --print    # also print the JSON (no secrets in it)
#
# Cron (see scripts/cron/crontab):
#   */5 * * * * ~/.dotfiles/scripts/utils/homelab-status.sh >> ~/logs/homelab-status.log 2>&1
#
# Glance serves ~/services/glance/assets/ at /assets/ (server.assets-path),
# and the "Homelab health" custom-api widget in glance.yml reads
# http://localhost:8080/assets/status.json from inside the container. Glance
# can't see the host's swap, the APFS data volume, backup stamps or the
# Paperclip board, so this script gathers them on the host and Glance only
# renders. Every value carries a precomputed level (ok / warn / bad) so the
# template stays dumb.
#
# Nothing here wakes a scale-to-zero app: awake/asleep is read from
# `docker ps`, never by requesting the app.
#
# Training numbers come from the TrainingPeaks MCP (127.0.0.1:8092, read-only
# tools only) and are cached for 30 min in ~/.cache/homelab-status/tp.json, so
# TrainingPeaks sees at most ~48 calls a day. The cache and status.json live
# outside the repo — personal health numbers are never committed.
#
# The Paperclip board password is read from ~/.config/homelab/paperclip-admin.env
# into a variable, sent only to the local Paperclip API, and never written out.

set -uo pipefail

OUT_DIR="${OUT_DIR:-$HOME/services/glance/assets}"
OUT="$OUT_DIR/status.json"
PAPERCLIP="${PAPERCLIP_URL:-http://127.0.0.1:3100}"
PAPERCLIP_EMAIL="${PAPERCLIP_EMAIL:-dziugas@peciulevicius.com}"
PAPERCLIP_ENV="$HOME/.config/homelab/paperclip-admin.env"
COACH_COMPANY="31472664-4bfe-4bd1-9313-19d0739378d2"
TP_MCP="${TP_MCP_URL:-http://127.0.0.1:8092/mcp}"
TP_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/homelab-status"
TP_CACHE="$TP_CACHE_DIR/tp.json"
TP_MAX_AGE_MIN=30
REFRESH_MIN=5   # keep in sync with the cron line

mkdir -p "$OUT_DIR"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# ── Memory: Docker VM used vs limit, macOS swap ─────────────────────────────
docker_total=$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo 0)
docker stats --no-stream --format '{{.MemUsage}}' 2>/dev/null | awk '{print $1}' > "$tmpdir/mem" || true
swap_line=$(sysctl -n vm.swapusage 2>/dev/null || echo "")

# ── Host: CPU load, cores, uptime, container counts (Glance's own
# server-stats widget only sees the Docker VM, not the Mac)
export HS_LOAD HS_CORES HS_BOOT HS_RUNNING HS_TOTAL
HS_LOAD=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')
HS_CORES=$(sysctl -n hw.ncpu 2>/dev/null)
HS_BOOT=$(sysctl -n kern.boottime 2>/dev/null | sed -E 's/^[{] sec = ([0-9]+),.*/\1/')
HS_RUNNING=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
HS_TOTAL=$(docker ps -aq 2>/dev/null | wc -l | tr -d ' ')

# ── Disk: APFS data volume (the real one, not the sealed system volume) + NAS
disk_host=$(df -k /System/Volumes/Data 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')
disk_nas=$(df -k /Volumes/media 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')

# ── Backups ────────────────────────────────────────────────────────────────
mtime() { [[ -e "$1" ]] && stat -f %m "$1" || echo 0; }
r2_ok=0
tail -5 "$HOME/logs/rclone-backup.log" 2>/dev/null | grep -q "All backups complete" && r2_ok=1
r2_ts=$(mtime "$HOME/logs/rclone-backup.log")
# shellcheck disable=SC2012  # newest file by mtime; names are ours, no odd chars
db_newest=$(ls -t "$HOME"/backups/* 2>/dev/null | head -1)
db_ts=$(mtime "${db_newest:-/nonexistent}")
t5_ts=$(cat "$HOME/logs/external-backup-Backup.last" 2>/dev/null || echo 0)
t7_ts=$(cat "$HOME/logs/external-backup-T7.last" 2>/dev/null || echo 0)

# ── Scale-to-zero: groups with at least one running container ──────────────
docker ps -a --filter label=sablier.enable=true \
  --format '{{.Label "sablier.group"}} {{.State}}' 2>/dev/null > "$tmpdir/sablier" || true

# ── Coach team ─────────────────────────────────────────────────────────────
today_line=$(grep -v -e '^#' -e '^[[:space:]]*$' "$HOME/ai-memory/training/nutrition/today.md" 2>/dev/null | head -1)

# ── Paperclip: pending approvals + issues waiting on the board ─────────────
pc_ok=0
if [[ -r "$PAPERCLIP_ENV" ]]; then
  pw=$(grep '^PAPERCLIP_ADMIN_PASSWORD=' "$PAPERCLIP_ENV" | cut -d= -f2-)
  jar="$tmpdir/cj"
  if python3 -c 'import json,sys;print(json.dumps({"email":sys.argv[1],"password":sys.argv[2]}))' "$PAPERCLIP_EMAIL" "$pw" |
     curl -fsS -m 10 -c "$jar" -H 'Content-Type: application/json' -H "Origin: $PAPERCLIP" \
       --data @- "$PAPERCLIP/api/auth/sign-in/email" -o /dev/null 2>/dev/null; then
    pc_ok=1
    pc() { curl -fsS -m 10 -b "$jar" -H "Origin: $PAPERCLIP" "$PAPERCLIP$1" 2>/dev/null; }
    pc /api/companies > "$tmpdir/companies" || true
    for cid in $(python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
for c in (d if isinstance(d,list) else d.get("companies",[])): print(c["id"])' "$tmpdir/companies" 2>/dev/null); do
      pc "/api/companies/$cid/approvals" > "$tmpdir/approvals-$cid" || true
      pc "/api/companies/$cid/issues" > "$tmpdir/issues-$cid" || true
    done
    # Latest Coach "Daily check-in" issue → its comments (summary for the panel)
    checkin_id=$(python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
items=d if isinstance(d,list) else d.get("issues",d.get("items",[]))
c=[i for i in items if "check-in" in (i.get("title") or "").lower() and i.get("status")!="cancelled"]
c.sort(key=lambda i:i.get("createdAt",""))
print(c[-1]["id"] if c else "")' "$tmpdir/issues-$COACH_COMPANY" 2>/dev/null)
    [[ -n "$checkin_id" ]] && pc "/api/issues/$checkin_id/comments" > "$tmpdir/checkin-comments" || true
    curl -fsS -m 10 -b "$jar" -H "Origin: $PAPERCLIP" -H 'Content-Type: application/json' \
      -X POST "$PAPERCLIP/api/auth/sign-out" -d '{}' -o /dev/null 2>/dev/null || true
  fi
  unset pw
fi

# ── TrainingPeaks (cached 30 min) ──────────────────────────────────────────
mkdir -p "$TP_CACHE_DIR"
if [[ ! -s "$TP_CACHE" ]] || [[ -n "$(find "$TP_CACHE" -mmin +"$TP_MAX_AGE_MIN" 2>/dev/null)" ]]; then
  python3 - "$TP_MCP" > "$tmpdir/tp.json" 2>/dev/null <<'PY'
import json, sys, urllib.request
from datetime import date, timedelta

url = sys.argv[1]
hdr = {"Content-Type": "application/json", "Accept": "application/json, text/event-stream"}

def post(body, sid=None):
    h = dict(hdr, **({"mcp-session-id": sid} if sid else {}))
    r = urllib.request.urlopen(urllib.request.Request(url, json.dumps(body).encode(), h), timeout=60)
    raw, new_sid = r.read().decode(), r.headers.get("mcp-session-id")
    if "data:" in raw[:30]:
        raw = [l[5:] for l in raw.splitlines() if l.startswith("data:")][-1]
    return (json.loads(raw) if raw.strip() else None), new_sid

_, sid = post({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {
    "protocolVersion": "2025-03-26", "capabilities": {},
    "clientInfo": {"name": "homelab-status", "version": "1"}}})
post({"jsonrpc": "2.0", "method": "notifications/initialized"}, sid)

def call(name, args=None):  # read-only tools only
    d, _ = post({"jsonrpc": "2.0", "id": 2, "method": "tools/call",
                 "params": {"name": name, "arguments": args or {}}}, sid)
    return json.loads(d["result"]["content"][0]["text"])

out = {"ok": False}
auth = call("tp_auth_status")
if not auth.get("valid"):
    out["error"] = "TP login expired"
else:
    today = date.today()
    out["fitness"] = call("tp_get_fitness", {"days": 7}).get("current", {})
    out["week"] = call("tp_get_weekly_summary")
    out["metrics"] = call("tp_get_metrics", {"start_date": str(today - timedelta(days=14)),
                                             "end_date": str(today)}).get("metrics", [])
    out["ok"] = True
print(json.dumps(out))
PY
  if python3 -m json.tool "$tmpdir/tp.json" > /dev/null 2>&1; then
    mv "$tmpdir/tp.json" "$TP_CACHE"
  elif [[ ! -s "$TP_CACHE" ]]; then
    echo '{"ok": false, "error": "TrainingPeaks MCP unreachable"}' > "$TP_CACHE"
  fi
fi

# ── Assemble ───────────────────────────────────────────────────────────────
python3 - "$tmpdir" "$docker_total" "$swap_line" "${disk_host:-0}" "${disk_nas:-0}" \
  "$r2_ok" "$r2_ts" "$db_ts" "$t5_ts" "$t7_ts" "$today_line" "$pc_ok" "$COACH_COMPANY" \
  "$TP_CACHE" "$REFRESH_MIN" \
  > "$tmpdir/status.json" <<'PY'
import glob, json, os, re, sys, time
from datetime import datetime, timedelta, timezone

(tmp, docker_total, swap_line, disk_host, disk_nas, r2_ok, r2_ts, db_ts,
 t5_ts, t7_ts, today_line, pc_ok, coach_company, tp_cache, refresh_min) = sys.argv[1:]
now = time.time()

def level(value, warn, bad):
    return "bad" if value >= bad else "warn" if value >= warn else "ok"

def mib(s):
    m = re.match(r"([\d.]+)\s*([KMG]i?B|B)", s)
    if not m:
        return 0.0
    n, u = float(m.group(1)), m.group(2)
    return n * {"B": 1 / 2**20, "KiB": 1 / 1024, "KB": 1 / 1024, "MiB": 1, "MB": 1,
                "GiB": 1024, "GB": 1024}.get(u, 1)

used = sum(mib(l) for l in open(f"{tmp}/mem").read().split())
total = int(docker_total) / 2**20 if docker_total.isdigit() else 0
mem_pct = round(100 * used / total) if total else 0

sw = dict(re.findall(r"(total|used) = ([\d.]+)M", swap_line))
swap_used = float(sw.get("used", 0)) / 1024
swap_total = float(sw.get("total", 0)) / 1024
swap_pct = round(100 * swap_used / swap_total) if swap_total else 0

def age(ts, warn_h, bad_h, ok=True):
    ts = int(float(ts or 0))
    if ts <= 0:
        return {"age": "never", "level": "bad"}
    h = (now - ts) / 3600
    text = f"{h:.0f}h ago" if h < 48 else f"{h / 24:.0f}d ago"
    return {"age": text, "level": "bad" if not ok else level(h, warn_h, bad_h)}

groups = {}
for line in open(f"{tmp}/sablier").read().splitlines():
    g, _, state = line.partition(" ")
    groups.setdefault(g, False)
    groups[g] = groups[g] or state == "running"
awake = sorted(g for g, up in groups.items() if up)

# Display name + link per Sablier group (same links as the 💤 bookmarks).
SLEEPER_LINKS = {
    "jellyfin": ("Jellyfin", "https://watch.peciulevicius.com"),
    "jellyseerr": ("Jellyseerr", "http://100.81.171.49:5055"),
    "audiobookshelf": ("Audiobookshelf", "https://listen.peciulevicius.com"),
    "calibre-web": ("Calibre-Web", "https://books.peciulevicius.com"),
    "bazarr": ("Bazarr", "http://100.81.171.49:6767"),
    "nextcloud": ("Nextcloud", "https://cloud.peciulevicius.com"),
    "paperless": ("Paperless-ngx", "https://papers.peciulevicius.com"),
    "stirling-pdf": ("Stirling PDF", "https://pdf.peciulevicius.com"),
    "linkwarden": ("Linkwarden", "https://links.peciulevicius.com"),
    "odysseus": ("Odysseus", "http://100.81.171.49:7001"),
    "it-tools": ("IT-Tools", "https://tools.peciulevicius.com"),
}
sleeper_list = sorted(
    ({"name": SLEEPER_LINKS.get(g, (g, ""))[0], "url": SLEEPER_LINKS.get(g, ("", ""))[1],
      "awake": up} for g, up in groups.items()),
    key=lambda x: (not x["awake"], x["name"].lower()))

# Paperclip
pending_approvals = 0
waiting = 0
last_checkin = None
if pc_ok == "1":
    for f in glob.glob(f"{tmp}/approvals-*"):
        try:
            d = json.load(open(f))
        except Exception:
            continue
        items = d if isinstance(d, list) else d.get("approvals", d.get("items", []))
        pending_approvals += sum(1 for a in items if a.get("status") == "pending")
    for f in glob.glob(f"{tmp}/issues-*"):
        try:
            d = json.load(open(f))
        except Exception:
            continue
        items = d if isinstance(d, list) else d.get("issues", d.get("items", []))
        waiting += sum(1 for i in items if i.get("status") == "in_review")
        if f.endswith(coach_company):
            for i in items:
                if "check-in" in (i.get("title") or "").lower():
                    c = i.get("createdAt")
                    if c and (last_checkin is None or c > last_checkin):
                        last_checkin = c

checkin = {"age": "never", "level": "warn"}
if last_checkin:
    ts = datetime.fromisoformat(last_checkin.replace("Z", "+00:00")).timestamp()
    checkin = age(ts, 26, 50)

def clean(line):
    line = re.sub(r"^#+\s*", "", line.strip())
    line = re.sub(r"[*_`]|\[(.*?)\]\(.*?\)", lambda m: m.group(1) or "", line)
    return line.strip(" -")

checkin_summary = []
try:
    d = json.load(open(f"{tmp}/checkin-comments"))
    items = d if isinstance(d, list) else d.get("comments", d.get("items", []))
    agent = sorted((c for c in items if c.get("authorType") == "agent"),
                   key=lambda c: c.get("createdAt", ""))
    if agent:
        raw = [l for l in (agent[-1].get("body") or "").splitlines() if l.strip()]
        # keep the title line, drop other markdown section headers
        is_header = lambda l: l.lstrip().startswith("#") or re.fullmatch(r"\s*\*\*[^*]+\*\*:?\s*", l)
        kept = raw[:1] + [l for l in raw[1:] if not is_header(l)]
        checkin_summary = [clean(l)[:140] for l in kept if clean(l)][:4]
except Exception:
    pass

# Training (TrainingPeaks cache)
try:
    tp = json.load(open(tp_cache))
except Exception:
    tp = {"ok": False, "error": "no TrainingPeaks data yet"}
training = {"ok": bool(tp.get("ok")), "error": tp.get("error", "")}
race = datetime(2027, 7, 11)
training["race_days"] = (race.date() - datetime.now().date()).days
if tp.get("ok"):
    f = tp.get("fitness", {})
    tsb = f.get("tsb")
    training["fitness"] = {"ctl": round(f.get("ctl") or 0), "atl": round(f.get("atl") or 0),
                           "tsb": round(tsb or 0), "status": f.get("fitness_status", ""),
                           "level": "ok" if tsb is None or tsb > -10 else "warn" if tsb > -25 else "bad"}
    series = {}
    for m in tp.get("metrics", []):
        for x in m.get("details", []):
            if isinstance(x.get("value"), (int, float)):
                series.setdefault(x["label"], []).append((x["time"][:10], x["value"]))
    def trend(label, digits=1):
        pts = sorted(series.get(label, []))
        if not pts:
            return {"now": "–", "delta": ""}
        now_d, now_v = pts[-1]
        cutoff = (datetime.fromisoformat(now_d) - timedelta(days=7)).date().isoformat()
        base = [v for d_, v in pts if d_ <= cutoff] or [pts[0][1]]
        delta = now_v - base[-1]
        return {"now": f"{now_v:.{digits}f}", "delta": f"{delta:+.{digits}f}"}
    training["weight"] = trend("Weight")
    training["fat"] = trend("Percent Fat")
    last = lambda label: (sorted(series.get(label, [])) or [("", None)])[-1][1]
    hrv, rhr, sleep = last("HRV"), last("Pulse"), last("Sleep Hours")
    training["recovery"] = (f"HRV {hrv:.0f}" if hrv else "HRV –") + " · " + \
        (f"RHR {rhr:.0f}" if rhr else "RHR –") + " · " + \
        (f"{int(sleep)}h{round((sleep % 1) * 60):02d} sleep" if sleep else "sleep –")
    wk = tp.get("week", {})
    ws = wk.get("workouts", [])
    real = [w for w in ws if w.get("sport") not in ("DayOff", None)]
    done = [w for w in real if w.get("type") == "completed" or w.get("duration_actual")]
    training["week"] = {"done": len(done), "planned": len(real),
                        "tss": round(wk.get("total_tss") or 0),
                        "hours": round(wk.get("total_duration_hours") or 0, 1)}
    today_iso = datetime.now().date().isoformat()
    todays = [w.get("title", "") for w in ws if w.get("date") == today_iso]
    training["today"] = ", ".join(todays) or "nothing planned"

today = re.sub(r"[*_`]", "", today_line).strip()
if len(today) > 160:
    today = today[:157].rstrip() + "…"

def host_stats():
    env = os.environ
    load = float(env.get("HS_LOAD") or 0)
    cores = int(env.get("HS_CORES") or 1)
    boot = int(env.get("HS_BOOT") or 0)
    up_h = (now - boot) / 3600 if boot else 0
    up = f"{up_h / 24:.0f}d" if up_h >= 48 else f"{up_h:.0f}h"
    cpu_pct = round(100 * load / cores)
    return {"load": round(load, 2), "cores": cores, "cpu_pct": cpu_pct,
            "cpu_level": level(cpu_pct, 70, 100), "uptime": up,
            "running": int(env.get("HS_RUNNING") or 0), "containers": int(env.get("HS_TOTAL") or 0)}

status = {
    "host": host_stats(),
    "updated": datetime.now().strftime("%H:%M"),
    "refresh_min": int(refresh_min),
    "memory": {"used_gb": round(used / 1024, 1), "total_gb": round(total / 1024, 1),
               "pct": mem_pct, "level": level(mem_pct, 80, 92)},
    "swap": {"used_gb": round(swap_used, 1), "total_gb": round(swap_total, 1),
             "pct": swap_pct, "level": level(swap_pct, 75, 90)},
    "disk": {"host_pct": int(disk_host), "host_level": level(int(disk_host), 85, 93),
             "nas_pct": int(disk_nas), "nas_level": level(int(disk_nas), 80, 90)},
    "backups": {
        "r2": age(r2_ts, 26, 50, ok=r2_ok == "1"),
        "db": age(db_ts, 8 * 24, 15 * 24),
        "t5": age(t5_ts, 35 * 24, 60 * 24),
        "t7": age(t7_ts, 35 * 24, 60 * 24),
    },
    "sleepers": {"awake": len(awake), "total": len(groups), "names": ", ".join(awake) or "none",
                 "list": sleeper_list},
    "coach": {"today": today or "no nutrition note yet", "checkin": checkin,
              "summary": checkin_summary or ["no check-in comment yet"]},
    "training": training,
    "paperclip": {"reachable": pc_ok == "1", "approvals": pending_approvals,
                  "waiting": waiting,
                  "level": "bad" if pc_ok != "1" else "warn" if pending_approvals + waiting else "ok"},
}
print(json.dumps(status, ensure_ascii=False, indent=1))
PY

if python3 -m json.tool "$tmpdir/status.json" > /dev/null 2>&1; then
  mv "$tmpdir/status.json" "$OUT.tmp" && mv "$OUT.tmp" "$OUT"
  chmod 644 "$OUT"
else
  echo "$(date '+%F %T') status.json generation failed" >&2
  exit 1
fi

[[ "${1:-}" == "--print" ]] && cat "$OUT"
exit 0
