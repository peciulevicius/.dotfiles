#!/bin/bash
# Nightly rsync backup of Immich photo library from 1TB to 500GB partition.
# Scheduled via cron: 0 3 * * * ~/.dotfiles/scripts/backup-immich.sh

SRC="/Volumes/Storage/immich"
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
