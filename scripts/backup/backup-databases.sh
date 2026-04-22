#!/bin/bash
# Dump databases from running Docker containers to ~/backups/
# Run weekly via cron: 0 4 * * 0 ~/.dotfiles/scripts/backup/backup-databases.sh
#
# Usage: ./backup-databases.sh [--dry-run]

set -uo pipefail

BACKUP_DIR="$HOME/backups"
DATE=$(date +%Y%m%d)
DRY_RUN=false
KEEP_DAYS=30

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_ok()   { echo -e "${GREEN}✓${NC} $1"; }
log_err()  { echo -e "${RED}✗${NC} $1" >&2; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_info() { echo -e "${CYAN}→${NC} $1"; }

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

mkdir -p "$BACKUP_DIR"

dump_postgres() {
  local container="$1"
  local user="$2"
  local label="$3"
  local file="$BACKUP_DIR/${label}-${DATE}.sql"

  if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
    log_warn "$label: container '$container' not running, skipping"
    return
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[dry-run] Would dump $container → $file"
    return
  fi

  log_info "Dumping $label..."
  if docker exec "$container" pg_dumpall -U "$user" > "$file" 2>/dev/null; then
    local size
    size=$(du -h "$file" | cut -f1)
    log_ok "$label → $file ($size)"
  else
    log_err "$label dump failed"
    rm -f "$file"
  fi
}

dump_mysql() {
  local container="$1"
  local label="$2"
  local file="$BACKUP_DIR/${label}-${DATE}.sql"

  if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
    log_warn "$label: container '$container' not running, skipping"
    return
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[dry-run] Would dump $container → $file"
    return
  fi

  log_info "Dumping $label..."
  if docker exec "$container" mariadb-dump -u root --all-databases > "$file" 2>/dev/null; then
    local size
    size=$(du -h "$file" | cut -f1)
    log_ok "$label → $file ($size)"
  else
    log_err "$label dump failed"
    rm -f "$file"
  fi
}

echo -e "${CYAN}Database Backups${NC} — $(date '+%Y-%m-%d %H:%M')"
[[ "$DRY_RUN" == "true" ]] && echo "(dry run — no dumps)"
echo ""

# Immich (PostgreSQL)
dump_postgres "immich_postgres" "postgres" "immich"

# Paperless-ngx (PostgreSQL)
dump_postgres "paperless_db" "paperless" "paperless"

# Linkwarden (PostgreSQL)
dump_postgres "linkwarden_db" "linkwarden" "linkwarden"

# Nextcloud (MariaDB)
dump_mysql "nextcloud_db" "nextcloud"

# Cleanup old dumps
if [[ "$DRY_RUN" == "false" ]]; then
  old=$(find "$BACKUP_DIR" -name "*.sql" -mtime +${KEEP_DAYS} 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$old" -gt 0 ]]; then
    find "$BACKUP_DIR" -name "*.sql" -mtime +${KEEP_DAYS} -delete
    log_ok "Cleaned up $old dumps older than ${KEEP_DAYS} days"
  fi
fi

echo ""
log_ok "Done"
