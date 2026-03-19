#!/bin/bash

# macOS Unified Installer (single source of truth)
# Keep setup clean and practical for both laptop and Mac mini.

set -uo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AUTO_CONFIRM=false

# Core CLI tools for daily development.
CORE_FORMULAS=(
  git         # Version control
  gh          # GitHub CLI (PRs/issues/auth)
  wget        # Robust file downloads
  bat         # Better cat with syntax highlighting
  eza         # Better ls
  ripgrep     # Fast code/text search (rg)
  fd          # Fast file finder
  fzf         # Fuzzy finder for history/files
  zoxide      # Smart cd
  tlrc        # tldr command examples client
  httpie      # Friendly HTTP client (http)
  jq          # JSON parser and transformer
  git-delta   # Better git diff output
  nvm         # Node version manager
  pnpm        # Fast Node package manager
  starship    # Prompt
  rclone      # Cloud backup (B2/S3 sync)
  cloudflared # Cloudflare Tunnel (HTTPS for self-hosted services)
  syncthing   # Peer-to-peer file sync (Obsidian vault across devices)
)

# Optional local AI tools.
AI_FORMULAS=(
  ollama      # Local model manager/server
  llama.cpp   # Local inference and benchmarking CLI
)

# Core apps you asked for.
CORE_CASKS=(
  google-chrome          # Main browser
  brave-browser          # Secondary privacy browser
  visual-studio-code     # Editor
  docker                 # Containers
  tailscale              # Private network (remote access, Immich from phone anywhere)
  claude                 # Claude desktop app
  bitwarden              # Password manager
  jetbrains-toolbox      # Install/manage JetBrains IDEs (instead of direct WebStorm cask)
  discord                # Team/community chat
  figma                  # Design/collaboration
  wispr-flow             # Voice dictation workflow
  darktable              # Photo workflow
  calibre                # Ebook library manager
  obsidian               # Notes / second brain (synced via Syncthing)
  logi-options+          # Logitech devices config
  yt-music               # YouTube Music desktop app
  the-unarchiver         # Archive extraction utility
  tg-pro                 # Mac thermal/system monitor
)

# Optional apps to keep off by default for cleanliness.
OPTIONAL_CASKS=(
  iterm2    # Alternative terminal (skip if Terminal.app is enough)
  raycast   # Launcher (skip if Spotlight is enough)
  orbstack  # Lightweight Docker Desktop alternative (faster on Mac, same docker commands)
)

# Optional cloud coding-agent apps/tools (off by default).
# These can require subscriptions or API spend depending on provider/plan.
AI_AGENT_CASKS=(
  claude-code       # Anthropic Claude Code desktop/launcher cask
  opencode-desktop  # OpenCode desktop client
)

# Kindle app note: no direct Homebrew cask found as of 2026-02-25.
MANUAL_APPS=(
  "Kindle app (install from Amazon/App Store manually)"
)

CONFIG_FILES=(
  "config/git/.gitconfig:.gitconfig"
  "config/git/.gitignore_global:.gitignore_global"
  "config/git/.gitmessage:.gitmessage"
  "config/zsh/.zshrc:.zshrc"
  "config/idea/.ideavimrc:.ideavimrc"
  "config/tmux/.tmux.conf:.tmux.conf"
  "config/ssh/config:.ssh/config"
  "config/curl/.curlrc:.curlrc"
  "config/.editorconfig:.editorconfig"
)

usage() {
  cat <<USAGE
Usage: ./os/mac/install.sh [options]

Options:
  --yes                  Non-interactive mode (accept defaults)
  -h, --help             Show this help

Recommended:
  ./os/mac/install.sh
USAGE
}

log_header() {
  echo -e "\n${BLUE}========================================${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}========================================${NC}"
}

log_ok() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }

confirm() {
  local prompt="$1"
  local default_yes="${2:-true}"

  if [[ "$AUTO_CONFIRM" == "true" ]]; then
    [[ "$default_yes" == "true" ]] && return 0 || return 1
  fi

  local suffix="[Y/n]"
  [[ "$default_yes" == "false" ]] && suffix="[y/N]"
  read -r -p "$prompt $suffix " answer

  if [[ -z "$answer" ]]; then
    [[ "$default_yes" == "true" ]] && return 0 || return 1
  fi

  [[ "$answer" =~ ^[Yy]$ ]]
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    log_ok "Homebrew already installed"
    return
  fi

  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  log_ok "Homebrew installed"
}

