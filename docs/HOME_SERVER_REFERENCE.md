# Home Server — Reference

Facts about the machine, not work to do. Outstanding work lives in
[HOME_SERVER_TODO.md](HOME_SERVER_TODO.md); finished work in
[HOME_SERVER_CHANGELOG.md](HOME_SERVER_CHANGELOG.md).

---

### RAM baseline

Mac mini M4, **16GB unified memory**. Docker VM ceiling is now **10GB** (raised
from 7.8GB on 2026-07-23), but that is a *ceiling*, not a reservation — the VM
allocates lazily.

Measured 2026-09-21 (evening) with 42 containers, after adding the
four-container Odysseus stack:

| Metric | Value | Reading |
|---|---|---|
| Containers, total | 7.59 GiB of the VM's 9.7 GiB | **2.11 GiB headroom** |
| macOS memory free | 30% | tighter; watch it |
| Swap used | ~3.3 GB of 4 GB | |

⚠️ **This was the tightest the host had been.** Resolved same night — see below.

**Measured 2026-09-21 (later) with 38 containers**, after removing Mealie (0
recipes, confirmed unused) and Grafana+Prometheus+node-exporter (Tailscale-only,
no scripts depended on it, credentials long forgotten):

| Metric | Value | Reading |
|---|---|---|
| Containers, total | **5.81 GiB** | ~1.78 GiB reclaimed vs the same-night peak |

Odysseus stack: odysseus ~745MB, searxng ~141MB, ntfy ~45MB, chromadb ~28MB.

Previous baselines: 2026-09-19, 39 containers, 5.55 GiB used / ~4.1 GiB free.
2026-09-08, 42 containers, 5.2 GiB used / 43% free.

Previous baseline, 2026-09-08 with 42 containers: 5.2 GiB of containers, 43%
free, ~2.5 GB swap.

**2026-09-26, adding Paperclip (44 containers):** before — 34–37% free, swap
10.2–10.3 GB of 11 GB used. After — **6.07 GiB** containers total, 36–38%
free, swap 9.7–10.0 GB used (did not grow). Paperclip itself: ~790–890MB idle
under a 1.5GB `mem_limit`; each Claude Code agent run adds ~300–500MB on top.
Swap has only ~1–1.6 GB headroom — it is the constraint to watch, not
container RAM.

**How to read swap on macOS:** "Pages free" is always near zero by design — macOS
uses spare RAM as cache, so a low free-page count is not a warning. Judge by
*memory pressure percentage* and whether swap is **growing**. Stable or shrinking
swap is fine, even at 2.5GB. Growing swap plus pressure under ~20% is the real
alarm.

Biggest single consumers (2026-09-19): `immich_server` (~839MB), `paperless`
(~374MB), `stirling_pdf` (~360MB on 0.46; ~1.3GB right after start on 2.14 — JVM `MaxRAMPercentage=50`), `flaresolverr` (~302MB), `calibre` (~299MB).

**Containers safe to stop while traveling:**
`nextcloud`, `nextcloud_db`, `pihole`, `bazarr`, `sonarr`, `radarr`, `prowlarr`, `transmission` + `transmission-ts`, `jellyseerr`, `immich_machine_learning`

**This is the budget that rules out Octopus Deploy** — its SQL Server dependency
alone wants 2GB. See [guides/OCTOPUS_DEPLOY.md](guides/OCTOPUS_DEPLOY.md).

---

## Paperclip — facts and gotchas

- `http://100.81.171.49:3100` / `http://127.0.0.1:3100`. Ports bound to those
  two addresses explicitly — the LAN IP refuses connections (verified).
- **Every hostname used to reach it must be in `PAPERCLIP_ALLOWED_HOSTNAMES`**
  (`~/services/paperclip/.env`), including `paperclip` for Glance and
  `host.docker.internal` for Uptime Kuma. A missing one returns **403**, not
  a connection error.
- Agents run *inside* the container (the image bundles `claude`, `codex`,
  `gemini`, `opencode`). Container `$HOME` is `/paperclip` = `./data`, so CLI
  logins persist in `data/.claude/` etc. The host's Claude Code login can't be
  reused — it lives in the macOS Keychain.
- `paperclipai auth bootstrap-ceo` does **not** work in this container (no
  `config.json`; the image configures from env). Losing the admin password
  means Vaultwarden or nothing.
