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
| `scripts/utils/run-with-notify.sh` | Wrap a cron job and notify Discord on failure and recovery | Used by every cron job |
| `scripts/utils/mount-nas.sh` | Mount the NAS SMB shares | At login (launchd) |
| `scripts/utils/nas-watchdog.sh` | Remount shares and restart NAS-backed containers | Every 5 minutes (launchd) |
| `scripts/utils/docker-watchdog.sh` | Restart Docker Desktop or its engine when down or hung | Every 5 minutes (launchd) |
| `scripts/utils/smb-watcher-rescan.sh` | Restart Jellyfin and Audiobookshelf so new NAS files are indexed | Every 30 minutes (cron) |
| `scripts/utils/migrate-calibre-to-ssd.sh` | Move the Calibre library from the NAS to the internal SSD | Once |

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

---

## Homelab scripts

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

### migrate-calibre-to-ssd.sh

Moves the Calibre library from `/Volumes/books` to
`~/services/calibre/library`. Dry run by default; `--apply` stops Calibre,
Calibre-Web and LazyLibrarian, copies and verifies (checksums and
`PRAGMA integrity_check`), updates `BOOKS_DIR` in each `.env` (keeping the old
file as `.env.pre-ssd-migration`), recreates the containers and verifies their
mounts. Rollback steps are in the script header.

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
