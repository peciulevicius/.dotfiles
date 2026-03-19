#!/bin/bash
# Rclone cloud backup — backs up ~/services volumes to B2/S3
# Usage: ./rclone-backup.sh [--dry-run]
# Set up rclone remote first: rclone config

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

DRY_RUN=false
LOG_DIR="${LOG_DIR:-$HOME/logs}"
LOG_FILE="$LOG_DIR/rclone-$(date +%Y%m%d).log"

log_ok()   { echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1" | tee -a "$LOG_FILE"; }
log_err()  { echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE"; }
log_info() { echo -e "${CYAN}→${NC} $1" | tee -a "$LOG_FILE"; }

# Load env
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

RCLONE_REMOTE="${RCLONE_REMOTE:-b2-backup}"
DOCKER_DIR="${DOCKER_DIR:-$HOME/services}"
BACKUP_DEST="${BACKUP_DEST:-${RCLONE_REMOTE}:peciulevicius-services-backup/services}"
RCLONE_FLAGS="${RCLONE_FLAGS:---transfers=4 --checkers=8 --fast-list --stats=60s}"

mkdir -p "$LOG_DIR"

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *) ;;
  esac
done

if ! command -v rclone &>/dev/null; then
  log_err "rclone not installed. Run: brew install rclone"
  exit 1
fi

if ! rclone listremotes | grep -q "^${RCLONE_REMOTE}:"; then
  log_err "rclone remote '${RCLONE_REMOTE}' not configured. Run: rclone config"
  exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') — rclone backup started" >> "$LOG_FILE"
log_info "Backing up $DOCKER_DIR → $BACKUP_DEST"
[[ "$DRY_RUN" == "true" ]] && log_warn "Dry run — no data will be transferred"

# Backup 1: Docker service configs
SYNC_CMD=(rclone sync "$DOCKER_DIR" "$BACKUP_DEST")
SYNC_CMD+=(--exclude "**/.env")
SYNC_CMD+=(--exclude "**/library/**")
SYNC_CMD+=(--exclude "**/data/postgres/**")
SYNC_CMD+=($RCLONE_FLAGS)
[[ "$DRY_RUN" == "true" ]] && SYNC_CMD+=(--dry-run)

if "${SYNC_CMD[@]}" 2>&1 | tee -a "$LOG_FILE"; then
  log_ok "Services backup complete"
else
  log_err "Services backup failed — check $LOG_FILE"
  exit 1
fi

# Backup 2: Obsidian vault
OBSIDIAN_DIR="$HOME/obsidian-vault"
OBSIDIAN_DEST="${OBSIDIAN_DEST:-${RCLONE_REMOTE}:peciulevicius-services-backup/obsidian-vault}"

if [[ -d "$OBSIDIAN_DIR" ]]; then
  log_info "Backing up $OBSIDIAN_DIR → $OBSIDIAN_DEST"
  VAULT_CMD=(rclone sync "$OBSIDIAN_DIR" "$OBSIDIAN_DEST")
  VAULT_CMD+=(--exclude ".obsidian/workspace*")
  VAULT_CMD+=(--exclude ".obsidian/plugins/**")
  VAULT_CMD+=(--exclude ".DS_Store")
  VAULT_CMD+=(--exclude ".stfolder")
  VAULT_CMD+=($RCLONE_FLAGS)
  [[ "$DRY_RUN" == "true" ]] && VAULT_CMD+=(--dry-run)

  if "${VAULT_CMD[@]}" 2>&1 | tee -a "$LOG_FILE"; then
    log_ok "Obsidian vault backup complete"
  else
    log_err "Obsidian vault backup failed — check $LOG_FILE"
    exit 1
  fi
else
  log_warn "Obsidian vault not found at $OBSIDIAN_DIR — skipping"
fi
