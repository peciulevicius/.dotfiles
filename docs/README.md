# Documentation

Complete documentation for this dotfiles repository.

## 📖 Table of Contents

### Getting Started

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

### Advanced Topics

- **[GIT_GUIDE.md](./GIT_GUIDE.md)** - Advanced Git configuration:
  - 40+ useful git aliases
  - GPG commit signing
  - Commit message templates
  - Multiple GitHub accounts

- **[SSH_GUIDE.md](./SSH_GUIDE.md)** - SSH configuration:
  - SSH key setup (ed25519)
  - SSH config file
  - Multiple SSH keys for different services

## 🎯 Quick Navigation

**I want to...**

- Get started quickly → [QUICKSTART.md](./QUICKSTART.md)
- Install on a new machine → [HOW_TO_INSTALL.md](./HOW_TO_INSTALL.md)
- Answer common questions → [FAQ.md](./FAQ.md) ⭐ **Start here if unsure!**
- Understand what each config file does → [CONFIG_GUIDE.md](./CONFIG_GUIDE.md)
- Learn about the installation scripts → [SCRIPTS_EXPLAINED.md](./SCRIPTS_EXPLAINED.md)
- Install on Arch Linux → [ARCH_INSTALLER_FLOW.md](./ARCH_INSTALLER_FLOW.md)
- Learn about modern CLI tools → [MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md)
- Use the utility scripts → [UTILITY_SCRIPTS.md](./UTILITY_SCRIPTS.md)

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
└── scripts/                  # Utility scripts
    ├── update.sh             # Update all package managers
    ├── backup.sh             # Backup configs
    ├── cleanup.sh            # Clean caches
    ├── dev-check.sh          # Health check
    └── setup-gpg.sh          # GPG setup
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
