#!/bin/bash

# Sync local folders to Mac mini
# Syncs BOOKS (Calibre + audiobooks), finances, and millionaire-mindset
#
# Usage: ./sync-to-macmini.sh [--dry-run]

set -euo pipefail

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

REMOTE="macmini"
REMOTE_HOME="/Users/dziugaspeciulevicius"
DRY_RUN=""
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN="--dry-run"
    print_warning "DRY RUN — no files will be transferred"
fi

RSYNC_OPTS="-avh --progress --delete $DRY_RUN"
SUCCESS=0
FAIL=0

sync_folder() {
    local src="$1"
    local dest="$2"
    local label="$3"

    if [[ ! -d "$src" ]]; then
        print_warning "Skipping $label — $src not found"
        return
    fi

    echo "Syncing $label..."
    if rsync $RSYNC_OPTS "$src/" "$REMOTE:$dest/"; then
        print_success "$label synced"
        SUCCESS=$((SUCCESS + 1))
    else
        print_error "$label failed"
        FAIL=$((FAIL + 1))
    fi
}

# ═══════════════════════════════════════════════════════
# Connectivity Check
# ═══════════════════════════════════════════════════════

print_header "Sync to Mac Mini"

if ! ssh -o ConnectTimeout=5 "$REMOTE" "echo ok" &>/dev/null; then
    print_error "Cannot reach $REMOTE — check Tailscale"
    exit 1
fi
print_success "Connected to $REMOTE"

# ═══════════════════════════════════════════════════════
# Sync Folders
# ═══════════════════════════════════════════════════════

# Calibre ebook library → Calibre-Web
sync_folder "$HOME/BOOKS/Calibre" "/Volumes/T7/calibre-books" "Calibre library"

# Audiobooks → Audiobookshelf
sync_folder "$HOME/BOOKS/audiobooks-m4b" "$REMOTE_HOME/services/audiobookshelf/data/audiobooks" "Audiobooks"

# Finances
sync_folder "$HOME/finances" "$REMOTE_HOME/synced/finances" "Finances"

# Millionaire Mindset
sync_folder "$HOME/millionaire-mindset" "$REMOTE_HOME/synced/millionaire-mindset" "Millionaire Mindset"

# ═══════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════

print_header "Done!"

echo "  Synced:  $SUCCESS"
echo "  Failed:  $FAIL"
