# Installation Scripts Documentation

## Current Script Comparison (macOS)

### install_minimal.sh
**Philosophy**: Bare minimum to get dotfiles working

**Installs:**
- Homebrew (package manager)
- Git
- GitHub CLI (gh)
- Optional: Powerlevel10k theme

**Symlinks:**
- ~/.gitconfig
- ~/.zshrc
- ~/.ideavimrc
- ~/.p10k.zsh

**Interactive:**
- Asks if you want Powerlevel10k
- Prompts for SSH key generation
- Prompts for GitHub authentication

**What's NOT included:**
- No GUI apps
- No Docker
- No Node/NVM
- No development tools beyond git

---

### install_optional.sh
**Philosophy**: Install additional tools interactively

**Asks about each:**
- Docker
- Node Version Manager (nvm)
- pnpm
- Yarn
- Stripe CLI
- Supabase CLI
- AWS CLI
- Visual Studio Code
- Neovim
- iTerm2
- Raycast

**Why separate?**
- So you can install only what you need
- Can be run multiple times
- Non-destructive

---

### install.sh (full)
**Philosophy**: Install everything (old approach - too much!)

**Installs:**
- All packages from minimal
- vim, neovim
- tmux, docker
- nvm, node, npm, gh
- thefuck, pnpm, yarn
- tree-sitter
- stripe-cli
- supabase
- angular-cli

**GUI Apps (commented out):**
- iTerm2, Raycast
- Spotify, Notion
- WebStorm, VS Code
- Many more

**Problems:**
- Installs too much you don't need
- Can't choose what to install
- Slow
- Includes apps you'll never use

---

## Your Actual Needs (Cross-Platform)

Based on your usage, you need:

### Essential CLI Tools
- git
- gh (GitHub CLI)
- docker
- node/npm (via nvm)

### Development IDEs/Editors
- WebStorm
- VS Code (sometimes)
- Claude Code (new!)

### Productivity Apps
- Google Chrome
- NordPass
- NordVPN
- Figma
- Notion (maybe?)

### Platform-Specific Notes

**macOS:**
- WebStorm: Via JetBrains Toolbox or direct download
- Claude Code: Available for Mac

**Linux (Arch):**
- WebStorm: Via AUR or Snap
- Chrome: google-chrome (AUR)
- Claude Code: Available for Linux
- Some apps might be Flatpak

**Windows/WSL:**
- Install GUI apps on Windows side
- Use WSL for development tools

---

## What Should Be Unified?

### Cross-Platform CLI Tools
These should install on ALL systems:
- git + git config
- GitHub CLI
- Docker
- Node/NVM
- SSH keys
- zsh config
- IdeaVim config

### Cross-Platform GUI Apps
These should install on ALL systems (where available):
- Google Chrome
- WebStorm
- VS Code
- Claude Code
- NordPass
- NordVPN
- Figma
- Docker Desktop

### What Should Be Optional?
Tools you might not need on every machine:
- Stripe CLI
- Supabase CLI
- Angular CLI
- AWS CLI
- Specific language tools

---

## Proposed New Structure

### 1. `install_essentials.sh` (All OS)
**What:** Dotfiles + Git + SSH
**Why:** Always needed

Installs:
- Git + config
- SSH keys
- Symlink dotfiles
- GitHub CLI

### 2. `install_developer.sh` (All OS)
**What:** Developer tools
**Why:** Your consistent dev environment

Installs:
- Docker
- Node/NVM
- Your zsh config
- Dev tools

### 3. `install_apps.sh` (All OS)
**What:** GUI applications
**Why:** Your consistent app environment

Installs:
- Google Chrome
- WebStorm
- VS Code
- Claude Code
- NordPass
- NordVPN
- Figma

### 4. `install_optional.sh` (All OS)
**What:** Project-specific tools
**Why:** Not always needed

Asks about:
- Stripe CLI
- Supabase CLI
- Angular CLI
- AWS CLI
- Language-specific tools

---

## macOS Preferences Script

**File:** `setup_macos_preferences.sh`

**What it does:**
- Fast keyboard repeat
- Show all file extensions
- Better Finder defaults (path bar, status bar, etc.)
- Better Dock settings
- Better Safari defaults
- Terminal settings
- Activity Monitor defaults
- Screenshot settings
- TextEdit defaults

**Why separate?**
- macOS-specific
- Modifies system preferences
- Can be run anytime
- Non-destructive (can be reverted)

**Should this be cross-platform?**
- No - these are macOS system preferences
- Linux equivalent would be GNOME/KDE settings
- Windows equivalent would be Registry settings
- Too OS-specific to unify

---

## Questions & Answers

### "Shouldn't it all be for all OS?"

**Dotfiles & Config: YES**
- .gitconfig ✅
- .zshrc ✅
- .ideavimrc ✅

**CLI Tools: MOSTLY YES**
- git, gh, docker, node ✅
- Some tools have different package names per OS

**GUI Apps: YES with caveats**
- Chrome, WebStorm, VS Code ✅ (available everywhere)
- NordPass, NordVPN ✅ (available everywhere)
- Figma ✅ (available everywhere)
- Claude Code ✅ (available everywhere)
- Installation method differs (brew vs pacman vs apt)

**System Preferences: NO**
- Too OS-specific
- Different APIs/settings per OS

### "What are the differences?"

Current scripts:
- **minimal**: Only git + dotfiles
- **optional**: Interactive tool installer
- **full**: Everything (too much)

Proposed scripts:
- **essentials**: Dotfiles + Git + SSH (always run)
- **developer**: Your dev environment (run on all dev machines)
- **apps**: Your GUI apps (run on all machines)
- **optional**: Project-specific tools (run when needed)

---

## What You Should Have

### On ALL machines (Mac, Arch, WSL):

**CLI Tools:**
- git + your .gitconfig
- GitHub CLI
- Docker
- Node/NVM
- zsh + your .zshrc

**GUI Apps (Mac & Arch, not WSL):**
- Google Chrome
- WebStorm
- VS Code
- Claude Code
- NordPass
- NordVPN
- Figma

### Optional (install per-project):
- Stripe CLI
- Supabase CLI
- Angular CLI
- AWS CLI

---

## Next Steps

I can create:

1. **Unified package lists** - Same tools across all OS
2. **Better Arch installer** - With your actual GUI apps
3. **Developer profile** - One command to install your environment
4. **Comprehensive docs** - What's installed, where, why

Would you like me to:
- Create a unified "developer setup" that installs the same things on Mac/Linux/Arch?
- Update the Arch installer with Chrome, WebStorm, Claude Code, NordPass, etc.?
- Create a config file where you list your apps once, and it installs them everywhere?
