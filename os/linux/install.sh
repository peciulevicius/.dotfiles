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
  linux/.gitconfig
  linux/.ideavimrc
  linux/.p10k.zsh
  linux/.zshrc
)

install_oh_my_zsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${GREEN}Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "Oh My Zsh is already installed"
  fi
}

install_packages() {
  echo -e "${GREEN}Updating package list..."
  sudo apt update

  echo -e "${GREEN}Installing necessary packages..."
  for PACKAGE in "${PACKAGES[@]}"; do
    if dpkg -l | grep -q $PACKAGE; then
      echo "$PACKAGE is already installed"
    else
      echo "Installing $PACKAGE..."
      sudo apt install -y $PACKAGE
    fi
  done

  if ! dpkg -l | grep -q powerlevel10k; then
    echo -e "${GREEN}Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/.powerlevel10k
    echo 'source $HOME/.powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
  else
    echo "Powerlevel10k is already installed"
  fi
}

install_applications() {
  echo -e "${GREEN}Installing applications..."

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
      echo "Installing $APP..."
      sudo apt install -y $APP
    fi
  done
}

clone_dotfiles_repo() {
    echo -e "${GREEN}Cloning dotfiles repository..."

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
  echo -e "${GREEN}Setting up symlinks for dotfiles..."

  for FILE in "${FILES[@]}"; do
    echo "Creating symlink for $FILE..."
    ln -sf "$DOTFILES_REPO/$FILE" "$HOME/$(basename $FILE)"
  done
}

main() {
  install_oh_my_zsh
  install_packages
  install_applications
  clone_dotfiles_repo

  echo -e "${GREEN}All done! Your development environment is set up."
}

main
