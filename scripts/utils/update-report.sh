#!/bin/bash
# Summarise which containers have a newer image, from WUD (services/wud).
#
#   update-report.sh              # write the Glance JSON, print a table
#   update-report.sh --discord    # same, plus post the summary to Discord
#   update-report.sh --markdown   # print a Markdown table (for the TODO list)
#
# Cron (scripts/cron/crontab): daily 06:30 (after WUD's 06:00 registry check)
# for the Glance widget; Mondays 09:00 with --discord for the weekly summary.
#
# Buckets:
#   safe  — patch/minor bump (or same-tag digest refresh): a candidate for
#           scripts/utils/upgrade-service.sh
#   major — major version: read the release notes first
#   held  — listed in services/wud/holds.tsv (DB majors, known false
#           positives); shown collapsed, never offered as an upgrade
# Digest-only refreshes of floating tags (`latest`, `release`) are left to
# Watchtower's nightly run and not counted.
#
# WUD 9 needs a login: ~/.config/homelab/wud.env (WUD_USER, WUD_PASSWORD,
# chmod 600). Read into the Python process only, never printed.
#
# Output: ~/services/glance/assets/updates.json (Glance serves /assets/; the
# "Updates" widget reads it, so Glance never needs the WUD login).

set -uo pipefail

WUD_URL="${WUD_URL:-http://127.0.0.1:3070}"
WUD_ENV="$HOME/.config/homelab/wud.env"
HOLDS="${HOLDS:-$HOME/.dotfiles/services/wud/holds.tsv}"
OUT_DIR="${OUT_DIR:-$HOME/services/glance/assets}"
OUT="$OUT_DIR/updates.json"
MODE="${1:-}"

mkdir -p "$OUT_DIR"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

WUD_URL="$WUD_URL" WUD_ENV="$WUD_ENV" HOLDS="$HOLDS" MODE="$MODE" \
python3 - > "$tmp" <<'PY'
import base64, json, os, sys, urllib.request
from datetime import datetime

creds = {}
try:
    for line in open(os.environ["WUD_ENV"]):
        k, _, v = line.strip().partition("=")
        if k:
            creds[k] = v
except FileNotFoundError:
    pass

holds = {}
try:
    for line in open(os.environ["HOLDS"]):
        if line.strip() and not line.startswith("#"):
            name, _, reason = line.rstrip("\n").partition("\t")
            holds[name.strip()] = reason.strip()
except FileNotFoundError:
    pass

out = {"updated": datetime.now().strftime("%Y-%m-%d %H:%M"), "ok": False,
       "error": None, "safe": [], "major": [], "held": []}
try:
    req = urllib.request.Request(os.environ["WUD_URL"] + "/api/containers")
    token = base64.b64encode(f'{creds.get("WUD_USER","")}:{creds.get("WUD_PASSWORD","")}'.encode()).decode()
    req.add_header("Authorization", "Basic " + token)
    containers = json.load(urllib.request.urlopen(req, timeout=20))
    out["ok"] = True
except Exception as e:  # WUD down or login wrong: the widget says so
    out["error"] = f"WUD unreachable ({type(e).__name__})"
    containers = []

for c in containers:
    if not c.get("updateAvailable"):
        continue
    kind = (c.get("updateKind") or {})
    diff = kind.get("semverDiff") or kind.get("kind") or "?"
    current = ((c.get("image") or {}).get("tag") or {}).get("value", "?")
    available = (c.get("result") or {}).get("tag", "?")
    if diff == "digest":
        continue  # floating tag refresh → Watchtower's job
    item = {"name": c.get("name"), "service": (c.get("labels") or {}).get("com.docker.compose.project", ""),
            "current": current, "available": available, "kind": diff}
    if item["name"] in holds:
        item["reason"] = holds[item["name"]]
        out["held"].append(item)
    elif diff == "major":
        out["major"].append(item)
    else:
        out["safe"].append(item)

for k in ("safe", "major", "held"):
    out[k].sort(key=lambda i: i["name"])
out["counts"] = {k: len(out[k]) for k in ("safe", "major", "held")}
print(json.dumps(out, indent=1))
PY

if ! python3 -m json.tool "$tmp" >/dev/null 2>&1; then
  echo "$(date '+%F %T') updates.json generation failed" >&2
  exit 1
fi
cp "$tmp" "$OUT.tmp" && mv "$OUT.tmp" "$OUT" && chmod 644 "$OUT"

table=$(python3 - "$OUT" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
if not d["ok"]:
    print(d["error"]); sys.exit()
for bucket, label in (("safe", "Safe (patch/minor)"), ("major", "Major — read release notes"), ("held", "Held")):
    rows = d[bucket]
    print(f"{label}: {len(rows)}")
    for r in rows:
        extra = f"  ({r['reason']})" if bucket == "held" else ""
        print(f"  {r['name']:<24} {r['current']} → {r['available']}{extra}")
PY
)

case "$MODE" in
  --markdown)
    python3 - "$OUT" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print("| Container | Service | Current | Available | Kind | Note |")
print("|---|---|---|---|---|---|")
for bucket in ("safe", "major", "held"):
    for r in d[bucket]:
        note = r.get("reason", "") if bucket == "held" else ("upgrade-service.sh" if bucket == "safe" else "read release notes")
        print(f"| {r['name']} | {r['service']} | `{r['current']}` | `{r['available']}` | {r['kind']} | {note} |")
PY
    ;;
  --discord)
    echo "$table"
    # shellcheck source=/dev/null
    source "$HOME/.dotfiles/scripts/lib/notify.sh"
    notify_discord "🐳 Weekly image updates" \
      "$table"$'\n\n'"Upgrade one: upgrade-service.sh <service> <tag>" info updates
    ;;
  *) echo "$table" ;;
esac
