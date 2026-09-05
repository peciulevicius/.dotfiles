#!/usr/bin/env bash
# mount-nas.sh — mounts UGREEN NAS SMB shares (launchd agent, at login + periodically)
# Credentials come from the login keychain (saved when first mounted in
# Finder as user `macmini`). Docker services depend on these mounts, so
# this must run before/alongside Docker Desktop autostart — both are
# login items, and containers restart-retry until paths appear.
#
# Addressing: the NAS is NOT on a DHCP reservation and its IP has drifted
# three times (.73 → .106 → .75 → .73), each time taking every NAS-backed
# service offline. So we address it by its Bonjour/mDNS name, which follows
# the NAS to whatever IP it currently holds. The numeric fallback below only
# matters until a keychain credential exists for the mDNS name.

set -uo pipefail

NAS_MDNS="DH4300PLUS-DP.local"      # drift-proof; preferred
NAS_FALLBACK_IPS=(192.168.1.73 192.168.1.75)  # only used if mDNS mount fails
NAS_USER="macmini"
SHARES=(media immich audiobooks books unsorted)
LOG="/opt/homebrew/var/log/mount-nas.log"

# A NAS rebuilding/checking its RAID5 array after a hard power cut can take
# well over the old 3-minute budget, so wait up to 10 minutes for port 445.
BOOT_WAIT_TRIES=120
BOOT_WAIT_SLEEP=5

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"; }

# Everything is already mounted — nothing to do (the common periodic case).
all_mounted() {
    local s
    for s in "${SHARES[@]}"; do
        mount | grep -q "on /Volumes/$s " || return 1
    done
    return 0
}

if all_mounted; then
    exit 0
fi

# Run `mount volume` with a hard timeout. Without one, a missing keychain
# credential makes osascript sit forever on an invisible GUI password prompt
# when this runs from launchd, wedging the whole agent.
try_mount() {
    local host="$1" share="$2"
    osascript -e "mount volume \"smb://$NAS_USER@$host/$share\"" &>/dev/null &
    local pid=$!
    local waited=0
    while kill -0 "$pid" 2>/dev/null; do
        if [ "$waited" -ge 30 ]; then
            kill -9 "$pid" 2>/dev/null
            wait "$pid" 2>/dev/null
            return 1
        fi
        sleep 1
        waited=$((waited + 1))
    done
    wait "$pid" 2>/dev/null
    mount | grep -q "on /Volumes/$share "
}

# Find an address that actually answers on SMB, preferring the mDNS name.
find_host() {
    local h
    for h in "$NAS_MDNS" "${NAS_FALLBACK_IPS[@]}"; do
        if nc -z -G 2 "$h" 445 &>/dev/null; then
            echo "$h"
            return 0
        fi
    done
    return 1
}

# Wait for the NAS to come up (network/NAS may boot slower than the Mac).
NAS_HOST=""
for _ in $(seq 1 "$BOOT_WAIT_TRIES"); do
    if NAS_HOST=$(find_host); then
        break
    fi
    sleep "$BOOT_WAIT_SLEEP"
done

if [ -z "$NAS_HOST" ]; then
    log "NAS unreachable on $NAS_MDNS or ${NAS_FALLBACK_IPS[*]} after 10 min — giving up"
    exit 1
fi

log "NAS reachable via $NAS_HOST"

FAILED=()
for share in "${SHARES[@]}"; do
    mount | grep -q "on /Volumes/$share " && continue

    if try_mount "$NAS_HOST" "$share"; then
        log "mounted $share via $NAS_HOST"
        continue
    fi

    # The keychain stores SMB credentials per server address, so a mount by
    # mDNS name can fail purely for lack of a saved credential under that
    # name. Retry via any numeric address that answers.
    mounted=false
    for ip in "${NAS_FALLBACK_IPS[@]}"; do
        [ "$ip" = "$NAS_HOST" ] && continue
        nc -z -G 2 "$ip" 445 &>/dev/null || continue
        if try_mount "$ip" "$share"; then
            log "mounted $share via fallback $ip (no keychain entry for $NAS_MDNS yet)"
            mounted=true
            break
        fi
    done

    if [ "$mounted" = false ]; then
        log "FAILED to mount $share"
        FAILED+=("$share")
    fi
done

if [ ${#FAILED[@]} -gt 0 ]; then
    log "shares still unmounted: ${FAILED[*]}"
    exit 1
fi

exit 0
