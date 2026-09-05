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

### 22. Power-outage recovery — NOT fully automatic yet (found 2026-08-16)

**Incident:** Power outage while user was out. Mac mini did not come back up on its own — required physically pressing the power button. Once manually powered on, 10+ service stacks were down/erroring (bad gateway on Immich, Jellyfin, Bazarr, etc.) and the NAS tile showed "Timed Out."

**Root causes found and fixed this session:**
- [x] NAS got a new DHCP IP again (`.73` → `.106` → **`.75`**, second time this has happened — no router reservation yet). Updated `mount-nas.sh`, `glance.yml`, `~/.cloudflared/config.yml` to `.75` and restarted affected services.
- [x] Immich's `immich-server` image (pinned to rolling `release` tag) had auto-updated to v3.1.0 at some point (likely when the VM disk reset on 2026-08-09/10 wiped the local image cache and forced a fresh pull), which dropped support for the old `pgvecto-rs` Postgres extension. Migrated `immich-postgres` to the official bridge image `ghcr.io/immich-app/postgres:14-vectorchord0.3.0-pgvectors0.2.0` (Immich's documented upgrade path) — server auto-migrated the vector extension on restart, no data lost.
- [x] `sonarr`, `radarr`, `calibre`, `transmission`, `readarr` containers were stuck in `Created` (never started) — leftover from the `rebuild-services.sh` run during last week's Docker VM reset. Started them.

**Not fixed — needs your decision, can't be done remotely:**
- [ ] **FileVault is ON**, and no macOS auto-login is configured. Result: after any power loss, even though `pmset autorestart` is correctly set to 1 (Mac *does* try to power back on), it stops at the FileVault unlock/login screen and NOTHING further happens automatically — no Docker, no NAS mounts, no cloudflared, no watchdog — until someone is physically there to log in. This is exactly why manual button-pressing was needed, and it will happen again on any future outage. Two ways to actually fix this:
  1. Turn off FileVault, then enable auto-login (System Settings → Users & Groups → Login Options) — full auto-recovery, but the internal SSD is no longer encrypted at rest.
  2. Keep FileVault, accept that a power outage while away means physical intervention is required to bring the Mac mini back — mitigate by leaving it on a battery backup (UPS) so brief outages never actually cut power.
- [ ] **NAS "Auto power-on when power is supplied" was never confirmed enabled** (this is TODO #11's own pending item — see below, Hardware & Power settings on the NAS itself). Even if the Mac mini fully self-recovers, if the NAS doesn't power back on by itself, none of the NAS-dependent services come up. Can't check/set this remotely — needs the NAS admin web UI.
- [ ] `mount-nas.sh` only runs once at login and gives up after 3 minutes if the NAS isn't reachable yet — a NAS doing a RAID5 array check after a hard power cut could plausibly take longer than that. Worth widening the timeout and/or adding a periodic retry so a late-booting NAS still gets mounted without a fresh login. (Proposed this session, held off — needs your go-ahead since it's a new persistent schedule.)

**Bottom line for "will it work tomorrow if the power goes out": likely NOT fully** — the Mac mini needs a human to physically log in past FileVault, and the NAS's own auto-power-on is unverified. A UPS on both devices is the highest-leverage fix if going away for real chunks of time.

### 23. NAS IP drift — root-caused and fixed (2026-09-05)

**Incident:** All NAS-backed services (Immich, Jellyfin, Bazarr, Calibre, Sonarr/Radarr,
Transmission, Readarr, LazyLibrarian, Audiobookshelf — 11 containers) had been down
**~7 days**, exited 255. `nas.peciulevicius.com`, `photos`, `watch` etc. all failing.
Nobody noticed because nothing alerts when the Mac mini's own monitoring is what's broken.

**Cause:** NAS IP drifted a *third* time (`.75` → `.73`). The IP was hard-coded in three
places, so every drift silently orphaned every NAS-backed service until someone was
physically home.

**Fixed — IP is no longer used anywhere:**
- [x] Everything now addresses the NAS as **`DH4300PLUS-DP.local`** (Bonjour/mDNS), which
  follows it to any IP. Verified working from the host, cloudflared, inside Docker
  containers, and for SMB mounts (keychain matches on it — no re-auth needed).
  Changed in `mount-nas.sh`, `services/glance/glance.yml`, `~/.cloudflared/config.yml`.
- [x] `mount-nas.sh` rewritten: mDNS-first with numeric fallback, 10-min boot wait (was
  3 — too short for a NAS doing a RAID5 check after a hard power cut), 30s timeout per
  mount so a missing keychain entry can't wedge the agent on an invisible GUI prompt,
  and a no-op fast path when everything is already mounted.
- [x] **New `com.peciulevicius.nas-watchdog` agent** (`scripts/utils/nas-watchdog.sh`,
  every 5 min): remounts dropped shares, then `compose up -d`s any NAS-backed container
  that isn't running. Closes the gap that let this sit broken for a week —
  `docker-watchdog.sh` only ever watched Docker itself, never the mounts or the
  containers. Tested by stopping a container + unmounting a share: recovered in <1s.

**Still open (belt-and-braces, no longer load-bearing):**
- [ ] Router DHCP reservation on OpenWrt (`192.168.1.1`) — MAC `6c:1f:f7:a9:39:e9`.
  Worth doing so the IP stops moving at all, but mDNS now absorbs the drift.

### 24. Tailscale is LOGGED OUT on the Mac mini (found 2026-09-05) — remote access is dead

`tailscale status` → `Logged out` / `BackendState: NeedsLogin`. Consequences:
- Every Tailscale-only service is unreachable from outside the house: Sonarr, Radarr,
  Prowlarr, Transmission, Syncthing, Jellyseerr, Bazarr, Grafana, Prometheus,
  LazyLibrarian, Karakeep (all the `100.81.171.49:<port>` links in Glance).
