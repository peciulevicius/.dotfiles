#!/bin/bash

# Determine the dotfiles directory based on the script's location
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Convert from WSL path to Windows path (e.g., /mnt/c to C:\)
DOTFILES_WIN_PATH=$(wslpath -w "$DOTFILES_DIR")

echo "Dotfiles directory: $DOTFILES_DIR"
echo "Dotfiles Windows directory: $DOTFILES_WIN_PATH"

## Function to link the common .ideavimrc file
#link_ideavimrc() {
#    echo "Attempting to link .ideavimrc..."
#    local source_path="${DOTFILES_DIR}/.ideavimrc"
#    local target_path="${HOME}/.ideavimrc"
#
#    if [ -f "$target_path" ]; then
#        echo "$target_path already exists. Creating a backup."
#        mv "$target_path" "${target_path}.backup"
#    fi
#    ln -s "$source_path" "$target_path" && echo ".ideavimrc linked successfully."
#}

# Main execution function
main() {
    OS="$(uname -s)"
    case "$OS" in
        Linux*)
            # Detecting WSL environment
            if grep -qi microsoft /proc/version; then
                echo "Detected WSL environment. Running Windows-specific setup."
                # Use the converted Windows path format
                powershell.exe -File "${DOTFILES_WIN_PATH}\\windows\\install.ps1"
            else
                echo "Detected Linux. Running Linux-specific setup."
#                link_ideavimrc
                bash "$DOTFILES_DIR/os/linux/install.sh"
            fi
            ;;
        Darwin*)
            echo "Detected macOS. Running macOS-specific setup."
#            link_ideavimrc
            bash "$DOTFILES_DIR/os/mac/install.sh"
            ;;
        *)
            echo "Unsupported OS detected."
            ;;
    esac
}

# Start the script
main