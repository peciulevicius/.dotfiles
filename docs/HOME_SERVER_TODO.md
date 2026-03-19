# Home Server — TODO

## Active

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
- [ ] Add Telegram, Discord, or email notification channel
- [ ] Test notification with a "Test" button

### 5. Verify B2 cloud backup

**Status:** Nightly cron at 5am backs up `~/services` configs + Obsidian vault → Backblaze B2.

- [x] Fixed cron PATH — added `/opt/homebrew/bin` to crontab
- [ ] Verify first real backup completes: check `~/logs/rclone-backup.log` after 5am
- [ ] Verify data in B2: `rclone ls b2:peciulevicius-services-backup/ | head -20`
- [ ] Consider: should database dumps also go to B2?
- [ ] Consider: should `.env` files be backed up (encrypted) to B2?

### 6. FreshRSS — add feeds

- [ ] Open http://localhost:8082, create account if needed
- [ ] Import OPML file or manually add RSS feeds

### 7. Linkwarden — phone setup

- [ ] Add to phone home screen as PWA: https://links.peciulevicius.com

### 8. Pi-hole local DNS

**Goal:** Access `*.peciulevicius.com` on local WiFi without going through Cloudflare.

- [ ] In Pi-hole admin (http://localhost:8053/admin) → Local DNS → DNS Records
- [ ] Add for each subdomain → Mac mini local IP
- [ ] Set router DNS to Mac mini IP (primary) + `1.1.1.1` (fallback)
- [ ] Test: `nslookup home.peciulevicius.com` should return Mac mini local IP

### 9. VPN for torrents (gluetun + Mullvad or Proton VPN)

**Goal:** Route Transmission traffic through a VPN so ISP can't see torrent activity. Not urgent — no downloads planned for ~1 month.

**Provider options (pick one):**
- [ ] **Mullvad** — €5/mo, best privacy, no email needed, cancel anytime
- [ ] **Proton VPN** — free tier works but slower, no port forwarding

**Setup (after choosing provider):**
- [ ] Create `services/gluetun/docker-compose.yml` with VPN credentials
- [ ] Update Transmission compose to use `network_mode: service:gluetun`
- [ ] Test: `docker exec transmission curl ifconfig.me` should show VPN IP, not home IP

---

## Done

- [x] ~~Media stack setup~~ — Sonarr/Radarr/Prowlarr/Transmission/Jellyfin fully connected, remote path mapping fixed, Narcos S1-S3 downloaded and playing
- [x] ~~Cloudflare DNS cleanup~~ — deleted stale CNAMEs: `sync`, `portainer`, `ai`
- [x] ~~Mealie~~ — setup complete
- [x] ~~Linkwarden~~ — setup complete, browser extensions installed (Chrome ✅, Brave ⚠️ disable Shields)
- [x] ~~Calibre-Web `metadata_dirtied` bug~~ — fixed: ran `CREATE TABLE` SQL
- [x] ~~Radarr Docker volumes~~ — compose already has `/media` mount
- [x] ~~Pi-hole 403 on root~~ — fixed: lighttpd redirect config mounted
- [x] ~~Transmission credentials~~ — changed to `admin` / `REDACTED`
- [x] ~~Homarr dashboard~~ — configured with all services, sections, descriptions
- [x] ~~Linkwarden bookmarks~~ — 621 bookmarks imported (services + browser bookmarks)
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
