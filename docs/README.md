# Documentation

Complete documentation for this dotfiles repository.

## 📖 Table of Contents

### Getting Started

- **[START_HERE.md](./START_HERE.md)** - Recommended reading order and daily commands
- **[MAC_SETUP.md](./MAC_SETUP.md)** - macOS setup, tools, local AI, and remote access (all-in-one)
- **[HOME_SERVER.md](./HOME_SERVER.md)** - Mac mini setup: photo hub (Immich), Time Machine, Tailscale, SSH, drive backup
- **[BEGINNER_TOOL_SETUP_GUIDE.md](./BEGINNER_TOOL_SETUP_GUIDE.md)** - Noob-friendly setup for every installed tool/app
- **[TOOL_COVERAGE_MATRIX.md](./TOOL_COVERAGE_MATRIX.md)** - Coverage tracker for every installer formula/cask/manual app
- **[QUICKSTART.md](./QUICKSTART.md)** - TL;DR guide for Mac users who want to get up and running fast
- **[HOW_TO_INSTALL.md](./HOW_TO_INSTALL.md)** - Complete step-by-step installation guide for all operating systems
- **[FAQ.md](./FAQ.md)** - Frequently asked questions about installation, maintenance, and safety
- **[SYMLINKS.md](./SYMLINKS.md)** - Understanding how symlinks work in dotfiles

### Configuration

- **[CONFIG_GUIDE.md](./CONFIG_GUIDE.md)** - Detailed documentation of all configuration files
  - Git configuration and aliases
  - Zsh configuration
  - IdeaVim keybindings
  - And more...

### Installation Details

- **[INSTALLATION_GUIDE.md](./INSTALLATION_GUIDE.md)** - Comprehensive guide covering:
  - What gets installed on each OS
  - Platform-specific instructions (macOS, Arch, Debian, WSL)
  - Customization options
  - Troubleshooting

- **[SCRIPTS_EXPLAINED.md](./SCRIPTS_EXPLAINED.md)** - Comparison of installation scripts:
  - Minimal vs. optional vs. full installers
  - What's in each script
  - Cross-platform considerations

- **[ARCH_INSTALLER_FLOW.md](./ARCH_INSTALLER_FLOW.md)** - Detailed Arch Linux installer flow:
  - Step-by-step walkthrough
  - What gets installed automatically
  - Interactive prompts
  - Post-installation steps

### Claude Code & Product Development

- **[CLAUDE_CODE_GUIDE.md](./CLAUDE_CODE_GUIDE.md)** - Complete Claude Code guide: skills, agents, statusline, settings, hooks
- **[BUSINESS_STACK_GUIDE.md](./BUSINESS_STACK_GUIDE.md)** - Product stack reference: web/mobile frameworks, analytics, payments, deployment

### Self-Hosted & Privacy

- **[SERVICES.md](./SERVICES.md)** - 13 Docker Compose stacks: Immich, Vaultwarden, Nextcloud, Ollama, and more
- **[BACKUPS.md](./BACKUPS.md)** - 3-2-1 backup strategy for services, photos, and personal data
- **[NOTES.md](./NOTES.md)** - Obsidian vault setup, Syncthing sync, git backup, and Ollama integration
- **[BOOKS.md](./BOOKS.md)** - Calibre-Web library server, Kindle highlights pipeline, mobile reading
- **[DEGOOGLE.md](./DEGOOGLE.md)** - Migration checklist: replace Google services with self-hosted alternatives

### Tools & Scripts

- **[MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md)** - Guide to modern CLI tools:
  - bat, eza, ripgrep, fd, fzf, zoxide, etc.
  - What they do and why they're useful
  - Usage examples

- **[UTILITY_SCRIPTS.md](./UTILITY_SCRIPTS.md)** - Documentation for utility scripts:
  - `update.sh` - Update all package managers
  - `backup.sh` - Backup configurations
  - `cleanup.sh` - Clean caches and free disk space
  - `dev-check.sh` - Check environment health
  - `setup-gpg.sh` - Set up GPG commit signing
- **[WALLPAPERS.md](./WALLPAPERS.md)** - Manage wallpapers from dotfiles
- **[tutorials/TOOL_TUTORIALS.md](./tutorials/TOOL_TUTORIALS.md)** - Official docs + YouTube tutorial links per tool
- **[SETUP_DOCS_SITE.md](./SETUP_DOCS_SITE.md)** - Browser-accessible docs via MkDocs + GitHub Pages

### Advanced Topics

- **[CONFIG_GUIDE.md](./CONFIG_GUIDE.md)** - Git/SSH/Zsh/Tmux configuration details

## 🎯 Quick Navigation

**I want to...**

