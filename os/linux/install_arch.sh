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
  docker-compose           # Docker Compose for multi-container apps
  nodejs
  npm
  zsh
  starship                # Modern, cross-shell prompt
  # Modern CLI tools (game changers!)
  bat                      # Better cat with syntax highlighting
  eza                      # Better ls with icons and git status
  ripgrep                  # Better grep - insanely fast (rg)
  fd                       # Better find - simple and fast
  fzf                      # Fuzzy finder - ESSENTIAL for productivity
  zoxide                   # Smart cd - learns your most-used directories
  tldr                     # Simplified man pages with examples
  httpie                   # Better curl for testing APIs
  jq                       # JSON processor - essential for API work
  git-delta                # Better git diff with syntax highlighting
)

# AUR packages (require yay)
AUR_DEVELOPER=(
  nvm               # Node version manager
  pnpm-bin          # Fast npm alternative
)

# Fonts (needed for terminal icons and Starship prompt)
AUR_FONTS=(
  ttf-meslo-nerd
  ttf-firacode-nerd
)

# YOUR ACTUAL GUI APPLICATIONS
# These match what you use on Mac
AUR_APPS=(
  # Browsers
  google-chrome

  # Development IDEs
  visual-studio-code-bin
  # Note: WebStorm via JetBrains Toolbox (installed separately)

  # AI Tools
  claude-desktop-bin        # Claude Code (AI assistant)

  # Password Managers & Security
  bitwarden-bin            # Password manager
  nordpass-bin             # Password manager
  nordvpn-bin              # VPN

  # Design & Collaboration
  figma-linux
  notion-app

  # Other
  # Docker Desktop - using docker CLI + docker-compose instead
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
  config/zsh/.zshrc
  # Note: Starship config is in ~/.dotfiles/config/starship/starship.toml
  # No need to symlink - STARSHIP_CONFIG env var points to it
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

install_fonts() {
  print_title "Installing Nerd Fonts"

  echo ""
  echo "Installing Nerd Fonts for terminal icons (needed for Powerlevel10k):"
  echo "  • Meslo Nerd Font"
  echo "  • FiraCode Nerd Font"
  echo ""
  read -p "Install Nerd Fonts? (y/n) " -n 1 -r
  echo

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Skipping fonts - terminal icons may not display correctly"
    return
  fi

  check_yay_installed

  for FONT in "${AUR_FONTS[@]}"; do
    if yay -Qi "$FONT" &> /dev/null || pacman -Qi "$FONT" &> /dev/null; then
      print_info "$FONT already installed"
    else
      yay -S --noconfirm "$FONT"
    fi
  done

  print_info "Nerd Fonts installed - set your terminal font to 'MesloLGS Nerd Font'"
}

install_gui_applications() {
  print_title "Installing GUI Applications"

  echo ""
  echo "This will install your standard app suite:"
  echo "  • Google Chrome"
  echo "  • VS Code"
  echo "  • Claude Code (AI assistant)"
  echo "  • Bitwarden (password manager)"
  echo "  • NordPass (password manager)"
  echo "  • NordVPN"
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

setup_oh_my_zsh() {
  print_title "Installing Oh My Zsh"

  if [ -d "$HOME/.oh-my-zsh" ]; then
    print_info "Oh My Zsh already installed"
    return
  fi

  echo ""
  echo "Oh My Zsh provides a framework for managing zsh configuration."
  echo "It's required for Powerlevel10k theme."
  echo ""
  read -p "Install Oh My Zsh? (y/n) " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    print_info "Oh My Zsh installed"
  else
    print_warning "Skipped Oh My Zsh - Powerlevel10k may not work correctly"
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

setup_starship() {
  print_title "Verifying Starship Prompt"

  if command -v starship &> /dev/null; then
    print_info "Starship is installed"

    # Verify config location
    if [ -f "$HOME/.dotfiles/config/starship/starship.toml" ]; then
      print_info "Starship config found"
      echo ""
      echo "Starship is a modern, fast, cross-shell prompt"
      echo "Config: ~/.dotfiles/config/starship/starship.toml"
      echo "Customize: https://starship.rs/config/"
    fi
  else
    print_warning "Starship not found - should have been installed with pacman"
    echo ""
    echo "Starship is a modern alternative to Powerlevel10k:"
    echo "  • Blazing fast (written in Rust)"
    echo "  • Cross-shell (zsh, bash, fish, PowerShell)"
    echo "  • Actively maintained (2025+)"
    echo "  • Easy TOML configuration"
    echo ""
    echo "Your .zshrc will use a basic fallback prompt if Starship isn't available."
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

# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================

setup_network() {
  print_title "Setting Up Network Configuration"

  # Install NetworkManager if not installed
  if ! pacman -Q networkmanager &> /dev/null; then
    print_info "Installing NetworkManager..."
    sudo pacman -S --noconfirm networkmanager
  fi

  # Enable and start NetworkManager
  print_info "Enabling NetworkManager service..."
  sudo systemctl enable NetworkManager
  sudo systemctl start NetworkManager

  # Check if we have network connectivity
  if ping -c 1 8.8.8.8 &> /dev/null; then
    print_success "Network is configured and working!"
  else
    print_warning "Network setup complete, but no internet connectivity detected"
    print_warning "You may need to manually configure your network adapter:"
    echo "  • Ethernet: Should work automatically"
    echo "  • WiFi: Run 'nmtui' for interactive setup"
    echo "  • Or use: nmcli device wifi connect <SSID> password <password>"
  fi

  # Optional: Install network tools
  read -p "Install additional network tools (dig, traceroute, etc)? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo pacman -S --noconfirm bind-tools traceroute net-tools
    print_success "Network tools installed"
  fi
}

# =============================================================================
# DISPLAY/GRAPHICS CONFIGURATION
# =============================================================================

setup_display() {
  print_title "Setting Up Display and Graphics"

  # Detect graphics card
  print_info "Detecting graphics hardware..."

  if lspci | grep -i nvidia &> /dev/null; then
    print_warning "NVIDIA GPU detected!"
    echo "NVIDIA drivers can be complex on Arch. Options:"
    echo "  1. nvidia - Latest drivers for newer cards"
    echo "  2. nvidia-lts - For LTS kernel"
    echo "  3. nvidia-open - Open source drivers (RTX 20+ series)"
    echo ""
    read -p "Install NVIDIA drivers? (1/2/3/n) " -n 1 -r
    echo
    case $REPLY in
      1)
        sudo pacman -S --noconfirm nvidia nvidia-utils
        print_success "NVIDIA drivers installed"
        ;;
      2)
        sudo pacman -S --noconfirm nvidia-lts nvidia-utils
        print_success "NVIDIA LTS drivers installed"
        ;;
      3)
        sudo pacman -S --noconfirm nvidia-open nvidia-utils
        print_success "NVIDIA open drivers installed"
        ;;
      *)
        print_info "Skipping NVIDIA drivers"
        ;;
    esac
  elif lspci | grep -i amd &> /dev/null; then
    print_info "AMD GPU detected"
    read -p "Install AMD drivers (mesa, vulkan)? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      sudo pacman -S --noconfirm mesa vulkan-radeon libva-mesa-driver
      print_success "AMD drivers installed"
    fi
  elif lspci | grep -i intel &> /dev/null; then
    print_info "Intel GPU detected"
    read -p "Install Intel drivers (mesa, vulkan)? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      sudo pacman -S --noconfirm mesa vulkan-intel libva-intel-driver intel-media-driver
      print_success "Intel drivers installed"
    fi
  fi

  # Install xrandr and display tools
  print_info "Installing display configuration tools..."
  sudo pacman -S --noconfirm xorg-xrandr arandr

  print_success "Display tools installed!"
  echo ""
  echo "Multi-monitor setup help:"
  echo "  • GUI tool: Run 'arandr' to configure displays visually"
  echo "  • CLI tool: Use 'xrandr' for command-line configuration"
  echo ""
  echo "Example xrandr commands:"
  echo "  xrandr                                    # List all displays"
  echo "  xrandr --output HDMI-1 --auto             # Enable display"
  echo "  xrandr --output HDMI-1 --right-of eDP-1   # Position display"
  echo "  xrandr --output HDMI-1 --mode 1920x1080   # Set resolution"
  echo ""

  # Offer to save xrandr config
  read -p "Configure displays now with arandr? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v arandr &> /dev/null; then
      arandr &
      print_info "ARandR launched. Configure your displays and save the layout."
    fi
  fi
}

