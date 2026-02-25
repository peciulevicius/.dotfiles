#!/bin/bash
set -euo pipefail

MKDOCS_BIN="${MKDOCS_BIN:-}"
if [[ -z "$MKDOCS_BIN" ]]; then
  if command -v mkdocs >/dev/null 2>&1; then
    MKDOCS_BIN="$(command -v mkdocs)"
  elif [[ -x "$HOME/.local/bin/mkdocs" ]]; then
    MKDOCS_BIN="$HOME/.local/bin/mkdocs"
  else
    echo "mkdocs not found. Install first: pipx install mkdocs && pipx inject mkdocs mkdocs-material pymdown-extensions"
    exit 1
  fi
fi

cmd="${1:-serve}"

case "$cmd" in
  serve)
    "$MKDOCS_BIN" serve
    ;;
  serve-lan)
    "$MKDOCS_BIN" serve -a 0.0.0.0:8000
    ;;
  build)
    "$MKDOCS_BIN" build --strict
    ;;
  clean)
    rm -rf site
    echo "Removed site/"
    ;;
  help|-h|--help)
    echo "Usage: scripts/docs.sh [serve|serve-lan|build|clean]"
    ;;
  *)
    echo "Unknown command: $cmd"
    echo "Usage: scripts/docs.sh [serve|serve-lan|build|clean]"
    exit 1
    ;;
esac
