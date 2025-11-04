# How to Install - Complete Step-by-Step Guide

This is the **complete guide** for setting up your development environment on any machine.

---

## Table of Contents

1. [Quick Start (TL;DR)](#quick-start-tldr)
2. [macOS Installation](#macos-installation)
3. [Arch Linux Installation](#arch-linux-installation)
4. [Debian/Ubuntu Installation](#debianubuntu-installation)
5. [Windows/WSL Installation](#windowswsl-installation)
6. [Post-Installation Steps](#post-installation-steps)
7. [Syncing Settings](#syncing-settings)
8. [Troubleshooting](#troubleshooting)

---

## Quick Start (TL;DR)

### Brand New Machine
```bash
# 1. Clone dotfiles
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 2. Run installer (auto-detects OS)
./install.sh

# 3. Follow prompts
# 4. Log out and back in
# 5. Done!
```

### Existing Dotfiles Setup
```bash
cd ~/.dotfiles
git pull
source ~/.zshrc  # Settings update immediately via symlinks
```

---

## macOS Installation

### Prerequisites
- macOS 12 (Monterey) or later
- Admin access
- Internet connection

### Step 1: Clone Dotfiles
```bash
# Open Terminal (Applications → Utilities → Terminal)
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### Step 2: Run Installer
```bash
./install.sh
```

**You'll be asked:**
```
Choose installation type:
  1) Minimal (recommended) - Git, GitHub CLI, SSH, dotfiles only
  2) Full - Installs many packages (not recommended)

Enter choice (1 or 2, default=1):
```

**Choose 1** (minimal)

### Step 3: What Gets Installed (Minimal)

✅ **Automatically installed:**
- Homebrew (if not present)
- Git
- GitHub CLI (gh)

✅ **Prompts you for:**
- Powerlevel10k theme (optional, say yes if you want nice terminal)
- SSH key generation (say yes)
- GitHub authentication (say yes)

✅ **Dotfiles linked:**
- `~/.gitconfig` → Git config with 40+ aliases
- `~/.zshrc` → Shell config
- `~/.ideavimrc` → Vim keybindings for WebStorm/IntelliJ
- `~/.p10k.zsh` → Powerlevel10k config (if installed)

### Step 4: Install Applications
```bash
./os/mac/install_optional.sh
```

**This will ask about each tool:**
- Docker (say yes if you use containers)
- Node/NVM (say yes)
- pnpm (say yes - faster npm)
- Yarn (optional)
- VS Code (say yes)
- Stripe CLI (only if you use it)
- Supabase CLI (only if you use it)
- AWS CLI (only if you use it)
- iTerm2 (optional - better terminal)
- Raycast (optional - Spotlight replacement)

### Step 5: Install Core Apps Manually
**These aren't in the scripts, install from websites:**

1. **Chrome**: https://www.google.com/chrome/
2. **WebStorm**: https://www.jetbrains.com/toolbox-app/
   - Install JetBrains Toolbox
   - Use Toolbox to install WebStorm
3. **Claude Code**: https://claude.ai/download
4. **Bitwarden**: https://bitwarden.com/download/
5. **NordPass**: https://nordpass.com/download/
6. **NordVPN**: https://nordvpn.com/download/
7. **Figma**: https://www.figma.com/downloads/
8. **Notion**: https://www.notion.so/desktop

### Step 6: Setup macOS Preferences (Optional)
```bash
./os/mac/setup_macos_preferences.sh
```

**This automates:**
- Fast keyboard repeat
- Show file extensions
- Better Finder defaults
- Faster Dock
- Development-friendly settings

### Step 7: Configure Applications

**WebStorm:**
1. Open WebStorm
2. Settings → Plugins → Search "IdeaVim" → Install
3. Restart WebStorm
4. Your `~/.ideavimrc` is automatically loaded

**Terminal (if using Powerlevel10k):**
```bash
p10k configure
```
Follow the wizard to customize your prompt.

**Sign into apps:**
- Bitwarden/NordPass
- NordVPN
- Claude Code
- Notion
- Figma

---

## Arch Linux Installation

### Prerequisites
- Fresh or existing Arch Linux install
- Base system installed (pacstrap completed)
- Internet connection
- User with sudo access

### Step 1: Clone Dotfiles
```bash
# Install git if not present
sudo pacman -S git

# Clone dotfiles
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### Step 2: Run Installer
```bash
./install.sh
```

**It will detect Arch and ask:**
```
Choose installer:
  1) Arch-specific (uses pacman/yay)
  2) Generic (uses apt - not recommended)
```

**Choose 1** (Arch-specific)

Or run directly:
```bash
./os/linux/install_arch.sh
```

### Step 3: Installation Flow

The installer will:

#### Phase 1: Essentials (Automatic)
✅ Installs without asking:
- git, github-cli, curl, wget, base-devel, openssh

#### Phase 2: Development Tools (Automatic)
✅ Installs without asking:
- docker, docker-compose
- nodejs, npm
- zsh
- nvm, pnpm (via yay)

Yay AUR helper is automatically installed if needed.

#### Phase 3: Oh My Zsh (Asks)
```
Install Oh My Zsh? (y/n)
```
**Say yes** - needed for Powerlevel10k

#### Phase 4: Nerd Fonts (Asks)
```
Install Nerd Fonts? (y/n)
```
**Say yes** - needed for terminal icons

Installs:
- Meslo Nerd Font
- FiraCode Nerd Font

#### Phase 5: Powerlevel10k (Asks)
```
Install Powerlevel10k theme? (y/n)
```
**Say yes** if you want a nice prompt

#### Phase 6: GUI Applications (Asks)
```
Install all GUI applications? (y/n)
```
**Say yes** to install:
- Google Chrome
- VS Code
- Claude Code (automated!)
- Bitwarden
- NordPass
- NordVPN
- Figma
- Notion

#### Phase 7: JetBrains Toolbox (Asks)
```
Install JetBrains Toolbox (for WebStorm)? (y/n)
```
**Say yes**

#### Phase 8: Optional Apps (Asks for each)
- Spotify
- Discord
- Slack
- Postman

Say yes to what you use.

#### Phase 9: Dotfiles (Automatic)
✅ Automatically:
- Clones dotfiles repo (if not present)
- Creates symlinks for all configs
- Backs up any existing files

#### Phase 10: SSH (Asks)
```
Generate SSH key? (y/n)
```
**Say yes**, then enter your email

#### Phase 11: GitHub CLI (Asks)
```
Authenticate with GitHub now? (y/n)
```
**Say yes**, follow the prompts

#### Phase 12: Docker & Zsh (Automatic)
✅ Automatically:
- Enables docker service
- Adds you to docker group
- Sets zsh as default shell

### Step 4: Log Out and Back In
**CRITICAL:** You must log out and back in for changes to take effect:
- Docker group membership
- Zsh as default shell

```bash
# Log out
exit
# Or reboot
sudo reboot
```

### Step 5: After Logging Back In

**Set terminal font:**
1. Open terminal preferences
2. Set font to: "MesloLGS Nerd Font" or "FiraCode Nerd Font"

**Configure Powerlevel10k:**
```bash
p10k configure
```

**Install WebStorm:**
1. Open JetBrains Toolbox
2. Install WebStorm
3. Open WebStorm
4. Settings → Plugins → Install "IdeaVim"
5. Restart WebStorm

**Sign into apps:**
- Bitwarden
- NordPass
- NordVPN
- Claude Code
- Notion
- Figma

### Step 6: Verify Installation
```bash
# Check git aliases
git aliases

# Check docker
docker --version
docker ps  # Should work without sudo

# Check node
node --version
nvm --version
pnpm --version

# Check zsh
echo $SHELL  # Should be /usr/bin/zsh
```

---

## Debian/Ubuntu Installation

### Prerequisites
- Ubuntu 20.04+ or Debian 11+
- Internet connection
- User with sudo access

### Step 1: Clone Dotfiles
```bash
# Install git
sudo apt update
sudo apt install git

# Clone dotfiles
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### Step 2: Run Installer
```bash
./install.sh
# Auto-detects Debian/Ubuntu
```

Or directly:
```bash
./os/linux/install.sh
```

### Step 3: What Gets Installed

**CLI Tools:**
- git, gh, docker.io, nodejs, npm, zsh, tmux
- nvm (via script), pnpm (via npm)

**Note:** GUI apps list is for Debian but many might not be available in apt.

**Recommended:** Install apps manually:
- Chrome: https://www.google.com/chrome/
- VS Code: https://code.visualstudio.com/
- Claude Code: https://claude.ai/download
- Bitwarden: https://bitwarden.com/download/
- etc.

### Step 4: Post-Install
Same as Arch:
- Log out and back in
- Configure terminal font
- Run `p10k configure`
- Sign into apps

---

## Windows/WSL Installation

### Important Notes
- **Install GUI apps on Windows side**, not in WSL
- Use WSL for CLI tools and development
- Docker Desktop provides WSL2 integration

### Step 1: Install WSL2
In PowerShell (admin):
```powershell
wsl --install
# Restart computer
```

### Step 2: Inside WSL
```bash
# Update system
sudo apt update && sudo apt upgrade

# Install git
sudo apt install git

# Clone dotfiles
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run installer
./install.sh
# Auto-detects WSL
```

### Step 3: Windows Side
Install these on **Windows**, not WSL:

**Via WinGet (PowerShell):**
```powershell
winget install Google.Chrome
winget install Microsoft.VisualStudioCode
winget install JetBrains.Toolbox
winget install Docker.DockerDesktop
winget install Bitwarden.Bitwarden
# etc.
```

**Or download from websites:**
- Same list as macOS section above

### Step 4: Docker Desktop
1. Install Docker Desktop on Windows
2. Open Docker Desktop
3. Settings → Resources → WSL Integration
4. Enable integration with your WSL distro

---

## Post-Installation Steps

### All Operating Systems

#### 1. Test Git Aliases
```bash
git aliases    # See all aliases
git st         # Test short status
git lg         # Test pretty log
```

#### 2. Configure Git
If not done during install:
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

#### 3. Test SSH
```bash
ssh-add -l  # List SSH keys
# If no keys, generate:
ssh-keygen -t ed25519 -C "your.email@example.com"
ssh-add ~/.ssh/id_ed25519
```

Add public key to GitHub:
```bash
cat ~/.ssh/id_ed25519.pub
# Copy output and add to https://github.com/settings/keys
```

#### 4. Test GitHub CLI
```bash
gh auth status
# If not authenticated:
gh auth login
```

#### 5. Configure Claude Code
```bash
# If you want to sync settings:
# See config/claude/README.md for instructions
```

#### 6. Configure WebStorm
- Install IdeaVim plugin
- Your ~/.ideavimrc is automatically loaded
- See CONFIG_GUIDE.md for keybindings reference

---

## Syncing Settings

### Between Machines

**First machine:**
```bash
cd ~/.dotfiles
# Make changes to configs
git add .
git commit -m "Update settings"
git push
```

**Other machines:**
```bash
cd ~/.dotfiles
git pull
# Settings update immediately via symlinks!
source ~/.zshrc  # Reload shell if needed
```

### What Gets Synced
✅ **Automatically via symlinks:**
- Git config and aliases
- Zsh config
- IdeaVim config
- Powerlevel10k config

❌ **Manually sync:**
- GUI app settings (Bitwarden, etc.)
- WebStorm settings (use built-in sync)
- Claude Code settings (see config/claude/README.md)

---

## Troubleshooting

### macOS: "Homebrew not found"
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add to PATH
eval "$(/opt/homebrew/bin/brew shellenv)"  # Apple Silicon
eval "$(/usr/local/bin/brew shellenv)"      # Intel Mac
```

### Arch: "yay not found"
```bash
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```

### Linux: "Docker permission denied"
```bash
# Add yourself to docker group
sudo usermod -aG docker $USER

# Log out and back in
exit
```

### Any OS: "Symlink failed"
```bash
# Remove existing file
rm ~/.zshrc

# Re-run symlink
cd ~/.dotfiles
ln -sf ~/.dotfiles/config/zsh/.zshrc ~/.zshrc
```

### Powerlevel10k not loading
**Check installation:**
```bash
# macOS
brew list powerlevel10k

# Linux
ls -la ~/.oh-my-zsh/custom/themes/powerlevel10k
```

**Reinstall if needed:**
```bash
# macOS
brew install powerlevel10k

# Linux
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
```

Then:
```bash
source ~/.zshrc
p10k configure
```

---

## Next Steps After Installation

1. ✅ Read QUICKSTART.md for git aliases
2. ✅ Read CONFIG_GUIDE.md for configuration details
3. ✅ Customize ~/.zshrc.local for machine-specific settings
4. ✅ Star this repo to remember where it is!
5. ✅ Enjoy your consistent development environment! 🎉

---

**Need Help?**
- Check INSTALLATION_GUIDE.md for detailed reference
- Check TROUBLESHOOTING.md (if it exists)
- Check individual config README files

**Found a Bug?**
- Open an issue on GitHub
- Or fix it and submit a PR!

---

**Last Updated:** 2025-11-04
**Tested On:** macOS 14, Arch Linux, Ubuntu 22.04, Windows 11 WSL2
