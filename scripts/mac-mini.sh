#!/bin/bash
#
# Mac mini management script.
#
# Usage:
#   scripts/mac-mini.sh sleep off   # server mode: disable sleep (run on first boot)
#   scripts/mac-mini.sh sleep on    # normal mode: re-enable sleep
#   scripts/mac-mini.sh setup       # one-time Immich setup (run after drives are ready)

set -uo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_CONFIG="$HOME/.config/dotfiles/mac-mini.conf"

log_ok()     { echo -e "${GREEN}✓${NC} $1"; }
log_warn()   { echo -e "${YELLOW}⚠${NC} $1"; }
log_error()  { echo -e "${RED}✗${NC} $1"; }
log_header() {
  echo -e "\n${BLUE}========================================${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}========================================${NC}"
}

# -------------------------------------------------------
# sleep off — server mode (no sleep, auto-restart)
# -------------------------------------------------------
cmd_sleep_off() {
  log_header "Server Mode — Disabling Sleep"
  sudo pmset -a sleep 0 disksleep 0 displaysleep 10
  sudo systemsetup -setrestartpowerfailure on
  log_ok "Machine will never sleep (screen turns off after 10 min)"
  log_ok "Auto-restart after power failure enabled"
}

# -------------------------------------------------------
# sleep on — normal mode
# -------------------------------------------------------
cmd_sleep_on() {
  log_header "Normal Mode — Re-enabling Sleep"
  sudo pmset -a sleep 1
  log_ok "Normal sleep restored"
}

# -------------------------------------------------------
# setup — one-time Immich setup (run after drives are ready)
# -------------------------------------------------------
cmd_setup() {
  log_header "Immich Setup"

  echo "Connected volumes (ls /Volumes/):"
  ls /Volumes/
  echo ""
  echo "The T7 volume name is whatever macOS named your T7 drive when it was formatted."
  echo "It appears in the list above — e.g. 'Samsung T7', 'T7 Touch', 'MyDrive', etc."
  echo ""
  read -r -p "Enter the T7 volume name exactly as shown above: " T7_NAME

  if [ ! -d "/Volumes/$T7_NAME" ]; then
    log_error "/Volumes/$T7_NAME not found. Check the name and rerun."
    exit 1
  fi

  # Save volume name so backup-immich.sh can read it without asking
  mkdir -p "$(dirname "$LOCAL_CONFIG")"
  cat > "$LOCAL_CONFIG" <<EOF
# Mac mini local config — written by mac-mini.sh setup
# Not committed to git.
IMMICH_VOLUME="$T7_NAME"
EOF
  log_ok "Volume name saved to $LOCAL_CONFIG"

  # Create folders
  mkdir -p "/Volumes/$T7_NAME/immich"
  mkdir -p ~/services/immich
  mkdir -p ~/logs
  log_ok "Folders created"

  # Copy docker-compose.yml with volume name substituted
  local compose_src="$DOTFILES_DIR/config/immich/docker-compose.yml"
  local compose_dst="$HOME/services/immich/docker-compose.yml"

  if [ -f "$compose_dst" ]; then
    log_warn "~/services/immich/docker-compose.yml already exists — skipping"
  else
    sed "s|{{IMMICH_VOLUME}}|$T7_NAME|g" "$compose_src" > "$compose_dst"
    log_ok "docker-compose.yml written to ~/services/immich/"
  fi

  # Copy .env.example → .env if not already present
  local env_src="$DOTFILES_DIR/config/immich/.env.example"
  local env_dst="$HOME/services/immich/.env"

  if [ -f "$env_dst" ]; then
    log_warn "~/services/immich/.env already exists — skipping"
  else
    cp "$env_src" "$env_dst"
    log_ok ".env copied to ~/services/immich/"
    log_warn "Edit ~/services/immich/.env and set DB_PASSWORD before starting Immich"
  fi

  log_header "Done — next steps"
  echo "  1) nano ~/services/immich/.env   (set DB_PASSWORD)"
  echo "  2) cd ~/services/immich && docker compose up -d"
  echo "  3) Open http://<tailscale-ip>:2283 to create your Immich account"
}

# -------------------------------------------------------
# Usage
# -------------------------------------------------------
usage() {
  echo ""
  echo "Usage: scripts/mac-mini.sh <command>"
  echo ""
  echo "Commands:"
  echo "  sleep off   Disable sleep — server/always-on mode (run on first boot)"
  echo "  sleep on    Re-enable normal sleep"
  echo "  setup       One-time Immich setup (run after drives are connected)"
  echo ""
}

# -------------------------------------------------------
# Main
# -------------------------------------------------------
case "${1:-}" in
  sleep)
    case "${2:-}" in
      on)  cmd_sleep_on ;;
      off) cmd_sleep_off ;;
      *)   echo "Usage: mac-mini.sh sleep on|off"; exit 1 ;;
    esac
    ;;
  setup) cmd_setup ;;
  *)     usage ;;
esac
