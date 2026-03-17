# .dotfiles

> Modern, cross-platform dotfiles with comprehensive tooling for macOS, Linux (Arch, Debian/Ubuntu, Kali), and Windows/WSL.

## ✨ Features

- 🚀 **Modern CLI Tools** - bat, eza, ripgrep, fd, fzf, zoxide, tlrc/tldr, httpie, jq, delta
- 🎨 **Beautiful Shell** - Zsh with Starship (modern, fast, cross-shell prompt)
- ⚙️ **Comprehensive Configs** - Git (40+ aliases), SSH, Tmux, EditorConfig, and more
- 🛠️ **Utility Scripts** - Update, backup, cleanup, and health check tools
- 🐳 **Self-Hosted Services** - 13 Docker Compose stacks: Immich, Vaultwarden, Nextcloud, Ollama, and more
- 📓 **Knowledge Management** - Obsidian vault setup with PARA structure, Syncthing sync, Kindle highlights
- ☁️ **Cloud Backup** - Rclone → Backblaze B2 with automatic Docker volume backup
- 📦 **Smart Installers** - OS-specific automated setup for all platforms
- 📚 **Complete Documentation** - Every feature thoroughly documented in `docs/`
- 🔐 **Security** - GPG commit signing, modern SSH (ed25519), proper .gitignore

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run the installer (automatically detects your OS)
./install.sh
```

**That's it!** The installer will guide you through the setup process.

For guided onboarding, start with [docs/START_HERE.md](docs/START_HERE.md).
For a detailed walkthrough, see [docs/HOW_TO_INSTALL.md](docs/HOW_TO_INSTALL.md).

## 🖥️ Supported Platforms

| Platform | Support | Installer |
|----------|---------|-----------|
| **macOS** (12+) | ✅ Full | `os/mac/install.sh` |
| **Arch Linux** | ✅ Full | `os/linux/install_arch.sh` |
| **Ubuntu/Debian** | ✅ Full | `os/linux/install_ubuntu.sh` |
| **Kali Linux** | ✅ Full | `os/linux/install_ubuntu.sh` |
| **Windows** | ✅ Claude + packages | `scripts/setup-claude.ps1`, `scripts/update.ps1` |
| **Windows/WSL** | ⚠️ Shell tools | `os/windows/install_wsl.sh` |

macOS non-interactive mode:

```bash
./os/mac/install.sh --yes
```

## 📦 What Gets Installed

### Modern CLI Tools

These modern alternatives significantly improve your terminal experience:

| Instead of | Use | Why |
|------------|-----|-----|
| `cat` | `bat` | Syntax highlighting, line numbers, Git integration |
| `ls` | `eza` | Colors, icons, Git status, tree view |
| `grep` | `rg` (ripgrep) | 10x faster, respects .gitignore |
| `find` | `fd` | Simpler syntax, faster, colored output |
| History search | `fzf` | Interactive fuzzy finder (Ctrl+R) |
| `cd` | `z` (zoxide) | Smart jump to frequent directories |
| `man` | `tldr` (via `tlrc`) | Practical examples, not walls of text |
| `curl` | `http` (httpie) | Intuitive syntax for APIs |
| JSON parsing | `jq` | Powerful JSON manipulation |
| `git diff` | `delta` | Syntax-highlighted diffs |

See [docs/MODERN_CLI_TOOLS.md](docs/MODERN_CLI_TOOLS.md) for detailed usage guide.

### Development Tools

- **Git** with 40+ useful aliases and optional GPG signing
- **Docker** + Docker Compose
- **Node.js** via nvm, plus npm and pnpm
- **GitHub CLI** (gh) for GitHub operations
- **VS Code**, Claude Code (automated on Arch)
- **JetBrains Toolbox** for WebStorm/IntelliJ

### Configuration Files

All configs are in `config/` and automatically symlinked:

- **Git** - `.gitconfig`, `.gitignore_global`, `.gitmessage` (commit template)
- **Shell** - `.zshrc` with platform detection and modern aliases
- **SSH** - `config` template with examples for multiple accounts
- **Tmux** - `.tmux.conf` with vim-style keybindings
- **Editor** - `.editorconfig` for consistent coding styles
- **IdeaVim** - `.ideavimrc` for vim bindings in JetBrains IDEs
- **Claude Code** - Settings sync template

See [docs/CONFIG_GUIDE.md](docs/CONFIG_GUIDE.md) for details.

### Utility Scripts

Powerful scripts to maintain your environment:

**macOS / Linux:**
```bash
~/.dotfiles/scripts/update.sh      # Update all package managers + Claude Code
~/.dotfiles/scripts/backup.sh      # Backup all configs and package lists
~/.dotfiles/scripts/cleanup.sh     # Free disk space (cleans Docker, npm, etc.)
~/.dotfiles/scripts/dev-check.sh   # Health check your dev environment
~/.dotfiles/scripts/setup-gpg.sh   # Set up GPG commit signing
```

**Windows (PowerShell):**
```powershell
.\scripts\update.ps1               # Update winget, npm, pnpm, Claude Code
.\scripts\setup-claude.ps1         # Set up Claude Code config
```

See [docs/UTILITY_SCRIPTS.md](docs/UTILITY_SCRIPTS.md) for detailed usage.

## 📁 Repository Structure

```
.dotfiles/
├── README.md                    # You are here
├── install.sh                   # Main installer (auto-detects OS)
│
├── docs/                        # 📚 Complete documentation
│   ├── README.md                # Documentation index
│   ├── QUICKSTART.md            # TL;DR guide
│   ├── HOW_TO_INSTALL.md        # Complete installation guide
│   ├── CONFIG_GUIDE.md          # Configuration details
│   ├── MODERN_CLI_TOOLS.md      # CLI tools guide
│   └── UTILITY_SCRIPTS.md       # Scripts documentation
│
├── config/                      # ⚙️ Configuration files
│   ├── git/                     # Git config & global ignores
│   ├── zsh/                     # Zsh configuration
│   ├── starship/                # Starship prompt config
│   ├── ssh/                     # SSH config template
│   ├── tmux/                    # Tmux configuration
│   ├── curl/                    # Curl preferences
│   ├── claude/                  # Claude Code settings
│   ├── idea/                    # IdeaVim configuration
│   └── .editorconfig            # EditorConfig
│
├── os/                          # 💻 OS-specific installers
│   ├── mac/                     # macOS installers
│   │   ├── install.sh           # Unified macOS installer (primary)
│   │   └── setup_macos_preferences.sh # Optional macOS defaults
│   ├── linux/                   # Linux installers
│   │   ├── install_arch.sh      # Arch Linux (full featured)
│   │   ├── install_ubuntu.sh    # Ubuntu/Debian/Kali
│   │   └── install.sh           # Generic Linux (legacy)
│   └── windows/                 # Windows/WSL
│       └── install_wsl.sh       # WSL setup
│
├── scripts/                     # 🛠️ Utility scripts
│   ├── update.sh                # Update everything
│   ├── backup.sh                # Backup configs
│   ├── cleanup.sh               # Clean caches
│   ├── dev-check.sh             # Health check
│   ├── setup-gpg.sh             # GPG setup
│   └── setup-obsidian.sh        # Obsidian vault setup
│
└── services/                    # 🐳 Self-hosted Docker Compose stacks
    ├── setup-services.sh        # Stage all stacks to ~/docker/
    ├── immich/                  # Google Photos replacement
    ├── vaultwarden/             # Bitwarden password manager
    ├── nextcloud/               # Google Drive replacement
    ├── ollama/                  # Local LLM inference
    ├── syncthing/               # File sync
    └── rclone/rclone-backup.sh  # Cloud backup (B2/S3)
