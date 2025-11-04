# .dotfiles

Cross-platform dotfiles configuration for Windows, macOS, and Linux (Arch-based and Debian-based distributions).

## Quick Start

```bash
# Clone the repository
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run the installation script
./install.sh
```

The script will automatically detect your operating system and run the appropriate setup.

## Supported Platforms

- **Linux**: Native Linux (Arch, Debian/Ubuntu-based)
- **macOS**: Full macOS support with Homebrew
- **Windows**: PowerShell setup with Chocolatey/Scoop/Winget
- **WSL**: Windows Subsystem for Linux (Ubuntu/Debian)

## What's Included

### Shell Configuration
- **Zsh** with Oh My Zsh framework
- **Powerlevel10k** theme for beautiful prompts
- Cross-platform compatible `.zshrc` with platform detection

### Development Tools
- **Git** with custom aliases and configuration
- **Node.js** ecosystem (nvm, npm, pnpm, yarn)
- **CLI Tools**: gh (GitHub CLI), thefuck, tree-sitter
- **Additional**: stripe-cli, supabase, angular-cli

### Editor Configuration
- **IdeaVim**: Comprehensive vim bindings for JetBrains IDEs
- Custom keybindings and plugins setup

### AI/MCP Configuration
- MCP (Model Context Protocol) servers configuration
- Desktop commander, sequential thinking, and Context7 integrations

## Repository Structure

```
.dotfiles/
├── config/               # Configuration files
│   ├── git/             # Git configuration
│   │   ├── .gitconfig   # Main git config
│   │   └── work/        # Work-specific git configs
│   ├── zsh/             # Zsh configuration
│   │   ├── .zshrc       # Zsh shell configuration
│   │   └── .p10k.zsh    # Powerlevel10k theme configuration
│   ├── idea/            # JetBrains IDEs configuration
│   │   └── .ideavimrc   # IdeaVim configuration
│   └── ai-mcp/          # AI MCP servers configuration
│       └── mcp.json     # MCP server definitions
├── os/                  # OS-specific installation scripts
│   ├── linux/           # Linux-specific setup
│   │   └── install.sh
│   ├── mac/             # macOS-specific setup
│   │   └── install.sh
│   └── windows/         # Windows-specific setup
│       ├── install.ps1  # PowerShell installation script
│       ├── install_wsl.sh  # WSL-specific installation
│       └── README.md    # Windows setup guide
├── scripts/             # Utility scripts
│   └── utils/
│       └── utils.sh     # Shared utility functions
└── install.sh           # Main installation script

```

## Installation Details

### Linux (Arch Linux)

For Arch Linux, the installer will:
1. Install packages using `pacman` and `yay` (AUR helper)
2. Set up Oh My Zsh and Powerlevel10k
3. Create symlinks for all configuration files
4. Install development tools (Node.js via nvm, Docker, etc.)
5. Optionally install GUI applications

**Arch-specific packages:**
```bash
# Core packages managed by pacman/yay
git vim neovim zsh tmux docker nodejs npm github-cli pnpm yarn
```

### Linux (Debian/Ubuntu)

For Debian-based distributions:
1. Use `apt` package manager
2. Add necessary repositories (GitHub CLI, Docker, etc.)
3. Install packages and tools
4. Set up shell and development environment

### macOS

The macOS installer will:
1. Install Homebrew (if not present)
2. Install packages via `brew`
3. Install GUI applications via `brew cask` (optional)
4. Configure zsh with Powerlevel10k
5. Set up development environment

**Casks (GUI applications):**
- iTerm2, Raycast, Visual Studio Code, WebStorm, Notion, Spotify, etc.

### Windows

For native Windows (PowerShell):
1. Install Chocolatey and Scoop package managers
2. Install development tools
3. Set up Windows Terminal with Oh My Posh
4. Install Nerd Fonts
5. Configure PowerShell profile

See [Windows Setup Guide](os/windows/README.md) for detailed customization.

### WSL (Windows Subsystem for Linux)

For WSL environments:
1. Detected automatically by checking `/proc/version` for "microsoft"
2. Installs packages via apt
3. Sets up zsh and Powerlevel10k
4. Configures development environment for WSL

## Configuration Files

### Git Configuration (`config/git/.gitconfig`)

Custom aliases included:
- `git gl` - Show global git configuration
- `git ac <message>` - Add all and commit
- `git last` - Show last commit with stats
- `git lg` - Beautiful git log graph
- `git lg-me` - Git log filtered by your commits

### Zsh Configuration (`config/zsh/.zshrc`)

