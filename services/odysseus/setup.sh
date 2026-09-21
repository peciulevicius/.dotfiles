#!/bin/bash
# Clone Odysseus and stage its config.
#
# Odysseus is the one service here that builds from source rather than pulling
# an image, so its upstream repo has to exist on disk. Its source is NOT
# vendored into this (public) dotfiles repo — only the .env template is ours.

set -uo pipefail

TARGET="$HOME/services/odysseus"
REPO="https://github.com/odysseus-dev/odysseus.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

if [[ -d "$TARGET/.git" ]]; then
  echo -e "${CYAN}→${NC} Updating $TARGET"
  git -C "$TARGET" pull --ff-only
else
  echo -e "${CYAN}→${NC} Cloning Odysseus to $TARGET"
  git clone --depth 1 "$REPO" "$TARGET" || exit 1
fi

if [[ ! -f "$TARGET/.env" ]]; then
  cp "$SCRIPT_DIR/.env.example" "$TARGET/.env"
  chmod 600 "$TARGET/.env"
  echo -e "${YELLOW}⚠${NC}  .env created from template — set ODYSSEUS_ADMIN_PASSWORD before starting"
else
  echo -e "${CYAN}→${NC} .env already exists, not overwriting"
fi

echo ""
echo -e "${GREEN}✓${NC} Staged. Next:"
echo "    brew services start ollama    # ⚠️ needs OLLAMA_HOST=0.0.0.0:11434"
echo "    ollama pull qwen2.5:7b        # chat default — see README benchmarks"
echo "    ollama pull llama3.2:3b       # background calls (titles, tagging)"
echo "    cd $TARGET && docker compose up -d --build"
