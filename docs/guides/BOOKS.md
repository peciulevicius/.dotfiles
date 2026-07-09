# Books & Audio Automation

Automated ebook and audiobook acquisition: search in LazyLibrarian → click "Wanted" → downloads automatically → EPUBs land in Calibre, audiobooks land in Audiobookshelf.

## Stack

| Tool | Role |
|------|------|
| LazyLibrarian | Book/audiobook automation (search, snatch, post-process) |
| Prowlarr | Indexer manager — provides Torznab endpoints to LazyLibrarian |
| Transmission | BitTorrent download client |
| Calibre | Library manager (runs as content server on port 8081) |
| Calibre-Web | Self-hosted library server (books.peciulevicius.com) |
| Audiobookshelf | Audiobook server (listen.peciulevicius.com) |

## How It Works

```
LazyLibrarian → search Prowlarr Torznab indexers
             → snatch torrent → Transmission downloads
             → PostProcessor runs every 10 min
             → EPUB → /books/ (Calibre auto-imports via content server)
             → MP3/M4B → ~/services/audiobookshelf/data/audiobooks/ (Audiobookshelf watches this)
```

## Indexers (via Prowlarr)

LazyLibrarian connects to Prowlarr's Torznab proxy. Prowlarr must be running with these indexers:

| Prowlarr ID | Indexer | Torznab URL |
|-------------|---------|-------------|
| 2 | The Pirate Bay | `http://prowlarr:9696/2` |
| 4 | Knaben | `http://prowlarr:9696/4` |
| 5 | EBookBay | `http://prowlarr:9696/5` |
| 6 | TorrentDownload | `http://prowlarr:9696/6` |

LazyLibrarian appends `/api` to these URLs automatically.

## LazyLibrarian Config (critical settings)

**Torznab providers** — in LazyLibrarian config, each `[Torznab_N]` section needs:
```ini
[Torznab_0]
dispname = EBookBay
enabled = True          ← CRITICAL: defaults to False, must be explicit
host = http://prowlarr:9696/5
api = <prowlarr_api_key>
generalsearch = search
bookcat = 7020,8000,8010
dltypes = A,E
```

**Ebook content filter** — `reject_words` defaults to `audiobook, mp3`. This causes ebook torrents containing spam files (e.g. `free audiobook version.txt`) to be rejected. Fix:
```ini
[GENERAL]
reject_words = mp3
```

**Transmission** — configured under `[TRANSMISSION]`:
```ini
[TRANSMISSION]
transmission_host = transmission
transmission_base = /transmission/
transmission_port = 9091
transmission_user = admin
transmission_pass = <password>
```

**Calibre content server** — books are imported via the running Calibre container:
```ini
[CALIBRE]
calibre_use_server = True
calibre_server = http://calibre:8081
```

## Setting Up from Scratch

### 1. Start containers

```bash
cd ~/services/lazylibrarian && docker compose up -d
```

LazyLibrarian is on port 5299 (Tailscale-only: `http://100.81.171.49:5299`).

### 2. Add Torznab providers via web UI

Go to **Config → Providers → Torznab** and add each indexer:
- Display Name: `EBookBay` / Host: `http://prowlarr:9696/5` / API: `<prowlarr_api_key>`
- Display Name: `The Pirate Bay` / Host: `http://prowlarr:9696/2` / API: `<prowlarr_api_key>`
- Display Name: `Knaben` / Host: `http://prowlarr:9696/4` / API: `<prowlarr_api_key>`
- Display Name: `TorrentDownload` / Host: `http://prowlarr:9696/6` / API: `<prowlarr_api_key>`

Check **Enabled** on each one. Set **Download Types** to `A,E`.

Get the Prowlarr API key from `http://100.81.171.49:9696` → Settings → General → API Key.

### 3. Add Transmission

**Config → Download → Transmission:**
- Host: `transmission`
- Port: `9091`
- Base URL: `/transmission/`
- Username/Password: from `~/services/transmission/.env`

Enable **"Use for Torrents"** checkbox.

### 4. Fix reject_words

**Config → Processing → Reject Words** — remove `audiobook` from the list, keep `mp3` only.

This prevents spam files inside ebook torrents (e.g. `free audiobook version.txt`) from causing the whole download to be rejected.

### 5. Set Calibre content server

**Config → Calibre:**
- Enable **Use Calibre Content Server**
- Server URL: `http://calibre:8081`

### 6. Verify directory paths

**Config → General:**
- Ebook dir: `/books`
- Audio dir: `/audiobooks`
- Download dir: `/downloads`

