#!/bin/bash

# Dotfiles Sync Script
# Syncs latest dotfiles changes without running full installer
#
# Usage: ./sync.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

print_header "Dotfiles Sync"

echo "Dotfiles directory: $DOTFILES_DIR"
echo ""

# ═══════════════════════════════════════════════════════
# Check for changes
# ═══════════════════════════════════════════════════════

cd "$DOTFILES_DIR"

print_header "Checking for Updates"

# Check if repo is clean
if [[ -n $(git status -s) ]]; then
    print_warning "Dotfiles have uncommitted changes"
    echo ""
    git status -s
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# Fetch latest changes
echo "Fetching latest changes..."
git fetch origin

# Check if behind
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")

if [ -z "$REMOTE" ]; then
    print_warning "No remote tracking branch found"
    echo "Run: git branch --set-upstream-to=origin/main"
    exit 1
fi

if [ "$LOCAL" = "$REMOTE" ]; then
    print_success "Already up to date"
    PULL_NEEDED=false
else
    print_info "Updates available"
    PULL_NEEDED=true

    echo ""
    echo "Recent changes:"
    git log --oneline HEAD..@{u} | head -5
    echo ""

    read -p "Pull these changes? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# ═══════════════════════════════════════════════════════
# Pull changes
# ═══════════════════════════════════════════════════════

if [ "$PULL_NEEDED" = true ]; then
    print_header "Pulling Updates"

    echo "Pulling latest changes..."
    git pull

    print_success "Updates pulled"
fi

# ═══════════════════════════════════════════════════════
# Re-symlink configs
# ═══════════════════════════════════════════════════════

print_header "Updating Configuration Symlinks"

CONFIG_FILES=(
    "config/git/.gitconfig:.gitconfig"
    "config/git/.gitignore_global:.gitignore_global"
    "config/git/.gitmessage:.gitmessage"
    "config/zsh/.zshrc:.zshrc"
    # Starship config accessed via STARSHIP_CONFIG env var, no symlink needed
    "config/idea/.ideavimrc:.ideavimrc"
    "config/tmux/.tmux.conf:.tmux.conf"
    "config/ssh/config:.ssh/config"
    "config/curl/.curlrc:.curlrc"
    "config/.editorconfig:.editorconfig"
)

for file_mapping in "${CONFIG_FILES[@]}"; do
    IFS=':' read -r source target <<< "$file_mapping"
    source_file="$DOTFILES_DIR/$source"
    target_file="$HOME/$target"

    if [ ! -f "$source_file" ]; then
        continue
    fi

    # Create parent directory if needed
    target_dir=$(dirname "$target_file")
    mkdir -p "$target_dir"

    # Backup existing file if it's not a symlink
    if [ -f "$target_file" ] && [ ! -L "$target_file" ]; then
        print_warning "Backing up existing $target"
        mv "$target_file" "${target_file}.backup.$(date +%Y%m%d)"
    fi

    # Create or update symlink
    if [ -L "$target_file" ]; then
        current_target=$(readlink "$target_file")
        if [ "$current_target" = "$source_file" ]; then
            print_success "$target (already linked)"
        else
            ln -sf "$source_file" "$target_file"
            print_success "$target (updated link)"
        fi
    else
        ln -sf "$source_file" "$target_file"
        print_success "$target (linked)"
    fi
done

# Set proper permissions for SSH config
if [ -f "$HOME/.ssh/config" ]; then
    chmod 600 "$HOME/.ssh/config"
fi

# ═══════════════════════════════════════════════════════
# Check for new packages
# ═══════════════════════════════════════════════════════

print_header "Checking for New Tools"

print_info "This script only updates configuration files."
print_info "To install new packages, run the full installer:"
echo ""
echo "  cd ~/.dotfiles && ./install.sh"
echo ""

# ═══════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════

print_header "Sync Complete!"

echo -e "${GREEN}Dotfiles synced successfully!${NC}"
echo ""
echo "What was updated:"
echo "  ✓ Configuration files (symlinks updated)"
echo "  ✓ Latest changes from repository"
echo ""
echo "Next steps:"
echo "  1. Reload your shell: source ~/.zshrc"
echo "  2. Or restart your terminal"
echo ""

if [ "$PULL_NEEDED" = true ]; then
    echo "To install any new packages added to installers:"
    echo "  cd ~/.dotfiles && ./install.sh"
    echo ""
fi

print_info "Use scripts/update.sh to update packages"