- Get started quickly → [QUICKSTART.md](./QUICKSTART.md)
- Start in the right order → [START_HERE.md](./START_HERE.md)
- Set up a Mac (setup, tools, local AI, remote access) → [MAC_SETUP.md](./MAC_SETUP.md)
- Set up Mac mini (photos, backups, remote access) → [HOME_SERVER.md](./HOME_SERVER.md)
- Set up each installed tool step-by-step → [BEGINNER_TOOL_SETUP_GUIDE.md](./BEGINNER_TOOL_SETUP_GUIDE.md)
- Check documentation coverage per installed tool → [TOOL_COVERAGE_MATRIX.md](./TOOL_COVERAGE_MATRIX.md)
- Install on a new machine → [HOW_TO_INSTALL.md](./HOW_TO_INSTALL.md)
- Answer common questions → [FAQ.md](./FAQ.md) ⭐ **Start here if unsure!**
- Understand what each config file does → [CONFIG_GUIDE.md](./CONFIG_GUIDE.md)
- Learn about the installation scripts → [SCRIPTS_EXPLAINED.md](./SCRIPTS_EXPLAINED.md)
- Install on Arch Linux → [ARCH_INSTALLER_FLOW.md](./ARCH_INSTALLER_FLOW.md)
- Learn about modern CLI tools → [MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md)
- Use the utility scripts → [UTILITY_SCRIPTS.md](./UTILITY_SCRIPTS.md)
- Learn tools with tutorial links → [tutorials/TOOL_TUTORIALS.md](./tutorials/TOOL_TUTORIALS.md)
- Run self-hosted services (Immich, Vaultwarden, etc.) → [SERVICES.md](./SERVICES.md)
- Back up everything → [BACKUPS.md](./BACKUPS.md)
- Manage notes with Obsidian → [NOTES.md](./NOTES.md)
- Stop using Google → [DEGOOGLE.md](./DEGOOGLE.md)

## 📁 Repository Structure

```
.dotfiles/
├── README.md                 # Main repository README
├── docs/                     # All documentation (you are here)
├── config/                   # Configuration files
│   ├── git/                  # Git config
│   ├── zsh/                  # Zsh config
│   ├── ssh/                  # SSH config template
│   ├── tmux/                 # Tmux config
│   ├── curl/                 # Curl config
│   ├── claude/               # Claude Code settings
│   └── .editorconfig         # EditorConfig
├── os/                       # OS-specific installers
│   ├── mac/                  # macOS installers
│   ├── linux/                # Linux installers
│   └── windows/              # Windows/WSL installer
├── scripts/                  # Utility scripts
│   ├── update.sh             # Update all package managers
│   ├── backup.sh             # Backup configs
│   ├── cleanup.sh            # Clean caches
│   ├── dev-check.sh          # Health check
│   ├── setup-gpg.sh          # GPG setup
│   └── setup-obsidian.sh     # Obsidian vault setup
│
└── services/                 # Self-hosted Docker Compose stacks
    ├── setup-services.sh     # Stage stacks to ~/docker/
    ├── immich/               # Google Photos replacement
    ├── vaultwarden/          # Bitwarden server
    ├── nextcloud/            # Google Drive replacement
    └── rclone/               # Cloud backup
```

## 🚀 Quick Start Commands

```bash
# Install on new machine
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh

# Update everything
~/.dotfiles/scripts/update.sh

# Backup configurations
~/.dotfiles/scripts/backup.sh

# Clean up disk space
~/.dotfiles/scripts/cleanup.sh

# Check environment health
~/.dotfiles/scripts/dev-check.sh

# Set up GPG commit signing
~/.dotfiles/scripts/setup-gpg.sh
```

## 💡 Tips

- Start with [QUICKSTART.md](./QUICKSTART.md) if you're new
- Refer to [HOW_TO_INSTALL.md](./HOW_TO_INSTALL.md) for complete installation
- Check [CONFIG_GUIDE.md](./CONFIG_GUIDE.md) to understand your configs
- Run `dev-check.sh` to verify your setup
- Use `update.sh` regularly to keep everything current

## 🔗 External Resources

- [GitHub Docs](https://docs.github.com)
- [Oh My Zsh](https://ohmyz.sh)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [Homebrew](https://brew.sh)
- [Arch Wiki](https://wiki.archlinux.org)

## 🆘 Getting Help

1. Check the relevant documentation file above
2. Run `dev-check.sh` to diagnose issues
3. Look for troubleshooting sections in the guides
4. Search for similar issues in the repository

## 📝 Contributing

Found a bug or have a suggestion? Please:
1. Check existing documentation first
2. Create an issue describing the problem
3. Submit a pull request with improvements

---

**Need help?** Start with [QUICKSTART.md](./QUICKSTART.md) or [HOW_TO_INSTALL.md](./HOW_TO_INSTALL.md)
