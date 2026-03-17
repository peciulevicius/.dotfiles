# Nextcloud

Google Drive / Docs replacement. Files, calendar, contacts, and more.

## Ports

| Port | Service |
|------|---------|
| 8080 | Web UI |

## Quick Start

```bash
cp .env.example .env
nano .env  # set passwords

docker compose up -d
# First start takes ~60 seconds
```

Access at `http://localhost:8080`. Default admin: set via `ADMIN_USER`/`ADMIN_PASSWORD` in `.env`.

## Sync Clients

Install Nextcloud desktop sync client from nextcloud.com/install.
