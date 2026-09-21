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

## ⚠️ Cloudflare Tunnel caps uploads at 100MB

The free Cloudflare plan limits request bodies to **100MB**. Anything larger
fails on the way *in* through `*.peciulevicius.com`, and the error comes from
the app rather than Cloudflare — Calibre-Web reports *"File size may be too
big"*, which looks like an app setting and isn't.

Affects any upload: Calibre-Web, Immich, Nextcloud, Paperless.

**Workaround: skip the tunnel for large uploads.** Every service is also
reachable directly:

| Route | Address | Limit |
|---|---|---|
| Public hostname | `https://<svc>.peciulevicius.com` | **100MB** |
| Tailscale | `http://100.81.171.49:<port>` | none |
| On the Mac mini | `http://localhost:<port>` | none |

Downloads are unaffected — the cap is on request bodies only.

The homepage carries a **"Direct (no tunnel)"** bookmark group with the
Tailscale URLs for the four upload-heavy services, so the right link is one
click away rather than something to remember.

⚠️ **A failed large upload can leave the library half-written.** One 750MB
attempt through the tunnel produced a Calibre record with no file on disk, a
folder renamed while the database still pointed at the old name, and a
733MB `.smbdelete` duplicate. See the SMB section below.

## 🚫 Never rename a book in Calibre-Web

**Renaming a book's title or author in Calibre-Web will corrupt the library
entry on this setup.** It happened twice on 2026-09-21, both times identically:

1. Calibre-Web renames the folder on disk
2. It copies the EPUB to the new filename
3. It tries to delete the original — and **SMB refuses**: *"Device or resource
   busy"*, because the Calibre content server still holds a handle
4. It rolls the database back, but **not the folder rename**

You are left with `metadata.db` pointing at the old path, a folder with the new
name, two copies of a 769MB file, and the book 404ing.

The cause is renaming large files on an **SMB share with the library open by two
services** — the same class of problem as never putting a database on SMB.

### Repair

```bash
# Rename the folder back to whatever metadata.db expects:
sqlite3 /Volumes/books/metadata.db "select path from books where id=<ID>;"
mv "/Volumes/books/<wrong name>" "/Volumes/books/<path from the DB>"
```

The duplicate EPUB left behind is usually locked server-side. Stopping the
containers and remounting the share does **not** always clear it — the lock
lives on the NAS. Clear it from the NAS's own file manager, or leave it; it is
excluded from the R2 backup.

### What to do instead

| Want | Do |
|---|---|
| **Mark a book as read-along/aligned** | Add a **tag** in Calibre-Web. Tags are metadata-only — no file or folder is touched, and KOReader's OPDS browser can filter by them. |
| **A different title** | Set it **before** importing, by editing the EPUB's metadata on the Mac: `ebook-meta book.epub --title "Can't Hurt Me (read-along)"`. Calibre reads the title from the file, so it imports correctly and nothing needs renaming afterwards. |
| Anything else that renames files | Do it from the **Calibre desktop app with the library local**, not over SMB. |

⚠️ Tags are also the answer to *"how do I tell which book is aligned from the
Kindle?"* — a `read-along` tag shows up as a browsable category in the OPDS feed.

## SMB leaves `.smbdelete*` files behind

When a file is deleted on an SMB share while a process still holds it open, the
server renames it to `.smbdeleteXXXX` instead of removing it. These are
byte-identical copies of real files — one was **733MB** — and they linger until
every handle closes.

```bash
find /Volumes/books -name ".smbdelete*" -exec ls -lh {} \; 2>/dev/null
find /Volumes/books -name ".smbdelete*" -delete          # "Resource busy" = still held
```

If they refuse to delete, restarting the containers that touch the share
(`calibre`, `calibre-web`, `lazylibrarian`) releases most of them. A stubborn
one needs the share unmounted and remounted, or deletion from the NAS itself.

`rclone-backup.sh` **excludes them** — otherwise a 733MB duplicate would be
uploaded to R2 as if it were a book.

---

## Drive Layout (reference)

Since the 2026-08-04 migration the **NAS is primary**. The two Samsung SSDs are
backup targets only, plugged in occasionally and synced by hand.

| Device | Size | Role | Mount path | Connected? |
|--------|------|------|-----------|---|
| **UGREEN NAS** | ~11TiB usable (RAID 5) | Primary storage | `/Volumes/<share>` | always, over SMB |
| **T7** | 1TB | Manual backup | `/Volumes/T7/` | **normally unplugged** |
| **T5** | 500GB | Manual backup, destined offsite | `/Volumes/Backup/` | **normally unplugged** |

**T7 and T5 are disconnected by design and were confirmed unplugged on
2026-09-19.** The migration to the NAS is finished: every service reads from
`/Volumes/<share>`, T7 was fully decoupled on 2026-08-04, and the nightly
external-drive cron was deleted on 2026-09-05 precisely because the drives
aren't attached. Any doc or script path mentioning `/Volumes/T7` is describing
**what to do once you plug it back in**, not a live mount.

Photos live in **Immich, on the NAS** — that is the source of truth now. The
year folders still sitting on T7 are an *unimported archive*, not a working
copy.

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
