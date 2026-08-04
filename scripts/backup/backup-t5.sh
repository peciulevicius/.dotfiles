#!/bin/bash
# Local backup: NAS → T5 (Samsung T5, /Volumes/Backup)
# Covers: Immich photos, audiobooks, Calibre books (from NAS SMB mounts)
# Does NOT back up: movies/TV (too large for 500GB T5)
#
# Cron: 0 3 * * * ~/.dotfiles/scripts/backup/backup-t5.sh >> ~/logs/t5-backup.log 2>&1

set -euo pipefail

NAS_IMMICH="/Volumes/immich"
NAS_AUDIOBOOKS="/Volumes/audiobooks"
NAS_BOOKS="/Volumes/books"
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

# Verify NAS shares are mounted (mount-nas.sh handles these at login)
for m in "$NAS_IMMICH" "$NAS_AUDIOBOOKS" "$NAS_BOOKS"; do
  if [[ ! -d "$m" ]]; then
    log_err "NAS share not mounted at $m — run scripts/utils/mount-nas.sh"
    exit 1
  fi
done

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
sync_dir "$NAS_IMMICH/upload" "$T5/immich/upload" "Immich photos"

# 2. Audiobooks
sync_dir "$NAS_AUDIOBOOKS" "$T5/audiobooks" "Audiobooks"

# 3. Calibre books
sync_dir "$NAS_BOOKS" "$T5/calibre-books" "Calibre books"

if [[ $ERRORS -eq 0 ]]; then
  log_ok "T5 backup complete"
  echo "$(date '+%Y-%m-%d %H:%M:%S') — done (0 errors)" | tee -a "$LOG_FILE"
  exit 0
else
  log_err "T5 backup finished with $ERRORS error(s) — check $LOG_FILE"
  exit 1
fi
