#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Install dos2unix if not already installed
if ! command -v dos2unix &> /dev/null; then
  sudo apt update
  sudo apt install -y dos2unix
fi

# Convert utils.sh to Unix-style line endings
dos2unix ../../scripts/utils/utils.sh

# Source utility functions
source ../../scripts/utils/utils.sh

print_section "Running WSL Dotfiles Setup"

DOTFILES_REPO="$HOME/.dotfiles"
PACKAGES=(
  git
  vim
  neovim
  zsh
  tmux
  docker.io
  nodejs
  npm
  gh
  thefuck
  yarn
  tree-sitter
  curl
)
FILES=(
  config/git/.gitconfig
  config/idea/.ideavimrc
  config/zsh/.zshrc
  # Note: Starship config is in ~/.dotfiles/config/starship/starship.toml
  # No need to symlink - STARSHIP_CONFIG env var points to it (set in .zshrc)
)

install_shell_prompt() {
  print_title "Installing Starship Prompt"

  # Install Starship if not already installed
  if ! command -v starship &> /dev/null; then
    echo "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  else
    echo "Starship is already installed"
  fi

  # Optional: Install Oh My Zsh for plugins (not required for prompt)
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    read -p "Install Oh My Zsh for additional plugins? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
      echo "Oh My Zsh installed"
    fi
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
}

install_nvm() {
  print_title "Installing NVM (Node Version Manager)"
  if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  else
    echo "NVM is already installed"
  fi
}

install_pnpm() {
  print_title "Installing PNPM (Package Manager)"
  curl -fsSL https://get.pnpm.io/install.sh | sh -
}

install_cli_tools() {
  print_title "Installing Additional CLI Tools"
  sudo npm install -g stripe @angular/cli
}

install_supabase_cli() {
  print_title "Installing Supabase CLI"
  curl -fsSL https://get.supabase.com/install/linux | sh
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
  install_shell_prompt
  install_packages
  install_nvm
  install_pnpm
  install_cli_tools
  install_supabase_cli
  setup_ssh
  clone_dotfiles_repo

  print_success "All done! Your development environment is set up."
}

main