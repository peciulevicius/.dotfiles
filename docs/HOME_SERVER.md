# Mac mini Homelab — Setup & Recovery Guide

> **Rewritten 2026-09-24 for the NAS-primary architecture.** The previous
> version described the pre-2026-08-04 setup where a T7 SSD was primary
> storage; it's preserved in git history. Facts here come from
> [HOME_SERVER_REFERENCE.md](HOME_SERVER_REFERENCE.md), [NAS.md](NAS.md),
> [SERVICES.md](SERVICES.md) and the scripts themselves — when this guide and
> one of those disagree, **those win**, and this file should be fixed.

This is the from-scratch guide: set up a new Mac mini and bring the whole
homelab back, or understand how it fits together. For day-to-day facts (RAM,
paths, gotchas) use the reference doc; for what's outstanding, the TODO.

---

## 1. What it is

```
                    Internet
                       │
          ┌────────────┴────────────┐
   Cloudflare Tunnel            Tailscale (private)
   *.peciulevicius.com          100.81.171.49 + phone/laptop
   (outbound-only, no           (Tailscale-only services,
    open ports, free plan)       SSH, large uploads)
          └────────────┬────────────┘
                       │
              Mac mini M4 (16GB)  ── computes
              Docker Desktop, ~38 containers
              databases + configs on internal SSD
                       │  SMB (mDNS: DH4300PLUS-DP.local)
              UGREEN DH4300 Plus  ── stores
              RAID 5, ~11TiB: media, immich, audiobooks, books, unsorted
                       │
              Cloudflare R2  ── offsite (nightly rclone)
```

| Layer | Role | Key rule |
|---|---|---|
| **Mac mini** | Runs every service in Docker, native Ollama for local AI | Databases live on the **internal SSD**, never on SMB — they corrupt over network mounts |
| **NAS** | All bulk data, mounted at `/Volumes/<share>` | Address it by **`DH4300PLUS-DP.local`**, never an IP — its IP drifted three times |
| **Cloudflare Tunnel** | Public HTTPS for services that should be public | No port forwarding; outbound connection, so a changing home IP doesn't matter (no DDNS needed). **100MB upload cap** on the free plan |
| **Tailscale** | Private access from anywhere | Admin/automation services (the *arr stack, Portainer, Syncthing, Transmission) are Tailscale-only |
| **R2** | Offsite backup, ~$1/month | Configs, Obsidian, DB dumps, Calibre books, Immich originals |
| **T7 / T5 SSDs** | **Manual** backup targets, normally **unplugged** | Not primary storage any more — any `/Volumes/T7` path means "once you plug it in" |

The full service list with ports and URLs is in [SERVICES.md](SERVICES.md).

---

## 2. Prerequisites

Have these before starting a rebuild:

