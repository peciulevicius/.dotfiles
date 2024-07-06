#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to install Homebrew if not already installed
install_homebrew() {
  if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "Homebrew is already installed"
  fi
}

# Function to install Oh My Zsh if not already installed
install_oh_my_zsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "Oh My Zsh is already installed"
  fi
}

# Function to install Powerlevel10k theme if not already installed
install_p10k() {
  if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    echo "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
  else
    echo "Powerlevel10k is already installed"
  fi
}

# Update Homebrew and install necessary packages
install_packages() {
  echo "Updating Homebrew..."
  brew update

  echo "Installing necessary packages..."
  brew install git vim neovim zsh tmux docker nvm node gh thefuck pnpm yarn tree-sitter
}

# Install applications with Homebrew Cask
install_applications() {
  echo "Installing applications with Homebrew Cask..."
  brew install --cask iterm2
  brew install --cask raycast
  brew install --cask unnaturalscrollwheels
  brew install --cask monitorcontrol
  brew install --cask nordpass
  brew install --cask nordvpn
  brew install --cask spotify
  brew install --cask notion
  brew install --cask webstorm
  brew install --cask visual-studio-code
  brew install --cask postman
  brew install --cask the-unarchiver
  brew install --cask tg-pro
}

# Function to set up symlinks for dotfiles
setup_symlinks() {
  echo "Setting up symlinks for dotfiles..."

  DOTFILES_DIR=$HOME/dotfiles

  ln -sf $DOTFILES_DIR/.zshrc $HOME/.zshrc
  ln -sf $DOTFILES_DIR/.p10k.zsh $HOME/.p10k.zsh
  ln -sf $DOTFILES_DIR/.vimrc $HOME/.vimrc
  ln -sf $DOTFILES_DIR/.gitconfig $HOME/.gitconfig
  ln -sf $DOTFILES_DIR/.ideavimrc $HOME/.ideavimrc
}

# Clone dotfiles repository and set up symlinks
clone_dotfiles_repo() {
  echo "Cloning dotfiles repository..."
  git clone --bare https://github.com/peciulevicius/.dotfiles.git $HOME/.dotfiles
  git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME checkout

  setup_symlinks
}

# Main function
main() {
  install_homebrew
  install_applications
  install_packages
  install_oh_my_zsh
  install_p10k
  clone_dotfiles_repo

  echo "All done! Your development environment is set up."
}

main
