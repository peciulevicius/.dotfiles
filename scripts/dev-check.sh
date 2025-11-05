#!/bin/bash

# Development Environment Health Check
# Verifies that all development tools are properly installed and configured
#
# Usage: ./dev-check.sh

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"
}

check_command() {
    local cmd="$1"
    local name="${2:-$1}"

    if command -v "$cmd" &> /dev/null; then
        local version=$($cmd --version 2>&1 | head -n 1)
        echo -e "${GREEN}✓${NC} $name: $version"
        return 0
    else
        echo -e "${RED}✗${NC} $name: Not installed"
        return 1
    fi
}

check_file() {
    local file="$1"
    local name="$2"

    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $name: $file"
        return 0
    else
        echo -e "${RED}✗${NC} $name: Not found"
        return 1
    fi
}

check_dir() {
    local dir="$1"
    local name="$2"

    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $name: $dir"
        return 0
    else
        echo -e "${RED}✗${NC} $name: Not found"
        return 1
    fi
}

TOTAL=0
PASSED=0

increment() {
    TOTAL=$((TOTAL + 1))
    if [ $? -eq 0 ]; then
        PASSED=$((PASSED + 1))
    fi
}

print_header "Development Environment Health Check"

OS="$(uname -s)"
echo "Operating System: $OS"
echo "Hostname: $(hostname)"
echo "User: $USER"
echo ""

# ═══════════════════════════════════════════════════════
# System Info
# ═══════════════════════════════════════════════════════

print_header "System Information"

if [[ "$OS" == "Darwin" ]]; then
    echo "macOS Version: $(sw_vers -productVersion)"
    echo "Chip: $(uname -m)"
elif [[ "$OS" == "Linux" ]]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "Distribution: $NAME $VERSION"
    fi
    echo "Kernel: $(uname -r)"
fi

echo "Shell: $SHELL"
echo "Terminal: $TERM"

# ═══════════════════════════════════════════════════════
# Essential Tools
# ═══════════════════════════════════════════════════════

print_header "Essential Tools"

check_command git "Git"
increment

check_command gh "GitHub CLI"
increment

check_command curl "curl"
increment

check_command wget "wget"
increment

check_command zsh "Zsh"
increment

# ═══════════════════════════════════════════════════════
# Modern CLI Tools
# ═══════════════════════════════════════════════════════

print_header "Modern CLI Tools"

check_command bat "bat"
increment

check_command eza "eza"
increment

check_command rg "ripgrep"
increment

check_command fd "fd"
increment

check_command fzf "fzf"
increment

check_command zoxide "zoxide"
increment

check_command tldr "tldr"
increment

check_command http "httpie"
increment

check_command jq "jq"
increment

check_command delta "git-delta"
increment

# ═══════════════════════════════════════════════════════
# Package Managers
# ═══════════════════════════════════════════════════════

print_header "Package Managers"

if [[ "$OS" == "Darwin" ]]; then
    check_command brew "Homebrew"
    increment
elif [[ "$OS" == "Linux" ]]; then
    if command -v pacman &> /dev/null; then
        check_command pacman "Pacman"
        increment
        check_command yay "Yay (AUR)"
        increment
    elif command -v apt &> /dev/null; then
        check_command apt "APT"
        increment
    elif command -v dnf &> /dev/null; then
        check_command dnf "DNF"
        increment
    fi
fi

# ═══════════════════════════════════════════════════════
# Development Tools
# ═══════════════════════════════════════════════════════

print_header "Development Tools"

check_command docker "Docker"
increment

if command -v docker &> /dev/null; then
    if docker ps &> /dev/null; then
        echo -e "${GREEN}✓${NC} Docker: Running"
    else
        echo -e "${YELLOW}⚠${NC} Docker: Installed but not running"
    fi
fi

check_command node "Node.js"
increment

if command -v node &> /dev/null; then
    node_version=$(node --version)
    npm_version=$(npm --version)
    echo -e "${CYAN}  ├─${NC} Node: $node_version"
    echo -e "${CYAN}  └─${NC} npm: $npm_version"
fi

