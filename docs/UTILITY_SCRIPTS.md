# Utility Scripts

This dotfiles repository includes several utility scripts to help maintain and manage your development environment.

## 📍 Location

All utility scripts are located in `scripts/` directory:

```
scripts/
├── update.sh       # Update all package managers
├── backup.sh       # Backup configurations
├── cleanup.sh      # Clean caches and free disk space
├── dev-check.sh    # Check environment health
└── setup-gpg.sh    # Set up GPG commit signing
```

## 🚀 Quick Start

```bash
# Make scripts executable (if needed)
chmod +x ~/.dotfiles/scripts/*.sh

# Run any script
~/.dotfiles/scripts/update.sh
```

---

## 📦 update.sh - Universal System Update

Updates all package managers and tools on your system.

### What it Updates

**macOS:**
- Homebrew (formulas and casks)
- npm global packages
- pnpm global packages
- pip packages
- Rust (via rustup)
- Oh My Zsh
- Dotfiles repository

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

## 💾 backup.sh - Configuration Backup

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
~/.dotfiles/scripts/backup.sh
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
~/.dotfiles/scripts/backup.sh

# Set up a cron job for automatic backups (weekly)
# Add to crontab (crontab -e):
0 0 * * 0 ~/.dotfiles/scripts/backup.sh
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
- IdeaVim, Powerlevel10k

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

  Passed:  45 / 50 (90%)
  Failed:  5 / 50

✓ Your development environment is in great shape!

Quick fixes:
  • Install missing tools: Run the appropriate installer from os/
  • Update packages: Run scripts/update.sh
  • Fix SSH: ssh-keygen -t ed25519 -C "your@email.com"
  • Fix GitHub: gh auth login
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
~/.dotfiles/scripts/setup-gpg.sh
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

## 🔗 Script Combinations

### Weekly Maintenance Routine

```bash
# 1. Backup current state
~/.dotfiles/scripts/backup.sh

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
~/.dotfiles/scripts/setup-gpg.sh

# 4. Verify everything
~/.dotfiles/scripts/dev-check.sh

# 5. Create first backup
~/.dotfiles/scripts/backup.sh
```

### Before Major Changes

```bash
# 1. Create backup
~/.dotfiles/scripts/backup.sh

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
alias backup='~/.dotfiles/scripts/backup.sh'
alias cleanup='~/.dotfiles/scripts/cleanup.sh'
alias check='~/.dotfiles/scripts/dev-check.sh'
```

### Schedule Automatic Tasks

```bash
# Add to crontab (crontab -e):

# Weekly updates (Sundays at 2 AM)
0 2 * * 0 ~/.dotfiles/scripts/update.sh

# Weekly backups (Sundays at 3 AM)
0 3 * * 0 ~/.dotfiles/scripts/backup.sh

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

- [INSTALLATION_GUIDE.md](./INSTALLATION_GUIDE.md) - Installation instructions
- [CONFIG_GUIDE.md](./CONFIG_GUIDE.md) - Configuration details
- [MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md) - Modern CLI tools guide

---

**These scripts will save you hours of maintenance time!** Set up aliases and use them regularly to keep your development environment healthy and up-to-date.
