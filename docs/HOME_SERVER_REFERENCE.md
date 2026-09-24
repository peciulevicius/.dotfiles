# Home server reference

Facts about the Mac mini homelab: capacity, storage layout, backups and known
platform behaviours. Outstanding work is in
[HOME_SERVER_TODO.md](HOME_SERVER_TODO.md); completed work in
[HOME_SERVER_CHANGELOG.md](HOME_SERVER_CHANGELOG.md).

---

## Memory

Mac mini M4, **16GB unified memory**. The Docker VM ceiling is **10GB** (raised
from 7.8GB on 2026-07-23). It is a ceiling, not a reservation; the VM allocates
lazily.

| Date | Containers | Container memory | Notes |
|---|---|---|---|
| 2026-09-08 | 42 | 5.2GiB | 43% free, ~2.5GB swap |
| 2026-09-19 | 39 | 5.55GiB | ~4.1GiB headroom in the VM |
| 2026-09-21 (peak) | 42 | 7.59GiB of 9.7GiB | 2.11GiB headroom, 30% free, ~3.3GB swap — after adding Odysseus |
| 2026-09-21 (later) | 38 | **5.81GiB** | After removing Mealie and Grafana/Prometheus/node-exporter (~1.78GiB reclaimed) |

Odysseus stack: odysseus ~745MB, searxng ~141MB, ntfy ~45MB, chromadb ~28MB.

Largest consumers (2026-09-19): `immich_server` ~839MB, `paperless` ~374MB,
`stirling_pdf` ~360MB, `flaresolverr` ~302MB, `calibre` ~299MB.

**Reading macOS memory:** a low "pages free" count is normal, since macOS uses
spare memory as cache. Judge by memory-pressure percentage and by whether swap is
growing. Stable swap is fine even at 2.5GB; growing swap with pressure below
~20% is the warning sign.

**Containers that can be stopped while travelling:** `nextcloud`,
`nextcloud_db`, `pihole`, `bazarr`, `sonarr`, `radarr`, `prowlarr`,
`transmission`, `jellyseerr`, `immich_machine_learning`.

This budget is why Octopus Deploy was not deployed
([guides/OCTOPUS_DEPLOY.md](guides/OCTOPUS_DEPLOY.md)).

---

## Storage layout

Since the 2026-08-04 migration the **NAS is primary storage**. The external
SSDs are backup targets, normally unplugged and synced manually.

| Device | Capacity | Role | Mount path | Connected |
|---|---|---|---|---|
| UGREEN NAS | ~11TiB usable (RAID 5) | Primary storage | `/Volumes/<share>` | Always, over SMB |
| Samsung T7 | 1TB | Manual backup | `/Volumes/T7/` | Normally unplugged |
| Samsung T5 | 500GB | Manual backup, planned offsite | `/Volumes/Backup/` | Normally unplugged |

Paths under `/Volumes/T7` in documentation or scripts describe what to do when
the drive is plugged in; they are not live mounts.

| Data | Location | Path |
|---|---|---|
| Immich photos | NAS | `/Volumes/immich/upload` |
| Immich database | Internal SSD | `~/services/immich/data/postgres` |
| Immich thumbnails | Internal SSD | `~/services/immich/data/thumbs` (regenerable) |
| Movies, TV, downloads | NAS | `/Volumes/media/` |
| Audiobooks | NAS | `/Volumes/audiobooks/` |
| Calibre library | NAS (moving to the SSD) | `BOOKS_DIR` in `~/services/calibre/.env` |
| CouchDB (Obsidian sync) | Internal SSD | `~/services/couchdb/data` |
| Obsidian vault | Internal SSD | `~/obsidian-vault` |
| Docker data | Internal SSD | `~/Library/Containers/com.docker.docker` |

**Databases never live on SMB**; they corrupt over network filesystems.

Photos are managed by Immich on the NAS. About 140GB of older year and trip
folders on T7 (also copied to T5) have not been imported into Immich yet; do
not wipe T7 until they are.

### Container paths

