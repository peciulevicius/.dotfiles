#!/bin/bash
# On-demand homelab services: stopped by default, started when needed.
#
#   ondemand.sh list               # state of every on-demand service
#   ondemand.sh start <name>       # start it, print its URL
#   ondemand.sh stop <name>        # stop it again
#   ondemand.sh stop-all           # stop every on-demand service
#   ondemand.sh containers         # container names (used by homelab-audit.sh)
#
# Why: the Mac mini has 16GB shared between macOS and a ~9.7GB Docker VM, and
# on 2026-09-26 macOS swap sat at 7.7/8GB. These services are used a few times
# a month, so they don't earn a permanent slice of RAM. They stay in the repo,
# stay staged in ~/services, and their data stays in the R2 backup — only the
# containers are stopped.
#
# How it stays stopped: `docker compose stop` (never `down`/`rm`) keeps the
# containers and networks, and with `restart: unless-stopped` a container
# stopped by hand stays stopped across Docker and Mac restarts. Watchtower runs
# with WATCHTOWER_INCLUDE_STOPPED=false, so it won't wake them either.
# ⚠️ A manual `docker compose up -d` in one of these dirs (e.g. the "update
# all services" loop) starts them again — run `ondemand.sh stop-all` after.
#
# The map below is the single source of truth: homelab-audit.sh treats these
# containers as expected-stopped, and backup-databases.sh briefly starts the
# DB containers to dump them.

set -uo pipefail

LIVE="$HOME/services"

# name|~/services dir|compose services (empty = whole stack)|local URL|remote URL
ENTRIES=(
  "paperless-ngx|paperless-ngx||http://localhost:8000|https://papers.peciulevicius.com"
  "nextcloud|nextcloud||http://localhost:8080|https://cloud.peciulevicius.com"
  "stirling-pdf|stirling-pdf||http://localhost:8084|https://pdf.peciulevicius.com"
  "it-tools|it-tools||http://localhost:8085|https://tools.peciulevicius.com"
  "odysseus|odysseus||http://localhost:7001|http://100.81.171.49:7001 (Tailscale)"
  "flaresolverr|sonarr-radarr|flaresolverr|http://localhost:8191|(internal — used by Prowlarr only)"
)

usage() { sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; }

lookup() {  # sets DIR SVCS URL REMOTE for a name, or fails
  local e n
  for e in "${ENTRIES[@]}"; do
    IFS='|' read -r n DIR SVCS URL REMOTE <<<"$e"
    [[ "$n" == "$1" ]] && { NAME="$n"; return 0; }
  done
  echo "Unknown on-demand service: $1" >&2
  echo "Known: $(names)" >&2
  return 1
}

names() { local e; for e in "${ENTRIES[@]}"; do printf '%s ' "${e%%|*}"; done; }

compose() {  # compose <args…> — run in the service dir (picks up overrides)
  ( cd "$LIVE/$DIR" && docker compose "$@" )
}

# shellcheck disable=SC2086  # $SVCS is intentionally word-split (may be empty)
containers_of() { compose ps -a --format '{{.Name}}' $SVCS 2>/dev/null; }

service_count() {  # `compose config --services` ignores a service filter
  if [[ -n "$SVCS" ]]; then echo "$SVCS" | wc -w | tr -d ' '
  else compose config --services 2>/dev/null | wc -l | tr -d ' '; fi
}

# shellcheck disable=SC2086
state_of() {
  local total running
  total=$(service_count)
  running=$(compose ps --status running -q $SVCS 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$running" -eq 0 ]]; then echo "stopped"
  elif [[ "$running" -ge "$total" ]]; then echo "running"
  else echo "partial ($running/$total)"; fi
}

cmd_list() {
  local e
  printf '%-14s %-16s %s\n' NAME STATE URL
  for e in "${ENTRIES[@]}"; do
    lookup "${e%%|*}" || continue
    printf '%-14s %-16s %s\n' "$NAME" "$(state_of)" "$URL"
  done
}

# shellcheck disable=SC2086
cmd_start() {
  lookup "$1" || return 1
  local total existing
  total=$(service_count)
  existing=$(compose ps -a -q $SVCS | wc -l | tr -d ' ')
  if [[ "$existing" -lt "$total" ]]; then
    echo "→ creating $NAME (docker compose up -d)"
    compose up -d $SVCS || return 1
  else
    echo "→ starting $NAME"
    compose start $SVCS || return 1
  fi
  echo "✓ $NAME is up"
  echo "    $URL"
  [[ -n "$REMOTE" ]] && echo "    $REMOTE"
  echo "  Stop it when done: ondemand stop $NAME"
}

# shellcheck disable=SC2086
cmd_stop() {
  lookup "$1" || return 1
  echo "→ stopping $NAME"
  compose stop $SVCS && echo "✓ $NAME stopped"
}

cmd_stop_all() {
  local e rc=0
  for e in "${ENTRIES[@]}"; do cmd_stop "${e%%|*}" || rc=1; done
  return $rc
}

cmd_containers() {
  local e
  for e in "${ENTRIES[@]}"; do lookup "${e%%|*}" && containers_of; done
}

case "${1:-list}" in
  list|ls|status) cmd_list ;;
  start)      [[ -n "${2:-}" ]] || { usage; exit 1; }; cmd_start "$2" ;;
  stop)       [[ -n "${2:-}" ]] || { usage; exit 1; }; cmd_stop "$2" ;;
  stop-all)   cmd_stop_all ;;
  containers) cmd_containers ;;
  -h|--help|help) usage ;;
  *) usage; exit 1 ;;
esac
