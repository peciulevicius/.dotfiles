# NAS — UGREEN DH4300 Plus

How storage works after the 2026-08-04 migration, and where to look when
something breaks.

## The mental model

```
UGREEN NAS (192.168.1.73, RAID 5, ~11TiB)
  └── SMB shares: media, immich, audiobooks, books, unsorted
        └── mounted on Mac mini at /Volumes/<share>  (user: macmini)
              └── Docker containers bind-mount those paths (set in .env files)
```

The NAS **stores**, the Mac mini **computes**. No service runs on the NAS
except Tailscale (Docker). Databases live on the Mac mini's internal SSD —
never on SMB (they corrupt over network mounts).

## Where paths are configured

Each service = one folder in `~/services/<name>/` with `docker-compose.yml`
(generic, uses variables) and `.env` (the actual paths). Storage lives in
`.env` only:

| Service | .env variable | Points at |
|---------|--------------|-----------|
| jellyfin, sonarr-radarr, transmission, bazarr | `MEDIA_DIR` | `/Volumes/media` |
| immich | `UPLOAD_LOCATION` | `/Volumes/immich/upload` |
| immich | `DB_DATA_LOCATION` | `./data/postgres` (internal SSD!) |
| audiobookshelf, readarr | `AUDIOBOOKS_DIR` | `/Volumes/audiobooks` |
| calibre, calibre-web, lazylibrarian, readarr | `BOOKS_DIR` | `/Volumes/books` |
| lazylibrarian | `DOWNLOADS_DIR` | `/Volumes/media/downloads` |

Find every storage reference: `grep -rn "/Volumes" ~/services/*/.env`

After changing a `.env`: `cd ~/services/<name> && docker compose up -d`
(recreates the container with the new path).

## Mounts (how /Volumes/<share> appears)

- `scripts/utils/mount-nas.sh` mounts all five shares via SMB as user
  `macmini` (password in macOS login keychain)
- Runs at login via LaunchAgent `com.peciulevicius.mount-nas`
  (`~/Library/LaunchAgents/com.peciulevicius.mount-nas.plist`)
- Log: `/opt/homebrew/var/log/mount-nas.log`
- Manual remount any time: `bash ~/.dotfiles/scripts/utils/mount-nas.sh`

## Troubleshooting: service can't see its files

Work down this ladder — it's almost always #1:

1. **Mount gone?** `ls /Volumes/media` — empty/missing → run
   `bash ~/.dotfiles/scripts/utils/mount-nas.sh`, check its log
2. **NAS reachable?** `nc -z 192.168.1.73 445` — fails → NAS off/IP changed
   (check router; reservation should pin 192.168.1.73) → check Glance tile
3. **Wrong path in config?** `cat ~/services/<name>/.env` — compare with
   table above
4. **Container started before mount existed?**
   `cd ~/services/<name> && docker compose restart`
5. **NAS side:** nas.peciulevicius.com → Storage (pool healthy?) →
   Control Panel → Shared Folder (share exists, `macmini` has R/W?)

## Putting your own files on the NAS

From any Mac at home: Finder → Cmd+K → `smb://192.168.1.73` (away from
home: same but via Tailscale, or use nas.peciulevicius.com → Files app in
the browser, or UGREEN mobile apps). Then drag & drop like a normal disk.

- Media/books/audiobooks → the matching share (services pick them up)
- Anything unsorted or "deal with later" → `unsorted` (the inbox —
  gets emptied into proper places, see TODO #20)
- New kinds of data (documents, projects…) → create a new shared folder
  on the NAS + give `macmini` R/W + add it to `SHARES` in `mount-nas.sh`

## Accounts

- `Džiugas` — human admin, web UI only (non-ASCII name breaks SMB)
- `macmini` — SMB service account used by the Mac mini for all mounts

## T7 retirement plan

T7 keeps the pre-migration copy as fallback. Before unplugging:
1. Update rclone/T5 backup scripts to read from NAS paths
2. A few days of green backups + stable services
3. Then: wipe, repurpose as local backup target (T5 stays offsite)
