#!/usr/bin/env bash
# Rotate an Uptime Kuma push monitor's token and update the consumer's .env.
#
# Kuma 1.23 has no "Reset Token" button in the edit form, so the token is
# changed directly in kuma.db while the container is stopped (~10 s downtime).
# The new token is never printed.
#
# Usage: kuma-reset-push-token.sh ["Monitor Name"] [env-file] [VAR_NAME]
# Default: the "Rclone Backup" monitor → ~/services/rclone/.env HEARTBEAT_URL
set -euo pipefail

MONITOR="${1:-Rclone Backup}"
ENV_FILE="${2:-$HOME/services/rclone/.env}"
VAR="${3:-HEARTBEAT_URL}"
KUMA_DIR="$HOME/services/uptime-kuma"
DB="$KUMA_DIR/data/kuma.db"
BASE_URL="https://status.peciulevicius.com/api/push"

[ -f "$DB" ] || { echo "kuma.db not found at $DB" >&2; exit 1; }
[ -f "$ENV_FILE" ] || { echo "env file not found: $ENV_FILE" >&2; exit 1; }

count=$(sqlite3 "$DB" "select count(*) from monitor where type='push' and name='${MONITOR//\'/\'\'}';")
[ "$count" = "1" ] || { echo "expected 1 push monitor named '$MONITOR', found $count" >&2; exit 1; }

cp "$DB" "$DB.bak-$(date +%Y%m%d%H%M%S)"
token=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32 || true)

(cd "$KUMA_DIR" && docker compose stop >/dev/null)
sqlite3 "$DB" "update monitor set push_token='$token' where type='push' and name='${MONITOR//\'/\'\'}';"
(cd "$KUMA_DIR" && docker compose start >/dev/null)

tmp=$(mktemp)
grep -v "^${VAR}=" "$ENV_FILE" >"$tmp" || true
printf '%s=%s/%s\n' "$VAR" "$BASE_URL" "$token" >>"$tmp"
cat "$tmp" >"$ENV_FILE" && rm -f "$tmp"
chmod 600 "$ENV_FILE"

echo "Waiting for Kuma to come back…"
for _ in $(seq 1 30); do
  if curl -fsS "$BASE_URL/$token?status=up&msg=token-rotated" 2>/dev/null | grep -q '"ok":true'; then
    echo "✓ '$MONITOR' token rotated; $VAR updated in $ENV_FILE; test push accepted"
    unset token
    exit 0
  fi
  sleep 2
done
echo "✗ Kuma did not accept the new token within 60 s — check 'docker logs uptime_kuma'" >&2
exit 1
