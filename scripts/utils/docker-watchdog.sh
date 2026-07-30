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
NET_FAILS_FILE="${TMPDIR:-/tmp}/docker-watchdog.netfails"
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

# Engine is up — verify containers can reach the internet.
# Not every image ships curl/wget (a missing binary looked like "no
# internet" and caused a 40h restart loop, 2026-07-29). Probe several
# containers, skip ones without a usable tool, and only conclude
# "broken" from a test that actually ran. Plain-http endpoint because
# busybox wget can't do TLS.
NET_RESULT="untested"
while IFS= read -r c; do
    tool=$(docker exec "$c" sh -c 'command -v curl || command -v wget' 2>/dev/null | head -1)
    case "$tool" in
        */curl|curl)
            if docker exec "$c" curl -s -o /dev/null --max-time 5 http://captive.apple.com &>/dev/null; then
                NET_RESULT="ok"
            else
                NET_RESULT="broken (tested via $c/curl)"
            fi
            break ;;
        */wget|wget)
            if docker exec "$c" wget -q -O /dev/null -T 5 http://captive.apple.com &>/dev/null; then
                NET_RESULT="ok"
            else
                NET_RESULT="broken (tested via $c/wget)"
            fi
            break ;;
    esac
done < <(docker ps --format "{{.Names}}" 2>/dev/null | head -8)

case "$NET_RESULT" in
    ok) rm -f "$NET_FAILS_FILE"; exit 0 ;;
    untested) log "No container with curl/wget in first 8 — skipping net test"; exit 0 ;;
esac

# Cap consecutive net-triggered restarts: if 3 restarts haven't fixed
# it, restarting isn't the cure — stop flapping and leave Docker up.
net_fails=$(( $(cat "$NET_FAILS_FILE" 2>/dev/null || echo 0) + 1 ))
echo "$net_fails" > "$NET_FAILS_FILE"
if (( net_fails > 3 )); then
    log "Container internet $NET_RESULT — restart cap reached ($net_fails), NOT restarting"
    exit 0
fi

log "Container internet $NET_RESULT — restarting Docker Desktop ($net_fails/3)"

osascript -e 'tell application "Docker Desktop" to quit' 2>/dev/null || \
    osascript -e 'quit app "Docker"' 2>/dev/null || true

# Wait for the app to actually exit before relaunching — 'open -a'
# during shutdown is a no-op and the relaunch never happened
for _ in $(seq 1 12); do
    pgrep -qf "Docker.app/Contents/MacOS/com.docker.backend" || break
    sleep 5
done
pkill -9 -f "Docker.app/Contents" 2>/dev/null || true
sleep 3
open -a "Docker"

log "Docker Desktop restart triggered"
