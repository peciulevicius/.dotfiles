# Home Server — TODO

## Active

### 1. Calibre-Web — finish setup

33 books synced. Remaining:
- [ ] Create bookshelves (e.g. "Fiction", "Self-Help", "Business", "Tech") and assign books
- [ ] Configure "Send to Kindle" for Kindle Scribe

### ~~2. Uptime Kuma notifications~~ ✅ Done (2026-05-09)

Gmail SMTP configured (smtp.gmail.com:465, app password). Email alerts working.

### 3. Paperless-NGX — organise documents

Paperless-NGX doesn't support traditional folders — it uses **tags**, **document types**, and **correspondents** instead.

- [ ] Create document types: e.g. "Invoice", "Contract", "Receipt", "Statement"
- [ ] Create correspondents: e.g. "Bank", "Employer", "Government"
- [ ] Create tags: e.g. "Tax 2024", "Important", "Archive"
- [ ] Assign types/correspondents/tags to uploaded documents
- [ ] Use **Saved Views** (left sidebar) to create folder-like filtered views

### 4. Linkwarden — browser extension + import

- [ ] Install Linkwarden browser extension
- [ ] Import bookmarks from Chrome/Brave

### ~~5. Set up Obsidian vault sync via Syncthing~~ ✅ Done (2026-05-08)

`obsidian-vault` folder shared in Syncthing across Mac mini, MacBook, and iPhone. Real-time sync working.


### 8. Bazarr — subtitle provider

- [ ] Settings → Providers → Add provider: **OpenSubtitles.com** (free account at opensubtitles.com)
- [ ] Settings → Languages → Add profile: set English + Lithuanian as preferred
- [ ] Apply profile to all series and movies

### 9. FreshRSS — add feeds

- [ ] Open http://localhost:8082, create account if needed
- [ ] Import OPML file or manually add RSS feeds

### 10. Pi-hole local DNS (later)

**Note:** PIHOLE_API_KEY is now configured in `~/services/glance/.env` — DNS stats widget is working.

**Goal:** Access `*.peciulevicius.com` on local WiFi without going through Cloudflare.

