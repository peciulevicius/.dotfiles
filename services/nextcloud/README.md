# Nextcloud

Google Drive / Docs replacement. Files, calendar, contacts, and more.

> ⏸ **On-demand** (since 2026-09-26) — stopped by default to save RAM.
> `ondemand start nextcloud` (alias for `scripts/utils/ondemand.sh`) prints the
> URL; `ondemand stop nextcloud` when done. The weekly DB dump still runs: `backup-databases.sh` starts only
> `nextcloud_db`, dumps it and stops it again. CalDAV/CardDAV sync would need it
> always on — take it off the on-demand list first.

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
