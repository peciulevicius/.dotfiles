#!/bin/bash

# Universal System Update Script
# Updates all package managers on your system
#
# Usage: ./update.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Detect OS
OS="$(uname -s)"

print_header "System Update Script"
echo "Detected OS: $OS"
echo ""

# ═══════════════════════════════════════════════════════
# macOS (Homebrew)
# ═══════════════════════════════════════════════════════

if [[ "$OS" == "Darwin" ]]; then
    if command -v brew &> /dev/null; then
        print_header "Updating Homebrew"

        echo "Updating Homebrew itself..."
        brew update

        echo ""
        echo "Upgrading installed packages..."
        brew upgrade

        echo ""
        echo "Upgrading casks..."
        brew upgrade --cask --greedy

        echo ""
        echo "Cleaning up old versions..."
        brew cleanup -s

        echo ""
        echo "Running brew doctor..."
        brew doctor || print_warning "brew doctor found some issues"

        print_success "Homebrew updated"
    else
        print_warning "Homebrew not found"
    fi
fi

# ═══════════════════════════════════════════════════════
# Linux Package Managers
# ═══════════════════════════════════════════════════════

if [[ "$OS" == "Linux" ]]; then
    # Arch Linux (pacman + yay)
    if command -v pacman &> /dev/null; then
        print_header "Updating Arch Linux"

        echo "Updating package database..."
        sudo pacman -Sy

        echo ""
        echo "Upgrading packages..."
        sudo pacman -Su --noconfirm

        if command -v yay &> /dev/null; then
            echo ""
            echo "Updating AUR packages..."
            yay -Syu --noconfirm
        fi

        echo ""
        echo "Cleaning package cache..."
        sudo pacman -Sc --noconfirm

        print_success "Arch Linux updated"

    # Debian/Ubuntu (apt)
    elif command -v apt &> /dev/null; then
        print_header "Updating Debian/Ubuntu"

        echo "Updating package lists..."
        sudo apt update

        echo ""
        echo "Upgrading packages..."
        sudo apt upgrade -y

        echo ""
        echo "Dist upgrade..."
        sudo apt dist-upgrade -y

        echo ""
        echo "Removing unnecessary packages..."
        sudo apt autoremove -y

        echo ""
        echo "Cleaning package cache..."
        sudo apt autoclean

        print_success "Debian/Ubuntu updated"

    # Fedora/RHEL (dnf)
    elif command -v dnf &> /dev/null; then
        print_header "Updating Fedora/RHEL"

        echo "Checking for updates..."
        sudo dnf check-update || true

        echo ""
        echo "Upgrading packages..."
        sudo dnf upgrade -y

        echo ""
        echo "Removing unnecessary packages..."
        sudo dnf autoremove -y

        echo ""
        echo "Cleaning package cache..."
        sudo dnf clean all

        print_success "Fedora/RHEL updated"
    fi

    # Flatpak (if installed)
    if command -v flatpak &> /dev/null; then
        print_header "Updating Flatpak"

        flatpak update -y
        flatpak uninstall --unused -y

        print_success "Flatpak updated"
    fi

    # Snap (if installed)
    if command -v snap &> /dev/null; then
        print_header "Updating Snap"

        sudo snap refresh

        print_success "Snap updated"
    fi
fi

# ═══════════════════════════════════════════════════════
# Language Package Managers (All OS)
# ═══════════════════════════════════════════════════════

# Node.js (npm)
if command -v npm &> /dev/null; then
    print_header "Updating npm"

    echo "Updating npm itself..."
    npm install -g npm@latest

    echo ""
    echo "Updating global packages..."
    npm update -g

    print_success "npm updated"
fi

# pnpm
if command -v pnpm &> /dev/null; then
    print_header "Updating pnpm"

    pnpm add -g pnpm
    pnpm update -g

    print_success "pnpm updated"
fi

# Rust (rustup)
if command -v rustup &> /dev/null; then
    print_header "Updating Rust"

    rustup update

    print_success "Rust updated"
fi

# Python (pip)
if command -v pip3 &> /dev/null; then
    print_header "Updating pip"

    pip3 install --upgrade pip

    # Uncomment to update all global packages (can be risky)
    # pip3 list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip3 install -U

    print_success "pip updated"
fi

# Ruby (gem)
if command -v gem &> /dev/null; then
    print_header "Updating RubyGems"

    gem update --system
    gem update

    print_success "RubyGems updated"
fi

# ═══════════════════════════════════════════════════════
# Dotfiles
# ═══════════════════════════════════════════════════════

if [ -d "$HOME/.dotfiles" ]; then
    print_header "Updating Dotfiles"

    cd "$HOME/.dotfiles"

    # Check if there are uncommitted changes
    if [[ -n $(git status -s) ]]; then
        print_warning "Dotfiles have uncommitted changes - skipping git pull"
    else
        echo "Pulling latest changes..."
        git pull
        print_success "Dotfiles updated"
    fi

    cd - > /dev/null
fi

# ═══════════════════════════════════════════════════════
# Oh My Zsh
# ═══════════════════════════════════════════════════════

if [ -d "$HOME/.oh-my-zsh" ]; then
    print_header "Updating Oh My Zsh"

    # Oh My Zsh has its own update mechanism
    if [ -f "$HOME/.oh-my-zsh/tools/upgrade.sh" ]; then
        env ZSH="$HOME/.oh-my-zsh" sh "$HOME/.oh-my-zsh/tools/upgrade.sh"
        print_success "Oh My Zsh updated"
    fi
fi

# ═══════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════

print_header "Update Complete!"

echo -e "${GREEN}All package managers have been updated!${NC}"
echo ""
echo "What was updated:"

if [[ "$OS" == "Darwin" ]] && command -v brew &> /dev/null; then
    echo "  ✓ Homebrew"
fi

if [[ "$OS" == "Linux" ]]; then
    if command -v pacman &> /dev/null; then
        echo "  ✓ Arch Linux (pacman/yay)"
    elif command -v apt &> /dev/null; then
        echo "  ✓ Debian/Ubuntu (apt)"
    elif command -v dnf &> /dev/null; then
        echo "  ✓ Fedora/RHEL (dnf)"
    fi

    if command -v flatpak &> /dev/null; then
        echo "  ✓ Flatpak"
    fi

    if command -v snap &> /dev/null; then
        echo "  ✓ Snap"
    fi
fi

if command -v npm &> /dev/null; then
    echo "  ✓ npm"
fi

if command -v pnpm &> /dev/null; then
    echo "  ✓ pnpm"
fi

if command -v rustup &> /dev/null; then
    echo "  ✓ Rust"
fi

if command -v pip3 &> /dev/null; then
    echo "  ✓ pip"
fi

if command -v gem &> /dev/null; then
    echo "  ✓ RubyGems"
fi

if [ -d "$HOME/.dotfiles" ]; then
    echo "  ✓ Dotfiles"
fi

if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "  ✓ Oh My Zsh"
fi

echo ""
