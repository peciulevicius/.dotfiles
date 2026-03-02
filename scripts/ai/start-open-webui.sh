#!/bin/bash
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="$DOTFILES_DIR/ai/docker-compose.open-webui.yml"

docker compose -f "$COMPOSE_FILE" up -d

echo "Open WebUI started: http://localhost:3000"
