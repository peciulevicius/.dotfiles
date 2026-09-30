# Utility scripts

Reference for the scripts in `scripts/` and `services/`. Scheduled jobs are
listed in [scripts/cron/README.md](https://github.com/peciulevicius/.dotfiles/blob/main/scripts/cron/README.md).

## Overview

### Workstation

| Script | Purpose | When |
|---|---|---|
| `scripts/update.sh` | Update package managers, pull the dotfiles, update Claude Code and its configuration, pull Docker images | Weekly |
| `scripts/sync.sh` | Pull the dotfiles, refresh configuration symlinks, enable the pre-commit hook (no package updates) | After changes on another machine |
| `scripts/dev-check.sh` | Check that development tools are installed and configured | After installation; when troubleshooting |
| `scripts/cleanup.sh` | Clear caches and temporary files | Monthly (see the warning below before running on the Mac mini) |
| `scripts/backup/backup-dotfiles.sh` | Archive configuration files and package lists | Before major changes |
| `scripts/setup/setup-claude.sh` | Install or resync the Claude Code configuration | After installation; after pulling changes |
| `scripts/setup/setup-gpg.sh` | Configure GPG commit signing | Once per machine |
| `scripts/setup/setup-obsidian.sh` | Create the Obsidian vault structure | Once |
| `scripts/docs.sh` | Serve or build the MkDocs site | When editing docs |
| `scripts/wallpapers/set-wallpaper.sh` | Set the desktop wallpaper from `wallpapers/` | As needed |
| `scripts/convert-audiobooks.sh` | Convert Audible AAX to M4B (chapters preserved) and copy to the Mac mini | As needed |
| `scripts/utils/arw-to-jpeg.sh` | Convert Sony ARW RAW files to JPEG for Immich (uses `sips`) | As needed |
| `scripts/kindle/sync.sh` | Serve wallpapers or files to a jailbroken Kindle over the LAN | As needed |
| `scripts/utils/gdpr-export.mjs` | Answer GDPR access/erasure requests for a Supabase project (vendored into each project) | When someone emails a data request |

### Homelab (Mac mini)

| Script | Purpose | When |
|---|---|---|
| `services/setup-services.sh` | Stage Docker Compose stacks into `~/services/` | After installation; after changing a service |
| `scripts/setup/mac-mini.sh` | Toggle server sleep settings; one-time Immich setup | Once |
| `scripts/setup/setup-cloudflare-tunnel.sh` | Create the Cloudflare Tunnel and DNS routes | Once |
| `services/rclone/rclone-backup.sh` | Back up to Cloudflare R2 (staged copy in `~/services/rclone/`) | Nightly (cron) |
| `scripts/backup/backup-databases.sh` | Dump PostgreSQL and MariaDB databases to `~/backups/` | Weekly (cron) |
| `scripts/backup/r2-verify.sh` | Restore one random file per R2 set and compare it; track bucket sizes | Monthly (cron) |
| `scripts/backup/restore.sh` | Restore from R2 into `~/services-restore/`; load database dumps | When needed |
| `scripts/backup/backup-external.sh` | rsync NAS data and dumps to an external drive | Manually, when a drive is connected |
| `scripts/utils/homelab-audit.sh` | Audit drift, containers, backups, disk, recent commits and cron | Weekly (cron) |
| `scripts/utils/homelab-status.sh` | Write the Glance status snapshot for *Training*, *Coach team*, *Homelab health* and *Sleeping apps* (`~/services/glance/assets/status.json`) | Every 5 minutes (cron) |
| `scripts/utils/finance-status.sh` | Write the Glance *Portfolio* snapshot (direct IBKR, Trading 212 and Kraken account data) to `~/services/glance/assets/finance.json` | Daily 07:00 (cron) |
| `scripts/utils/update-report.sh` | Read WUD's "update available" list, bucket it (safe / major / held), write `~/services/glance/assets/updates.json`; `--discord` weekly summary, `--markdown` table | Daily 06:30, Mon 09:00 (cron) |
| `scripts/utils/upgrade-service.sh` | Upgrade one pinned image: pull, back up, bump tag in repo, stage, recreate, health-check, **auto-rollback** | By hand, one service at a time |
| `scripts/utils/run-with-notify.sh` | Wrap a cron job and notify Discord on failure and recovery | Used by every cron job |
| `scripts/utils/mount-nas.sh` | Mount the NAS SMB shares | At login (launchd) |
| `scripts/utils/nas-watchdog.sh` | Remount shares and restart NAS-backed containers | Every 5 minutes (launchd) |
| `scripts/utils/docker-watchdog.sh` | Restart Docker Desktop or its engine when down or hung | Every 5 minutes (launchd) |
| `scripts/utils/smb-watcher-rescan.sh` | Restart Jellyfin and Audiobookshelf so new NAS files are indexed | Every 30 minutes (cron) |

---

## Workstation scripts

### update.sh

Updates everything installed through the dotfiles.

| Platform | Updated |
|---|---|
| macOS | Homebrew formulae and casks, npm and pnpm globals, pip, Rust (rustup), Oh My Zsh, the dotfiles repository, Claude Code and its configuration |
| Arch | pacman, yay (AUR), Flatpak, Snap, language package managers |
| Debian/Ubuntu | apt, Flatpak, Snap, language package managers |

```bash
~/.dotfiles/scripts/update.sh
```

The script detects the OS, removes old versions and prints a summary. It is
idempotent.

### sync.sh

Pulls the latest dotfiles without installing packages, then refreshes the
configuration symlinks. It also enables the gitleaks pre-commit hook for the
clone (`core.hooksPath` is per clone) and warns if gitleaks is not installed.
If local and remote history have diverged, it offers to reset to the remote.

```bash
~/.dotfiles/scripts/sync.sh
```

### dev-check.sh

Reports on the development environment and exits non-zero when a required tool
is missing.

| Area | Checks |
|---|---|
| System | OS, shell, terminal |
| Essential tools | git, GitHub CLI, curl, wget, zsh |
| Modern CLI tools | bat, eza, ripgrep, fd, fzf, zoxide, tldr, httpie, jq, delta |
| Package managers | Homebrew, pacman/yay, apt, dnf |
| Development | Docker (and whether it is running), Node.js, npm, nvm, pnpm, VS Code |
| Languages | Python, pip; Ruby, Go, Rust (optional) |
| Configuration | git, SSH, zsh, tmux, EditorConfig, IdeaVim, Starship |
| SSH and GitHub | SSH keys, agent, `gh` authentication |
| Dotfiles | Repository status, branch, sync state, uncommitted changes |
| Network | Internet and GitHub reachability |
| Homelab | Staged services and running containers (when `~/services/` exists) |

```bash
~/.dotfiles/scripts/dev-check.sh
```

### cleanup.sh

Frees disk space by clearing caches and temporary files, and reports disk usage
before and after.

| Platform | Cleared |
|---|---|
| macOS | Homebrew cache, user caches, Trash, Xcode DerivedData, iOS Simulator data |
| Linux | Package manager caches, unused Flatpak runtimes, old Snap revisions, journal logs, user caches |
| All | Docker, npm/pnpm/yarn/pip/Cargo caches, VS Code, JetBrains and Chrome caches |

```bash
~/.dotfiles/scripts/cleanup.sh
sudo ~/.dotfiles/scripts/cleanup.sh   # system-level cleanup on macOS
```

> **Warning:** The Docker section removes stopped containers, all unused
> images and unused volumes. On the Mac mini that deletes services that are
> stopped by design (Storyteller) together with their images. On the homelab
> host, reclaim Docker space with `docker builder prune -af` only.

More aggressive options (removing `node_modules`, `__pycache__`, old kernels)
are present in the script but commented out.

### backup-dotfiles.sh

Creates `~/dotfiles_backup_<timestamp>.tar.gz` containing configuration files
(git, zsh, SSH, tmux, IdeaVim, VS Code, Claude Code) and package lists
(Homebrew, pacman/yay, apt, npm, pip, VS Code extensions). The last five
archives are kept.

```bash
~/.dotfiles/scripts/backup/backup-dotfiles.sh
```

Restore by extracting the archive, copying files back, and reinstalling from
the package lists:

```bash
tar -xzf ~/dotfiles_backup_<timestamp>.tar.gz -C ~
xargs brew install < ~/dotfiles_backup_<timestamp>/brew_packages.txt          # macOS
xargs yay -S --needed < ~/dotfiles_backup_<timestamp>/yay_packages.txt        # Arch
sudo dpkg --set-selections < ~/dotfiles_backup_<timestamp>/apt_packages.txt   # Debian/Ubuntu
sudo apt-get dselect-upgrade
```

### setup-claude.sh

Symlinks `config/claude/` (agents, skills, rules, commands, `CLAUDE.md`,
`settings.json`, status line) into `~/.claude/`.

```bash
~/.dotfiles/scripts/setup/setup-claude.sh          # interactive menu
~/.dotfiles/scripts/setup/setup-claude.sh update   # non-interactive resync (used by update.sh)
```

| Option | Action |
|---|---|
| 1 | First-time setup, including `settings.json` |
| 2 | Resync symlinks after pulling changes |
| 3 | Status line only |
| 4 | Copy live agents back into the repository |

Windows equivalents: `setup-claude.ps1`, `setup-claude.bat`.

### setup-gpg.sh

Interactive setup for signed commits: uses an existing GPG key or generates one,
sets `user.signingkey`, `commit.gpgsign` and `tag.gpgsign`, exports
`GPG_TTY`, configures `pinentry-mac` on macOS, and prints the public key for
GitHub (Settings → SSH and GPG keys → New GPG key).

```bash
brew install gnupg pinentry-mac      # macOS prerequisites
~/.dotfiles/scripts/setup/setup-gpg.sh
git log --show-signature -1          # verify after the next commit
```

| Problem | Fix |
|---|---|
| No passphrase prompt | `export GPG_TTY=$(tty)`, then `gpgconf --kill gpg-agent` |
| `gpg failed to sign the data` | Check `gpg --list-secret-keys`; test with `echo test \| gpg --clearsign` |
| macOS `Inappropriate ioctl for device` | `echo "pinentry-program $(which pinentry-mac)" >> ~/.gnupg/gpg-agent.conf`, then `gpgconf --kill gpg-agent` |

### setup-obsidian.sh

Creates the vault folder structure and templates described in
[guides/NOTES.md](guides/NOTES.md). Exits without changes if `HOME.md` already
exists.

```bash
~/.dotfiles/scripts/setup/setup-obsidian.sh
VAULT_PATH=/path/to/vault ~/.dotfiles/scripts/setup/setup-obsidian.sh
```

### kindle/sync.sh

Transfers files to a jailbroken Kindle over plain HTTP on the LAN and generates
an installer, so the device side is a single command.

```bash
~/.dotfiles/scripts/kindle/sync.sh                               # wallpapers (mirror)
~/.dotfiles/scripts/kindle/sync.sh --dir ~/Downloads/kindle-plugins
~/.dotfiles/scripts/kindle/sync.sh --list                        # list what is on the device
~/.dotfiles/scripts/kindle/sync.sh --port 9000
```

On the Kindle, in kTerm:

```sh
wget -O /tmp/i.sh http://<mac-ip>:8765/_install.sh && sh /tmp/i.sh
```

**Wallpaper mode mirrors** `wallpapers/kindle/`: images are converted to
1860 × 2480 greyscale (letterboxed) with `sips`, and anything removed from the
folder is removed from the device. Output names derive from source names
(`4.jpg` → `ks-4.png`), so adding or removing an image does not renumber the
others. AVIF, HEIC, JPEG, PNG and WebP are supported; small sources produce a
warning.

**`--dir` mode only adds:**

| File | Destination |
|---|---|
| `*.png`, `*.jpg` | `/mnt/us/screensavers/` |
| `*koplugin*.zip` | Extracted into `/mnt/us/koreader/plugins/` |
| Other `*.zip` | Extracted at `/mnt/us` |
| Anything else | `/mnt/us/` |

LAN HTTP is used because the Scribe uses MTP over USB (not mountable on macOS
without extra software) and its busybox `wget` cannot complete TLS with
GitHub's CDN. See [guides/KINDLE_SETUP.md](guides/KINDLE_SETUP.md).

### gdpr-export.mjs

Answers GDPR data-subject requests — "send me my data" (access, Art. 15) and
"delete my data" (erasure, Art. 17) — for any Supabase project. Dependency-free
Node ≥ 22, one file, driven by a per-project JSON config. This copy is
canonical; projects vendor it (see below).

**What GDPR actually asks of you**

- **Verify identity first.** Only act on a request that arrives from the address
  itself, or reply to that address and wait for the answer. Anyone can type
  someone else's email into a contact form; sending them that person's data is
  itself a breach.
- **Answer within one month** of the request (extendable by two more months for
  complex cases, but you must say so within the first month). Free of charge.
- **Send only that person's data**, to that person. The export holds only rows
  matched to their address or auth user id — don't forward it anywhere else,
  and delete your local copy once sent.
- **Erasure is not absolute**: data you must keep for a legal obligation (e.g.
  invoices) stays. Say which and why in the reply. Newsletter unsubscribes are
  often kept as a suppression record; tell the person and delete fully if asked.
- **Explain what you can't link.** Data that can't be tied back to a person
  (e.g. salted IP hashes) isn't theirs to request; the config's `notes` put that
  explanation in the export itself.

**Run it** (from the project root, so `.env.local`/`.env` are picked up):

```bash
node gdpr-export.mjs --config gdpr.config.json export someone@example.com [--out file.json]
node gdpr-export.mjs --config gdpr.config.json delete someone@example.com          # dry run
node gdpr-export.mjs --config gdpr.config.json delete someone@example.com --yes    # deletes
```

- Env: `SUPABASE_URL` (falls back to `PUBLIC_SUPABASE_URL` /
  `NEXT_PUBLIC_SUPABASE_URL`) and `SUPABASE_SERVICE_KEY` (falls back to
  `SUPABASE_SERVICE_ROLE_KEY`). Real env wins, then `.env.local`, then `.env`
  (`process.loadEnvFile` never overwrites a set variable, so loading
  `.env.local` first gives it priority). The service key bypasses RLS — this is
  a local operator tool, never deploy it.
- `export` writes `gdpr-export-<email>-<date>.json` (mode 0600, never overwrites
  an existing file): `{ subject, generated_at, notes, data: { <table>: [rows] },
  auth_user }`. Any key containing `password`, `token` or `secret` is stripped
  from the auth user; per-table `omit` columns are withheld and listed in
  `notes`. Gitignore `gdpr-export-*.json` in the project.
- `delete` without `--yes` only prints per-table counts. With `--yes` it deletes
  tables marked `"delete": true` in reverse config order (children before
  parents), then the auth user if the config says so, and prints a summary.
- Exit codes: `0` ok, `1` usage/config/API error, `2` no data found. With no
  match, `export` writes nothing and `delete` refuses.

**Config** (`gdpr.config.json`):

```json
{
  "authUser": { "export": true, "delete": true },
  "notes": ["Likes are stored as an irreversible IP hash and cannot be linked to a person."],
  "tables": [
    { "table": "newsletter_subscribers", "match": { "column": "email", "by": "email" },
      "delete": true, "omit": ["unsubscribe_token"] },
    { "table": "newsletter_sends",
      "match": { "column": "subscriber_id", "by": "ref",
                 "ref": { "table": "newsletter_subscribers", "column": "id" } } },
    { "table": "guestbook_entries", "match": { "column": "user_id", "by": "auth_user_id" }, "delete": true }
  ]
}
```

| `match.by` | Matches rows where `column` equals… |
|---|---|
| `email` | the address, case-insensitively (`ilike` with `%`/`_` escaped, so exact) |
| `auth_user_id` | the id of the auth user with that email |
| `ref` | any value of `ref.column` in rows already found in the earlier `ref.table` |

`authUser: true` is shorthand for export-only. `delete` defaults to `false`, so
export-only or cascade-deleted tables (like `newsletter_sends` above, removed by
its `ON DELETE CASCADE`) just leave it out.

**How it works.** Plain `fetch` against PostgREST
(`/rest/v1/<table>?<col>=eq.<value>`, paged 1000 rows at a time) and the GoTrue
Admin API. The admin API has no reliable exact-email filter, so the auth user is
found by paging `/auth/v1/admin/users` and matching the email — fine for small
projects, slow for 100k+ users. Everything is collected first; deletes only run
after the full plan has been read, so a failure mid-collection deletes nothing.

**Vendoring into a project.** Copy it to `scripts/gdpr-export.mjs` with a first
comment line pointing back here ("canonical copy lives in
~/.dotfiles/scripts/utils/gdpr-export.mjs — update there first"), write a
`scripts/gdpr.config.json` from the project's migrations (every table holding an
email, an auth user id, or rows hanging off those), and add npm scripts:

```json
"gdpr:export": "node scripts/gdpr-export.mjs --config scripts/gdpr.config.json export",
"gdpr:delete": "node scripts/gdpr-export.mjs --config scripts/gdpr.config.json delete"
```

Then `npm run gdpr:export -- someone@example.com`. Fix bugs here first and
re-copy; the vendored copies should stay byte-identical below the header.
First vendored into `peciulevicius.com` (2026-09-26).

---

## Homelab scripts

### paperclip-fallback.sh

Usage-limit watchdog for Paperclip (cron every 5 min, `~/logs/paperclip-fallback.log`).
Detects Claude-subscription limit failures and, with `--switch` or
`AUTO_SWITCH=1`, moves non-paused `claude_local` agents to OpenRouter
(deepseek-v3.2), saving their configs in `~/.config/homelab/paperclip-fallback/`;
`--restore` probes the subscription but does not PATCH a stuck agent back to
Claude. `--reconcile` previews remaps for already-rehired, retired agents;
`--reconcile --apply` adds their saved skills, updates reporting links and open
issues, and clears matching stale state. Auto-switch remains off until a full
rehire-and-approval workflow is safe. Details: `services/paperclip/README.md`
→ *Usage-limit fallback*.

### setup-services.sh

Copies each service's `docker-compose.yml`, scripts and `.env.example` into
`~/services/<service>/`. An existing `.env` is never overwritten.

```bash
~/.dotfiles/services/setup-services.sh             # all services
~/.dotfiles/services/setup-services.sh immich      # one service
~/.dotfiles/services/setup-services.sh --dry-run
```

> **Note:** Staging copies files; it does not link them. Editing a file under
> `services/` changes nothing until it is re-staged. Verify with
> `diff services/<svc>/docker-compose.yml ~/services/<svc>/docker-compose.yml`;
> the weekly audit reports drift.

The service list, ports and purposes are in [SERVICES.md](SERVICES.md).

### mac-mini.sh

```bash
~/.dotfiles/scripts/setup/mac-mini.sh sleep off   # server mode: no sleep, restart after power loss
~/.dotfiles/scripts/setup/mac-mini.sh sleep on    # restore normal sleep
~/.dotfiles/scripts/setup/mac-mini.sh setup       # one-time Immich setup
```

`setup` predates the NAS migration: it asks for the T7 volume name, creates
Immich folders, and writes `~/services/immich/docker-compose.yml` and `.env`
from `config/immich/`. Existing files are skipped. On the current architecture,
use `services/setup-services.sh immich` instead.

### rclone-backup.sh

Nightly backup to Cloudflare R2: service configuration, the Obsidian vault,
database dumps, the Calibre library and (opt-in) Immich originals. Secrets
(`.env`), live databases and regenerable data are excluded.

```bash
~/services/rclone/rclone-backup.sh --dry-run
~/services/rclone/rclone-backup.sh
```

Cron runs the staged copy in `~/services/rclone/`, which reads
`~/services/rclone/.env`. Setup, exclusions and costs:
[services/rclone/README.md](https://github.com/peciulevicius/.dotfiles/blob/main/services/rclone/README.md).

### r2-verify.sh and restore.sh

`r2-verify.sh` downloads one random file from each backup set, compares it byte
for byte with the original, and appends bucket sizes to
`~/logs/r2-size-history.tsv`. It fails on a mismatch or on a set that shrank by
more than 5% (database dumps are exempt, as they rotate).

`restore.sh` restores into `~/services-restore/` and never overwrites live data,
except for `db`, which asks for confirmation.

```bash
~/.dotfiles/scripts/backup/restore.sh list                  # service configs in R2
~/.dotfiles/scripts/backup/restore.sh service immich
~/.dotfiles/scripts/backup/restore.sh all
~/.dotfiles/scripts/backup/restore.sh set dumps             # vault | dumps | books | photos
~/.dotfiles/scripts/backup/restore.sh db ~/services-restore/dumps/immich-<date>.sql immich_postgres postgres
```

`db` detects MariaDB dumps (Nextcloud) and PostgreSQL `pg_dumpall` output and
uses the matching client.

### backup-external.sh

Copies Immich originals and transcoded video, database dumps, audiobooks and the
Calibre library from the NAS to an external drive. Movies and TV
(re-downloadable) and Immich thumbnails (regenerable) are skipped.

```bash
~/.dotfiles/scripts/backup/backup-external.sh /Volumes/T7 --dry-run
~/.dotfiles/scripts/backup/backup-external.sh /Volumes/T7
~/.dotfiles/scripts/backup/backup-external.sh /Volumes/Backup      # T5
```

- **Manual only.** The drives are not permanently connected, so a scheduled job
  would fail most nights. Each successful run writes
  `~/logs/external-backup-<drive>.last`, and the weekly audit fails after 30
  days without a backup.
- **Refuses to run if a source share is missing or empty.** An `rsync --delete`
  from an unmounted share would erase the backup.
- **Destination paths mirror the NAS layout** (`…/immich/upload/upload`).
  Changing them makes rsync delete and re-copy the whole backup.
- Database dumps matter as much as photos: Immich stores originals under UUID
  names, so without the database a restore loses albums, faces, dates and
  favourites.

Log: `~/logs/external-backup-<drive>-<date>.log`

### homelab-audit.sh

Weekly checks, each derived from a past failure:

| Check | Detects |
|---|---|
| Drift | Repository `services/` files that differ from the staged copies |
| Containers | Stopped or unhealthy containers (services with `restart: "no"` are ignored) |
| Backups | No successful R2 backup in the last day; Immich step enabled but skipped; stale database dumps; external drives more than 30 days out of date |
| Disk | Internal disk at 90% or more |
| Secrets | gitleaks findings in the last eight days of commits; pre-commit hook not enabled |
| Cron | Live crontab differs from `scripts/cron/crontab` |

```bash
~/.dotfiles/scripts/utils/homelab-audit.sh
```

The `homelab-audit` project skill adds the judgement-based checks (pinned image
versions, credential copies, documentation accuracy).

### update-report.sh

Reads the WUD API (`services/wud`, login from `~/.config/homelab/wud.env`)
and sorts every "update available" into **safe** (patch/minor), **major** or
**held** (`services/wud/holds.tsv` — DB majors, false positives). Writes
`~/services/glance/assets/updates.json` for the Glance *Updates* widget, so
Glance never needs the WUD login. Floating-tag digest refreshes are skipped
(Watchtower's job).

```bash
~/.dotfiles/scripts/utils/update-report.sh             # table + JSON
~/.dotfiles/scripts/utils/update-report.sh --markdown  # table for the TODO list
~/.dotfiles/scripts/utils/update-report.sh --discord   # + weekly Discord post
```

### upgrade-service.sh

The one supported way to change a pinned tag. Details, safety steps and test
results: `services/wud/README.md` → *Upgrading a service*.

```bash
~/.dotfiles/scripts/utils/upgrade-service.sh <service> [tag] [--image <substring>] [--commit]
```

Written for macOS `/bin/bash` 3.2 (no `mapfile`). Leaves the repo change for
you to commit unless `--commit` is passed.

### homelab-status.sh

Host-side snapshot for the Glance homepage's **Homelab health** widget:
Docker memory, macOS swap, disk usage (APFS data volume and NAS), backup
ages, and each scale-to-zero app's awake/asleep state with its link (read
from `docker ps`, never by requesting the app). Also the Paperclip queue, the
Coach's latest check-in summary, the Dietitian's line for today, and
TrainingPeaks fitness, body and weekly numbers. TP data comes from the local
MCP through read-only tools and is cached for 30 min in
`~/.cache/homelab-status/tp.json`. The script writes JSON atomically and puts
an `ok`/`warn`/`bad` level on every value.

```bash
~/.dotfiles/scripts/utils/homelab-status.sh --print   # output has no secrets
```

Details, thresholds and the Glance side: `services/glance/README.md` →
*Homelab health widget*.

### calendar-status.sh

Feeds the Glance **Today** widget: reads Radicale over CalDAV (REPORT
calendar-query — today..tomorrow events with server-side recurrence
expansion, plus open VTODOs overdue, due within 7 days, or undated) and writes
`~/services/glance/assets/calendar.json`. Times are shown in Europe/Vilnius;
all-day events sort first. Login from `~/.config/homelab/radicale.env`, never
printed. Cron: every 5 min. On failure the widget says "Calendar unavailable"
with the error instead of showing stale data.

```bash
~/.dotfiles/scripts/utils/calendar-status.sh --print
```

### finance-status.sh

Direct IBKR Flex, Trading 212 account summaries and Kraken default-wallet balances for the Glance Finance
page. `finance-status.sh` calls `finance-data.py`, which writes the private
served snapshot and keeps credential-specific native caches outside Glance's
assets. Each provider has its own status and date; the combined EUR figure
covers connected investments only. Failed fetches mark cached data stale.
Wallet balances and budgets are no longer collected.
Trading 212 also reads positions; per-instrument wallet values use its account
currency, and a detail failure keeps the fresh account total with a warning.
Pie shares are not added twice, and holdings are never added to reported NAV.

```bash
bash scripts/utils/finance-status.sh            # refresh; no balances printed
bash scripts/utils/finance-status.sh --health   # cached booleans, no API calls
```

`--print` includes private financial data. `--from-file` parses one local IBKR
report without calling other brokers; use isolated output/cache directories
as described in `services/glance/README.md` → Finance. Capital.com,
Ledger and bank import connectors remain planned. The private daily memory
snapshot records coverage and avoids comparisons against legacy Wallet data.
Kraken uses a dedicated Query Funds key and persists private nonces before
signed balance reads. Its EUR value is an indicative spot midpoint estimate;
unknown assets/prices fail the account instead of producing a partial value.

### run-with-notify.sh

```bash
run-with-notify.sh <label> <command> [args...]
```

Runs a job and posts to Discord only on state changes: when it starts failing
(with its output), a reminder every `REMIND_HOURS` (default 24) while it keeps
failing, and when it recovers. The webhook is read from
`~/.config/homelab/notify.env`; without it the wrapper does nothing extra.
State is kept in `~/.local/state/homelab-jobs/`. The Discord helper is sourced
from `scripts/lib/notify.sh`.

### Watchdogs and mounts

- `mount-nas.sh` mounts the NAS shares by mDNS name with credentials from the
  login keychain.
- `nas-watchdog.sh` remounts missing shares **before** restarting exited
  NAS-backed containers; a container started without its mount writes into an
  empty directory on the SSD.
- `docker-watchdog.sh` relaunches Docker Desktop, or force-restarts it when the
  engine hangs.

Details: [NAS.md](NAS.md).

### smb-watcher-rescan.sh

Restarts Jellyfin and Audiobookshelf every 30 minutes because their file
watchers miss new files on SMB. This is a stopgap until import notifications
are configured; see
[HOME_SERVER_REFERENCE.md](HOME_SERVER_REFERENCE.md#file-watchers-miss-new-files-on-smb).

---

## Suggested routines

**Weekly (workstation)**

```bash
~/.dotfiles/scripts/backup/backup-dotfiles.sh
~/.dotfiles/scripts/update.sh
~/.dotfiles/scripts/dev-check.sh
```

**New machine**

```bash
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh
~/.dotfiles/scripts/setup/setup-gpg.sh
~/.dotfiles/scripts/dev-check.sh
```

**Shell aliases**

```bash
alias update='~/.dotfiles/scripts/update.sh'
alias backup='~/.dotfiles/scripts/backup/backup-dotfiles.sh'
alias cleanup='~/.dotfiles/scripts/cleanup.sh'
alias check='~/.dotfiles/scripts/dev-check.sh'
```

## See also

- [HOW_TO_INSTALL.md](HOW_TO_INSTALL.md)
- [CONFIG_GUIDE.md](CONFIG_GUIDE.md)
- [MODERN_CLI_TOOLS.md](MODERN_CLI_TOOLS.md)
