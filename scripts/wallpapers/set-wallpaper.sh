#!/bin/bash

set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WALLPAPER_DIR="$DOTFILES_DIR/wallpapers"

if [[ "${1:-}" == "" ]]; then
  selected="$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.heic' -o -iname '*.webp' \) | head -n 1)"
else
  if [[ -f "$1" ]]; then
    selected="$1"
  else
    selected="$WALLPAPER_DIR/$1"
  fi
fi

if [[ -z "${selected:-}" || ! -f "$selected" ]]; then
  echo "Wallpaper not found."
  echo "Available wallpapers:"
  find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.heic' -o -iname '*.webp' \) -exec basename {} \;
  exit 1
fi

abs_path="$(cd "$(dirname "$selected")" && pwd)/$(basename "$selected")"

osascript <<APPLESCRIPT
 tell application "System Events"
   repeat with d in desktops
     set picture of d to "$abs_path"
   end repeat
 end tell
APPLESCRIPT

echo "Wallpaper set: $abs_path"
