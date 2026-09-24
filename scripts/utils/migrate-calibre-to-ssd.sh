#!/bin/bash
# Move the Calibre library off the SMB share onto the internal SSD.
#
#   migrate-calibre-to-ssd.sh            # dry run: preflight checks + the plan
#   migrate-calibre-to-ssd.sh --apply    # do it
#
# Why: metadata.db is SQLite, and SQLite's locking is not reliable over SMB.
# Every Calibre-Web failure so far traced back to it — `disk I/O error` opening
# a shelf, `Device or resource busy` renaming a book, `.smbdelete` duplicates,
# `database disk image is malformed` from a stale mount. The setup's own rule
# is "databases on the SSD, media on the NAS"; this library broke it.
#
# The whole library is ~1.1GB, so it fits. What happens:
#   1. preflight — source has metadata.db and passes integrity_check, target
#      is empty, enough free space
#   2. stop calibre, calibre_web, lazylibrarian (they all open the library)
#   3. rsync the library to the SSD, then a checksum pass to prove the copy
#   4. set BOOKS_DIR in all three services' .env (old .env kept alongside)
#   5. recreate the three containers and confirm they mount the new path
#
# The NAS copy is left untouched as the rollback. Backups follow automatically:
# rclone-backup.sh, backup-external.sh and r2-verify.sh read BOOKS_DIR from
# ~/services/calibre/.env.
#
# Rollback (if OPDS or Calibre-Web misbehave afterwards):
#   for s in calibre calibre-web lazylibrarian; do
#     mv ~/services/$s/.env.pre-ssd-migration ~/services/$s/.env
#     docker compose -f ~/services/$s/docker-compose.yml up -d
#   done

set -uo pipefail

SRC="${SRC:-/Volumes/books}"
DST="${DST:-$HOME/services/calibre/library}"
SERVICES_DIR="$HOME/services"
SERVICES=(calibre calibre-web lazylibrarian)
CONTAINERS=(calibre calibre_web lazylibrarian)
HEADROOM_KB=$((2 * 1024 * 1024))   # keep 2GB free after the copy