```

## 🎯 Common Tasks

### Install on New Machine

```bash
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh
```

### Update Everything

```bash
~/.dotfiles/scripts/update.sh
# Updates: Homebrew, apt/pacman, npm, pnpm, pip, Rust, Oh My Zsh, dotfiles
```

### Backup Your Configs

```bash
~/.dotfiles/scripts/backup.sh
# Creates: ~/dotfiles_backup_YYYYMMDD_HHMMSS.tar.gz
```

### Clean Up Disk Space

```bash
~/.dotfiles/scripts/cleanup.sh
# Cleans: Docker, npm cache, Homebrew, apt, system caches, temp files
```

### Check Environment Health

```bash
~/.dotfiles/scripts/dev-check.sh
# Verifies: All tools installed, configs present, SSH keys, GitHub auth
```

### Set Up GPG Commit Signing

```bash
~/.dotfiles/scripts/setup-gpg.sh
# Sets up GPG for verified commits on GitHub
```

## 💡 Useful Git Aliases

This repo includes 40+ git aliases. Here are the most useful ones:

```bash
git st               # Short status
git br               # List branches
git lg               # Beautiful log graph
git ac "message"     # Add all and commit
git amend            # Amend last commit
git undo             # Undo last commit (keeps changes)
git sync             # Pull and push
git cleanup          # Remove merged branches
git aliases          # Show all aliases
```

See [docs/CONFIG_GUIDE.md](docs/CONFIG_GUIDE.md) for the complete list.

## 📚 Documentation

All documentation is in the `docs/` folder:

- **[START_HERE.md](docs/START_HERE.md)** — Where to begin (all platforms)
- **[HOW_TO_INSTALL.md](docs/HOW_TO_INSTALL.md)** — Complete installation guide
- **[CLAUDE_CODE_GUIDE.md](docs/CLAUDE_CODE_GUIDE.md)** — Claude Code agents, skills, rules setup
- **[MAC_SETUP.md](docs/MAC_SETUP.md)** — macOS-specific setup and tools
- **[MODERN_CLI_TOOLS.md](docs/MODERN_CLI_TOOLS.md)** — bat, eza, fzf, zoxide, and more
- **[CONFIG_GUIDE.md](docs/CONFIG_GUIDE.md)** — Configuration details
- **[UTILITY_SCRIPTS.md](docs/UTILITY_SCRIPTS.md)** — Scripts documentation
- **[FAQ.md](docs/FAQ.md)** — Frequently asked questions
- **[SYMLINKS.md](docs/SYMLINKS.md)** — How symlinks work in this repo
- **[ARCH_INSTALLER_FLOW.md](docs/ARCH_INSTALLER_FLOW.md)** — Arch Linux setup walkthrough

## 🔧 Customization

### Add Your Own Packages

Edit the appropriate OS installer:

```bash
# macOS
vim ~/.dotfiles/os/mac/install.sh

