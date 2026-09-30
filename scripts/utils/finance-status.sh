#!/usr/bin/env bash
# Read-only IBKR and Trading 212 account snapshots for Glance.
# Setup: services/glance/README.md → Finance.
# --health reads cached booleans; --print includes private balances.
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/finance-data.py" "$@"
