#!/bin/bash
# Discord notifications for cron jobs. Source this, don't run it.
#
#   source ~/.dotfiles/scripts/lib/notify.sh
#   notify_discord "Backup failed" "linkwarden dump returned 1" error
#
# The webhook lives in ~/.config/homelab/notify.env, outside this repo:
#
#   DISCORD_JOBS_WEBHOOK_URL=https://discord.com/api/webhooks/...
#   DISCORD_AGENTS_WEBHOOK_URL=https://discord.com/api/webhooks/...
#   DISCORD_REMINDERS_WEBHOOK_URL=https://discord.com/api/webhooks/...
#
# Keep Kuma's webhook separate. DISCORD_WEBHOOK_URL is a legacy jobs fallback
# during migration; every payload sets its own sender name. If no webhook is
# configured, every notify_* call is a silent no-op —
# jobs must never fail just because notifications aren't configured.

NOTIFY_ENV_FILE="${NOTIFY_ENV_FILE:-$HOME/.config/homelab/notify.env}"

if [[ -f "$NOTIFY_ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$NOTIFY_ENV_FILE"
fi

# notify_discord <title> <message> [level] [route]
# level: info (blue, default) | ok (green) | warn (amber) | error (red)
# route: jobs (default) | agents | reminders | updates
notify_discord() {
  local title="$1"
  local message="$2"
  local level="${3:-info}"
  local route="${4:-jobs}"
  local jobs_webhook="${DISCORD_JOBS_WEBHOOK_URL:-${DISCORD_WEBHOOK_URL:-}}"
  local webhook username
  case "$route" in
    jobs) webhook="$jobs_webhook"; username="Homelab Jobs" ;;
    agents) webhook="${DISCORD_AGENTS_WEBHOOK_URL:-$jobs_webhook}"; username="Paperclip" ;;
    reminders) webhook="${DISCORD_REMINDERS_WEBHOOK_URL:-$jobs_webhook}"; username="Homelab Reminders" ;;
    updates) webhook="${DISCORD_UPDATES_WEBHOOK_URL:-$jobs_webhook}"; username="Homelab Updates" ;;
    *) return 0 ;;
  esac

  [[ -z "$webhook" ]] && return 0

  local colour
  case "$level" in
    ok)    colour=3066993  ;;  # green
    warn)  colour=16098851 ;;  # amber
    error) colour=15158332 ;;  # red
    *)     colour=3447003  ;;  # blue
  esac

  local payload
  payload=$(python3 -c '
import json, sys
title, desc, colour, host, username = sys.argv[1:6]
desc = desc[-3800:]
print(json.dumps({"username": username, "allowed_mentions": {"parse": []}, "embeds": [{
    "title": title[:256],
    "description": "```\n" + desc + "\n```" if desc else "",
    "color": int(colour),
    "footer": {"text": host},
}]}))' "$title" "$message" "$colour" "$(scutil --get ComputerName 2>/dev/null || hostname)" "$username")

  curl -sS -m 15 -H "Content-Type: application/json" \
       -X POST -d "$payload" "$webhook" >/dev/null 2>&1 || true
}
