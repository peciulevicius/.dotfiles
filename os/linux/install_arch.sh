#!/bin/bash

# Arch Linux Dotfiles Installation Script
# Installs your consistent development environment across all machines

set -e

# Import utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../../scripts/utils/utils.sh"

print_section "Arch Linux Development Environment Setup"

DOTFILES_REPO="$HOME/.dotfiles"

# =============================================================================
# PACKAGES TO INSTALL
# =============================================================================

# Essential CLI tools (always installed)
ESSENTIALS=(
  git
  github-cli
  curl
  wget
  base-devel        # Needed for building AUR packages
  openssh
)

# Development tools
DEVELOPER_CLI=(
  docker
  nodejs
  npm
  zsh
)

# AUR packages (require yay)
AUR_DEVELOPER=(
  nvm               # Node version manager
  pnpm-bin          # Fast npm alternative
)

# YOUR ACTUAL GUI APPLICATIONS
# These match what you use on Mac
AUR_APPS=(
  # Browsers
  google-chrome

  # Development IDEs
  visual-studio-code-bin
  # Note: WebStorm via JetBrains Toolbox (installed separately)

  # Password & Security
  nordpass-bin
  nordvpn-bin

  # Design & Collaboration
  figma-linux
  notion-app

  # Other
  # Claude Code - download from https://claude.ai/download
  # Docker Desktop - or use docker CLI + docker-compose
)

# Optional (will ask before installing)
OPTIONAL_APPS=(
  spotify
  discord
  slack-desktop
  postman-bin
)

# Dotfiles to symlink
FILES=(
  config/git/.gitconfig
  config/idea/.ideavimrc
  config/zsh/.p10k.zsh
  config/zsh/.zshrc
)

# =============================================================================
# FUNCTIONS
# =============================================================================

print_info() {
  echo -e "${GREEN}✓${NC} $1"
}

check_yay_installed() {
  if ! command -v yay &> /dev/null; then
    print_warning "yay AUR helper not found. Installing yay..."
    install_yay
  else
    print_info "yay is already installed"
  fi
}

install_yay() {
  print_title "Installing yay AUR Helper"

  # Install dependencies
  sudo pacman -S --needed --noconfirm git base-devel

  # Clone and build yay
  local TMP_DIR=$(mktemp -d)
  cd "$TMP_DIR"
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm

  # Cleanup
  cd ~
  rm -rf "$TMP_DIR"

  print_info "yay installed successfully"
}

install_essentials() {
  print_title "Installing Essential Packages"

  sudo pacman -Sy --noconfirm

  for PACKAGE in "${ESSENTIALS[@]}"; do
    if pacman -Qi "$PACKAGE" &> /dev/null; then
      print_info "$PACKAGE already installed"
    else
      sudo pacman -S --noconfirm "$PACKAGE"
    fi
  done
}

install_developer_tools() {
  print_title "Installing Development CLI Tools"

  for PACKAGE in "${DEVELOPER_CLI[@]}"; do
    if pacman -Qi "$PACKAGE" &> /dev/null; then
      print_info "$PACKAGE already installed"
    else
      sudo pacman -S --noconfirm "$PACKAGE"
    fi
  done

  # AUR packages
  check_yay_installed

  for PACKAGE in "${AUR_DEVELOPER[@]}"; do
    if yay -Qi "$PACKAGE" &> /dev/null || pacman -Qi "$PACKAGE" &> /dev/null; then
      print_info "$PACKAGE already installed"
    else
      yay -S --noconfirm "$PACKAGE"
    fi
  done
}

install_gui_applications() {
  print_title "Installing GUI Applications"

  echo ""
  echo "This will install your standard app suite:"
  echo "  • Google Chrome"
  echo "  • VS Code"
  echo "  • NordPass + NordVPN"
  echo "  • Figma"
  echo "  • Notion"
  echo ""
  read -p "Install all GUI applications? (y/n) " -n 1 -r
  echo

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Skipping GUI applications"
    return
  fi

  check_yay_installed

  for APP in "${AUR_APPS[@]}"; do
    if yay -Qi "$APP" &> /dev/null || pacman -Qi "$APP" &> /dev/null; then
      print_info "$APP already installed"
    else
      print_title "Installing $APP..."
      yay -S --noconfirm "$APP"
    fi
  done

  print_info "GUI applications installed"
}

install_jetbrains_toolbox() {
  print_title "Installing JetBrains Toolbox"

  if command -v jetbrains-toolbox &> /dev/null; then
    print_info "JetBrains Toolbox already installed"
    return
  fi

  read -p "Install JetBrains Toolbox (for WebStorm)? (y/n) " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    check_yay_installed
    yay -S --noconfirm jetbrains-toolbox
    print_info "JetBrains Toolbox installed"
    echo ""
    echo "After installing WebStorm via Toolbox:"
    echo "1. Open WebStorm"
    echo "2. Install IdeaVim plugin"
    echo "3. Restart WebStorm"
    echo "4. Your ~/.ideavimrc will be used automatically"
    echo ""
  else
    print_warning "Skipped JetBrains Toolbox"
  fi
}

