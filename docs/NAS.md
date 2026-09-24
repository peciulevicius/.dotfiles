# NAS (UGREEN DH4300 Plus)

Storage architecture since the 2026-08-04 migration, and troubleshooting.

## Architecture

```
UGREEN NAS — DH4300PLUS-DP.local, RAID 5, ~11TiB
  └── SMB shares: media, immich, audiobooks, books, unsorted
        └── mounted on the Mac mini at /Volumes/<share> (SMB user: macmini)
              └── bind-mounted into containers (paths set in each .env)
```

The NAS stores; the Mac mini computes. The only container on the NAS is
Tailscale. **Databases live on the Mac mini's internal SSD, never on SMB**,
because SQLite and PostgreSQL corrupt over network filesystems.

Hardware: 4-bay, RK3588C (8-core ARM), 8GB RAM, 2.5GbE, 3 × 6TB IronWolf Pro in
RAID 5 (Btrfs).

## Addressing

**Always address the NAS by its mDNS name, never by IP:**

```
DH4300PLUS-DP.local
```

The NAS has no DHCP reservation, and its IP changed three times before this
rule; each change broke every NAS-backed service until noticed (the 2026-09-05
outage lasted about seven days). The mDNS name resolves from the host, from
cloudflared, from inside containers and for SMB mounts. A router DHCP
reservation is still planned, but nothing depends on it.

Used in `scripts/utils/mount-nas.sh`, `services/glance/glance.yml` (NAS tile)
and `~/.cloudflared/config.yml` (NAS ingress). `mount-nas.sh` keeps a numeric
fallback list only for when mDNS itself is unavailable.

## Mounts

- `scripts/utils/mount-nas.sh` mounts all five shares over SMB as `macmini`,
  with the password in the macOS login keychain.
- It runs at login via the LaunchAgent `com.peciulevicius.mount-nas`
  (`~/Library/LaunchAgents/com.peciulevicius.mount-nas.plist`).
- Log: `/opt/homebrew/var/log/mount-nas.log`
- Manual remount: `bash ~/.dotfiles/scripts/utils/mount-nas.sh`

## Self-healing

Two launchd agents run every five minutes:

| Agent | Script | Handles |
|---|---|---|
| `com.peciulevicius.docker-watchdog` | `scripts/utils/docker-watchdog.sh` | Docker Desktop or the engine down or hung |
| `com.peciulevicius.nas-watchdog` | `scripts/utils/nas-watchdog.sh` | Unmounted shares (remount), exited NAS-backed containers (`compose up -d`) |

`nas-watchdog.sh` remounts **before** starting containers. A container started
while its bind path is missing gets an empty directory created on the internal
SSD and runs against it.

Logs: `/opt/homebrew/var/log/{docker,nas}-watchdog.log`

## Path configuration

Each service lives in `~/services/<name>/`, with a generic
`docker-compose.yml` and the actual storage paths in `.env`:

| Service | Variable | Value |
|---|---|---|
| jellyfin, sonarr-radarr, transmission, bazarr | `MEDIA_DIR` | `/Volumes/media` |
| immich | `UPLOAD_LOCATION` | `/Volumes/immich/upload` |
| immich | `DB_DATA_LOCATION` | `./data/postgres` (internal SSD) |
| audiobookshelf, lazylibrarian | `AUDIOBOOKS_DIR` | `/Volumes/audiobooks` |
| calibre, calibre-web, lazylibrarian | `BOOKS_DIR` | `/Volumes/books`; moving to `~/services/calibre/library` on the SSD via `scripts/utils/migrate-calibre-to-ssd.sh` |
| lazylibrarian | `DOWNLOADS_DIR` | `/Volumes/media/downloads` |

```bash
grep -rn "/Volumes" ~/services/*/.env              # every storage reference
cd ~/services/<name> && docker compose up -d       # apply a changed .env
```

## Troubleshooting: a service cannot see its files

Check in order; the first step is the usual cause.

1. **Mount missing.** `ls /Volumes/media` is empty or missing → run
   `bash ~/.dotfiles/scripts/utils/mount-nas.sh` and check its log.
2. **NAS unreachable.** `nc -z DH4300PLUS-DP.local 445` fails → the NAS is off
   or off the network; check power and the Glance tile.
3. **Wrong path.** Compare `~/services/<name>/.env` with the table above.
4. **Container started before the mount.**
   `cd ~/services/<name> && docker compose restart`
5. **NAS side.** `nas.peciulevicius.com` → Storage (pool healthy?) → Control
   Panel → Shared Folder (share exists; `macmini` has read/write?).

## Adding files

From a Mac at home: Finder → ⌘K → `smb://DH4300PLUS-DP.local`. Remotely: the
same over Tailscale, the web file manager at `nas.peciulevicius.com`, or the
UGREEN mobile apps.

- Media, books, audiobooks → the matching share; services pick them up.
- Unsorted material → `unsorted`, an inbox to be filed later.
- A new category of data → create a shared folder on the NAS, grant `macmini`
  read/write, and add it to `SHARES` in `mount-nas.sh`.

## Accounts

| Account | Use |
|---|---|
| Personal admin account | Web UI only. Its non-ASCII name breaks SMB authentication. |
| `macmini` | SMB service account for all Mac mini mounts |

## External drives

- **T7:** holds the pre-migration copy as a fallback. Backup scripts already
  read from NAS paths. Once backups have run green for a period, it can be
  wiped and reused as a local backup target.
- **T5:** verified 1:1 against the NAS on 2026-09-05; planned as the offsite
  copy.

`scripts/backup/backup-external.sh` backs up to either drive and records the
date; the weekly audit reports a drive that has not been backed up for more
than 30 days.
