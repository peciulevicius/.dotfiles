#!/bin/bash

# Determine the dotfiles directory based on the script's location
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

# Function to link the common .ideavimrc file
link_ideavimrc() {
    echo "Linking .ideavimrc"
    local source_path="${DOTFILES_DIR}/.ideavimrc"
    local target_path="${HOME}/.ideavimrc"

    if [ -f "$target_path" ]; then
        echo "$target_path already exists. Backup created."
        mv "$target_path" "${target_path}.backup"
    fi
    ln -s "$source_path" "$target_path"
}

# Detect OS and call the specific script
case "$(uname -s)" in
    Linux*)
        link_ideavimrc
        bash "${DOTFILES_DIR}/linux/install.sh"
        ;;
    Darwin*)
        link_ideavimrc
        bash "${DOTFILES_DIR}/macos/install.sh"
        ;;
    CYGWIN*|MINGW32*|MSYS*|MINGW*)
        link_ideavimrc
        powershell.exe -File "${DOTFILES_DIR}/windows/install.ps1"
        ;;
    *)
        echo "Unsupported OS detected."
        ;;
esac
