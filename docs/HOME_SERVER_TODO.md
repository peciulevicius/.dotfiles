# Home Server — TODO

## Active

### 0. Restart stopped services

Many services are currently stopped (likely after a Docker restart or reboot). Bring them back up:

```bash
for svc in sonarr-radarr transmission pihole nextcloud paperless-ngx calibre-web mealie it-tools stirling-pdf jellyseerr bazarr; do
  cd ~/services/$svc && docker compose up -d
done
```

- [ ] sonarr-radarr (Sonarr/Radarr/Prowlarr)
- [ ] transmission
- [ ] pihole
- [ ] nextcloud
- [ ] paperless-ngx
- [ ] calibre-web
- [ ] mealie
- [ ] it-tools
- [ ] stirling-pdf
- [ ] jellyseerr
- [ ] bazarr

**Tip:** Add a startup script or Docker restart policy check — all services should have `restart: unless-stopped` so they auto-recover. If they're not restarting, check `docker compose ps` to see if they exited with errors.

### 1. Convert Audible AAX → Audiobookshelf

**Goal:** Strip DRM from Audible AAX files, convert to M4B, add to Audiobookshelf.

- [ ] Install `audible-cli`: `pip install audible-cli`
- [ ] Get activation bytes: `audible activation-bytes`
- [ ] Convert AAX → M4B (keeps chapters):
  ```bash
  ffmpeg -activation_bytes YOUR_BYTES -i book.aax -c copy book.m4b
  ```
