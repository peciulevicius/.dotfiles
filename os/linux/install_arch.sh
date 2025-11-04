#!/bin/bash

# Arch Linux Dotfiles Installation Script
# This script is specifically designed for Arch Linux using pacman and yay (AUR helper)

# Exit immediately if a command exits with a non-zero status
set -e

# Import utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../../scripts/utils/utils.sh"

print_section "Running Arch Linux Dotfiles Setup"

DOTFILES_REPO="$HOME/.dotfiles"

# Arch Linux packages (available in official repos or AUR)
PACKAGES=(
  git
  vim
  neovim
  zsh
  tmux
  docker
  nodejs
  npm
  github-cli
  yarn
  curl
  base-devel
)

# AUR packages (require yay)
AUR_PACKAGES=(
  nvm
  pnpm
  thefuck
)

# Optional GUI applications (comment out if not needed)
AUR_APPS=(
  nordpass-bin
  nordvpn-bin
  spotify
  google-chrome
  notion-app
  visual-studio-code-bin
  postman-bin
  discord
  figma-linux
)

FILES=(
  config/git/.gitconfig
  config/idea/.ideavimrc
  config/zsh/.p10k.zsh
  config/zsh/.zshrc
)

check_yay_installed() {
  if ! command -v yay &> /dev/null; then
    print_warning "yay AUR helper not found. Installing yay..."
    install_yay
  else
    print_success "yay is already installed"
  fi
}

install_yay() {
  print_title "Installing yay AUR Helper"

  # Install git and base-devel if not present
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

  print_success "yay installed successfully"
}

