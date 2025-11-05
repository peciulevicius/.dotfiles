# Quick Start Guide

## TL;DR - For Your Mac Right Now

```bash
# Clone the repo
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run the installer (will ask for minimal or full)
./install.sh

# Choose option 1 (minimal) - installs only:
# ✓ Homebrew (if needed)
# ✓ Git + GitHub CLI
# ✓ SSH key setup
# ✓ Dotfiles (git config, zshrc, IdeaVim)
# ✓ Starship prompt (modern, fast)
```

That's it! Everything else can be installed later when you need it.

---

## What Gets Installed (Minimal Setup)

### Essentials Only
- **Homebrew** - Package manager (if not installed)
- **Git** - Version control
- **GitHub CLI** - `gh` command
- **SSH Keys** - Prompts to generate if needed

### Dotfiles Linked
- `~/.gitconfig` - Git configuration with tons of useful aliases
- `~/.zshrc` - Shell configuration with Starship prompt
- `~/.ideavimrc` - Vim keybindings for WebStorm
- `~/.config/starship.toml` - Starship prompt configuration

### What's NOT Installed
- ❌ Docker
- ❌ Node/NVM
- ❌ Stripe CLI
- ❌ Supabase
- ❌ Angular CLI
- ❌ Neovim
- ❌ GUI apps

**You can install these later** with `os/mac/install_optional.sh`

---

##Actually Useful Git Aliases

After setup, try these:

```bash
# Status
git st               # Short status with branch info
git s                # Full status

# Adding & Committing
git aa               # Add all changes
git ac "message"     # Add all and commit
git amend            # Amend last commit (no message change)
git undo             # Undo last commit, keep changes

# Branching
git cob feature      # Create and checkout new branch
git main             # Quick switch to main

# Logs
git lg               # Beautiful log graph
git tree             # Quick tree view
git today            # Today's commits

# Diffing
git d                # Show unstaged changes
git ds               # Show staged changes

# Cleanup
git cleanup          # Delete all merged branches

# See all aliases
git aliases
```

---

## Optional: Install More Tools Later

When you actually need them:

```bash
cd ~/.dotfiles

# Interactive installer - asks for each tool
./os/mac/install_optional.sh

# Or install individually:
brew install docker
brew install nvm
npm install -g @angular/cli
```

---

## Optional: Setup macOS Preferences

Automate those annoying System Preferences:

```bash
cd ~/.dotfiles
./os/mac/setup_macos_preferences.sh
```

This sets up:
- Fast key repeat
- Show all file extensions
- Better Finder defaults
- Faster Dock animations
- Development-friendly settings

---

## Zsh & Starship Prompt

**Good news**: The .zshrc comes with Starship, a modern cross-shell prompt!

### Starship Features
Beautiful, customizable prompt with icons:
```
~/code/project on main [!?] via 🦀 v1.70.0
❯
```

Shows: directory + git branch + git status + language versions

### Customize Your Prompt

**Edit the config:**
```bash
vim ~/.config/starship.toml
# Or
vim ~/.dotfiles/config/starship/starship.toml
```

**See all presets:**
```bash
starship preset -l
```

### Fallback Prompt
If Starship isn't installed, you get a clean basic prompt:
```
~/code/project (main) ❯
```

---

## Customization

### Add Your Own Aliases

Edit `~/.zshrc` or create `~/.zshrc.local`:

```bash
# ~/.zshrc.local (not tracked in git)
alias myproject="cd ~/code/my-project"
export MY_API_KEY="..."
```

### Modify Git Config

Edit `config/git/.gitconfig` in the repo, then:
```bash
cd ~/.dotfiles
git pull  # Get latest
source ~/.zshrc  # Reload
```

---

## Will It Override My Existing Config?

**No!** The installer:
1. ✅ Backs up existing files (creates `.backup` files)
2. ✅ Creates symlinks to dotfiles repo
3. ✅ Checks if things are already installed
4. ✅ Asks before installing optional things

Example:
```
~/.zshrc → ~/.zshrc.backup
~/.zshrc → symlink to ~/.dotfiles/config/zsh/.zshrc
```

To restore originals:
```bash
mv ~/.zshrc.backup ~/.zshrc
```

---

## Different Machines

### Your Mac (what you have now)
```bash
cd ~/.dotfiles
./install.sh
# Choose: 1) Minimal
```

### Work Machine (maybe need more)
```bash
cd ~/.dotfiles
./install.sh
# Choose: 1) Minimal
# Then run optional installer
./os/mac/install_optional.sh
```

### Linux (Arch)
```bash
cd ~/.dotfiles
./install.sh
# Auto-detects Arch, uses pacman/yay
```

### WSL
```bash
cd ~/.dotfiles
./install.sh
# Auto-detects WSL
```

---

## Updating Dotfiles

```bash
cd ~/.dotfiles
git pull
source ~/.zshrc  # Reload shell config
```

Changes are immediately reflected via symlinks!

---

## Troubleshooting

### Starship prompt not loading
```bash
# Check if Starship is installed
which starship

# Install if needed
brew install starship  # macOS
# or
pacman -S starship     # Arch Linux
# or
apt install starship   # Ubuntu/Debian

# Reload shell
source ~/.zshrc
```

### Git aliases not working
```bash
git config --global --list | grep alias
# Should show lots of aliases

# If not, reload:
cd ~/.dotfiles
rm ~/.gitconfig
./os/mac/install_minimal.sh  # Re-run to recreate symlink
```

### Want to start over
```bash
# Remove symlinks
rm ~/.zshrc ~/.gitconfig ~/.ideavimrc ~/.config/starship.toml

# Restore backups
mv ~/.zshrc.backup ~/.zshrc
# (if backups exist)

# Or just re-run installer
cd ~/.dotfiles
./install.sh
```

---

## Questions?

**"Do I need Oh My Zsh?"**
No! The .zshrc works without it.

**"Can I customize the Starship prompt?"**
Yes! Edit `~/.config/starship.toml` - it's easy TOML configuration.

**"Should I install all those CLI tools?"**
No! Only install what you actually use.

**"Will this slow down my shell?"**
No! Minimal setup is fast. Starship is blazing fast (written in Rust).

**"Can I use this with VS Code?"**
Yes! The git config works everywhere. IdeaVim is for WebStorm/IntelliJ.

---

## What's Actually Worth It?

Based on your usage (Mac Terminal + WebStorm):

### Must Have ✅
- Git config with aliases (huge time saver)
- IdeaVim config for WebStorm (those keybindings!)
- SSH key setup (one less thing to remember)

### Nice to Have 👍
- Starship prompt (beautiful, included by default)
- macOS preferences script (saves manual clicking)
- Zsh aliases (small conveniences)

### Skip for Now ⏭️
- Docker (install when needed)
- CLI tools (install per-project)
- Neovim (you don't use it)

---

**Ready to go? Just run:**
```bash
cd ~/.dotfiles && ./install.sh
```
