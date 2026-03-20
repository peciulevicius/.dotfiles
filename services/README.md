# Self-Hosted Services

Docker Compose stacks for running your own cloud on a Mac mini (or any Docker host).

## Services

### Core (12)

| Service | Port | Purpose |
|---------|------|---------|
| Immich | 2283 | Google Photos replacement |
| Vaultwarden | 8001 | Bitwarden server (password manager) |
| Nextcloud | 8080 | Google Drive / Docs replacement |
| Uptime Kuma | 3001 | Uptime monitoring dashboard |
| FreshRSS | 8082 | RSS reader (Google Reader replacement) |
| Syncthing | 8384 | File sync (Dropbox replacement) |
| Portainer | 9000 | Docker management UI |
| Watchtower | — | Automatic Docker image updates |
| Homarr | 7575 | Home dashboard |
| Paperless-ngx | 8000 | Document scanner and organiser |
| Calibre-Web | 8083 | Ebook library server |
| Rclone | — | Cloud backup (B2/S3) |

### Utilities (6)

| Service | Port | Purpose |
|---------|------|---------|
| Pi-hole | 8053, 53 | Network-wide ad blocker + local DNS |
| Stirling PDF | 8084 | PDF manipulation tool |
| IT-Tools | 8085 | Developer utilities collection |
| Audiobookshelf | 13378 | Audiobook and podcast server |
| Linkwarden | 3005 | Bookmark manager with archiving |
| Mealie | 9925 | Recipe manager and meal planner |

### Media (5)

| Service | Port | Purpose |
|---------|------|---------|
| Jellyfin | 8096 | Media server (movies, TV) |
| Sonarr | 8989 | TV show management |
| Radarr | 7878 | Movie management |
| Prowlarr | 9696 | Indexer manager |
| Transmission | 9091 | BitTorrent client |

## Quick Start

```bash
# Stage all services to ~/services/
./services/setup-services.sh

# Or stage a single service
./services/setup-services.sh immich

# Dry run (shows what would happen)
./services/setup-services.sh --dry-run
```

Then edit the `.env` files in `~/services/<service>/` before running `docker compose up -d`.

## Documentation

Full guides in `docs/`:
- [SERVICES.md](../docs/SERVICES.md) — Setup walkthrough
- [HOME_SERVER.md](../docs/HOME_SERVER.md) — Backup strategy
- [DEGOOGLE.md](../docs/guides/DEGOOGLE.md) — Privacy migration checklist