# =============================================================================
# SYSTEM CONFIGURATION
# =============================================================================

setup_system_config() {
  print_title "System Configuration (Timezone, Locale, Hostname)"

  # Timezone
  print_info "Current timezone: $(timedatectl show -p Timezone --value)"
  read -p "Configure timezone? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Available timezones (examples):"
    echo "  Europe/London, Europe/Paris, America/New_York, America/Los_Angeles"
    echo "  Asia/Tokyo, Australia/Sydney, etc."
    echo ""
    read -p "Enter timezone (e.g., Europe/London): " timezone
    if [ -n "$timezone" ]; then
      sudo timedatectl set-timezone "$timezone"
      print_success "Timezone set to: $timezone"
    fi
  fi

  # Locale
  print_info "Current locale: $LANG"
  read -p "Configure locale? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Common locales:"
    echo "  en_US.UTF-8 (US English)"
    echo "  en_GB.UTF-8 (UK English)"
    echo "  lt_LT.UTF-8 (Lithuanian)"
    echo ""
    read -p "Enter locale (e.g., en_US.UTF-8): " locale
    if [ -n "$locale" ]; then
      # Ensure locale is generated
      if ! grep -q "^$locale" /etc/locale.gen; then
        sudo sed -i "s/^#$locale/$locale/" /etc/locale.gen 2>/dev/null || echo "$locale UTF-8" | sudo tee -a /etc/locale.gen
      fi
      sudo locale-gen
      echo "LANG=$locale" | sudo tee /etc/locale.conf
      print_success "Locale set to: $locale (will apply on next login)"
    fi
  fi

  # Hostname
  print_info "Current hostname: $(hostnamectl hostname)"
  read -p "Configure hostname? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter new hostname: " hostname
    if [ -n "$hostname" ]; then
      sudo hostnamectl set-hostname "$hostname"
      print_success "Hostname set to: $hostname"
    fi
  fi
}

