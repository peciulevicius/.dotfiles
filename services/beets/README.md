# beets — music library organiser

**What:** [beets](https://beets.readthedocs.io) takes audio files dropped into
`Incoming/` on the NAS, looks them up on MusicBrainz, fixes the tags, fetches
and embeds cover art, adds a genre from Last.fm, strips junk metadata, and
moves them into a clean `Library/Artist/Album/NN Title.ext` tree. Jellyfin
serves `Library/`; Finamp on the phone plays it.

**Why:** adding music should be "drop the files in a folder", with no manual
tagging or folder naming. Beets itself has no downloader: it handles music you
buy DRM-free and add by hand. Lidarr separately manages automated album
acquisition into `Library/`; Beets continues to process hand-added files from
`Incoming/`.

## Adding music

1. **Buy DRM-free files:**
   - **Bandcamp** — FLAC or MP3; the app/site has a download button per purchase.
   - **Qobuz** — FLAC downloads.
   - **iTunes Store** — purchases are DRM-free AAC; download them in the Music
     app, then find the files in `~/Music/Music/Media/`.
2. **Drop the album folder (or loose tracks) into**
   `smb://DH4300PLUS-DP.local/media/music/Incoming/` — on the Mac mini that is
   `/Volumes/media/music/Incoming/`.
3. **Wait up to ~12 minutes.** Cron runs `scripts/utils/beets-import.sh` every
   10 minutes; it waits until nothing in `Incoming/` has changed for 2 minutes
   (so a half-copied album isn't imported), then runs `beet import -q`.
4. The album appears in `Library/Artist/Album/` and then in **Jellyfin →
   Music** and **Finamp**.

Something stuck in `Incoming/`? Check `~/logs/beets-import.log` and
`~/services/beets/data/config/import.log`. The usual cause is a duplicate:
quiet mode skips an album that's already in the library, and the files stay
behind (retried every run, harmlessly). Import it by hand to choose:

```bash
docker exec -it beets beet import /music/Incoming    # interactive
```

## How it works

| Piece | Where |
|---|---|
| Container | `lscr.io/linuxserver/beets`, pinned; main process is `beet web` (read-only browser UI) on **8337**, Tailscale only |
| Config | `services/beets/config.yaml` → staged to `~/services/beets/config.yaml`, bind-mounted over `/config/config.yaml` |
| Library DB | `~/services/beets/data/config/musiclibrary.blb` (SQLite, on the internal SSD — never on SMB) |
| Music | `/Volumes/media/music` → `/music` (one mount, so an import is a rename, not copy + delete) |
| Trigger | `scripts/utils/beets-import.sh`, cron `*/10` via `run-with-notify.sh` (Discord on failure) |
| Jellyfin | mounts `music/Library` read-only at `/media/music` |

Key settings (`config.yaml`):

- `import: move: yes, write: yes, quiet: yes, quiet_fallback: asis` — no
  prompts; if MusicBrainz has no confident match the files are imported with
  their own tags instead of being skipped.
- `paths: default: $albumartist/$album%aunique{}/$track $title`,
  `singleton: Singles/$artist - $title`.
- Plugins: `musicbrainz` (the autotagger's source — a plugin since beets 2.4,
  so it must be listed), `fetchart`, `embedart`, `lastgenre`, `scrub`,
  `duplicates` (`beet duplicates` to list dupes), `web` (the container's main
  process runs `beet web`, so without it the service crash-loops).

**Why cron, not a watcher:** the share is SMB-mounted and inotify never fires
for SMB changes — the same reason `smb-watcher-rescan.sh` exists for Jellyfin.

**Why the config isn't under `data/`:** `services/**/data/` is gitignored, so a
config there can't live in this repo. It sits next to `docker-compose.yml` and
is bind-mounted in; `setup-services.sh` copies `*.yaml` like it does
`*.ini`/`*.conf`.

## Setup from scratch

```bash
mkdir -p /Volumes/media/music/Incoming /Volumes/media/music/Library
~/.dotfiles/services/setup-services.sh beets
mkdir -p ~/services/beets/data/config && touch ~/services/beets/data/config/config.yaml
cd ~/services/beets && docker compose up -d
crontab < ~/.dotfiles/scripts/cron/crontab
```

The `touch` matters: Docker Desktop can't create a single-file bind mount
inside another bind mount (`/config`), and fails the first `up` with
`mountpoint … is outside of rootfs`. With the placeholder file present it
works (a second `up` also works, because the failed one leaves the file behind).

## Changing the config

```bash
cp ~/.dotfiles/services/beets/config.yaml ~/services/beets/config.yaml
diff ~/.dotfiles/services/beets/config.yaml ~/services/beets/config.yaml
docker restart beets
docker exec beets beet config | head    # confirm it loaded
```

## Gotchas

- **Deleting on the SMB share leaves `.smbdelete*` ghosts** while Docker
  Desktop's virtualization process holds the file open (seen with
  `beet remove -d` and plain `rm`). They clear when Docker Desktop restarts,
  same as the Calibre/Immich ones in `HOME_SERVER_TODO.md`. Moves (the normal
  import path) are unaffected.
- `beet remove -d` from inside the container removed the DB rows but the file
  lingered as one of those ghosts — prefer removing albums in beets **and**
  checking `Library/` afterwards.

## Backups

`~/services/beets/` is covered by the nightly R2 sync like every service
directory (config + library DB, tiny) — no `rclone-backup.sh` change needed.
The music itself lives on the NAS (RAID 5) and is **not yet** in R2 or
`backup-external.sh` — purchases can be re-downloaded from the store, but see
the open item in `docs/HOME_SERVER_TODO.md`.