install_oh_my_zsh() {
  print_title "Installing Oh My Zsh"
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    print_success "Oh My Zsh installed"
  else
    print_success "Oh My Zsh is already installed"
  fi

  # Install Powerlevel10k theme
  print_title "Installing Powerlevel10k Theme"
  local P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [ ! -d "$P10K_DIR" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    print_success "Powerlevel10k installed"
  else
    print_success "Powerlevel10k is already installed"
  fi
}

install_packages() {
  print_title "Installing Official Repository Packages"

  # Update package database
  sudo pacman -Sy

  for PACKAGE in "${PACKAGES[@]}"; do
    if pacman -Qi "$PACKAGE" &> /dev/null; then
      echo "$PACKAGE is already installed"
    else
      print_title "Installing $PACKAGE..."
      sudo pacman -S --noconfirm "$PACKAGE"
    fi
  done

  print_success "Official packages installed"
}

install_aur_packages() {
  print_title "Installing AUR Packages"

  check_yay_installed

  for PACKAGE in "${AUR_PACKAGES[@]}"; do
    if yay -Qi "$PACKAGE" &> /dev/null || pacman -Qi "$PACKAGE" &> /dev/null; then
      echo "$PACKAGE is already installed"
    else
      print_title "Installing $PACKAGE from AUR..."
      yay -S --noconfirm "$PACKAGE"
    fi
  done

  print_success "AUR packages installed"
}

install_applications() {
  print_title "Installing GUI Applications from AUR"

  local response
  print_question "Do you want to install GUI applications? (y/n)"
  read -p "   > " response

  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    print_warning "Skipping GUI application installation"
    return
  fi

  check_yay_installed

  for APP in "${AUR_APPS[@]}"; do
    if yay -Qi "$APP" &> /dev/null || pacman -Qi "$APP" &> /dev/null; then
      echo "$APP is already installed"
    else
      print_title "Installing $APP from AUR..."
      yay -S --noconfirm "$APP"
    fi
  done

  print_success "GUI applications installed"
}

install_additional_tools() {
  print_title "Installing Additional Development Tools"

  # Install NVM (Node Version Manager)
  if [ ! -d "$HOME/.nvm" ]; then
    print_title "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    print_success "NVM installed"
  else
    print_success "NVM is already installed"
  fi

  # Install pnpm
  if ! command -v pnpm &> /dev/null; then
    print_title "Installing pnpm..."
    curl -fsSL https://get.pnpm.io/install.sh | sh -
    print_success "pnpm installed"
  else
    print_success "pnpm is already installed"
  fi

  # Install global npm packages
  print_title "Installing global npm packages..."
  if command -v npm &> /dev/null; then
    npm install -g @angular/cli stripe
    print_success "Global npm packages installed"
  fi

  # Install Supabase CLI
  if ! command -v supabase &> /dev/null; then
    print_title "Installing Supabase CLI..."
    curl -fsSL https://get.supabase.com/install/linux | sh
    print_success "Supabase CLI installed"
  else
    print_success "Supabase CLI is already installed"
  fi
}

setup_ssh() {
  print_title "Setting Up SSH"
  if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    local email
    email=$(prompt_for_input "Enter your email for SSH key:")
    ssh-keygen -t rsa -b 4096 -C "$email" -N "" -f "$HOME/.ssh/id_rsa"
    eval "$(ssh-agent -s)"
    ssh-add "$HOME/.ssh/id_rsa"
    echo ""
    print_success "SSH setup complete. Add the following public key to your GitHub account:"
    print_in_cyan "$(cat $HOME/.ssh/id_rsa.pub)"
    echo ""
  else
    print_success "SSH is already set up"
  fi
}

clone_dotfiles_repo() {
  print_title "Setting Up Dotfiles Repository"
  if [ ! -d "$DOTFILES_REPO" ]; then
    git clone https://github.com/peciulevicius/.dotfiles.git "$DOTFILES_REPO"
    print_success "Dotfiles repository cloned"
  else
    print_success "Dotfiles repository already exists at $DOTFILES_REPO"
  fi

  setup_symlinks
}

setup_symlinks() {
  print_title "Setting Up Symlinks for Dotfiles"

  # Backup and create symlinks for each config file
  for FILE in "${FILES[@]}"; do
    local source_file="$DOTFILES_REPO/$FILE"
    local target_file="$HOME/$(basename $FILE)"

    # Check if source file exists
    if [ ! -f "$source_file" ]; then
      print_warning "Source file $source_file does not exist, skipping..."
      continue
    fi

    # Backup existing file if it exists and is not a symlink
    if [ -f "$target_file" ] && [ ! -L "$target_file" ]; then
      print_warning "$(basename $FILE) already exists. Creating a backup."
      mv "$target_file" "${target_file}.backup"
    fi

    # Create symlink
    echo "Creating symlink: $target_file -> $source_file"
    ln -sf "$source_file" "$target_file"
  done

  print_success "Symlinks created successfully"
}

enable_docker() {
  print_title "Enabling Docker Service"
  if systemctl is-enabled docker &> /dev/null; then
    print_success "Docker service is already enabled"
  else
    sudo systemctl enable docker
    sudo systemctl start docker
    print_success "Docker service enabled and started"
  fi

  # Add user to docker group
  if groups $USER | grep &> /dev/null '\bdocker\b'; then
    print_success "User is already in docker group"
  else
    sudo usermod -aG docker $USER
    print_warning "User added to docker group. Log out and back in for changes to take effect."
  fi
}

change_shell_to_zsh() {
  print_title "Setting Zsh as Default Shell"
  if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s $(which zsh)
    print_success "Default shell changed to zsh. Please log out and back in."
  else
    print_success "Zsh is already the default shell"
  fi
}

main() {
  print_title "Starting Arch Linux setup..."

  install_oh_my_zsh
  install_packages
  install_aur_packages
  install_applications
  install_additional_tools
  setup_ssh
  clone_dotfiles_repo
  enable_docker
  change_shell_to_zsh

  print_line_break
  print_success "All done! Your Arch Linux development environment is set up."
  print_line_break
  print_warning "IMPORTANT: Please log out and back in for all changes to take effect."
  print_warning "Then run 'p10k configure' to customize your prompt."
  print_line_break
}

main
