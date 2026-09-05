# NAS — UGREEN DH4300 Plus

How storage works after the 2026-08-04 migration, and where to look when
something breaks.

## The mental model

```
UGREEN NAS (addressed as DH4300PLUS-DP.local — see "Addressing" below, RAID 5, ~11TiB)
  └── SMB shares: media, immich, audiobooks, books, unsorted
        └── mounted on Mac mini at /Volumes/<share>  (user: macmini)
              └── Docker containers bind-mount those paths (set in .env files)
```

The NAS **stores**, the Mac mini **computes**. No service runs on the NAS
except Tailscale (Docker). Databases live on the Mac mini's internal SSD —
never on SMB (they corrupt over network mounts).

## Addressing — always use the mDNS name, never an IP

The NAS is **not** on a DHCP reservation, and its IP has drifted three times
(`.73` → `.106` → `.75` → `.73`). Each drift silently broke every NAS-backed
service until someone was home to notice — the 2026-09-05 outage ran ~7 days.

So everything now addresses the NAS by its Bonjour/mDNS name, which follows it
to whatever IP it holds:

```
DH4300PLUS-DP.local
```

Verified to resolve from the host, from cloudflared, from inside Docker
containers, and for SMB mounts (the login keychain matches on it fine).
**Don't reintroduce a hard-coded IP** — that is what kept breaking. A router
DHCP reservation is still worth doing as belt-and-braces (TODO #22), but is no
longer load-bearing.

Used in: `scripts/utils/mount-nas.sh`, `services/glance/glance.yml` (NAS tile),
`~/.cloudflared/config.yml` (nas ingress). `mount-nas.sh` keeps a numeric
fallback list purely for the case where mDNS itself is unavailable.

## Self-healing

Two launchd agents, both every 5 min:

| Agent | Script | Covers |
|---|---|---|
| `com.peciulevicius.docker-watchdog` | `scripts/utils/docker-watchdog.sh` | Docker Desktop/engine down or hung |
| `com.peciulevicius.nas-watchdog` | `scripts/utils/nas-watchdog.sh` | Shares unmounted → remount; NAS-backed containers exited → `compose up -d` |

`nas-watchdog.sh` deliberately remounts **before** touching containers: start a
container while its bind path is missing and Docker creates an empty directory
on the internal SSD, so the service comes up pointing at nothing.

Logs: `/opt/homebrew/var/log/{docker,nas}-watchdog.log`

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
2. **NAS reachable?** `nc -z DH4300PLUS-DP.local 445` — fails → NAS is off or
   off the network (IP drift no longer matters, see Addressing above) →
   check Glance tile / power
3. **Wrong path in config?** `cat ~/services/<name>/.env` — compare with
   table above
4. **Container started before mount existed?**
   `cd ~/services/<name> && docker compose restart`
5. **NAS side:** nas.peciulevicius.com → Storage (pool healthy?) →
   Control Panel → Shared Folder (share exists, `macmini` has R/W?)

## Putting your own files on the NAS

From any Mac at home: Finder → Cmd+K → `smb://DH4300PLUS-DP.local` (away from
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
