#!/bin/bash

# Dotfiles Backup Script
# Creates timestamped backups of your configuration files
#
# Usage: ./backup.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Create backup directory with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/.dotfiles_backup_$TIMESTAMP"

print_header "Dotfiles Backup Script"

echo "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# ═══════════════════════════════════════════════════════
# Files to Backup
# ═══════════════════════════════════════════════════════

# Config files
FILES=(
    "$HOME/.gitconfig"
    "$HOME/.gitignore_global"
    "$HOME/.zshrc"
    "$HOME/.dotfiles/config/starship/starship.toml"
    "$HOME/.ideavimrc"
    "$HOME/.tmux.conf"
    "$HOME/.curlrc"
    "$HOME/.editorconfig"
    "$HOME/.vimrc"
    "$HOME/.npmrc"
)

# Directories to backup
DIRS=(
    "$HOME/.ssh"
    "$HOME/.config/git"
    "$HOME/.config/zsh"
    "$HOME/.config/nvim"
    "$HOME/.config/Claude"
)

# ═══════════════════════════════════════════════════════
# Backup Files
# ═══════════════════════════════════════════════════════

print_header "Backing Up Configuration Files"

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        cp "$file" "$BACKUP_DIR/$filename"
        print_success "Backed up: $filename"
    fi
done

# ═══════════════════════════════════════════════════════
# Backup Directories
# ═══════════════════════════════════════════════════════

print_header "Backing Up Configuration Directories"

for dir in "${DIRS[@]}"; do
    if [ -d "$dir" ]; then
        dirname=$(basename "$dir")
        cp -r "$dir" "$BACKUP_DIR/$dirname"
        print_success "Backed up: $dirname/"
    fi
done

# ═══════════════════════════════════════════════════════
# Backup Package Lists
# ═══════════════════════════════════════════════════════

print_header "Backing Up Package Lists"

OS="$(uname -s)"

# macOS - Homebrew
if [[ "$OS" == "Darwin" ]] && command -v brew &> /dev/null; then
    echo "Exporting Homebrew packages..."
    brew list --formula > "$BACKUP_DIR/brew_packages.txt"
    brew list --cask > "$BACKUP_DIR/brew_casks.txt"
    print_success "Homebrew packages exported"
fi

# Arch Linux
if command -v pacman &> /dev/null; then
    echo "Exporting pacman packages..."
    pacman -Qqe > "$BACKUP_DIR/pacman_packages.txt"

    if command -v yay &> /dev/null; then
        echo "Exporting AUR packages..."
        yay -Qqe > "$BACKUP_DIR/yay_packages.txt"
    fi
    print_success "Arch packages exported"
fi

# Debian/Ubuntu
if command -v apt &> /dev/null; then
    echo "Exporting apt packages..."
    dpkg --get-selections > "$BACKUP_DIR/apt_packages.txt"
    print_success "Apt packages exported"
fi

# Node.js global packages
if command -v npm &> /dev/null; then
    echo "Exporting npm global packages..."
    npm list -g --depth=0 > "$BACKUP_DIR/npm_global_packages.txt"
    print_success "npm packages exported"
fi

# pnpm global packages
if command -v pnpm &> /dev/null; then
    echo "Exporting pnpm global packages..."
    pnpm list -g --depth=0 > "$BACKUP_DIR/pnpm_global_packages.txt" 2>/dev/null || true
    print_success "pnpm packages exported"
fi

# pip packages
if command -v pip3 &> /dev/null; then
    echo "Exporting pip packages..."
    pip3 list --format=freeze > "$BACKUP_DIR/pip_packages.txt"
    print_success "pip packages exported"
fi

# VS Code extensions
if command -v code &> /dev/null; then
    echo "Exporting VS Code extensions..."
    code --list-extensions > "$BACKUP_DIR/vscode_extensions.txt"
    print_success "VS Code extensions exported"
fi

# ═══════════════════════════════════════════════════════
# Backup Git Repositories List
# ═══════════════════════════════════════════════════════

print_header "Backing Up Git Repositories"

if [ -d "$HOME/projects" ]; then
    echo "Finding git repositories in ~/projects..."
    find "$HOME/projects" -name ".git" -type d | sed 's/\/.git$//' > "$BACKUP_DIR/git_repos.txt"
    print_success "Git repositories list created"
fi

# ═══════════════════════════════════════════════════════
# Create Archive
# ═══════════════════════════════════════════════════════

print_header "Creating Archive"

ARCHIVE_NAME="dotfiles_backup_$TIMESTAMP.tar.gz"
tar -czf "$HOME/$ARCHIVE_NAME" -C "$HOME" "$(basename "$BACKUP_DIR")"

print_success "Archive created: $HOME/$ARCHIVE_NAME"

# Remove temporary backup directory
rm -rf "$BACKUP_DIR"

# ═══════════════════════════════════════════════════════
# Cleanup Old Backups (keep last 5)
# ═══════════════════════════════════════════════════════

print_header "Cleaning Up Old Backups"

cd "$HOME"
BACKUP_COUNT=$(ls -1 dotfiles_backup_*.tar.gz 2>/dev/null | wc -l)

if [ "$BACKUP_COUNT" -gt 5 ]; then
    echo "Found $BACKUP_COUNT backups, keeping most recent 5..."
    ls -1t dotfiles_backup_*.tar.gz | tail -n +6 | xargs rm -f
    print_success "Old backups cleaned up"
else
    print_success "No cleanup needed (found $BACKUP_COUNT backups)"
fi

# ═══════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════

print_header "Backup Complete!"

ARCHIVE_SIZE=$(du -h "$HOME/$ARCHIVE_NAME" | cut -f1)

echo -e "${GREEN}Backup archive created successfully!${NC}"
echo ""
echo "Location: $HOME/$ARCHIVE_NAME"
echo "Size: $ARCHIVE_SIZE"
echo ""
echo "What was backed up:"
echo "  ✓ Configuration files (.gitconfig, .zshrc, etc.)"
echo "  ✓ Configuration directories (.ssh, .config, etc.)"
echo "  ✓ Package manager lists"
echo "  ✓ Git repositories list"
echo ""
echo "To restore:"
echo "  1. Extract: tar -xzf $ARCHIVE_NAME"
echo "  2. Copy files back to their original locations"
echo "  3. Reinstall packages from the exported lists"
echo ""
