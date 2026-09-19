#!/bin/bash
# Set the Gmail app password for kindle_sync.py, without the secret ever
# appearing in shell history, process lists, or a terminal transcript.
#
#   ~/.dotfiles/scripts/setup/set-kindle-password.sh
#
# Prompts silently, writes it into pkm/config.py (gitignored), then runs a real
# IMAP login so you find out immediately whether it works.

set -uo pipefail

CONFIG="$HOME/.dotfiles/pkm/config.py"
VENV_PY="$HOME/.dotfiles/pkm/.venv/bin/python3"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

[[ -f "$CONFIG" ]] || { echo -e "${RED}✗${NC} $CONFIG not found"; exit 1; }
[[ -x "$VENV_PY" ]] || { echo -e "${RED}✗${NC} $VENV_PY not found"; exit 1; }

echo -e "${CYAN}Gmail app password → kindle_sync${NC}"
echo "Generate at https://myaccount.google.com/apppasswords (name it e.g. 'Mac mini homelab')."
echo "Paste it below — it will not be echoed. Spaces are fine, they get stripped."
echo ""

read -r -s -p "App password: " APP_PW
echo ""

# Google displays it as 4 groups of 4; the API wants it with or without spaces
APP_PW="${APP_PW// /}"

if [[ ${#APP_PW} -ne 16 ]]; then
  echo -e "${YELLOW}⚠${NC}  That is ${#APP_PW} characters after removing spaces; Gmail app passwords are 16."
  read -r -p "Continue anyway? [y/N] " yn
  [[ "$yn" =~ ^[Yy]$ ]] || { echo "Aborted, nothing changed."; exit 1; }
fi

cp "$CONFIG" "$CONFIG.bak"

APP_PW="$APP_PW" python3 - "$CONFIG" <<'PY'
import os, re, sys
path = sys.argv[1]
pw = os.environ["APP_PW"]
s = open(path).read()
new, n = re.subn(r'^EMAIL_PASSWORD\s*=.*$', 'EMAIL_PASSWORD = %r' % pw, s, flags=re.M)
if n != 1:
    sys.exit("could not find a single EMAIL_PASSWORD line to replace")
open(path, 'w').write(new)
PY

if [[ $? -ne 0 ]]; then
  mv "$CONFIG.bak" "$CONFIG"
  echo -e "${RED}✗${NC} Failed to update config, original restored."
  exit 1
fi

unset APP_PW
chmod 600 "$CONFIG"
echo -e "${GREEN}✓${NC} Written to $CONFIG"
echo ""
echo -e "${CYAN}Testing IMAP login…${NC}"

if "$VENV_PY" "$HOME/.dotfiles/pkm/kindle_sync.py"; then
  rm -f "$CONFIG.bak"
  echo ""
  echo -e "${GREEN}✓ Working.${NC} The hourly cron will pick up from here."
  echo ""
  echo -e "${YELLOW}Two more places use this same password:${NC}"
  echo "  1. Uptime Kuma  → status.peciulevicius.com → Settings → Notifications"
  echo "     → edit 'Uptime Kuma' (SMTP) → paste → Test → Save"
  echo "  2. Calibre-Web  → books.peciulevicius.com → Admin → SMTP settings"
  echo "     → paste → send a test to peciulevicius-scribe@kindle.com"
  echo ""
  echo "Both have been broken for as long as the sync has. Save the password to"
  echo "Bitwarden too, then delete ~/credentials-import.md once the vault is done."
else
  echo ""
  echo -e "${RED}✗ Login failed.${NC} Previous config kept at $CONFIG.bak"
  echo "  Check you pasted the app password, not the account password."
  exit 1
fi
