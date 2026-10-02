# Vaultwarden

Lightweight Bitwarden server. Use with the official Bitwarden browser extension and mobile app.

## Ports

| Port | Service |
|------|---------|
| 8001 | Web UI + API |

## Quick Start

```bash
# 1. Generate a long random admin token in Vaultwarden/Bitwarden and keep it there.
# 2. Hash it at vaultwarden's own hidden prompt (typed, never on a command line;
#    --rm so the throwaway container is gone afterwards):
docker run --rm -it vaultwarden/server:1.37.3 /vaultwarden hash
# 3. Put ONLY the printed hash in .env, single-quoted: ADMIN_TOKEN='$argon2id$...'
cp .env.example .env
nano .env  # paste the hash, set DOMAIN

docker compose up -d
```

Never put the plain token in `.env` — it would sit in the container
environment, readable through `docker inspect`.

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
