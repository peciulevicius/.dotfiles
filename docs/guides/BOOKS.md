# Books & Reading

Ebook library with Calibre-Web, Kindle highlight import, and note-taking workflow.

## Stack

| Tool | Role |
|------|------|
| Calibre | Desktop library manager |
| Calibre-Web | Self-hosted library server |
| Kindle | E-reader |
| Readwise (optional) | Highlight sync service |
| Obsidian | Book notes destination |

## Calibre Library Setup

1. Install Calibre: `brew install --cask calibre` (included in macOS installer)
2. Create library at a consistent path (e.g. `~/Books/` or `/Volumes/SSD/Books/`)
3. Import ebooks via drag-and-drop or `File → Add Books`

## Calibre-Web Setup

Serve your library from the Mac mini:

```bash
cd ~/docker/calibre-web
nano .env  # set BOOKS_DIR to your Calibre library path

docker compose up -d
# Open: http://localhost:8083
# Default: admin / admin123 — change immediately
```

**Point to library:** Settings → Edit Basic Configuration → Location of Calibre Database → `/books`

## Mobile Reading

Enable OPDS in Calibre-Web (Admin → Basic Configuration → Enable OPDS catalog).

| App | Platform | Connection |
|-----|---------|-----------|
| KyBook 3 | iOS | OPDS: `http://macmini.local:8083/opds` |
| Moon+ Reader | Android | OPDS: `http://macmini.local:8083/opds` |
| Kindle app | iOS/Android | Sideload via Calibre conversion |

## Kindle Highlights Pipeline

### Option 1: Readwise (paid, ~$8/month)

Readwise automatically syncs highlights from Kindle, Pocket, and other sources, then exports to Obsidian.

1. Sign up at readwise.io
2. Connect Kindle account
3. Install Readwise Official plugin in Obsidian
4. Highlights sync to `800 Kindle Highlights/`

### Option 2: Manual Export (free)

```bash
# Kindle stores highlights in My Clippings.txt
# Mount Kindle or find file at:
# /Volumes/Kindle/documents/My Clippings.txt

# Parse with klp (Kindle clippings parser)
pip3 install kindle-clippings

# Export to Markdown
kindle-clippings /Volumes/Kindle/documents/My\ Clippings.txt \
  --output ~/obsidian-vault/800\ Kindle\ Highlights/
```

### Option 3: KOReader (open-source firmware)

KOReader can export highlights directly to a folder synced by Syncthing.

## Book Note Template

```markdown
---
title: "Book Title"
author: Author Name
rating: 4/5
date_read: 2026-01-01
tags: [books, topic]
---

# Book Title

## Summary

One paragraph summary.

## Key Ideas

- Idea 1
- Idea 2

## Highlights

<!-- paste Kindle highlights here -->

## My Notes

<!-- own thoughts and connections -->
```

Save as `~/obsidian-vault/500 Templates/Book Note.md`.

## DRM Removal (for personal use)

To read your legally purchased ebooks on all your devices, you can remove DRM using the DeDRM plugin for Calibre. This is legal for personal use in many jurisdictions — check local laws.

## Sending to Kindle

Calibre can convert and send ebooks to Kindle via email:
1. Preferences → Sharing Books by Email → add Kindle email
2. Right-click book → Send by email to Kindle