install_claude_code() {
  print_title "Claude Code Installation"

  echo ""
  echo "Claude Code needs to be downloaded manually:"
  echo "  1. Visit: https://claude.ai/download"
  echo "  2. Download the Linux .deb or .AppImage"
  echo "  3. Install with: sudo pacman -U <package>.pkg.tar.zst"
  echo "     (or run the AppImage directly)"
  echo ""
  read -p "Open Claude Code download page? (y/n) " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    xdg-open "https://claude.ai/download" 2>/dev/null || echo "Please visit https://claude.ai/download manually"
  fi
}

install_optional_apps() {
  print_title "Optional Applications"

  echo ""
  echo "Additional apps you might want:"
  echo ""

  for APP in "${OPTIONAL_APPS[@]}"; do
    read -p "Install $APP? (y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      if yay -Qi "$APP" &> /dev/null || pacman -Qi "$APP" &> /dev/null; then
        print_info "$APP already installed"
      else
        yay -S --noconfirm "$APP"
      fi
    fi
  done
}

setup_zsh() {
  print_title "Setting Up Zsh"

  # Install Powerlevel10k theme
  read -p "Install Powerlevel10k theme? (y/n) " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    local P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [ ! -d "$P10K_DIR" ]; then
      git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
      print_info "Powerlevel10k installed"
    else
      print_info "Powerlevel10k already installed"
    fi
  fi
}

setup_ssh() {
  print_title "Setting Up SSH Key"

  if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_rsa" ]; then
    read -p "Generate SSH key? (y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      read -p "Enter your email: " email
      ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""

      eval "$(ssh-agent -s)"
      ssh-add "$HOME/.ssh/id_ed25519"

      echo ""
      print_info "SSH key generated!"
      echo ""
      cat "$HOME/.ssh/id_ed25519.pub"
      echo ""
      print_warning "Add this key to GitHub: https://github.com/settings/keys"
    fi
  else
    print_info "SSH key already exists"
  fi
}

setup_github_cli() {
  print_title "Setting Up GitHub CLI"

  if ! gh auth status &>/dev/null; then
    read -p "Authenticate with GitHub now? (y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      gh auth login
    else
      print_warning "Skipped GitHub auth - run 'gh auth login' later"
    fi
  else
    print_info "Already authenticated with GitHub"
  fi
}

clone_dotfiles_repo() {
  print_title "Setting Up Dotfiles Repository"

  if [ ! -d "$DOTFILES_REPO" ]; then
    git clone https://github.com/peciulevicius/.dotfiles.git "$DOTFILES_REPO"
    print_info "Dotfiles repository cloned"
  else
    print_info "Dotfiles repository already exists"
  fi

  setup_symlinks
}

setup_symlinks() {
  print_title "Setting Up Symlinks for Dotfiles"

  for FILE in "${FILES[@]}"; do
    local source_file="$DOTFILES_REPO/$FILE"
    local target_file="$HOME/$(basename $FILE)"

    if [ ! -f "$source_file" ]; then
      print_warning "Source $source_file doesn't exist, skipping..."
      continue
    fi

    # Backup existing file
    if [ -f "$target_file" ] && [ ! -L "$target_file" ]; then
      mv "$target_file" "${target_file}.backup"
      print_info "Backed up existing $(basename $FILE)"
    fi

    # Create symlink
    ln -sf "$source_file" "$target_file"
    print_info "Linked $(basename $FILE)"
  done
}

enable_docker() {
  print_title "Enabling Docker Service"

  if systemctl is-enabled docker &> /dev/null; then
    print_info "Docker service already enabled"
  else
    sudo systemctl enable docker
    sudo systemctl start docker
    print_info "Docker service enabled and started"
  fi

  # Add user to docker group
  if groups $USER | grep &> /dev/null '\bdocker\b'; then
    print_info "User already in docker group"
  else
    sudo usermod -aG docker $USER
    print_warning "Added to docker group - log out and back in to apply"
  fi
}

change_shell_to_zsh() {
  print_title "Setting Zsh as Default Shell"

  if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s $(which zsh)
    print_info "Default shell changed to zsh - log out to apply"
  else
    print_info "Zsh is already the default shell"
  fi
}

print_summary() {
  echo ""
  print_section "Installation Complete!"
  echo ""
  echo "What was installed:"
  echo "  ✓ Essential CLI tools (git, gh, curl)"
  echo "  ✓ Development tools (docker, node, npm, nvm, pnpm)"
  echo "  ✓ GUI applications (Chrome, VS Code, NordPass, etc.)"
  echo "  ✓ Dotfiles (.gitconfig, .zshrc, .ideavimrc)"
  echo "  ✓ SSH keys and GitHub authentication"
  echo ""
  echo "Still TODO:"
  echo "  • Download Claude Code from https://claude.ai/download"
  echo "  • Open JetBrains Toolbox and install WebStorm"
  echo "  • Install IdeaVim plugin in WebStorm"
  echo "  • Run 'p10k configure' if you installed Powerlevel10k"
  echo ""
  print_warning "IMPORTANT: Log out and back in for all changes to take effect"
  echo ""
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
  echo ""
  echo "This will set up your Arch Linux development environment to match your Mac setup."
  echo ""
  read -p "Continue? (y/n) " -n 1 -r
  echo

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
  fi

  install_essentials
  install_developer_tools
  setup_zsh
  install_gui_applications
  install_jetbrains_toolbox
  install_claude_code
  install_optional_apps
  clone_dotfiles_repo
  setup_ssh
  setup_github_cli
  enable_docker
  change_shell_to_zsh
  print_summary
}

main
