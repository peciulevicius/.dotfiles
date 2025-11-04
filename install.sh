#!/bin/bash

# Determine the dotfiles directory based on the script's location
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Dotfiles directory: $DOTFILES_DIR"

# Main execution function
main() {
    OS="$(uname -s)"
    case "$OS" in
        Linux*)
            # Detecting WSL environment
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "Detected WSL environment. Running Windows-specific setup."
                # Convert to Windows path for PowerShell (only in WSL)
                DOTFILES_WIN_PATH=$(wslpath -w "$DOTFILES_DIR" 2>/dev/null || echo "$DOTFILES_DIR")
                powershell.exe -File "${DOTFILES_WIN_PATH}\\os\\windows\\install.ps1"
            else
                echo "Detected Linux."

                # Check if Arch Linux
                if [ -f /etc/arch-release ]; then
                    echo "Arch Linux detected."
                    echo ""
                    echo "Choose installer:"
                    echo "  1) Arch-specific (uses pacman/yay)"
                    echo "  2) Generic (uses apt - not recommended)"
                    echo ""
                    read -p "Enter choice (1 or 2): " choice

                    case $choice in
                        1)
                            bash "$DOTFILES_DIR/os/linux/install_arch.sh"
                            ;;
                        2)
                            bash "$DOTFILES_DIR/os/linux/install.sh"
                            ;;
                        *)
                            echo "Running Arch installer..."
                            bash "$DOTFILES_DIR/os/linux/install_arch.sh"
                            ;;
                    esac
                else
                    # Debian/Ubuntu or other
                    bash "$DOTFILES_DIR/os/linux/install.sh"
                fi
            fi
            ;;
        Darwin*)
            echo "Detected macOS."
            echo ""
            echo "Choose installation type:"
            echo "  1) Minimal (recommended) - Git, GitHub CLI, SSH, dotfiles only"
            echo "  2) Full - Installs many packages (not recommended)"
            echo ""
            read -p "Enter choice (1 or 2, default=1): " choice

            case $choice in
                2)
                    echo "Running full setup..."
                    bash "$DOTFILES_DIR/os/mac/install.sh"
                    ;;
                *)
                    echo "Running minimal setup..."
                    bash "$DOTFILES_DIR/os/mac/install_minimal.sh"
                    ;;
            esac
            ;;
        *)
            echo "Unsupported OS detected."
            exit 1
            ;;
    esac
}

# Start the script
main