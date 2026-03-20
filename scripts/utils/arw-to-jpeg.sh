#!/bin/bash
# Convert Sony ARW (RAW) files to JPEG for Immich upload
# Uses macOS built-in sips — no dependencies needed
#
# Usage:
#   ./arw-to-jpeg.sh /path/to/arw/folder
#   ./arw-to-jpeg.sh /path/to/arw/folder --delete-originals
#   ./arw-to-jpeg.sh /path/to/arw/folder --quality 85
#   ./arw-to-jpeg.sh /path/to/arw/folder --out /path/to/output/folder
#
# Output: JPEGs alongside originals (or in --out folder), EXIF preserved

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log_ok()   { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_err()  { echo -e "${RED}✗${NC} $1"; }
log_info() { echo -e "${CYAN}→${NC} $1"; }

# Defaults
INPUT_DIR=""
OUTPUT_DIR=""
QUALITY=90
DELETE_ORIGINALS=false
DRY_RUN=false

usage() {
  cat <<EOF
Usage: $(basename "$0") <input-dir> [options]

Options:
  --out <dir>           Output directory (default: same as input)
  --quality <1-100>     JPEG quality (default: 90)
  --delete-originals    Delete ARW files after successful conversion
  --dry-run             Show what would be converted without doing it
  -h, --help            Show this help

Examples:
  $(basename "$0") ~/Desktop/photos
  $(basename "$0") ~/Desktop/photos --out ~/Desktop/converted --quality 85
  $(basename "$0") ~/Desktop/photos --delete-originals
EOF
}

# Parse args
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --delete-originals) DELETE_ORIGINALS=true ;;
    --dry-run) DRY_RUN=true ;;
  esac
done

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --out) OUTPUT_DIR="$2"; shift 2 ;;
    --quality) QUALITY="$2"; shift 2 ;;
    --delete-originals|--dry-run|-h|--help) shift ;;
    -*) log_err "Unknown option: $1"; usage; exit 1 ;;
    *) POSITIONAL+=("$1"); shift ;;
  esac
done

INPUT_DIR="${POSITIONAL[0]}"

if [[ -z "$INPUT_DIR" ]]; then
  log_err "No input directory specified"
  usage
  exit 1
fi

if [[ ! -d "$INPUT_DIR" ]]; then
  log_err "Directory not found: $INPUT_DIR"
  exit 1
fi

# Find all ARW files (case-insensitive)
ARW_FILES=()
while IFS= read -r -d '' f; do
  ARW_FILES+=("$f")
done < <(find "$INPUT_DIR" -type f \( -iname "*.arw" \) -print0 | sort -z)

if [[ ${#ARW_FILES[@]} -eq 0 ]]; then
  log_warn "No ARW files found in $INPUT_DIR"
  exit 0
fi

echo ""
echo -e "${CYAN}ARW → JPEG Converter${NC}"
echo "  Input:   $INPUT_DIR"
echo "  Output:  ${OUTPUT_DIR:-alongside originals}"
echo "  Quality: ${QUALITY}%"
echo "  Files:   ${#ARW_FILES[@]} ARW files found"
[[ "$DELETE_ORIGINALS" == "true" ]] && echo -e "  ${YELLOW}⚠ Will delete originals after conversion${NC}"
[[ "$DRY_RUN" == "true" ]] && echo -e "  ${YELLOW}⚠ Dry run — no changes will be made${NC}"
echo ""

CONVERTED=0
FAILED=0
SKIPPED=0

for ARW in "${ARW_FILES[@]}"; do
  BASENAME=$(basename "$ARW" .ARW)
  BASENAME=$(basename "$BASENAME" .arw)

  if [[ -n "$OUTPUT_DIR" ]]; then
    mkdir -p "$OUTPUT_DIR"
    JPEG="${OUTPUT_DIR}/${BASENAME}.jpg"
  else
    JPEG="${ARW%.*}.jpg"
  fi

  # Skip if JPEG already exists
  if [[ -f "$JPEG" ]]; then
    log_warn "Skipping (already exists): $(basename "$JPEG")"
    ((SKIPPED++))
    continue
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[dry-run] $(basename "$ARW") → $(basename "$JPEG")"
    ((CONVERTED++))
    continue
  fi

  if sips -s format jpeg -s formatOptions "$QUALITY" "$ARW" --out "$JPEG" > /dev/null 2>&1; then
    SIZE_ARW=$(du -sh "$ARW" 2>/dev/null | cut -f1)
    SIZE_JPEG=$(du -sh "$JPEG" 2>/dev/null | cut -f1)
    log_ok "$(basename "$ARW") → $(basename "$JPEG")  (${SIZE_ARW} → ${SIZE_JPEG})"
    ((CONVERTED++))

    if [[ "$DELETE_ORIGINALS" == "true" ]]; then
      rm "$ARW"
    fi
  else
    log_err "Failed: $(basename "$ARW")"
    ((FAILED++))
  fi
done

echo ""
echo "Done — ${CONVERTED} converted, ${SKIPPED} skipped, ${FAILED} failed"
if [[ "$DELETE_ORIGINALS" == "true" && "$DRY_RUN" == "false" && $CONVERTED -gt 0 ]]; then
  echo "Original ARW files deleted."
fi
echo ""
