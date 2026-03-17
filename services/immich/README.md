# Immich

Google Photos replacement — self-hosted photo/video library with mobile backup.

## Ports

| Port | Service |
|------|---------|
| 2283 | Web UI + API |

## Quick Start

```bash
# Copy and edit env
cp .env.example .env
nano .env  # set DB_PASSWORD and UPLOAD_LOCATION

# Start
docker compose up -d

# Check logs
docker compose logs -f immich-server
```

## Mobile App

Install Immich from App Store / Google Play. Set server URL to:
- Local: `http://macmini.local:2283`
- Remote: `https://photos.yourdomain.com` (needs Tailscale or reverse proxy)

## Backup

Immich database backup — add to crontab:
```bash
docker exec immich_postgres pg_dumpall -U immich > ~/backups/immich-db-$(date +%Y%m%d).sql
```

See [BACKUPS.md](../../docs/BACKUPS.md) for full 3-2-1 strategy.

## Notes

- Watchtower is disabled for Immich containers (breaking changes between releases)
- Update manually: edit `IMMICH_VERSION` in `.env`, then `docker compose pull && docker compose up -d`
- Storage grows fast — monitor with `docker system df`
