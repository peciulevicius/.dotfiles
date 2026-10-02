#!/usr/bin/env bash
# Fill in the Discord side of ~/services/discord-bridge/.env and start the
# bridge. Prompts only for the bot token (hidden); channel IDs are read from
# the agents' webhooks and the owner is the bot application's owner.
set -euo pipefail

ENV_FILE="$HOME/services/discord-bridge/.env"

[[ -f "$ENV_FILE" ]] || { echo "Run services/setup-services.sh discord-bridge first."; exit 1; }

# Resolve current hires each time. Rehires get new IDs; never reinstall retired
# IDs from a historical configuration. Fail before writing if ambiguous.
agent_ids=$(python3 - <<'PY'
import http.cookiejar, json, os, pathlib, shlex, urllib.request
base = 'http://127.0.0.1:3100'
values = {}
for line in (pathlib.Path.home() / '.config/homelab/paperclip-admin.env').read_text().splitlines():
    if line.strip() and not line.lstrip().startswith('#') and '=' in line:
        key, value = line.split('=', 1)
        parts = shlex.split(value)
        values[key] = parts[0] if parts else ''
opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
def api(method, path, data=None):
    request = urllib.request.Request(base + path, method=method,
        headers={'Origin': base, 'Content-Type': 'application/json'},
        data=json.dumps(data).encode() if data is not None else None)
    with opener.open(request, timeout=30) as response:
        return json.load(response)
api('POST', '/api/auth/sign-in/email', {
    'email': values.get('PAPERCLIP_ADMIN_EMAIL', 'dziugas@peciulevicius.com'),
    'password': values['PAPERCLIP_ADMIN_PASSWORD']})
try:
    companies = [c for c in api('GET', '/api/companies') if c['name'] == 'Coach']
    if len(companies) != 1:
        raise SystemExit('Expected exactly one Coach company')
    agents = api('GET', '/api/companies/' + companies[0]['id'] + '/agents')
    for name in ('Coach', 'Dietitian'):
        matches = [a for a in agents if a['name'] == name
            and a['status'] not in ('terminated', 'pending_approval')]
        if len(matches) != 1:
            raise SystemExit('Expected exactly one current ' + name + ' agent')
        print(matches[0]['id'])
finally:
    api('POST', '/api/auth/sign-out', {})
PY
)
COACH_ID=$(printf '%s\n' "$agent_ids" | sed -n '1p')
DIETITIAN_ID=$(printf '%s\n' "$agent_ids" | sed -n '2p')

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
# Refresh only the Coach/Dietitian channels (their agent IDs change on a
# rehire) and keep every other channel (Studio, Homelab, Finance, Travel).
current_map=$(grep '^CHANNEL_MAP=' "$ENV_FILE" | cut -d= -f2-)
new_map=$(python3 - "$current_map" "${coach_ch}:${COACH_ID}:Coach" "${diet_ch}:${DIETITIAN_ID}:Dietitian" <<'PY'
import sys
current, *ours = sys.argv[1:]
channels = {entry.split(":", 1)[0] for entry in ours}  # match by channel, not label
kept = [e for e in current.split(",") if e and e.split(":", 1)[0] not in channels]
print(",".join(ours + kept))
PY
)
set_var CHANNEL_MAP "$new_map"
unset token
chmod 600 "$ENV_FILE"

cd "$HOME/services/discord-bridge"
docker compose up -d --build
sleep 5
docker logs --tail 5 discord-bridge
