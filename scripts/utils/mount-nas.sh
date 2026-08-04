#!/usr/bin/env bash
# mount-nas.sh — mounts UGREEN NAS SMB shares at login (launchd agent)
# Credentials come from the login keychain (saved when first mounted in
# Finder as user `macmini`). Docker services depend on these mounts, so
# this must run before/alongside Docker Desktop autostart — both are
# login items, and containers restart-retry until paths appear.

set -uo pipefail

NAS_HOST="192.168.1.73"
NAS_USER="macmini"
SHARES=(media immich audiobooks books unsorted)
LOG="/opt/homebrew/var/log/mount-nas.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"; }

# Wait for the NAS to be reachable (network comes up after login)
for _ in $(seq 1 36); do
    nc -z -G 2 "$NAS_HOST" 445 &>/dev/null && break
    sleep 5
done
if ! nc -z -G 2 "$NAS_HOST" 445 &>/dev/null; then
    log "NAS $NAS_HOST unreachable after 3 min — giving up"
    exit 1
fi

for share in "${SHARES[@]}"; do
    if mount | grep -q "on /Volumes/$share "; then
        continue
    fi
    if osascript -e "mount volume \"smb://$NAS_USER@$NAS_HOST/$share\"" &>/dev/null; then
        log "mounted $share"
    else
        log "FAILED to mount $share"
    fi
done
