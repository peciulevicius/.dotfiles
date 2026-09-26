#!/bin/bash
# Weekly reports feed for the Paperclip "Homelab" company.
#
#   paperclip-reports.sh            # write ~/services/paperclip/reports/latest.md
#
# Cron (Sunday 09:30, after the 09:00 homelab audit; see scripts/cron/crontab):
#   30 9 * * 0 ~/.dotfiles/scripts/utils/run-with-notify.sh "Paperclip reports" \
#              ~/.dotfiles/scripts/utils/paperclip-reports.sh >> ~/logs/paperclip-reports.log 2>&1
#
# The directory is mounted READ-ONLY into the paperclip container at /reports
# (not under /paperclip — see the compose file for why). The agents there only
# read these files and raise decisions; they never touch the servers. That split is the whole point:
# the host decides what the agents may see, and the agents get no shell here.
#
# What goes in: audit output, backup log tail, container list, disk/memory,
# Uptime Kuma last status per monitor, and the TODO index. What must NEVER go
# in: .env contents, tokens, passwords, webhook URLs. Nothing below reads a
# .env file, and a final redaction pass blanks anything shaped like key=value
# for secret-ish keys as a backstop.

set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${PAPERCLIP_REPORTS_DIR:-$HOME/services/paperclip/reports}"
KUMA_DB="$HOME/services/uptime-kuma/data/kuma.db"
KEEP_WEEKS=8
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

mkdir -p "$OUT_DIR"
stamp="$(date +%Y-%m-%d)"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

section() { printf '\n## %s\n\n```text\n' "$1"; }
end_section() { printf '```\n'; }

{
  echo "# Homelab weekly feed — $stamp"
  echo ""
  echo "Generated $(date '+%Y-%m-%d %H:%M %Z') on $(hostname -s) by scripts/utils/paperclip-reports.sh."
  echo "Read-only snapshot. Kuma times are UTC."

  section "1. Homelab audit (scripts/utils/homelab-audit.sh, run now)"
  "$DOTFILES/scripts/utils/homelab-audit.sh" 2>&1 | tail -n 150
  echo "(audit exit code: ${PIPESTATUS[0]} — 0 = clean, 1 = something needs attention)"
  end_section

  section "2. Last cloud backup log (tail)"
  last_log="$(ls "$HOME"/logs/rclone-2*.log 2>/dev/null | sort | tail -n 1)"
  if [[ -n "$last_log" ]]; then
    echo "file: $(basename "$last_log")"
    grep -v -E '^\s*$' "$last_log" | tail -n 40
  else
    echo "no rclone log found in ~/logs"
  fi
  end_section

  section "3. Containers (docker ps -a)"
  docker ps -a --format '{{.Names}}\t{{.Status}}' 2>&1 | sort
  echo ""
  echo "Top memory users:"
  docker stats --no-stream --format '{{.Name}}\t{{.MemUsage}}' 2>&1 | sort -k2 -h -r | head -n 12
  end_section

  section "4. Disk and memory"
  df -h / /System/Volumes/Data 2>/dev/null
  df -h 2>/dev/null | grep -E '/Volumes/' || true
  echo ""
  memory_pressure 2>/dev/null | tail -n 1
  sysctl vm.swapusage 2>/dev/null
  end_section

  section "5. Uptime Kuma — last status per active monitor"
  if [[ -f "$KUMA_DB" ]]; then
    sqlite3 -readonly -separator ' | ' "$KUMA_DB" "
      SELECT m.name,
             CASE h.status WHEN 1 THEN 'UP' WHEN 0 THEN 'DOWN' WHEN 2 THEN 'PENDING'
                           WHEN 3 THEN 'MAINTENANCE' ELSE 'NO DATA' END,
             h.time
      FROM monitor m
      LEFT JOIN heartbeat h ON h.id = (
        SELECT id FROM heartbeat WHERE monitor_id = m.id ORDER BY time DESC LIMIT 1)
      WHERE m.active = 1
      ORDER BY 2, 1;" 2>&1
  else
    echo "kuma.db not found"
  fi
  end_section

  printf '\n## 6. Open TODO index (docs/HOME_SERVER_TODO.md)\n\n'
  awk '/^## 🧭/{on=1; next} on && /^## /{exit} on' "$DOTFILES/docs/HOME_SERVER_TODO.md"
} > "$tmp"

# Backstop redaction: blank values of secret-looking keys (KEY=..., "token": ...).
perl -pe '
  s/\e\[[0-9;]*m//g;
  s/((?:password|passwd|secret|token|api[_-]?key|webhook)\w*["\x27]?\s*[=:]\s*)\S+/$1\[REDACTED\]/gi;
  s{https://discord(?:app)?\.com/api/webhooks/\S+}{[REDACTED-WEBHOOK]}g;
' "$tmp" > "$OUT_DIR/weekly-$stamp.md"
cp "$OUT_DIR/weekly-$stamp.md" "$OUT_DIR/latest.md"
chmod 644 "$OUT_DIR/weekly-$stamp.md" "$OUT_DIR/latest.md"

# Keep ~2 months of history for week-over-week comparison.
find "$OUT_DIR" -name 'weekly-*.md' -mtime +$((KEEP_WEEKS * 7)) -delete

echo "$(date '+%Y-%m-%d %H:%M:%S') wrote $OUT_DIR/weekly-$stamp.md ($(wc -l < "$OUT_DIR/latest.md") lines)"
