#!/bin/bash

# Development Environment Health Check
# Verifies that development tools are installed and configured
#
# Usage: ./dev-check.sh

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

TOTAL_REQUIRED=0
PASSED_REQUIRED=0
TOTAL_OPTIONAL=0
PASSED_OPTIONAL=0

MISSING_REQUIRED=()
MISSING_OPTIONAL=()

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"
}

record_result() {
    local tier="$1"
    local ok="$2"
    local name="$3"
    local details="$4"
    local install_hint="$5"

    if [[ "$tier" == "required" ]]; then
        TOTAL_REQUIRED=$((TOTAL_REQUIRED + 1))
        if [[ "$ok" == "true" ]]; then
            PASSED_REQUIRED=$((PASSED_REQUIRED + 1))
            echo -e "${GREEN}✓${NC} $name: $details"
        else
            echo -e "${RED}✗${NC} $name: $details"
            [[ -n "$install_hint" ]] && MISSING_REQUIRED+=("$install_hint")
        fi
    else
        TOTAL_OPTIONAL=$((TOTAL_OPTIONAL + 1))
        if [[ "$ok" == "true" ]]; then
            PASSED_OPTIONAL=$((PASSED_OPTIONAL + 1))
            echo -e "${GREEN}✓${NC} $name: $details"
        else
            echo -e "${YELLOW}⚠${NC} $name: $details"
            [[ -n "$install_hint" ]] && MISSING_OPTIONAL+=("$install_hint")
        fi
    fi
}

check_command() {
    local tier="$1"
    local cmd="$2"
    local name="$3"
    local install_hint="$4"
    local version_cmd="${5:-$cmd --version}"

    if command -v "$cmd" >/dev/null 2>&1; then
        local version
        version=$(eval "$version_cmd" 2>&1 | head -n 1)
        record_result "$tier" "true" "$name" "$version" ""
    else
        local missing_label="Not installed"
        if [[ "$tier" == "optional" ]]; then
            missing_label="Not installed (optional)"
        fi
        record_result "$tier" "false" "$name" "$missing_label" "$install_hint"
    fi
}

check_file() {
    local tier="$1"
    local file="$2"
    local name="$3"

    if [[ -f "$file" ]]; then
        record_result "$tier" "true" "$name" "$file" ""
    else
        record_result "$tier" "false" "$name" "Not found" ""
    fi
}

print_header "Development Environment Health Check"

OS="$(uname -s)"
echo "Operating System: $OS"
echo "Hostname: $(hostname)"
echo "User: $USER"
echo ""

print_header "System Information"

if [[ "$OS" == "Darwin" ]]; then
    echo "macOS Version: $(sw_vers -productVersion)"
    echo "Chip: $(uname -m)"
elif [[ "$OS" == "Linux" ]]; then
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "Distribution: $NAME $VERSION"
    fi
    echo "Kernel: $(uname -r)"
fi

echo "Shell: $SHELL"
echo "Terminal: $TERM"

print_header "Essential Tools"

check_command required git "Git" "brew install git"
check_command required curl "curl" "brew install curl" "curl -q --version"
check_command required zsh "Zsh" "brew install zsh"

if [[ "$OS" == "Darwin" ]]; then
    check_command required brew "Homebrew" "Install from: https://brew.sh"
fi

check_command optional gh "GitHub CLI" "brew install gh"
check_command optional wget "wget" "brew install wget"

print_header "Modern CLI Tools (Recommended)"

check_command optional bat "bat" "brew install bat"
check_command optional eza "eza" "brew install eza"
check_command optional rg "ripgrep" "brew install ripgrep"
check_command optional fd "fd" "brew install fd"
check_command optional fzf "fzf" "brew install fzf"
check_command optional zoxide "zoxide" "brew install zoxide"
if command -v tldr >/dev/null 2>&1; then
    record_result optional true "tldr (tlrc client)" "$(tldr --version 2>&1 | head -n1)" ""
else
    record_result optional false "tlrc (tldr client)" "Not installed (optional)" "brew install tlrc"
fi
check_command optional http "httpie" "brew install httpie"
check_command optional jq "jq" "brew install jq"
check_command optional delta "git-delta" "brew install git-delta"

print_header "Development Tools"

check_command optional docker "Docker" "brew install --cask docker"
if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Docker daemon: Running"
    else
        echo -e "${YELLOW}⚠${NC} Docker daemon: Installed but not running"
    fi
