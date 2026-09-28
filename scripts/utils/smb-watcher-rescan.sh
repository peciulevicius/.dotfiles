#!/bin/bash
# Force services with an SMB-mounted library to notice new files.
#
# Why this exists: a media server's real-time file watcher does not reliably
# see changes on an SMB-mounted share — the same class of limitation
# documented elsewhere in this repo for other services on the NAS.
#
# Confirmed 2026-09-22 for Jellyfin (/Volumes/media): a movie sat fully
# downloaded and imported by Radarr for several minutes with zero Jellyfin
# scan activity, until the container was restarted — which forces a full
# library scan on startup and picked it up immediately.
#
# Audiobookshelf (/Volumes/audiobooks) runs its own watcher on the identical
# SMB-mounted pattern. No confirmed failure yet — added preventively, not
# reactively, since the root cause is architectural, not Jellyfin-specific.
#
# This is the blunt fix: restart on a schedule, not the surgical one. The
# surgical fix is an API key from each service wired into Radarr/Sonarr's
# (Jellyfin) and LazyLibrarian's (Audiobookshelf, if it supports it) own
# "notify on import" integration — refreshes just the new item, no restart,
# no brief interruption for anyone using it. Needs one thing only a person
# can do per service: generate the key in that service's own dashboard. Once
# both exist, this script (and its cron line) can be deleted.

# 2026-09-28: removed from cron. Both apps now scale to zero (Sablier), and
# every Sablier start is a fresh container start = a full library scan, so a
# timed restart is unnecessary. Worse, `docker restart` also STARTS a stopped
# container, so the 30-minute cron kept both awake permanently and cut off
# anyone mid-stream. Kept for manual use; it now only restarts what is
# already running.

set -euo pipefail
for c in jellyfin audiobookshelf; do
  if [[ "$(docker inspect -f '{{.State.Running}}' "$c" 2>/dev/null)" == "true" ]]; then
    docker restart "$c" >/dev/null && echo "$c restarted — forces a library scan"
  else
    echo "$c asleep — skipped (it scans on its next start)"
  fi
done
