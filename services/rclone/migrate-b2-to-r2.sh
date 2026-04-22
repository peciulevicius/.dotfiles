#!/bin/bash
# Migrate rclone backup from Backblaze B2 to Cloudflare R2
#
# Prerequisites:
#   1. R2 bucket created in Cloudflare dashboard (e.g. peciulevicius-backups)
#   2. R2 API token created (Object Read & Write)
#   3. rclone r2 remote configured: rclone config
#      type: s3, provider: Cloudflare, endpoint: https://<account-id>.r2.cloudflarestorage.com

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_ok()   { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_err()  { echo -e "${RED}✗${NC} $1"; }
log_info() { echo -e "${CYAN}→${NC} $1"; }
log_step() { echo -e "\n${BOLD}$1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# ── Pre-flight checks ────────────────────────────────────────────────────────

log_step "Pre-flight checks"

if ! command -v rclone &>/dev/null; then
  log_err "rclone not installed. Run: brew install rclone"
  exit 1
fi
log_ok "rclone installed ($(rclone version | head -1))"

# Check B2 remote exists
B2_REMOTE=""
for remote in $(rclone listremotes); do
  name="${remote%:}"
  type=$(rclone config show "$name" 2>/dev/null | grep "^type" | awk '{print $3}' || true)
  if [[ "$type" == "b2" ]]; then
    B2_REMOTE="$name"
    break
  fi
done

if [[ -z "$B2_REMOTE" ]]; then
  log_warn "No B2 remote found. If you haven't configured one, nothing to migrate."
  log_info "Skipping data migration — proceeding to env update only."
fi

# Check R2 remote exists
R2_REMOTE=""
for remote in $(rclone listremotes); do
  name="${remote%:}"
  provider=$(rclone config show "$name" 2>/dev/null | grep "^provider" | awk '{print $3}' || true)
  if [[ "$provider" == "Cloudflare" ]]; then
    R2_REMOTE="$name"
    break
  fi
done

if [[ -z "$R2_REMOTE" ]]; then
  log_err "No Cloudflare R2 remote found."
  echo ""
  echo "  Run: rclone config"
  echo "  → n (new remote) → name: r2 → type: s3 → provider: Cloudflare"
  echo "  → access_key_id: <R2 token> → secret_access_key: <R2 secret>"
  echo "  → endpoint: https://<account-id>.r2.cloudflarestorage.com"
  echo ""
  exit 1
fi
log_ok "R2 remote found: $R2_REMOTE"

# ── Detect bucket names from existing env ────────────────────────────────────

log_step "Reading current configuration"

if [[ -f "$ENV_FILE" ]]; then
  source "$ENV_FILE"
  log_ok "Loaded .env"
else
  log_warn ".env not found — using defaults"
fi

OLD_REMOTE="${RCLONE_REMOTE:-b2}"
OLD_BUCKET="${BACKUP_DEST:-${OLD_REMOTE}:peciulevicius-services-backup/services}"
# Extract just "remote:bucket" without subpath
OLD_ROOT="${OLD_BUCKET%%/*}"   # e.g. "b2:peciulevicius-services-backup"

R2_BUCKET="peciulevicius-backups"
NEW_REMOTE="$R2_REMOTE"
NEW_BACKUP_DEST="${NEW_REMOTE}:${R2_BUCKET}/services"
NEW_OBSIDIAN_DEST="${NEW_REMOTE}:${R2_BUCKET}/obsidian-vault"

log_info "B2 source:  $OLD_REMOTE (bucket root: $OLD_ROOT)"
log_info "R2 target:  ${NEW_REMOTE}:${R2_BUCKET}"

# ── Create R2 bucket if needed ───────────────────────────────────────────────

log_step "Checking R2 bucket"

if rclone lsd "${NEW_REMOTE}:${R2_BUCKET}" &>/dev/null; then
  log_ok "Bucket '${R2_BUCKET}' exists"
else
  log_info "Creating bucket '${R2_BUCKET}'"
  rclone mkdir "${NEW_REMOTE}:${R2_BUCKET}"
  log_ok "Bucket created"
fi

# ── Migrate data from B2 to R2 ───────────────────────────────────────────────

if [[ -n "$B2_REMOTE" ]]; then
  log_step "Migrating data: B2 → R2"
  log_warn "This copies all existing backup data. May take a few minutes."
  echo ""

  rclone sync "${OLD_ROOT}" "${NEW_REMOTE}:${R2_BUCKET}" \
    --transfers=8 \
    --checkers=16 \
    --fast-list \
    --progress \
    --stats=10s

  log_ok "Data migration complete"
else
  log_warn "No B2 remote — skipping data migration. R2 bucket is empty; next backup will populate it."
fi

# ── Update .env ───────────────────────────────────────────────────────────────

log_step "Updating .env"

if [[ -f "$ENV_FILE" ]]; then
  cp "$ENV_FILE" "${ENV_FILE}.b2-backup"
  log_ok "Backed up old .env to .env.b2-backup"
fi

cat > "$ENV_FILE" <<EOF
# Rclone Backup Configuration — Cloudflare R2
# Migrated from B2 on $(date +%Y-%m-%d)

RCLONE_REMOTE=${NEW_REMOTE}
DOCKER_DIR=${DOCKER_DIR:-$HOME/services}
BACKUP_DEST=${NEW_BACKUP_DEST}
OBSIDIAN_DEST=${NEW_OBSIDIAN_DEST}
RCLONE_FLAGS="--transfers=4 --checkers=8 --fast-list --stats=60s"
EOF

log_ok ".env updated with R2 config"

# Also update the staged services copy if it exists
SERVICES_ENV="$HOME/services/rclone/.env"
if [[ -f "$SERVICES_ENV" ]]; then
  cp "$SERVICES_ENV" "${SERVICES_ENV}.b2-backup"
  cp "$ENV_FILE" "$SERVICES_ENV"
  log_ok "Also updated $SERVICES_ENV"
fi

# ── Test dry run ─────────────────────────────────────────────────────────────

log_step "Testing backup (dry run)"

bash "$SCRIPT_DIR/rclone-backup.sh" --dry-run
log_ok "Dry run passed — R2 backup is working"

# ── Next steps ───────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}${BOLD}Migration complete.${NC}"
echo ""
echo "Next steps:"
echo "  1. Run a live backup to confirm: bash $SCRIPT_DIR/rclone-backup.sh"
echo "  2. Verify data in Cloudflare dashboard → R2 → peciulevicius-backups"
echo "  3. Once confirmed, delete the B2 bucket to stop incurring charges:"
echo "     rclone purge ${OLD_ROOT}"
echo "     (or delete via Backblaze dashboard)"
echo ""
echo "The old .env is preserved at: ${ENV_FILE}.b2-backup"