| Service | Container path | Host path |
|---|---|---|
| Radarr/Sonarr media | `/media` | `/Volumes/media` |
| Radarr movies | `/media/movies` | `/Volumes/media/movies` |
| Sonarr TV | `/media/tv` | `/Volumes/media/tv` |
| Transmission downloads | `/downloads` | `/Volumes/media/downloads` |
| Audiobookshelf | `/audiobooks` | `/Volumes/audiobooks` |
| Calibre library | `/books` | `BOOKS_DIR` (`/Volumes/books` today) |
| Immich photos | `/usr/src/app/upload` | `/Volumes/immich/upload` |
| Immich thumbnails | `/usr/src/app/upload/thumbs` | `~/services/immich/data/thumbs` |
| Immich database | `/var/lib/postgresql/data` | `~/services/immich/data/postgres` |

NAS mounts and troubleshooting: [NAS.md](NAS.md).

---

## Backups

### Cloud: rclone → Cloudflare R2, nightly at 05:00

| Set | Source | Notes |
|---|---|---|
| Service configs | `~/services` | `.env` files, databases (dumped separately), large media and regenerable caches excluded |
| Obsidian vault | `~/obsidian-vault` | |
| Database dumps | `~/backups` | Weekly `pg_dump` / `mariadb-dump` |
| Calibre library | `BOOKS_DIR` | |
| Immich originals | `/Volumes/immich/upload/upload` | Enabled 2026-09-21: 72.4GB, 6,696 files. Transcodes, thumbnails and Immich's own DB backups are excluded as regenerable or redundant. |

- Cron runs the staged copy `~/services/rclone/rclone-backup.sh` with its
  configuration in `~/services/rclone/.env`. Keep one script path and one
  `.env`: two copies once silently dropped the Immich step.
- Cost: about $1/month (everything except photos is ~2.9GB, within the free
  tier).
- **Verified monthly** by `scripts/backup/r2-verify.sh`, which restores one
  random file per set, compares it byte for byte, and records sizes in
  `~/logs/r2-size-history.tsv`.
- **Restore** with `scripts/backup/restore.sh` (`list`, `service <name>`,
  `set vault|dumps|books|photos`) into `~/services-restore/`; `restore.sh db`
  loads a dump into its container.

Details: `services/rclone/README.md`.

### Local: rsync NAS → external drive, manual

```bash
~/.dotfiles/scripts/backup/backup-external.sh /Volumes/T7        # or /Volumes/Backup for T5
```

- Covers Immich originals and transcoded video, database dumps, audiobooks and
  the Calibre library. Skips movies and TV (large, re-downloadable) and Immich
  thumbnails (regenerable).
- Each successful run writes `~/logs/external-backup-<drive>.last`; the weekly
  audit fails when a drive is more than 30 days out of date.
- Both drives were verified 1:1 against the NAS on 2026-09-05.

### Failure scenarios

| Failure | Recovery |
|---|---|
| NAS | Photos, books, audiobooks and database dumps from T7/T5 and R2; configs from R2; media re-downloaded |
| One external drive | Re-run the backup to a replacement |
| Mac mini | Data is on the NAS; reinstall macOS, clone the dotfiles, restore configs from R2 |
| Site loss (fire, flood, theft) | R2 holds configs, vault, dumps, books and photo originals. Moving T5 offsite adds a physical copy. |

---

## Known platform behaviours

### Cloudflare Tunnel limits uploads to 100MB

The free Cloudflare plan limits request bodies to 100MB. Larger uploads through
`*.peciulevicius.com` fail, and the error comes from the application (for
example Calibre-Web reports *"File size may be too big"*). Downloads are not
affected.

| Route | Address | Upload limit |
|---|---|---|
| Public hostname | `https://<svc>.peciulevicius.com` | 100MB |
| Tailscale | `http://100.81.171.49:<port>` | None |
| On the Mac mini | `http://localhost:<port>` | None |

The homepage has a **Direct (no tunnel)** bookmark group with Tailscale URLs for
the upload-heavy services (Calibre-Web, Immich, Nextcloud, Paperless).

A failed large upload can leave a library half-written: one 750MB attempt left
a Calibre record without a file, a renamed folder the database no longer
matched, and a 733MB `.smbdelete` duplicate.

### Two cloudflared LaunchAgents

```
~/Library/LaunchAgents/com.cloudflare.cloudflared.plist   # serves traffic
~/Library/LaunchAgents/sh.brew.cloudflared.plist          # Homebrew's agent, inactive
```

`brew services restart cloudflared` restarts the Homebrew agent and reports
success, while the real tunnel keeps running with the old configuration in
memory. To reload after editing `~/.cloudflared/config.yml`:

