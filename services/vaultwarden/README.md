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

`http://localhost:8001/admin` — use ADMIN_TOKEN to access. `.env` holds only its
Argon2id hash, single-quoted so Compose keeps the `$` signs literal; the plain
token lives in Vaultwarden itself ("Vaultwarden admin token").

**Rotating the token:** `scripts/utils/vaultwarden-rotate-admin-token.sh`. You
type the token at vaultwarden's own hidden `hash` prompt inside the running
container (`docker exec -it` under `script`, which supplies the pty the prompt
needs: piping into `docker exec -i` panics with "No such device or address").
Only the hash is written to `.env` (backed up first), then `docker compose up -d`.
Never pass the token as an argument to `docker run`/`exec`: on 2026-09-21 a
throwaway `vaultwarden hash` container kept the plain token in its config,
readable via `docker inspect`, which is why it was rotated on 2026-10-02.