fi

check_command required node "Node.js" "brew install node"
if command -v node >/dev/null 2>&1; then
    echo -e "${CYAN}  ├─${NC} Node: $(node --version)"
    if command -v npm >/dev/null 2>&1; then
        echo -e "${CYAN}  └─${NC} npm: $(npm --version)"
    fi
fi

if command -v nvm >/dev/null 2>&1 || [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]] || [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    nvm_version_output=$(nvm --version 2>/dev/null | head -n1)
    if [[ -z "$nvm_version_output" ]]; then
        nvm_version_output="Installed (load in shell with source ~/.zshrc)"
    fi
    record_result optional true "NVM" "$nvm_version_output" ""
else
    record_result optional false "NVM" "Not installed (optional)" "brew install nvm"
fi
check_command optional pnpm "pnpm" "brew install pnpm"
check_command optional code "VS Code" "brew install --cask visual-studio-code" "code --version 2>/dev/null"

print_header "Local AI Tools (Optional)"

if command -v ollama >/dev/null 2>&1; then
    record_result optional true "Ollama" "Installed" ""
else
    record_result optional false "Ollama" "Not installed (optional)" "brew install ollama"
fi

if command -v ollama >/dev/null 2>&1; then
    if pgrep -x ollama >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Ollama service: Running"
    else
        echo -e "${YELLOW}⚠${NC} Ollama service: Installed but not running"
        echo -e "${CYAN}  └─${NC} Start with: brew services start ollama"
    fi
fi

if command -v llama-cli >/dev/null 2>&1; then
    record_result optional true "llama.cpp" "llama-cli available" ""
else
    record_result optional false "llama.cpp" "Not installed (optional)" "brew install llama.cpp"
fi

if [[ "$OS" == "Darwin" ]]; then
    print_header "Productivity Apps (Optional)"

    if [[ -d "/Applications/Wispr Flow.app" ]]; then
        record_result optional true "Wispr Flow" "Installed" ""
    else
        record_result optional false "Wispr Flow" "Not installed (optional)" "brew install --cask wispr-flow"
    fi

    if [[ -d "/Applications/Raycast.app" ]]; then
        record_result optional true "Raycast" "Installed" ""
    else
        record_result optional false "Raycast" "Not installed (optional)" "brew install --cask raycast"
    fi
fi

print_header "Languages & Runtimes"

if command -v python3 >/dev/null 2>&1; then
    record_result required true "Python" "$(python3 --version)" ""
    if command -v pip3 >/dev/null 2>&1; then
        echo -e "${CYAN}  └─${NC} pip: $(pip3 --version | awk '{print $2}')"
    fi
else
    record_result required false "Python" "Not installed" "brew install python"
fi

if command -v ruby >/dev/null 2>&1; then
    record_result optional true "Ruby" "$(ruby --version)" ""
else
    record_result optional false "Ruby" "Not installed (optional)" "brew install ruby"
fi

if command -v go >/dev/null 2>&1; then
    record_result optional true "Go" "$(go version)" ""
else
    record_result optional false "Go" "Not installed (optional)" "brew install go"
fi

if command -v rustc >/dev/null 2>&1; then
    record_result optional true "Rust" "$(rustc --version)" ""
else
    record_result optional false "Rust" "Not installed (optional)" "brew install rust"
fi

print_header "Configuration Files"

check_file required "$HOME/.gitconfig" "Git config"
check_file required "$HOME/.gitignore_global" "Git ignore global"
check_file required "$HOME/.zshrc" "Zsh config"
check_file required "$HOME/.dotfiles/config/starship/starship.toml" "Starship config"
check_file required "$HOME/.ideavimrc" "IdeaVim config"
check_file required "$HOME/.tmux.conf" "Tmux config"
check_file required "$HOME/.ssh/config" "SSH config"
check_file required "$HOME/.editorconfig" "EditorConfig"

print_header "SSH Keys"

if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
    record_result required true "SSH key (ed25519)" "$HOME/.ssh/id_ed25519" ""
    if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
        echo -e "${CYAN}  └─${NC} Public key:"
        head -c 60 "$HOME/.ssh/id_ed25519.pub"
        echo "..."
    fi
elif [[ -f "$HOME/.ssh/id_rsa" ]]; then
    record_result optional true "SSH key (RSA)" "$HOME/.ssh/id_rsa" ""
    echo -e "${YELLOW}  ⚠${NC} Consider upgrading to ed25519"
else
    record_result required false "SSH key" "Not found" "ssh-keygen -t ed25519 -C \"your@email.com\""
fi

if ssh-add -l >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} SSH agent: Keys loaded"
else
    echo -e "${YELLOW}⚠${NC} SSH agent: No keys loaded"
    echo -e "${CYAN}  └─${NC} Add with: ssh-add ~/.ssh/id_ed25519"