- Embedded Postgres on port 54329 inside the container; live dir excluded from
  R2, Paperclip's own daily dumps (`data/instances/default/data/backups/`,
  14 days) plus `secrets/master.key` are backed up.
- Health reports `databaseBackup: warning` until the first daily dump exists
  (24h after first start) — expected, not a fault.

---

## Transmission runs behind a Tailscale sidecar

Since 2026-09-26 `transmission` uses `network_mode: service:transmission-ts`
(image `tailscale/tailscale:v1.102.5`). Facts worth knowing without opening the
`services/transmission/README.md`:

- `transmission-ts` is its own tailnet node (hostname `transmission-ts`,
  own `100.x` IP), kernel-mode tailscaled, `/dev/net/tun` + `NET_ADMIN` —
  Docker Desktop's VM provides the tun device; `SYS_MODULE` isn't needed.
- Login state: `~/services/transmission/data/tailscale/` (under the services
  backup). The auth key was single-use; lose this dir → new key needed.
- `transmission:9091` on `media` is a **network alias of the sidecar**.
- **Sidecar restarted alone → Transmission orphaned** on a dead netns (only
  `lo`). `docker compose up -d` doesn't repair it; `docker restart transmission`
  does. Glance's Transmission monitor goes red when this happens.
- Node key expires 2027-03-25 unless key expiry is disabled in the admin console.
- No exit node yet (Mullvad add-on not bought), so egress is still the home IP.
- Tailscale does **not** document fail-closed behaviour for an offline exit
  node — don't rely on it as a kill switch until tested.

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

## ⚠️ Two cloudflared LaunchAgents exist — only one is real

```
~/Library/LaunchAgents/com.cloudflare.cloudflared.plist   ← the one actually serving traffic
~/Library/LaunchAgents/sh.brew.cloudflared.plist          ← brew's own agent, inert
```

`brew services restart cloudflared` restarts the **second one**, silently —
it reports success either way, and the real tunnel process (started outside
Homebrew, `PPID 1`, running since whenever it was first set up) never notices
the config file changed underneath it. Confirmed 2026-09-22: after editing
`~/.cloudflared/config.yml`, `brew services restart cloudflared` reported
success but a request to the removed hostname still hung for 15s+ instead of
404ing — the old process, with the old config already read into memory, was
still running, untouched.

**To actually reload the tunnel after editing `config.yml`:**

```bash
launchctl kickstart -k "gui/$(id -u)/com.cloudflare.cloudflared"
```

Verify it worked by checking the PID and start time changed:

```bash
ps aux | grep "[c]loudflared tunnel"
```

`brew services stop cloudflared` is safe to run once, to stop the dead
duplicate from sitting in `error` state in `brew services list` — it does not
touch the real tunnel.

## ⚠️ Rotating a password only fixes one side of a connection

Radarr and Sonarr each store their **own separate copy** of Transmission's
login to talk to it — rotating Transmission's password (done 2026-09-19,
credential migration) does not touch that copy. Result, not caught until
2026-09-22: every release either app grabbed silently failed the handoff
(`Authentication Failure`) for three days, invisible unless you specifically
opened Radarr's queue and read the error detail — Jellyseerr showed the
request as accepted, nothing looked broken.

**When rotating any credential a *client* also stores its own copy of**, check
every consumer, not just the service whose password changed:

| Rotated | Also stored in | Check |
|---|---|---|
| Transmission | Radarr, Sonarr (download client settings) | `/api/v3/downloadclient/test` |
| Pi-hole | Glance (`PIHOLE_PASSWORD` in `~/services/glance/.env`, DNS-stats widget — since the v6 upgrade, 2026-09-25) | homepage DNS widget shows numbers, not an error |
| Vaultwarden's own login | nothing — it's the source of truth | — |
| Any `*@peciulevicius.com` alias | wherever that alias is the *login*, not just the notify address | per-service |