- No `ssh macmini` from away — so when something breaks while travelling there is
  currently **no way to fix it remotely at all**. This is exactly the "I'm not home and
  can't do anything" problem.
- The NAS's own Tailscale node (`ugreen-nas`, was `100.95.228.35`) is also gone from the
  tailnet.

**Resolved 2026-09-05** — user logged back in:
- [x] Mac mini back on the tailnet as `100.81.171.49` (same IP as before, so every
  Tailscale link in Glance still works). NAS node `ugreen-nas` (100.95.228.35) is back
  too. All 10 Tailscale-only services verified responding.
- [ ] **Still to do — disable key expiry** on `macmini` and `ugreen-nas` in the
  Tailscale admin console (Machines → ⋯ → Disable key expiry). Current key expires
  **2027-03-04**, and when it does, remote access dies silently exactly like this
  time — most likely while away, which is when it's needed. This is the actual
  permanent fix; logging back in is only a reset of the same 6-month timer.

### 25. Backups were silently under-reporting (found + partly fixed 2026-09-05)

Found while checking whether anything else broke during the 7-day NAS outage. Two
separate ways backups looked healthy while not actually protecting the data:

**a) rclone → R2 reported success while skipping missing sources — FIXED**
A source directory that didn't exist was treated as a benign skip (`log_warn`, no
error count), so the script still printed "All backups complete" and pinged the
Uptime Kuma heartbeat as **up/OK**. During the outage `/Volumes/books` was unmounted,
so Calibre books went unbacked-up for 7 days behind a green status page.
- [x] Missing sources now count as errors → heartbeat goes **down** → Uptime Kuma
  alerts. Verified: still all-green when the shares are mounted.

**b) T5 local backup hasn't run since ~2026-08-06 — EXPECTED, but silent**
T5 is unplugged (it's earmarked for the parents' offsite copy), so the 3am cron exits
immediately each night. Log files since then are the 133–142 byte "not mounted" error.
Nothing alerts on this — it's the missing heartbeat noted in TODO #19.
- [ ] Decide what T5 is actually for now. Once it lives at the parents' house it can
  never be the nightly local target, so either accept "no local backup" or pick a new
  local target (the NAS itself is RAID5, not a backup — it doesn't protect against
  deletion or ransomware).
- [ ] Add an Uptime Kuma push heartbeat to `backup-t5.sh` so whatever it ends up being
  is actually monitored (TODO #19 leftover).

**Current real posture:** R2 (configs, obsidian, DB dumps, Calibre books) is the only
backup actually running. Photos/audiobooks/media exist **only** on the NAS's RAID 5 —
which survives a dead drive but not an accidental delete, a corrupted share, or theft.

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

**Migration done (2026-08-04)** ✅
- [x] RAID 5 pool created (3× 6TB IronWolf Pro = ~11TiB usable), Btrfs
- [x] SMB on; shares: `media`, `immich`, `audiobooks`, `books`, `unsorted`; service account `macmini` (ASCII name — `ž` in `Džiugas` breaks SMB auth)
- [x] Tailscale via Docker container on NAS (`ugreen-nas`, 100.95.228.35) — remote SMB/Finder
- [x] Full copy T7 → NAS (~680GB incl. 142G photo archives → `unsorted`), zero errors
- [x] All services switched to NAS paths (`/Volumes/media` etc.); Immich Postgres moved to internal SSD (`~/services/immich/data/postgres`) — DBs must not live on SMB
- [x] Reboot-proof mounts: `scripts/utils/mount-nas.sh` + `com.peciulevicius.mount-nas` LaunchAgent
- [x] Glance tile for NAS

**Remaining follow-ups:**
- [x] ~~Update rclone/T5 backup scripts to NAS paths~~ (2026-08-04 — backup-t5.sh, backup-immich.sh, rclone-backup.sh all read from NAS mounts; T7 fully decoupled, safe to disconnect. Keep T7 data intact on the shelf ~2 weeks before wiping/repurposing)
- [ ] Delete stale `immich/postgres` folder on NAS share (460MB dead copy — via Files app)
- [ ] Verify first NAS-sourced backups: T5 cron (3am, needs T5 plugged) + rclone (5am)
- [ ] Decide: delete stale `/Volumes/T7/docker/` (53G old Docker VM copy)
- [ ] T5 future plan: reload with full photo/video collection, store at parents' home as offsite family copy
- [ ] Verify drive sleep works (configured: 20 min idle)
- [ ] Optional: Bonjour + Time Machine target, NAS rsync service
- [ ] Mac mini auto-login (System Settings → Users & Groups) — without it, after a power outage neither Docker, cloudflared, nor NAS mounts come up
- [ ] Watch streaming: 4K high-bitrate files may exceed the extender's ~100Mbps ceiling — if Jellyfin buffers, wire the NAS/Mac path properly

**Hardware reference:** 4-bay, RK3588C ARM 8-core, 8GB RAM (keep NAS storage-only — no heavy Docker workloads; compute stays on Mac mini), 2.5GbE port. Purchase total ~€1,060 (NAS €340 + drives €690 + switch/cables €30).

### 21. Rotate reused passwords (NAS accounts)

Both NAS accounts (`Džiugas` admin + `macmini` SMB service account) currently
use the same password as elsewhere. Rotate to unique generated passwords:
- [ ] `Džiugas` (web UI admin) — generate in Bitwarden, update entry
- [ ] `macmini` (SMB) — generate in Bitwarden; after changing on NAS, update
  the saved credential in macOS Keychain on the Mac mini (Finder will prompt
  on next mount; also remount the four shares)
- [ ] While at it: audit other reused passwords flagged by Bitwarden's
  Vault Health report

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
