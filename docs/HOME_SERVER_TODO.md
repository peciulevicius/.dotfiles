# Home Server — TODO

## 1. Fix Radarr Docker volumes

**Problem:** Radarr is browsing the container's internal filesystem, not the Mac mini's disk.

- [ ] Open `docker-compose.yml` for Radarr
- [ ] Add volume mounts:
  ```yaml
  volumes:
    - /path/on/macmini/config:/config
    - /path/on/macmini/movies:/movies
    - /path/on/macmini/downloads:/downloads
  ```
- [ ] Do the same for the download client (qBittorrent/SABnzbd/etc.) — it needs the same `/downloads` path mapped
- [ ] Restart: `docker compose down && docker compose up -d`
- [ ] In Radarr → Settings → Media Management → Root Folders → add `/movies`
- [ ] In Radarr → Settings → Download Clients → verify remote path mappings

---

## 2. Convert Audible AAX → MP3 → Audiobookshelf

**Goal:** Strip Audible DRM from AAX files and convert to MP3 (or M4B), then add to Audiobookshelf.

### Steps

- [ ] Get your Audible activation bytes (one-time):
  ```bash
  # Install audible-activator or use RCX (GUI) to extract your bytes
  # Or: pip install audible-cli
  audible activation-bytes
  ```
- [ ] Convert AAX → M4B or MP3 using `ffmpeg`:
  ```bash
  # M4B (recommended — keeps chapters)
  ffmpeg -activation_bytes YOUR_BYTES -i book.aax -c copy book.m4b

  # MP3 (no chapters)
  ffmpeg -activation_bytes YOUR_BYTES -i book.aax -c:a libmp3lame -q:a 4 book.mp3
  ```
- [ ] Alternative: use **AAXtoMP3** script (handles batch conversion):
  ```bash
  # https://github.com/KrumpetPirate/AAXtoMP3
  ./AAXtoMP3 --authcode YOUR_BYTES *.aax
  ```
- [ ] Place converted files in Audiobookshelf's watched library folder
- [ ] In Audiobookshelf → scan library

### Docker option (fully automated)
- [ ] Look into `openaudible` or `audiobookshelf` with built-in Audible import support

---

## 3. DeDRM Calibre library → Calibre-Web

**Goal:** Remove DRM from Kindle/Adobe ebooks in Calibre so they can be uploaded to Calibre-Web in open formats (EPUB, MOBI, PDF).

### Setup DeDRM in Calibre (desktop)

- [ ] Download **DeDRM_tools** from: https://github.com/noDRM/DeDRM_tools/releases
- [ ] In Calibre → Preferences → Plugins → Load plugin from file → select `DeDRM_plugin.zip`
- [ ] Restart Calibre
- [ ] Configure plugin:
  - **Kindle:** add your Kindle serial number (Settings → DeDRM → eInk Kindle ebooks)
  - **Adobe:** add your Adobe ID credentials (Settings → DeDRM → Adobe Digital Editions)
- [ ] Re-add your DRM books to Calibre — DeDRM runs automatically on import
- [ ] Convert to EPUB if needed: right-click book → Convert → EPUB

### Upload to Calibre-Web

- [ ] Calibre-Web should point to your Calibre library folder (via Docker volume)
- [ ] Books added/converted in Calibre desktop appear automatically in Calibre-Web
- [ ] Or manually upload EPUB files via Calibre-Web UI → Upload

### Notes
- DeDRM only works on books you legitimately own
- Keep original DRM files as backup before removing DRM
- Calibre-Web needs read access to the Calibre library path

---

## 4. Calibre-Web bugs

### `no such table: metadata_dirtied` on book upload / metadata update

- [ ] This is a known SQLite schema migration bug in Calibre-Web
- [ ] Fix: exec into the container and run the migration manually:
  ```bash
  docker exec -it calibre-web sqlite3 /books/metadata.db \
    "CREATE TABLE IF NOT EXISTS metadata_dirtied (id INTEGER PRIMARY KEY, book INTEGER NOT NULL, UNIQUE(book));"
  ```
- [ ] Or: stop the container, delete `/config/app.db` (Calibre-Web's own DB, not the library), restart — it will rebuild
- [ ] If persists: upgrade Calibre-Web image to latest (`docker compose pull && docker compose up -d`)

### Can't add folders in Calibre-Web (Papers / collections)

- [ ] Calibre-Web does not support folder creation from the UI — folders = Calibre "shelves" or "virtual libraries"
- [ ] To organise by folder/collection use **Custom Columns** or **Bookshelves** in Calibre-Web:
  - Admin → Edit Shelves → create a shelf → add books to it
- [ ] Or manage folder structure in Calibre desktop (Calibre-Web mirrors it automatically)
- [ ] Alternative: switch to **Kavita** which has native folder/series support

---

## Quick reference

| Service | Container path | Mac mini path (example) |
|---|---|---|
| Radarr movies | `/movies` | `/Volumes/Media/Movies` |
| Downloads | `/downloads` | `/Volumes/Media/Downloads` |
| Audiobookshelf | `/audiobooks` | `/Volumes/Media/Audiobooks` |
| Calibre library | `/books` | `/Volumes/Media/Books` |
