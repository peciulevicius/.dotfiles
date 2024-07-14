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

## Function to install Powerlevel10k theme if not already installed
#install_p10k() {
##  if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
#    echo "Installing Powerlevel10k..."
##    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
##  else
##    echo "Powerlevel10k is already installed"
##  fi
#}

# Update Homebrew and install necessary packages
install_packages() {
  echo "Updating Homebrew..."
  brew update

  PACKAGES=(
    git
    vim
    neovim
    zsh
    tmux
    docker
    nvm
    node
    gh
    thefuck
    pnpm
    yarn
    tree-sitter
  )

  echo "Installing necessary packages..."
  for PACKAGE in "${PACKAGES[@]}"; do
    if brew list $PACKAGE >/dev/null 2>&1; then
      echo "$PACKAGE is already installed"
    else
      echo "Installing $PACKAGE..."
      brew install $PACKAGE
    fi
  done

  if ! brew list powerlevel10k >/dev/null 2>&1; then
    echo "Installing Powerlevel10k..."
    brew install powerlevel10k
    echo "source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme" >>~/.zshrc
  else
    echo "Powerlevel10k is already installed"
  fi
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
   FILES_TO_CHECK=(
     .gitconfig
     .ideavimrc
#     .vimrc
     .zshrc
     .p10k.zsh
   )
#
#    FILES_TO_BACKUP=(
#      .gitignore
#      .idea/.dotfiles.iml
#      .idea/.gitignore
#      .idea/modules.xml
#      .idea/vcs.xml
#      README.md
#      install.sh
#      linux/install.sh
#      mac/install.sh
#      nvim/after/plugin/colors.lua
#      nvim/after/plugin/fugitive.lua
#      nvim/after/plugin/harpoon.lua
#      nvim/after/plugin/lsp.lua
#      nvim/after/plugin/telescope.lua
#      nvim/after/plugin/treesitter.lua
#      nvim/after/plugin/undotree.lua
#      nvim/init.lua
#      nvim/lua/peciulevicius/init.lua
#      nvim/lua/peciulevicius/packer.lua
#      nvim/lua/peciulevicius/remap.lua
#      nvim/lua/peciulevicius/set.lua
#      windows/.gitconfig
#      windows/.gitconfig-personal
#      windows/.gitconfig-work
#      windows/install.ps1
#    )
#
#    # Create a backup directory if it doesn't exist
#    mkdir -p ~/dotfiles_backup
#
#    # List of files to check and backup
#
#    # Loop through the files
#    for FILE in "${FILES_TO_BACKUP[@]}"; do
#      # If the file exists, move it to the backup directory
#      if [ -e "$HOME/$FILE" ]; then
#        echo "Moving $FILE to backup directory..."
#        mv "$HOME/$FILE" "~/dotfiles_backup/$FILE"
#      fi
#    done
    for FILE in "${FILES_TO_CHECK[@]}"; do
        if [ -f "$WORK_TREE/$FILE" ] || [ -d "$WORK_TREE/$FILE" ] || [ -L "$WORK_TREE/$FILE" ]; then
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

# Function to set up symlinks for dotfiles
setup_symlinks() {
  echo "Setting up symlinks for dotfiles..."

  DOTFILES_DIR=$HOME/.dotfiles
  FILES=(
     mac/.gitconfig
     mac/.ideavimrc
     mac/.p10k.zsh
     mac/.zshrc
  )

  for FILE in "${FILES[@]}"; do
    if [ -e "$HOME/$(basename $FILE)" ]; then
      echo "$(basename $FILE) already exists. Creating a backup."
      mv "$HOME/$(basename $FILE)" "$HOME/$(basename $FILE).backup"
    fi

    echo "Creating symlink for $FILE..."
    ln -sf "$DOTFILES_DIR/$FILE" "$HOME/$(basename $FILE)"
  done
}

# Main function
main() {
  install_homebrew
#  install_applications
  install_packages
  install_oh_my_zsh
#  install_p10k
  clone_dotfiles_repo

  echo "All done! Your development environment is set up."
}

main