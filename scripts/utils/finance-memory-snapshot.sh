#!/bin/bash
# Append/update today's private finance summary from Glance's generated JSON.
# No credentials are read here; source data lives outside the public repo.
set -uo pipefail

FINANCE_JSON="${FINANCE_JSON:-$HOME/services/glance/assets/finance.json}"
MEMORY_DIR="${AI_MEMORY_DIR:-$HOME/ai-memory/finance}"
TODAY="$(date '+%F')"
SNAPSHOTS="$MEMORY_DIR/snapshots"
DEST="$SNAPSHOTS/$TODAY.md"

if [[ ! -r "$FINANCE_JSON" ]]; then
  echo "finance snapshot source is missing: $FINANCE_JSON" >&2
  exit 1
fi
mkdir -p "$SNAPSHOTS"

python3 - "$FINANCE_JSON" "$DEST" "$SNAPSHOTS" "$TODAY" <<'PY'
import glob
import json
import os
import re
import sys
from datetime import date

source, dest, snapshots, today = sys.argv[1:]
with open(source, encoding="utf-8") as f:
    data = json.load(f)
total = data.get("total", {})
value = total.get("value_numeric")
currency = total.get("currency", "")

previous = None
this_date = date.fromisoformat(today)
for path in sorted(glob.glob(os.path.join(snapshots, "????-??-??.md")), reverse=True):
    stamp = os.path.basename(path)[:10]
    try:
        old_date = date.fromisoformat(stamp)
    except ValueError:
        continue
    if old_date >= this_date or old_date.month == this_date.month and old_date.year == this_date.year:
        continue
    with open(path, encoding="utf-8") as f:
        match = re.search(r"<!-- finance-value:([-+0-9.eE]+); currency:([A-Z]+) -->", f.read())
    if match and match.group(2) == currency:
        previous = float(match.group(1))
        break

if value is None:
    net_worth = "Unavailable — no provider has a current snapshot."
    change = "Unavailable"
else:
    net_worth = f"{currency} {value:,.2f}"
    change = "No comparable prior-month snapshot" if previous is None else f"{currency} {value - previous:+,.2f} ({(value - previous) / previous * 100:+.1f}%)" if previous else f"{currency} {value - previous:+,.2f} (prior value was zero)"

providers = data.get("provider_breakdown", [])
budgets = data.get("budget_categories", [])
lines = [f"# Finance snapshot — {today}", "", f"- Net worth: {net_worth}",
         f"- Month-over-month change: {change}", "", "## Providers"]
lines.extend([f"- {p.get('name', 'Provider')}: {p.get('value', 'unavailable')}" for p in providers] or ["- No connected provider data."])
lines.extend(["", "## Current-month budget vs actual"])
lines.extend([f"- {b.get('name', 'Budget')}: {b.get('spent', '–')} spent / {b.get('limit', '–')} budget" for b in budgets] or ["- No budget data available."])
if value is not None:
    lines.extend(["", f"<!-- finance-value:{value}; currency:{currency} -->"])
with open(dest, "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")
PY
