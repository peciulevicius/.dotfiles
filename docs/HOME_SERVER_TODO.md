# Home Server — TODO

## Active

### 1. DeDRM Kindle books → Calibre-Web

**Goal:** Remove DRM from Kindle ebooks, add to Calibre-Web.

**Done so far:**
- [x] Download [DeDRM_tools](https://github.com/noDRM/DeDRM_tools/releases) (v10.0.3)
- [x] Install DeDRM + Obok plugins in Calibre desktop (MacBook Air)
- [x] Configure: DeDRM → eInk Kindle → added both serials (Scribe + Paperwhite)
- [x] DeDRM'd 5 sideloaded/DRM-free books → converted to EPUB → in `/Users/peciulevicius/BOOKS/Calibre/`
  - Project Hail Mary (Andy Weir) — original cover set
  - Man's Search for Meaning (Viktor E. Frankl)
  - The Culture Code (Daniel Coyle)
  - Kaip pildyti 2026m. VMI deklaraciją? (sesinuliai.lt)
  - Social Styles and Versatility report
- [x] Copied full Kindle Paperwhite `/mnt/us/documents/` via SSH (KOReader) → `/Users/peciulevicius/BOOKS/kindle-paperwhite-full/`

**Blocked — Amazon KFX DRM:**
- Serial-based decryption fails on all Amazon-purchased KFX books (newer Paperwhite firmware changed key derivation)
- DeDRM 10.0.3 doesn't support the new Kindle Mac app (Lassen) DRM either
- Amazon removed "Download & transfer via USB" from their website (Feb 2025)

**Setup done (Apr 2026):**
- [x] Install [UTM](https://mac.getutm.app/) + [CrystalFetch](https://apps.apple.com/app/crystalfetch/id6445889614) (VM + Windows ISO downloader)
- [x] Download [Satsuoni DeDRM v10.0.18](https://github.com/Satsuoni/DeDRM_tools/releases/tag/v10.0.18) with KFXArchiver283.exe → `~/BOOKS/kindle-dedrm-tools/DeDRM_v10.0.18/`
- [x] Download Kindle for PC 2.8.2 installer → `~/BOOKS/kindle-dedrm-tools/KindleForPC-installer-2.8.2.exe`

**Remaining steps — Windows VM + Kindle for PC 2.8.2:**
1. [ ] Open CrystalFetch → download Windows 11 ARM ISO
2. [ ] Open UTM → Create VM → Virtualize → Windows → select ISO → 8GB RAM, 64GB disk
3. [ ] Install Windows 11, then install SPICE Guest Tools from the UTM virtual drive
4. [ ] Copy `KindleForPC-installer-2.8.2.exe` into the VM (drag & drop or shared folder)
5. [ ] Install Kindle for PC → Tools → Options → General → uncheck auto-updates
6. [ ] Sign in to Amazon, download all books
7. [ ] Copy `DeDRM_v10.0.18/KFXArchiver283.exe` into the VM
8. [ ] Run `KFXArchiver283.exe` in the Kindle app folder — creates DRM-free KFX-ZIP files
9. [ ] Copy decrypted files back to Mac → import into Calibre → convert to EPUB
10. [ ] rsync clean library to Mac mini: `rsync -avz ~/BOOKS/Calibre/ macmini:~/services/calibre-web/data/books/`
11. [ ] Scan in Calibre-Web

### 3. Calibre-Web — organising books

Calibre-Web doesn't support folder creation from the UI. Use **Bookshelves** instead:
- [ ] Admin → Edit Shelves → create shelves (e.g. "Fiction", "Tech", "Papers")
- [ ] Add books to shelves
- [ ] Or manage folder structure in Calibre desktop (mirrored to Calibre-Web)
- [ ] Alternative: consider **Kavita** if folder/series support is needed

### 4. Uptime Kuma notifications

- [ ] Open http://localhost:3001 → Settings → Notifications
- [ ] Add email notification channel
- [ ] Test notification with a "Test" button

### 5. Paperless-NGX — organise documents

Paperless-NGX doesn't support traditional folders — it uses **tags**, **document types**, and **correspondents** instead.

- [ ] Create document types: e.g. "Invoice", "Contract", "Receipt", "Statement"
- [ ] Create correspondents: e.g. "Bank", "Employer", "Government"
- [ ] Create tags: e.g. "Tax 2024", "Important", "Archive"
- [ ] Assign types/correspondents/tags to uploaded documents
- [ ] Use **Saved Views** (left sidebar) to create folder-like filtered views

### 6. Linkwarden — browser extension + import

- [ ] Install Linkwarden browser extension
- [ ] Import bookmarks from Chrome/Brave

### 7. Set up Obsidian vault sync via Syncthing

**Goal:** Real-time vault sync across Mac mini, MacBook, and phone — replacing the nightly B2 backup (one-way) as the primary sync mechanism.

Syncthing is already running on all three devices. Just needs the vault folder configured.

- [ ] On Mac mini Syncthing (http://localhost:8384):
  - Add Folder → select Obsidian vault path (e.g. `~/Documents/MyVault`)
  - Get the Folder ID shown
  - Share with MacBook and iPhone device IDs (visible in Remote Devices on each device)
- [ ] On MacBook: accept folder share invitation from Mac mini
- [ ] On iPhone (Syncthing app): accept folder share invitation
- [ ] Test: edit a note on phone → verify it appears on MacBook within seconds


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

### 13. Show Mac host stats in monitoring (alongside Docker VM stats)

**Problem:** Glance/Grafana currently shows Docker Linux VM memory (~7.8GB), not the actual Mac mini's 16GB RAM, real CPU, thermals, or disk health.

**Solution:** Run node-exporter natively on macOS (outside Docker), scrape it with Prometheus, show it in Glance/Grafana.

- [ ] Install node-exporter on macOS host (via Homebrew):
  ```bash
  brew install node_exporter
  brew services start node_exporter
  # Now running at http://localhost:9100/metrics
  ```
- [ ] Add host scrape target to Prometheus config (`prometheus.yml`):
  ```yaml
  scrape_configs:
    - job_name: 'mac-host'
      static_configs:
        - targets: ['host.docker.internal:9100']
          labels:
            instance: 'mac-mini-host'
    - job_name: 'docker-vm'
      static_configs:
        - targets: ['node-exporter:9100']
          labels:
            instance: 'docker-vm'
  ```
- [ ] Restart Prometheus container to pick up config change
- [ ] In Grafana → import dashboard ID `1860` again, select `mac-mini-host` instance → real Mac RAM/CPU/disk
- [ ] Import Grafana dashboard ID `893` (Docker containers) — shows per-container RAM so you know which is the culprit next time memory spikes
- [ ] In Glance, add a second `system-monitor` widget pointing to host metrics — shows both VM and Mac side by side

**What you'll be able to monitor:**

| Metric | Docker VM | Mac Host |
|--------|-----------|----------|
| RAM | ✅ (7.8GB view) | ✅ (full 16GB) |
| CPU | ✅ | ✅ (all cores) |
| Disk | partial | ✅ (T7, T5, internal) |
| Swap | ✅ (1GB VM swap) | ✅ (real macOS swap) |
| Thermals | ❌ | ✅ (with extra tool) |
| Network | ✅ | ✅ |

- [ ] **Bonus — Mac thermals:** install [mac-metrics-exporter](https://github.com/antoniopataro/mac-metrics-exporter) for CPU die temp, fan speed, power draw. Useful for checking the Mini isn't overheating headless.

### 14. Uptime Kuma — B2 backup heartbeat

**Goal:** Alert if nightly rclone backup silently fails while away.

- [ ] In Uptime Kuma → Add Monitor → type: Push → copy the heartbeat URL
- [ ] Add to end of `~/.dotfiles/services/rclone/rclone-backup.sh`:
  ```bash
  curl -s "https://uptime.peciulevicius.com/api/push/YOUR_HEARTBEAT_KEY" > /dev/null
  ```
- [ ] Test by running the backup script manually — Kuma should show green

### 15. Migrate backups from B2 to Cloudflare R2 (later)

**Goal:** Replace Backblaze B2 with Cloudflare R2 for cloud backups. R2 has 10GB free, no egress fees, already using Cloudflare.

**Current B2 usage:** ~1.2GB (services configs + obsidian vault). Immich photos backup disabled — relying on T5 local backup.

- [ ] Cloudflare dashboard → R2 → Create bucket (e.g. `peciulevicius-backups`)
- [ ] Create R2 API token (Object Read & Write)
- [ ] `rclone config` → add `r2` remote (type: s3, provider: Cloudflare, endpoint: `<account-id>.r2.cloudflarestorage.com`)
- [ ] Migrate data: `rclone sync b2:peciulevicius-services-backup r2:peciulevicius-backups`
- [ ] Update `~/.dotfiles/services/rclone/.env` and `~/services/rclone/.env`: change `RCLONE_REMOTE=b2` → `RCLONE_REMOTE=r2`
- [ ] Update `BACKUP_DEST` to use new bucket name
- [ ] Test: `bash ~/.dotfiles/services/rclone/rclone-backup.sh --dry-run`
- [ ] Delete B2 bucket after verifying R2 works

### 16. Docker VM resource limits (later)

**Goal:** Give Docker more headroom for the full stack.

Current: ~7.8GB RAM / 1GB swap (Docker Desktop default)
Recommended: 10GB RAM / 2GB swap

- [ ] Docker Desktop → Settings → Resources → increase RAM to 10GB, swap to 2GB
- [ ] Restart Docker, verify containers come back up
- [ ] Check Glance — RAM pressure should be gone even with full stack running

---

## Done

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
- [x] ~~Audible AAX → Audiobookshelf (Apr 2026)~~ — converted 28 AAX audiobooks to M4B via `scripts/convert-audiobooks.sh` (ffmpeg stream copy, chapters preserved). Synced to Mac mini Audiobookshelf.
- [x] ~~B2 backup cleanup (Apr 2026)~~ — deleted Immich photos (7GB), Linkwarden (644MB), Audiobookshelf (890MB) from B2. Down from 9.7GB to 1.2GB. Immich backup disabled (using T5 local). Script fixed: `pipefail` + error counter.
- [x] ~~Cloudflared plist fix~~ — brew service was missing `tunnel run` args, created proper `com.cloudflare.cloudflared.plist` launch agent
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

**Cloud backup (rclone → Backblaze B2):**
- Docker service configs → `b2-backup:peciulevicius-services-backup/services`
- Obsidian vault → `b2-backup:peciulevicius-services-backup/obsidian-vault`
- Immich photos → `b2-backup:peciulevicius-services-backup/immich-photos`
- Runs nightly at 5am via cron: `~/.dotfiles/services/rclone/rclone-backup.sh`

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
