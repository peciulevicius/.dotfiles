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
# The Paperclip board password is read from ~/.config/homelab/paperclip-admin.env
# into a variable, sent only to the local Paperclip API, and never written out.

set -uo pipefail

OUT_DIR="${OUT_DIR:-$HOME/services/glance/assets}"
OUT="$OUT_DIR/status.json"
PAPERCLIP="${PAPERCLIP_URL:-http://127.0.0.1:3100}"
PAPERCLIP_EMAIL="${PAPERCLIP_EMAIL:-dziugas@peciulevicius.com}"
PAPERCLIP_ENV="$HOME/.config/homelab/paperclip-admin.env"
COACH_COMPANY="31472664-4bfe-4bd1-9313-19d0739378d2"

mkdir -p "$OUT_DIR"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# ── Memory: Docker VM used vs limit, macOS swap ─────────────────────────────
docker_total=$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo 0)
docker stats --no-stream --format '{{.MemUsage}}' 2>/dev/null | awk '{print $1}' > "$tmpdir/mem" || true
swap_line=$(sysctl -n vm.swapusage 2>/dev/null || echo "")

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
today_line=$(grep -v -e '^#' -e '^[[:space:]]*$' "$HOME/.training/nutrition/today.md" 2>/dev/null | head -1)

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
    curl -fsS -m 10 -b "$jar" -H "Origin: $PAPERCLIP" -H 'Content-Type: application/json' \
      -X POST "$PAPERCLIP/api/auth/sign-out" -d '{}' -o /dev/null 2>/dev/null || true
  fi
  unset pw
fi

# ── Assemble ───────────────────────────────────────────────────────────────
python3 - "$tmpdir" "$docker_total" "$swap_line" "${disk_host:-0}" "${disk_nas:-0}" \
  "$r2_ok" "$r2_ts" "$db_ts" "$t5_ts" "$t7_ts" "$today_line" "$pc_ok" "$COACH_COMPANY" \
  > "$tmpdir/status.json" <<'PY'
import glob, json, os, re, sys, time
from datetime import datetime, timezone

(tmp, docker_total, swap_line, disk_host, disk_nas, r2_ok, r2_ts, db_ts,
 t5_ts, t7_ts, today_line, pc_ok, coach_company) = sys.argv[1:]
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

today = re.sub(r"[*_`]", "", today_line).strip()
if len(today) > 160:
    today = today[:157].rstrip() + "…"

status = {
    "updated": datetime.now().strftime("%H:%M"),
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
    "sleepers": {"awake": len(awake), "total": len(groups), "names": ", ".join(awake) or "none"},
    "coach": {"today": today or "no nutrition note yet", "checkin": checkin},
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
