#!/bin/bash

# System Cleanup Script
# Cleans up caches, logs, and temporary files to free up disk space
#
# Usage: ./cleanup.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

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

# Get initial disk usage
get_disk_usage() {
    df -h "$HOME" | awk 'NR==2 {print $3}'
}

print_header "System Cleanup Script"

BEFORE=$(get_disk_usage)
echo "Disk usage before cleanup: $BEFORE"
echo ""

OS="$(uname -s)"

# ═══════════════════════════════════════════════════════
# macOS Cleanup
# ═══════════════════════════════════════════════════════

if [[ "$OS" == "Darwin" ]]; then
    print_header "macOS Cleanup"

    # Homebrew
    if command -v brew &> /dev/null; then
        echo "Cleaning Homebrew cache..."
        brew cleanup -s
        rm -rf "$(brew --cache)"
        print_success "Homebrew cleaned"
    fi

    # Empty Trash
    echo "Emptying Trash..."
    rm -rf ~/.Trash/*
    print_success "Trash emptied"

    # Clear system caches (requires sudo)
    if [ "$EUID" -eq 0 ]; then
        echo "Clearing system caches..."
        rm -rf /Library/Caches/*
        rm -rf /System/Library/Caches/*
        print_success "System caches cleared"
    else
        print_warning "Run with sudo to clear system caches"
    fi

    # User caches
    echo "Clearing user caches..."
    rm -rf ~/Library/Caches/*
    print_success "User caches cleared"

    # Xcode derived data (if you use Xcode)
    if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
        echo "Cleaning Xcode derived data..."
        rm -rf ~/Library/Developer/Xcode/DerivedData/*
        print_success "Xcode cleaned"
    fi

    # iOS Simulators (if you develop for iOS)
    if [ -d ~/Library/Developer/CoreSimulator/Devices ]; then
        if command -v xcrun &> /dev/null; then
            echo "Cleaning iOS Simulators..."
            xcrun simctl delete unavailable
            print_success "iOS Simulators cleaned"
        fi
    fi
fi

# ═══════════════════════════════════════════════════════
# Linux Cleanup
# ═══════════════════════════════════════════════════════

if [[ "$OS" == "Linux" ]]; then
    print_header "Linux Cleanup"

    # Arch Linux
    if command -v pacman &> /dev/null; then
        echo "Cleaning pacman cache..."
        sudo pacman -Sc --noconfirm
        sudo pacman -Scc --noconfirm

        if command -v yay &> /dev/null; then
            echo "Cleaning yay cache..."
            yay -Sc --noconfirm
        fi

        print_success "Pacman cache cleaned"
    fi

    # Debian/Ubuntu
    if command -v apt &> /dev/null; then
        echo "Cleaning apt cache..."
        sudo apt autoremove -y
        sudo apt autoclean -y
        sudo apt clean -y

        echo "Removing old kernels..."
        if command -v dpkg &> /dev/null; then
            OLD_KERNELS=$(dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d')
            if [ -n "$OLD_KERNELS" ]; then
                echo "$OLD_KERNELS" | xargs sudo apt-get -y purge
            fi
        fi

        print_success "Apt cache cleaned"
    fi

    # Fedora/RHEL
    if command -v dnf &> /dev/null; then
        echo "Cleaning dnf cache..."
        sudo dnf autoremove -y
        sudo dnf clean all

        print_success "DNF cache cleaned"
    fi

    # Flatpak
    if command -v flatpak &> /dev/null; then
        echo "Cleaning Flatpak..."
        flatpak uninstall --unused -y
        flatpak repair

        print_success "Flatpak cleaned"
    fi

    # Snap
    if command -v snap &> /dev/null; then
        echo "Cleaning Snap..."
        sudo snap set system refresh.retain=2
        LANG=C snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
            sudo snap remove "$snapname" --revision="$revision"
        done

        print_success "Snap cleaned"
    fi

    # Systemd journal logs
    if command -v journalctl &> /dev/null; then
        echo "Cleaning systemd journals..."
        sudo journalctl --vacuum-time=3d
        sudo journalctl --vacuum-size=100M

        print_success "Journals cleaned"
    fi

    # User cache
    echo "Clearing user cache..."
    rm -rf ~/.cache/*

    print_success "User cache cleared"
fi

# ═══════════════════════════════════════════════════════
# Docker Cleanup (All OS)
# ═══════════════════════════════════════════════════════

if command -v docker &> /dev/null; then
    print_header "Docker Cleanup"

    echo "Removing stopped containers..."
    docker container prune -f

    echo "Removing unused images..."
    docker image prune -a -f

    echo "Removing unused volumes..."
    docker volume prune -f

    echo "Removing unused networks..."
    docker network prune -f

    echo "Removing build cache..."
    docker builder prune -a -f

    print_success "Docker cleaned"
fi

# ═══════════════════════════════════════════════════════
# Node.js Cleanup (All OS)
# ═══════════════════════════════════════════════════════

if command -v npm &> /dev/null; then
    print_header "Node.js Cleanup"

    echo "Cleaning npm cache..."
    npm cache clean --force

    # Clean node_modules in projects (optional - commented out)
    # echo "Finding and removing node_modules directories..."
    # find ~/projects -name "node_modules" -type d -prune -exec rm -rf '{}' +

    print_success "npm cache cleaned"
fi

if command -v pnpm &> /dev/null; then
    echo "Cleaning pnpm cache..."
    pnpm store prune

    print_success "pnpm cache cleaned"
fi

if command -v yarn &> /dev/null; then
    echo "Cleaning yarn cache..."
    yarn cache clean

    print_success "yarn cache cleaned"
fi

# ═══════════════════════════════════════════════════════
# Python Cleanup (All OS)
# ═══════════════════════════════════════════════════════

if command -v pip3 &> /dev/null; then
    print_header "Python Cleanup"

    echo "Cleaning pip cache..."
    pip3 cache purge

    # Clean __pycache__ directories (optional - commented out)
    # echo "Removing __pycache__ directories..."
    # find ~/projects -name "__pycache__" -type d -prune -exec rm -rf '{}' +

    print_success "pip cache cleaned"
fi

# ═══════════════════════════════════════════════════════
# Rust Cleanup (All OS)
# ═══════════════════════════════════════════════════════

if command -v cargo &> /dev/null; then
    print_header "Rust Cleanup"

    echo "Cleaning Cargo cache..."
    cargo clean

    if command -v cargo-cache &> /dev/null; then
        cargo cache --autoclean
    fi

    print_success "Cargo cache cleaned"
fi

# ═══════════════════════════════════════════════════════
# Development Tool Cleanup
# ═══════════════════════════════════════════════════════

print_header "Development Tools Cleanup"

# Remove temporary files
echo "Removing temporary files..."
rm -rf /tmp/*
rm -rf ~/.tmp/*

# Clean VS Code cache
if [ -d ~/.config/Code/Cache ]; then
    echo "Cleaning VS Code cache..."
    rm -rf ~/.config/Code/Cache/*
    rm -rf ~/.config/Code/CachedData/*
fi

# Clean JetBrains caches
if [ -d ~/.cache/JetBrains ]; then
    echo "Cleaning JetBrains cache..."
    rm -rf ~/.cache/JetBrains/*
fi

# Clean Chrome cache
if [ -d ~/Library/Caches/Google/Chrome ]; then
    echo "Cleaning Chrome cache..."
    rm -rf ~/Library/Caches/Google/Chrome/*
elif [ -d ~/.cache/google-chrome ]; then
    echo "Cleaning Chrome cache..."
    rm -rf ~/.cache/google-chrome/*
fi

print_success "Development tools cleaned"

# ═══════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════

print_header "Cleanup Complete!"

AFTER=$(get_disk_usage)

echo -e "${GREEN}System cleanup finished!${NC}"
echo ""
echo "Disk usage:"
echo "  Before: $BEFORE"
echo "  After:  $AFTER"
echo ""
echo "What was cleaned:"

if [[ "$OS" == "Darwin" ]] && command -v brew &> /dev/null; then
    echo "  ✓ Homebrew cache"
    echo "  ✓ macOS caches"
    echo "  ✓ Trash"
fi

if [[ "$OS" == "Linux" ]]; then
    if command -v pacman &> /dev/null; then
        echo "  ✓ Pacman cache"
    elif command -v apt &> /dev/null; then
        echo "  ✓ Apt cache"
    elif command -v dnf &> /dev/null; then
        echo "  ✓ DNF cache"
    fi

    echo "  ✓ User cache"
    echo "  ✓ System logs"
fi

if command -v docker &> /dev/null; then
    echo "  ✓ Docker (containers, images, volumes)"
fi

if command -v npm &> /dev/null; then
    echo "  ✓ npm cache"
fi

if command -v pnpm &> /dev/null; then
    echo "  ✓ pnpm cache"
fi

if command -v pip3 &> /dev/null; then
    echo "  ✓ pip cache"
fi

if command -v cargo &> /dev/null; then
    echo "  ✓ Cargo cache"
fi

echo "  ✓ Temporary files"
echo "  ✓ IDE caches"
echo ""
