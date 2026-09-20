#!/bin/bash
# Prepare images as Kindle Scribe lockscreens and serve them to the device.
#
#   ~/.dotfiles/scripts/books/kindle-lockscreens.sh [source-dir]
#
# Converts every image it finds to greyscale PNG at the Scribe's native
# 1860x2480, letterboxing rather than cropping so nothing is cut off, then
# starts the LAN server and prints the wget lines to run in kTerm.
#
# Uses `sips`, which ships with macOS — no ImageMagick, no Homebrew. It reads
# AVIF, HEIC, JPEG, PNG and WebP.
#
# Why serve over the LAN at all: the Scribe is MTP, which macOS cannot mount,
# and the Kindle's busybox wget cannot do HTTPS. Plain HTTP on the LAN is the
# one path that works without installing anything on either machine.

set -uo pipefail

SRC="${1:-$HOME/Downloads}"
OUT="$HOME/Pictures/kindle-lockscreens"
W=1860
H=2480
GRAY="/System/Library/ColorSync/Profiles/Generic Gray Gamma 2.2 Profile.icc"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

[[ -d "$SRC" ]] || { echo "No such directory: $SRC"; exit 1; }
[[ -f "$GRAY" ]] || { echo "Grey ColorSync profile missing: $GRAY"; exit 1; }

mkdir -p "$OUT"
rm -f "$OUT"/lockscreen-*.png

echo -e "${CYAN}Converting${NC} images in $SRC → ${W}x${H} greyscale PNG"
echo ""

shopt -s nullglob nocaseglob
i=1
for f in "$SRC"/*.jpg "$SRC"/*.jpeg "$SRC"/*.png "$SRC"/*.avif "$SRC"/*.heic "$SRC"/*.webp; do
  [[ -f "$f" ]] || continue

  sw=$(sips -g pixelWidth  "$f" 2>/dev/null | awk '/pixelWidth/{print $2}')
  sh=$(sips -g pixelHeight "$f" 2>/dev/null | awk '/pixelHeight/{print $2}')
  [[ -n "$sw" && -n "$sh" && "$sw" -gt 0 && "$sh" -gt 0 ]] || {
    echo -e "  ${YELLOW}skip${NC} $(basename "$f") — not a readable image"; continue; }

  dest="$OUT/$(printf 'lockscreen-%02d.png' "$i")"

  # Fit inside the panel without cropping: scale on whichever edge binds first,
  # then pad the other with black. Cropping would silently cut faces off.
  if (( sw * H > sh * W )); then
    resize=(--resampleWidth "$W")     # wide relative to the panel
  else
    resize=(--resampleHeight "$H")    # tall relative to the panel
  fi

  if sips -s format png "${resize[@]}" \
          --padToHeightWidth "$H" "$W" --padColor 000000 \
          --matchTo "$GRAY" "$f" --out "$dest" >/dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} $(basename "$f") → $(basename "$dest")  (${sw}x${sh})"
    i=$((i+1))
  else
    echo -e "  ${YELLOW}skip${NC} $(basename "$f") — sips could not convert it"
  fi
done
shopt -u nullglob nocaseglob

count=$((i-1))
if [[ "$count" -eq 0 ]]; then
  echo "No images converted. Put some in $SRC first."
  exit 1
fi

echo ""
echo -e "${GREEN}$count image(s) ready${NC} in $OUT"
echo -e "${YELLOW}Preview them in Finder before pushing:${NC} open $OUT"
echo ""

exec "$(dirname "${BASH_SOURCE[0]}")/serve-to-kindle.sh" "$OUT"