- Platform-aware path detection for Powerlevel10k
- Works on macOS (Homebrew paths), Linux, and WSL
- Instant prompt for faster shell startup
- Easy customization through `.p10k.zsh`

### IdeaVim Configuration (`config/idea/.ideavimrc`)

Comprehensive vim bindings for JetBrains IDEs:
- Custom leader key (Space)
- Window/tab/buffer navigation
- Code actions and refactoring shortcuts
- Integrated with IdeaVim plugins
- Full keybinding reference in the file

### MCP Configuration (`config/ai-mcp/mcp.json`)

Configured MCP servers:
- Desktop Commander - Desktop automation
- Sequential Thinking - Enhanced reasoning
- Context7 - Context management

## Customization

### Adding Platform-Specific Packages

Edit the appropriate OS installation script:
- **Linux**: `os/linux/install.sh` - Modify `PACKAGES` array
- **macOS**: `os/mac/install.sh` - Modify `PACKAGES` or `CASKS` arrays
- **Windows**: `os/windows/install.ps1` - Modify `$packages` or `$apps` arrays

### Customizing Zsh

1. Edit `config/zsh/.zshrc` for shell configuration
2. Run `p10k configure` to customize the prompt theme
3. The configuration is saved to `config/zsh/.p10k.zsh`

### Git Configuration

For work-specific git configuration:
- Check `config/git/work/` directory
- Contains separate configs for personal and work profiles
- Use `git config --global include.path` to switch contexts

## Maintenance

### Updating Dotfiles

```bash
cd ~/.dotfiles
git pull origin main
./install.sh  # Re-run to update symlinks and packages
```

### Adding New Configurations

1. Add your config file to appropriate directory under `config/`
2. Update the OS-specific install script to create symlinks
3. Document the configuration in this README

### Backing Up Existing Configs

The installation scripts automatically backup existing dotfiles:
- Backups are created with `.backup` extension
- Example: `~/.zshrc` → `~/.zshrc.backup`

## Troubleshooting

### Zsh Theme Not Loading

**macOS (Homebrew):**
```bash
# Check if powerlevel10k is installed
brew list powerlevel10k

# Source should be at:
source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme
```

**Linux:**
```bash
# Check if powerlevel10k is cloned
ls -la ~/powerlevel10k

# Or check Oh My Zsh custom themes
ls -la ~/.oh-my-zsh/custom/themes/powerlevel10k
```

### Symlinks Not Created

```bash
# Manually create symlinks
ln -sf ~/.dotfiles/config/zsh/.zshrc ~/.zshrc
ln -sf ~/.dotfiles/config/zsh/.p10k.zsh ~/.p10k.zsh
ln -sf ~/.dotfiles/config/git/.gitconfig ~/.gitconfig
ln -sf ~/.dotfiles/config/idea/.ideavimrc ~/.ideavimrc
```

### SSH Key Setup

The installer will prompt for SSH key generation. To manually set up:

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# Copy public key to clipboard (Linux)
cat ~/.ssh/id_rsa.pub | xclip -selection clipboard

# Copy public key to clipboard (macOS)
cat ~/.ssh/id_rsa.pub | pbcopy

# Then add to GitHub: https://github.com/settings/keys
```

### Windows Terminal Not Customizing

1. Ensure you've installed a Nerd Font
2. Select the font in Windows Terminal settings
3. Install Oh My Posh: `winget install JanDeDobbeleer.OhMyPosh`
4. Configure PowerShell profile (see [Windows README](os/windows/README.md))

## Platform-Specific Notes

### Arch Linux

For Arch, you may want to install `yay` AUR helper first:
```bash
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```

Then modify `os/linux/install.sh` to use `yay` instead of `apt`.

### macOS Apple Silicon

If you're on Apple Silicon (M1/M2/M3):
- Homebrew installs to `/opt/homebrew` (already handled in `.zshrc`)
- Intel Macs use `/usr/local/homebrew`

### WSL Specific

For WSL, you may want to:
1. Install Windows Terminal from Microsoft Store
2. Set up font in Windows Terminal settings (not in WSL)
3. Consider using Windows-side Git for better performance

## Contributing

Feel free to fork this repository and customize it for your needs!

## License

MIT License - Feel free to use and modify as needed.

## Author

Džiugas Pečiulevičius ([@peciulevicius](https://github.com/peciulevicius))

---

**Last Updated**: 2025-11-04
**Supports**: Windows 10/11, macOS 12+, Ubuntu 20.04+, Arch Linux, WSL2
