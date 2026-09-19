# Home Server — Reference

Facts about the machine, not work to do. Outstanding work lives in
[HOME_SERVER_TODO.md](HOME_SERVER_TODO.md); finished work in
[HOME_SERVER_CHANGELOG.md](HOME_SERVER_CHANGELOG.md).

---

### RAM baseline

Mac mini M4, **16GB unified memory**. Docker VM ceiling is now **10GB** (raised
from 7.8GB on 2026-07-23), but that is a *ceiling*, not a reservation — the VM
allocates lazily.

Measured 2026-09-19 with 39 containers running (karakeep x3 and actual-budget
stopped, couchdb added):

| Metric | Value | Reading |
|---|---|---|
| Containers, total | 5.55 GiB of the VM's 9.7 GiB | ~4.1 GiB headroom |
| macOS memory free | 39% | healthy |
| Swap used | ~2.8 GB of 4 GB | historical; watch whether it grows |
| Compressor occupied | ~7.4 GB | macOS working, but coping |

Previous baseline, 2026-09-08 with 42 containers: 5.2 GiB of containers, 43%
free, ~2.5 GB swap.

**How to read swap on macOS:** "Pages free" is always near zero by design — macOS
uses spare RAM as cache, so a low free-page count is not a warning. Judge by
*memory pressure percentage* and whether swap is **growing**. Stable or shrinking
swap is fine, even at 2.5GB. Growing swap plus pressure under ~20% is the real
alarm.

Biggest single consumers (2026-09-19): `immich_server` (~839MB), `paperless`
(~374MB), `stirling_pdf` (~360MB), `flaresolverr` (~302MB), `calibre` (~299MB).

**Containers safe to stop while traveling:**
`nextcloud`, `nextcloud_db`, `pihole`, `bazarr`, `sonarr`, `radarr`, `prowlarr`, `transmission`, `jellyseerr`, `immich_machine_learning`, `mealie`

**This is the budget that rules out Octopus Deploy** — its SQL Server dependency
alone wants 2GB. See [guides/OCTOPUS_DEPLOY.md](guides/OCTOPUS_DEPLOY.md).

---

## Drive Layout (reference)

Since the 2026-08-04 migration the **NAS is primary**. The two Samsung SSDs are
backup targets only, plugged in occasionally and synced by hand.

| Device | Size | Role | Mount path |
|--------|------|------|-----------|
| **UGREEN NAS** | ~11TiB usable (RAID 5) | Primary storage | `/Volumes/<share>` |
| **T7** | 1TB | Manual backup | `/Volumes/T7/` |
| **T5** | 500GB | Manual backup, destined offsite | `/Volumes/Backup/` |

**What lives where:**

| Data | Where | Path |
|------|-------|------|
| Immich photos | NAS | `/Volumes/immich/upload` |
| Immich database | Internal SSD | `~/services/immich/data/postgres` (never on SMB — DBs corrupt over network mounts) |
| Immich thumbnails | Internal SSD | `~/services/immich/data/thumbs` (SSD for fast scrolling; regenerable) |
| Media (movies, TV, downloads) | NAS | `/Volumes/media/` |
| Audiobooks | NAS | `/Volumes/audiobooks/` |
| Calibre books | NAS | `/Volumes/books/` |
| CouchDB (Obsidian LiveSync) | Internal SSD | `~/services/couchdb/data` (database — never on SMB) |
| Obsidian vault | Internal SSD | `~/obsidian-vault` |
| Docker data | Internal SSD | `~/Library/Containers/com.docker.docker` |

**Still on T7 and not yet in Immich:** the year folders (`2002`–`2024`, `Močiutė`,
`from iphone`) — ~140GB of archives, see TODO #20. T5 holds copies of the same
folders, so they are not single-copy, but **do not wipe T7 until they are imported**.

**Cloud backup (rclone → Cloudflare R2), nightly 5am:**
- Docker service configs, obsidian vault, Calibre books, DB dumps → R2 `peciulevicius-backups`
- Script: `~/.dotfiles/services/rclone/rclone-backup.sh`
- ~1.3GB total (critical-only; photos/audiobooks excluded from R2)

**Local backup (rsync NAS → external drive), MANUAL — no cron:**
- `~/.dotfiles/scripts/backup/backup-external.sh /Volumes/T7` (or `/Volumes/Backup` for T5)
- Covers: Immich originals + transcoded video, **database dumps**, audiobooks, Calibre books
- Skips: media (movies/TV — too large, re-downloadable), Immich thumbnails (regenerable)
- Both drives verified 1:1 against the NAS on 2026-09-05

**If the NAS dies:** photos + books + audiobooks + DB dumps on T7 and T5. Configs on R2.
Re-download media.
**If a drive dies:** re-run the script against a replacement.
**If the Mac mini dies:** all data safe on the NAS. Reinstall macOS, clone dotfiles,
restore configs from R2.

**The gap:** T7 and T5 currently sit in the same room as the NAS, so nothing survives
fire/flood/theft. Moving T5 offsite (the parents' house plan) is what makes this 3-2-1.

---

## Quick reference

| Service | Container path | Mac mini path |
|---|---|---|
| Radarr/Sonarr media | `/media` | `/Volumes/media` |
| Radarr movies | `/media/movies` | `/Volumes/media/movies` |
| Sonarr TV | `/media/tv` | `/Volumes/media/tv` |
| Transmission downloads | `/downloads` | `/Volumes/media/downloads` |
| Audiobookshelf | `/audiobooks` | `/Volumes/audiobooks` |
| Calibre library | `/books` | `/Volumes/books` |
| Immich photos | `/usr/src/app/upload` | `/Volumes/immich/upload` |
| Immich thumbnails | `/usr/src/app/upload/thumbs` | `~/services/immich/data/thumbs` (internal SSD) |
| Immich DB | `/var/lib/postgresql/data` | `~/services/immich/data/postgres` (internal SSD) |

All `/Volumes/<share>` paths are NAS SMB mounts — see `docs/NAS.md`.