- [ ] Or batch convert with [AAXtoMP3](https://github.com/KrumpetPirate/AAXtoMP3):
  ```bash
  ./AAXtoMP3 --authcode YOUR_BYTES *.aax
  ```
- [ ] Place converted files in `~/services/audiobookshelf/data/audiobooks/`
- [ ] In Audiobookshelf → Libraries → scan

### 2. DeDRM Kindle books → Calibre-Web

**Goal:** Remove DRM from Kindle ebooks, add to Calibre-Web.

- [ ] Download [DeDRM_tools](https://github.com/noDRM/DeDRM_tools/releases)
- [ ] In Calibre desktop → Preferences → Plugins → Load plugin → `DeDRM_plugin.zip`
- [ ] Configure: Settings → DeDRM → eInk Kindle ebooks → add serial number
- [ ] Re-import DRM books to Calibre — DeDRM runs automatically
- [ ] Convert to EPUB: right-click → Convert → EPUB
- [ ] Books appear in Calibre-Web automatically (shared library folder)

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

### 6. Linkwarden → Karakeep migration

**Goal:** Replace Linkwarden with Karakeep (formerly Hoarder) for AI-powered bookmarking with auto-tagging, smart lists, and native mobile apps.

**Why Karakeep over Linkwarden:** AI auto-tagging, smart lists, saves notes/images/PDFs (not just links), Meilisearch full-text search, native iOS/Android apps, 2x the GitHub stars and momentum.

- [x] Staged to `~/services/karakeep/` and added to setup-services.sh (port 3006)
- [x] Added to Glance dashboard (Tailscale bookmarks, port 3006)
- [ ] Generate secrets and start:
  ```bash
  # Generate two secrets
  openssl rand -base64 36  # → NEXTAUTH_SECRET
  openssl rand -base64 36  # → MEILI_MASTER_KEY
  # Edit ~/services/karakeep/.env with those values
  cd ~/services/karakeep && docker compose up -d
  ```
- [ ] Export all 621 bookmarks from Linkwarden (Settings → Export → HTML)
- [ ] Import bookmarks from HTML export (Karakeep → Settings → Import)
- [ ] Configure AI tagging (optional — add `OPENAI_API_KEY` to .env or set up Ollama)
- [ ] Install browser extension + mobile app
- [ ] Verify all bookmarks imported correctly
- [ ] Update Cloudflare Tunnel: change `links.peciulevicius.com` from Linkwarden (3005) → Karakeep (3006)
- [ ] Update Uptime Kuma monitors
- [ ] Stop and remove Linkwarden containers: `cd ~/services/linkwarden && docker compose down`
- [ ] Update Glance dashboard: swap Linkwarden for Karakeep in monitors and bookmarks

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

### 8. NordPass → Vaultwarden migration

**Goal:** Move all passwords from NordPass into self-hosted Vaultwarden. Review and clean up stale entries during migration.

- [ ] In NordPass: Settings → Export → download CSV (`nordpass_export.csv`)
- [ ] Run conversion script (outputs `bitwarden_import.json`):
  ```bash
  bash ~/.dotfiles/scripts/nordpass-to-bitwarden.sh nordpass_export.csv
  ```
- [ ] Review `bitwarden_import.json` — delete stale/duplicate entries before import
- [ ] In Vaultwarden: Admin → Import Data → format: Bitwarden JSON → upload `bitwarden_import.json`
- [ ] Verify all logins imported correctly
- [ ] Install Bitwarden browser extension + mobile app, connect to `vault.peciulevicius.com`
- [ ] Test: log in to a few sites using Vaultwarden autofill
- [ ] Cancel NordPass subscription after verified working

**Note:** The NordPass CSV has columns: `name,url,username,password,note,cardholdername,cardnumber,cvc,expirydate,ziporpostalcode,folder,type`

### 9. Set up Actual Budget (finance tracking)

**Goal:** Self-hosted personal finance tracker. Zero-based budgeting, bank CSV import.

- [x] Staged to `~/services/actual-budget/` and added to setup-services.sh
- [x] Added to Glance dashboard (Finance page + Tailscale bookmarks)
- [ ] `docker compose up -d` in `~/services/actual-budget/`
- [ ] Open http://100.81.171.49:5006 → create budget
- [ ] Export transactions from your bank as CSV
- [ ] Import: Settings → Import transactions → select CSV
- [ ] Configure budget categories
- [ ] Tailscale-only is fine — no need to expose finance data publicly

### 10. Configure new services

- [ ] **Jellyseerr** (http://100.81.171.49:5055) — deploy first: `cd ~/services/jellyseerr && docker compose up -d`
  - Sign in with Jellyfin account
  - Settings → Sonarr: host `sonarr`, port `8989`, API key from Sonarr Settings → General
  - Settings → Radarr: host `radarr`, port `7878`, API key from Radarr Settings → General

- [ ] **Bazarr** (http://100.81.171.49:6767) — deploy first: `cd ~/services/bazarr && docker compose up -d`
  - Settings → Sonarr: host `localhost`, port `8989`, API key from Sonarr Settings → General → API Key
  - Settings → Radarr: host `localhost`, port `7878`, API key from Radarr Settings → General → API Key
  - Settings → Providers → Add provider: **OpenSubtitles.com** (free account at opensubtitles.com)
  - Settings → Languages → Add profile: set English + Lithuanian as preferred
  - Apply profile to all series and movies

- [x] **Grafana** (http://100.81.171.49:3000) — running
  - [ ] Login: admin / admin → change password
  - [ ] Connections → Add data source → Prometheus → URL: `http://prometheus:9090` → Save & Test
  - [ ] Dashboards → Import → ID `1860` → Load → select Prometheus source → Import

### 11. FreshRSS — add feeds

- [ ] Open http://localhost:8082, create account if needed
- [ ] Import OPML file or manually add RSS feeds

### 12. Pi-hole local DNS (later)

**Note:** After pulling latest dotfiles and restarting Glance, add `PIHOLE_API_KEY` to `~/services/glance/.env`:
1. Pi-hole admin → Settings → API/Web interface → Show API token
2. Copy the token → add `PIHOLE_API_KEY=<token>` to `~/services/glance/.env`
3. `docker compose restart` in `~/services/glance/`

**Goal:** Access `*.peciulevicius.com` on local WiFi without going through Cloudflare.

- [ ] In Pi-hole admin (http://localhost:8053/admin) → Local DNS → DNS Records
- [ ] Add for each subdomain → Mac mini local IP
- [ ] Set router DNS to Mac mini IP (primary) + `1.1.1.1` (fallback)
- [ ] Test: `nslookup home.peciulevicius.com` should return Mac mini local IP

### 13. Replace external SSDs with proper NAS storage (later)

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

### 14. VPN for torrents (later)

**Goal:** Route Transmission traffic through a VPN so ISP can't see torrent activity. Not urgent — no downloads planned for ~1 month.

**Provider options (pick one):**
- [ ] **Mullvad** — €5/mo, best privacy, no email needed, cancel anytime
- [ ] **Proton VPN** — free tier works but slower, no port forwarding

**Setup (after choosing provider):**
- [ ] Create `services/gluetun/docker-compose.yml` with VPN credentials
- [ ] Update Transmission compose to use `network_mode: service:gluetun`
- [ ] Test: `docker exec transmission curl ifconfig.me` should show VPN IP, not home IP

### 15. Show Mac host stats in monitoring (alongside Docker VM stats)

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

### 16. Uptime Kuma — B2 backup heartbeat

**Goal:** Alert if nightly rclone backup silently fails while away.

- [ ] In Uptime Kuma → Add Monitor → type: Push → copy the heartbeat URL
- [ ] Add to end of `~/.dotfiles/services/rclone/rclone-backup.sh`:
  ```bash
  curl -s "https://uptime.peciulevicius.com/api/push/YOUR_HEARTBEAT_KEY" > /dev/null
  ```
- [ ] Test by running the backup script manually — Kuma should show green

### 17. Docker VM resource limits (later)

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
- [x] ~~Actual Budget~~ — staged, added to Glance Finance page (deploy: `cd ~/services/actual-budget && docker compose up -d`)
- [x] ~~Karakeep~~ — staged at port 3006, added to Glance (needs secrets + deploy before use)
- [x] ~~Jellyseerr~~ — media request/discovery UI for Jellyfin (Tailscale-only, port 5055)
- [x] ~~Bazarr~~ — automated subtitle management for Sonarr/Radarr (Tailscale-only, port 6767)
- [x] ~~Grafana + Prometheus~~ — monitoring stack with Node Exporter (Tailscale-only, ports 3000/9090/9100)
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
- [x] ~~Audiobookshelf subdomain~~ — fixed: books → listen
- [x] ~~B2 cloud backup~~ — nightly cron at 5am, services + obsidian-vault + Immich photos all backed up
- [x] ~~Immich photos B2 backup~~ — added `/Volumes/T7/immich/upload` to rclone-backup.sh

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
| Time Machine (MacBook + Mac Mini) | T7 | APFS `TimeMachine` volume |
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
