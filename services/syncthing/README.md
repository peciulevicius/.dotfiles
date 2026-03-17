# Syncthing

Peer-to-peer file sync. Replaces Dropbox for documents and notes.

## Ports

| Port | Service |
|------|---------|
| 8384 | Web UI |
| 22000 | Sync protocol |
| 21027 | Local discovery |

## Quick Start

```bash
cp .env.example .env
docker compose up -d
```

Open `http://localhost:8384` — first visit has no password (add one in Settings → GUI).

## Common Uses

- Sync Obsidian vault between Mac, iPhone, and Mac mini
- Sync project files without a cloud intermediary
- Keep config backups in sync

## Mobile

Install Syncthing from iOS/Android app stores.
