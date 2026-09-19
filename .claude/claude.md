# Dotfiles Repository

Personal dotfiles + self-hosted services stack for macOS (primary), Arch Linux, Debian/Ubuntu.

## Structure

```
.dotfiles/
├── install.sh              # Main installer (detects OS)
├── config/                 # Configs (git, zsh, ssh, tmux, claude)
├── os/mac/install.sh       # macOS installer (Homebrew formulas + casks)
├── os/linux/               # Arch + Debian installers
├── scripts/                # Utility scripts (update, backup, cleanup, dev-check)
├── services/               # Docker Compose stacks for Mac mini homelab
│   ├── setup-services.sh   # Stage all services to ~/services/
│   └── <service>/          # docker-compose.yml + .env.example per service
└── docs/                   # Documentation
```

## Services (23 total)

Mac mini M4 runs 21 Docker services + rclone backup + cloudflared tunnel.
See `docs/SERVICES.md` for full list. Key services: Immich, Vaultwarden, Nextcloud, Jellyfin, Sonarr/Radarr, Transmission, Pi-hole.

All services accessible via: localhost, Tailscale (`100.81.171.49`), and `*.peciulevicius.com` (Cloudflare Tunnel).

## Key files

- `services/setup-services.sh` — stages docker-compose configs to `~/services/`
- `scripts/setup/setup-cloudflare-tunnel.sh` — creates tunnel + DNS records
- `services/rclone/rclone-backup.sh` — Cloudflare R2 cloud backup (cron at 5am)
- `docs/HOME_SERVER_TODO.md` — **active TODO list for the homelab. Start here.**
- `docs/HOME_SERVER.md` — full setup guide for new Mac mini
- `docs/HOME_SERVER_CHANGELOG.md` — completed work. Check before proposing
  anything — several ideas have been tried and reverted already.

## Active projects — read before proposing work

Two ongoing efforts have dedicated plans. **Read the guide before suggesting
anything in these areas**, and keep `docs/HOME_SERVER_TODO.md` in sync with it.

### De-Googling — `docs/guides/DEGOOGLE.md`

Goal: own all personal data, off Google. **~90% complete** — Immich, Nextcloud,
Vaultwarden, Syncthing, own domain and Tailscale are all done and in use.

Four gaps remain: **email, phone OS, calendar/contacts, AI.** Do not propose
re-doing the finished parts.

Standing decisions (don't relitigate without being asked):
- **Never self-host the mail server** — residential IP, blocklists, blocked
  port 25. Use a provider on the user's own domain.
- **Email: Purelymail ($10/yr).** Budget ceiling is ~€1/month, which rules out
  Fastmail (~$60/yr). Any provider must speak **native IMAP** — `kindle_sync.py`
  and Odysseus's mail integration both need it — which rules out Proton
  (Bridge-only), Tuta (no IMAP) and Zoho free (webmail only).
- **Never delete the Google account.** It breaks remaining "Sign in with Google"
  logins and frees the address for someone else to register. Stop *using* it.
- **Google Authenticator migration is the top priority** — its TOTP seeds sync
  to the account being left, so it's a lockout risk. Ente Auth or Vaultwarden.
- **No Pixel purchase for now.** Revisit ~2028–2030 when the iPhone 13 mini
  ages out. The iPhone is kept regardless — it's needed for Expo/React Native
  iOS testing.

### Self-hosted AI — `docs/guides/SELF_HOSTED_AI.md`

Goal: own the chat history, memories and RAG corpus; rent the inference.

- Target: **Odysseus** (<https://github.com/odysseus-dev/odysseus>, AGPL-3.0,
  port 7000, macOS supported). Open WebUI is the fallback.
- Phase 1 is a workspace with **cloud** backends — this is sovereignty, not
  privacy from the provider. Be precise about that distinction.
- **Models run natively via Homebrew, never in Docker.** Docker on macOS has no
  GPU passthrough, so containerised Ollama is CPU-only. This is the likely real
  cause of the earlier failed attempt recorded in the changelog.
- Hardware ceiling is ~8B quantised. 16GB unified, shared with 42 containers.
  Do not propose 30B+ models.

## Rules for this repo

- Configs must work cross-platform (macOS + Linux)
- Installers: interactive prompts, backup existing files, clear output
- Services: each gets `docker-compose.yml` + `.env.example` + README
- Don't modify git name/email without permission
