#!/bin/bash

# Audible AAX to M4B Converter + Audiobookshelf Sync
# Converts AAX audiobooks to M4B format (preserving chapters) and syncs to Mac mini
#
# Usage: ./convert-audiobooks.sh
#
# Prerequisites:
#   brew install ffmpeg
#   pip install audible-cli
#   audible quickstart  (interactive, one-time Amazon login)

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

# Configuration
AAX_DIR="$HOME/BOOKS/audio"
OUTPUT_DIR="$HOME/BOOKS/audiobooks-m4b"
ACTIVATION_BYTES_CACHE="$HOME/.audible_activation_bytes"
REMOTE_HOST="macmini"
REMOTE_DIR="~/services/audiobookshelf/data/audiobooks/"

# ═══════════════════════════════════════════════════════
# Dependency Checks
# ═══════════════════════════════════════════════════════

print_header "Checking Dependencies"

MISSING=0

check_dependency() {
    if command -v "$1" &>/dev/null; then
        print_success "$1 found"
    else
        print_error "$1 not found — install with: $2"
        MISSING=$((MISSING + 1))
    fi
}

check_dependency ffmpeg "brew install ffmpeg"
check_dependency ffprobe "brew install ffmpeg"
check_dependency jq "brew install jq"
check_dependency audible "pip install audible-cli"

if [[ $MISSING -gt 0 ]]; then
    echo ""
    print_error "Missing $MISSING dependencies. Install them and re-run."
    exit 1
fi

# ═══════════════════════════════════════════════════════
# Activation Bytes
# ═══════════════════════════════════════════════════════

print_header "Activation Bytes"

if [[ -f "$ACTIVATION_BYTES_CACHE" ]]; then
    ACTIVATION_BYTES=$(cat "$ACTIVATION_BYTES_CACHE")
    print_success "Using cached activation bytes from $ACTIVATION_BYTES_CACHE"
else
    echo "Retrieving activation bytes from Audible..."
    if ! raw_output=$(audible activation-bytes 2>&1); then
        print_error "Failed to get activation bytes."
        print_error "Run 'audible quickstart' first to authenticate with Amazon."
        exit 1
    fi
    # Extract just the hex string (last non-empty line matching hex pattern)
    ACTIVATION_BYTES=$(echo "$raw_output" | grep -oE '^[0-9a-f]{8}$' | tail -1)
    if [[ -z "$ACTIVATION_BYTES" ]]; then
        print_error "Could not parse activation bytes from output:"
        echo "$raw_output"
        exit 1
    fi
    echo "$ACTIVATION_BYTES" > "$ACTIVATION_BYTES_CACHE"
    print_success "Activation bytes cached to $ACTIVATION_BYTES_CACHE"
fi

# ═══════════════════════════════════════════════════════
# Convert AAX → M4B
# ═══════════════════════════════════════════════════════

print_header "Converting AAX → M4B"

mkdir -p "$OUTPUT_DIR"

if ! ls "$AAX_DIR"/*.aax &>/dev/null; then
    print_warning "No .aax files found in $AAX_DIR"
    exit 0
fi

SUCCESS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
TOTAL=$(ls -1 "$AAX_DIR"/*.aax | wc -l | tr -d ' ')

echo "Found $TOTAL AAX files in $AAX_DIR"
echo ""

sanitize() {
    echo "$1" | sed 's/[\/:"*?<>|]/-/g' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//'
}

for aax_file in "$AAX_DIR"/*.aax; do
    filename=$(basename "$aax_file" .aax)

    # Extract metadata via ffprobe
    metadata=$(ffprobe -v quiet -print_format json -show_format "$aax_file" 2>/dev/null || echo "{}")
    author=$(echo "$metadata" | jq -r '.format.tags.artist // empty' 2>/dev/null)
    title=$(echo "$metadata" | jq -r '.format.tags.title // empty' 2>/dev/null)

    # Fallback: derive from filename if metadata is missing
    if [[ -z "$author" ]]; then
        author="Unknown Author"
    fi
    if [[ -z "$title" ]]; then
        title=$(echo "$filename" | sed 's/_ep[0-9]*$//' | sed 's/\([a-z]\)\([A-Z]\)/\1 \2/g')
    fi

    author=$(sanitize "$author")
    title=$(sanitize "$title")
    folder_name="$author - $title"
    output_folder="$OUTPUT_DIR/$folder_name"
    output_file="$output_folder/$title.m4b"

    # Skip if already converted
    if [[ -f "$output_file" ]]; then
        print_warning "Skipping (already converted): $folder_name"
        SKIP_COUNT=$((SKIP_COUNT + 1))
        continue
    fi

    mkdir -p "$output_folder"

    echo -e "Converting: ${BLUE}$folder_name${NC}"
    if ffmpeg -activation_bytes "$ACTIVATION_BYTES" -i "$aax_file" -c copy -y "$output_file" </dev/null 2>/dev/null; then
        print_success "Converted: $folder_name"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        print_error "Failed: $folder_name"
        rm -f "$output_file"
        rmdir "$output_folder" 2>/dev/null || true
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

# ═══════════════════════════════════════════════════════
# Sync to Mac Mini
# ═══════════════════════════════════════════════════════

print_header "Syncing to Mac Mini"

if [[ $SUCCESS_COUNT -eq 0 && $SKIP_COUNT -eq 0 ]]; then
    print_warning "Nothing to sync (no successful conversions)"
else
    echo "Syncing to $REMOTE_HOST:$REMOTE_DIR"
    echo ""
    if rsync -avh --progress "$OUTPUT_DIR/" "$REMOTE_HOST:$REMOTE_DIR"; then
        print_success "Sync complete!"
        echo ""
        echo "Open Audiobookshelf and trigger a library scan to see your books."
    else
        print_error "Rsync failed — your converted files are safe in $OUTPUT_DIR"
        print_warning "Check SSH connectivity: ssh $REMOTE_HOST"
    fi
fi

# ═══════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════

print_header "Done!"

echo "  Converted:  $SUCCESS_COUNT"
echo "  Skipped:    $SKIP_COUNT"
echo "  Failed:     $FAIL_COUNT"
echo "  Total:      $TOTAL"
echo ""
echo "  Local:  $OUTPUT_DIR"
echo "  Remote: $REMOTE_HOST:$REMOTE_DIR"
