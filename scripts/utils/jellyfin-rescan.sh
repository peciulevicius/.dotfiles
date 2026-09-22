#!/bin/bash
# Force Jellyfin to notice new files on the NAS.
#
# Why this exists: Jellyfin's real-time file watcher does not reliably see
# changes on an SMB-mounted share (/Volumes/media) — the same class of
# limitation documented elsewhere in this repo for other services on the NAS.
# Confirmed 2026-09-22: a movie sat fully downloaded and imported by Radarr
# for several minutes with zero Jellyfin activity, until the container was
# restarted — which forces a full library scan on startup and picked it up
# immediately.
#
# This is the blunt fix: restart on a schedule, not the surgical one. The
# surgical fix is a Jellyfin API key wired into Radarr/Sonarr's own "Connect"
# integration, which pings Jellyfin to refresh just the new item right after
# import — no full restart, no brief playback interruption for anyone
# streaming. Needs one thing only a person can do: Jellyfin dashboard →
# Admin → API Keys → "+" → copy the key. Once that exists, this script (and
# the cron line for it) can be deleted in favor of that integration.

set -euo pipefail
docker restart jellyfin >/dev/null
echo "Jellyfin restarted — forces a library scan on startup"