```bash
launchctl kickstart -k "gui/$(id -u)/com.cloudflare.cloudflared"
ps aux | grep "[c]loudflared tunnel"     # confirm the PID and start time changed
```

`brew services stop cloudflared` can be run once to clear the inactive agent's
error state; it does not affect the tunnel.

### Credentials stored by clients

Rotating a password on a service does not update clients that keep their own
copy. After Transmission's password was rotated on 2026-09-19, Radarr, Sonarr
and LazyLibrarian failed to authenticate for three days while every request
appeared accepted upstream.

| Rotated | Also stored in | Check |
|---|---|---|
| Transmission | Radarr, Sonarr, LazyLibrarian (download client settings) | `/api/v3/downloadclient/test` for Radarr/Sonarr |
| An `@peciulevicius.com` alias | Any service that uses it as the login | Per service |

After any rotation, search for the old value across all service configuration
(`grep -rl "<old value>" ~/services/`) and test each consumer. The
`credential-rotation` project skill encodes this procedure.

### Malicious releases disguised as media

Fake releases sometimes contain an executable instead of video. On 2026-09-22 a
grabbed movie release turned out to be a single 1.15GB `.exe`.

- **Legitimate:** one `.mkv`/`.mp4`/`.avi` makes up most of the size, possibly
  with `.srt`, `.nfo` or small `.txt` files.
- **Suspicious:** the only substantial file is `.exe`, `.scr`, `.msi`, `.bat` or
  `.zip`.

Radarr and Sonarr have a **release profile** that rejects release names
containing `.exe .scr .lnk .msi .bat .cmd .vbs .jar`, `password.txt`,
`setup.exe` or `installer` before they reach the download client:

```bash
curl -s "http://localhost:7878/api/v3/releaseprofile" -H "X-Api-Key: <radarr-key>"
```

The filter only matches names that include the extension; it reduces the risk
rather than removing it. Never run files from `/Volumes/media`.

### Renaming books in Calibre-Web corrupts the entry (library on SMB)

Renaming a title or author in Calibre-Web while the library is on SMB failed
twice on 2026-09-21 in the same way:

1. Calibre-Web renames the folder.
2. It copies the EPUB to the new filename.
3. Deleting the original fails (*Device or resource busy*) because the Calibre
   content server holds the file open.
4. The database change is rolled back, the folder rename is not.

Repair:

```bash
sqlite3 "$BOOKS_DIR/metadata.db" "select path from books where id=<ID>;"
mv "$BOOKS_DIR/<wrong name>" "$BOOKS_DIR/<path from the DB>"
```

The leftover duplicate is usually locked by the NAS and has to be removed from
the NAS file manager; it is excluded from the R2 backup.

| Goal | Method |
|---|---|
| Mark a book (for example as read-along) | Add a **tag**. Tags are metadata only and appear as a category in the OPDS feed. |
| Change the title | Set it in the EPUB before importing: `ebook-meta book.epub --title "Title (read-along)"` |
| Any other renaming | Use the Calibre desktop app with a local library |

Moving the library to the SSD (`scripts/utils/migrate-calibre-to-ssd.sh`)
removes the underlying cause.

### SMB leaves `.smbdelete*` files

When a file on an SMB share is deleted while still open, the server renames it
to `.smbdeleteXXXX` until every handle closes. These are full copies (one was
733MB).

```bash
find /Volumes/books -name ".smbdelete*" -exec ls -lh {} \; 2>/dev/null
find /Volumes/books -name ".smbdelete*" -delete     # "Resource busy" means still held
```

Restarting `calibre`, `calibre-web` and `lazylibrarian` releases most of them;
the rest need removal from the NAS itself. The R2 and external backups exclude
them.

### File watchers miss new files on SMB

Real-time file watching does not work reliably on SMB mounts. Confirmed for
Jellyfin (`/Volumes/media`) on 2026-09-22: an imported movie was not detected
until the container restarted. Audiobookshelf (`/Volumes/audiobooks`) uses the
same pattern.

- **Current workaround:** `scripts/utils/smb-watcher-rescan.sh` restarts both
  containers every 30 minutes (cron).
- **Planned fix:** a Jellyfin API key configured in Radarr and Sonarr
  (Settings → Connect) triggers a targeted refresh on import, with no restart.
  Audiobookshelf has no documented notify-on-import hook from LazyLibrarian as
  of 2026-09-22; its API may offer a per-folder scan.
