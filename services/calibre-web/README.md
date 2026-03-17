# Calibre-Web

Browse and read your Calibre ebook library from a browser or phone.

## Ports

| Port | Service |
|------|---------|
| 8083 | Web UI |

## Quick Start

```bash
cp .env.example .env
nano .env  # set BOOKS_DIR to your Calibre library path

docker compose up -d
```

Open `http://localhost:8083`. Default credentials: `admin` / `admin123` (change immediately).

Point Calibre-Web to your `metadata.db` file at `/books/metadata.db` in the UI setup.

## Kindle Highlights Pipeline

See [docs/BOOKS.md](../../docs/BOOKS.md) for the full workflow of syncing Kindle highlights into Obsidian.

## Mobile Reading

Enable OPDS catalog in Calibre-Web (Admin → Basic Configuration → Enable OPDS).
Use KyBook 3 (iOS) or Moon+ Reader (Android) to connect.
