# Utility Scripts

This dotfiles repository includes several utility scripts to help maintain and manage your development environment.

## Quick Reference

| Script | What it does | When to run |
|--------|-------------|-------------|
| `update.sh` | Updates all package managers + pulls dotfiles + Claude Code + Docker images | Weekly |
| `sync.sh` | Pulls dotfiles from git + re-symlinks configs (no package updates) | After pulling dotfiles |
| `setup/setup-claude.sh` | Syncs Claude Code config (agents, skills, rules, commands) | After install / as needed |
| `backup/backup-dotfiles.sh` | Backs up config files + package lists to a timestamped archive | Before major changes |
| `backup/backup-immich.sh` | Rsync Immich photos T7 → T5 `ImmichBackup` (Mac mini only) | Nightly via cron |
| `cleanup.sh` | Cleans caches and frees disk space | Monthly |
| `dev-check.sh` | Checks all dev tools are installed and configured | After fresh install / troubleshooting |
| `setup/setup-gpg.sh` | Sets up GPG commit signing | Once per machine |
| `setup/setup-obsidian.sh` | Creates Obsidian vault with PARA folder structure | Once per machine |
| `docs.sh` | Serves or builds the MkDocs documentation site | Dev / CI |
| `setup/mac-mini.sh` | Mac mini sleep toggle + one-time Immich setup | Mac mini only |
| `setup/setup-cloudflare-tunnel.sh` | Sets up Cloudflare Tunnel for HTTPS on all services | Once per machine |
| `backup/backup-databases.sh` | Dumps PostgreSQL + MariaDB databases from Docker | Weekly via cron |
| `backup/restore.sh` | Restores service data from Backblaze B2 | When needed |
| `services/setup-services.sh` | Stages Docker Compose stacks to `~/services/` | After fresh install |
| `services/rclone/rclone-backup.sh` | Backs up `~/services/` to Backblaze B2 via rclone | Nightly via cron |

---

## 📍 Location

All utility scripts are located in `scripts/` directory:

```
scripts/
├── update.sh           # Update all package managers + pull dotfiles + Claude Code
├── sync.sh             # Pull dotfiles from git + re-symlink configs (no package updates)
├── setup/setup-claude.sh     # Sync Claude Code config (agents, skills, rules, commands)
├── setup/setup-obsidian.sh   # Create Obsidian vault with PARA folder structure
├── backup/backup-dotfiles.sh # Back up config files + package lists to timestamped archive
├── backup/backup-immich.sh   # Rsync Immich photos T7 → T5 ImmichBackup (Mac mini only)
├── cleanup.sh          # Clean caches and free disk space
├── dev-check.sh        # Check environment health
├── setup/setup-gpg.sh  # Set up GPG commit signing
├── setup/setup-cloudflare-tunnel.sh  # Set up Cloudflare Tunnel for HTTPS
├── backup/backup-databases.sh  # Dump databases from Docker containers
├── backup/restore.sh   # Restore service data from B2
├── docs.sh             # Serve or build MkDocs docs site
├── setup/mac-mini.sh   # Mac mini: sleep toggle + Immich setup (Mac mini only)
├── utils/utils.sh      # Shared print functions used by Linux + Windows installers
└── wallpapers/         # Wallpaper management

services/
├── setup-services.sh             # Stage all Docker Compose stacks to ~/services/
├── immich/                       # Google Photos replacement
├── vaultwarden/                  # Bitwarden password manager server
├── nextcloud/                    # Google Drive replacement
├── uptime-kuma/                  # Uptime monitoring dashboard
├── freshrss/                     # RSS reader
├── syncthing/                    # File sync (Dropbox replacement)
├── portainer/                    # Docker management UI
├── watchtower/                   # Automatic Docker image updates
├── homarr/                       # Home dashboard
├── paperless-ngx/                # Document scanner and organiser
├── calibre-web/                  # Ebook library server
└── rclone/rclone-backup.sh       # Cloud backup to B2/S3
```

## 🚀 Quick Start

