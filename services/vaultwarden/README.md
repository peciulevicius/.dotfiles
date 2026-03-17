# Vaultwarden

Lightweight Bitwarden server. Use with the official Bitwarden browser extension and mobile app.

## Ports

| Port | Service |
|------|---------|
| 8001 | Web UI + API |

## Quick Start

```bash
# Generate admin token
openssl rand -base64 48

cp .env.example .env
nano .env  # paste token, set DOMAIN

docker compose up -d
```

## Connect Bitwarden Clients

In Bitwarden app settings, set **Server URL** to `http://macmini.local:8001` (or your Tailscale IP).

## Admin Panel

`http://localhost:8001/admin` — use ADMIN_TOKEN to access.
