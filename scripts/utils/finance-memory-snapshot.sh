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
import tempfile
from datetime import date, timedelta

source, dest, snapshots, today = sys.argv[1:]
with open(source, encoding="utf-8") as f:
    data = json.load(f)
total = data.get("total", {})
value = total.get("value_numeric")
currency = total.get("currency", "")
coverage = ",".join(data.get("coverage", []))
comparable = bool(data.get("ok")) and data.get("schema") == 2 and not total.get("stale") and not total.get("partial")
marker = f"schema:2; providers:{coverage}; currency:{currency}"

previous = None
this_date = date.fromisoformat(today)
prior_month = this_date.replace(day=1) - timedelta(days=1)
for path in sorted(glob.glob(os.path.join(snapshots, "????-??-??.md")), reverse=True):
    stamp = os.path.basename(path)[:10]
    try:
        old_date = date.fromisoformat(stamp)
    except ValueError:
        continue
    if (old_date.year, old_date.month) != (prior_month.year, prior_month.month):
        continue
    with open(path, encoding="utf-8") as f:
        match = re.search(r"<!-- finance-value:([-+0-9.eE]+); (schema:2; providers:[a-z0-9_,]+; currency:[A-Z]+) -->", f.read())
    if comparable and match and match.group(2) == marker:
        previous = float(match.group(1))
        break

if value is None:
    portfolio = "Unavailable — no provider has a current snapshot."
    change = "Unavailable"
else:
    portfolio = f"{currency} {value:,.2f}"
    change = "No comparable prior-month snapshot" if previous is None else f"{currency} {value - previous:+,.2f} ({(value - previous) / previous * 100:+.1f}%)" if previous else f"{currency} {value - previous:+,.2f} (prior value was zero)"

providers = data.get("provider_breakdown", [])
lines = [f"# Finance snapshot — {today}", "", f"- Connected investments: {portfolio}",
         f"- Month-over-month value change (includes deposits/withdrawals): {change}",
         f"- Freshness: {'stale or partial — check each provider' if not comparable else 'fresh fetched data'}",
         "", "## Providers"]
lines.extend([f"- {p.get('name', 'Provider')}: {p.get('value', 'unavailable')} — {p.get('status', 'unknown')}; {p.get('as_of', '')}" for p in providers] or ["- No connected provider data."])
accounts = data.get("accounts") or {}
if accounts.get("any_set"):
    emergency = accounts.get("emergency", {})
    lines.extend(["", "## Accounts (hand-entered)",
                  f"- Emergency fund: {emergency.get('value', 'unavailable')} ({emergency.get('months', '–')} months of spending)",
                  f"- Net cash: {accounts.get('net_cash', 'unavailable')}"])
    lines.extend(f"- {row['name']}: {row['value']}{' (old)' if row.get('stale') else ''}" for row in accounts.get("rows", []))
if value is not None and comparable:
    lines.extend(["", f"<!-- finance-value:{value}; {marker} -->"])
descriptor, temporary = tempfile.mkstemp(dir=snapshots, prefix=".finance-", suffix=".tmp")
try:
    with os.fdopen(descriptor, "w", encoding="utf-8") as output:
        output.write("\n".join(lines) + "\n")
        output.flush()
        os.fsync(output.fileno())
    os.replace(temporary, dest)
finally:
    if os.path.exists(temporary):
        os.unlink(temporary)
PY
