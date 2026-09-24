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
- `docs/HOME_SERVER.md` — full setup + disaster-recovery guide for a new Mac
  mini (rewritten 2026-09-24 for the NAS architecture)
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
  **Audiobookshelf** serve them. Readarr was **removed 2026-09-19** — it had
  0 authors, 0 books and 0 grab history, and was archived upstream.
- Stock Kindle **cannot read EPUB**; Send to Kindle converts server-side at
  Amazon. **KOReader reads EPUB natively** via Calibre-Web's OPDS feed — this is
  the reason to jailbreak.
- **Jailbroken 2026-09-20 with Vera**, on firmware 5.19.6 — earlier than the
  guide predicted. `;kpm` is the on-device package manager. Never let the device
  take a firmware update; that removes the jailbreak.
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
- Hardware ceiling is ~8B quantised. 16GB unified, shared with 38 containers.
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

- **Documentation is part of the change, not a follow-up.** Anything a future
  reader — Džiugas in six months, or someone else entirely — would need to
  understand this setup goes in `docs/`, in the same commit as the change:
  what a thing does, how to set it up from scratch, how it works underneath,
  and *why* it was built that way. Record the reasoning and the failure modes,
  not just the commands. A change nobody can reconstruct later is unfinished
  work. Put facts in `HOME_SERVER_REFERENCE.md`, decisions in the topic guide,
  outstanding work in `HOME_SERVER_TODO.md`, finished work in
  `HOME_SERVER_CHANGELOG.md`, and index it from `START_HERE.md`.
- **Never commit a secret.** This repo is **public** — no password, token or
  webhook URL may ever land in it, not even in documentation. Real values belong
  in `~/services/<svc>/.env` (gitignored), `~/.config/homelab/` or Vaultwarden.
  Sweep the staged diff before every commit. A **gitleaks pre-commit hook**
  (`.githooks/pre-commit`, rules in `.gitleaks.toml`) blocks commits with
  secrets — enabled per clone via `git config core.hooksPath .githooks`
  (`install.sh` does it). Never bypass it with `--no-verify`; if it flags a
  false positive, add the fingerprint to `.gitleaksignore`. CI
  (`.github/workflows/checks.yml`) re-runs gitleaks on every push as a
  backstop for clones without the hook, plus `shellcheck -S error` and a
  strict `mkdocs build` — a red check on a push is a real problem, fix it.
- **Use the project skills** in `.claude/skills/` — they encode steps that
  were missed repeatedly:
  - `homelab-service` — any add/remove/change of a service (staging, Glance,
    tunnel, backups, credentials, docs)
  - `credential-rotation` — any password/key/email change; checks every
    service that keeps its own copy
  - `homelab-audit` — health/security audit; runs
    `scripts/utils/homelab-audit.sh` (also cron'd weekly → Discord)

- **Adding or removing a service? Update the homepage too.** `services/glance/glance.yml`
  drives `home.peciulevicius.com` — add a monitor (with `check-url`) *and* a
  bookmark link, or remove both. Glance joins each service's Docker network to
  reach its `check-url`, so also add the network to `services/glance/docker-compose.yml`.
  A service that isn't on the homepage effectively doesn't exist.
- **Push after every commit.** The repo is synced across machines via
  `scripts/sync.sh`; unpushed commits mean the others run stale config.
  ⚠️ The repo is **public** — sweep the staged diff for secrets first.
- ⚠️ **Editing `services/<svc>/docker-compose.yml` or a script under it does
  NOT change what's running.** `setup-services.sh` **copies** these files into
  `~/services/<svc>/` — no symlink — so a repo edit sits inert until re-staged.
  `.env` is the one exception (only created if missing, never overwritten, so
  it's safe to re-run the installer without clobbering live secrets). Caught
  2026-09-21: an `rclone-backup.sh` change went untested for an hour because
  the live copy never picked it up. After editing anything under `services/`
  that isn't `.env`, either re-copy that one file or re-run
  `services/setup-services.sh`, then verify with:
  ```bash
  diff services/<svc>/docker-compose.yml ~/services/<svc>/docker-compose.yml
  ```

- Configs must work cross-platform (macOS + Linux)
- Installers: interactive prompts, backup existing files, clear output
- Services: each gets `docker-compose.yml` + `.env.example` + README
- Don't modify git name/email without permission
