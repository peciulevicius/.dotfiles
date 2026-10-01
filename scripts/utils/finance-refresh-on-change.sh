#!/usr/bin/env bash
# Rebuild Glance's finance.json when ~/ai-memory/finance/balances.json changes.
# The Finance Manager (Paperclip) edits that file; without this the Accounts
# card only caught up at the 07:00 run. Cron: every 2 minutes, a no-op unless
# the file is newer than finance.json. Provider caches keep API use low.
set -uo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BALANCES="${FINANCE_BALANCES_FILE:-$HOME/ai-memory/finance/balances.json}"
OUTPUT="${OUT_DIR:-$HOME/services/glance/assets}/finance.json"

[[ -r "$BALANCES" ]] || exit 0
if [[ -e "$OUTPUT" && ! "$BALANCES" -nt "$OUTPUT" ]]; then
  exit 0
fi

if "$SCRIPT_DIR/finance-status.sh"; then
  # shellcheck source=../lib/notify.sh
  source "$SCRIPT_DIR/../lib/notify.sh"
  notify_discord "Glance finance refreshed" "balances.json changed; Accounts card is up to date." ok agents
else
  echo "finance refresh failed after balances.json changed" >&2
  exit 1
fi