# Arch Linux
vim ~/.dotfiles/os/linux/install_arch.sh

# Ubuntu/Debian
vim ~/.dotfiles/os/linux/install_ubuntu.sh
```

### Customize Zsh Prompt

```bash
# Starship prompt - edit the config file
vim ~/.dotfiles/config/starship/starship.toml

# See Starship docs for customization options
# https://starship.rs/config/
```

### Add Your Own Aliases

```bash
# Add to ~/.zshrc.local (not tracked by git)
echo 'alias myalias="my command"' >> ~/.zshrc.local
source ~/.zshrc
```

## 🆘 Troubleshooting

### Something's not working?

1. **Run health check:** `~/.dotfiles/scripts/dev-check.sh`
2. **Check docs:** Look in `docs/` folder for relevant guide
3. **Re-run installer:** `cd ~/.dotfiles && ./install.sh`

### Common Issues

**Shell theme not showing up:**
- Install Nerd Font: MesloLGS NF or FiraCode Nerd Font
- Set it in your terminal preferences
- Restart terminal

**Modern CLI tools not found:**
- Make sure you ran the installer completely
- Run: `~/.dotfiles/scripts/update.sh`
- Add to PATH: `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc`

**SSH key not working:**
- Generate one: `ssh-keygen -t ed25519 -C "your@email.com"`
- Add to agent: `ssh-add ~/.ssh/id_ed25519`
- Add to GitHub: https://github.com/settings/keys

**Git commits not verified:**
- Run: `~/.dotfiles/scripts/setup-gpg.sh`
- Add GPG key to GitHub: https://github.com/settings/keys

See individual documentation files for more troubleshooting.

## 🤝 Credits

Inspired by countless dotfiles repos in the community. Special thanks to:

- [bat](https://github.com/sharkdp/bat), [eza](https://github.com/eza-community/eza), [ripgrep](https://github.com/BurntSushi/ripgrep), [fd](https://github.com/sharkdp/fd), [fzf](https://github.com/junegunn/fzf), [zoxide](https://github.com/ajeetdsouza/zoxide), and other modern CLI tool authors
- [Oh My Zsh](https://ohmyz.sh) and [Starship](https://starship.rs)
- The entire open-source community

## 📝 License

MIT License - Feel free to fork and customize!

## 👤 Author

**Džiugas Pečiulevičius**

- GitHub: [@peciulevicius](https://github.com/peciulevicius)

---

**Supports**: macOS 12+, Arch Linux, Ubuntu 20.04+, Debian 11+, Kali Linux, Windows 10/11 (PowerShell + WSL2)

**⭐ If you find this useful, consider giving it a star!**