```bash
# Make scripts executable (if needed)
chmod +x ~/.dotfiles/scripts/*.sh

# Run any script
~/.dotfiles/scripts/update.sh
```

---

## 🤖 setup/setup-claude.sh - Claude Code Setup

Sets up Claude Code configuration — agents, skills, rules, commands, CLAUDE.md, statusline.

### Usage

```bash
~/.dotfiles/scripts/setup/setup-claude.sh          # interactive menu (pick 1–4)
~/.dotfiles/scripts/setup/setup-claude.sh update   # non-interactive resync (used by update.sh)
```

### Menu options

```
1) First-time setup       — full install, prompts for settings.json
2) Update / resync        — sync all symlinks after pulling dotfiles
3) Statusline only        — just configure the status bar
4) Sync agents → dotfiles — pull live agents back into the repo
```

### What it installs

Symlinks everything from `config/claude/` into `~/.claude/`:
- `agents/` — 17 specialist sub-agents
- `skills/` — 22 reusable skills
- `rules/` — 7 rule files (TypeScript, Git, React, etc.)
- `commands/` — 6 slash commands (/pr, /debug, etc.)
- `CLAUDE.md` — global instructions
- `settings.json` — permissions and statusline config

### When to run

- **New machine:** run once after `./install.sh`
- **After pulling dotfiles:** run with option 2 (or let `update.sh` do it)
- **After adding new agents/skills:** run with option 2

---

## 📦 update.sh - Universal System Update

Updates all package managers, tools, and Claude Code config on your system.

### What it Updates

**macOS:**
- Homebrew (formulas and casks)
- npm global packages
- pnpm global packages
- pip packages
- Rust (via rustup)
- Oh My Zsh
- Dotfiles repository
- Claude Code CLI + config resync

**Linux (Arch):**
- pacman packages
- yay (AUR packages)
- Flatpak
- Snap
- All language package managers

**Linux (Debian/Ubuntu):**
- apt packages
- Flatpak
- Snap
- All language package managers

### Usage

```bash
# Update everything
~/.dotfiles/scripts/update.sh
```

### Features

- ✓ Detects your OS automatically
- ✓ Updates all relevant package managers
- ✓ Cleans up old versions
- ✓ Shows summary of what was updated
- ✓ Safe to run regularly (idempotent)

### Recommended Frequency

Run this weekly or before starting new projects:

```bash
# Add to your shell aliases
alias update='~/.dotfiles/scripts/update.sh'

# Then simply run
update
```

---

## 📓 setup/setup-obsidian.sh - Obsidian Vault Setup

Creates an Obsidian vault with 10 emoji-prefixed folders and 27 template files.

### Usage

```bash
# Create vault at ~/obsidian-vault (default)
~/.dotfiles/scripts/setup/setup-obsidian.sh

# Custom path
VAULT_PATH=/Volumes/SSD/notes ~/.dotfiles/scripts/setup/setup-obsidian.sh
```

### What it creates

```
~/obsidian-vault/
├── HOME.md              # Root dashboard — open on startup
├── ⚡ Capture/           # Quick capture inbox
├── 🏢 Visma/            # Work notes (VFS, Gweb, 1on1, VCDM, YPP)
├── 🚀 Build/            # Business ideas, SaaS research, writing
├── 📚 Books & Learning/ # Currently reading, quotes, book notes
├── 🏊 Training & Health/# Training log, races, gear, health
├── 💰 Finance/          # Budget, finance notes
├── ✈️ Travel/           # Trip templates, wishlist
├── 🙋 Personal/         # Goals, weekly reflection
├── 📥 Imports/          # Kindle TXT exports (process weekly)
└── 📦 Archive/          # Dead ideas, old notes
```

See [guides/NOTES.md](./guides/NOTES.md) for the full Obsidian + Syncthing workflow.

---

## 🐳 services/setup-services.sh - Docker Services Setup

Stages Docker Compose stacks and `.env` templates to `~/docker/<service>/`.

### Usage