This is the same class of risk as the [malware release profile](#) below —
a change that looks complete from the changed service's side can be silently
broken from a consumer's side. Verify the *consumer*, not just the source.

## 🔴 A fake "movie" release is often a bare `.exe` — check before it finishes

Caught 2026-09-22: a Radarr-grabbed release of a new movie was a
single 1.15GB `.exe` file, no video container, already 19% downloaded before
anyone looked. This is a known piracy-scene scam pattern — a fake release
with a real-looking name whose payload is a Trojan installer, not media.

**Manual check, if you ever want to look yourself** (Transmission's web UI or
API, before a download finishes): open the torrent's file list.

- ✅ **Legitimate:** one `.mkv`/`.mp4`/`.avi` as the bulk of the size, optionally
  with `.srt`/`.nfo`/small `.txt` siblings (release-group attribution files are
  normal and harmless)
- 🔴 **Fake:** the *only* substantial file is `.exe`/`.scr`/`.msi`/`.bat`/`.zip`,
  or a video-shaped name that actually resolves to one of those extensions

**Automated, added the same day:** a **release profile** in both Radarr and
Sonarr (Settings → Custom Formats, or `/api/v3/releaseprofile`) that rejects
any release whose name contains `.exe .scr .lnk .msi .bat .cmd .vbs .jar`,
`password.txt`, `setup.exe`, `installer` — **before it ever reaches a download
client**, not just cleaned up after. This is now a standing, automatic
protection; nothing to run by hand going forward. Verify it's still there:

```bash
curl -s "http://localhost:7878/api/v3/releaseprofile" -H "X-Api-Key: <radarr-key>"
```

⚠️ **It only catches releases naming the bad extension in the release title
itself** — this specific scam did (the release name ended in `.exe`), which is why the filter
works, but a more careful fake could rename the payload after download to
something less obvious. It raises the bar; it doesn't guarantee zero risk. If
you ever manually eyeball a torrent's file list and it doesn't look like §
above, delete it — don't run anything from `/Volumes/media`.

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

> **Since 2026-09-25 the library lives on the internal SSD**
> (`~/services/calibre/library`), so the SMB half of this cause is gone. The
> rule stays until a rename has been tried and verified on the SSD — the
> second service holding a handle is still a factor. Paths in the repair
> below are now under `~/services/calibre/library`.

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

(Calibre-specific examples below are historical — the library left SMB on
2026-09-25. The mechanism still applies to every other share.)

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

**Seen 2026-09-26 with a container restart not helping:** `lsof` showed the
holder was Docker Desktop's virtualization process itself
(`com.apple.Virtualization…`), which keeps handles to files a container
touched even after that container restarts — the same process holds the
Immich backup and `media/downloads` ghosts. Only a Docker Desktop restart
releases those.

`rclone-backup.sh` **excludes them** — otherwise a 733MB duplicate would be
uploaded to R2 as if it were a book.

## Services with an SMB-mounted library don't reliably notice new files

A media server's real-time file watcher does not reliably fire on an
SMB-mounted share. **Confirmed** for Jellyfin (`/Volumes/media`) 2026-09-22 —
a Radarr import completed, the file sat correctly in `/media/movies/`, and
Jellyfin's logs showed zero scan activity until the container was
**restarted**, which forces a full library scan on startup and picked it up
immediately. **Audiobookshelf** (`/Volumes/audiobooks`) runs the identical
watcher-on-SMB pattern — no confirmed failure yet, covered preventively since
the root cause is architectural, not specific to Jellyfin.

**Stopgap, running now:** `scripts/utils/smb-watcher-rescan.sh` restarts
both containers every 30 minutes via cron. Brief interruption for anyone
actively using either at that moment, but new files stop needing a manual
nudge either way.

**Real fix, needs a person, per service:**
- **Jellyfin** — generate an API key (dashboard → Admin → API Keys) and wire
  it into Radarr's and Sonarr's Settings → Connect as a native Jellyfin
  notification. Refreshes just the new item the moment import finishes, no
  restart, no interruption.
- **Audiobookshelf** — no equivalent documented "notify on import" hook from
  LazyLibrarian as of 2026-09-22. Worth checking Audiobookshelf's own API for
  a targeted scan-one-folder endpoint before assuming the blunt restart is
  permanent for this one.

See `HOME_SERVER_TODO.md`.

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
| Calibre library (books + `metadata.db`) | Internal SSD | `~/services/calibre/library` — moved off SMB 2026-09-25 (SQLite must not live on SMB). Path is `BOOKS_DIR` in the calibre, calibre-web and lazylibrarian `.env`s. The old NAS copy `/Volumes/books` is a **frozen rollback** until ~2026-10-02, then deleted |
| CouchDB (Obsidian LiveSync) | Internal SSD | `~/services/couchdb/data` (database — never on SMB) |
| Obsidian vault | Internal SSD | `~/obsidian-vault` |
| Docker data | Internal SSD | `~/Library/Containers/com.docker.docker` |

**Still on T7 and not yet in Immich:** the year folders (`2002`–`2024`, plus a few named and
unsorted folders) — ~140GB of archives, see TODO #20. T5 holds copies of the same
folders, so they are not single-copy, but **do not wipe T7 until they are imported**.

**Cloud backup (rclone → Cloudflare R2), nightly 5am:**
- Docker service configs, obsidian vault, Calibre books, DB dumps → R2 `peciulevicius-backups`
- Script: cron runs the staged copy `~/services/rclone/rclone-backup.sh`, config in `~/services/rclone/.env` (one script path, one `.env` — two copies silently dropped the Immich step once)
- ~2.9GB total (critical-only; audiobooks excluded from R2), **$0/month** — under
  the 10GB free tier
- **Immich photo originals — enabled 2026-09-21.** `/Volumes/immich/upload/upload`
  → R2 `immich-photos/`, **72.4GB, 6,696 files, zero errors**
  (encoded-video/thumbs/backups excluded as regenerable or redundant with the
  DB dump above). Second offsite copy alongside the T5 drive plan below.
  Total R2 bill is now ~$1/month. See `services/rclone/README.md`.
- **Verified monthly** by `scripts/backup/r2-verify.sh` (one random file per
  set restored and byte-compared; size history in `~/logs/r2-size-history.tsv`)
- **Restore:** `scripts/backup/restore.sh list | service <name> | set
  <vault|dumps|books|photos>`, always into `~/services-restore/`; `restore.sh db`
  loads a dump back into its container

**Local backup (rsync NAS → external drive), MANUAL — no cron:**
- `~/.dotfiles/scripts/backup/backup-external.sh /Volumes/T7` (or `/Volumes/Backup` for T5)
- Each successful run stamps `~/logs/external-backup-<drive>.last`; the weekly
  `homelab-audit.sh` fails once a drive is over 30 days stale
- Covers: Immich originals + transcoded video, **database dumps**, audiobooks, Calibre books
- Skips: media (movies/TV — too large, re-downloadable), Immich thumbnails (regenerable)
- Both drives verified 1:1 against the NAS on 2026-09-05

**If the NAS dies:** photos + books + audiobooks + DB dumps on T7 and T5. Configs on R2.
Re-download media.
**If a drive dies:** re-run the script against a replacement.
**If the Mac mini dies:** all data safe on the NAS. Reinstall macOS, clone dotfiles,
restore configs from R2.

**The gap:** T7 and T5 currently sit in the same room as the NAS, so nothing survives
fire/flood/theft. Moving T5 offsite (the parents' house plan) is what makes this 3-2-1
for everything *except* photos. Photo originals additionally have a cloud-based
offsite option (`BACKUP_IMMICH_PHOTOS=true`, above) that doesn't depend on a trip
to the parents' house — the two are complementary, not either/or.

---

## Quick reference

| Service | Container path | Mac mini path |
|---|---|---|
| Radarr/Sonarr media | `/media` | `/Volumes/media` |
| Radarr movies | `/media/movies` | `/Volumes/media/movies` |
| Sonarr TV | `/media/tv` | `/Volumes/media/tv` |
| Transmission downloads | `/downloads` | `/Volumes/media/downloads` |
| Audiobookshelf | `/audiobooks` | `/Volumes/audiobooks` |
| Calibre library | `/books` | `~/services/calibre/library` (internal SSD; was `/Volumes/books` until 2026-09-25) |
| Immich photos | `/usr/src/app/upload` | `/Volumes/immich/upload` |
| Immich thumbnails | `/usr/src/app/upload/thumbs` | `~/services/immich/data/thumbs` (internal SSD) |
| Immich DB | `/var/lib/postgresql/data` | `~/services/immich/data/postgres` (internal SSD) |

All `/Volumes/<share>` paths are NAS SMB mounts — see `docs/NAS.md`.
