# Complete Installation Guide

## Your Development Environment - Consistent Across All Machines

This guide explains what gets installed where and how to keep all your machines in sync.

---

## 🎯 What You Get

### CLI Tools (All Machines)
- **Git** + your custom .gitconfig with 40+ aliases
- **GitHub CLI** (gh) for GitHub operations
- **Docker** for containerization
- **Node.js/npm** via nvm for version management
- **pnpm** - fast npm alternative
- **zsh** with your custom .zshrc

### GUI Applications (Mac & Arch, not WSL)
- **Google Chrome** - Browser
- **WebStorm** - Main IDE (via JetBrains Toolbox)
- **VS Code** - Secondary editor
- **Claude Code** - AI assistant
- **NordPass** - Password manager
- **NordVPN** - VPN
- **Figma** - Design tool
- **Notion** - Notes/docs

### Dotfiles (All Machines)
- `~/.gitconfig` - Git configuration
- `~/.zshrc` - Shell configuration
- `~/.ideavimrc` - Vim keybindings for WebStorm/IntelliJ
- Starship config at `~/.dotfiles/config/starship/starship.toml`

---

## 📦 Installation by Operating System

### macOS

#### Option 1: Minimal (Recommended First Time)
```bash
cd ~/.dotfiles
./install.sh  # Choose option 1
```

**Installs:**
- Homebrew
- Git + GitHub CLI
- SSH key setup
- Dotfiles (symlinks)
- Starship prompt (included)

**Then install your apps:**
```bash
./os/mac/install_optional.sh
```

#### Option 2: Everything (if you know what you want)
Just say yes to everything in `install_optional.sh`

**Package Manager:** Homebrew
```bash
brew install git gh docker nvm
brew install --cask google-chrome visual-studio-code webstorm
```

---

### Arch Linux

```bash
cd ~/.dotfiles
./install.sh  # Auto-detects Arch, offers Arch-specific installer
# OR directly:
./os/linux/install_arch.sh
```

**Installs:**
- Essential CLI tools (git, gh, curl, openssh)
- Development tools (docker, node, npm, zsh, nvm, pnpm)
- GUI applications (Chrome, VS Code, NordPass, NordVPN, Figma, Notion)
- JetBrains Toolbox (for WebStorm)
- Dotfiles
- SSH keys
- GitHub authentication

**Package Managers:**
- `pacman` for official packages
- `yay` for AUR packages (auto-installed if needed)

**Example packages:**
```bash
# Official repos
sudo pacman -S git github-cli docker nodejs

# AUR (via yay)
yay -S google-chrome visual-studio-code-bin nordpass-bin figma-linux
```

**Notes:**
- WebStorm installed via JetBrains Toolbox
- Claude Code downloaded manually from claude.ai/download

---

### Ubuntu/Debian

```bash
cd ~/.dotfiles
./install.sh  # Auto-detects, uses apt
# OR directly:
./os/linux/install.sh
```

**Installs:**
- Similar to Arch but uses `apt`
- Some apps via snap or flatpak
- May need to add PPAs for some packages

**Package Manager:** apt
```bash
sudo apt update
sudo apt install git gh docker.io nodejs npm
```

---

### Windows/WSL

```bash
cd ~/.dotfiles
./install.sh  # Auto-detects WSL
```

**Important:**
- Install GUI apps on **Windows side**, not in WSL
- Use WSL for CLI tools and development
- Docker Desktop provides WSL2 integration

**WSL installs:**
- CLI tools only
- Dotfiles
- Development environment

**Windows installs (separate):**
- GUI applications
- Docker Desktop
- IDEs

---

## 🔧 What Each Script Does

### Main Scripts

#### `install.sh` (Root directory)
**Purpose:** Auto-detect OS and run appropriate installer

**Behavior:**
- Detects: macOS, Linux (Arch or Debian), WSL, Windows
- On **macOS**: Asks minimal or full
- On **Arch**: Offers Arch-specific installer
- On **other Linux**: Uses generic installer

#### `os/mac/install_minimal.sh`
**Purpose:** Essential macOS setup only

**Installs:**
- Homebrew
- Git
- GitHub CLI
- Starship prompt (included)

**Skips:**
- All GUI apps
- Docker
- Node/development tools

