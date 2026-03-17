# Uptime Kuma

Self-hosted uptime monitoring with status pages and notifications.

## Ports

| Port | Service |
|------|---------|
| 3001 | Web UI |

## Quick Start

```bash
docker compose up -d
```

Open `http://localhost:3001` to set up your admin account on first visit.

## Monitors to Add

- Immich: `http://localhost:2283`
- Vaultwarden: `http://localhost:8001`
- Nextcloud: `http://localhost:8080`
- Syncthing: `http://localhost:8384`
