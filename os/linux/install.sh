#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

# Import utility functions
. "../../scripts/utils/utils.sh"

print_section "Running Linux Dotfiles Setup"

# NOTE: This script is designed for Debian/Ubuntu-based distributions (apt).
# For Arch Linux, you'll need to:
# 1. Install yay AUR helper: https://github.com/Jguer/yay
# 2. Replace 'apt' commands with 'pacman' or 'yay'
# 3. Adjust package names for Arch repositories
# Example: docker.io -> docker, build-essential -> base-devel

DOTFILES_REPO="$HOME/.dotfiles"
PACKAGES=(
  git
  vim
  neovim
  zsh
  tmux
  docker.io
  nvm
  nodejs
  npm
  gh
  thefuck
  pnpm
  yarn
  tree-sitter
  curl
  build-essential
  software-properties-common
  apt-transport-https
  ca-certificates
  gnupg
  lsb-release
  openssh-client
  openssh-server
)
APPS=(
  nordpass
  nordvpn
  spotify-client
  google-chrome-stable
  notion-app
  webstorm
  code
  postman
  discord
  figma-linux
)

FILES=(
  config/git/.gitconfig
  config/idea/.ideavimrc
  config/zsh/.p10k.zsh
  config/zsh/.zshrc
)

install_oh_my_zsh() {
  print_title "Installing Oh My Zsh"
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "Oh My Zsh is already installed"
  fi
}

install_packages() {
  print_title "Installing Packages"
  sudo apt update

  for PACKAGE in "${PACKAGES[@]}"; do
    if dpkg -l | grep -q $PACKAGE; then
      echo "$PACKAGE is already installed"
    else
      sudo apt install -y $PACKAGE
    fi
  done

  if ! dpkg -l | grep -q powerlevel10k; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/.powerlevel10k
    echo 'source $HOME/.powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
  else
    echo "Powerlevel10k is already installed"
  fi
}

install_applications() {
  print_title "Installing Applications"

  # Add repositories and keys for third-party applications
  curl -fsSL https://download.spotify.com/debian/pubkey.gpg | sudo gpg --dearmor -o /usr/share/keyrings/spotify-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/spotify-archive-keyring.gpg] http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

  curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list

  sudo apt update

  for APP in "${APPS[@]}"; do
    if dpkg -l | grep -q $APP; then
      echo "$APP is already installed"
    else
      sudo apt install -y $APP
    fi
  done
}

setup_ssh() {
  print_title "Setting Up SSH"
  if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    local email
    email=$(prompt_for_input "Enter your email for SSH key:")
    ssh-keygen -t rsa -b 4096 -C "$email" -N "" -f "$HOME/.ssh/id_rsa"
    eval "$(ssh-agent -s)"
    ssh-add "$HOME/.ssh/id_rsa"
    echo "SSH setup complete. Add the following public key to your GitHub account:"
    cat "$HOME/.ssh/id_rsa.pub"
  else
    echo "SSH is already set up"
  fi
}

clone_dotfiles_repo() {
  print_title "Cloning Dotfiles Repository"
  if [ ! -d $DOTFILES_REPO ]; then
    git clone https://github.com/peciulevicius/.dotfiles.git $DOTFILES_REPO
  else
    echo "Dotfiles repository already exists at $DOTFILES_REPO"
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

main() {
  install_oh_my_zsh
  install_packages
  install_applications
  setup_ssh
  clone_dotfiles_repo

  print_success "All done! Your development environment is set up."
}

main