# =============================================================================
# AUDIO CONFIGURATION
# =============================================================================

setup_audio() {
  print_title "Audio System Setup"

  print_info "Arch Linux can use:"
  echo "  1. PipeWire (Modern, recommended - handles audio + video)"
  echo "  2. PulseAudio (Traditional, stable)"
  echo "  3. Skip (configure manually later)"
  echo ""
  read -p "Choose audio system (1/2/3): " -n 1 -r
  echo

  case $REPLY in
    1)
      print_info "Installing PipeWire..."
      sudo pacman -S --noconfirm pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber
      systemctl --user enable pipewire pipewire-pulse wireplumber
      print_success "PipeWire installed! (will start on next login)"
      ;;
    2)
      print_info "Installing PulseAudio..."
      sudo pacman -S --noconfirm pulseaudio pulseaudio-alsa
      systemctl --user enable pulseaudio
      print_success "PulseAudio installed! (will start on next login)"
      ;;
    *)
      print_info "Skipping audio configuration"
      ;;
  esac

  # Volume control tools
  if [[ $REPLY =~ ^[12]$ ]]; then
    read -p "Install GUI volume control (pavucontrol)? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      sudo pacman -S --noconfirm pavucontrol
      print_success "PulseAudio Volume Control installed"
    fi
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
  echo "  ✓ Essential CLI tools (git, gh, curl, openssh)"
  echo "  ✓ Development tools (docker, docker-compose, node, npm, nvm, pnpm)"
  echo "  ✓ Modern CLI tools (bat, eza, ripgrep, fd, fzf, zoxide, tldr, httpie, jq, delta)"
  echo "  ✓ Shell setup (zsh, oh-my-zsh, starship)"
  echo "  ✓ Nerd Fonts (for terminal icons)"
  echo "  ✓ GUI applications:"
  echo "    • Google Chrome"
  echo "    • VS Code"
  echo "    • Claude Code"
  echo "    • Bitwarden + NordPass"
  echo "    • NordVPN"
  echo "    • Figma"
  echo "    • Notion"
  echo "  ✓ Dotfiles (.gitconfig, .zshrc, .ideavimrc, starship.toml)"
  echo "  ✓ SSH keys and GitHub authentication"
  echo ""
  echo "Next steps:"
  echo "  1. LOG OUT and log back in (required for docker group and zsh)"
  echo "  2. Set terminal font to 'MesloLGS Nerd Font' or 'FiraCode Nerd Font'"
  echo "  3. Customize Starship prompt: edit ~/.dotfiles/config/starship/starship.toml"
  echo "  4. Open JetBrains Toolbox and install WebStorm"
  echo "  5. In WebStorm: Install IdeaVim plugin (Settings → Plugins → IdeaVim)"
  echo "  6. Sign into Bitwarden/NordPass"
  echo "  7. Sign into NordVPN"
  echo "  8. Open Claude Code and sign in"
  echo ""
  echo "Useful commands:"
  echo "  git aliases    # See all git aliases"
  echo "  git st         # Short status"
  echo "  git lg         # Pretty log"
  echo "  pacup          # Update all packages (alias in .zshrc)"
  echo ""
  echo "Modern CLI tools:"
  echo "  bat <file>     # View files with syntax highlighting"
  echo "  eza -la        # Better ls with icons"
  echo "  rg <pattern>   # Lightning fast search"
  echo "  fd <name>      # Quick file finding"
  echo "  fzf            # Fuzzy finder (Ctrl+R for history)"
  echo "  z <dir>        # Smart jump to directories"
  echo "  tldr <cmd>     # Quick command examples"
  echo "  http <url>     # Better curl for APIs"
  echo "  jq             # JSON processor"
  echo ""
  print_warning "IMPORTANT: You MUST log out and back in for changes to take effect!"
  echo ""
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
  echo ""
  echo "This will set up your Arch Linux development environment to match your Mac setup."
  echo ""
  echo "This installer will:"
  echo "  • Install CLI tools (git, docker, node, etc.)"
  echo "  • Install GUI apps (Chrome, VS Code, Claude Code, Bitwarden, etc.)"
  echo "  • Set up dotfiles (.gitconfig, .zshrc, .ideavimrc)"
  echo "  • Configure SSH and GitHub"
  echo "  • Set up zsh with Starship prompt"
  echo "  • Configure network (NetworkManager)"
  echo "  • Set up display/graphics drivers"
  echo "  • Configure system (timezone, locale)"
  echo ""
  read -p "Continue? (y/n) " -n 1 -r
  echo

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
  fi

  # Core system setup
  setup_network
  setup_system_config

  # Software installation
  install_essentials
  install_developer_tools
  setup_oh_my_zsh
  install_fonts
  setup_starship

  # Hardware setup
  setup_display
  setup_audio

  # Applications
  install_gui_applications
  install_jetbrains_toolbox
  install_optional_apps

  # Configuration
  clone_dotfiles_repo
  setup_ssh
  setup_github_cli
  enable_docker
  change_shell_to_zsh

  print_summary
}

main
