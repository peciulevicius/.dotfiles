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

Annotated replacement list: **`docs/guides/DEGOOGLE_ALTERNATIVES.md`**. When the
user is about to replace any individual Google service, **surface that file and
its recommendation for that service** — it records what's already running, what
was ruled out, and why, so popular-but-wrong picks don't get re-suggested.

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
- **Nextcloud Mail is an IMAP client, not a mail server.** It cannot host email.
  Nextcloud covers Drive/Calendar/Contacts/Docs/Notes/Meet — email needs a provider.
- **Proton and Tuta are ruled out** despite being the popular r/degoogle picks:
  both exceed the ~€1/mo budget, and Proton is Bridge-only while Tuta has no
  IMAP at all. mailbox.org's €1 tier has no custom domain; Posteo never supports
  custom domains by design.
- **Never delete the Google account.** It breaks remaining "Sign in with Google"
  logins and frees the address for someone else to register. Stop *using* it.
- **Google Authenticator migration is the top priority** — its TOTP seeds sync
  to the account being left, so it's a lockout risk. Ente Auth or Vaultwarden.
- **No Pixel purchase for now.** Revisit ~2028–2030 when the iPhone 13 mini
  ages out. The iPhone is kept regardless — it's needed for Expo/React Native
  iOS testing.

### Notes / PKM — `docs/guides/NOTES.md`

Obsidian vault + Syncthing + `pkm/kindle_sync.py` all exist but go largely
unused. **Diagnosis is capture friction, not tool choice** — do not suggest
replacing Obsidian. Fix: self-hosted sync, a ≤2-tap iPhone capture Shortcut, the
Obsidian Web Clipper, then 30 days of capture-only with no organising.

- **No subscriptions and no Apple-ecosystem dependency.** The user cancelled
  iCloud; the NAS and Mac mini exist to avoid monthly fees, and a future
  GrapheneOS phone must work. **Never propose iCloud or Obsidian Sync.**
  Sync target is **CouchDB + Self-hosted LiveSync**, self-hosted on the Mac mini.

- `pkm/kindle_sync.py` pulls Kindle Scribe notebook exports out of email over
  IMAP into the vault, **hourly** (Amazon's share links expire after 7 days).
  It runs on the **Mac mini**; `pkm/config.py` is gitignored and not in the repo.
- Scribe's only provider-neutral export route is **email** — its Drive/OneDrive
  options are 2025+ models only and are the services being left.

### Books + Kindle — `docs/guides/BOOKS.md`

**The Kindle Scribe is a target device for this project, not just phone and PC.**
Goal: read self-hosted Calibre-Web EPUBs on it without Amazon in the middle.

- **LazyLibrarian** acquires both ebooks and audiobooks; **Calibre-Web** and
  **Audiobookshelf** serve them. `readarr` may be a stale container — verify.
- Stock Kindle **cannot read EPUB**; Send to Kindle converts server-side at
  Amazon. **KOReader reads EPUB natively** via Calibre-Web's OPDS feed — this is
  the reason to jailbreak.
- **Jailbreak decided: yes.** Blocker is **software availability, not warranty** —
  Vera's Scribe support reads as pending. EU statutory warranty is 2 years
  (~Oct 2027) and the jailbreak is reversible, so warranty is a minor factor.
  Freeze firmware at **5.19.6** now — updating past it could strand the device.
- **Wi-Fi stays on after jailbreaking** (`renametobin` blocks OTA updates), and
  Wi-Fi is *required* — the Searchable PDF export routes through Amazon to email,
  which feeds `kindle_sync.py`. Don't recommend permanent airplane mode.
- **OPDS is pull, not push** — books don't auto-transfer. A `scp`-over-SSH push
  script is possible later but isn't built.
- **Keep Amazon's stock software for handwriting.** KOReader's Scribe stylus
  support was merged then reverted as unstable. Jailbreak is additive: KOReader
  for reading, stock Kindle for notes + OCR export into Obsidian.

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

### Octopus Deploy — ruled out, `docs/guides/OCTOPUS_DEPLOY.md`

Wanted as a day-job-mirroring .NET practice rig, **not** as a deploy path for
Cloudflare Worker or static-site projects (`wrangler versions` already covers
promote/rollback there). **Ruled out on the Mac mini 2026-09-19 on measured RAM**,
not on principle: Octopus's SQL Server dependency needs ~3–4GB, and the host was
already swapping 3GB of 4GB with only ~4.1GiB of Docker VM headroom left.
Revisit only if it gets its own machine. Don't re-research it — the licence
check, compose sketch, exposure rules and the unrecoverable master-key step are
all in that guide.

## Rules for this repo

- Configs must work cross-platform (macOS + Linux)
- Installers: interactive prompts, backup existing files, clear output
- Services: each gets `docker-compose.yml` + `.env.example` + README
- Don't modify git name/email without permission
