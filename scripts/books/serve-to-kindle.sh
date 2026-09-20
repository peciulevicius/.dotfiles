#!/bin/bash
# Serve a directory over plain HTTP on the LAN so a Kindle can wget from it.
#
#   ~/.dotfiles/scripts/books/serve-to-kindle.sh [directory] [port]
#
# Why this exists: getting files onto a modern Kindle is awkward on macOS.
#
#   * USB doesn't work — Kindles from ~2022 (Scribe included) present as MTP,
#     which macOS cannot mount without third-party software.
#   * Downloading on-device doesn't work either — the Kindle's busybox `wget`
#     can't negotiate the TLS that GitHub's CDN requires, so HTTPS downloads
#     die with "Connection reset by peer".
#
# Plain HTTP over the LAN sidesteps both. The server runs only while this script
# is in the foreground, binds to the local network, and serves read-only.

set -uo pipefail

DIR="${1:-$HOME/Downloads/kindle-plugins}"
PORT="${2:-8765}"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

[[ -d "$DIR" ]] || { echo "No such directory: $DIR"; exit 1; }

IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)"
[[ -n "$IP" ]] || { echo "Could not determine a LAN IP — are you on Wi-Fi?"; exit 1; }

echo -e "${CYAN}Serving${NC} $DIR"
echo -e "${CYAN}at${NC}      http://$IP:$PORT"
echo ""
echo -e "${YELLOW}On the Kindle, in kTerm:${NC}"
echo ""
for f in "$DIR"/*.zip; do
  [[ -f "$f" ]] || continue
  echo "  wget -O /mnt/us/$(basename "$f") http://$IP:$PORT/$(basename "$f")"
done
echo ""
echo -e "${GREEN}Ctrl-C to stop the server when you're done.${NC}"
echo ""

cd "$DIR" && exec python3 -m http.server "$PORT" --bind 0.0.0.0
