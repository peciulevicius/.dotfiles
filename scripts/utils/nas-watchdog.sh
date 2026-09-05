#!/usr/bin/env bash
# nas-watchdog.sh — keeps NAS mounts and the services that depend on them alive
# Runs every 5 minutes via launchd (com.peciulevicius.nas-watchdog)
#
# The gap this closes: docker-watchdog.sh keeps Docker itself healthy, but
# when the NAS disappears — IP drift, NAS reboot, power cut, SMB timeout —
# the shares unmount, every container that bind-mounts /Volumes/<share>
# exits, and nothing ever brings them back. That has meant services staying
# down for days until someone was physically home to notice, most recently
# 2026-09-05 (11 containers exited, down ~7 days).
#
# Order matters: mounts must exist BEFORE the containers start, or Docker
# recreates the bind path as an empty directory on the internal SSD and the
# service comes up pointing at nothing.

set -uo pipefail

export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

LOG="/opt/homebrew/var/log/nas-watchdog.log"
MOUNT_SCRIPT="$HOME/.dotfiles/scripts/utils/mount-nas.sh"
SERVICES_DIR="$HOME/services"
DOCKER_SOCK="$HOME/.docker/run/docker.sock"

SHARES=(media immich audiobooks books unsorted)

# Compose stacks that bind-mount a NAS share (dir name under ~/services)
NAS_STACKS=(immich jellyfin audiobookshelf calibre calibre-web lazylibrarian
            readarr bazarr sonarr-radarr transmission)

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"; }

engine_ok() {
    [[ "$(curl -s --max-time 5 --unix-socket "$DOCKER_SOCK" http://localhost/_ping 2>/dev/null)" == "OK" ]]
}

# Note: `${out[*]}` on an empty array trips `set -u` under macOS's bash 3.2,
# so the expansion needs the :- guard even though `out` is initialised.
missing_shares() {
    local s out=()
    for s in "${SHARES[@]}"; do
        mount | grep -q "on /Volumes/$s " || out+=("$s")
    done
    echo "${out[*]:-}"
}

# Docker being down is docker-watchdog.sh's job, not ours. Bailing out here
# also stops us from starting containers while the engine is mid-restart.
if ! engine_ok; then
    exit 0
fi

MISSING=$(missing_shares)
if [ -n "$MISSING" ]; then
    log "shares not mounted: $MISSING — running mount-nas.sh"
    bash "$MOUNT_SCRIPT"
    MISSING=$(missing_shares)
    if [ -n "$MISSING" ]; then
        log "still not mounted after remount: $MISSING — NAS likely down, skipping container restarts"
        exit 1
    fi
    log "shares remounted OK"
fi

# Mounts are healthy. Revive any NAS-backed container that is not running.
# `compose up -d` is used rather than `docker start` so a container that
# exited while its bind path was missing gets recreated against the now
# correct mount instead of resuming with a stale one.
RESTARTED=()
for stack in "${NAS_STACKS[@]}"; do
    compose="$SERVICES_DIR/$stack/docker-compose.yml"
    [ -f "$compose" ] || continue

    # Any container belonging to this stack that isn't running?
    down=$(docker compose -f "$compose" --project-directory "$SERVICES_DIR/$stack" \
             ps -a --format '{{.Name}} {{.State}}' 2>/dev/null \
           | awk '$2 != "running" {print $1}')

    [ -z "$down" ] && continue

    log "$stack has non-running containers: $(echo "$down" | tr '\n' ' ')— bringing up"
    if docker compose -f "$compose" --project-directory "$SERVICES_DIR/$stack" up -d >>"$LOG" 2>&1; then
        RESTARTED+=("$stack")
    else
        log "$stack FAILED to come up"
    fi
done

if [ ${#RESTARTED[@]} -gt 0 ]; then
    log "recovered stacks: ${RESTARTED[*]}"
fi

exit 0
