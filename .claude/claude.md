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
- `services/rclone/rclone-backup.sh` — B2 cloud backup (cron at 5am)
- `docs/HOME_SERVER_TODO.md` — active TODO list for homelab
- `docs/HOME_SERVER.md` — full setup guide for new Mac mini

## Rules for this repo

- Configs must work cross-platform (macOS + Linux)
- Installers: interactive prompts, backup existing files, clear output
- Services: each gets `docker-compose.yml` + `.env.example` + README
- Don't modify git name/email without permission
