#!/bin/bash
# PostToolUse hook — runs TypeScript type check after file edits
# Only runs if a tsconfig.json exists in the current directory or any parent

find_tsconfig() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/tsconfig.json" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

PROJECT_ROOT=$(find_tsconfig) || exit 0  # no tsconfig = not a TS project, skip silently

# Only run if package.json has a typecheck or tsc script
cd "$PROJECT_ROOT" || exit 0

if grep -q '"typecheck"' package.json 2>/dev/null; then
  pnpm typecheck --noEmit 2>&1 | tail -5
elif grep -q '"tsc"' package.json 2>/dev/null; then
  pnpm tsc --noEmit 2>&1 | tail -5
else
  npx tsc --noEmit 2>&1 | tail -5
fi
