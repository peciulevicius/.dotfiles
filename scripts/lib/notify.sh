#!/bin/bash
# Discord notifications for cron jobs. Source this, don't run it.
#
#   source ~/.dotfiles/scripts/lib/notify.sh
#   notify_discord "Backup failed" "linkwarden dump returned 1" error
#
# The webhook lives in ~/.config/homelab/notify.env, outside this repo:
#
#   DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
#
# Use the same webhook Uptime Kuma posts to (Uptime Kuma → Settings →
# Notifications → the Discord entry) so service alerts and job alerts land in
# one channel. If the file is missing, every notify_* call is a silent no-op —
# jobs must never fail just because notifications aren't configured.

NOTIFY_ENV_FILE="${NOTIFY_ENV_FILE:-$HOME/.config/homelab/notify.env}"

if [[ -f "$NOTIFY_ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$NOTIFY_ENV_FILE"
fi

# notify_discord <title> <message> [level]
# level: info (blue, default) | ok (green) | warn (amber) | error (red)
notify_discord() {
  local title="$1"
  local message="$2"
  local level="${3:-info}"

  [[ -z "${DISCORD_WEBHOOK_URL:-}" ]] && return 0

  local colour
  case "$level" in
    ok)    colour=3066993  ;;  # green
    warn)  colour=16098851 ;;  # amber
    error) colour=15158332 ;;  # red
    *)     colour=3447003  ;;  # blue
  esac

  # Discord embed descriptions cap at 4096 chars; leave room for the code fence
  local trimmed
  trimmed="$(printf '%s' "$message" | tail -c 3800)"

  local payload
  payload=$(python3 -c '
import json, sys
title, desc, colour, host = sys.argv[1:5]
print(json.dumps({"embeds": [{
    "title": title,
    "description": "```\n" + desc + "\n```" if desc else "",
    "color": int(colour),
    "footer": {"text": host},
}]}))' "$title" "$trimmed" "$colour" "$(scutil --get ComputerName 2>/dev/null || hostname)")

  curl -sS -m 15 -H "Content-Type: application/json" \
       -X POST -d "$payload" "$DISCORD_WEBHOOK_URL" >/dev/null 2>&1 || true
}
