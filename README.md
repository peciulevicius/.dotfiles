# .dotfiles

> Modern, cross-platform dotfiles with comprehensive tooling for macOS, Linux (Arch, Debian/Ubuntu, Kali), and Windows/WSL.

## ✨ Features

- 🚀 **Modern CLI Tools** - bat, eza, ripgrep, fd, fzf, zoxide, tldr, httpie, jq, delta
- 🎨 **Beautiful Shell** - Zsh with Powerlevel10k (optional fallback to basic prompt)
- ⚙️ **Comprehensive Configs** - Git (40+ aliases), SSH, Tmux, EditorConfig, and more
- 🛠️ **Utility Scripts** - Update, backup, cleanup, and health check tools
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

For more details, see [docs/HOW_TO_INSTALL.md](docs/HOW_TO_INSTALL.md) or [docs/QUICKSTART.md](docs/QUICKSTART.md).

## 🖥️ Supported Platforms

| Platform | Support | Installer |
|----------|---------|-----------|
| **macOS** (12+) | ✅ Full | `os/mac/install_minimal.sh` or `os/mac/install.sh` |
| **Arch Linux** | ✅ Full | `os/linux/install_arch.sh` |
| **Ubuntu/Debian** | ✅ Full | `os/linux/install_ubuntu.sh` |
| **Kali Linux** | ✅ Full | `os/linux/install_ubuntu.sh` |
| **Windows/WSL** | ⚠️ Basic | `os/windows/install_wsl.sh` |

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
| `man` | `tldr` | Practical examples, not walls of text |
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

```bash
~/.dotfiles/scripts/update.sh      # Update all package managers at once
~/.dotfiles/scripts/sync.sh        # Sync dotfiles configs (fast!)
~/.dotfiles/scripts/backup.sh      # Backup all configs and package lists
~/.dotfiles/scripts/cleanup.sh     # Free disk space (cleans Docker, npm, etc.)
~/.dotfiles/scripts/dev-check.sh   # Health check your dev environment
~/.dotfiles/scripts/setup-gpg.sh   # Set up GPG commit signing
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
│   ├── zsh/                     # Zsh & Powerlevel10k config
│   ├── ssh/                     # SSH config template
│   ├── tmux/                    # Tmux configuration
│   ├── curl/                    # Curl preferences
│   ├── claude/                  # Claude Code settings
│   ├── idea/                    # IdeaVim configuration
│   └── .editorconfig            # EditorConfig
│
├── os/                          # 💻 OS-specific installers
│   ├── mac/                     # macOS installers
│   │   ├── install_minimal.sh   # Minimal setup (recommended)
│   │   ├── install.sh           # Full setup
│   │   └── install_optional.sh  # Optional tools
│   ├── linux/                   # Linux installers
│   │   ├── install_arch.sh      # Arch Linux (full featured)
│   │   ├── install_ubuntu.sh    # Ubuntu/Debian/Kali
│   │   └── install.sh           # Generic Linux (legacy)
│   └── windows/                 # Windows/WSL
│       └── install_wsl.sh       # WSL setup
│
└── scripts/                     # 🛠️ Utility scripts
    ├── update.sh                # Update everything
    ├── backup.sh                # Backup configs
    ├── cleanup.sh               # Clean caches
    ├── dev-check.sh             # Health check
    └── setup-gpg.sh             # GPG setup
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

- **[FAQ.md](docs/FAQ.md)** - Frequently asked questions ⭐ **Start here!**
- **[SYMLINKS.md](docs/SYMLINKS.md)** - Understanding how symlinks work
- **[QUICKSTART.md](docs/QUICKSTART.md)** - Quick start guide for Mac users
- **[HOW_TO_INSTALL.md](docs/HOW_TO_INSTALL.md)** - Complete installation guide
- **[CONFIG_GUIDE.md](docs/CONFIG_GUIDE.md)** - Configuration details
- **[MODERN_CLI_TOOLS.md](docs/MODERN_CLI_TOOLS.md)** - Modern CLI tools guide
- **[UTILITY_SCRIPTS.md](docs/UTILITY_SCRIPTS.md)** - Utility scripts documentation
- **[INSTALLATION_GUIDE.md](docs/INSTALLATION_GUIDE.md)** - Platform-specific details
- **[SCRIPTS_EXPLAINED.md](docs/SCRIPTS_EXPLAINED.md)** - Installer comparison
- **[ARCH_INSTALLER_FLOW.md](docs/ARCH_INSTALLER_FLOW.md)** - Arch setup walkthrough

## 🔧 Customization

### Add Your Own Packages

Edit the appropriate OS installer:

```bash
# macOS
vim ~/.dotfiles/os/mac/install_minimal.sh

# Arch Linux
vim ~/.dotfiles/os/linux/install_arch.sh

# Ubuntu/Debian
vim ~/.dotfiles/os/linux/install_ubuntu.sh
```

### Customize Zsh Prompt

```bash
# If you installed Powerlevel10k
p10k configure

# Or edit directly
vim ~/.dotfiles/config/zsh/.p10k.zsh
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
- [Oh My Zsh](https://ohmyz.sh) and [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- The entire open-source community

## 📝 License

MIT License - Feel free to fork and customize!

## 👤 Author

**Džiugas Pečiulevičius**

- GitHub: [@peciulevicius](https://github.com/peciulevicius)

---

**Last Updated**: 2025-11-05

**Supports**: macOS 12+, Arch Linux, Ubuntu 20.04+, Debian 11+, Kali Linux, Windows WSL2

**⭐ If you find this useful, consider giving it a star!**
