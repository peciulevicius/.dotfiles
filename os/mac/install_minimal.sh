#!/bin/bash

# Minimal macOS Setup - Only Essentials
# Run this if you want just the basics without bloat

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

DOTFILES_REPO="$HOME/.dotfiles"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Minimal macOS Dotfiles Setup${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Essential packages only
ESSENTIAL_PACKAGES=(
  git
  gh           # GitHub CLI
  zsh          # Already installed on macOS, but listed for completeness
)

# Modern CLI tools (optional but highly recommended)
MODERN_CLI_TOOLS=(
  bat          # Better cat with syntax highlighting
  eza          # Better ls with icons and git status
  ripgrep      # Better grep - insanely fast (rg)
  fd           # Better find - simple and fast
  fzf          # Fuzzy finder - ESSENTIAL for productivity
  zoxide       # Smart cd - learns your most-used directories
  tldr         # Simplified man pages with examples
  httpie       # Better curl for testing APIs
  jq           # JSON processor - essential for API work
  git-delta    # Better git diff with syntax highlighting
)

# Essential dotfiles to symlink
FILES=(
  config/git/.gitconfig
  config/idea/.ideavimrc
  config/zsh/.zshrc
  config/zsh/.p10k.zsh
)

print_info() {
  echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}!${NC} $1"
}

install_homebrew() {
  if ! command -v brew &> /dev/null; then
    echo -e "\n${GREEN}Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH
    if [[ $(uname -m) == 'arm64' ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi

    print_info "Homebrew installed"
  else
    print_info "Homebrew already installed"
  fi
}

install_essential_packages() {
  echo -e "\n${GREEN}Installing essential packages...${NC}"

  for PACKAGE in "${ESSENTIAL_PACKAGES[@]}"; do
    if brew list "$PACKAGE" >/dev/null 2>&1; then
      print_info "$PACKAGE already installed"
    else
      echo "Installing $PACKAGE..."
      brew install "$PACKAGE"
    fi
  done
}

install_modern_cli_tools() {
  echo -e "\n${GREEN}Modern CLI Tools (Game Changers!)${NC}"
  echo "These tools significantly improve your terminal experience:"
  echo "  • bat, eza, ripgrep, fd, fzf, zoxide, tldr, httpie, jq, git-delta"
  echo ""

  read -p "Install modern CLI tools? (highly recommended) (y/n) " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    for TOOL in "${MODERN_CLI_TOOLS[@]}"; do
      # Extract just the package name (before any comment)
      PACKAGE=$(echo "$TOOL" | awk '{print $1}')
      if brew list "$PACKAGE" >/dev/null 2>&1; then
        print_info "$PACKAGE already installed"
      else
        echo "Installing $PACKAGE..."
        brew install "$PACKAGE"
      fi
    done
    print_info "Modern CLI tools installed!"
  else
    print_warning "Skipping modern CLI tools"
  fi
}

install_powerlevel10k() {
  echo -e "\n${GREEN}Setting up Powerlevel10k theme...${NC}"

  # Ask user if they want p10k
  read -p "Install Powerlevel10k theme for a better prompt? (y/n) " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    if ! brew list powerlevel10k >/dev/null 2>&1; then
      brew install powerlevel10k
      print_info "Powerlevel10k installed"
    else
      print_info "Powerlevel10k already installed"
    fi
  else
    print_warning "Skipping Powerlevel10k - you'll have a basic prompt"
    # Remove p10k files from symlink list
    FILES=("${FILES[@]/config\/zsh\/.p10k.zsh/}")
  fi
}

setup_symlinks() {
  echo -e "\n${GREEN}Setting up configuration symlinks...${NC}"

  for FILE in "${FILES[@]}"; do
    [[ -z "$FILE" ]] && continue  # Skip empty entries

    local source_file="$DOTFILES_REPO/$FILE"
    local target_file="$HOME/$(basename $FILE)"

    if [ ! -f "$source_file" ]; then
      print_warning "Source $source_file doesn't exist, skipping..."
      continue
    fi

    # Backup existing file
    if [ -f "$target_file" ] && [ ! -L "$target_file" ]; then
      echo "  Backing up existing $(basename $FILE)"
      mv "$target_file" "${target_file}.backup"
    fi

    # Create symlink
    ln -sf "$source_file" "$target_file"
    print_info "Linked $(basename $FILE)"
  done
}

setup_github_cli() {
  echo -e "\n${GREEN}Setting up GitHub CLI...${NC}"

  if ! gh auth status &>/dev/null; then
    read -p "Do you want to authenticate with GitHub now? (y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      gh auth login
    else
      print_warning "Skipped GitHub auth - run 'gh auth login' later"
    fi
  else
    print_info "Already authenticated with GitHub"
  fi
}

setup_ssh() {
  echo -e "\n${GREEN}Setting up SSH key...${NC}"

  if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_rsa" ]; then
    read -p "Generate SSH key? (y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      read -p "Enter your email: " email
      ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""

      # Start ssh-agent and add key
      eval "$(ssh-agent -s)"
      ssh-add "$HOME/.ssh/id_ed25519"

      echo ""
      print_info "SSH key generated!"
      echo -e "\n${GREEN}Your public key:${NC}"
      cat "$HOME/.ssh/id_ed25519.pub"
      echo ""
      print_warning "Add this to GitHub: https://github.com/settings/keys"

      # Copy to clipboard if pbcopy available
      if command -v pbcopy &>/dev/null; then
        cat "$HOME/.ssh/id_ed25519.pub" | pbcopy
        print_info "Key copied to clipboard!"
      fi
    fi
  else
    print_info "SSH key already exists"
  fi
}

show_optional_tools() {
  echo -e "\n${YELLOW}========================================${NC}"
  echo -e "${YELLOW}  Optional Tools${NC}"
  echo -e "${YELLOW}========================================${NC}"
  echo ""
  echo "The following tools were NOT installed:"
  echo ""
  echo "  Development:"
  echo "    • docker      - brew install docker"
  echo "    • node/nvm    - brew install nvm"
  echo "    • pnpm        - brew install pnpm"
  echo ""
  echo "  IDE/Editors:"
  echo "    • visual-studio-code - brew install --cask visual-studio-code"
  echo "    • webstorm (requires JetBrains Toolbox or license)"
  echo ""
  echo "  CLI Tools (install when needed):"
  echo "    • stripe      - brew install stripe/stripe-cli/stripe"
  echo "    • supabase    - brew install supabase/tap/supabase"
  echo "    • angular-cli - npm install -g @angular/cli"
  echo ""
  echo "  See os/mac/install_optional.sh for full installation"
  echo ""
}

main() {
  install_homebrew
  install_essential_packages
  install_modern_cli_tools
  install_powerlevel10k
  setup_symlinks
  setup_github_cli
  setup_ssh
  show_optional_tools

  echo -e "\n${GREEN}========================================${NC}"
  echo -e "${GREEN}  Setup Complete!${NC}"
  echo -e "${GREEN}========================================${NC}\n"

  print_info "Your dotfiles are configured"
  print_info "Restart your terminal or run: source ~/.zshrc"

  if brew list powerlevel10k >/dev/null 2>&1; then
    echo ""
    print_warning "Run 'p10k configure' to customize your prompt"
  fi

  echo ""
}

main
