#!/bin/bash
# Prove the R2 backup can actually be restored — not just that it uploaded.
#
#   r2-verify.sh            # spot-check one random file per backup set + size history
#
# Cron (monthly, via run-with-notify so a failure reaches Discord):
#   0 6 1 * * ~/.dotfiles/scripts/utils/run-with-notify.sh "R2 restore check" \
#             ~/.dotfiles/scripts/backup/r2-verify.sh >> ~/logs/r2-verify.log 2>&1
#
# Why: rclone-backup.sh reporting "All backups complete" says the upload ran.
# It does not say the bytes in the bucket match the originals, and it cannot
# tell you the backup quietly stopped growing. Both have happened in spirit
# already: Calibre went unbacked-up for 7 days with a green heartbeat
# (2026-09-05), and the Immich photo step was silently skipped every night
# until 2026-09-23.
#
# What it does, per backup set:
#   1. pick one random file from the bucket, download it to a temp dir, and
#      byte-compare it with the original on disk
#   2. append `rclone size` to ~/logs/r2-size-history.tsv and fail if the set
#      shrank by more than 5% since last month — rclone sync mirrors deletions,
#      so a shrink means data vanished locally too
#
# R2 has no egress fees, so the download costs nothing.

set -uo pipefail

ENV_FILE="$HOME/services/rclone/.env"
# shellcheck disable=SC1090
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

RCLONE_REMOTE="${RCLONE_REMOTE:-r2}"
# Same lookup as rclone-backup.sh: calibre's .env is the source of truth.
CALIBRE_DIR="${CALIBRE_DIR:-$(sed -n 's/^BOOKS_DIR=//p' "$HOME/services/calibre/.env" 2>/dev/null)}"
HISTORY="$HOME/logs/r2-size-history.tsv"
SHRINK_LIMIT_PCT=5
PROBLEMS=0

ok()  { echo "  ✓ $1"; }
bad() { echo "  ✗ $1"; PROBLEMS=$((PROBLEMS + 1)); }
info(){ echo "  · $1"; }
human() { awk -v b="$1" 'BEGIN { split("B KB MB GB TB", u); i = 1; while (b >= 1024 && i < 5) { b /= 1024; i++ } printf "%.1f%s", b, u[i] }'; }

mkdir -p "$(dirname "$HISTORY")"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if ! command -v rclone >/dev/null 2>&1; then
  echo "✗ rclone not installed"; exit 1
fi
if ! rclone listremotes | grep -q "^${RCLONE_REMOTE}:"; then
  echo "✗ rclone remote '$RCLONE_REMOTE' not configured"; exit 1
fi

# label | local source | remote path — keep in step with rclone-backup.sh
SETS=(
  "obsidian-vault|$HOME/obsidian-vault|${OBSIDIAN_DEST:-${RCLONE_REMOTE}:peciulevicius-backups/obsidian-vault}"
  "db-dumps|$HOME/backups|${RCLONE_REMOTE}:peciulevicius-backups/db-dumps"
  "calibre-books|${CALIBRE_DIR:-/Volumes/books}|${RCLONE_REMOTE}:peciulevicius-backups/calibre-books"
)
if [[ "${BACKUP_IMMICH_PHOTOS:-false}" == "true" ]]; then
  SETS+=("immich-photos|/Volumes/immich/upload/upload|${RCLONE_REMOTE}:peciulevicius-backups/immich-photos")
fi

# Random order without `shuf` (macOS has none): prefix a random key, sort, strip.
shuffle() {
  awk -v seed="$RANDOM$$" 'BEGIN { srand(seed) } { printf "%.9f\t%s\n", rand(), $0 }' | sort | cut -f2-
}

spot_check() {
  local label="$1" src="$2" dest="$3"

  if [[ ! -d "$src" ]]; then
    bad "$label: local source $src missing — cannot compare (NAS unmounted?)"
    return
  fi

  # Skip files that change constantly (the vault's daily note, a dump being
  # written) — a mismatch there means "edited since 5am", not corruption.
  local file=""
  local candidate
  while IFS= read -r candidate; do
    if [[ -f "$src/$candidate" && -z "$(find "$src/$candidate" -mmin -1440 2>/dev/null)" ]]; then
      file="$candidate"; break
    fi
  done < <(rclone lsf -R --files-only "$dest" 2>/dev/null \
           | grep -v -e '\.smbdelete' -e '/\.obsidian/' -e '^\.obsidian/' \
           | shuffle | head -50)

  if [[ -z "$file" ]]; then
    bad "$label: no comparable file found in $dest (empty bucket, or everything changed in the last day)"
    return
  fi

  if ! rclone copyto "$dest/$file" "$TMP/$label.restore" 2>"$TMP/$label.err"; then
    bad "$label: download of '$file' failed — $(tail -1 "$TMP/$label.err")"
    return
  fi

  # A single transient SMB/NAS read or download glitch (seen 2026-10-01) must not
  # raise an alert: re-download and re-compare once before declaring a mismatch.
  if ! cmp -s "$TMP/$label.restore" "$src/$file"; then
    sleep 30
    rclone copyto "$dest/$file" "$TMP/$label.restore" 2>/dev/null || true
  fi

  if cmp -s "$TMP/$label.restore" "$src/$file"; then
    ok "$label: restored '$file' ($(human "$(wc -c < "$TMP/$label.restore")")) — byte-identical"
  else
    bad "$label: restored '$file' DIFFERS from the original"
  fi
  rm -f "$TMP/$label.restore"
}

track_size() {
  local label="$1" dest="$2"
  local json bytes count
  json=$(rclone size --json "$dest" 2>/dev/null) || { bad "$label: rclone size failed"; return; }
  bytes=$(echo "$json" | sed -n 's/.*"bytes":\([0-9]*\).*/\1/p')
  count=$(echo "$json" | sed -n 's/.*"count":\([0-9]*\).*/\1/p')

  local prev
  prev=$(awk -F'\t' -v l="$label" '$2 == l { last = $3 } END { print last }' "$HISTORY" 2>/dev/null)
  printf '%s\t%s\t%s\t%s\n' "$(date +%Y-%m-%d)" "$label" "$bytes" "$count" >> "$HISTORY"

  local size
  size=$(human "$bytes")

  if [[ -z "$prev" || "$prev" -eq 0 ]]; then
    info "$label: $size, $count files (first measurement)"
  elif [[ "$label" != db-dumps ]] && (( bytes * 100 < prev * (100 - SHRINK_LIMIT_PCT) )); then
    # db-dumps is exempt: backup-databases.sh rotates old dumps out by design.
    bad "$label: shrank from $prev to $bytes bytes since the last check — something was deleted locally"
  elif (( bytes == prev )); then
    info "$label: $size, $count files — unchanged since the last check"
  else
    ok "$label: $size, $count files (was $prev bytes)"
  fi
}

for set in "${SETS[@]}"; do
  IFS='|' read -r label src dest <<< "$set"
  echo ""
  echo "== $label"
  spot_check "$label" "$src" "$dest"
  track_size "$label" "$dest"
done

echo ""
if (( PROBLEMS > 0 )); then
  echo "✗ $PROBLEMS problem(s) — the R2 backup is not trustworthy until these are explained"
  exit 1
fi
echo "✓ Every backup set restored a byte-identical file"
