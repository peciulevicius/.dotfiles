#!/usr/bin/env python3
# Hand the Studio its own accounts: prompts (hidden for secrets) for each value,
# stores it as an encrypted Paperclip company secret and binds it as an env var
# on the agent that uses it. Blank answer = skip/keep. Values never hit argv,
# output or files. Signs in with ~/.config/homelab/paperclip-admin.env.
import getpass, http.cookiejar, json, re, sys, urllib.error, urllib.request
from pathlib import Path

BASE = "http://127.0.0.1:3100"
STUDIO = "2efa3f91-92c9-4199-b1cd-08358fca4864"
# env var, hidden?, agent that gets it, prompt
VALUES = [
    ("BLUESKY_HANDLE", False, "Community & Launch", "Bluesky handle (e.g. studio.bsky.social)"),
    ("BLUESKY_APP_PASSWORD", True, "Community & Launch", "Bluesky app password (Settings → App passwords)"),
    ("CLOUDFLARE_ACCOUNT_ID", False, "Frontend Developer", "Studio Cloudflare account ID"),
    ("CLOUDFLARE_API_TOKEN", True, "Frontend Developer", "Studio Cloudflare API token (Pages + Workers KV edit)"),
]

admin = Path.home() / ".config/homelab/paperclip-admin.env"
password = re.search(r"^PAPERCLIP_ADMIN_PASSWORD=(.*)$", admin.read_text(), re.M).group(1).strip().strip("'\"")
opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))


def api(method, path, body=None):
    request = urllib.request.Request(BASE + path, method=method, data=json.dumps(body).encode() if body is not None else None,
                                     headers={"Origin": BASE, "Content-Type": "application/json"})
    with opener.open(request, timeout=30) as response:
        return json.load(response)


api("POST", "/api/auth/sign-in/email", {"email": "dziugas@peciulevicius.com", "password": password})
agents = {a["name"]: a for a in api("GET", f"/api/companies/{STUDIO}/agents")}
secrets = {s["name"]: s for s in api("GET", f"/api/companies/{STUDIO}/secrets")}

for key, hidden, agent_name, prompt in VALUES:
    value = (getpass.getpass if hidden else input)(f"{prompt} [blank = skip]: ").strip()
    if not value:
        print(f"  skipped {key}")
        continue
    if key in secrets:
        api("POST", f"/api/secrets/{secrets[key]['id']}/rotate", {"value": value})
        secret_id = secrets[key]["id"]
    else:
        created = api("POST", f"/api/companies/{STUDIO}/secrets", {"name": key, "value": value})
        secret_id = created.get("id") or created["secret"]["id"]
    agent = api("GET", "/api/agents/" + agents[agent_name]["id"])
    config = dict(agent["adapterConfig"])
    config["env"] = {**(config.get("env") or {}), key: {"type": "secret_ref", "secretId": secret_id, "version": "latest"}}
    api("PATCH", "/api/agents/" + agent["id"], {"adapterConfig": config})
    print(f"  {key} stored and bound to {agent_name}")

api("POST", "/api/auth/sign-out", {})
print("Done. Save the same accounts in Vaultwarden if you haven't.")
