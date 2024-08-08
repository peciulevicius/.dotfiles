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
  ../../config/git/.gitconfig
  ../../idea/.ideavimrc
  ../../zsh/.p10k.zsh
  ../../zsh/.zshrc
)

install_oh_my_zsh() {
  print_title "Installing Oh My Zsh"
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "Oh My Zsh is already installed"
  fi

  echo "Setting up Powerlevel10k theme..."
  if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
  else
    echo "Powerlevel10k is already installed"
  fi

  if ! grep -q 'ZSH_THEME="powerlevel10k/powerlevel10k"' ~/.zshrc; then
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
  fi

  if ! grep -q 'source ~/.p10k.zsh' ~/.zshrc; then
    echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >>~/.zshrc
  fi

  echo "Sourcing .zshrc to apply changes..."
  zsh -c 'source ~/.zshrc && p10k configure'
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
  fi

  # Backup and remove existing dotfiles before checkout
  for FILE in "${FILES[@]}"; do
    if [ -f "$HOME/$(basename $FILE)" ]; then
      echo "$(basename $FILE) already exists. Creating a backup."
      mv "$HOME/$(basename $FILE)" "$HOME/$(basename $FILE).backup"
    fi
  done

  # Checkout dotfiles
  git -C $DOTFILES_REPO checkout
  if [ $? != 0 ]; then
    echo "Error checking out dotfiles, possible conflicts."
  else
    echo "Dotfiles checked out successfully."
  fi

  setup_symlinks
}

setup_symlinks() {
  print_title "Setting Up Symlinks for Dotfiles"
  for FILE in "${FILES[@]}"; do
    echo "Creating symlink for $FILE..."
    ln -sf "$DOTFILES_REPO/$FILE" "$HOME/$(basename $FILE)"
  done
}

# TODO: needs cleanup
main() {
  install_oh_my_zsh
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