#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="$DOTFILES_DIR/ai/docker-compose.open-webui.yml"

docker compose -f "$COMPOSE_FILE" down

echo "Open WebUI stopped"
