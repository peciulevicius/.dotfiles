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
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
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

# Helper function to check if an application is already installed in /Applications
app_is_installed() {
  if [ -d "/Applications/$1.app" ]; then
    return 0  # 0 means true/success in bash
  else
    return 1  # 1 means false/error
  fi
}

# Function to check if an application is installed via Homebrew Cask
is_cask_installed() {
  brew list --cask "$1" &>/dev/null
}

# Install applications with Homebrew Cask
install_applications() {
  echo "Installing applications with Homebrew Cask..."

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

  for CASK in "${CASKS[@]}"; do
    if app_is_installed "$CASK"; then
      echo "$CASK app already installed in '/Applications', skipping."
    elif is_cask_installed "$CASK"; then
      echo "$CASK is already installed by Homebrew, skipping."
    else
      echo "Installing $CASK..."
      brew install --cask "$CASK"
    fi
  done
}

# Function to set up symlinks for dotfiles
setup_symlinks() {
  echo "Setting up symlinks for dotfiles..."

  DOTFILES_DIR=$HOME/dotfiles
  FILES=(
    .zshrc
    .p10k.zsh
    .vimrc
    .gitconfig
    .ideavimrc
  )

  for FILE in "${FILES[@]}"; do
    if [ -e "$HOME/$FILE" ]; then
      echo "$FILE already exists. Creating a backup."
      mv "$HOME/$FILE" "$HOME/${FILE}.backup"
    fi
    ln -sf "$DOTFILES_DIR/$FILE" "$HOME/$FILE"
  done
}

#clone_dotfiles_repo() {
#  echo "Cloning dotfiles repository..."
#  git clone --bare https://github.com/peciulevicius/.dotfiles.git $HOME/.dotfiles
#  git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME checkout
#
#  setup_symlinks
#}

# Clone dotfiles repository and set up symlinks
clone_dotfiles_repo() {
    echo "Cloning dotfiles repository..."
    DOTFILES_REPO="$HOME/.dotfiles"
    WORK_TREE="$HOME"
    GIT_DIR="--git-dir=$DOTFILES_REPO/ --work-tree=$WORK_TREE"

    if [ ! -d $DOTFILES_REPO ]; then
        git clone --bare https://github.com/peciulevicius/.dotfiles.git $DOTFILES_REPO
    fi

    # Backup and remove existing dotfiles before checkout
   FILES_TO_CHECK=(.gitconfig .idea .ideavimrc .zshrc)
    for FILE in "${FILES_TO_CHECK[@]}"; do
        if [ -f "$WORK_TREE/$FILE" ] || [ -d "$WORK_TREE/$FILE" ]; then
            echo "$FILE exists, backing up..."
            mv "$WORK_TREE/$FILE" "$WORK_TREE/${FILE}.backup"
        fi
    done

    # Checkout dotfiles
    git $GIT_DIR checkout
    if [ $? != 0 ]; then
        echo "Error checking out dotfiles, possible conflicts."
    else
        echo "Dotfiles checked out successfully."
    fi

    setup_symlinks
}

# Main function
main() {
  install_homebrew
#  install_applications
  install_packages
  install_oh_my_zsh
  install_p10k
  clone_dotfiles_repo

  echo "All done! Your development environment is set up."
}

main