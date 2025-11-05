#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

GREEN='\033[0;32m'
DOTFILES_REPO="$HOME/.dotfiles"
PACKAGES=(
  git
  vim
  neovim
  zsh
  tmux
  docker
  nvm
  node
  npm
  gh
  thefuck
  pnpm
  yarn
  tree-sitter
  stripe/stripe-cli/stripe
  supabase/tap/supabase
  angular-cli
)
CASKS=(
  iterm2
  raycast
  unnaturalscrollwheels
  monitorcontrol
  nordpass
  nordvpn
  spotify
  notion
  webstorm
  visual-studio-code
  postman
  the-unarchiver
  tg-pro
)
FILES=(
  config/git/.gitconfig
  config/idea/.ideavimrc
  config/zsh/.p10k.zsh
  config/zsh/.zshrc
)

install_homebrew() {
  if ! command -v brew &> /dev/null; then
    echo -e "${GREEN}Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "Homebrew is already installed"
  fi
}

install_oh_my_zsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${GREEN}Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "Oh My Zsh is already installed"
  fi
}

install_packages() {
  echo -e "${GREEN}Updating Homebrew..."
  brew update

  echo -e "${GREEN}Installing necessary packages..."
  for PACKAGE in "${PACKAGES[@]}"; do
    if brew list $PACKAGE >/dev/null 2>&1; then
      echo "$PACKAGE is already installed"
    else
      echo "Installing $PACKAGE..."
      brew install $PACKAGE
    fi
  done

  if ! brew list powerlevel10k >/dev/null 2>&1; then
    echo -e "${GREEN}Installing Powerlevel10k..."
    brew install powerlevel10k
    echo "source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme" >>~/.zshrc
  else
    echo "Powerlevel10k is already installed"
  fi
}

is_app_installed() {
  if [ -d "/Applications/$1.app" ]; then
    return 0  # 0 means true/success in bash
  else
    return 1  # 1 means false/error
  fi
}

is_cask_installed() {
  brew list --cask "$1" &>/dev/null
}

install_applications() {
  echo -e "${GREEN}Installing applications with Homebrew Cask..."

  for CASK in "${CASKS[@]}"; do
    if is_app_installed "$CASK"; then
      echo "$CASK app already installed in '/Applications', skipping."
    elif is_cask_installed "$CASK"; then
      echo "$CASK is already installed by Homebrew, skipping."
    else
      echo "Installing $CASK..."
      brew install --cask "$CASK"
    fi
  done
}

clone_dotfiles_repo() {
    echo -e "${GREEN}Cloning dotfiles repository..."

    if [ ! -d $DOTFILES_REPO ]; then
        git clone https://github.com/peciulevicius/.dotfiles.git $DOTFILES_REPO
    else
        echo "Dotfiles repository already exists at $DOTFILES_REPO"
    fi

    setup_symlinks
}

setup_symlinks() {
  echo -e "${GREEN}Setting up symlinks for dotfiles..."

  # Backup and create symlinks for each config file
  for FILE in "${FILES[@]}"; do
    local source_file="$DOTFILES_REPO/$FILE"
    local target_file="$HOME/$(basename $FILE)"

    # Check if source file exists
    if [ ! -f "$source_file" ]; then
      echo "Warning: Source file $source_file does not exist, skipping..."
      continue
    fi

    # Backup existing file if it exists and is not a symlink
    if [ -f "$target_file" ] && [ ! -L "$target_file" ]; then
      echo "$(basename $FILE) already exists. Creating a backup."
      mv "$target_file" "${target_file}.backup"
    fi

    # Create symlink
    echo "Creating symlink: $target_file -> $source_file"
    ln -sf "$source_file" "$target_file"
  done

  echo -e "${GREEN}Symlinks created successfully"
}

main() {
  install_homebrew
  install_oh_my_zsh
  install_packages
  #  install_applications
  clone_dotfiles_repo

  echo -e "${GREEN}All done! Your development environment is set up."
}

main
