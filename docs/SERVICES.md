# Self-Hosted Services

Run your own cloud on a Mac mini (or any Docker host). 13 services covering photos, passwords, files, documents, and more.

## Service Overview

| Service | Port | Replaces | Status |
|---------|------|---------|--------|
| [Immich](#immich) | 2283 | Google Photos | Essential |
| [Vaultwarden](#vaultwarden) | 8001 | Bitwarden Cloud | Essential |
| [Nextcloud](#nextcloud) | 8080 | Google Drive | Optional |
| [Uptime Kuma](#uptime-kuma) | 3001 | StatusCake | Recommended |
| [FreshRSS](#freshrss) | 8082 | Feedly | Optional |
| [Ollama](#ollama) | 11434 | OpenAI API | Optional |
| [Syncthing](#syncthing) | 8384 | Dropbox | Recommended |
| [Portainer](#portainer) | 9000 | Docker Desktop | Recommended |
| [Watchtower](#watchtower) | — | Manual updates | Recommended |
| [Homarr](#homarr) | 7575 | — | Optional |
| [Paperless-ngx](#paperless-ngx) | 8000 | Paper filing | Optional |
| [Calibre-Web](#calibre-web) | 8083 | Kindle Cloud | Optional |
| [Rclone](#rclone) | — | Google Drive | Essential |

## Prerequisites

- macOS with Docker Desktop or OrbStack installed
- 16GB+ RAM recommended (varies by active services)
- Tailscale installed (for remote access)

## Quick Start

```bash
# Clone or pull dotfiles
cd ~/.dotfiles

# Stage all services to ~/docker/
./services/setup-services.sh

# Or stage one at a time
./services/setup-services.sh immich
```

Then for each service:

```bash
cd ~/docker/<service>
nano .env          # fill in passwords/settings
docker compose up -d
```

## Service Details

### Immich

Google Photos replacement with mobile backup, face recognition, and shared albums.

```bash
cd ~/docker/immich
nano .env          # set DB_PASSWORD, UPLOAD_LOCATION
docker compose up -d
# Open: http://localhost:2283
```

**First run:** Create admin account, then install Immich app on iOS/Android.

### Vaultwarden

Lightweight Bitwarden server. Use with the official Bitwarden browser extension.

```bash
openssl rand -base64 48  # generate admin token
cd ~/docker/vaultwarden
nano .env
docker compose up -d
# Open: http://localhost:8001
```

### Nextcloud

Google Drive, Calendar, and Contacts replacement.

```bash
cd ~/docker/nextcloud
nano .env
docker compose up -d
# Open: http://localhost:8080 (takes ~60s on first start)
```

### Uptime Kuma

Monitor all your services and get notified when something goes down.

```bash
cd ~/docker/uptime-kuma
docker compose up -d
# Open: http://localhost:3001
```

### FreshRSS

RSS reader replacing Feedly/Google Reader.

```bash
cd ~/docker/freshrss
nano .env  # set timezone
docker compose up -d
# Open: http://localhost:8082
```

### Ollama

Run LLMs locally. See [docs/NOTES.md](NOTES.md) for integration with Obsidian.

```bash
cd ~/docker/ollama
docker compose up -d
docker exec ollama ollama pull llama3.2:3b
```

### Syncthing

Peer-to-peer file sync without a cloud intermediary. Great for Obsidian vault sync.

```bash
cd ~/docker/syncthing
nano .env  # set SYNC_DIR
docker compose up -d
# Open: http://localhost:8384
```

### Portainer

Docker management UI — view containers, restart services, view logs.

```bash
cd ~/docker/portainer
docker compose up -d
# Open: http://localhost:9000
```

### Watchtower

Automatically keeps containers updated.

```bash
cd ~/docker/watchtower
nano .env  # set timezone
docker compose up -d
```

### Homarr

Dashboard showing all services in one place.

```bash
cd ~/docker/homarr
docker compose up -d
# Open: http://localhost:7575
```

### Paperless-ngx

Document scanner and organiser with OCR.

```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
cd ~/docker/paperless-ngx
nano .env
docker compose up -d
# Open: http://localhost:8000
```

### Calibre-Web

Ebook library server with mobile OPDS support.

```bash
cd ~/docker/calibre-web
nano .env  # set BOOKS_DIR to your Calibre library
docker compose up -d
# Open: http://localhost:8083 (admin/admin123 — change immediately)
```

### Rclone

Cloud backup to Backblaze B2 or any S3-compatible storage.

```bash
brew install rclone
rclone config  # set up B2 remote
cd ~/.dotfiles/services/rclone
nano .env
./rclone-backup.sh --dry-run  # test first
./rclone-backup.sh            # live backup
```

## Remote Access

All services are accessible via Tailscale — install on your Mac mini and connect from anywhere with `http://100.x.x.x:<port>`.

For public access (e.g. Immich from the internet), use a reverse proxy with HTTPS. Caddy is recommended:

```bash
# Example Caddyfile
photos.yourdomain.com {
    reverse_proxy localhost:2283
}
```

## Backup Strategy

See [BACKUPS.md](BACKUPS.md) for the full 3-2-1 backup strategy.

## Troubleshooting

**Container won't start:**
```bash
docker compose logs -f <service>
```

**Port already in use:**
```bash
lsof -i :<port>
```

**Out of disk space:**
```bash
docker system df
docker system prune
```
