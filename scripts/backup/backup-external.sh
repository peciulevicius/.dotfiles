#!/bin/bash
# Local backup: NAS → an external drive (T7, T5, whatever is plugged in)
#
#   ./backup-external.sh /Volumes/T7        # explicit target
#   ./backup-external.sh                    # defaults to /Volumes/Backup (T5)
#
# Covers Immich photos + the Immich database, audiobooks, and Calibre books.
# Does NOT cover movies/TV — too large, and re-downloadable.
#
# The database matters as much as the photos: originals on disk are named by
# UUID, so without a matching dump a restore gives you 6,600 anonymous files
# with no albums, faces, dates, or favourites. Photos alone are not a backup.

set -uo pipefail

TARGET="${1:-/Volumes/Backup}"

NAS_IMMICH="/Volumes/immich"
NAS_AUDIOBOOKS="/Volumes/audiobooks"
NAS_BOOKS="/Volumes/books"
DB_DUMPS="$HOME/backups"          # weekly pg_dump output (internal SSD)

LOG_DIR="$HOME/logs"
LOG_FILE="$LOG_DIR/external-backup-$(basename "$TARGET")-$(date +%Y%m%d).log"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

mkdir -p "$LOG_DIR"

log_ok()   { echo -e "$(date '+%H:%M:%S') ${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"; }
log_err()  { echo -e "$(date '+%H:%M:%S') ${RED}✗${NC} $1" | tee -a "$LOG_FILE"; }
log_warn() { echo -e "$(date '+%H:%M:%S') ${YELLOW}⚠${NC} $1" | tee -a "$LOG_FILE"; }
log_info() { echo -e "$(date '+%H:%M:%S') ${CYAN}→${NC} $1" | tee -a "$LOG_FILE"; }

DRY_RUN=false
for arg in "$@"; do
  [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done

echo "$(date '+%Y-%m-%d %H:%M:%S') — backup to $TARGET started" | tee -a "$LOG_FILE"
[[ "$DRY_RUN" == "true" ]] && log_warn "DRY RUN — nothing will be written"

if [[ ! -d "$TARGET" ]]; then
  log_err "Target $TARGET not mounted — plug the drive in and retry"
  exit 1
fi

# A missing NAS share means the source is unavailable, not empty. Syncing
# with --delete from a vanished source would wipe the backup, so refuse.
for m in "$NAS_IMMICH" "$NAS_AUDIOBOOKS" "$NAS_BOOKS"; do
  if [[ ! -d "$m" ]] || [[ -z "$(ls -A "$m" 2>/dev/null)" ]]; then
    log_err "NAS share missing or empty at $m — refusing to sync (would delete the backup)"
    log_err "Run: bash ~/.dotfiles/scripts/utils/mount-nas.sh"
    exit 1
  fi
done

ERRORS=0

sync_dir() {
  local src="$1" dst="$2" label="$3"

  if [[ ! -d "$src" ]]; then
    log_err "$label: source $src not found — NOT backed up"
    ERRORS=$((ERRORS + 1))
    return
  fi

  mkdir -p "$dst"
  log_info "Syncing $label"

  local cmd=(rsync -a --delete --exclude='.DS_Store' --exclude='.smbdelete*')
  [[ "$DRY_RUN" == "true" ]] && cmd+=(--dry-run --stats)
  cmd+=("$src/" "$dst/")

  if "${cmd[@]}" >>"$LOG_FILE" 2>&1; then
    log_ok "$label synced"
  else
    log_err "$label FAILED"
    ERRORS=$((ERRORS + 1))
  fi
}

# 1. Immich originals — the irreplaceable part
# Destination mirrors the NAS layout exactly (…/immich/upload/upload). Do not
# "tidy" this into a flatter path: the existing drives were seeded with this
# structure, and changing it makes rsync delete the whole backup and re-copy
# ~77GB over USB instead of transferring the handful of genuinely new files.
sync_dir "$NAS_IMMICH/upload/upload" "$TARGET/immich/upload/upload" "Immich originals"

# 2. Immich transcoded video — regenerable, but hours of CPU to rebuild
sync_dir "$NAS_IMMICH/upload/encoded-video" "$TARGET/immich/upload/encoded-video" "Immich encoded video"

# 3. Database dumps — without these the originals are anonymous UUIDs
sync_dir "$DB_DUMPS" "$TARGET/db-dumps" "Database dumps"

# 4. Audiobooks + books
sync_dir "$NAS_AUDIOBOOKS" "$TARGET/audiobooks" "Audiobooks"
sync_dir "$NAS_BOOKS" "$TARGET/calibre-books" "Calibre books"

# Thumbnails are deliberately skipped: they live on the internal SSD now and
# Immich regenerates them from the originals in minutes.

if [[ $ERRORS -eq 0 ]]; then
  log_ok "Backup to $TARGET complete"
  exit 0
else
  log_err "Backup finished with $ERRORS error(s) — check $LOG_FILE"
  exit 1
fi
