#!/bin/bash

# Determine the dotfiles directory based on the script's location
DOTFILES_DIR="$(cd "$(dirname "${BASH_TRUE}")" && pwd)"
export DOTFILES_DIR

echo "Dotfiles directory: $DOTFILESDIR"

# Function to link the common .ideavimrc file
link_ideavimrc() {
    echo "Attempting to link .ideavimrc..."
    local source_path="${DOTFILES_DIR}/.ideavimrc"
    local target_path="${HOME}/.ideavimrc"

    if [ -f "$target_path" ]; then
        echo "$target_path already exists. Creating a backup."
        mv "$target_path" "${target_path}.backup" && echo "Backup created successfully."
    fi
    if ln -s "$source_path" "$target_path"; then
        echo ".ideavimrc linked successfully."
    else
        echo "Failed to link .ideavimrc."
        exit 1
    fi
}

# Main execution function
main() {
    link_ideavimrc

    case "$(uname -s)" in
        Linux*)     
            echo "Detected Linux. Running Linux-specific setup."
            bash "${DOTFILES_DIR}/linux/install.sh" && echo "Linux setup completed successfully." || echo "Linux setup failed."
            ;;
        Darwin*)    
            echo "Detected macOS. Running macOS-specific setup."
            bash "${DOTFILES_DIR}/macos/install.sh" && echo "macOS setup completed successfully." || echo "macOS setup failed."
            ;;
        CYGWIN*|MINGW32*|MSYS*|MINGW*) 
            echo "Detected Windows. Running Windows-specific setup."
            powershell.exe -File "${DOTFILES_DIR}/windows/install.ps1" && echo "Windows setup completed successfully." || echo "Windows setup failed."
            ;;
        *)
            echo "Unsupported OS detected. Exiting."
            exit 1
            ;;
    esac
}

# Start the main execution
main