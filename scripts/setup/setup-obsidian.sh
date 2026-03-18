#!/bin/bash
# Set up Obsidian vault with a sensible folder structure
# Usage: ./scripts/setup-obsidian.sh [--vault-path /custom/path]

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

VAULT_PATH="${VAULT_PATH:-$HOME/obsidian-vault}"

log_ok()   { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_info() { echo -e "${CYAN}→${NC} $1"; }

for arg in "$@"; do
  case "$arg" in
    --vault-path) shift; VAULT_PATH="$1" ;;
    *) ;;
  esac
done

echo -e "${CYAN}Obsidian Vault Setup${NC}"
echo "Vault path: $VAULT_PATH"
echo ""

if [[ -d "$VAULT_PATH/.obsidian" ]]; then
  log_warn "Obsidian vault already exists at $VAULT_PATH"
  log_warn "Run 'ls $VAULT_PATH' to inspect it"
  exit 0
fi

mkdir -p "$VAULT_PATH"

# Core folder structure
FOLDERS=(
  "000 Inbox"
  "100 Projects"
  "200 Areas"
  "300 Resources"
  "400 Archive"
  "500 Templates"
  "600 Daily Notes"
  "700 Books"
  "800 Kindle Highlights"
  ".obsidian"
)

for folder in "${FOLDERS[@]}"; do
  mkdir -p "$VAULT_PATH/$folder"
  log_ok "Created $folder/"
done

# Minimal Obsidian config (daily notes plugin enabled)
cat > "$VAULT_PATH/.obsidian/app.json" <<'EOF'
{
  "promptDelete": true,
  "showInlineTitle": true,
  "showRibbonCommands": true,
  "defaultViewMode": "source",
  "legacyEditor": false,
  "strictLineBreaks": false
}
EOF

cat > "$VAULT_PATH/.obsidian/core-plugins.json" <<'EOF'
{
  "file-explorer": true,
  "global-search": true,
  "switcher": true,
  "graph": true,
  "backlink": true,
  "canvas": true,
  "outgoing-link": true,
  "tag-pane": true,
  "page-preview": true,
  "daily-notes": true,
  "templates": true,
  "note-composer": true,
  "command-palette": true,
  "editor-status": true,
  "starred": true,
  "markdown-importer": true,
  "word-count": true,
  "outline": true,
  "audio-recorder": true
}
EOF

# Daily note template
cat > "$VAULT_PATH/500 Templates/Daily Note.md" <<'EOF'
# {{date:YYYY-MM-DD}} {{date:dddd}}

## Focus

-

## Log

-

## Notes

EOF

# Inbox note
cat > "$VAULT_PATH/000 Inbox/README.md" <<'EOF'
# Inbox

Quick-capture landing zone. Process regularly into Projects / Areas / Resources.
EOF

# README at vault root
cat > "$VAULT_PATH/README.md" <<'EOF'
# Obsidian Vault

Personal knowledge base using PARA (Projects, Areas, Resources, Archive).

## Structure

| Folder | Purpose |
|--------|---------|
| `000 Inbox` | Quick captures, process weekly |
| `100 Projects` | Active projects with deadlines |
| `200 Areas` | Ongoing responsibilities |
| `300 Resources` | Reference material by topic |
| `400 Archive` | Completed / inactive items |
| `500 Templates` | Note templates |
| `600 Daily Notes` | Daily notes |
| `700 Books` | Book notes and summaries |
| `800 Kindle Highlights` | Imported Kindle highlights |

## Sync

Sync across devices with Syncthing (see `docs/NOTES.md`).

## Backup

This vault should be a git repo:
```bash
cd ~/obsidian-vault
git init
git remote add origin git@github.com:yourusername/obsidian-vault.git
```
EOF

log_ok "Vault structure created at $VAULT_PATH"
echo ""
echo "Next steps:"
echo "  1) Open Obsidian and 'Open folder as vault' → $VAULT_PATH"
echo "  2) Install plugins: Dataview, Calendar, Templater"
echo "  3) Set up Syncthing for mobile sync (see docs/NOTES.md)"
echo "  4) Initialize as git repo for backup:"
echo "       cd $VAULT_PATH && git init && git remote add origin <your-repo>"
