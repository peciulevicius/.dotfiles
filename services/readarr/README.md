# Readarr

Book automation (like Sonarr for TV / Radarr for movies). Search, download, and import ebooks automatically into your Calibre library.

## Access

- Local: http://localhost:8787
- Tailscale: http://100.81.171.49:8787
- Not exposed publicly (internal tool)

## Setup

```bash
cd ~/services/readarr
docker compose up -d
```

### 1. Connect Prowlarr (indexers)

Readarr → Settings → Indexers → Add → Prowlarr
- URL: `http://prowlarr:9696`
- API Key: (copy from Prowlarr → Settings → General)

### 2. Connect Calibre (auto-import into library)

Readarr → Settings → Media Management → Use Calibre: **enabled**
- Calibre Host: `calibre`
- Calibre Port: `8080`
- Calibre Library: `/books`

This requires `calibre-web` to have `DOCKER_MODS: linuxserver/mods:universal-calibre` (already set).
Books downloaded by Readarr are added directly into Calibre — Calibre-Web picks them up automatically.

### 3. Connect Download Client (Transmission)

Readarr → Settings → Download Clients → Add → Transmission
- Host: `transmission`
- Port: `9091`
- Category: `books`

### 4. Set root folder

Readarr → Settings → Media Management → Root Folders → `/books`

### 5. Add books/authors

Search for an author or book → Add → Monitor → Search Now.
Readarr downloads, imports into Calibre, and Calibre-Web shows it immediately.

## Send to Kindle

Once books appear in Calibre-Web (books.peciulevicius.com):
- Click book → Send to Device → sends to `peciulevicius-scribe@kindle.com`
- Or enable "Auto send to Kindle" per-book

## Flow

```
Readarr (finds + downloads) → Calibre library (/Volumes/books)
  → Calibre-Web (books.peciulevicius.com) → Send to Kindle email
```
