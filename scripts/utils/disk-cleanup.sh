#!/usr/bin/env bash
# Daily disk cleanup for the Mac mini (cron, 04:30). Only removes things that
# rebuild themselves: Docker build cache, untagged ("dangling") image layers,
# Homebrew's download cache, and node_modules / screenshots from Studio agent
# work. Never touches tagged images, volumes, service data, source code or
# backups. The internal SSD is 228 GB; below 15 GB free it pings Discord.
#
# Why daily + agent folders (2026-10-15): the Studio's agents had built 65
# projects with their own node_modules (~22 GB counted) under Paperclip's data;
# the disk hit 97%, macOS couldn't grow swap, and Docker crashed.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

free_gb() { df -g / | awk 'NR==2{print $4}'; }
before=$(free_gb)

docker builder prune -f --filter "until=168h" >/dev/null 2>&1 || true
docker image prune -f >/dev/null 2>&1 || true
brew cleanup --prune=30 >/dev/null 2>&1 || true

# Studio agent work: dependencies come back with `pnpm install`.
for dir in "$HOME"/services/paperclip/data/instances/*/workspaces \
           "$HOME"/services/paperclip/data/instances/*/projects \
           "$HOME"/dev/studio/.worktrees; do
    [ -d "$dir" ] && find "$dir" -type d -name node_modules -prune -mtime +3 -exec rm -rf {} + 2>/dev/null || true
done
# Package caches the agents fill inside Paperclip (pnpm store, npm), ~5 GB by
# 2026-10-15. pnpm only drops packages no project references any more.
docker exec -u node -e HOME=/paperclip paperclip sh -c 'pnpm store prune >/dev/null 2>&1; npm cache clean --force >/dev/null 2>&1' 2>/dev/null || true
# Preview screenshots older than two weeks.
[ -d "$HOME/dev/studio/.previews/artifacts" ] && \
    find "$HOME/dev/studio/.previews/artifacts" -mindepth 2 -maxdepth 2 -type d -mtime +14 -exec rm -rf {} + 2>/dev/null || true

after=$(free_gb)
echo "$(date '+%F %T') disk cleanup: ${before} GB → ${after} GB free"

if [ "$after" -lt 15 ]; then
    # shellcheck source=/dev/null
    source "$HOME/.dotfiles/scripts/lib/notify.sh" 2>/dev/null && \
        notify_discord "💾 Disk low: ${after} GB free" \
            "Cleanup ran but the Mac mini has under 15 GB free. Below ~7 GB macOS can't grow swap and Docker crashes (2026-10-15). Biggest usual suspects: Docker.raw, Steam, ~/dev repos' node_modules." warning || true
fi