```bash
# Stage all 13 services
~/.dotfiles/services/setup-services.sh

# Stage one service
~/.dotfiles/services/setup-services.sh immich

# Preview without changes
~/.dotfiles/services/setup-services.sh --dry-run
```

### Services staged

| Service | Port | Replaces |
|---------|------|---------|
| immich | 2283 | Google Photos |
| vaultwarden | 8001 | Bitwarden Cloud |
| nextcloud | 8080 | Google Drive |
| uptime-kuma | 3001 | StatusCake |
| freshrss | 8082 | Feedly |
| syncthing | 8384 | Dropbox |
| portainer | 9000 | Docker UI |
| watchtower | — | Manual updates |
| homarr | 7575 | Home dashboard |
| paperless-ngx | 8000 | Paper filing |
| calibre-web | 8083 | Kindle Cloud |
| rclone | — | Cloud backup |

See [SERVICES.md](./SERVICES.md) for full setup guide.

---

## ☁️ services/rclone/rclone-backup.sh - Cloud Backup

Backs up `~/docker/` volumes to Backblaze B2 (or any rclone remote).

### Usage

```bash
# Test first
~/.dotfiles/services/rclone/rclone-backup.sh --dry-run

# Live backup
~/.dotfiles/services/rclone/rclone-backup.sh
```

### Setup

```bash
brew install rclone
rclone config  # configure B2 remote named 'b2-backup'
cp ~/.dotfiles/services/rclone/.env.example ~/docker/rclone/.env
nano ~/docker/rclone/.env
```

### Automate

```bash
crontab -e
# Daily at 3 AM:
0 3 * * * ~/.dotfiles/services/rclone/rclone-backup.sh >> ~/logs/rclone-cron.log 2>&1
```

See [HOME_SERVER.md](./HOME_SERVER.md) for full strategy.

---

## 💾 backup-dotfiles.sh - Configuration Backup

Creates timestamped backups of your configuration files and settings.

### What it Backs Up

**Configuration Files:**
- `.gitconfig`, `.zshrc`, `.ideavimrc`, `.tmux.conf`, etc.
- SSH keys and configuration
- VS Code settings
- Claude Code settings

**Package Lists:**
- Homebrew packages (macOS)
- pacman/yay packages (Arch)
- apt packages (Debian/Ubuntu)
- npm global packages
- pip packages
- VS Code extensions

**Other:**
- Git repositories list
- Custom configuration directories

### Usage

```bash
# Create a backup
~/.dotfiles/scripts/backup/backup-dotfiles.sh
```

### Output

Creates a compressed archive in your home directory:

```
~/dotfiles_backup_20241105_143022.tar.gz
```

### Backup Retention

- Automatically keeps the last 5 backups
- Older backups are automatically deleted
- Backups are compressed to save space

### Restoring from Backup

```bash
# Extract the backup
cd ~
tar -xzf dotfiles_backup_20241105_143022.tar.gz

# Copy files back to their original locations
cp dotfiles_backup_20241105_143022/.gitconfig ~/.gitconfig
# ... etc

# Reinstall packages from lists
# macOS:
xargs brew install < dotfiles_backup_20241105_143022/brew_packages.txt

# Arch:
xargs yay -S --needed < dotfiles_backup_20241105_143022/yay_packages.txt

# Ubuntu/Debian:
sudo dpkg --set-selections < dotfiles_backup_20241105_143022/apt_packages.txt
sudo apt-get dselect-upgrade
```

### Recommended Usage

```bash
# Before major changes
~/.dotfiles/scripts/backup/backup-dotfiles.sh

# Set up a cron job for automatic backups (weekly)
# Add to crontab (crontab -e):
0 0 * * 0 ~/.dotfiles/scripts/backup/backup-dotfiles.sh
```

---

## 🧹 cleanup.sh - System Cleanup

Frees up disk space by cleaning caches, logs, and temporary files.

### What it Cleans

**macOS:**
- Homebrew cache
- User and system caches
- Trash
- Xcode derived data
- iOS Simulator data

