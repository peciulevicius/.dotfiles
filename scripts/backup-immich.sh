#!/bin/bash
# Nightly rsync backup of Immich photo library from T7 to T5 (ImmichBackup).
# Scheduled via cron: 0 3 * * * ~/.dotfiles/scripts/backup-immich.sh
#
# Reads IMMICH_VOLUME from ~/.config/dotfiles/mac-mini.conf (set by mac-mini-setup.sh).

LOCAL_CONFIG="$HOME/.config/dotfiles/mac-mini.conf"
[ -f "$LOCAL_CONFIG" ] && source "$LOCAL_CONFIG"

if [ -z "${IMMICH_VOLUME:-}" ]; then
  echo "ERROR: IMMICH_VOLUME not set. Run scripts/mac-mini-setup.sh first." >&2
  exit 1
fi

SRC="/Volumes/$IMMICH_VOLUME/immich"
DST="/Volumes/ImmichBackup/immich"
LOG_DIR="$HOME/logs"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }

echo "$(timestamp) Starting Immich backup"

# Check source is mounted
if [ ! -d "$SRC" ]; then
    echo -e "${RED}ERROR: Source not mounted at $SRC${RESET}" >&2
    exit 1
fi

# Check destination is mounted
if [ ! -d "/Volumes/ImmichBackup" ]; then
    echo -e "${RED}ERROR: Backup drive not mounted at /Volumes/ImmichBackup${RESET}" >&2
    exit 1
fi

mkdir -p "$DST" "$LOG_DIR"

rsync -av --delete \
    --exclude='*.tmp' \
    "$SRC/" "$DST/"

STATUS=$?

if [ $STATUS -eq 0 ]; then
    echo -e "$(timestamp) ${GREEN}Backup complete${RESET}"
else
    echo -e "$(timestamp) ${RED}Backup failed (rsync exit $STATUS)${RESET}" >&2
    exit $STATUS
fi
