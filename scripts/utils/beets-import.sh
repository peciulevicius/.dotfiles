#!/bin/bash
# Import music dropped into the NAS Incoming/ folder into the beets library.
#
#   /Volumes/media/music/Incoming/  →  beet import -q  →  /Volumes/media/music/Library/Artist/Album/
#
# Why cron and not a watcher: the share is SMB-mounted, and inotify never
# fires for changes on SMB (the same limitation smb-watcher-rescan.sh works
# around for Jellyfin). So cron runs this every 10 minutes and it exits
# immediately when there is nothing to do.
#
# Two guards:
#   - settle time: skip the run while anything in Incoming/ was modified in the
#     last SETTLE_MIN minutes, so an album still copying over SMB isn't
#     imported half-finished;
#   - lock: skip if a previous import is still running (large FLAC albums with
#     art fetching can take longer than the cron interval).
#
# Files beets refuses (e.g. an album already in the library — quiet mode skips
# duplicates) stay in Incoming/ and are retried each run; the import log is
# /config/import.log inside the container (~/services/beets/data/config/).

set -euo pipefail

INCOMING="${MUSIC_DIR:-/Volumes/media/music}/Incoming"
SETTLE_MIN="${SETTLE_MIN:-2}"
LOCK_DIR="${TMPDIR:-/tmp}/beets-import.lock"

if [[ ! -d "$INCOMING" ]]; then
  echo "Incoming folder not found: $INCOMING (is the NAS mounted?)" >&2
  exit 1
fi

# Ignore macOS/SMB metadata that Finder leaves behind.
has_files() {
  find "$INCOMING" -type f ! -name '.DS_Store' ! -name '._*' ! -name '.smbdelete*' "$@" -print -quit | grep -q .
}

has_files || exit 0

if (( SETTLE_MIN > 0 )) && has_files -mmin "-$SETTLE_MIN"; then
  echo "$(date '+%F %T') Incoming still changing — waiting for the next run"
  exit 0
fi

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo "$(date '+%F %T') previous import still running — skipping"
  exit 0
fi
trap 'rmdir "$LOCK_DIR"' EXIT

echo "$(date '+%F %T') importing from $INCOMING"
docker exec beets beet import -q /music/Incoming
echo "$(date '+%F %T') import finished"
