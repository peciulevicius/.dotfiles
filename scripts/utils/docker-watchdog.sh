#!/usr/bin/env bash
# docker-watchdog.sh — restarts Docker Desktop if containers lose internet access
# Runs every 5 minutes via launchd

set -euo pipefail

LOG="/opt/homebrew/var/log/docker-watchdog.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

log() { echo "[$TIMESTAMP] $1" >> "$LOG"; }

# Check if Docker daemon is running
if ! /usr/local/bin/docker info &>/dev/null 2>&1 && ! /opt/homebrew/bin/docker info &>/dev/null 2>&1 && ! docker info &>/dev/null 2>&1; then
    log "Docker daemon not running — launching Docker Desktop"
    open -a "Docker"
    exit 0
fi

# Check if any container exists to test with
TEST_CONTAINER=$(docker ps --format "{{.Names}}" 2>/dev/null | head -1)
if [[ -z "$TEST_CONTAINER" ]]; then
    log "No running containers to test — skipping"
    exit 0
fi

# Test internet access from a container
if docker exec "$TEST_CONTAINER" wget -q -O /dev/null --timeout=5 https://1.1.1.1 &>/dev/null; then
    # Internet works fine
    exit 0
fi

log "Container internet broken (tested via $TEST_CONTAINER) — restarting Docker Desktop"

# Quit Docker Desktop gracefully
osascript -e 'tell application "Docker Desktop" to quit' 2>/dev/null || \
    osascript -e 'quit app "Docker"' 2>/dev/null || true

sleep 5

# Relaunch
open -a "Docker"

log "Docker Desktop restart triggered"
