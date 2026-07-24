# Home Server — TODO

## Active

### ~~1. Calibre-Web — finish setup~~ ✅ Done (2026-05-09)

Bookshelves skipped (not needed). Send to Kindle configured via Gmail SMTP — `peciulevicius-scribe@kindle.com` approved and working.

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


### ~~8. Bazarr — subtitle provider~~ ✅ Done (2026-05-09)

OpenSubtitles.com configured, Default language profile set with English. Applied to all series and movies. 71 Wanted items queued — downloading automatically.

### 10. Pi-hole local DNS (later)

**Note:** PIHOLE_API_KEY is now configured in `~/services/glance/.env` — DNS stats widget is working.

**Goal:** Access `*.peciulevicius.com` on local WiFi without going through Cloudflare.

- [ ] In Pi-hole admin (http://localhost:8053/admin) → Local DNS → DNS Records
- [ ] Add for each subdomain → Mac mini local IP
- [ ] Set router DNS to Mac mini IP (primary) + `1.1.1.1` (fallback)
- [ ] Test: `nslookup home.peciulevicius.com` should return Mac mini local IP

### 11. Replace external SSDs with proper NAS storage

**Status (Jul 2026):** NAS arrived ✅ (UGREEN DH4300 Plus, SN H43001J61J30FAD0, warranty until 2028-07-23). Drives ordered — 3× IronWolf Pro 6TB recert (ST6000NE000) €230 each from [datablocks.dev](https://datablocks.dev), preorder arriving **~Jul 27–31**.

**Done (pre-drives, Jul 22):**
- [x] NAS on network at 192.168.1.73 via WiFi extender ethernet port (100Mbps — extender is the bottleneck, acceptable for now)
- [x] `nas.peciulevicius.com` → UGOS Pro web UI, via existing cloudflared tunnel on Mac mini (ingress: `http://192.168.1.73:9999`). No Docker needed on NAS.
- [x] UGREENlink remote access active (backup access: https://ug.link/dh4300plus-dp)

**Still to do (pre-drives):**
- [ ] **NEXT SESSION:** Reserve 192.168.1.73 for NAS in router DHCP settings — if IP changes, nas.peciulevicius.com breaks. Steps:
  1. Open http://192.168.1.1 in browser, log in (admin password often on router sticker)
  2. Find the DHCP section — usually under *LAN*, *Network*, or *Advanced → DHCP Server*. The feature is called **"Address Reservation"**, **"Static Lease"**, **"DHCP Binding"**, or **"Reserved IP"** depending on brand
  3. Add entry: MAC `6c:1f:f7:a9:39:e9` → IP `192.168.1.73` (device may appear in a connected-clients list as DH4300PLUS-DP — can often click it and hit "reserve")
  4. Save/apply. No NAS reboot needed — reservation kicks in at next DHCP renewal
  5. Verify: NAS Control Panel → Network still shows 192.168.1.73
- [ ] Enable SSH (Control Panel → Terminal; set "Shut down automatically" to never)
- [ ] Enable "Auto power-on when power is supplied" + WOL (Hardware & Power → Power)
- [ ] Set up 2FA on admin account (Security → Account security)
- [ ] Enable DoS protection (Security → Security)
- [ ] Change custom domain name from "localhost" to "nas" (Device Connection → LAN)

**When drives arrive (~Jul 27–31):**
- [ ] Insert 3 drives, create RAID 5 storage pool (3× 6TB = 12TB usable, 1-drive fault tolerance)
- [ ] Enable SMB (File Service → SMB), create shares: `media/`, `immich/`, `audiobooks/`, `books/`
- [ ] Mount NAS on Mac mini via SMB, verify transfer speed
- [ ] rsync all T7 data to NAS (`immich/`, `media/`, `calibre-books/`, `audiobooks/`) — at 100Mbps ~800GB takes ~20h, run overnight or connect NAS temporarily via direct ethernet
- [ ] Update all Docker Compose volume paths to NAS mount
- [ ] Restart all services, verify everything works
- [ ] Update rclone backup script to back up from NAS instead of T7
- [ ] Repurpose T7 as additional backup, T5 as offsite backup
- [ ] Verify drive sleep works (already configured: 20 min idle, wake on sign-in)
- [ ] Optional: enable rsync service + Bonjour/Time Machine target (File Service)
- [ ] Install Tailscale from App Center (needs storage pool), join tailnet — enables remote SMB/Finder mounting from MacBook when away from home (web UI already remote via nas.peciulevicius.com + UGREENlink)

**Hardware reference:** 4-bay, RK3588C ARM 8-core, 8GB RAM (keep NAS storage-only — no heavy Docker workloads; compute stays on Mac mini), 2.5GbE port. Purchase total ~€1,060 (NAS €340 + drives €690 + switch/cables €30).

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

### ~~19. T7 → T5 full backup~~ ✅ Done (2026-07-09)

**What was done:**
- Renamed T5 volume from `ImmichBackup` → `Backup` (`diskutil rename`)
- Created `scripts/backup/backup-t5.sh` — rsync T7 → T5 covering:
  - `/Volumes/T7/immich/upload` → `/Volumes/Backup/immich/upload` (photos)
  - `/Volumes/T7/audiobooks` → `/Volumes/Backup/audiobooks`
  - `/Volumes/T7/calibre-books` → `/Volumes/Backup/calibre-books`
  - Skips `/Volumes/T7/media/` — movies/TV too large for 500GB T5
- Updated cron: 3am daily now runs `backup-t5.sh` (replaces `backup-immich.sh`)
- Fixed `backup-immich.sh` path references from `/Volumes/ImmichBackup` → `/Volumes/Backup`

**Current recovery posture:**
| If... | Photos | Audiobooks | Books | Services config |
|-------|--------|------------|-------|----------------|
| T7 fails | T5 ✅ | T5 ✅ | T5 ✅ + R2 ✅ | R2 ✅ |
| T5 fails | R2 ✅ | ❌ re-download | R2 ✅ | R2 ✅ |
| Both fail | ❌ | ❌ | R2 ✅ | R2 ✅ |

**Remaining:** T5 backup has no Uptime Kuma heartbeat — if T5 isn't plugged in, cron silently fails. Add a push monitor when convenient.

### 20. Import old photo archives into Immich

~140GB of personal photos sitting on T7 outside of Immich, organised by year/trip:

- `/Volumes/T7/2002` → `/Volumes/T7/2024` — ~130GB of photos going back years
- `/Volumes/T7/from iphone (reikia surušiuoti)` — 9.2GB unsorted iPhone photos
- Notable: `/Volumes/T7/2024` (99GB) contains Barcelona F1 + Zakopane trips with both iPhone and camera shots

- [ ] Check if any of these are already in Immich (avoid duplicates)
- [ ] Import via Immich CLI or bulk upload through the web UI
- [ ] Sort/tag the unsorted iPhone folder before importing
- [ ] Delete originals from T7 after confirming import (frees ~140GB)

### ~~16. Docker VM resource limits~~ ✅ Done (2026-07-23)

Docker Desktop VM bumped from 7.8GB → 10GB RAM, swap 1GB → 2GB (via
`settings-store.json`). Also enabled AutoStart so Docker launches on login
after a reboot/power cut. All 40 containers verified back up, key services
responding (photos/vault/home/watch/nas all 200).

---

## Done

- [x] ~~Books & audio automation (Jul 2026)~~ — LazyLibrarian fully configured: 4 Torznab indexers via Prowlarr (EBookBay, TPB, Knaben, TorrentDownload), Transmission download client, PostProcessor auto-moves EPUBs to Calibre and MP3s to Audiobookshelf. Click "Wanted" → fully hands-off. See `docs/guides/BOOKS.md` for setup notes and gotchas.

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

Two Samsung SSDs connected to the Mac Mini (T5 plugged in for backups, not permanently):

| Drive | Size | Role | Mount path |
|-------|------|------|-----------|
| **T7** | 1TB | Primary data | `/Volumes/T7/` |
| **T5** | 500GB | Local backup | `/Volumes/Backup/` |

**What lives where:**

| Data | Drive | Path |
|------|-------|------|
| Immich photos | T7 | `/Volumes/T7/immich/upload` |
| Immich DB | T7 | `/Volumes/T7/immich/postgres` |
| Media (movies, TV, downloads) | T7 | `/Volumes/T7/media/` |
| Audiobooks | T7 | `/Volumes/T7/audiobooks/` (symlinked from `~/services/audiobookshelf/data/audiobooks`) |
| Calibre books | T7 | `/Volumes/T7/calibre-books/` |
| Docker data | Internal SSD | `~/Library/Containers/com.docker.docker` (51GB actual / 245GB sparse) |

**Cloud backup (rclone → Cloudflare R2), nightly 5am:**
- Docker service configs, obsidian vault, Calibre books, DB dumps → R2 `peciulevicius-backups`
- Script: `~/.dotfiles/services/rclone/rclone-backup.sh`
- ~1.3GB total (critical-only; photos/audiobooks excluded from R2)

**Local backup (rsync T7 → T5 `/Volumes/Backup`), nightly 3am:**
- `~/.dotfiles/scripts/backup/backup-t5.sh`
- Covers: Immich photos, audiobooks, Calibre books
- Skips: media (movies/TV — too large, acceptable loss)

**If T7 dies:** photos + audiobooks + books on T5. Services configs on R2. Re-download media.
**If T5 dies:** replace it, rsync from T7 again.
**If Mac Mini dies:** all data safe on T7. Reinstall macOS, clone dotfiles, restore from R2.

---

## Quick reference

| Service | Container path | Mac mini path |
|---|---|---|
| Radarr/Sonarr media | `/media` | `/Volumes/T7/media` |
| Radarr movies | `/media/movies` | `/Volumes/T7/media/movies` |
| Sonarr TV | `/media/tv` | `/Volumes/T7/media/tv` |
| Transmission downloads | `/downloads` | `/Volumes/T7/media/downloads` |
| Audiobookshelf | `/audiobooks` | `/Volumes/T7/audiobooks` (symlink: `~/services/audiobookshelf/data/audiobooks`) |
| Calibre library | `/books` | `/Volumes/T7/calibre-books` |
| Immich photos | `/usr/src/app/upload` | `/Volumes/T7/immich/upload` |
| Immich DB | `/var/lib/postgresql/data` | `/Volumes/T7/immich/postgres` |
