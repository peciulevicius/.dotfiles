#!/usr/bin/env bash
# Game mode: give a game the whole Mac mini.
#
#   game-mode.sh watch    # launchd (KeepAlive): checks every POLL_SEC seconds,
#                         # so it reacts within ~2s of the game starting
#   game-mode.sh auto     # one check
#   game-mode.sh on|off   # by hand
#   game-mode.sh status
#
# STYLE=stop (default since 2026-10-16) quits Docker Desktop while a game runs
# and starts it again RESUME_AFTER_MIN minutes after the game closes. Pausing
# containers (STYLE=pause, the old behaviour) frees their CPU but not memory:
# the Docker VM keeps its ~8 GB of the 16 GB either way, and Liftoff still
# lagged until the owner quit Docker by hand. Containers come back on their
# own restart policies when Docker starts. Every service is offline while
# you play: Vaultwarden clients keep their offline vault, and DNS doesn't go
# through Pi-hole.
#
# The state file doubles as the "game mode is on" flag. docker-watchdog,
# heartbeat, nas-watchdog, the PR bot and the Paperclip crons check it and
# stand down, so nothing relaunches Docker or reports false failures.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

GAME_PATTERNS="${GAME_PATTERNS:-Liftoff|Uncrashed|VelociDrone}"
RESUME_AFTER_MIN="${RESUME_AFTER_MIN:-20}"
POLL_SEC="${POLL_SEC:-2}"
STYLE="${STYLE:-stop}"
PAUSE_LIST="${PAUSE_LIST:-paperclip studio-preview immich_server immich_machine_learning jellyfin audiobookshelf odysseus-odysseus-1 uptime_kuma strava-mcp trainingpeaks-mcp linkwarden nextcloud paperless}"
STATE="$HOME/.config/homelab/game-mode.state"
LAST_SEEN="$HOME/.config/homelab/game-mode.last-seen"

log() { echo "$(date '+%F %T') $*"; }

notify() {
  # shellcheck source=/dev/null
  source "$HOME/.dotfiles/scripts/lib/notify.sh" 2>/dev/null && notify_discord "$1" "$2" info reminders || true
}

# Match the process *name* only (no -f): matching full command lines fired on any
# command that merely mentioned "Liftoff" (a PR description, 2026-10-14).
game_running() { pgrep -i "^(${GAME_PATTERNS})" >/dev/null 2>&1; }

docker_up() { [[ "$(curl -s --max-time 3 --unix-socket "$HOME/.docker/run/docker.sock" http://localhost/_ping 2>/dev/null)" == "OK" ]]; }

pause_containers() {
  # Idempotent: pauses anything on the list still running, even if game mode
  # was already on (a stale state file left everything running on 2026-10-16).
  local running c
  running=$(docker ps --filter status=running --format '{{.Names}}' 2>/dev/null) || return 0
  for c in $PAUSE_LIST; do
    if grep -qx "$c" <<<"$running" && docker pause "$c" >/dev/null 2>&1; then
      grep -qx "$c" "$STATE" 2>/dev/null || echo "$c" >> "$STATE"
    fi
  done
}

turn_on() {
  local fresh=false
  [[ -f "$STATE" ]] || { mkdir -p "$(dirname "$STATE")"; : > "$STATE"; fresh=true; }
  if [[ "$STYLE" == "stop" ]]; then
    if docker_up || pgrep -qf "Docker.app/Contents/MacOS/com.docker.backend"; then
      grep -qx "@docker-stopped" "$STATE" || echo "@docker-stopped" >> "$STATE"
      docker desktop stop >/dev/null 2>&1 || osascript -e 'quit app "Docker Desktop"' >/dev/null 2>&1 || true
      log "game mode: Docker Desktop stopped"
      $fresh && notify "🎮 Game mode on" "Docker stopped while you play (all services offline). It starts again ${RESUME_AFTER_MIN} min after the game closes."
    fi
  else
    pause_containers
    $fresh && { log "game mode ON — paused: $(tr '\n' ' ' < "$STATE")"; notify "🎮 Game mode on" "Paused busy containers while you play. They resume ${RESUME_AFTER_MIN} min after the game closes."; }
  fi
  return 0
}

turn_off() {
  [[ -f "$STATE" ]] || return 0
  local c resumed=0
  if grep -qx "@docker-stopped" "$STATE"; then
    docker desktop start --detach >/dev/null 2>&1 || open -ga "Docker" || true
    log "game mode OFF — Docker Desktop starting"
    notify "🎮 Game mode off" "Docker is starting again; services are back in a minute or two."
  fi
  while IFS= read -r c; do
    [[ -z "$c" || "$c" == @* ]] && continue
    docker unpause "$c" >/dev/null 2>&1 && resumed=$((resumed + 1)) || true
  done < "$STATE"
  rm -f "$STATE" "$LAST_SEEN"
  (( resumed > 0 )) && { log "game mode OFF — resumed $resumed"; notify "🎮 Game mode off" "Resumed $resumed containers."; }
  return 0
}

check() {
  if game_running; then
    date +%s > "$LAST_SEEN"
    turn_on
  elif [[ -f "$STATE" ]]; then
    last=$(cat "$LAST_SEEN" 2>/dev/null || echo 0)
    if (( $(date +%s) - last >= RESUME_AFTER_MIN * 60 )); then
      turn_off
    fi
  fi
}

case "${1:-status}" in
  auto) check ;;
  watch)
    # launchd keeps this running (KeepAlive); pgrep every 2s costs ~nothing.
    while true; do
      check || true
      sleep "$POLL_SEC"
    done
    ;;
  on) date +%s > "$LAST_SEEN"; turn_on ;;
  off) turn_off ;;
  status)
    if [[ -f "$STATE" ]]; then
      echo "game mode ON — paused: $(tr '\n' ' ' < "$STATE")"
      game_running && echo "a game is running" || echo "no game running (resumes ${RESUME_AFTER_MIN} min after it closed)"
    else
      echo "game mode off"
    fi
    ;;
  *) echo "usage: $0 watch|auto|on|off|status" >&2; exit 2 ;;
esac
