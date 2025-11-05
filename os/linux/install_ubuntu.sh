#!/bin/bash

# Modern Ubuntu/Debian/Kali Linux Installer
# Works on: Ubuntu 20.04+, Debian 11+, Kali Linux, Pop!_OS, Linux Mint
# This installer sets up a complete modern development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get the dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

print_header() {
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════${NC}\n"
}

print_step() {
    echo -e "${CYAN}▸ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"

    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    while true; do
        read -p "$prompt" yn
        yn=${yn:-$default}
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

#═══════════════════════════════════════════════════════
# PHASE 1: System Update & Essential CLI Tools
#═══════════════════════════════════════════════════════

update_system() {
    print_header "PHASE 1: System Update"
    print_step "Updating package lists..."
    sudo apt update

    print_step "Upgrading installed packages..."
    sudo apt upgrade -y

    print_success "System updated"
}

install_essentials() {
    print_header "Installing Essential CLI Tools"

    local essentials=(
        git
        curl
        wget
        build-essential
        software-properties-common
        apt-transport-https
        ca-certificates
        gnupg
        lsb-release
        openssh-client
    )

    print_step "Installing: ${essentials[*]}"
    sudo apt install -y "${essentials[@]}"

    print_success "Essential tools installed"
}

install_github_cli() {
    print_header "Installing GitHub CLI"

    if command -v gh &> /dev/null; then
        print_success "GitHub CLI already installed"
        return
    fi

    print_step "Adding GitHub CLI repository..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

    sudo apt update
    sudo apt install -y gh

    print_success "GitHub CLI installed"
}

#═══════════════════════════════════════════════════════
# PHASE 2: Modern CLI Tools (Game Changers!)
#═══════════════════════════════════════════════════════

install_modern_cli_tools() {
    print_header "PHASE 2: Installing Modern CLI Tools"

    # bat - better cat with syntax highlighting
    if ! command -v bat &> /dev/null && ! command -v batcat &> /dev/null; then
        print_step "Installing bat (better cat)..."
        sudo apt install -y bat
        # Create bat alias if it's installed as batcat (Ubuntu)
        if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
            mkdir -p ~/.local/bin
            ln -sf /usr/bin/batcat ~/.local/bin/bat
        fi
        print_success "bat installed"
    fi

    # eza - better ls (replaces exa)
    if ! command -v eza &> /dev/null; then
        print_step "Installing eza (better ls)..."
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt update
        sudo apt install -y eza
        print_success "eza installed"
    fi

    # ripgrep - better grep
    if ! command -v rg &> /dev/null; then
        print_step "Installing ripgrep (better grep)..."
        sudo apt install -y ripgrep
        print_success "ripgrep installed"
    fi

    # fd - better find
    if ! command -v fd &> /dev/null && ! command -v fdfind &> /dev/null; then
        print_step "Installing fd (better find)..."
        sudo apt install -y fd-find
        # Create fd alias if it's installed as fdfind (Ubuntu)
        if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
            mkdir -p ~/.local/bin
            ln -sf /usr/bin/fdfind ~/.local/bin/fd
        fi
        print_success "fd installed"
    fi

    # fzf - fuzzy finder (ESSENTIAL)
    if ! command -v fzf &> /dev/null; then
        print_step "Installing fzf (fuzzy finder)..."
        sudo apt install -y fzf
        print_success "fzf installed"
    fi

    # zoxide - smart cd
    if ! command -v zoxide &> /dev/null; then
        print_step "Installing zoxide (smart cd)..."
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        print_success "zoxide installed"
    fi

    # tldr - simplified man pages
    if ! command -v tldr &> /dev/null; then
        print_step "Installing tldr (quick man pages)..."
        sudo apt install -y tldr
        print_success "tldr installed"
    fi

    # httpie - better curl for APIs
    if ! command -v http &> /dev/null; then
        print_step "Installing httpie (better curl)..."
        sudo apt install -y httpie
        print_success "httpie installed"
    fi

    # jq - JSON processor
    if ! command -v jq &> /dev/null; then
        print_step "Installing jq (JSON processor)..."
        sudo apt install -y jq
        print_success "jq installed"
    fi

    # delta - better git diff
    if ! command -v delta &> /dev/null; then
        print_step "Installing git-delta (better git diff)..."
        # Get latest delta release
        DELTA_VERSION=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
        wget -q "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb"
        sudo dpkg -i "git-delta_${DELTA_VERSION}_amd64.deb"
        rm "git-delta_${DELTA_VERSION}_amd64.deb"
        print_success "git-delta installed"
    fi

    print_success "Modern CLI tools installed!"
}

#═══════════════════════════════════════════════════════
# PHASE 3: Development Tools
#═══════════════════════════════════════════════════════

install_docker() {
    print_header "PHASE 3: Installing Docker"

    if command -v docker &> /dev/null; then
        print_success "Docker already installed"
        return
    fi

    print_step "Installing Docker..."

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add user to docker group
    sudo usermod -aG docker $USER

    print_success "Docker installed (you'll need to log out and back in for group changes)"
}

install_nodejs() {
    print_header "Installing Node.js & Package Managers"

    # Install nvm
    if [ ! -d "$HOME/.nvm" ]; then
        print_step "Installing nvm (Node Version Manager)..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        print_step "Installing Node.js LTS..."
        nvm install --lts
        nvm use --lts

        print_success "Node.js installed via nvm"
    else
        print_success "nvm already installed"
    fi

    # Install pnpm
    if ! command -v pnpm &> /dev/null; then
        print_step "Installing pnpm..."
        curl -fsSL https://get.pnpm.io/install.sh | sh -
        print_success "pnpm installed"
    fi
}

#═══════════════════════════════════════════════════════
# PHASE 4: Shell Setup (Zsh + Oh My Zsh + Powerlevel10k)
#═══════════════════════════════════════════════════════

install_zsh() {
    print_header "PHASE 4: Shell Setup"

    if ! command -v zsh &> /dev/null; then
        print_step "Installing zsh..."
        sudo apt install -y zsh
        print_success "zsh installed"
    fi

    if ask_yes_no "Install Oh My Zsh?" "y"; then
        if [ ! -d "$HOME/.oh-my-zsh" ]; then
            print_step "Installing Oh My Zsh..."
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
            print_success "Oh My Zsh installed"
        fi

        if ask_yes_no "Install Powerlevel10k theme?" "y"; then
            if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
                print_step "Installing Powerlevel10k..."
                git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
                print_success "Powerlevel10k installed"
                print_warning "Remember to run 'p10k configure' after shell restart"
            fi
        fi
    fi

    # Install Nerd Fonts
    if ask_yes_no "Install Nerd Fonts (for terminal icons)?" "y"; then
        print_step "Installing Nerd Fonts..."
        mkdir -p ~/.local/share/fonts

        # MesloLGS Nerd Font (recommended for p10k)
        cd ~/.local/share/fonts
        wget -q https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
        wget -q https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
        wget -q https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
        wget -q https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf

        fc-cache -f -v > /dev/null 2>&1
        cd - > /dev/null

        print_success "Nerd Fonts installed"
        print_warning "Set your terminal font to 'MesloLGS NF' or 'MesloLGS Nerd Font'"
    fi
}

#═══════════════════════════════════════════════════════
# PHASE 5: GUI Applications
#═══════════════════════════════════════════════════════

install_apps() {
    print_header "PHASE 5: GUI Applications"

    # Google Chrome
    if ask_yes_no "Install Google Chrome?" "y"; then
        if ! command -v google-chrome &> /dev/null; then
            print_step "Installing Google Chrome..."
            wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
            sudo dpkg -i google-chrome-stable_current_amd64.deb
            sudo apt install -f -y
            rm google-chrome-stable_current_amd64.deb
            print_success "Google Chrome installed"
        fi
    fi

    # VS Code
    if ask_yes_no "Install VS Code?" "y"; then
        if ! command -v code &> /dev/null; then
            print_step "Installing VS Code..."
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
            sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
            rm -f packages.microsoft.gpg

            sudo apt update
            sudo apt install -y code
            print_success "VS Code installed"
        fi
    fi

    # JetBrains Toolbox (for WebStorm)
    if ask_yes_no "Install JetBrains Toolbox? (for WebStorm)" "y"; then
        if [ ! -f "$HOME/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox" ]; then
            print_step "Installing JetBrains Toolbox..."
            wget -q https://download.jetbrains.com/toolbox/jetbrains-toolbox-2.1.3.18901.tar.gz
            tar -xzf jetbrains-toolbox-2.1.3.18901.tar.gz
            ./jetbrains-toolbox-*/jetbrains-toolbox &
            rm -rf jetbrains-toolbox-*
            print_success "JetBrains Toolbox installed (should open automatically)"
        fi
    fi

    # Docker Desktop (optional - already have Docker CLI)
    if ask_yes_no "Install Docker Desktop GUI?" "n"; then
        print_step "Installing Docker Desktop..."
        wget -q https://desktop.docker.com/linux/main/amd64/docker-desktop-4.26.1-amd64.deb
        sudo dpkg -i docker-desktop-4.26.1-amd64.deb
        sudo apt install -f -y
        rm docker-desktop-4.26.1-amd64.deb
        print_success "Docker Desktop installed"
    fi

    # Bitwarden
    if ask_yes_no "Install Bitwarden?" "y"; then
        if ! command -v bitwarden &> /dev/null; then
            print_step "Installing Bitwarden..."
            snap install bitwarden || {
                wget -q https://vault.bitwarden.com/download/?app=desktop\&platform=linux -O bitwarden.AppImage
                chmod +x bitwarden.AppImage
                mkdir -p ~/.local/bin
                mv bitwarden.AppImage ~/.local/bin/bitwarden
                print_warning "Bitwarden installed as AppImage in ~/.local/bin/"
            }
            print_success "Bitwarden installed"
        fi
    fi

    # NordPass
    if ask_yes_no "Install NordPass?" "y"; then
        print_step "Installing NordPass..."
        wget -q https://downloads.npass.app/linux/NordPass-latest.deb
        sudo dpkg -i NordPass-latest.deb
        sudo apt install -f -y
        rm NordPass-latest.deb
        print_success "NordPass installed"
    fi

    # NordVPN
    if ask_yes_no "Install NordVPN?" "y"; then
        print_step "Installing NordVPN..."
        wget -q https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/nordvpn-release_1.0.0_all.deb
        sudo dpkg -i nordvpn-release_1.0.0_all.deb
        sudo apt update
        sudo apt install -y nordvpn
        rm nordvpn-release_1.0.0_all.deb
        print_success "NordVPN installed"
    fi

    # Figma (via Snap or web)
    if ask_yes_no "Install Figma? (via figma-linux)" "y"; then
        if ! command -v figma-linux &> /dev/null; then
            print_step "Installing Figma..."
            sudo snap install figma-linux || print_warning "Could not install Figma via snap"
        fi
    fi

    # Notion
    if ask_yes_no "Install Notion?" "y"; then
        print_step "Installing Notion..."
        wget -q https://github.com/notion-enhancer/notion-repackaged/releases/latest/download/notion-app_amd64.deb
        sudo dpkg -i notion-app_amd64.deb
        sudo apt install -f -y
        rm notion-app_amd64.deb
        print_success "Notion installed"
    fi
}

#═══════════════════════════════════════════════════════
# PHASE 6: Dotfiles Setup
#═══════════════════════════════════════════════════════

setup_dotfiles() {
    print_header "PHASE 6: Setting Up Dotfiles"

    local files=(
        "config/git/.gitconfig:.gitconfig"
        "config/git/.gitignore_global:.gitignore_global"
        "config/zsh/.zshrc:.zshrc"
        "config/zsh/.p10k.zsh:.p10k.zsh"
        "config/idea/.ideavimrc:.ideavimrc"
        "config/tmux/.tmux.conf:.tmux.conf"
        "config/ssh/config:.ssh/config"
        "config/curl/.curlrc:.curlrc"
        "config/.editorconfig:.editorconfig"
    )

    for file_mapping in "${files[@]}"; do
        IFS=':' read -r source target <<< "$file_mapping"
        source_file="$DOTFILES_DIR/$source"
        target_file="$HOME/$target"

        if [ ! -f "$source_file" ]; then
            continue
        fi

        # Create parent directory if needed
        target_dir=$(dirname "$target_file")
        mkdir -p "$target_dir"

        # Backup existing file
        if [ -f "$target_file" ] && [ ! -L "$target_file" ]; then
            print_warning "Backing up existing $target"
            mv "$target_file" "${target_file}.backup"
        fi

        # Create symlink
        print_step "Linking $target"
        ln -sf "$source_file" "$target_file"
    done

    # Set proper permissions for SSH config
    if [ -f "$HOME/.ssh/config" ]; then
        chmod 600 "$HOME/.ssh/config"
    fi

    print_success "Dotfiles symlinked"
}

setup_ssh() {
    print_header "Setting Up SSH"

    if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
        if ask_yes_no "Generate SSH key?" "y"; then
            read -p "Enter your email for SSH key: " email
            ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""
            eval "$(ssh-agent -s)"
            ssh-add "$HOME/.ssh/id_ed25519"

            print_success "SSH key generated"
            echo -e "\n${GREEN}Your SSH public key:${NC}"
            cat "$HOME/.ssh/id_ed25519.pub"
            echo -e "\n${YELLOW}Add this to GitHub: https://github.com/settings/keys${NC}\n"
        fi
    else
        print_success "SSH key already exists"
    fi
}

setup_github() {
    print_header "Setting Up GitHub"

    if command -v gh &> /dev/null; then
        if ! gh auth status &> /dev/null; then
            if ask_yes_no "Authenticate with GitHub CLI?" "y"; then
                gh auth login
                print_success "GitHub authenticated"
            fi
        else
            print_success "Already authenticated with GitHub"
        fi
    fi
}

change_shell() {
    if command -v zsh &> /dev/null; then
        if [ "$SHELL" != "$(which zsh)" ]; then
            if ask_yes_no "Change default shell to zsh?" "y"; then
                chsh -s $(which zsh)
                print_success "Default shell changed to zsh"
                print_warning "You'll need to log out and back in for shell change to take effect"
            fi
        fi
    fi
}

#═══════════════════════════════════════════════════════
# MAIN
#═══════════════════════════════════════════════════════

print_summary() {
    print_header "Installation Complete! 🎉"

    echo -e "${GREEN}What was installed:${NC}"
    echo "  ✓ Essential CLI tools (git, gh, curl, wget, build tools)"
    echo "  ✓ Modern CLI tools (bat, eza, ripgrep, fd, fzf, zoxide, tldr, httpie, jq, delta)"
    echo "  ✓ Development tools (Docker, Node.js via nvm, pnpm)"
    echo "  ✓ Shell setup (zsh, Oh My Zsh, Powerlevel10k, Nerd Fonts)"
    echo "  ✓ GUI applications (as selected)"
    echo "  ✓ Dotfiles configuration"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Log out and log back in (for group changes and shell)"
    echo "  2. Set terminal font to 'MesloLGS NF' for best experience"
    echo "  3. Run 'p10k configure' to customize your prompt"
    echo "  4. Open JetBrains Toolbox and install WebStorm"
    echo "  5. Sign into your apps (Bitwarden, NordPass, etc.)"
    echo ""
    echo -e "${CYAN}Useful commands:${NC}"
    echo "  bat <file>          - View files with syntax highlighting"
    echo "  eza -la             - Better ls with icons"
    echo "  rg <pattern>        - Lightning fast search"
    echo "  fd <name>           - Quick file finding"
    echo "  fzf                 - Fuzzy finder (Ctrl+R for history)"
    echo "  z <dir>             - Smart jump to directories"
    echo "  tldr <command>      - Quick command examples"
    echo ""
    echo -e "${GREEN}Check out the docs/ folder for more information!${NC}"
    echo ""
}

main() {
    clear
    echo -e "${PURPLE}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║                                                       ║"
    echo "║       Modern Ubuntu/Debian/Kali Installer            ║"
    echo "║                                                       ║"
    echo "║  Setting up your development environment...          ║"
    echo "║                                                       ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"

    update_system
    install_essentials
    install_github_cli
    install_modern_cli_tools
    install_docker
    install_nodejs
    install_zsh
    install_apps
    setup_dotfiles
    setup_ssh
    setup_github
    change_shell

    print_summary
}

main
