#!/bin/bash
#
# Mac mini management script.
#
# Usage:
#   scripts/mac-mini.sh sleep off        # server mode: disable sleep (run on first boot)
#   scripts/mac-mini.sh sleep on         # normal mode: re-enable sleep
#   scripts/mac-mini.sh services up      # start all Docker services
#   scripts/mac-mini.sh services down    # stop all Docker services
#   scripts/mac-mini.sh services restart # restart all Docker services
#   scripts/mac-mini.sh services status  # show running services
#   scripts/mac-mini.sh cleanup          # free disk space (downloads, Docker cache)
#   scripts/mac-mini.sh disk             # show disk usage summary
#   scripts/mac-mini.sh ssh on           # enable remote login (SSH)
#   scripts/mac-mini.sh immich-setup     # one-time Immich setup (run after drives are ready)

set -uo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_CONFIG="$HOME/.config/dotfiles/mac-mini.conf"
SERVICES_DIR="$HOME/services"
MEDIA_DIR="/Volumes/T7/media"

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
# services up|down|restart|status — manage all Docker services
# -------------------------------------------------------
cmd_services() {
  local action="${1:-}"

  if [[ ! -d "$SERVICES_DIR" ]]; then
    log_error "Services directory not found: $SERVICES_DIR"
    exit 1
  fi

  local failed=0
  local succeeded=0

  case "$action" in
    up|down|restart)
      log_header "Services ${action}"
      for dir in "$SERVICES_DIR"/*/; do
        local svc
        svc="$(basename "$dir")"
        if [[ -f "$dir/docker-compose.yml" ]]; then
          echo -n "  $svc... "
          if docker compose -f "$dir/docker-compose.yml" "$action" -d 2>/dev/null; then
            echo -e "${GREEN}ok${NC}"
            ((succeeded++))
          else
            echo -e "${RED}failed${NC}"
            ((failed++))
          fi
        fi
      done
      echo ""
      log_ok "$succeeded services processed"
      [[ $failed -gt 0 ]] && log_warn "$failed services failed"
      ;;
    status)
      log_header "Services Status"
      docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -50
      echo ""
      echo "Stopped containers:"
      docker ps -a --filter "status=exited" --format "  {{.Names}} ({{.Status}})" 2>/dev/null || echo "  none"
      ;;
    *)
      echo "Usage: mac-mini.sh services up|down|restart|status"
      exit 1
      ;;
  esac
}

# -------------------------------------------------------
# cleanup — free disk space
# -------------------------------------------------------
cmd_cleanup() {
  log_header "Disk Cleanup"

  # Show current disk usage
  echo "Current disk usage:"
  df -h /Volumes/T7 2>/dev/null || log_warn "/Volumes/T7 not mounted"
  echo ""

  # Completed downloads
  local downloads_dir="$MEDIA_DIR/downloads/complete"
  if [[ -d "$downloads_dir" ]]; then
    local dl_size
    dl_size="$(du -sh "$downloads_dir" 2>/dev/null | cut -f1)"
    echo -e "Completed downloads: ${YELLOW}$dl_size${NC} in $downloads_dir"

    if [[ "$dl_size" != "0B" && "$dl_size" != "0" ]]; then
      read -r -p "Delete completed downloads? (y/N) " confirm
      if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -rf "${downloads_dir:?}"/*
        log_ok "Completed downloads cleared"
      fi
    fi
  fi

  # Docker cleanup
  echo ""
  echo "Docker disk usage:"
  docker system df 2>/dev/null
  echo ""
  read -r -p "Prune unused Docker images/containers/cache? (y/N) " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    docker system prune -a -f
    log_ok "Docker pruned"
  fi

  # Ollama models
  if [[ -d "/Volumes/T7/ollama-models" ]]; then
    local ollama_size
    ollama_size="$(du -sh /Volumes/T7/ollama-models 2>/dev/null | cut -f1)"
    echo ""
    echo -e "Ollama models: ${YELLOW}$ollama_size${NC}"
    read -r -p "Delete ollama models? (y/N) " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      rm -rf /Volumes/T7/ollama-models
      log_ok "Ollama models removed"
    fi
  fi

  echo ""
  echo "After cleanup:"
  df -h /Volumes/T7 2>/dev/null || true
}

# -------------------------------------------------------
# disk — show disk usage summary
# -------------------------------------------------------
cmd_disk() {
  log_header "Disk Usage"

  echo "Volumes:"
  df -h / /Volumes/T7 2>/dev/null || df -h /
  echo ""

  if [[ -d "/Volumes/T7" ]]; then
    echo "Top-level usage on T7:"
    du -sh /Volumes/T7/*/ 2>/dev/null | sort -rh | head -10
    echo ""
    echo "Media breakdown:"
    du -sh "$MEDIA_DIR"/*/ 2>/dev/null | sort -rh
    echo ""
    echo "Docker:"
    docker system df 2>/dev/null || true
  fi
}

# -------------------------------------------------------
# ssh on — enable remote login
# -------------------------------------------------------
cmd_ssh() {
  case "${1:-}" in
    on)
      log_header "Enabling SSH (Remote Login)"
      sudo systemsetup -setremotelogin on
      log_ok "SSH enabled — connect via: ssh macmini"
      ;;
    off)
      log_header "Disabling SSH (Remote Login)"
      sudo systemsetup -setremotelogin off
      log_ok "SSH disabled"
      ;;
    *)
      echo "Usage: mac-mini.sh ssh on|off"
      exit 1
      ;;
  esac
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
  echo "  services up|down|restart|status   Manage all Docker services"
  echo "  cleanup                           Free disk space (downloads, Docker, ollama)"
  echo "  disk                              Show disk usage summary"
  echo "  ssh on|off                        Enable/disable remote login (SSH)"
  echo "  sleep off                         Disable sleep — server/always-on mode"
  echo "  sleep on                          Re-enable normal sleep"
  echo "  immich-setup                      One-time Immich setup"
  echo ""
}

# -------------------------------------------------------
# Main
# -------------------------------------------------------
case "${1:-}" in
  services) cmd_services "${2:-}" ;;
  cleanup)  cmd_cleanup ;;
  disk)     cmd_disk ;;
  ssh)      cmd_ssh "${2:-}" ;;
  sleep)
    case "${2:-}" in
      on)  cmd_sleep_on ;;
      off) cmd_sleep_off ;;
      *)   echo "Usage: mac-mini.sh sleep on|off"; exit 1 ;;
    esac
    ;;
  immich-setup) cmd_setup ;;
  *)            usage ;;
esac
