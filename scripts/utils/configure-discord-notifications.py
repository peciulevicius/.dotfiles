#!/usr/bin/env python3
"""Preview, or --apply, separate Discord channels/webhooks for homelab alerts."""
import argparse
import json
import os
from pathlib import Path
import shlex
import shutil
import sys
import urllib.error
import urllib.parse
import urllib.request

API = "https://discord.com/api/v10"
ROUTES = {
    "DISCORD_JOBS_WEBHOOK_URL": ("homelab-jobs", "Homelab Jobs"),
    "DISCORD_AGENTS_WEBHOOK_URL": ("ai-agents", "Paperclip"),
    "DISCORD_REMINDERS_WEBHOOK_URL": ("homelab-reminders", "Homelab Reminders"),
}
CATEGORIES = {"uptime-alerts": "Homelab", "homelab-jobs": "Homelab",
    "homelab-reminders": "Homelab", "ai-agents": "AI"}


def read_env(path):
    values = {}
    for line in path.read_text().splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        key, value = line.split("=", 1)
        parts = shlex.split(value, comments=True)
        values[key.strip()] = parts[0] if parts else ""
    return values


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--notify-env", type=Path, default=Path.home() / ".config/homelab/notify.env")
    parser.add_argument("--bridge-env", type=Path, default=Path.home() / "services/discord-bridge/.env")
    args = parser.parse_args()
    config = read_env(args.notify_env)
    token = read_env(args.bridge_env)["DISCORD_BOT_TOKEN"]

    def request(method, path, body=None, *, webhook=False):
        headers = {"User-Agent": "HomelabNotifications/1.0", "Content-Type": "application/json"}
        if not webhook:
            headers["Authorization"] = "Bot " + token
        req = urllib.request.Request(API + path, method=method, headers=headers,
            data=json.dumps(body).encode() if body is not None else None)
        with urllib.request.urlopen(req, timeout=30) as response:
            return json.load(response)

    # Capture the original shared webhook once; subsequent runs must not move
    # the legacy jobs webhook into the uptime channel.
    kuma_url = config.get("UPTIME_KUMA_DISCORD_WEBHOOK_URL") or config["DISCORD_WEBHOOK_URL"]
    url = urllib.parse.urlparse(kuma_url)
    parts = url.path.rstrip("/").split("/")
    if (url.scheme != "https" or url.hostname not in {"discord.com", "discordapp.com"}
            or len(parts) != 5 or parts[1:3] != ["api", "webhooks"]):
        raise ValueError("Expected a Discord webhook URL in the private notification config")
    kuma = request("GET", "/webhooks/" + "/".join(parts[3:]), webhook=True)
    guild_id = kuma["guild_id"]
    guilds = request("GET", "/users/@me/guilds")
    guild = next(guild for guild in guilds if guild["id"] == guild_id)
    permissions = int(guild["permissions"])
    can_manage = bool(permissions & 8) or bool(permissions & 16 and permissions & (1 << 29))
    channels = request("GET", f"/guilds/{guild_id}/channels")
    current_channel = next(channel for channel in channels if channel["id"] == kuma["channel_id"])
    categories = {}
    for name in dict.fromkeys(CATEGORIES.values()):
        matches = [channel for channel in channels if channel["name"] == name and channel["type"] == 4]
        if len(matches) > 1:
            raise ValueError(f"Ambiguous existing category: {name}")
        if matches:
            categories[name] = matches[0]
        print(f"Category {name}: {'reuse' if matches else 'create'}")
    names = ["uptime-alerts"] + [name for name, _ in ROUTES.values()]
    existing = {}
    for name in names:
        matches = [channel for channel in channels if channel["name"] == name and channel["type"] == 0]
        if len(matches) > 1:
            raise ValueError(f"Ambiguous existing channel: {name}")
        if matches:
            existing[name] = matches[0]
        print(f"#{name}: {'reuse/move' if matches else 'create'} under {CATEGORIES[name]}")
    chats = []
    for canonical, aliases in (("ai-training-coach", {"ai-training-coach"}),
            ("ai-training-dietitian", {"ai-training-dietitian", "ai-training-dietitial"})):
        matches = [channel for channel in channels if channel["type"] == 0 and channel["name"] in aliases]
        if len(matches) > 1:
            raise ValueError(f"Ambiguous existing chat channel: {canonical}")
        if matches:
            chats.append((canonical, matches[0]))
            print(f"#{matches[0]['name']}: move to AI as #{canonical}; retain messages/threads")
    print("Kuma: move its existing webhook to #uptime-alerts; retain its saved URL.")
    print("Jobs/agents/reminders: dedicated webhooks and sender names; updates use jobs.")
    if not can_manage:
        print("Required: grant the bridge bot Manage Channels and Manage Webhooks in this server.", file=sys.stderr)
        return 2
    if not args.apply:
        print("Preview only. Run with --apply to configure channels and save private URLs.")
        return 0

    me = request("GET", "/users/@me")
    for name in dict.fromkeys(CATEGORIES.values()):
        if name not in categories:
            categories[name] = request("POST", f"/guilds/{guild_id}/channels",
                {"name": name, "type": 4,
                 "permission_overwrites": current_channel.get("permission_overwrites", [])})
    for name in names:
        parent_id = categories[CATEGORIES[name]]["id"]
        if name not in existing:
            body = {"name": name, "type": 0, "parent_id": parent_id,
                "permission_overwrites": current_channel.get("permission_overwrites", [])}
            existing[name] = request("POST", f"/guilds/{guild_id}/channels", body)
        elif existing[name].get("parent_id") != parent_id:
            existing[name] = request("PATCH", "/channels/" + existing[name]["id"],
                {"parent_id": parent_id,
                 "permission_overwrites": existing[name].get("permission_overwrites", [])})
    for canonical, channel in chats:
        if channel.get("parent_id") != categories["AI"]["id"] or channel["name"] != canonical:
            request("PATCH", "/channels/" + channel["id"], {"name": canonical,
                "parent_id": categories["AI"]["id"],
                "permission_overwrites": channel.get("permission_overwrites", [])})
    for key, (name, sender) in ROUTES.items():
        channel_id = existing[name]["id"]
        hooks = request("GET", f"/channels/{channel_id}/webhooks")
        matches = [hook for hook in hooks if hook["name"] == sender
            and (hook.get("user") or {}).get("id") == me["id"] and hook.get("token")]
        if len(matches) > 1:
            raise ValueError(f"Ambiguous bot-owned webhook in #{name}")
        hook = matches[0] if matches else request("POST", f"/channels/{channel_id}/webhooks", {"name": sender})
        config[key] = API + f"/webhooks/{hook['id']}/{hook['token']}"

    # Old scripts still using the generic key now land in jobs, never Kuma.
    config["DISCORD_WEBHOOK_URL"] = config["DISCORD_JOBS_WEBHOOK_URL"]
    config["UPTIME_KUMA_DISCORD_WEBHOOK_URL"] = kuma_url
    backup = args.notify_env.with_name(args.notify_env.name + ".pre-routing")
    if not backup.exists():
        shutil.copyfile(args.notify_env, backup)
        os.chmod(backup, 0o600)
    temp = args.notify_env.with_name(args.notify_env.name + ".tmp")
    with open(temp, "w", opener=lambda path, flags: os.open(path, flags, 0o600)) as output:
        os.chmod(temp, 0o600)
        output.write("# Private Discord notification routing; do not commit.\n")
        for key, value in config.items():
            output.write(f"{key}={shlex.quote(value)}\n")
    os.replace(temp, args.notify_env)
    request("PATCH", "/webhooks/" + kuma["id"],
        {"channel_id": existing["uptime-alerts"]["id"], "name": "Uptime Kuma"})
    print("Configured. Private URLs saved; Kuma now posts to #uptime-alerts.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except urllib.error.HTTPError as error:
        # A traceback includes the secret webhook URL; never print it.
        print(f"Discord refused the operation (HTTP {error.code}); check channel permissions and rerun.", file=sys.stderr)
        sys.exit(1)
    except Exception as error:
        print(f"Configuration failed ({type(error).__name__}); inspect private files and rerun.", file=sys.stderr)
        sys.exit(1)