check_command nvm "NVM"
increment

check_command pnpm "pnpm"
increment

check_command code "VS Code"
increment

# ═══════════════════════════════════════════════════════
# Languages & Runtimes
# ═══════════════════════════════════════════════════════

print_header "Languages & Runtimes"

if command -v python3 &> /dev/null; then
    python_version=$(python3 --version)
    echo -e "${GREEN}✓${NC} Python: $python_version"
    increment
else
    echo -e "${RED}✗${NC} Python: Not installed"
    increment
fi

if command -v pip3 &> /dev/null; then
    pip_version=$(pip3 --version | awk '{print $2}')
    echo -e "${CYAN}  └─${NC} pip: $pip_version"
fi

if command -v ruby &> /dev/null; then
    ruby_version=$(ruby --version)
    echo -e "${GREEN}✓${NC} Ruby: $ruby_version"
    increment
else
    echo -e "${YELLOW}⚠${NC} Ruby: Not installed (optional)"
    increment
fi

if command -v go &> /dev/null; then
    go_version=$(go version)
    echo -e "${GREEN}✓${NC} Go: $go_version"
    increment
else
    echo -e "${YELLOW}⚠${NC} Go: Not installed (optional)"
    increment
fi

if command -v rustc &> /dev/null; then
    rust_version=$(rustc --version)
    echo -e "${GREEN}✓${NC} Rust: $rust_version"
    increment
else
    echo -e "${YELLOW}⚠${NC} Rust: Not installed (optional)"
    increment
fi

# ═══════════════════════════════════════════════════════
# Configuration Files
# ═══════════════════════════════════════════════════════

print_header "Configuration Files"

check_file "$HOME/.gitconfig" "Git config"
increment

check_file "$HOME/.gitignore_global" "Git ignore global"
increment

check_file "$HOME/.zshrc" "Zsh config"
increment

check_file "$HOME/.dotfiles/config/starship/starship.toml" "Starship config"
increment

check_file "$HOME/.ideavimrc" "IdeaVim config"
increment

check_file "$HOME/.tmux.conf" "Tmux config"
increment

check_file "$HOME/.ssh/config" "SSH config"
increment

check_file "$HOME/.editorconfig" "EditorConfig"
increment

# ═══════════════════════════════════════════════════════
# SSH Keys
# ═══════════════════════════════════════════════════════

print_header "SSH Keys"

if [ -f "$HOME/.ssh/id_ed25519" ]; then
    echo -e "${GREEN}✓${NC} SSH key (ed25519): $HOME/.ssh/id_ed25519"
    echo -e "${CYAN}  └─${NC} Public key:"
    cat "$HOME/.ssh/id_ed25519.pub" | head -c 60
    echo "..."
    increment
elif [ -f "$HOME/.ssh/id_rsa" ]; then
    echo -e "${GREEN}✓${NC} SSH key (RSA): $HOME/.ssh/id_rsa"
    echo -e "${YELLOW}  ⚠${NC} Consider upgrading to ed25519"
    increment
else
    echo -e "${RED}✗${NC} No SSH key found"
    echo -e "${CYAN}  └─${NC} Generate one with: ssh-keygen -t ed25519 -C \"your@email.com\""
    increment
fi

# Check if SSH key is added to agent
if ssh-add -l &> /dev/null; then
    echo -e "${GREEN}✓${NC} SSH agent: Keys loaded"
else
    echo -e "${YELLOW}⚠${NC} SSH agent: No keys loaded"
    echo -e "${CYAN}  └─${NC} Add with: ssh-add ~/.ssh/id_ed25519"
fi

# ═══════════════════════════════════════════════════════
# GitHub Authentication
# ═══════════════════════════════════════════════════════

print_header "GitHub Authentication"

if command -v gh &> /dev/null; then
    if gh auth status &> /dev/null; then
        echo -e "${GREEN}✓${NC} GitHub CLI: Authenticated"
        gh_user=$(gh api user -q .login)
        echo -e "${CYAN}  └─${NC} Logged in as: $gh_user"
        increment
    else
        echo -e "${RED}✗${NC} GitHub CLI: Not authenticated"
        echo -e "${CYAN}  └─${NC} Authenticate with: gh auth login"
        increment
    fi