**Linux:**
- Package manager caches (pacman, apt, dnf)
- Flatpak unused apps
- Snap old versions
- Systemd journal logs
- User cache directories

**All OS:**
- Docker containers, images, volumes, and build cache
- npm cache
- pnpm cache
- yarn cache
- pip cache
- Cargo cache
- VS Code cache
- JetBrains IDE cache
- Chrome cache
- Temporary files

### Usage

```bash
# Clean everything
~/.dotfiles/scripts/cleanup.sh

# Some operations require sudo
sudo ~/.dotfiles/scripts/cleanup.sh  # For system-level cleanup on macOS
```

### Safety

- ✓ Only cleans caches and temp files
- ✓ Does not delete user data
- ✓ Does not delete source code
- ✓ Shows disk usage before and after
- ✓ Safe to run regularly

### Expected Results

Typical disk space freed:
- **Light use:** 500MB - 2GB
- **Heavy use:** 5GB - 20GB
- **Docker users:** 10GB - 50GB+

### Aggressive Cleaning (Optional)

The script includes commented-out options for more aggressive cleaning:

```bash
# Uncomment in the script to enable:
# - Remove all node_modules directories
# - Remove all __pycache__ directories
# - Remove old kernel versions (Linux)
```

### Recommended Frequency

```bash
# Monthly cleanup
~/.dotfiles/scripts/cleanup.sh

# Add to alias for convenience
alias cleanup='~/.dotfiles/scripts/cleanup.sh'
```

---

## 🏥 dev-check.sh - Environment Health Check

Verifies that all development tools are properly installed and configured.

### What it Checks

**System Info:**
- OS version and details
- Shell and terminal info

**Essential Tools:**
- Git, GitHub CLI, curl, wget, zsh

**Modern CLI Tools:**
- bat, eza, ripgrep, fd, fzf, zoxide, tldr, httpie, jq, delta

**Package Managers:**
- Homebrew (macOS)
- pacman/yay (Arch)
- apt (Debian/Ubuntu)
- dnf (Fedora/RHEL)

