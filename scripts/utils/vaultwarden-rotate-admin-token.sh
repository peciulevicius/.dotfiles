#!/usr/bin/env bash
# Rotate Vaultwarden's /admin token. You type the new token at vaultwarden's own
# hidden prompt inside the running container (docker exec under a pty), so it
# never appears in a command line, `docker inspect`, a log or this script; only
# the Argon2id hash is written to ~/services/vaultwarden/.env.
set -euo pipefail

SVC="$HOME/services/vaultwarden"
ENV_FILE="$SVC/.env"
[[ -f "$ENV_FILE" ]] || { echo "No $ENV_FILE"; exit 1; }
docker ps --format '{{.Names}}' | grep -qx vaultwarden || { echo "vaultwarden container is not running"; exit 1; }

echo "Save the new admin token in Vaultwarden first (generate a long random one),"
echo "then paste it at both prompts below. Nothing you type is echoed or recorded."
transcript=$(mktemp)
trap 'rm -f "$transcript"' EXIT
script -q "$transcript" docker exec -it vaultwarden /vaultwarden hash
hash=$(tr -d '\r' < "$transcript" | grep -o '\$argon2id\$[^'"'"']*' | tail -1)
[[ -n "$hash" ]] || { echo "No hash produced (did the two entries match?). Nothing changed."; exit 1; }

backup="$ENV_FILE.bak-$(date +%Y%m%d-%H%M%S)"
cp -p "$ENV_FILE" "$backup"
HASH="$hash" python3 - "$ENV_FILE" <<'PY'
import os, re, sys
path = sys.argv[1]
s, n = re.subn(r"^ADMIN_TOKEN=.*$", lambda m: "ADMIN_TOKEN='" + os.environ["HASH"] + "'", open(path).read(), flags=re.M)
if n != 1:
    sys.exit("ADMIN_TOKEN line not found exactly once; nothing changed")
open(path, "w").write(s)
PY
chmod 600 "$ENV_FILE" "$backup"

cd "$SVC" && docker compose up -d
echo "Done. Log in at /admin with the NEW token, then delete the backup: rm '$backup'"