fi

# ═══════════════════════════════════════════════════════
# Dotfiles Repository
# ═══════════════════════════════════════════════════════

print_header "Dotfiles Repository"

if [ -d "$HOME/.dotfiles" ]; then
    echo -e "${GREEN}✓${NC} Dotfiles: $HOME/.dotfiles"

    cd "$HOME/.dotfiles"

    # Check git status
    if [ -d ".git" ]; then
        branch=$(git branch --show-current)
        echo -e "${CYAN}  ├─${NC} Branch: $branch"

        if [[ -n $(git status -s) ]]; then
            echo -e "${YELLOW}  ├─${NC} Status: Uncommitted changes"
        else
            echo -e "${GREEN}  ├─${NC} Status: Clean"
        fi

        # Check if up to date with remote
        git fetch origin &> /dev/null
        LOCAL=$(git rev-parse @)
        REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")

        if [ -n "$REMOTE" ]; then
            if [ $LOCAL = $REMOTE ]; then
                echo -e "${GREEN}  └─${NC} Up to date with remote"
            else
                echo -e "${YELLOW}  └─${NC} Out of sync with remote (pull needed)"
            fi
        fi
    fi

    cd - > /dev/null
    increment
else
    echo -e "${RED}✗${NC} Dotfiles: Not found"
    echo -e "${CYAN}  └─${NC} Clone with: git clone https://github.com/yourusername/.dotfiles ~/.dotfiles"
    increment
fi

# ═══════════════════════════════════════════════════════
# Shell Environment
# ═══════════════════════════════════════════════════════

print_header "Shell Environment"

if [ -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${GREEN}✓${NC} Oh My Zsh: Installed"
    increment
else
    echo -e "${YELLOW}⚠${NC} Oh My Zsh: Not installed"
    increment
fi

if command -v starship &> /dev/null; then
    echo -e "${GREEN}✓${NC} Starship: Installed ($(starship --version | head -n1))"
    increment
else
    echo -e "${YELLOW}⚠${NC} Starship: Not installed"
    increment
fi

# Check if Nerd Font is being used
if [[ "$TERM_PROGRAM" == "iTerm.app" ]] || [[ "$TERM_PROGRAM" == "vscode" ]]; then
    echo -e "${GREEN}✓${NC} Terminal: $TERM_PROGRAM"
else
    echo -e "${CYAN}ℹ${NC} Terminal: $TERM_PROGRAM"
fi

# ═══════════════════════════════════════════════════════
# Network
# ═══════════════════════════════════════════════════════

print_header "Network Connectivity"

if ping -c 1 github.com &> /dev/null; then
    echo -e "${GREEN}✓${NC} Internet: Connected"
    echo -e "${GREEN}✓${NC} GitHub: Reachable"
else
    echo -e "${RED}✗${NC} Internet/GitHub: Not reachable"
fi

# ═══════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════

print_header "Summary"

PERCENT=$((PASSED * 100 / TOTAL))

echo "Health Check Results:"
echo ""
echo -e "  Passed:  ${GREEN}$PASSED${NC} / $TOTAL ($PERCENT%)"
echo -e "  Failed:  ${RED}$((TOTAL - PASSED))${NC} / $TOTAL"
echo ""

if [ $PERCENT -ge 90 ]; then
    echo -e "${GREEN}✓ Your development environment is in great shape!${NC}"
elif [ $PERCENT -ge 70 ]; then
    echo -e "${YELLOW}⚠ Your development environment is mostly healthy, but some tools are missing.${NC}"
else
    echo -e "${RED}✗ Your development environment needs attention.${NC}"
fi

echo ""
echo "Quick fixes:"
echo "  • Install missing tools: Run the appropriate installer from os/"
echo "  • Update packages: Run scripts/update.sh"
echo "  • Fix SSH: ssh-keygen -t ed25519 -C \"your@email.com\""
echo "  • Fix GitHub: gh auth login"
echo ""