**Development Tools:**
- Docker (and if it's running)
- Node.js, npm, nvm, pnpm
- VS Code

**Languages & Runtimes:**
- Python, pip
- Ruby (optional)
- Go (optional)
- Rust (optional)

**Configuration Files:**
- Git config, SSH config, Zsh config
- Tmux, EditorConfig
- IdeaVim, Starship config

**SSH & GitHub:**
- SSH keys (ed25519 or RSA)
- SSH agent status
- GitHub CLI authentication

**Dotfiles:**
- Repository status
- Git branch and sync status
- Uncommitted changes

**Network:**
- Internet connectivity
- GitHub reachability

### Usage

```bash
# Run health check
~/.dotfiles/scripts/dev-check.sh
```

### Output Example

```
═══════════════════════════════════════════════════════
  Development Environment Health Check
═══════════════════════════════════════════════════════

Operating System: Darwin
Hostname: MacBook-Pro
User: john

═══════════════════════════════════════════════════════
  Essential Tools
═══════════════════════════════════════════════════════

✓ Git: git version 2.42.0
✓ GitHub CLI: gh version 2.40.0
✓ curl: curl 8.4.0
✓ wget: GNU Wget 1.21.4
✓ Zsh: zsh 5.9

... [more checks]

═══════════════════════════════════════════════════════
  Summary
═══════════════════════════════════════════════════════

Health Check Results:

  Required passed: 16 / 16 (100%)
  Required failed: 0
  Optional passed: 4 / 22
  Optional missing: 18

✓ Core environment is healthy.

Quick fixes:
  • Install missing CLI tools: brew install ...
  • Install missing casks: brew install --cask ...
  • Update packages: Run scripts/update.sh
  • Install from: https://ohmyz.sh
```

### Use Cases

**After Fresh Install:**
```bash
# Verify everything installed correctly
~/.dotfiles/scripts/dev-check.sh
```

**Troubleshooting:**
```bash
# Diagnose why something isn't working
~/.dotfiles/scripts/dev-check.sh
```

**Regular Maintenance:**
```bash
# Verify environment health monthly
~/.dotfiles/scripts/dev-check.sh
```

**Documentation:**
```bash
# Share your environment setup with team
~/.dotfiles/scripts/dev-check.sh > my-setup.txt
```

---

## 🔐 setup-gpg.sh - GPG Commit Signing Setup

Sets up GPG keys for signing Git commits, making your commits verified on GitHub.

### What it Does

1. Checks if GPG is installed
2. Lists existing GPG keys (if any)
3. Generates new GPG key or uses existing one
4. Configures Git to sign commits automatically
5. Exports public key for GitHub
6. Tests GPG signing
7. Provides instructions for adding key to GitHub

### Usage

```bash
# Run the setup wizard
~/.dotfiles/scripts/setup/setup-gpg.sh
```

### Interactive Setup

The script will ask you:
1. Do you want to use an existing key? (if any exist)
2. Your name (for new key)
3. Your email (must match your GitHub email)
4. Set a passphrase (keep it safe!)

### What Gets Configured

**Git Configuration:**
```ini
[user]
    signingkey = YOUR_GPG_KEY_ID

[commit]
    gpgsign = true

[tag]
    gpgsign = true
```

**Shell Configuration:**
```bash
# Added to .zshrc or .bashrc
export GPG_TTY=$(tty)
```

**macOS Specific:**
```
# If pinentry-mac is installed
pinentry-program /opt/homebrew/bin/pinentry-mac
```

### Prerequisites

**macOS:**
```bash
brew install gnupg pinentry-mac
```

**Arch Linux:**
```bash
sudo pacman -S gnupg
```

**Ubuntu/Debian:**
```bash
sudo apt install gnupg
```

### Adding Key to GitHub

1. The script will display your public key
2. Go to https://github.com/settings/keys
3. Click "New GPG key"
4. Paste the public key
5. Click "Add GPG key"

### Verifying It Works

After setup, your commits will show as "Verified" on GitHub:

```bash
# Make a test commit
echo "test" > test.txt
git add test.txt
git commit -m "Test GPG signing"

# Check the signature
git log --show-signature -1

# Push to GitHub and check for "Verified" badge
git push
```

### Troubleshooting

**Passphrase Prompt Not Appearing:**
```bash
# Ensure GPG_TTY is set
export GPG_TTY=$(tty)

# Restart GPG agent
gpgconf --kill gpg-agent
```

**"gpg failed to sign the data":**
```bash
# Check your key
gpg --list-secret-keys

# Test signing
echo "test" | gpg --clearsign
```

**macOS: "Inappropriate ioctl for device":**
```bash
# Install pinentry-mac
brew install pinentry-mac

# Configure it
echo "pinentry-program $(which pinentry-mac)" >> ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
```

---

## 🖥️ mac-mini.sh — Mac mini Management

Manages sleep settings and Immich setup on the Mac mini. Not relevant on MacBook.

### Usage

```bash
~/.dotfiles/scripts/setup/mac-mini.sh sleep off   # server mode: disable sleep
~/.dotfiles/scripts/setup/mac-mini.sh sleep on    # normal mode: re-enable sleep
~/.dotfiles/scripts/setup/mac-mini.sh setup       # one-time Immich setup
```

### Commands

| Command | What it does |
|---------|-------------|
| `sleep off` | Disables sleep, enables auto-restart after power failure. Run on first boot. |
| `sleep on` | Restores normal sleep behaviour. |
| `setup` | Creates Immich folders, writes `docker-compose.yml` and `.env` to `~/services/immich/`. Run once after drives are connected. |

### When to run

- **First boot on Mac mini:** `mac-mini.sh sleep off` then later `mac-mini.sh setup`
- **Temporarily need sleep:** `mac-mini.sh sleep on` / `mac-mini.sh sleep off` to toggle
- **Re-running setup:** safe to rerun — existing files are skipped, not overwritten

### What `setup` does

1. Lists `/Volumes/` so you can see what your T7 drive is named in macOS
2. Asks for the T7 volume name (e.g. `Samsung T7`, `T7 Touch` — whatever macOS calls it)
3. Saves that name to `~/.config/dotfiles/mac-mini.conf` so `backup-immich.sh` can read it
4. Creates `/Volumes/<T7>/immich/`, `~/services/immich/`, `~/logs/`
5. Writes `~/services/immich/docker-compose.yml` from `config/immich/docker-compose.yml` with your volume name substituted in
6. Copies `config/immich/.env.example` to `~/services/immich/.env`

---

## 📸 backup-immich.sh — Immich Photo Backup

Rsync copy of Immich photos from T7 (primary) to T5 `ImmichBackup` (backup). Reads the T7 volume name from `~/.config/dotfiles/mac-mini.conf` — run `mac-mini.sh setup` first.

### Usage

```bash
# Run manually
~/.dotfiles/scripts/backup/backup-immich.sh

# Schedule via cron (3am daily)
crontab -e
# Add: 0 3 * * * ~/.dotfiles/scripts/backup/backup-immich.sh >> ~/logs/immich-backup.log 2>&1
```

### Check the log

```bash
cat ~/logs/immich-backup.log
```

---

## 🔗 Script Combinations

### Weekly Maintenance Routine

```bash
# 1. Backup current state
~/.dotfiles/scripts/backup/backup-dotfiles.sh

# 2. Update everything
~/.dotfiles/scripts/update.sh

# 3. Clean up disk space
~/.dotfiles/scripts/cleanup.sh

# 4. Verify health
~/.dotfiles/scripts/dev-check.sh
```

### New Machine Setup

```bash
# 1. Clone dotfiles
git clone https://github.com/yourusername/.dotfiles.git ~/.dotfiles

# 2. Run installer
~/.dotfiles/install.sh

# 3. Set up GPG signing
~/.dotfiles/scripts/setup/setup-gpg.sh

# 4. Verify everything
~/.dotfiles/scripts/dev-check.sh

# 5. Create first backup
~/.dotfiles/scripts/backup/backup-dotfiles.sh
```

### Before Major Changes

```bash
# 1. Create backup
~/.dotfiles/scripts/backup/backup-dotfiles.sh

# 2. Check current state
~/.dotfiles/scripts/dev-check.sh

# ... make your changes ...

# 3. Verify nothing broke
~/.dotfiles/scripts/dev-check.sh
```

---

## 💡 Pro Tips

### Create Aliases

Add these to your `.zshrc`:

```bash
alias update='~/.dotfiles/scripts/update.sh'
alias backup='~/.dotfiles/scripts/backup/backup-dotfiles.sh'
alias cleanup='~/.dotfiles/scripts/cleanup.sh'
alias check='~/.dotfiles/scripts/dev-check.sh'
```

### Schedule Automatic Tasks

```bash
# Add to crontab (crontab -e):

# Weekly updates (Sundays at 2 AM)
0 2 * * 0 ~/.dotfiles/scripts/update.sh

# Weekly backups (Sundays at 3 AM)
0 3 * * 0 ~/.dotfiles/scripts/backup/backup-dotfiles.sh

# Monthly cleanup (1st of month at 4 AM)
0 4 1 * * ~/.dotfiles/scripts/cleanup.sh
```

### Use in CI/CD

```bash
# Verify developer environment in CI
- name: Check Development Environment
  run: ~/.dotfiles/scripts/dev-check.sh
```

---

## 📚 See Also

- [HOW_TO_INSTALL.md](./HOW_TO_INSTALL.md) - Installation instructions
- [CONFIG_GUIDE.md](./CONFIG_GUIDE.md) - Configuration details
- [MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md) - Modern CLI tools guide

---

**These scripts will save you hours of maintenance time!** Set up aliases and use them regularly to keep your development environment healthy and up-to-date.
