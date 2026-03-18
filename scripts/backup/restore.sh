#!/bin/bash
# Restore service data from Backblaze B2 via rclone
#
# Usage:
#   ./restore.sh list                    # list what's in B2
#   ./restore.sh service <name>          # restore a single service
#   ./restore.sh all                     # restore everything
#   ./restore.sh db <file.sql> <container> <user>  # restore a database dump

set -uo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_ok()   { echo -e "${GREEN}✓${NC} $1"; }
log_err()  { echo -e "${RED}✗${NC} $1" >&2; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_info() { echo -e "${CYAN}→${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RCLONE_ENV="$HOME/services/rclone/.env"

# Load rclone config
if [[ -f "$RCLONE_ENV" ]]; then
  # shellcheck disable=SC1090
  source "$RCLONE_ENV"
fi

RCLONE_REMOTE="${RCLONE_REMOTE:-b2-backup}"
BACKUP_DEST="${BACKUP_DEST:-${RCLONE_REMOTE}:my-backup-bucket/services}"
RESTORE_DIR="$HOME/services-restore"

if ! command -v rclone &>/dev/null; then
  log_err "rclone not installed. Run: brew install rclone"
  exit 1
fi

cmd_list() {
  log_info "Listing contents of $BACKUP_DEST"
  echo ""
  rclone ls "$BACKUP_DEST" | head -50
  echo ""
  log_info "Use 'restore.sh service <name>' to restore a specific service"
}

cmd_service() {
  local name="$1"
  local dest="$RESTORE_DIR/$name"

  log_info "Restoring $name → $dest"
  log_warn "This will NOT overwrite ~/services/$name — restoring to $dest"
  echo ""

  read -r -p "Continue? (y/n) " confirm
  [[ "$confirm" != "y" ]] && echo "Cancelled." && exit 0

  mkdir -p "$dest"
  rclone copy "$BACKUP_DEST/$name" "$dest" --progress
  log_ok "Restored to $dest"
  echo ""
  echo "To use: compare with ~/services/$name, then copy what you need"
}

cmd_all() {
  log_info "Restoring all services → $RESTORE_DIR"
  log_warn "This will NOT overwrite ~/services/ — restoring to $RESTORE_DIR"
  echo ""

  read -r -p "Continue? (y/n) " confirm
  [[ "$confirm" != "y" ]] && echo "Cancelled." && exit 0

  mkdir -p "$RESTORE_DIR"
  rclone sync "$BACKUP_DEST" "$RESTORE_DIR" --progress
  log_ok "Restored to $RESTORE_DIR"
}

cmd_db() {
  local file="$1"
  local container="$2"
  local user="${3:-postgres}"

  if [[ ! -f "$file" ]]; then
    log_err "File not found: $file"
    exit 1
  fi

  if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
    log_err "Container '$container' is not running"
    exit 1
  fi

  log_warn "This will restore $file into container '$container'"
  log_warn "Existing data will be OVERWRITTEN"
  echo ""

  read -r -p "Are you sure? (type 'yes' to confirm) " confirm
  [[ "$confirm" != "yes" ]] && echo "Cancelled." && exit 0

  log_info "Restoring database..."
  cat "$file" | docker exec -i "$container" psql -U "$user" 2>&1
  log_ok "Database restored"
}

usage() {
  echo ""
  echo "Usage: restore.sh <command>"
  echo ""
  echo "Commands:"
  echo "  list                              List what's in B2 backup"
  echo "  service <name>                    Restore a single service (e.g. immich)"
  echo "  all                               Restore all services"
  echo "  db <file.sql> <container> [user]  Restore a database dump into a container"
  echo ""
  echo "Examples:"
  echo "  restore.sh list"
  echo "  restore.sh service immich"
  echo "  restore.sh db ~/backups/immich-20260318.sql immich_postgres postgres"
  echo ""
}

case "${1:-}" in
  list)    cmd_list ;;
  service) cmd_service "${2:?Service name required}" ;;
  all)     cmd_all ;;
  db)      cmd_db "${2:?SQL file required}" "${3:?Container name required}" "${4:-postgres}" ;;
  *)       usage ;;
esac
