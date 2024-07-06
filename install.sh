#!/bin/bash

# Determine the dotfiles directory based on the script's location
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

echo "Dotfiles directory: $DOTFILES_DIR"

# Function to link the common .ideavimrc file
link_ideavimrc() {
    echo "Attempting to link .ideavimrc..."
    local source_path="${DOTFILES_DIR}/.ideavimrc"
    local target_path="${HOME}/.ideavimrc"

    if [ -f "$target_path" ]; then
        echo "$target_path already exists. Creating a backup."
        mv "$target_path" "${target_path}.backup"
    fi
    ln -s "$source_path" "$target_path" && echo ".ideavimrc linked successfully."
}

# Detect the operating system
OS="$(uname -s)"
case "$OS" in
    Linux*)
        # Check if running under WSL (Windows Subsystem for Linux)
        if grep -qi microsoft /proc/version; then
            echo "Detected WSL environment. Running Windows-specific setup."
            # Assuming powershell.exe is in your path; adjust if needed
            powershell.exe -File "$DOTFILES_DIR/windows/install.ps1"
        else
            echo "Detected Linux. Running Linux-specific setup."
            link_ideavimrc
            bash "$DOTFILES_DIR/linux/install.sh"
        fi
        ;;
    Darwin*)
        echo "Detected macOS. Running macOS-specific setup."
        link_ideavimrc
        bash "$DOTFILES_DIR/macos/install.sh"
        ;;
    *)
        echo "Unsupported OS detected."
        ;;
esac