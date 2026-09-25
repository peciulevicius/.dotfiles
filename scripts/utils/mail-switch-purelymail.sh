#!/usr/bin/env bash
# Move kindle_sync (IMAP) and Uptime Kuma (SMTP) from Gmail to
# Purelymail. Reads ~/.config/homelab/purelymail.env (PM_USER, PM_PASS).
# Never prints the password. Calibre-Web encrypts its SMTP password, so that
# one is done in its UI.
set -euo pipefail
ENV="$HOME/.config/homelab/purelymail.env"
[ -f "$ENV" ] || { echo "missing $ENV" >&2; exit 1; }
set -a
# shellcheck source=/dev/null
. "$ENV"
set +a
: "${PM_USER:?}" "${PM_PASS:?}"
TS=$(date +%Y%m%d%H%M%S)

echo "== 1. IMAP login test"
python3 - <<'EOF'
import imaplib, os
m = imaplib.IMAP4_SSL("imap.purelymail.com", 993)
m.login(os.environ["PM_USER"], os.environ["PM_PASS"])
print("   ✓ IMAP login ok as", os.environ["PM_USER"]); m.logout()
EOF

echo "== 2. kindle_sync (pkm/config.py)"
CFG="$HOME/.dotfiles/pkm/config.py"
cp "$CFG" "$CFG.bak-$TS"
python3 - "$CFG" <<'EOF'
import os, re, sys
p = sys.argv[1]; s = open(p).read()
repl = {
    "IMAP_SERVER": '"imap.purelymail.com"',
    "IMAP_PORT": "993",
    "EMAIL_ADDRESS": repr(os.environ["PM_USER"]),
    "EMAIL_PASSWORD": repr(os.environ["PM_PASS"]),
}
for k, v in repl.items():
    s, n = re.subn(rf"^{k}\s*=.*$", lambda _m: f"{k} = {v}", s, flags=re.M)
    if n != 1: sys.exit(f"   ✗ {k} not found exactly once")
open(p, "w").write(s); os.chmod(p, 0o600)
print("   ✓ config.py updated (backup kept)")
EOF
(cd "$HOME/.dotfiles/pkm" && ./.venv/bin/python3 kindle_sync.py 2>&1 | grep -iE "connect|login|found|error|✓|✗" | head -5) || true

echo "== 3. Uptime Kuma SMTP notification"
KDIR="$HOME/services/uptime-kuma"; DB="$KDIR/data/kuma.db"
cp "$DB" "$DB.bak-$TS"
(cd "$KDIR" && docker compose stop >/dev/null)
sqlite3 "$DB" "update notification set config = json_set(config,
  '\$.smtpHost','smtp.purelymail.com', '\$.smtpPort',465, '\$.smtpSecure',json('true'),
  '\$.smtpUsername','$PM_USER', '\$.smtpPassword','$(printf %s "$PM_PASS" | sed "s/'/''/g")',
  '\$.smtpFrom','$PM_USER', '\$.smtpTo','$PM_USER')
  where json_extract(config,'\$.type')='smtp';"
(cd "$KDIR" && docker compose start >/dev/null)
echo "   ✓ Kuma SMTP → smtp.purelymail.com:465 (open the notification → Test to confirm)"

echo "== 4. Calibre-Web: do in the UI (password is encrypted in app.db)"
echo "   Admin → Edit E-mail Server Settings → server smtp.purelymail.com,"
echo "   port 465, encryption SSL/TLS, login + from $PM_USER, password → Save → Test"
