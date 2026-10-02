#!/usr/bin/env python3
# Change the Paperclip admin password (the UI has no field for it) via Better
# Auth, then update paperclip-admin.env and the Discord bridge .env. Hidden
# prompts; files are only touched after the server accepts the change.

import json, os, re, sys, pathlib, urllib.request, urllib.error, http.cookiejar, getpass
H = pathlib.Path.home()
ADMIN = H / ".config/homelab/paperclip-admin.env"
BRIDGE = H / "services/discord-bridge/.env"
BASE, ORIGIN = "http://127.0.0.1:3100", "http://100.81.171.49:3100"
def val(p, k): return re.search(rf"^{k}=(.*)$", p.read_text(), re.M).group(1).strip()
email, current = val(BRIDGE, "PAPERCLIP_EMAIL"), val(ADMIN, "PAPERCLIP_ADMIN_PASSWORD")
op = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
def post(path, body):
    r = urllib.request.Request(BASE + path, json.dumps(body).encode(), {"Content-Type": "application/json", "Origin": ORIGIN})
    try:
        with op.open(r, timeout=20) as resp: return resp.status, resp.read()[:200]
    except urllib.error.HTTPError as e: return e.code, e.read()[:200]
code, _ = post("/api/auth/sign-in/email", {"email": email, "password": current})
if code != 200: sys.exit(f"sign-in with the current password failed ({code}); nothing changed")
if "--probe" in sys.argv:
    print("change-password probe:", *post("/api/auth/change-password", {"currentPassword": "wrong-on-purpose", "newPassword": "x" * 20}))
    sys.exit()
new = getpass.getpass("New Paperclip password: ")
if new != new.strip(): sys.exit("leading/trailing whitespace is not allowed (the env readers strip it); nothing changed")
if len(new) < 12 or new != getpass.getpass("Again: "): sys.exit("passwords differ or shorter than 12; nothing changed")
code, body = post("/api/auth/change-password", {"currentPassword": current, "newPassword": new, "revokeOtherSessions": True})
if code != 200: sys.exit(f"change failed ({code}): {body!r}; nothing changed")
for f, k in ((ADMIN, "PAPERCLIP_ADMIN_PASSWORD"), (BRIDGE, "PAPERCLIP_PASSWORD")):
    f.write_text(re.sub(rf"^{k}=.*$", lambda m: f"{k}={new}", f.read_text(), flags=re.M)); print(f.name, "updated")
print("Password changed. Now: cd ~/services/discord-bridge && docker compose up -d --force-recreate")
