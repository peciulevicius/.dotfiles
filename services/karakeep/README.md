# Karakeep — AI-powered bookmark manager

Replaces Linkwarden. Auto-tags bookmarks with AI, saves full-page archives, native mobile apps.

## Setup

1. Generate secrets:
   ```bash
   openssl rand -base64 36  # use once for NEXTAUTH_SECRET
   openssl rand -base64 36  # use again for MEILI_MASTER_KEY
   ```
2. Copy `.env.example` → `.env`, fill in secrets + `NEXTAUTH_URL`
3. `docker compose up -d`
4. Open http://localhost:3005 → create admin account

## Migration from Linkwarden

See `docs/HOME_SERVER_TODO.md` — task: Linkwarden → Karakeep migration.
Export HTML from Linkwarden, import in Karakeep → Settings → Import.

## Optional: AI tagging

Add `OPENAI_API_KEY` to `.env` for automatic tag suggestions.
Or use a local Ollama-compatible API via `OPENAI_BASE_URL`.

## Cloudflare Tunnel

Reuse `links.peciulevicius.com` after Linkwarden is removed.
