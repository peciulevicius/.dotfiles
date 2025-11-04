#!/bin/bash

# Optional Tools for macOS
# Run this when you actually need these tools

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Optional Tools Installer${NC}"
echo -e "${GREEN}========================================${NC}\n"

print_info() {
  echo -e "${GREEN}✓${NC} $1"
}

install_if_confirmed() {
  local name=$1
  local install_cmd=$2
  local check_cmd=$3

  if eval "$check_cmd" &>/dev/null; then
    print_info "$name already installed"
    return
  fi

  read -p "Install $name? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    eval "$install_cmd"
    print_info "$name installed"
  else
    echo "  Skipped $name"
  fi
}

echo -e "${YELLOW}Development Tools${NC}\n"

install_if_confirmed "Docker" \
  "brew install --cask docker" \
  "command -v docker"

install_if_confirmed "Node Version Manager (nvm)" \
  "brew install nvm && mkdir -p ~/.nvm" \
  "command -v nvm"

install_if_confirmed "pnpm (fast npm alternative)" \
  "brew install pnpm" \
  "command -v pnpm"

install_if_confirmed "Yarn" \
  "brew install yarn" \
  "command -v yarn"

echo -e "\n${YELLOW}Cloud & Service CLIs${NC}\n"

install_if_confirmed "Stripe CLI" \
  "brew install stripe/stripe-cli/stripe" \
  "command -v stripe"

install_if_confirmed "Supabase CLI" \
  "brew install supabase/tap/supabase" \
  "command -v supabase"

install_if_confirmed "AWS CLI" \
  "brew install awscli" \
  "command -v aws"

echo -e "\n${YELLOW}Editors & IDEs${NC}\n"

install_if_confirmed "Visual Studio Code" \
  "brew install --cask visual-studio-code" \
  "test -d /Applications/Visual\ Studio\ Code.app"

install_if_confirmed "Neovim" \
  "brew install neovim" \
  "command -v nvim"

echo -e "\n${YELLOW}Productivity Apps${NC}\n"

install_if_confirmed "iTerm2" \
  "brew install --cask iterm2" \
  "test -d /Applications/iTerm.app"

install_if_confirmed "Raycast" \
  "brew install --cask raycast" \
  "test -d /Applications/Raycast.app"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Optional Tools Setup Complete${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo "To install more tools, edit this script or use:"
echo "  brew install <package>      # CLI tools"
echo "  brew install --cask <app>   # GUI apps"
