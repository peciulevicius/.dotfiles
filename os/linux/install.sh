#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

# Import utility functions
. "../../scripts/utils/utils.sh"

print_section "Running Linux Dotfiles Setup"

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
  linux/.gitconfig
  linux/.ideavimrc
  linux/.p10k.zsh
  linux/.zshrc
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

main() {
  install_oh_my_zsh
  install_packages
  install_applications
  setup_ssh
  clone_dotfiles_repo

  print_success "All done! Your development environment is set up."
}

main
