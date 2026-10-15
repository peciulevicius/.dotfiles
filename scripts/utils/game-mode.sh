#!/usr/bin/env bash
# Game mode: free the Mac mini's CPU for a game by pausing busy containers.
#
#   game-mode.sh auto     # cron, every minute: on while a game runs, off
#                         # RESUME_AFTER_MIN after the last game process exits
#   game-mode.sh on|off   # by hand
#   game-mode.sh status
#
# `docker pause` freezes a container (no CPU) without stopping it; `unpause`
# resumes it exactly where it was. Essentials (DNS, Vaultwarden, Caddy/Sablier,
# Glance, the Discord bridge) are never paused. The state file lists what this
# script paused and doubles as the "game mode is on" flag that Paperclip crons
# check so they don't report false failures.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

GAME_PATTERNS="${GAME_PATTERNS:-Liftoff|Uncrashed|VelociDrone}"
RESUME_AFTER_MIN="${RESUME_AFTER_MIN:-20}"
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

turn_on() {
  [[ -f "$STATE" ]] && return 0
  local running paused=()
  running=$(docker ps --filter status=running --format '{{.Names}}')
  for c in $PAUSE_LIST; do
    if grep -qx "$c" <<<"$running" && docker pause "$c" >/dev/null 2>&1; then
      paused+=("$c")
    fi
  done
  mkdir -p "$(dirname "$STATE")"
  printf '%s\n' "${paused[@]+"${paused[@]}"}" > "$STATE"
  log "game mode ON — paused: ${paused[*]:-none}"
  notify "🎮 Game mode on" "Paused ${#paused[@]} containers (agents, Immich, media) while you play. They resume ${RESUME_AFTER_MIN} min after the game closes."
}

turn_off() {
  [[ -f "$STATE" ]] || return 0
  local c resumed=0
  while IFS= read -r c; do
    [[ -z "$c" ]] && continue
    docker unpause "$c" >/dev/null 2>&1 && resumed=$((resumed + 1)) || true
  done < "$STATE"
  rm -f "$STATE" "$LAST_SEEN"
  log "game mode OFF — resumed $resumed"
  notify "🎮 Game mode off" "Resumed $resumed containers."
}

case "${1:-status}" in
  auto)
    if game_running; then
      date +%s > "$LAST_SEEN"
      turn_on
    elif [[ -f "$STATE" ]]; then
      last=$(cat "$LAST_SEEN" 2>/dev/null || echo 0)
      if (( $(date +%s) - last >= RESUME_AFTER_MIN * 60 )); then
        turn_off
      fi
    fi
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
  *) echo "usage: $0 auto|on|off|status" >&2; exit 2 ;;
esac
