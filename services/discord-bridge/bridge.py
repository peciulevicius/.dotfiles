"""Discord <-> Paperclip bridge for the Coach team.

A message from the owner in a mapped channel becomes a Paperclip issue
assigned to that channel's agent, with a Discord thread for the conversation.
Agent comments on tracked issues are relayed into the thread; the owner's
replies in the thread become issue comments that @mention the agent (which
wakes it).
"""

import asyncio
import json
import logging
import os
from pathlib import Path

import discord
import httpx

log = logging.getLogger("bridge")
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

TOKEN = os.environ["DISCORD_BOT_TOKEN"]
OWNER_ID = int(os.environ["DISCORD_OWNER_ID"])
PC_URL = os.environ.get("PAPERCLIP_URL", "http://paperclip:3100").rstrip("/")
PC_EMAIL = os.environ["PAPERCLIP_EMAIL"]
PC_PASSWORD = os.environ["PAPERCLIP_PASSWORD"]
COMPANY_ID = os.environ["PAPERCLIP_COMPANY_ID"]
# "channelId:agentId:AgentName,channelId:agentId:AgentName"
CHANNELS = {
    int(c): {"agent_id": a, "name": n}
    for c, a, n in (item.split(":") for item in os.environ["CHANNEL_MAP"].split(",") if item)
}
POLL_SECONDS = int(os.environ.get("POLL_SECONDS", "30"))
STATE_FILE = Path(os.environ.get("STATE_FILE", "/data/state.json"))
DISCORD_LIMIT = 1900


def load_state() -> dict:
    try:
        return json.loads(STATE_FILE.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return {"threads": {}}  # thread_id -> {issue_id, identifier, agent_name, seen: [comment ids]}


def save_state(state: dict) -> None:
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    tmp = STATE_FILE.with_suffix(".tmp")
    tmp.write_text(json.dumps(state))
    tmp.replace(STATE_FILE)


def chunks(text: str) -> list[str]:
    out = []
    while text:
        if len(text) <= DISCORD_LIMIT:
            out.append(text)
            break
        cut = text.rfind("\n", 0, DISCORD_LIMIT)
        cut = cut if cut > DISCORD_LIMIT // 2 else DISCORD_LIMIT
        out.append(text[:cut])
        text = text[cut:].lstrip("\n")
    return out


class Paperclip:
    def __init__(self) -> None:
        self.http = httpx.AsyncClient(base_url=PC_URL, headers={"Origin": PC_URL}, timeout=30)

    async def login(self) -> None:
        r = await self.http.post("/api/auth/sign-in/email", json={"email": PC_EMAIL, "password": PC_PASSWORD})
        r.raise_for_status()
        log.info("signed in to Paperclip")

    async def request(self, method: str, path: str, **kw) -> httpx.Response:
        r = await self.http.request(method, path, **kw)
        if r.status_code == 401:
            await self.login()
            r = await self.http.request(method, path, **kw)
        r.raise_for_status()
        return r

    async def create_issue(self, agent_id: str, title: str, body: str) -> dict:
        r = await self.request("POST", f"/api/companies/{COMPANY_ID}/issues",
                               json={"title": title, "description": body,
                                     "assigneeAgentId": agent_id, "status": "todo"})
        return r.json()

    async def comments(self, issue_id: str) -> list[dict]:
        data = (await self.request("GET", f"/api/issues/{issue_id}/comments")).json()
        return data if isinstance(data, list) else data.get("comments", data.get("items", []))

    async def comment(self, issue_id: str, body: str) -> dict:
        return (await self.request("POST", f"/api/issues/{issue_id}/comments", json={"body": body})).json()


intents = discord.Intents.default()
intents.message_content = True
client = discord.Client(intents=intents)
pc = Paperclip()
state = load_state()


@client.event
async def on_ready() -> None:
    await pc.login()
    log.info("logged in to Discord as %s; channels %s", client.user, list(CHANNELS))
    client.loop.create_task(poll_loop())


@client.event
async def on_message(msg: discord.Message) -> None:
    if msg.author.bot or msg.author.id != OWNER_ID:
        return
    text = msg.content.strip()
    if not text:
        return

    # Reply inside a tracked thread -> comment that wakes the agent.
    if isinstance(msg.channel, discord.Thread) and str(msg.channel.id) in state["threads"]:
        t = state["threads"][str(msg.channel.id)]
        c = await pc.comment(t["issue_id"], f"@{t['agent_name']} {text}\n\n_(via Discord)_")
        t["seen"].append(c.get("id"))
        save_state(state)
        await msg.add_reaction("📨")
        return

    # New message in a mapped channel -> new issue + thread.
    target = CHANNELS.get(msg.channel.id)
    if not target:
        return
    title = text.splitlines()[0][:80]
    issue = await pc.create_issue(target["agent_id"], title, f"{text}\n\n_(from Discord, {msg.created_at:%Y-%m-%d %H:%M} UTC)_")
    ident = issue.get("identifier", issue["id"][:8])
    thread = await msg.create_thread(name=f"{ident} · {title}"[:100])
    state["threads"][str(thread.id)] = {"issue_id": issue["id"], "identifier": ident,
                                        "agent_name": target["name"], "seen": []}
    save_state(state)
    await thread.send(f"📋 **{ident}** created for {target['name']}. Replies land here; answer in this thread.")


async def poll_loop() -> None:
    while True:
        for thread_id, t in list(state["threads"].items()):
            try:
                new = [c for c in await pc.comments(t["issue_id"])
                       if c.get("authorType") == "agent" and c["id"] not in t["seen"]]
                if not new:
                    continue
                thread = client.get_channel(int(thread_id)) or await client.fetch_channel(int(thread_id))
                for c in sorted(new, key=lambda c: c["createdAt"]):
                    for part in chunks(c.get("body") or ""):
                        await thread.send(part)
                    t["seen"].append(c["id"])
                save_state(state)
            except discord.NotFound:
                log.info("thread %s gone, untracking", thread_id)
                del state["threads"][thread_id]
                save_state(state)
            except Exception:
                log.exception("poll failed for thread %s", thread_id)
        await asyncio.sleep(POLL_SECONDS)


if __name__ == "__main__":
    client.run(TOKEN, log_handler=None)
