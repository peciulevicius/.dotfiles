# Self-Hosted Services

Docker Compose stacks for running your own cloud on a Mac mini (or any Docker host).

## Services

| Service | Port | Purpose |
|---------|------|---------|
| Immich | 2283 | Google Photos replacement |
| Vaultwarden | 8001 | Bitwarden server (password manager) |
| Nextcloud | 8080 | Google Drive / Docs replacement |
| Uptime Kuma | 3001 | Uptime monitoring dashboard |
| FreshRSS | 8082 | RSS reader (Google Reader replacement) |
| Ollama | 11434 | Local LLM inference |
| Syncthing | 8384 | File sync (Dropbox replacement) |
| Portainer | 9000 | Docker management UI |
| Watchtower | — | Automatic Docker image updates |
| Homarr | 7575 | Home dashboard |
| Paperless-ngx | 8000 | Document scanner and organiser |
| Calibre-Web | 8083 | Ebook library server |
| Rclone | — | Cloud backup (B2/S3) |

## Quick Start

```bash
# Stage all services to ~/docker/
./services/setup-services.sh

# Or stage a single service
./services/setup-services.sh immich

# Dry run (shows what would happen)
./services/setup-services.sh --dry-run
```

Then edit the `.env` files in `~/docker/<service>/` before running `docker compose up -d`.

## Documentation

Full guides in `docs/`:
- [SERVICES.md](../docs/SERVICES.md) — Setup walkthrough
- [BACKUPS.md](../docs/BACKUPS.md) — Backup strategy
- [DEGOOGLE.md](../docs/DEGOOGLE.md) — Privacy migration checklist
