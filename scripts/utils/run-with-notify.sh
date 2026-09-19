#!/bin/bash
# Run a cron job and tell Discord when it breaks — and when it recovers.
#
#   run-with-notify.sh <label> <command> [args...]
#
# Example crontab line:
#   0 4 * * 0 ~/.dotfiles/scripts/utils/run-with-notify.sh "DB backup" \
#             ~/.dotfiles/scripts/backup/backup-databases.sh
#
# Why this exists: the Kindle sync failed every hour for ~73 days and the DB
# dumps for linkwarden and nextcloud had never once succeeded. Both wrote their
# errors to a log file nobody reads. A job that fails silently is a job you do
# not have.
#
# It notifies on *transitions*, not on every failure, so an hourly job that
# breaks sends one message rather than 24 a day:
#
#   ok    -> fail   "X is failing"      (plus the output)
#   fail  -> fail   nothing, until REMIND_HOURS has passed, then a reminder
#   fail  -> ok     "X recovered"
#
# The job's own output still goes to stdout/stderr, so existing `>> log` cron
# redirections keep working unchanged.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/../lib/notify.sh"

STATE_DIR="${STATE_DIR:-$HOME/.local/state/homelab-jobs}"
REMIND_HOURS="${REMIND_HOURS:-24}"

if [[ $# -lt 2 ]]; then
  echo "Usage: $(basename "$0") <label> <command> [args...]" >&2
  exit 2
fi

LABEL="$1"
shift

mkdir -p "$STATE_DIR"
SLUG="$(printf '%s' "$LABEL" | tr -c '[:alnum:]' '-' | tr -s '-' | sed 's/^-//;s/-$//')"
STATE_FILE="$STATE_DIR/$SLUG.state"

OUTPUT_FILE="$(mktemp)"
trap 'rm -f "$OUTPUT_FILE"' EXIT

# Run it, showing output live and keeping a copy for the notification
"$@" > >(tee "$OUTPUT_FILE") 2> >(tee -a "$OUTPUT_FILE" >&2)
STATUS=$?
wait

PREV_STATUS="ok"
PREV_NOTIFIED=0
if [[ -f "$STATE_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$STATE_FILE"
fi

now=$(date +%s)

if [[ $STATUS -ne 0 ]]; then
  should_notify=false
  if [[ "$PREV_STATUS" == "ok" ]]; then
    should_notify=true                       # just broke
  elif (( now - PREV_NOTIFIED >= REMIND_HOURS * 3600 )); then
    should_notify=true                       # still broken, time to nag again
  fi

  if [[ "$should_notify" == "true" ]]; then
    notify_discord "❌ $LABEL failed (exit $STATUS)" "$(cat "$OUTPUT_FILE")" error
    PREV_NOTIFIED=$now
  fi
  printf 'PREV_STATUS=fail\nPREV_NOTIFIED=%s\n' "$PREV_NOTIFIED" > "$STATE_FILE"
else
  if [[ "$PREV_STATUS" == "fail" ]]; then
    notify_discord "✅ $LABEL recovered" "$(tail -c 1000 "$OUTPUT_FILE")" ok
  fi
  printf 'PREV_STATUS=ok\nPREV_NOTIFIED=0\n' > "$STATE_FILE"
fi

exit $STATUS
