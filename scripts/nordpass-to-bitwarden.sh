#!/usr/bin/env bash
#
# NordPass CSV → Bitwarden JSON converter
#
# Usage:
#   bash nordpass-to-bitwarden.sh nordpass_export.csv
#   bash nordpass-to-bitwarden.sh nordpass_export.csv output.json
#
# Then import output.json into Vaultwarden:
#   Admin → Import Data → Bitwarden (json)

set -euo pipefail

INPUT="${1:-nordpass_export.csv}"
OUTPUT="${2:-bitwarden_import.json}"

if [[ ! -f "$INPUT" ]]; then
    echo "Error: input file '$INPUT' not found"
    echo "Usage: $0 <nordpass_export.csv> [output.json]"
    exit 1
fi

if ! command -v python3 &>/dev/null; then
    echo "Error: python3 is required"
    exit 1
fi

python3 - "$INPUT" "$OUTPUT" <<'PYTHON'
import csv
import json
import sys
import uuid
from datetime import datetime

input_file = sys.argv[1]
output_file = sys.argv[2]

items = []
skipped = 0

with open(input_file, newline='', encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    for row in reader:
        entry_type = row.get('type', '').strip().lower()
        name = row.get('name', '').strip()

        if not name:
            skipped += 1
            continue

        # Login entry
        if entry_type in ('', 'password', 'login') and (row.get('username') or row.get('password')):
            item = {
                "id": str(uuid.uuid4()),
                "organizationId": None,
                "folderId": None,
                "type": 1,
                "name": name or row.get('url', 'Unnamed'),
                "notes": row.get('note', '') or None,
                "favorite": False,
                "login": {
                    "uris": [{"match": None, "uri": row.get('url', '')}] if row.get('url') else None,
                    "username": row.get('username', '') or None,
                    "password": row.get('password', '') or None,
                    "totp": None
                },
                "collectionIds": None
            }
            items.append(item)

        # Credit card entry
        elif entry_type in ('credit card', 'creditcard', 'card') and row.get('cardnumber'):
            item = {
                "id": str(uuid.uuid4()),
                "organizationId": None,
                "folderId": None,
                "type": 3,
                "name": name,
                "notes": row.get('note', '') or None,
                "favorite": False,
                "card": {
                    "cardholderName": row.get('cardholdername', '') or None,
                    "brand": None,
                    "number": row.get('cardnumber', '') or None,
                    "expMonth": None,
                    "expYear": None,
                    "code": row.get('cvc', '') or None
                },
                "collectionIds": None
            }
            # Parse expiry MM/YYYY or MM/YY
            expiry = row.get('expirydate', '')
            if expiry and '/' in expiry:
                parts = expiry.split('/')
                item['card']['expMonth'] = parts[0].strip() if parts else None
                item['card']['expYear'] = parts[1].strip() if len(parts) > 1 else None
            items.append(item)

        # Secure note
        elif entry_type in ('note', 'secure note') or (not row.get('username') and not row.get('password') and not row.get('cardnumber')):
            if row.get('note') or name:
                note_content = row.get('note', '') or ''
                if row.get('url'):
                    note_content = f"URL: {row['url']}\n\n{note_content}".strip()
                item = {
                    "id": str(uuid.uuid4()),
                    "organizationId": None,
                    "folderId": None,
                    "type": 2,
                    "name": name,
                    "notes": note_content or None,
                    "favorite": False,
                    "secureNote": {"type": 0},
                    "collectionIds": None
                }
                items.append(item)
        else:
            skipped += 1

output = {
    "encrypted": False,
    "folders": [],
    "items": items
}

with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(output, f, indent=2, ensure_ascii=False)

print(f"Converted {len(items)} items ({skipped} skipped)")
print(f"Output: {output_file}")
print()
print("Next steps:")
print("  1. Review the output JSON and remove stale/duplicate entries")
print("  2. In Vaultwarden: Admin → Import Data → Bitwarden (json) → upload the file")
print("  3. Verify logins imported correctly before cancelling NordPass")
PYTHON

echo ""
echo "Done. Review '$OUTPUT' before importing."
