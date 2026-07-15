#!/bin/bash
# Local backup: T7 → T5 (Samsung T5, /Volumes/Backup)
# Covers: Immich photos, audiobooks, Calibre books
# Does NOT back up: movies/TV (too large for 500GB T5)
#
# Cron: 0 3 * * * ~/.dotfiles/scripts/backup/backup-t5.sh >> ~/logs/t5-backup.log 2>&1

set -euo pipefail

T7="/Volumes/T7"
T5="/Volumes/Backup"
LOG_DIR="$HOME/logs"
LOG_FILE="$LOG_DIR/t5-backup-$(date +%Y%m%d).log"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

mkdir -p "$LOG_DIR"

log_ok()   { echo -e "$(date '+%H:%M:%S') ${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"; }
log_err()  { echo -e "$(date '+%H:%M:%S') ${RED}✗${NC} $1" | tee -a "$LOG_FILE"; }
log_warn() { echo -e "$(date '+%H:%M:%S') ${YELLOW}⚠${NC} $1" | tee -a "$LOG_FILE"; }
log_info() { echo -e "$(date '+%H:%M:%S') ${CYAN}→${NC} $1" | tee -a "$LOG_FILE"; }

echo "$(date '+%Y-%m-%d %H:%M:%S') — T5 backup started" | tee -a "$LOG_FILE"

# Verify drives are mounted
if [[ ! -d "$T7" ]]; then
  log_err "T7 not mounted at $T7 — aborting"
  exit 1
fi

if [[ ! -d "$T5" ]]; then
  log_err "T5 not mounted at $T5 — plug in Samsung T5 and retry"
  exit 1
fi

ERRORS=0

sync_dir() {
  local src="$1"
  local dst="$2"
  local label="$3"

  if [[ ! -d "$src" ]]; then
    log_warn "$label: source $src not found — skipping"
    return
  fi

  mkdir -p "$dst"
  log_info "Syncing $label ($src → $dst)"

  if rsync -a --delete --exclude='.DS_Store' "$src/" "$dst/" 2>&1 | tee -a "$LOG_FILE"; then
    log_ok "$label synced"
  else
    log_err "$label failed"
    ERRORS=$((ERRORS + 1))
  fi
}

# 1. Immich photos
sync_dir "$T7/immich/upload" "$T5/immich/upload" "Immich photos"

# 2. Audiobooks
sync_dir "$T7/audiobooks" "$T5/audiobooks" "Audiobooks"

# 3. Calibre books
sync_dir "$T7/calibre-books" "$T5/calibre-books" "Calibre books"

if [[ $ERRORS -eq 0 ]]; then
  log_ok "T5 backup complete"
  echo "$(date '+%Y-%m-%d %H:%M:%S') — done (0 errors)" | tee -a "$LOG_FILE"
  exit 0
else
  log_err "T5 backup finished with $ERRORS error(s) — check $LOG_FILE"
  exit 1
fi
