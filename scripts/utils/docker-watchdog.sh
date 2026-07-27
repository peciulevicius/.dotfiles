#!/usr/bin/env bash
# docker-watchdog.sh — keeps Docker Desktop and its engine alive
# Runs every 5 minutes via launchd
#
# Failure modes covered:
#   1. App not running                → launch it
#   2. App running, engine hung      → force-kill + relaunch (after 2 strikes;
#      `open -a` is a no-op on a running app — this exact state left all
#      services down for 6h after a reboot on 2026-07-27)
#   3. Engine up, container net dead → graceful restart (Docker proxy dies
#      intermittently)
#
# All engine checks go through the unix socket with curl --max-time: the
# docker CLI can block forever against a half-started engine, which hung
# the watchdog itself.

set -uo pipefail

# launchd's PATH lacks docker (/usr/local/bin) — bare `docker` calls fail there
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

LOG="/opt/homebrew/var/log/docker-watchdog.log"
STRIKES_FILE="${TMPDIR:-/tmp}/docker-watchdog.strikes"
DOCKER_SOCK="$HOME/.docker/run/docker.sock"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"; }

engine_ok() {
    [[ "$(curl -s --max-time 5 --unix-socket "$DOCKER_SOCK" http://localhost/_ping 2>/dev/null)" == "OK" ]]
}

app_running() {
    pgrep -qf "Docker.app/Contents/MacOS/com.docker.backend"
}

if ! engine_ok; then
    if ! app_running; then
        log "Docker not running — launching Docker Desktop"
        rm -f "$STRIKES_FILE"
        open -a "Docker"
        exit 0
    fi

    # App is running but engine unresponsive. Could be normal startup
    # (engine takes ~1 min after launch), so only escalate on the second
    # consecutive failed check (~5+ min in this state = genuinely hung).
    strikes=$(( $(cat "$STRIKES_FILE" 2>/dev/null || echo 0) + 1 ))
    echo "$strikes" > "$STRIKES_FILE"

    if (( strikes >= 2 )); then
        log "Engine unresponsive with app running (strike $strikes) — force restart"
        osascript -e 'quit app "Docker Desktop"' 2>/dev/null || true
        sleep 10
        pkill -9 -f "Docker.app/Contents" 2>/dev/null || true
        sleep 5
        open -a "Docker"
        rm -f "$STRIKES_FILE"
        log "Force restart triggered"
    else
        log "Engine unresponsive with app running (strike $strikes) — waiting one cycle"
    fi
    exit 0
fi

rm -f "$STRIKES_FILE"

# Engine is up — verify containers can reach the internet
TEST_CONTAINER=$(docker ps --format "{{.Names}}" 2>/dev/null | head -1)
if [[ -z "$TEST_CONTAINER" ]]; then
    log "No running containers to test — skipping"
    exit 0
fi

if docker exec "$TEST_CONTAINER" wget -q -O /dev/null --timeout=5 https://1.1.1.1 &>/dev/null; then
    exit 0
fi

log "Container internet broken (tested via $TEST_CONTAINER) — restarting Docker Desktop"

osascript -e 'tell application "Docker Desktop" to quit' 2>/dev/null || \
    osascript -e 'quit app "Docker"' 2>/dev/null || true

sleep 5
open -a "Docker"

log "Docker Desktop restart triggered"