These map to:
| Container path | Mac mini path |
|----------------|--------------|
| `/books` | `/Volumes/T7/calibre-books` (shared with Calibre) |
| `/audiobooks` | `~/services/audiobookshelf/data/audiobooks/` |
| `/downloads` | `/Volumes/T7/media/downloads` |

### 7. Add an author and search

1. Search for an author → Add to library
2. LazyLibrarian imports all their books/audio as "Skipped"
3. Click **Wanted** on a book (ebook) or audiobook → it searches and downloads automatically
4. PostProcessor runs every 10 min and moves completed files to the right place

## Day-to-Day Usage

1. Go to `http://100.81.171.49:5299`
2. Search for author → Add → find books
3. Click **Wanted** button next to any book or audiobook
4. Wait ~15 min for download + processing
5. Ebook appears in Calibre-Web / Audiobookshelf automatically

## Known Gotchas

### Torznab `enabled` defaults to False
**Symptom:** All searches return empty. Searches complete with "0 results" for every provider.
**Cause:** `configdefs.py` sets `ConfigBool('', "ENABLED", False)` — every Torznab section defaults to disabled.
**Fix:** Must explicitly set `enabled = True` in each `[Torznab_N]` section, or tick **Enabled** in the web UI.
**After restart:** If LazyLibrarian rewrites config and drops the `enabled` field, use the web UI to re-enable providers and save. Alternatively, run `config_update` POST via script (see `scripts/lazylibrarian-config-fix.sh` if it exists).

### EBookBay rate limiting (429)
**Symptom:** EBookBay returns `429 Too Many Requests`, gets blocked for 30 seconds.
**Impact:** Minor — other 3 indexers still search fine. EBookBay just times out.
**Fix:** No fix needed — LazyLibrarian continues with other providers.

### "audiobook" in banword list rejects ebook torrents
**Symptom:** PostProcessor log shows: `free audiobook version.txt contains audiobook. Rejecting download`.
**Cause:** Some ebook torrents (especially from TPB) contain spam files named `*audiobook*.txt`. Default `reject_words = audiobook, mp3` matches them.
**Fix:** Set `reject_words = mp3` (remove "audiobook"). Done in Config → Processing.

### Author status "Paused" blocks searching
**Symptom:** Clicking "Wanted" does nothing. No search triggered.
**Cause:** Authors can be set to "Paused" status — this blocks all processing.
**Fix:** In LazyLibrarian → Authors → find author → set Status to "Active". Or via SQLite:
```bash
sqlite3 ~/services/lazylibrarian/data/lazylibrarian.db \
  "UPDATE authors SET Status='Active' WHERE AuthorName='Author Name';"
```

### Calibre content server must be running for import
**Symptom:** PostProcessor completes but book doesn't appear in Calibre.
**Cause:** LazyLibrarian imports via `calibredb --with-library=http://calibre:8081` — needs the Calibre container running.
**Fix:** Ensure `calibre` container is up: `docker compose up -d` in `~/services/calibre/`.

### Manual Calibre import (if PostProcessor fails)
Copy file to the shared `/books` volume then import via Calibre container:
```bash
# Copy EPUB to /books volume (accessible as /Volumes/T7/calibre-books/)
cp book.epub /Volumes/T7/calibre-books/

# Import via calibredb inside the calibre container
docker exec calibre calibredb add /books/book.epub --with-library="http://localhost:8081"
```

## Volume Paths

| What | Container | Mac mini |
|------|-----------|---------|
| Ebooks | `/books` | `/Volumes/T7/calibre-books` |
| Audiobooks | `/audiobooks` | `~/services/audiobookshelf/data/audiobooks` |
| Downloads | `/downloads` | `/Volumes/T7/media/downloads` |
| LazyLibrarian config | `/config` | `~/services/lazylibrarian/data` |
| SQLite database | `/config/lazylibrarian.db` | `~/services/lazylibrarian/data/lazylibrarian.db` |

## Audiobook File Structure

Audiobookshelf expects books organised by author:
```
audiobooks/
  Pierce Brown/
    Red Rising/
      Red Rising (Unabridged) Part 1 Pierce Brown.mp3
      Red Rising (Unabridged) Part 2 Pierce Brown.mp3
```

LazyLibrarian PostProcessor creates this structure automatically using the `$Author/$Title` template.

## Device Access

| App | Platform | URL |
|-----|----------|-----|
| Audiobookshelf | iOS/Android/Web | https://listen.peciulevicius.com |
| Calibre-Web | Browser | https://books.peciulevicius.com |
| Calibre-Web OPDS | Kobo/KyBook | https://books.peciulevicius.com/opds |
| Kindle | iOS/Hardware | Send via Calibre-Web → Send to Device |
