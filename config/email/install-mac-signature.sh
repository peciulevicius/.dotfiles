#!/usr/bin/env bash
# Install signature.html into Apple Mail as RAW HTML, so the <style> block
# (light/dark logo swap) survives. Pasting via Safari drops <style>, which
# leaves only the fallback (black logo on a white tile) — fine, but no swap.
#
# Before running:
#   1. Mail → Settings → Signatures → select the dziugas@ account in the LEFT
#      column → + → name it "peciulevicius" → leave the placeholder text.
#   2. Quit Mail (Cmd+Q).
# Then: ~/.dotfiles/config/email/install-mac-signature.sh
#
# It rewrites the newest *.mailsignature file (the one you just created) and
# locks it (chflags uchg) — otherwise Mail rewrites it on next launch. To edit
# or delete the signature later: `chflags nouchg <file>` first (path printed).
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)/signature.html"

if pgrep -xq Mail; then
  echo "Quit Mail first (Cmd+Q), then re-run." >&2
  exit 1
fi

# Local signatures, or iCloud-synced ones if Mail syncs signatures via iCloud.
newest=""
for dir in "$HOME"/Library/Mail/V*/MailData/Signatures \
           "$HOME"/Library/Mobile\ Documents/com~apple~mail/Data/V*/Signatures; do
  [[ -d "$dir" ]] || continue
  for f in "$dir"/*.mailsignature; do
    [[ -f "$f" ]] || continue
    if [[ -z "$newest" || "$f" -nt "$newest" ]]; then newest="$f"; fi
  done
done

if [[ -z "$newest" ]]; then
  echo "No .mailsignature found — create the placeholder signature in Mail first (see header)." >&2
  exit 1
fi

echo "Rewriting: $newest"
chflags nouchg "$newest" 2>/dev/null || true
cp "$newest" "$newest.bak"

# Keep Mail's header block (everything up to the first blank line), replace the body.
tmp="$(mktemp)"
awk 'NF==0 {exit} {print}' "$newest" > "$tmp"
printf '\n' >> "$tmp"
cat "$src" >> "$tmp"
mv "$tmp" "$newest"
chflags uchg "$newest"

echo "Done. Backup of the placeholder: $newest.bak"
echo "Open Mail → Settings → Signatures: pick it in 'Choose Signature' for the account, then send yourself a test in light and dark mode."
