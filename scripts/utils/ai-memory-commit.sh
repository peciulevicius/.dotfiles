#!/bin/bash
# Auto-commit ~/ai-memory (shared AI agent memory) so every agent edit is
# versioned and revertable. Local git repo only — never pushed anywhere.
# Runs from cron every 15 min; does nothing when there are no changes.
set -euo pipefail

MEM="${AI_MEMORY_DIR:-$HOME/ai-memory}"
[[ -d "$MEM/.git" ]] || { echo "$(date '+%F %T') $MEM is not a git repo" >&2; exit 1; }
cd "$MEM"

git add -A
if git diff --cached --quiet; then
  exit 0
fi

files=$(git diff --cached --name-only | head -5 | paste -sd ' ' -)
count=$(git diff --cached --name-only | wc -l | tr -d ' ')
[[ "$count" -gt 5 ]] && files="$files (+$((count - 5)) more)"
git commit -qm "auto: $files"
echo "$(date '+%F %T') committed: $files"