- [ ] In Pi-hole admin (http://localhost:8053/admin) → Local DNS → DNS Records
- [ ] Add for each subdomain → Mac mini local IP
- [ ] Set router DNS to Mac mini IP (primary) + `1.1.1.1` (fallback)
- [ ] Test: `nslookup home.peciulevicius.com` should return Mac mini local IP

### 11. Replace external SSDs with proper NAS storage (later)

**Goal:** Eliminate T7/T5 external SSDs — move to network-attached storage that's more reliable, expandable, and not physically dependent on being plugged into the Mac Mini.

**Options researched:**

| Option | Cost | Pros | Cons |
|--------|------|------|------|
| **Synology DS423+** + 2x 4TB WD Red | ~€540 | Best UX, stable DSM, 2.5GbE, runs Docker itself, RAID 1 | Expensive upfront |
| **Mini PC + TrueNAS SCALE** (e.g. Beelink N100) + drives | ~€300-400 | ZFS, free software, very flexible, also runs Docker | More DIY, more maintenance |
| **Thunderbolt DAS** (e.g. OWC ThunderBay) + drives | ~€350-500 | Fastest (Thunderbolt), simple | Tied to Mac Mini physically, no NAS features |

**Recommendation when ready:** Synology DS423+ with 2x 4TB WD Red Plus in RAID 1 (~€540 total). Keeps Mac Mini as pure compute, Synology as pure storage. 2.5GbE is fast enough for all services.

**Migration plan (when buying):**
- [ ] Buy NAS + drives, set up with RAID 1
- [ ] Mount NAS on Mac Mini via SMB/NFS
- [ ] rsync all T7 data to NAS (`immich/`, `media/`, `calibre-books/`)
- [ ] Update all Docker Compose volume paths to NAS mount
- [ ] Restart all services, verify everything works
- [ ] Update rclone backup script to back up from NAS instead of T7
- [ ] Repurpose T7 as Time Machine backup drive, T5 as offsite backup

### 12. VPN for torrents (later)

**Goal:** Route Transmission traffic through a VPN so ISP can't see torrent activity. Not urgent — no downloads planned for ~1 month.

**Provider options (pick one):**
- [ ] **Mullvad** — €5/mo, best privacy, no email needed, cancel anytime
- [ ] **Proton VPN** — free tier works but slower, no port forwarding

**Setup (after choosing provider):**
- [ ] Create `services/gluetun/docker-compose.yml` with VPN credentials
- [ ] Update Transmission compose to use `network_mode: service:gluetun`
- [ ] Test: `docker exec transmission curl ifconfig.me` should show VPN IP, not home IP

### ~~13. Show Mac host stats in monitoring~~ ✅ Done (2026-05-07)

Homebrew node_exporter running at port 9100, scraped by Prometheus (`job="mac-host"`). Custom Grafana dashboard (`mac-host.json`) provisioned — shows real 16GB RAM, swap, CPU, disk, network. Glance `server-stats` widget updated to show actual host figures.

### ~~14. Uptime Kuma — rclone backup heartbeat~~ ✅ Done (2026-05-09)

Push monitor added in Uptime Kuma. Heartbeat URL wired into `rclone-backup.sh` — pings up on success, down on failure. R2 backup verified working across all 4 targets.

### 15. ~~Migrate backups from B2 to Cloudflare R2~~ ✅ Done (2026-04-22)

Migrated to Cloudflare R2. Nightly rclone backup running at 5am. R2 at ~1.3GB (critical-only: vaultwarden, paperless docs, obsidian vault, db dumps, calibre books). B2 bucket purged and can be deleted from Backblaze dashboard.

### ~~17. Kindle Scribe → Obsidian automation~~ ✅ Done (2026-05-08)

**Goal:** Automatically sync Kindle Scribe handwritten/typed notes to the Obsidian vault so notes taken on the Scribe appear on all synced devices (MacBook, Mac mini, iPhone, eventually Windows work laptop).

**How it works:** Scribe exports a notebook as TXT via email (Share → Send to email). A script fetches those emails, extracts the text, and routes it to the correct vault folder based on the notebook name.

**Existing infrastructure:**
- Vault structure + templates: `scripts/setup/setup-obsidian.sh`
- Routing rules documented: `docs/guides/NOTES.md` (Kindle Scribe → Obsidian Routing table)
- Syncthing sync: TODO #7

**To build — `pkm/kindle_sync.py` (IMAP-based, provider-agnostic):**

1. Connect to email via IMAP (works with any provider — Gmail now, easy to switch later)
2. Search for unread emails from `do-not-reply@amazon.com` with subject containing "from your Kindle"
3. Parse email subject to extract notebook name
4. Download TXT content from the download link in the email body
5. Route to correct vault folder using keyword matching (same rules as `docs/guides/NOTES.md`)
6. Save as `.md` with frontmatter:
   ```yaml
   ---
   source: Kindle Scribe
   exported: YYYY-MM-DD
   notebook: [original notebook name]
   ---
   ```
7. Filename: `YYYY-MM-DD_NotebookName.md` (append `_v2`, `_v3` if exists — never overwrite)
8. Mark email as read after processing
9. Optional: git commit + push to `obsidian-vault` private repo

**Directory structure:**
```
pkm/
├── kindle_sync.py       # main script
├── config.py            # IMAP creds, vault path, routing rules, toggles
└── requirements.txt     # imaplib is stdlib, requests for download link
```

~~Steps completed (2026-05-08):~~
- Script at `pkm/kindle_sync.py` — IMAP-based, provider-agnostic
- Exports as **Searchable PDF** from Scribe → email → script grabs `.txt` + `.pdf`
- Saves to `📥 Imports/YYYY-MM-DD_HH-MM_name.md` + `.pdf` attachment
- Hourly cron job running, logs to `~/logs/kindle-sync.log`
- Gmail app password configured in `pkm/config.py` (gitignored)

### 18. De-Google — migrate off all Google services (later)

**Goal:** Own all personal data. No Google Drive, Gmail, Calendar, Photos, or other Google services.

**Why:** Data sovereignty — not dependent on a single corporation, easier to switch providers, data stays under your control.

**Services to replace:**

| Google service | Self-hosted replacement | Status |
|---|---|---|
| Gmail | Migadu / Fastmail / self-host with Stalwart Mail | Not started |
| Google Drive | Nextcloud (already running) | Nextcloud ready, needs migration |
| Google Calendar | Nextcloud Calendar (CalDAV) | Not started |
| Google Contacts | Nextcloud Contacts (CardDAV) | Not started |
| Google Photos | Immich (already running) | Immich ready, needs migration |
| Google Docs | Nextcloud Office / OnlyOffice | Nextcloud ready |
| YouTube | n/a (no full replacement) | — |

**Migration order (recommended):**
1. [ ] **Email first** — pick provider (Migadu ~€4/mo recommended: own domain, no Google dependency)
  - Create account at Migadu with `peciulevicius.com` domain
  - Add MX records in Cloudflare DNS
  - Import Gmail archive (Google Takeout → IMAP import)
  - Update all accounts (banking, work, services) to new address
  - Update `pkm/config.py`: change `IMAP_SERVER` to new provider
  - Keep Gmail forwarding for ~3 months, then delete
2. [ ] **Calendar + Contacts** — enable Nextcloud Calendar + Contacts apps
  - Add Nextcloud CalDAV to iPhone (Settings → Calendar → Add Account → Other)
  - Add Nextcloud CardDAV to iPhone (Settings → Contacts → Add Account → Other)
  - Import Google Calendar (export .ics → import to Nextcloud)
  - Import Google Contacts (export .vcf → import to Nextcloud)
3. [ ] **Drive** — redirect remaining Google Drive usage to Nextcloud
  - Install Nextcloud desktop client on MacBook
  - Move any files still in Google Drive → Nextcloud
4. [ ] **Photos** — migrate Google Photos to Immich
  - Google Takeout → download photos archive
  - Import to Immich via bulk upload
5. [ ] **Account cleanup** — after 3–6 months with no Google services
  - Delete Google account (irreversible — confirm everything migrated first)

**Note:** `pkm/kindle_sync.py` is already IMAP-based so switching email providers requires only changing `IMAP_SERVER` in `config.py`.

### 19. T7 → T5 full backup (not just Immich)

**Problem:** `backup-immich.sh` (cron 3am daily) only backs up Immich photos from T7 to T5. Media, Calibre books, and other T7 data are **not** covered. If T7 fails, only photos are recoverable from T5.

**Additional problem:** T5 must be physically plugged in for backups to work. Currently no alert if it's missing — the script just silently fails.

**What T7 currently holds:**
| Path | Size (approx) | Backed up to T5? |
|------|--------------|-----------------|
| `/Volumes/T7/immich/` | ~100GB+ photos | ✅ (backup-immich.sh) |
| `/Volumes/T7/media/` | large (movies/TV) | ❌ |
| `/Volumes/T7/calibre-books/` | small (~5GB) | ❌ |
| `/Volumes/T7/immich/postgres/` | DB files | ❌ (rsync skips open DB files) |

**Plan:**
- [ ] Plug in T5 and verify it mounts as `/Volumes/ImmichBackup` (or rename label to `T5Backup`)
- [ ] Extend `backup-immich.sh` (or create new `backup-t7.sh`) to also rsync:
  - `/Volumes/T7/calibre-books/` → `/Volumes/T5/calibre-books/`
  - Skip `/Volumes/T7/media/` — too large for 500GB T5, keep media loss acceptable
- [ ] Add T5 mount check at start of backup: if not mounted → send alert via Uptime Kuma heartbeat miss (TODO #2) + log error
- [ ] Add Uptime Kuma push heartbeat to backup script (coordinate with TODO #14)
- [ ] Test: unplug T5, run backup → should log error, not silently pass

**Recovery posture after fix:**
- If T7 fails: Immich photos + Calibre books on T5, services configs on R2 (cloud)
- If T5 fails: replace it, rsync from T7 again

### 16. Docker VM resource limits (later)

**Goal:** Give Docker more headroom for the full stack.

Current: ~7.8GB RAM / 1GB swap (Docker Desktop default)
Recommended: 10GB RAM / 2GB swap

- [ ] Docker Desktop → Settings → Resources → increase RAM to 10GB, swap to 2GB
- [ ] Restart Docker, verify containers come back up
- [ ] Check Glance — RAM pressure should be gone even with full stack running

---

## Done

- [x] ~~DeDRM Kindle books → Calibre-Web (Apr 2026)~~ — ~30 books DRM-removed via Windows VM (UTM) + Kindle for PC 2.8.2 + KFXArchiver283, converted to EPUB, uploaded to Calibre-Web
- [x] ~~Calibre-Web — organising books (Apr 2026)~~ — year-end books processed and organised
- [x] ~~Media stack setup~~ — Sonarr/Radarr/Prowlarr/Transmission/Jellyfin fully connected, remote path mapping fixed, Narcos S1-S3 downloaded and playing
- [x] ~~Cloudflare DNS cleanup~~ — deleted stale CNAMEs: `sync`, `portainer`, `ai`, `sonarr`, `radarr`, `prowlarr`, `downloads`
- [x] ~~Cloudflare Access (wildcard)~~ — removed `*.peciulevicius.com` Zero Trust gate; was breaking all native apps (Bitwarden, Immich, etc.). Each service has its own login screen — Access wasn't needed.
- [x] ~~Cloudflare Access (Glance only)~~ — added Access policy on `home.peciulevicius.com` only. GitHub SSO (primary) + email OTP (fallback). 1-month session. Other services unaffected.
- [x] ~~Homarr → Glance migration~~ — replaced Homarr with Glance (YAML config, responsive). Four pages: Home, Feed, Media, Finance.
- [x] ~~Glance internal links~~ — fixed `host.docker.internal` → Tailscale IP (`100.81.171.49`) so all links work from any device (phone, laptop, etc.)
- [x] ~~Actual Budget~~ — removed (using Wallet by Budget Bakers instead — bank sync support for Lithuanian banks). Container stopped, removed from Glance/tunnel/setup-services.
- [x] ~~Passkey migration~~ — all 5 services (Amazon, Binance, GitHub, Google, PSN) re-registered with Bitwarden
- [x] ~~Karakeep~~ — tried as Linkwarden replacement, reverted back to Linkwarden (simpler UI). Karakeep stopped, data kept at `~/services/karakeep/`
- [x] ~~Linkwarden~~ — restored as primary bookmark manager on port 3005, `links.peciulevicius.com`
- [x] ~~Grafana + Prometheus configured~~ — datasource connected, dashboards imported, password set
- [x] ~~Bazarr connected~~ — Sonarr/Radarr API keys configured, subtitle provider still needed
- [x] ~~Kindle DeDRM → Calibre-Web (Apr 2026)~~ — decrypted 30 Kindle books via KFXArchiver283 (work laptop + Kindle for PC 2.8.2), converted to EPUB in Calibre, synced to Mac mini Calibre-Web. BOOKS folder cleaned (~22GB freed).
- [x] ~~Audible AAX → Audiobookshelf (Apr 2026)~~ — converted 28 AAX audiobooks to M4B via `scripts/convert-audiobooks.sh` (ffmpeg stream copy, chapters preserved). Synced to Mac mini Audiobookshelf.
- [x] ~~B2 backup cleanup (Apr 2026)~~ — deleted Immich photos (7GB), Linkwarden (644MB), Audiobookshelf (890MB) from B2. Down from 9.7GB to 1.2GB. Immich backup disabled (using T5 local). Script fixed: `pipefail` + error counter.
- [x] ~~Cloudflared plist fix~~ — brew service was missing `tunnel run` args, created proper `com.cloudflare.cloudflared.plist` launch agent
- [x] ~~Docker Desktop watchdog~~ — `scripts/utils/docker-watchdog.sh` + launchd agent runs every 5min; restarts Docker Desktop if containers lose internet (Docker proxy dies intermittently)
- [x] ~~NordPass cancelled~~ — subscription ended, passwords in Vaultwarden
- [x] ~~Jellyseerr~~ — media request/discovery UI for Jellyfin (Tailscale-only, port 5055)
- [x] ~~Bazarr~~ — automated subtitle management for Sonarr/Radarr (Tailscale-only, port 6767)
- [x] ~~Grafana + Prometheus~~ — monitoring stack with Node Exporter (Tailscale-only, ports 3000/9090/9100)
- [x] ~~Restart stopped services~~ — all 33 containers confirmed running (all have `restart: unless-stopped`)
- [x] ~~Homarr cleanup~~ — removed containers, images, Docker network, updated setup script
- [x] ~~Tunnel security split~~ — moved Sonarr/Radarr/Prowlarr/Transmission to Tailscale-only, added Portainer to public tunnel
- [x] ~~Mealie~~ — setup complete
- [x] ~~Linkwarden~~ — setup complete, browser extensions installed (Chrome ✅, Brave ⚠️ disable Shields), phone PWA added
- [x] ~~Calibre-Web `metadata_dirtied` bug~~ — fixed: ran `CREATE TABLE` SQL
- [x] ~~Radarr Docker volumes~~ — compose already has `/media` mount
- [x] ~~Pi-hole 403 on root~~ — fixed: lighttpd redirect config mounted
- [x] ~~Transmission credentials~~ — changed from defaults (see .env on Mac Mini)
- [x] ~~Homarr dashboard~~ — configured with all services, organized into categories (Main, Media, Utilities, System, Direct Access)
- [x] ~~Linkwarden bookmarks~~ — 621 bookmarks imported (services + browser bookmarks)
- [x] ~~Uptime Kuma monitors~~ — all services monitored
- [x] ~~Ollama + Open WebUI~~ — removed (not enough RAM, using Claude instead)
- [x] ~~NordPass → Vaultwarden~~ — passwords migrated, subscription cancelled (Apr 2026)
- [x] ~~Radarr/Sonarr auto-cleanup~~ — `removeCompletedDownloads` + `removeFailedDownloads` enabled via API
- [x] ~~Ollama/Open WebUI containers~~ — stopped, removed from setup-services.sh
- [x] ~~Audiobookshelf subdomain~~ — fixed: books → listen
- [x] ~~B2 cloud backup~~ — nightly cron at 5am, services + obsidian-vault + Immich photos all backed up
- [x] ~~Immich photos B2 backup~~ — added `/Volumes/T7/immich/upload` to rclone-backup.sh
- [x] ~~Disk full (Apr 2026)~~ — T7 at 100% (17MB free). Cleared 480GB duplicate downloads from `downloads/complete/`, deleted 156GB old photo copies from APFS `TimeMachine` volume, removed 2.5GB ollama-models. Now at 140GB free.
- [x] ~~SSH enabled~~ — Remote Login turned on via System Settings, `ssh macmini` works via Tailscale
- [x] ~~Jellyfin delete fix~~ — removed `:ro` from media volume mounts so Jellyfin can delete files
- [x] ~~mac-mini.sh expanded~~ — added `services up/down/restart/status`, `cleanup`, `disk`, `ssh on/off` commands
- [x] ~~Ollama containers still running~~ — `ollama` and `open_webui` still in `~/services/ollama/`, should remove when home

---

## RAM Baseline Reference

Healthy Docker VM state (7.8GB allocated):

| State | RAM | Swap |
|-------|-----|------|
| Minimal (travel) | ~4.2GB / 7.8GB | ~200-400MB |
| Full stack (home) | ~6-7GB / 7.8GB | <500MB |
| Overloaded (before trim) | 6.3GB / 7.8GB | 1GB (maxed) |

**If swap hits 900MB+:** something is leaking or too many containers running.
First suspects: `immich_machine_learning`, `grafana`+`prometheus`, `nextcloud`.

**Containers safe to stop while traveling:**
`nextcloud`, `nextcloud_db`, `pihole`, `bazarr`, `sonarr`, `radarr`, `prowlarr`, `transmission`, `jellyseerr`, `immich_machine_learning`, `mealie`

---

## Drive Layout (reference)

Two Samsung SSDs permanently connected to the Mac Mini:

| Drive | Size | Role | Mount path |
|-------|------|------|-----------|
| **T7** | 1TB | Primary data | `/Volumes/T7/` |
| **T5** | 500GB | Local backup + Time Machine | `/Volumes/T5/` (or similar) |

**What lives where:**

| Data | Drive | Path |
|------|-------|------|
| Immich photos | T7 | `/Volumes/T7/immich/upload` |
| Immich DB | T7 | `/Volumes/T7/immich/postgres` |
| Media (movies, TV, downloads) | T7 | `/Volumes/T7/media/` |
| Calibre books | T7 | `/Volumes/T7/calibre-books` |
| Old photo copies (to delete) | T7 | APFS `TimeMachine` volume (not actually TM — just old photo copies) |
| Local photo backup (rsync from T7) | T5 | nightly copy |

**Cloud backup (rclone → Cloudflare R2):**
- Docker service configs, obsidian vault, Calibre books, DB dumps → R2 bucket `peciulevicius-services-backup`
- Runs nightly at 5am via cron: `~/.dotfiles/services/rclone/rclone-backup.sh`
- ~1.3GB total (critical-only; Immich photos excluded — T5 local backup instead)

**If T7 dies:** photos are on T5 (local) + B2 (cloud). Reinstall services from dotfiles, restore data from B2.
**If T5 dies:** replace it, rsync from T7 again.
**If Mac Mini dies:** all data is safe on T7 + B2. Reinstall macOS, clone dotfiles, restore.

---

## Quick reference

| Service | Container path | Mac mini path |
|---|---|---|
| Radarr/Sonarr media | `/media` | `/Volumes/T7/media` |
| Radarr movies | `/media/movies` | `/Volumes/T7/media/movies` |
| Sonarr TV | `/media/tv` | `/Volumes/T7/media/tv` |
| Transmission downloads | `/downloads` | `/Volumes/T7/media/downloads` |
| Audiobookshelf | `/audiobooks` | `~/services/audiobookshelf/data/audiobooks` |
| Calibre library | `/books` | `~/services/calibre-web/data/books` |
| Immich photos | `/usr/src/app/upload` | `/Volumes/T7/immich/upload` |
| Immich DB | `/var/lib/postgresql/data` | `/Volumes/T7/immich/postgres` |
