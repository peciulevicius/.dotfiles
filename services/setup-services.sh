#!/bin/bash
# Stage Docker Compose stacks to ~/services/<service>/
# Usage: ./services/setup-services.sh [--dry-run] [service-name]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$HOME/services"
DRY_RUN=false
TARGET_SERVICE=""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SERVICES=(
  immich
  vaultwarden
  nextcloud
  uptime-kuma
  freshrss
  syncthing
  portainer
  watchtower
  glance
  paperless-ngx
  calibre-web
  rclone
  pihole
  stirling-pdf
  it-tools
  audiobookshelf
  linkwarden
  mealie
  jellyfin
  sonarr-radarr
  transmission
  jellyseerr
  bazarr
  grafana
)

SERVICE_PORTS=(
  "immich:2283"
  "vaultwarden:8001"
  "nextcloud:8080"
  "uptime-kuma:3001"
  "freshrss:8082"
  "syncthing:8384"
  "portainer:9000"
  "watchtower:—"
  "glance:7575"
  "paperless-ngx:8000"
  "calibre-web:8083"
  "rclone:—"
  "pihole:8053,53"
  "stirling-pdf:8084"
  "it-tools:8085"
  "audiobookshelf:13378"
  "linkwarden:3005"
  "mealie:9925"
  "jellyfin:8096"
  "sonarr-radarr:8989,7878,9696"
  "transmission:9091"
  "jellyseerr:5055"
  "bazarr:6767"
  "grafana:3000,9090,9100"
)

log_ok()   { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_info() { echo -e "${CYAN}→${NC} $1"; }

usage() {
  cat <<USAGE
Usage: ./services/setup-services.sh [--dry-run] [service-name]

Options:
  --dry-run       Show what would be staged without doing it
  service-name    Stage only this service (e.g. immich, nextcloud)

Examples:
  ./services/setup-services.sh
  ./services/setup-services.sh immich
  ./services/setup-services.sh --dry-run
USAGE
}

stage_service() {
  local svc="$1"
  local svc_dir="$SCRIPT_DIR/$svc"
  local dest_dir="$DOCKER_DIR/$svc"

  if [[ ! -d "$svc_dir" ]]; then
    log_warn "$svc: source directory not found, skipping"
    return
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[dry-run] Would create $dest_dir"
    [[ -f "$svc_dir/docker-compose.yml" ]] && log_info "[dry-run] Would copy docker-compose.yml"
    [[ -f "$svc_dir/.env.example" ]] && log_info "[dry-run] Would copy .env.example → .env (if not exists)"
    return
  fi

  mkdir -p "$dest_dir"

  if [[ -f "$svc_dir/docker-compose.yml" ]]; then
    cp "$svc_dir/docker-compose.yml" "$dest_dir/docker-compose.yml"
  fi

  if [[ -f "$svc_dir/.env.example" ]]; then
    if [[ ! -f "$dest_dir/.env" ]]; then
      cp "$svc_dir/.env.example" "$dest_dir/.env"
      log_warn "$svc: .env created from template — edit before running"
    else
      log_info "$svc: .env already exists, not overwriting"
    fi
  fi

  log_ok "$svc staged → $dest_dir"
}

print_summary() {
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║         Services Staging Summary             ║${NC}"
  echo -e "${CYAN}╠══════════════════════════════════════════════╣${NC}"
  printf "${CYAN}║${NC} %-20s %-8s %-14s ${CYAN}║${NC}\n" "Service" "Port" "Status"
  echo -e "${CYAN}╠══════════════════════════════════════════════╣${NC}"

  for entry in "${SERVICE_PORTS[@]}"; do
    local svc="${entry%%:*}"
    local port="${entry##*:}"
    local dest_dir="$DOCKER_DIR/$svc"
    local status="not staged"

    if [[ -d "$dest_dir" ]]; then
      if [[ -f "$dest_dir/.env" ]]; then
        status="staged ✓"
      else
        status="staged (no .env)"
      fi
    fi

    printf "${CYAN}║${NC} %-20s %-8s %-14s ${CYAN}║${NC}\n" "$svc" "$port" "$status"
  done

  echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
  echo ""
  echo "Next: edit .env files in $DOCKER_DIR/<service>/, then:"
  echo "  cd ~/services/<service> && docker compose up -d"
}

# Parse args
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "Unknown option: $arg"; usage; exit 1 ;;
    *) TARGET_SERVICE="$arg" ;;
  esac
done

# Check Docker
if ! command -v docker &>/dev/null; then
  log_warn "Docker not found. Install Docker Desktop or OrbStack first."
  exit 1
fi

echo -e "${CYAN}Self-Hosted Services Setup${NC}"
echo "Target directory: $DOCKER_DIR"
[[ "$DRY_RUN" == "true" ]] && echo "(dry run — no changes)"
echo ""

if [[ -n "$TARGET_SERVICE" ]]; then
  stage_service "$TARGET_SERVICE"
else
  for svc in "${SERVICES[@]}"; do
    stage_service "$svc"
  done
fi

print_summary
