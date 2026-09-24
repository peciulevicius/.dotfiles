#!/bin/bash
# Restore from the Cloudflare R2 backup (rclone-backup.sh) via rclone
#
# Usage:
#   ./restore.sh list                    # list the service configs in R2
#   ./restore.sh service <name>          # restore a single service's config/data
#   ./restore.sh all                     # restore every service
#   ./restore.sh set <vault|dumps|books|photos>   # restore one of the other backup sets
#   ./restore.sh db <file.sql> <container> [user] # load a dump back into a database
#
# Everything restores into ~/services-restore/ — nothing live is overwritten
# except by `db`, which asks first.
#
# Backup sets, matching rclone-backup.sh (keep the two in step):
#   services  ${BACKUP_DEST}                          configs + app data, no .env
#   vault     ${OBSIDIAN_DEST}                        Obsidian vault
#   dumps     <remote>:peciulevicius-backups/db-dumps weekly pg_dumpall / mariadb-dump
#   books     <remote>:peciulevicius-backups/calibre-books
#   photos    <remote>:peciulevicius-backups/immich-photos  (~73GB — Immich originals)
#
# ⚠️ .env files are never backed up. Secrets come back from Vaultwarden.
# ⚠️ Photos without the matching immich dump are 6,600 anonymous UUID files —
#    restore `dumps` too and load immich's with `db`.

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

RCLONE_REMOTE="${RCLONE_REMOTE:-r2}"
BACKUP_DEST="${BACKUP_DEST:-${RCLONE_REMOTE}:peciulevicius-backups/services}"
OBSIDIAN_DEST="${OBSIDIAN_DEST:-${RCLONE_REMOTE}:peciulevicius-backups/obsidian-vault}"
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
  # copy, not sync: sync would delete sets already restored alongside
  # (~/services-restore/{vault,dumps,books,photos}).
  rclone copy "$BACKUP_DEST" "$RESTORE_DIR" --progress
  log_ok "Restored to $RESTORE_DIR"
}

cmd_set() {
  local set="$1" src
  case "$set" in
    vault)  src="$OBSIDIAN_DEST" ;;
    dumps)  src="${RCLONE_REMOTE}:peciulevicius-backups/db-dumps" ;;
    books)  src="${RCLONE_REMOTE}:peciulevicius-backups/calibre-books" ;;
    photos) src="${RCLONE_REMOTE}:peciulevicius-backups/immich-photos" ;;
    *) log_err "Unknown set '$set' — use vault, dumps, books or photos"; exit 1 ;;
  esac
  local dest="$RESTORE_DIR/$set"

  log_info "Restoring $src → $dest"
  log_info "Size: $(rclone size "$src" 2>/dev/null | tr '\n' ' ')"
  [[ "$set" == photos ]] && log_warn "Photos are ~73GB — make sure $RESTORE_DIR has room"
  echo ""

  read -r -p "Continue? (y/n) " confirm
  [[ "$confirm" != "y" ]] && echo "Cancelled." && exit 0

  mkdir -p "$dest"
  rclone copy "$src" "$dest" --progress
  log_ok "Restored to $dest"
  if [[ "$set" == books ]]; then
    echo ""
    echo "To use: stop calibre, calibre-web, lazylibrarian; point BOOKS_DIR in their"
    echo ".env files at $dest (or copy it into place); docker compose up -d."
  fi
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
  # backup-databases.sh writes two formats: pg_dumpall for Postgres, and
  # mariadb-dump --all-databases for Nextcloud. Pick the client by the header.
  if head -5 "$file" | grep -qiE 'MariaDB dump|MySQL dump'; then
    docker exec -i "$container" sh -c 'mariadb -u root -p"$MYSQL_ROOT_PASSWORD"' < "$file" 2>&1
  else
    # pg_dumpall output recreates its own databases, so connect to the
    # maintenance db rather than one named after the user.
    docker exec -i "$container" psql -U "$user" -d postgres < "$file" 2>&1
  fi || { log_err "Restore reported errors — read the output above"; exit 1; }
  log_ok "Database restored"
}

usage() {
  echo ""
  echo "Usage: restore.sh <command>"
  echo ""
  echo "Commands:"
  echo "  list                              List the service configs in R2"
  echo "  service <name>                    Restore a single service (e.g. immich)"
  echo "  all                               Restore all services"
  echo "  set <vault|dumps|books|photos>    Restore one of the other backup sets"
  echo "  db <file.sql> <container> [user]  Restore a database dump into a container"
  echo ""
  echo "Examples:"
  echo "  restore.sh list"
  echo "  restore.sh service immich"
  echo "  restore.sh set dumps"
  echo "  restore.sh db ~/backups/immich-20260318.sql immich_postgres postgres"
  echo ""
}

case "${1:-}" in
  list)    cmd_list ;;
  service) cmd_service "${2:?Service name required}" ;;
  all)     cmd_all ;;
  set)     cmd_set "${2:?Set required: vault, dumps, books or photos}" ;;
  db)      cmd_db "${2:?SQL file required}" "${3:?Container name required}" "${4:-postgres}" ;;
  *)       usage ;;
esac