fi

print_header "GitHub Authentication"

if command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then
        record_result optional true "GitHub CLI auth" "Authenticated" ""
        gh_user=$(gh api user -q .login 2>/dev/null || true)
        [[ -n "$gh_user" ]] && echo -e "${CYAN}  └─${NC} Logged in as: $gh_user"
    else
        record_result optional false "GitHub CLI auth" "Not authenticated" "gh auth login"
    fi
else
    record_result optional false "GitHub CLI auth" "GitHub CLI not installed" "brew install gh"
fi

print_header "Dotfiles Repository"

if [[ -d "$HOME/.dotfiles/.git" ]]; then
    echo -e "${GREEN}✓${NC} Dotfiles: $HOME/.dotfiles"
    cd "$HOME/.dotfiles" || exit 1

    echo -e "${CYAN}  ├─${NC} Branch: $(git branch --show-current)"
    if [[ -n $(git status -s) ]]; then
        echo -e "${YELLOW}  ├─${NC} Status: Uncommitted changes"
    else
        echo -e "${GREEN}  ├─${NC} Status: Clean"
    fi

    git fetch origin >/dev/null 2>&1 || true
    LOCAL=$(git rev-parse @ 2>/dev/null || echo "")
    REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")

    if [[ -n "$LOCAL" && -n "$REMOTE" && "$LOCAL" == "$REMOTE" ]]; then
        echo -e "${GREEN}  └─${NC} Up to date with remote"
    elif [[ -n "$REMOTE" ]]; then
        echo -e "${YELLOW}  └─${NC} Out of sync with remote (pull needed)"
    else
        echo -e "${YELLOW}  └─${NC} No upstream branch configured"
    fi

    cd - >/dev/null || exit 1
    record_result required true "Dotfiles repo" "Repository found" ""
else
    record_result required false "Dotfiles repo" "Not found" "git clone https://github.com/yourusername/.dotfiles ~/.dotfiles"
fi

print_header "Shell Environment"

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    record_result optional true "Oh My Zsh" "Installed" ""
else
    record_result optional false "Oh My Zsh" "Not installed (optional)" "Install from: https://ohmyz.sh"
fi

if command -v starship >/dev/null 2>&1; then
    record_result optional true "Starship" "$(starship --version | head -n1)" ""
else
    record_result optional false "Starship" "Not installed (optional)" "brew install starship"
fi

if [[ -n "$TERM_PROGRAM" ]]; then
    echo -e "${CYAN}ℹ${NC} Terminal: $TERM_PROGRAM"
fi

print_header "Network Connectivity"

if command -v curl >/dev/null 2>&1; then
    if curl -q -s --max-time 5 https://github.com >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Internet: Connected"
        echo -e "${GREEN}✓${NC} GitHub: Reachable"
    else
        echo -e "${YELLOW}⚠${NC} GitHub reachability: Could not verify with curl"
    fi
else
    if ping -c 1 github.com >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Internet/GitHub: Reachable"
    else
        echo -e "${YELLOW}⚠${NC} Internet/GitHub: Could not verify"
    fi
fi

print_header "Self-Hosted Services"

