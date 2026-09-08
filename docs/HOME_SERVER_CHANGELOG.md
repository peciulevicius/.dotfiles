# Home Server — Completed Work

Archive of finished items, moved out of `HOME_SERVER_TODO.md` on 2026-09-08 so
that file holds only outstanding work. Kept because the *why* behind a past fix
is often what you need when something similar breaks again.

Newest first-ish; dates are when the work was finished.

---

### ~~1. Calibre-Web — finish setup~~ ✅ Done (2026-05-09)

Bookshelves skipped (not needed). Send to Kindle configured via Gmail SMTP — `peciulevicius-scribe@kindle.com` approved and working.


### ~~2. Uptime Kuma notifications~~ ✅ Done (2026-05-09)

Gmail SMTP configured (smtp.gmail.com:465, app password). Email alerts working.


### ~~5. Set up Obsidian vault sync via Syncthing~~ ✅ Done (2026-05-08)

`obsidian-vault` folder shared in Syncthing across Mac mini, MacBook, and iPhone. Real-time sync working.



### ~~8. Bazarr — subtitle provider~~ ✅ Done (2026-05-09)

OpenSubtitles.com configured, Default language profile set with English. Applied to all series and movies. 71 Wanted items queued — downloading automatically.


### ~~13. Show Mac host stats in monitoring~~ ✅ Done (2026-05-07)

Homebrew node_exporter running at port 9100, scraped by Prometheus (`job="mac-host"`). Custom Grafana dashboard (`mac-host.json`) provisioned — shows real 16GB RAM, swap, CPU, disk, network. Glance `server-stats` widget updated to show actual host figures.


### ~~14. Uptime Kuma — rclone backup heartbeat~~ ✅ Done (2026-05-09)

Push monitor added in Uptime Kuma. Heartbeat URL wired into `rclone-backup.sh` — pings up on success, down on failure. R2 backup verified working across all 4 targets.


### 15. ~~Migrate backups from B2 to Cloudflare R2~~ ✅ Done (2026-04-22)

Migrated to Cloudflare R2. Nightly rclone backup running at 5am. R2 at ~1.3GB (critical-only: vaultwarden, paperless docs, obsidian vault, db dumps, calibre books). B2 bucket purged and can be deleted from Backblaze dashboard.


### ~~16. Docker VM resource limits~~ ✅ Done (2026-07-23)

Docker Desktop VM bumped from 7.8GB → 10GB RAM, swap 1GB → 2GB (via
`settings-store.json`). Also enabled AutoStart so Docker launches on login
after a reboot/power cut. All 40 containers verified back up, key services
responding (photos/vault/home/watch/nas all 200).

---


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

**Recovery posture as of 2026-09-05** (superseded by the NAS migration — kept for history;
current posture is in the Drive Layout section below):
| If... | Photos | Audiobooks | Books | Services config |
|-------|--------|------------|-------|----------------|
| NAS fails | T7 ✅ + T5 ✅ | T7 ✅ + T5 ✅ | T7 ✅ + T5 ✅ + R2 ✅ | R2 ✅ |
| A drive fails | re-run `backup-external.sh` | same | same | R2 ✅ |
| Fire/theft | ❌ everything is in one room | ❌ | R2 ✅ | R2 ✅ |

**The real remaining gap:** both external drives sit next to the NAS, so nothing survives
fire, flood or theft. Moving T5 offsite is what makes this genuinely 3-2-1.


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
- [~] Actual Budget — was marked removed in favour of Wallet by Budget Bakers, but the `actual-budget` container is **still running** as of 2026-09-05. Either finish removing it or drop the strikethrough; right now the notes and reality disagree.
- [x] ~~Passkey migration~~ — all 5 services (Amazon, Binance, GitHub, Google, PSN) re-registered with Bitwarden
- [~] Karakeep — tried as a Linkwarden replacement and reverted, but `karakeep`, `karakeep-chrome` and `karakeep-meilisearch` are **still running** as of 2026-09-05 (three containers' worth of RAM). Either stop them or drop the strikethrough.
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