install_formula_list() {
  local list_name="$1"
  shift
  local packages=("$@")

  [[ ${#packages[@]} -eq 0 ]] && return

  log_header "Installing $list_name"
  for pkg in "${packages[@]}"; do
    if brew list "$pkg" >/dev/null 2>&1; then
      log_ok "$pkg already installed"
    else
      echo "Installing $pkg..."
      brew install "$pkg"
    fi
  done
}

install_cask_list() {
  local list_name="$1"
  shift
  local casks=("$@")

  [[ ${#casks[@]} -eq 0 ]] && return

  log_header "Installing $list_name"
  for app in "${casks[@]}"; do
    if brew list --cask "$app" >/dev/null 2>&1; then
      log_ok "$app already installed"
    else
      echo "Installing $app..."
      install_output="$(brew install --cask "$app" 2>&1)" || {
        if echo "$install_output" | rg -q "already an App at '/Applications/"; then
          log_warn "$app already present in /Applications (not Homebrew-managed), skipping"
          continue
        fi
        if echo "$install_output" | rg -q "a terminal is required to read the password|password is required"; then
          log_warn "$app needs interactive sudo installer; install manually later"
          continue
        fi
        log_warn "$app failed to install; continuing"
        echo "$install_output"
        continue
      }
      echo "$install_output"
    fi
  done
}

link_dotfiles() {
  log_header "Linking Configuration Files"

  for mapping in "${CONFIG_FILES[@]}"; do
    IFS=':' read -r source target <<< "$mapping"
    local source_file="$DOTFILES_DIR/$source"
    local target_file="$HOME/$target"

    [[ -f "$source_file" ]] || continue
    mkdir -p "$(dirname "$target_file")"

    if [[ -f "$target_file" && ! -L "$target_file" ]]; then
      mv "$target_file" "${target_file}.backup.$(date +%Y%m%d_%H%M%S)"
      log_warn "Backed up existing $target"
    fi

    ln -sf "$source_file" "$target_file"
    log_ok "Linked $target"
  done

  [[ -f "$HOME/.ssh/config" ]] && chmod 600 "$HOME/.ssh/config"
}

setup_docker_config() {
  local src="$DOTFILES_DIR/config/docker/daemon.json"
  local dest="$HOME/.docker/daemon.json"

  [[ -f "$src" ]] || return

  mkdir -p "$HOME/.docker"

  if [[ -f "$dest" ]]; then
    # Merge: ensure default-address-pools is set (Docker Desktop may add its own keys)
    if ! grep -q "default-address-pools" "$dest" 2>/dev/null; then
      cp "$dest" "${dest}.backup.$(date +%Y%m%d_%H%M%S)"
      cp "$src" "$dest"
      log_warn "Docker daemon.json updated (old config backed up)"
      log_warn "Restart Docker Desktop to apply network pool changes"
    else
      log_ok "Docker daemon.json already configured"
    fi
  else
    cp "$src" "$dest"
    log_ok "Docker daemon.json created (network pool: /24 subnets)"
  fi
}

setup_code_cli() {
  local code_app="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  if [[ -x "$code_app" ]]; then
    mkdir -p /opt/homebrew/bin
    ln -sf "$code_app" /opt/homebrew/bin/code || true
    log_ok "VS Code CLI linked"
  fi
}

post_install_summary() {
  log_header "Setup Complete"
  echo "Next steps:"
  echo "  1) source ~/.zshrc"
  echo "  2) mkdir -p ~/.nvm && nvm install --lts"
  echo "  3) gh auth login"
  echo "  4) ssh-add ~/.ssh/id_ed25519"
  echo "  5) scripts/dev-check.sh"
  echo ""
  echo "Optional second script (macOS defaults):"
  echo "  os/mac/setup_macos_preferences.sh"
  echo ""
  echo "Manual installs:"
  for app in "${MANUAL_APPS[@]}"; do
    echo "  • $app"
  done
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --yes)
        AUTO_CONFIRM=true
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done
}

maybe_setup_services() {
  echo ""
  if confirm "Stage self-hosted services to ~/docker/?" false; then
    if command -v docker &>/dev/null; then
      bash "$DOTFILES_DIR/services/setup-services.sh"
    else
      log_warn "Docker not found — run services/setup-services.sh after installing Docker"
    fi
  fi
}

maybe_setup_obsidian() {
  if confirm "Set up Obsidian vault at ~/obsidian-vault/?" false; then
    bash "$DOTFILES_DIR/scripts/setup/setup-obsidian.sh"
  fi
  mkdir -p "$HOME/logs"
}

run_interactive() {
  log_header "macOS Unified Installer"
  echo "Lean setup with your requested apps and no unnecessary defaults."

  brew update
  install_formula_list "Core CLI Tools" "${CORE_FORMULAS[@]}"

  if confirm "Install core apps (browsers, editors, business + utility apps)?" true; then
    install_cask_list "Core Apps" "${CORE_CASKS[@]}"
  fi

  if confirm "Install local AI tools (Ollama + llama.cpp)?" true; then
    install_formula_list "Local AI Tools" "${AI_FORMULAS[@]}"
  fi

  if confirm "Install extra optional apps (iTerm2, Raycast)?" false; then
    install_cask_list "Optional Apps" "${OPTIONAL_CASKS[@]}"
  fi

  if confirm "Install optional AI coding-agent apps (Claude Code, OpenCode Desktop)?" false; then
    install_cask_list "AI Coding-Agent Apps" "${AI_AGENT_CASKS[@]}"
  fi

  link_dotfiles
  setup_docker_config
  setup_code_cli
  post_install_summary
  maybe_setup_services
  maybe_setup_obsidian
}

main() {
  parse_args "$@"
  ensure_homebrew
  run_interactive
}

main "$@"
