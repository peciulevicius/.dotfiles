#!/bin/bash
# Dump databases from Docker containers to ~/backups/
# Run weekly via cron: 0 4 * * 0 ~/.dotfiles/scripts/backup/backup-databases.sh
#
# On-demand services (scripts/utils/ondemand.sh) keep their DB containers
# stopped. A stopped DB container is started on its own — never the app —
# dumped, and stopped again, so their dumps stay fresh without the app running.
#
# Usage: ./backup-databases.sh [--dry-run]

set -uo pipefail

BACKUP_DIR="$HOME/backups"
DATE=$(date +%Y%m%d)
DRY_RUN=false
KEEP_DAYS=30
ERRORS=0

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

# DB containers this run started; stopped again on exit, even after a failure.
STARTED=()
stop_started() {
  local c
  for c in ${STARTED[@]+"${STARTED[@]}"}; do
    if docker stop "$c" >/dev/null 2>&1; then
      log_info "$c stopped again (on-demand)"
    else
      log_err "$c could not be stopped again — stop it by hand"
    fi
  done
}
trap stop_started EXIT

# ensure_running <container> <readiness command…>
# Running → nothing to do. Exists but stopped (on-demand) → start just this
# container and wait until the DB answers. Doesn't exist → fail.
ensure_running() {
  local container="$1"; shift
  docker ps --format '{{.Names}}' | grep -q "^${container}$" && return 0
  docker ps -a --format '{{.Names}}' | grep -q "^${container}$" || return 1
  [[ "$DRY_RUN" == "true" ]] && { log_info "[dry-run] Would start stopped $container temporarily"; return 0; }

  log_info "$container is stopped (on-demand) — starting it just for the dump"
  docker start "$container" >/dev/null || return 1
  STARTED+=("$container")
  for _ in $(seq 1 60); do
    docker exec "$container" "$@" >/dev/null 2>&1 && return 0
    sleep 1
  done
  log_err "$container did not become ready within 60s"
  return 1
}

dump_postgres() {
  local container="$1"
  local user="$2"
  local label="$3"
  local file="$BACKUP_DIR/${label}-${DATE}.sql"

  if ! ensure_running "$container" pg_isready -U "$user"; then
    log_err "$label: container '$container' missing or not ready, skipping"
    ((ERRORS++))
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
    ((ERRORS++))
  fi
}

dump_mysql() {
  local container="$1"
  local label="$2"
  local file="$BACKUP_DIR/${label}-${DATE}.sql"

  # shellcheck disable=SC2016  # $MYSQL_ROOT_PASSWORD expands inside the container
  if ! ensure_running "$container" sh -c 'mariadb-admin ping -u root -p"$MYSQL_ROOT_PASSWORD"'; then
    log_err "$label: container '$container' missing or not ready, skipping"
    ((ERRORS++))
    return
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[dry-run] Would dump $container → $file"
    return
  fi

  log_info "Dumping $label..."
  # Password is read from the container's own env so it never lands in this repo
  if docker exec "$container" sh -c \
       'mariadb-dump -u root -p"$MYSQL_ROOT_PASSWORD" --all-databases' > "$file" 2>/dev/null; then
    local size
    size=$(du -h "$file" | cut -f1)
    log_ok "$label → $file ($size)"
  else
    log_err "$label dump failed"
    rm -f "$file"
    ((ERRORS++))
  fi
}

echo -e "${CYAN}Database Backups${NC} — $(date '+%Y-%m-%d %H:%M')"
[[ "$DRY_RUN" == "true" ]] && echo "(dry run — no dumps)"
echo ""

# Immich (PostgreSQL)
dump_postgres "immich_postgres" "postgres" "immich"

# Paperless-ngx (PostgreSQL)
dump_postgres "paperless_db" "paperless" "paperless"

# Linkwarden (PostgreSQL) — superuser is 'postgres'; POSTGRES_DB is 'linkwarden'
dump_postgres "linkwarden_db" "postgres" "linkwarden"

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
if [[ "$ERRORS" -gt 0 ]]; then
  # Exit non-zero so run-with-notify.sh (and cron) can see the failure.
  # Without this the script reported success while linkwarden and nextcloud
  # had never dumped once.
  log_err "Done with $ERRORS failed dump(s)"
  exit 1
fi
log_ok "Done"
