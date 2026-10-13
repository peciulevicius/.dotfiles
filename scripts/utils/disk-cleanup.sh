#!/usr/bin/env bash
# Weekly disk cleanup for the Mac mini (cron, Sunday 04:30). Only removes things
# that rebuild themselves: Docker build cache, untagged ("dangling") image
# layers, and Homebrew's download cache. Never touches tagged images, volumes,
# service data or backups. The internal SSD is 228 GB; the weekly audit warns at 90%.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

free_gb() { df -g / | awk 'NR==2{print $4}'; }
before=$(free_gb)

docker builder prune -f --filter "until=168h" >/dev/null 2>&1 || true
docker image prune -f >/dev/null 2>&1 || true
brew cleanup --prune=30 >/dev/null 2>&1 || true

after=$(free_gb)
echo "$(date '+%F %T') disk cleanup: ${before} GB → ${after} GB free"