check_command optional rclone "rclone" "brew install rclone"

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    DOCKER_DIR="$HOME/docker"
    SERVICES=(immich vaultwarden nextcloud uptime-kuma freshrss ollama syncthing portainer watchtower homarr paperless-ngx calibre-web)

    if [[ -d "$DOCKER_DIR" ]]; then
        staged_count=0
        running_count=0
        for svc in "${SERVICES[@]}"; do
            [[ -d "$DOCKER_DIR/$svc" ]] && staged_count=$((staged_count + 1))
            if docker ps --format '{{.Names}}' 2>/dev/null | grep -qi "$svc"; then
                running_count=$((running_count + 1))
            fi
        done
        record_result optional true "Docker services staged" "$staged_count / ${#SERVICES[@]} services in $DOCKER_DIR" ""
        echo -e "${CYAN}  └─${NC} Running containers: $running_count"
    else
        record_result optional false "Docker services" "~/docker/ not found — run services/setup-services.sh" "services/setup-services.sh"
    fi

    OBSIDIAN_VAULT="$HOME/obsidian-vault"
    if [[ -d "$OBSIDIAN_VAULT/.obsidian" ]]; then
        record_result optional true "Obsidian vault" "$OBSIDIAN_VAULT" ""
        if [[ -d "$OBSIDIAN_VAULT/.git" ]]; then
            echo -e "${CYAN}  └─${NC} Git backup: enabled"
        else
            echo -e "${YELLOW}  └─${NC} Git backup: not set up (run: cd ~/obsidian-vault && git init)"
        fi
    else
        record_result optional false "Obsidian vault" "Not found — run scripts/setup-obsidian.sh" "scripts/setup-obsidian.sh"
    fi
fi

print_header "Summary"

REQUIRED_PERCENT=0
if [[ $TOTAL_REQUIRED -gt 0 ]]; then
    REQUIRED_PERCENT=$((PASSED_REQUIRED * 100 / TOTAL_REQUIRED))
fi

echo "Health Check Results:"
echo ""
echo -e "  Required passed: ${GREEN}$PASSED_REQUIRED${NC} / $TOTAL_REQUIRED (${REQUIRED_PERCENT}%)"
echo -e "  Required failed: ${RED}$((TOTAL_REQUIRED - PASSED_REQUIRED))${NC}"
echo -e "  Optional passed: ${GREEN}$PASSED_OPTIONAL${NC} / $TOTAL_OPTIONAL"
echo -e "  Optional missing: ${YELLOW}$((TOTAL_OPTIONAL - PASSED_OPTIONAL))${NC}"
echo ""

if [[ $REQUIRED_PERCENT -ge 95 ]]; then
    echo -e "${GREEN}✓ Core environment is healthy.${NC}"
elif [[ $REQUIRED_PERCENT -ge 75 ]]; then
    echo -e "${YELLOW}⚠ Core environment is usable but missing key items.${NC}"
else
    echo -e "${RED}✗ Core environment needs attention.${NC}"
fi

echo ""
echo "Quick fixes:"
echo "  • Sync dotfiles: scripts/sync.sh"
echo "  • Update packages: scripts/update.sh"

auto_install_mac_cmd() {
    local cli_list=()
    local cask_list=()
    local item

    for item in "$@"; do
        case "$item" in
            brew\ install\ --cask\ *)
                cask_list+=("${item#brew install --cask }")
                ;;
            brew\ install\ *)
                cli_list+=("${item#brew install }")
                ;;
            *)
                ;;
        esac
    done

    if [[ ${#cli_list[@]} -gt 0 ]]; then
        local cli_unique
        cli_unique=$(printf '%s\n' "${cli_list[@]}" | awk 'NF && !seen[$0]++')
        printf '%s\n' "  • Install missing CLI tools:"
        printf '%s\n' "$cli_unique" | awk '{printf "    brew install %s\n", $0}'
    fi

    if [[ ${#cask_list[@]} -gt 0 ]]; then
        local cask_unique
        cask_unique=$(printf '%s\n' "${cask_list[@]}" | awk 'NF && !seen[$0]++')
        printf '%s\n' "  • Install missing casks:"
        printf '%s\n' "$cask_unique" | awk '{printf "    brew install --cask %s\n", $0}'
    fi
}

if [[ "$OS" == "Darwin" ]]; then
    auto_install_mac_cmd "${MISSING_REQUIRED[@]}" "${MISSING_OPTIONAL[@]}"
fi

manual_action_list() {
    local actions=()
    local item

    for item in "$@"; do
        case "$item" in
            brew\ install\ *|brew\ install\ --cask\ *) ;;
            "") ;;
            *) actions+=("$item") ;;
        esac
    done

    if [[ ${#actions[@]} -gt 0 ]]; then
        printf '%s\n' "${actions[@]}" | awk 'NF && !seen[$0]++' | awk '{printf "  • %s\n", $0}'
    fi
}

manual_action_list "${MISSING_REQUIRED[@]}" "${MISSING_OPTIONAL[@]}"

echo ""
