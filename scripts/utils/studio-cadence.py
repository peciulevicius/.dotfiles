#!/usr/bin/env python3
"""Set the Studio "Pipeline cycle" routine's cron (Europe/Vilnius).

    studio-cadence.py "0 */2 * * *"            # set it now
    studio-cadence.py "0 */2 * * *" --once     # cron: set it, then remove this
                                               # line from the live crontab

Used to step the cadence back down after a burst (2026-10-14: hourly until the
weekly Max reset, then every 2 h). Signs in as the board with
~/.config/homelab/paperclip-admin.env.
"""
import http.cookiejar
import json
import re
import subprocess
import sys
import urllib.request
from pathlib import Path

BASE = "http://127.0.0.1:3100"
STUDIO = "2efa3f91-92c9-4199-b1cd-08358fca4864"
ROUTINE = "Pipeline cycle"

cron = sys.argv[1]
admin = (Path.home() / ".config/homelab/paperclip-admin.env").read_text()
password = re.search(r"^PAPERCLIP_ADMIN_PASSWORD=(.*)$", admin, re.M).group(1).strip().strip("'\"")
opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))


def api(method, path, body=None):
    req = urllib.request.Request(BASE + path, method=method, data=json.dumps(body).encode() if body is not None else None,
                                 headers={"Origin": BASE, "Content-Type": "application/json"})
    with opener.open(req, timeout=30) as r:
        return json.load(r)


api("POST", "/api/auth/sign-in/email", {"email": "dziugas@peciulevicius.com", "password": password})
routines = api("GET", f"/api/companies/{STUDIO}/routines")
routines = routines.get("items", routines) if isinstance(routines, dict) else routines
routine = next(r for r in routines if r["title"] == ROUTINE)
for trigger in routine.get("triggers", []):
    if trigger.get("cronExpression"):
        done = api("PATCH", f"/api/routine-triggers/{trigger['id']}", {"cronExpression": cron})
        print(f"{ROUTINE}: {trigger['cronExpression']} -> {done['cronExpression']} (next {done.get('nextRunAt')})")

if "--once" in sys.argv:
    current = subprocess.run(["crontab", "-l"], capture_output=True, text=True).stdout
    kept = "".join(line + "\n" for line in current.splitlines() if "studio-cadence.py" not in line)
    subprocess.run(["crontab", "-"], input=kept, text=True, check=True)
    print("removed the one-shot crontab line")