APPLY=false
[[ "${1:-}" == "--apply" ]] && APPLY=true

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $1"; }
err()  { echo -e "${RED}✗${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
step() { echo -e "\n${CYAN}→${NC} $1"; }
die()  { err "$1"; exit 1; }

RSYNC_EXCLUDES=(--exclude='.smbdelete*' --exclude='.DS_Store' --exclude='._*')

# ── 1. Preflight ─────────────────────────────────────────────────────────────
step "Preflight"

command -v rsync >/dev/null 2>&1 || die "rsync not installed"
command -v docker >/dev/null 2>&1 || die "docker not available"

[[ -f "$SRC/metadata.db" ]] || die "$SRC/metadata.db not found — is the NAS mounted? (scripts/utils/mount-nas.sh)"
ok "source library at $SRC"

current=$(sed -n 's/^BOOKS_DIR=//p' "$SERVICES_DIR/calibre/.env" 2>/dev/null)
if [[ "$current" == "$DST" ]]; then
  ok "already migrated — calibre's BOOKS_DIR is $DST"; exit 0
fi

for s in "${SERVICES[@]}"; do
  [[ -f "$SERVICES_DIR/$s/docker-compose.yml" ]] || die "$SERVICES_DIR/$s/docker-compose.yml missing — stage it first (services/setup-services.sh)"
done
ok "all three services staged in $SERVICES_DIR"

if command -v sqlite3 >/dev/null 2>&1; then
  result=$(sqlite3 -readonly "$SRC/metadata.db" 'PRAGMA integrity_check;' 2>&1)
  [[ "$result" == "ok" ]] || die "source metadata.db fails integrity_check: $result — repair before moving (copy in ~/backups/calibre-repair/)"
  ok "source metadata.db integrity_check: ok"
else
  warn "sqlite3 not found — skipping integrity_check"
fi

if [[ -d "$DST" && -n "$(ls -A "$DST" 2>/dev/null)" ]]; then
  die "$DST already exists and is not empty — refusing to merge into it"
fi

need_kb=$(du -sk "$SRC" | cut -f1)
parent="$(dirname "$DST")"; mkdir -p "$parent"
free_kb=$(df -Pk "$parent" | awk 'NR==2 {print $4}')
(( free_kb > need_kb + HEADROOM_KB )) \
  || die "not enough space: library is $((need_kb / 1024))MB, $((free_kb / 1024))MB free on the SSD (want 2GB headroom)"
ok "space: library $((need_kb / 1024))MB, $((free_kb / 1024))MB free"

smbdelete=$(find "$SRC" -name '.smbdelete*' 2>/dev/null | wc -l | tr -d ' ')
(( smbdelete > 0 )) && warn "$smbdelete .smbdelete file(s) on the share — excluded from the copy (they are SMB lock orphans)"

if [[ "$APPLY" != true ]]; then
  echo ""
  echo "Dry run. With --apply this will:"
  echo "  1. docker stop ${CONTAINERS[*]}"
  echo "  2. rsync $SRC/ → $DST/ (then a checksum verification pass)"
  echo "  3. set BOOKS_DIR=$DST in ~/services/{$(IFS=,; echo "${SERVICES[*]}")}/.env"
  echo "  4. docker compose up -d for each, and check the mounts"
  echo "The NAS copy is not touched."
  exit 0
fi

# ── 2. Stop everything that opens the library ────────────────────────────────
restart_old() {
  err "$1"
  warn "restarting the containers on the OLD path — nothing was switched"
  docker start "${CONTAINERS[@]}" >/dev/null 2>&1
  exit 1
}

step "Stopping ${CONTAINERS[*]}"
docker stop "${CONTAINERS[@]}" >/dev/null || die "docker stop failed"
ok "stopped"

# ── 3. Copy + verify ─────────────────────────────────────────────────────────
step "Copying $SRC → $DST"
mkdir -p "$DST"
rsync -a "${RSYNC_EXCLUDES[@]}" "$SRC/" "$DST/" || restart_old "rsync failed"
ok "copied"

step "Verifying by checksum"
diffs=$(rsync -a -n -c --itemize-changes "${RSYNC_EXCLUDES[@]}" "$SRC/" "$DST/")
[[ -z "$diffs" ]] || restart_old "copy differs from source:\n$diffs"
ok "every file matches by checksum"

if command -v sqlite3 >/dev/null 2>&1; then
  result=$(sqlite3 -readonly "$DST/metadata.db" 'PRAGMA integrity_check;' 2>&1)
  [[ "$result" == "ok" ]] || restart_old "copied metadata.db fails integrity_check: $result"
  ok "copied metadata.db integrity_check: ok"
fi

# ── 4. Repoint BOOKS_DIR ─────────────────────────────────────────────────────
step "Setting BOOKS_DIR=$DST"
for s in "${SERVICES[@]}"; do
  env="$SERVICES_DIR/$s/.env"
  touch "$env"
  cp "$env" "$env.pre-ssd-migration"
  # awk + mv rather than sed -i: BSD and GNU sed disagree on -i
  awk -v v="$DST" 'BEGIN { done = 0 }
       /^BOOKS_DIR=/ { print "BOOKS_DIR=" v; done = 1; next }
       { print }
       END { if (!done) print "BOOKS_DIR=" v }' "$env" > "$env.tmp" && mv "$env.tmp" "$env"
  ok "$s/.env (previous kept as .env.pre-ssd-migration)"
done

# ── 5. Recreate and confirm ──────────────────────────────────────────────────
step "Recreating containers"
for s in "${SERVICES[@]}"; do
  docker compose -f "$SERVICES_DIR/$s/docker-compose.yml" --project-directory "$SERVICES_DIR/$s" up -d \
    || err "$s failed to start — see the rollback at the top of this script"
done

sleep 5
failed=0
for c in "${CONTAINERS[@]}"; do
  src_mount=$(docker inspect "$c" --format '{{range .Mounts}}{{if eq .Destination "/books"}}{{.Source}}{{end}}{{end}}' 2>/dev/null)
  if [[ "$src_mount" == "$DST" ]]; then
    ok "$c mounts /books from $DST"
  else
    err "$c mounts /books from '${src_mount:-nothing}', expected $DST"; failed=1
  fi
done

echo ""
if (( failed )); then
  err "Migration incomplete — see above. Rollback is at the top of this script."
  exit 1
fi
ok "Calibre library now lives on the SSD"
echo ""
echo "Verify by hand, then tick off HOME_SERVER_TODO.md 'Move the Calibre library off SMB':"
echo "  - Calibre-Web opens a book and a shelf (the old 'disk I/O error' path)"
echo "  - KOReader: OPDS catalog loads and a book downloads"
echo "  - LazyLibrarian: Config → Processing still shows /books"
echo "  - next morning: ~/logs/rclone-*.log shows 'Calibre books backup complete' from $DST"
echo "Keep $SRC for a week as the rollback, then remove it from the NAS (UGOS file manager)."