**Use when:** First time setup or you want to install apps manually

#### `os/mac/install_optional.sh`
**Purpose:** Interactive tool installer

**Asks about:**
- Docker
- Node/NVM
- pnpm, Yarn
- VS Code
- iTerm2
- Raycast
- Stripe CLI
- Supabase CLI
- AWS CLI

**Use when:** You need additional tools

#### `os/mac/install.sh` (Full)
**Purpose:** Install everything (old approach)

**Installs:** EVERYTHING - not recommended unless you want it all

#### `os/mac/setup_macos_preferences.sh`
**Purpose:** Automate macOS system preferences

**Changes:**
- Keyboard repeat rate (faster)
- Finder settings (show extensions, path bar)
- Dock settings (size, animations)
- Safari defaults
- Screenshot settings
- And 20+ more tweaks

**Use when:** New Mac or after fresh install

#### `os/linux/install_arch.sh`
**Purpose:** Complete Arch Linux setup

**Installs:**
- Everything you need to match your Mac environment
- Yay AUR helper (if needed)
- All CLI tools
- All GUI apps (asks first)
- JetBrains Toolbox
- Dotfiles and SSH

**Use when:** Setting up Arch Linux machine

#### `os/linux/install.sh`
**Purpose:** Generic Linux installer (Debian/Ubuntu)

**Installs:**
- Similar to Arch but uses apt
- May not have all GUI apps in repos

---

## 🗂️ Configuration Files

### `packages.conf`
**Purpose:** Central package list for all OS

**Contains:**
- Essential packages
- Developer tools
- GUI applications
- Optional tools
- Package names per OS

**Why:** Single source of truth for what to install

**Future:** Could be parsed by scripts to generate installer commands

### `SCRIPTS_EXPLAINED.md`
**Purpose:** Detailed comparison of all scripts

**Contains:**
- What's in each script
- Differences between minimal/optional/full
- Your actual needs vs what scripts install
- Proposed improvements

### `QUICKSTART.md`
**Purpose:** TL;DR guide for your Mac

**Contains:**
- Quick setup instructions
- Git aliases cheat sheet
- Troubleshooting

---

## 🎨 Customization

### Modify Package Lists

**Arch Linux:**
Edit `os/linux/install_arch.sh`:
```bash
# Add to GUI apps section
AUR_APPS=(
  google-chrome
  visual-studio-code-bin
  your-new-app  # Add here
)
```

**macOS:**
Edit `os/mac/install_optional.sh`:
```bash
install_if_confirmed "Your App" \
  "brew install --cask your-app" \
  "test -d /Applications/YourApp.app"
```

### Add Custom Aliases

Create `~/.zshrc.local` (not tracked in git):
```bash
# Personal stuff not in dotfiles
alias myproject="cd ~/code/my-project"
export MY_SECRET_KEY="..."
```

Your `~/.zshrc` automatically loads this if it exists.

### Modify Git Config

Edit `config/git/.gitconfig` in the repo:
```bash
cd ~/.dotfiles
# Edit config/git/.gitconfig
git add config/git/.gitconfig
git commit -m "Add my custom alias"
git push
```

On other machines:
```bash
cd ~/.dotfiles
git pull  # Config updates immediately via symlink!
```

---

## 🔄 Keeping Machines in Sync

### Initial Setup on New Machine

```bash
# 1. Clone dotfiles
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 2. Run installer (auto-detects OS)
./install.sh

# 3. For Arch: install GUI apps
#    For Mac: run optional installer
#    For WSL: install Windows apps separately
```

### Updating Existing Machine

```bash
cd ~/.dotfiles
git pull

# Reload shell config
source ~/.zshrc

# If packages added, re-run installer
./install.sh  # Safe to re-run, checks what's installed
```

### Adding New Tool to All Machines

1. **Test on one machine:**
   ```bash
   brew install new-tool  # or yay -S new-tool
   ```

2. **If you like it, add to scripts:**
   - Edit relevant install script
   - Add to DEVELOPER_CLI or AUR_APPS array
   - Commit and push

3. **Install on other machines:**
   ```bash
   cd ~/.dotfiles
   git pull
   ./install.sh  # Or re-run specific script
   ```

---

## 🆘 Troubleshooting

