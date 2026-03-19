# Home Server — TODO

## Active

### 1. Media stack setup (Sonarr/Radarr/Prowlarr → Transmission → Jellyfin)

**Status:** Containers running, volumes mounted at `/Volumes/T7/media/{downloads,movies,tv}`. Narcos S1 downloading via Sonarr → Transmission.

- [x] **Prowlarr** → Add indexers (YTS, Pirate Bay, LimeTorrents, Knaben added)
- [x] **Prowlarr** → Connect to Sonarr + Radarr via API
- [x] **Sonarr** → Add root folder `/media/tv`
- [x] **Sonarr** → Add Transmission as download client
- [x] **Radarr** → Add root folder `/media/movies`
- [x] **Radarr** → Add Transmission as download client
- [x] **Jellyfin** → Added TV Shows + Movies libraries
- [x] Test: Narcos S1-S3 → Sonarr → Transmission → imported → playing in Jellyfin
- [x] Fixed remote path mapping (Transmission `/downloads/` → Sonarr/Radarr `/media/downloads/`)

### 2. VPN for torrents (gluetun + Mullvad or Proton VPN)

**Goal:** Route Transmission traffic through a VPN so ISP can't see torrent activity. Not urgent — no active downloads planned for ~1 month.

**How it works:** gluetun container runs VPN tunnel, Transmission uses `network_mode: service:gluetun` so all its traffic exits through the VPN. If VPN drops, Transmission loses internet (built-in kill switch).

**Provider options (pick one):**
- [ ] **Mullvad** — €5/mo, best privacy, no email needed, cancel anytime
- [ ] **Proton VPN** — free tier works but slower, no port forwarding

**Setup (after choosing provider):**
- [ ] Create `services/gluetun/docker-compose.yml` with VPN credentials
- [ ] Update Transmission compose to use `network_mode: service:gluetun`
- [ ] Test: `docker exec transmission curl ifconfig.me` should show VPN IP, not home IP

### 3. Convert Audible AAX → Audiobookshelf

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

### 4. DeDRM Kindle books → Calibre-Web

**Goal:** Remove DRM from Kindle ebooks, add to Calibre-Web.

- [ ] Download [DeDRM_tools](https://github.com/noDRM/DeDRM_tools/releases)
- [ ] In Calibre desktop → Preferences → Plugins → Load plugin → `DeDRM_plugin.zip`
- [ ] Configure: Settings → DeDRM → eInk Kindle ebooks → add serial number
- [ ] Re-import DRM books to Calibre — DeDRM runs automatically
- [ ] Convert to EPUB: right-click → Convert → EPUB
- [ ] Books appear in Calibre-Web automatically (shared library folder)

### 5. Calibre-Web — organising books

Calibre-Web doesn't support folder creation from the UI. Use **Bookshelves** instead:
- [ ] Admin → Edit Shelves → create shelves (e.g. "Fiction", "Tech", "Papers")
- [ ] Add books to shelves
- [ ] Or manage folder structure in Calibre desktop (mirrored to Calibre-Web)
- [ ] Alternative: consider **Kavita** if folder/series support is needed

### 6. Uptime Kuma notifications

- [ ] Open http://localhost:3001 → Settings → Notifications
- [ ] Add Telegram, Discord, or email notification channel
- [ ] Test notification with a "Test" button

### 7. ~~Cloudflare DNS cleanup~~ ✅

- [x] Deleted stale CNAMEs: `sync`, `portainer`, `ai`

### 8. Verify B2 cloud backup

**Status:** Nightly cron at 5am backs up `~/services` configs + Obsidian vault → Backblaze B2. Was broken because cron didn't have `/opt/homebrew/bin` in PATH — fixed by adding `PATH=` line to crontab.

**What's backed up:**
- `~/services/*` configs (excludes `.env` files, `library/`, `data/postgres/` — large/sensitive data)
- `~/obsidian-vault` (excludes `.obsidian/workspace*`, plugins, `.DS_Store`)

**What's NOT backed up:**
- Immich photos (separate backup: T7 → T5 at 3am, not to B2 — too large)
- Database dumps (separate cron at 4am Sunday → local only)
- `.env` files (contain passwords — not sent to B2)

- [x] Fixed cron PATH — added `/opt/homebrew/bin` to crontab
- [ ] Verify first real backup completes: check `~/logs/rclone-backup.log` tomorrow after 5am
- [ ] Verify data in B2: `rclone ls b2:peciulevicius-services-backup/ | head -20`
- [ ] Consider: should database dumps also go to B2? (add to rclone-backup.sh)
- [ ] Consider: should `.env` files be backed up (encrypted) to B2?

### 9. FreshRSS — add feeds

- [ ] Open http://localhost:8082, create account if needed
- [ ] Import OPML file or manually add RSS feeds

### 10. Mealie — first-time setup

- [ ] Open http://localhost:9925, create admin account
- [ ] Default credentials: `changeme@email.com` / `MyPassword` — change immediately

### 11. Linkwarden — first-time setup

- [ ] Open http://localhost:3005 — account created
- [ ] Install browser extension: Chrome ✅, Brave ⚠️ (disable Shields for links.peciulevicius.com)
- [ ] Add to phone home screen as PWA: https://links.peciulevicius.com

### 12. Pi-hole local DNS

**Goal:** Access `*.peciulevicius.com` on local WiFi without going through Cloudflare.

- [ ] In Pi-hole admin (http://localhost:8053/admin) → Local DNS → DNS Records
- [ ] Add for each subdomain: `home.peciulevicius.com` → `192.168.x.x` (Mac mini local IP)
- [ ] Repeat for: `vault`, `photos`, `cloud`, `papers`, `rss`, `status`, `books`, `pihole`, `pdf`, `tools`, `listen`, `links`, `recipes`, `watch`, `sonarr`, `radarr`, `prowlarr`, `downloads`
- [ ] Set router DNS to Mac mini IP (primary) + `1.1.1.1` (fallback)
- [ ] Test: on a WiFi device, `nslookup home.peciulevicius.com` should return Mac mini local IP

---

## Done

- [x] ~~Calibre-Web `metadata_dirtied` bug~~ — fixed: ran `CREATE TABLE` SQL
- [x] ~~Radarr Docker volumes~~ — compose already has `/media` mount, just needs UI root folder config (moved to item 1)
- [x] ~~Pi-hole 403 on root~~ — fixed: lighttpd redirect config mounted
- [x] ~~Transmission credentials~~ — changed to `admin` / `REDACTED`
- [x] ~~Homarr dashboard~~ — configured with all 23 services, sections, descriptions
- [x] ~~Linkwarden bookmarks~~ — 621 bookmarks imported (23 services + browser bookmarks)
- [x] ~~Uptime Kuma monitors~~ — all 21 services monitored
- [x] ~~Ollama + Open WebUI~~ — removed (not enough RAM, using Claude instead)
- [x] ~~Audiobookshelf subdomain~~ — fixed: books → listen

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
