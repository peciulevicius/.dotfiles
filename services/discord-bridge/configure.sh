#!/usr/bin/env bash
# Fill in the Discord side of ~/services/discord-bridge/.env and start the
# bridge. Prompts only for the bot token (hidden); channel IDs are read from
# the agents' webhooks and the owner is the bot application's owner.
set -euo pipefail

ENV_FILE="$HOME/services/discord-bridge/.env"
COACH_ID="12432817-656c-4c59-aa19-bdc57e4c6377"
DIETITIAN_ID="895d2ed3-141a-4400-8b3b-0d42aea56b77"

[[ -f "$ENV_FILE" ]] || { echo "Run services/setup-services.sh discord-bridge first."; exit 1; }

read -rsp "Discord bot token (hidden, paste + Enter): " token; echo

# Channel IDs come from the agents' webhooks (a GET on a webhook URL returns
# its channel_id), so nobody has to hunt for them in Discord's UI.
channel_of() { curl -fsS "$(cut -d= -f2- "$HOME/.config/homelab/$1")" | python3 -c 'import json,sys;print(json.load(sys.stdin)["channel_id"])'; }
coach_ch=$(channel_of coach-discord.env)
diet_ch=$(channel_of dietitian-discord.env)
echo "Channels: coach=$coach_ch dietitian=$diet_ch (owner = bot application owner)"

set_var() {  # set_var KEY VALUE — replace the KEY= line in place
  python3 - "$ENV_FILE" "$1" "$2" <<'PY'
import re, sys
path, key, val = sys.argv[1:]
s = open(path).read()
s = re.sub(rf"^{key}=.*$", lambda m: f"{key}={val}", s, flags=re.M)
open(path, "w").write(s)
PY
}

set_var DISCORD_BOT_TOKEN "$token"
set_var CHANNEL_MAP "${coach_ch}:${COACH_ID}:Coach,${diet_ch}:${DIETITIAN_ID}:Dietitian"
unset token
chmod 600 "$ENV_FILE"

cd "$HOME/services/discord-bridge"
docker compose up -d --build
sleep 5
docker logs --tail 5 discord-bridge
