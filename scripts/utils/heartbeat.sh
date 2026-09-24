#!/bin/bash
# Dead-man's switch: ping an external monitor (Healthchecks.io) every few
# minutes. The alert fires on *their* servers when the pings stop.
#
#   heartbeat.sh            # ping (or report failure) — run from cron every 5 min
#   heartbeat.sh --test     # ping once and print the result
#
# Cron (see scripts/cron/crontab):
#   */5 * * * * ~/.dotfiles/scripts/utils/heartbeat.sh >> ~/logs/heartbeat.log 2>&1
#
# Why: every other alert here (Uptime Kuma, run-with-notify → Discord) runs on
# this Mac mini. On 2026-09-22 a power cut took the whole house down and
# nothing could say so, because the alerter was off too. This is the inverse:
# silence is the alarm, and it is raised from outside the network.
#
# It also covers the second blind spot: when Docker stops responding, Uptime
# Kuma (a container) goes with it. In that case the ping is sent to /fail, so
# the external monitor alerts immediately instead of staying green.
#
# Configuration, outside the repo (the URL lets anyone fake a heartbeat):
#   ~/.config/homelab/heartbeat.env
#     HEARTBEAT_PING_URL=https://hc-ping.com/<uuid>
#
# Deliberately NOT wrapped in run-with-notify.sh: a missing URL is reported by
# the weekly homelab-audit instead of every five minutes.

set -uo pipefail

CONFIG="${HEARTBEAT_CONFIG:-$HOME/.config/homelab/heartbeat.env}"
STATE_DIR="${STATE_DIR:-$HOME/.local/state/homelab-jobs}"
LAST_OK="$STATE_DIR/heartbeat.last"
DOCKER_TIMEOUT=20

TEST=false
[[ "${1:-}" == "--test" ]] && TEST=true

if [[ ! -f "$CONFIG" ]]; then
  echo "$(date '+%F %T') heartbeat: $CONFIG missing — external monitoring is OFF" >&2
  exit 1
fi
# shellcheck disable=SC1090
source "$CONFIG"
if [[ -z "${HEARTBEAT_PING_URL:-}" ]]; then
  echo "$(date '+%F %T') heartbeat: HEARTBEAT_PING_URL not set in $CONFIG" >&2
  exit 1
fi

# macOS has no `timeout`; run docker info in the background and kill it if it
# hangs — a hung engine is exactly the case being detected.
docker_ok() {
  command -v docker >/dev/null 2>&1 || return 1
  docker info >/dev/null 2>&1 &
  local pid=$! waited=0
  while kill -0 "$pid" 2>/dev/null; do
    if (( waited >= DOCKER_TIMEOUT )); then
      kill "$pid" 2>/dev/null
      return 1
    fi
    sleep 1
    waited=$((waited + 1))
  done
  wait "$pid"
}

problems=()
docker_ok || problems+=("Docker engine not responding within ${DOCKER_TIMEOUT}s (Uptime Kuma is down with it)")

url="$HEARTBEAT_PING_URL"
body="host=$(hostname -s) uptime=$(uptime | sed 's/^ *//')"
if (( ${#problems[@]} > 0 )); then
  url="$HEARTBEAT_PING_URL/fail"
  body="$(printf '%s\n' "${problems[@]}")"$'\n'"$body"
fi

if curl -fsS -m 10 --retry 3 --data-raw "$body" "$url" >/dev/null; then
  mkdir -p "$STATE_DIR"
  date +%s > "$LAST_OK"
  if [[ "$TEST" == "true" ]]; then
    # never print the URL itself — it is the credential
    if (( ${#problems[@]} > 0 )); then echo "sent: fail — ${problems[*]}"; else echo "sent: ok"; fi
  fi
  (( ${#problems[@]} == 0 )) || echo "$(date '+%F %T') heartbeat: reported failure — ${problems[*]}" >&2
  exit 0
fi

echo "$(date '+%F %T') heartbeat: could not reach the monitor (network down?)" >&2
exit 1