### Script Fails on Mac
```bash
# Check Homebrew
brew doctor

# Re-run installer
cd ~/.dotfiles
./install.sh
```

### Script Fails on Arch
```bash
# Update system first
sudo pacman -Syu

# Check yay
yay --version

# If yay missing, manually install:
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# Re-run installer
cd ~/.dotfiles
./os/linux/install_arch.sh
```

### Dotfiles Not Updating
```bash
# Check if symlinked
ls -la ~/.gitconfig ~/.zshrc ~/.ideavimrc

# Should show -> ~/.dotfiles/config/...

# If not, re-run setup_symlinks function
cd ~/.dotfiles
# Run just the symlink part of installer
```

### Apps Not Installing on Arch
```bash
# Update package database
yay -Sy

# Try installing individually
yay -S google-chrome visual-studio-code-bin

# Check AUR package name
yay -Ss chrome  # Search for packages
```

---

## 💡 Tips & Tricks

### Use Git Aliases
```bash
git aliases    # See all aliases
git st         # Short status
git lg         # Pretty log
git undo       # Undo last commit
git cleanup    # Delete merged branches
```

### Quick Server
```bash
serve         # Start HTTP server on port 8000
serve 3000    # Custom port
```

### Extract Archives
```bash
extract file.tar.gz
extract file.zip
# Works with any common archive format
```

### macOS Specific
```bash
brewup        # Update all Homebrew packages
flushdns      # Clear DNS cache
showfiles     # Show hidden files in Finder
finder        # Open current directory in Finder
```

---

## 📋 Checklist for New Machine

### Mac
- [ ] Clone dotfiles repo
- [ ] Run `./install.sh` (choose minimal)
- [ ] Run `./os/mac/install_optional.sh`
- [ ] Run `./os/mac/setup_macos_preferences.sh`
- [ ] Install WebStorm via JetBrains Toolbox
- [ ] Download Claude Code from claude.ai
- [ ] Sign into NordPass
- [ ] Sign into NordVPN
- [ ] Configure WebStorm (enable IdeaVim plugin)
- [ ] Starship is configured automatically

### Arch Linux
- [ ] Clone dotfiles repo
- [ ] Run `./os/linux/install_arch.sh`
- [ ] Say yes to GUI apps
- [ ] Download Claude Code from claude.ai
- [ ] Install WebStorm via JetBrains Toolbox
- [ ] Sign into NordPass
- [ ] Sign into NordVPN
- [ ] Configure WebStorm (enable IdeaVim plugin)
- [ ] Log out and back in (for docker group, zsh)
- [ ] Customize Starship: `vim ~/.dotfiles/config/starship/starship.toml`

### WSL
- [ ] Clone dotfiles repo in WSL
- [ ] Run `./install.sh` (detects WSL)
- [ ] Install GUI apps on Windows side
- [ ] Install Docker Desktop on Windows
- [ ] Enable WSL2 integration in Docker Desktop
- [ ] Test docker commands in WSL

---

## 🤔 FAQ

**Q: Do I need to install everything?**
A: No! The Arch script asks before installing GUI apps. Mac has minimal option.

**Q: Can I customize the Starship prompt?**
A: Script asks. If you skip it, you get a clean basic prompt. Works great!

**Q: Can I use this with Oh My Zsh?**
A: Yes, but not required. The .zshrc works standalone or with Oh My Zsh.

**Q: What about Windows (not WSL)?**
A: Use the PowerShell installer in `os/windows/install.ps1`

**Q: How do I remove Claude Code from the list?**
A: It's already manual - just skip when prompted. Not auto-installed.

**Q: Different apps on different machines?**
A: Sure! Just don't run the GUI apps installer, install manually instead.

**Q: Can I have machine-specific config?**
A: Yes! Create `~/.zshrc.local` for machine-specific stuff.

---

## 📚 See Also

- `QUICKSTART.md` - Quick start guide for Mac
- `SCRIPTS_EXPLAINED.md` - Detailed script comparison
- `CONFIG_GUIDE.md` - Configuration file documentation
- `README.md` - General overview
- `packages.conf` - Package list reference

---

**Last Updated:** 2025-11-04
**Supports:** macOS, Arch Linux, Debian/Ubuntu, WSL