| Need | Why | Where it lives |
|---|---|---|
| Access to **Vaultwarden** (phone app's offline cache works) | Every service's secrets | The phone/laptop Bitwarden app keeps a cached copy even if the server is down |
| **Cloudflare** login (with 2FA) | Tunnel, DNS, R2 tokens | — |
| **Tailscale** login | Private network | — |
| NAS admin login | SMB account `macmini`, shares | Vaultwarden |
| This repo | Everything else | `github.com/peciulevicius/.dotfiles` (public — no secrets in it) |

⚠️ **The chicken-and-egg:** Vaultwarden runs *on* the Mac mini you're
rebuilding. Its data is in the R2 backup, but you need R2 credentials to pull
it — which are in Vaultwarden. Break the loop with the phone's cached vault,
or create a **new** R2 API token in the Cloudflare dashboard (scope it to the
`peciulevicius-backups` bucket only).

---

## 3. Step by step

### 3.1 macOS basics

| Setting | Command / place | Why |
|---|---|---|
| Never sleep | `scripts/setup/mac-mini.sh sleep off` (or `sudo pmset -a sleep 0 disksleep 0`) | A sleeping Mac mini runs nothing — no sync, no backups, no SSH |
| Restart after a crash | `sudo pmset -a autorestart 1` | Kernel-panic recovery (already on) |
| **Power on when AC returns** | `sudo pmset -a autorestartatconnect 1` | A *separate* flag from `autorestart`; it was missing during the 2026-09-22 outage and the Mac stayed off |
| Remote Login (SSH) | System Settings → General → Sharing, or `scripts/setup/mac-mini.sh ssh on` | `ssh macmini` from the laptop (`config/ssh/config` has the `Host macmini` entry) |
| FileVault | **Keep it on** (decided 2026-09-22) | Trade-off below |

⚠️ **FileVault vs unattended recovery.** With FileVault on, every cold boot
stops at a pre-boot password screen — so after a power outage someone has to
be there once, even with `autorestartatconnect`. The alternative (FileVault
off) would leave every service's `.env` secrets readable on a stolen disk.
The decision is to accept the one manual step.

### 3.2 Dotfiles + tools

```bash
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh     # Homebrew, CLI tools, gitleaks, pre-commit hook
scripts/setup/setup-claude.sh      # Claude Code config (optional for the server itself)
```

`install.sh` also enables the repo's secret-scanning pre-commit hook
(`git config core.hooksPath .githooks`). The repo is public — never commit a
secret, never bypass the hook.

### 3.3 NAS mounts

1. NAS side (nas.peciulevicius.com or the local web UI): SMB account
   **`macmini`** with R/W on `media`, `immich`, `audiobooks`, `books`,
   `unsorted`. (The human admin account `Džiugas` can't be used for SMB — the
   non-ASCII name breaks it.)
2. Store the `macmini` SMB password in the macOS login keychain (first manual
   mount via Finder → ⌘K → `smb://DH4300PLUS-DP.local` and tick "remember").
3. Mount everything: `bash ~/.dotfiles/scripts/utils/mount-nas.sh`
4. Make it automatic — three LaunchAgents keep this self-healing:

| Agent | Script | Does |
|---|---|---|
| `com.peciulevicius.mount-nas` | `scripts/utils/mount-nas.sh` | Mounts shares at login |
| `com.peciulevicius.nas-watchdog` | `scripts/utils/nas-watchdog.sh` | Every 5 min: remount missing shares, then restart NAS-backed containers |
| `com.peciulevicius.docker-watchdog` | `scripts/utils/docker-watchdog.sh` | Every 5 min: Docker Desktop down/hung |

⚠️ **Only the docker-watchdog plist is in the repo** (`os/mac/`). The
mount-nas and nas-watchdog plists currently exist only in
`~/Library/LaunchAgents/` on the Mac mini — on a rebuild, check whether they
were added to the repo since; if not, recreate them from the script headers.

Verify: `ls /Volumes/media /Volumes/immich /Volumes/books /Volumes/audiobooks`.
Details and troubleshooting: [NAS.md](NAS.md).

### 3.4 Docker Desktop

- Install Docker Desktop, set **Resources → Memory to 10 GB** (the ceiling
  used since 2026-07-23 — a ceiling, not a reservation). Lowering it is the
  lever if you ever want a bigger local model in Ollama; see the RAM section
  of the reference doc.
- Start Docker **after** the NAS is mounted. A container started while its
  bind path is missing gets an empty folder on the internal SSD and runs
  pointing at nothing.

### 3.5 Stage services and fill secrets

```bash
~/.dotfiles/services/setup-services.sh   # copies every services/<svc>/ into ~/services/<svc>/
```

⚠️ **`~/services/` is a copy, not a symlink.** Editing
`~/.dotfiles/services/<svc>/…` changes nothing that's running until you
re-copy the file and recreate the container. `.env` is the exception:
`setup-services.sh` creates it from `.env.example` only if it's missing and
never overwrites it.

For each service: fill `~/services/<svc>/.env` from Vaultwarden, then
`cd ~/services/<svc> && docker compose up -d`. Storage paths live only in
`.env` (`MEDIA_DIR=/Volumes/media`, `UPLOAD_LOCATION=/Volumes/immich/upload`,
`BOOKS_DIR=/Volumes/books`, `AUDIOBOOKS_DIR=/Volumes/audiobooks`); databases
stay under `./data/` on the SSD. The full table is in [NAS.md](NAS.md).

Odysseus is the one service built from source: run
`services/odysseus/setup.sh` (clones upstream into `~/services/odysseus`).

**Order that avoids surprises:** Vaultwarden first (restore it, §3.8, so you
can read everything else) → Immich → the rest → Glance last (it joins every
service's Docker network, so those networks must exist).

The `homelab-service` Claude skill (`.claude/skills/homelab-service/`) has the
full add/remove/change checklist for any single service.

### 3.6 Cloudflare Tunnel

```bash
brew install cloudflared
scripts/setup/setup-cloudflare-tunnel.sh   # creates the tunnel + DNS routes
```

Public hostnames and their local ports are in `~/.cloudflared/config.yml`
(the list mirrors [SERVICES.md](SERVICES.md)). Tunnel credentials are
`~/.cloudflared/*.json` — secret, not in the repo; recreating the tunnel with
the script is simpler than restoring them.

⚠️ **Reloading the tunnel after editing `config.yml`:** use
`launchctl kickstart -k "gui/$(id -u)/com.cloudflare.cloudflared"`. There is
also a Homebrew agent (`sh.brew.cloudflared`); `brew services restart
cloudflared` restarts *that* one and silently does nothing. Verify the PID
changed: `ps aux | grep "[c]loudflared tunnel"`.

Only expose services that need it — admin tools stay Tailscale-only.

### 3.7 Tailscale

Install Tailscale on the Mac mini, NAS (runs in Docker there), phone and
laptop. **Disable key expiry** for the Mac mini and NAS in the Tailscale admin
console — an expired key silently drops the machine off the tailnet (it
happened once). The Mac mini's Tailscale IP has been `100.81.171.49`; it
changes if the node is re-registered, so update docs/bookmarks if it does.

### 3.8 Restore data

**Pull configs back from R2** (needs an rclone remote named `r2`, created with
`rclone config` → S3 → Cloudflare, credentials from Vaultwarden or a fresh R2
token):

```bash
rclone lsd r2:peciulevicius-backups                  # services, obsidian-vault, db-dumps, calibre-books, immich-photos
~/.dotfiles/scripts/backup/restore.sh list           # uses ~/services/rclone/.env
~/.dotfiles/scripts/backup/restore.sh service vaultwarden
~/.dotfiles/scripts/backup/restore.sh all
```

(`restore.sh`'s header still says "Backblaze B2"; it reads `RCLONE_REMOTE` and
`BACKUP_DEST` from `~/services/rclone/.env`, so with that file restored it
works against R2.) `.env` files are **not** in the backup by design — secrets
come from Vaultwarden.

**Databases.** Postgres/MariaDB data dirs are excluded from the file backup;
weekly `pg_dump`s are what's backed up:

```bash
rclone copy r2:peciulevicius-backups/db-dumps ~/backups
~/.dotfiles/scripts/backup/restore.sh db ~/backups/<svc>-<date>.sql <container> <user>
```

**Immich.** Two parts — the database (albums, people, faces, favourites) from
the newest `immich-*.sql` dump as above, and the photo/video originals:

- If the NAS survived: nothing to do — originals are on `/Volumes/immich/upload`.
- If the NAS is lost: `rclone copy r2:peciulevicius-backups/immich-photos
  /Volumes/immich/upload/upload`. Transcodes and thumbnails aren't backed up;
  Immich regenerates them.

**Obsidian vault:** `rclone copy r2:peciulevicius-backups/obsidian-vault ~/obsidian-vault`.
**Calibre books:** `rclone copy r2:peciulevicius-backups/calibre-books /Volumes/books`.

### 3.9 Cron jobs

Every job runs through `scripts/utils/run-with-notify.sh`, which posts to
Discord when a job starts failing and when it recovers (webhook in
`~/.config/homelab/notify.env`, outside the repo).

| When | Job | Script |
|---|---|---|
| Sun 04:00 | DB dumps → `~/backups/` | `scripts/backup/backup-databases.sh` |
| Daily 05:00 | R2 backup | `~/services/rclone/rclone-backup.sh` (**staged copy** — it reads `.env` from its own directory) |
| Hourly | Kindle Scribe → Obsidian | `pkm/kindle_sync.py` |
| Every 30 min | Restart Jellyfin + Audiobookshelf so they see new NAS files | `scripts/utils/smb-watcher-rescan.sh` |
| Sun 09:00 | Homelab audit | `scripts/utils/homelab-audit.sh` |

Install from `scripts/cron/crontab` (the schedule's source of truth) and read
it back:

```bash
crontab < ~/.dotfiles/scripts/cron/crontab
crontab -l
```

⚠️ Check `scripts/cron/crontab` matches the table above before installing — the
live crontab was changed on 2026-09-23 (backup path, two new jobs). See
[scripts/cron/README.md](https://github.com/peciulevicius/.dotfiles/blob/main/scripts/cron/README.md)
for the `crontab <file>` pitfall on macOS.

### 3.10 Homepage, monitoring, phone

- **Glance** (`home.peciulevicius.com`) — one monitor + bookmark per service.
- **Uptime Kuma** (`status.peciulevicius.com`) — monitors + the backup push
  heartbeat (`HEARTBEAT_URL` in `~/services/rclone/.env`).
- **Phone:** Immich app with background backup, Bitwarden pointed at the
  self-hosted URL, Tailscale. The per-service app list is in
  [SERVICES.md](SERVICES.md) → Mobile Apps.

### 3.11 Verify

```bash
~/.dotfiles/scripts/utils/homelab-audit.sh   # drift, containers, backups, disk, secrets
docker ps --format '{{.Names}}\t{{.Status}}'
tailscale status
curl -s -o /dev/null -w '%{http_code}\n' https://home.peciulevicius.com
```

---

## 4. Photos: how the phone backup works

1. Immich app on the phone → server URL → sign in → enable background backup.
2. At home, new photos upload in the background; away, over Tailscale when the
   app opens. Large uploads through the public hostname hit the 100MB tunnel
   cap — use the Tailscale URL.
3. Originals land on the NAS (`/Volumes/immich/upload`); the database and
   thumbnails stay on the Mac mini's SSD; R2 gets the originals nightly.

Old archives (the year folders on T7) are **not yet imported** into Immich —
don't wipe T7 until they are (tracked in the TODO).

---

## 5. Backups at a glance

| Copy | What | How often |
|---|---|---|
| NAS RAID 5 | Everything bulk | Live (survives one disk failure — not a backup on its own) |
| Cloudflare R2 | Configs, Obsidian, DB dumps, Calibre books, **Immich originals** | Nightly, automatic |
| T7 / T5 | Immich originals + transcodes, DB dumps, audiobooks, books | **Manual** — plug in, run `scripts/backup/backup-external.sh /Volumes/T7` (`--dry-run` first) |

Deliberately **not** backed up offsite: movies/TV (re-downloadable),
audiobooks and books beyond Calibre (re-acquirable), Immich
transcodes/thumbnails (regenerable).

**Time Machine:** the old setup used a `TimeMachine` APFS volume on T7. With
T7 unplugged, check whether any Time Machine target is currently active
before relying on it (a NAS-based target is an open TODO).

---

## 6. Day-to-day

| Task | How |
|---|---|
| Health check | `scripts/utils/homelab-audit.sh` (also runs Sundays, alerts Discord) |
| Add/remove/change a service | `homelab-service` skill checklist |
| Rotate a password or key | `credential-rotation` skill — every service that keeps its own copy of it must be updated and tested |
| Updates | Watchtower handles `:latest` images; **pinned tags never move** — review them (Pi-hole first) |
| Disk space | `df -h /System/Volumes/Data`; safe reclaim: `docker builder prune -af`. ⚠️ Never `docker image prune -a` — stopped services like Storyteller lose their image |
| Put files on the NAS | Finder → ⌘K → `smb://DH4300PLUS-DP.local`, or nas.peciulevicius.com |

---

## 7. If something breaks

| Scenario | What to do |
|---|---|
| **A service can't see its files** | [NAS.md](NAS.md) ladder: mount gone? → `mount-nas.sh`; NAS reachable? `nc -z DH4300PLUS-DP.local 445`; wrong path in `.env`? container started before the mount? → `docker compose restart` |
| **New movie/audiobook not appearing** | SMB file watchers miss changes. Wait for the 30-min rescan or `docker restart jellyfin audiobookshelf`. Radarr/Sonarr queue shows `downloadClientUnavailable`? → credentials to Transmission are stale (see `credential-rotation`) |
| **Power outage** | Mac mini powers back on (if `autorestartatconnect` is set) but stops at the **FileVault password** — someone types it once. Then shares mount via LaunchAgent and watchdogs restart containers. Uptime Kuma runs on the same box, so **nothing alerts during a whole-house outage** — an external dead-man's switch (Healthchecks.io) is an open TODO |
| **NAS down** | Shares vanish; NAS-backed services stop seeing data (the watchdog remounts once it's back). Check power, then nas.peciulevicius.com → Storage |
| **One NAS disk fails** | RAID 5 keeps running degraded — replace the disk promptly; a second failure loses the array |
| **NAS lost entirely** | Photos: R2 `immich-photos` + T7/T5. DB dumps: R2 + drives. Books: R2 `calibre-books`. Media: re-download. Rebuild shares, then §3.8 |
| **Mac mini dead** | Data is safe on the NAS. New machine: §3.1–3.11, restore configs and DB dumps from R2 |
| **External drive dead** | Buy a replacement, run `backup-external.sh` against it |
| **Docker hung** | `docker-watchdog` restarts it within ~5 min; otherwise quit/reopen Docker Desktop |
| **Tunnel down / hostname 404s** | `ps aux \| grep "[c]loudflared tunnel"`; reload with the `launchctl kickstart` command in §3.6 |
| **Lost remote access** | Tailscale key expired? Log into the admin console; disable key expiry |

Deeper fixes and known traps (Calibre-Web renames over SMB, `.smbdelete`
files, live SQLite files failing the R2 upload, the two cloudflared agents)
are in [HOME_SERVER_REFERENCE.md](HOME_SERVER_REFERENCE.md).

---

## 8. Where things are documented

| Need | File |
|---|---|
| What to do next | [HOME_SERVER_TODO.md](HOME_SERVER_TODO.md) |
| What was done and why | [HOME_SERVER_CHANGELOG.md](HOME_SERVER_CHANGELOG.md) |
| Facts, paths, RAM, gotchas | [HOME_SERVER_REFERENCE.md](HOME_SERVER_REFERENCE.md) |
| Services, ports, mobile apps | [SERVICES.md](SERVICES.md) |
| NAS, mounts, watchdogs | [NAS.md](NAS.md) |
| Scripts | [UTILITY_SCRIPTS.md](UTILITY_SCRIPTS.md) |
| Checklists for Claude Code | `.claude/skills/` — `homelab-service`, `credential-rotation`, `homelab-audit` |
