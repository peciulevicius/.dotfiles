"""Discord <-> Paperclip bridge.

Chat: a message from the owner in a mapped channel becomes a Paperclip issue
assigned to that channel's agent, with a Discord thread for the conversation.
Agent comments are relayed into the thread; the owner's replies become issue
comments that @mention the agent (which wakes it). Channels can belong to
different Paperclip companies (Coach, Studio, Homelab, ...).

Decisions: everything in a company's Paperclip "attention" feed that needs the
owner (agent questions, confirmations, approvals, blockers) is posted to
Discord with buttons, and clicking resolves it in Paperclip. Only the owner can
click. Items resolved elsewhere get their buttons removed.
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
# Optional: defaults to the owner of the bot application (resolved on login).
OWNER_ID = int(os.environ.get("DISCORD_OWNER_ID") or 0)
PC_URL = os.environ.get("PAPERCLIP_URL", "http://paperclip:3100").rstrip("/")
# Base for the "Open in Paperclip" link buttons (must be reachable from the phone).
PC_LINK_BASE = os.environ.get("PAPERCLIP_LINK_BASE", "http://100.81.171.49:3100").rstrip("/")
PC_EMAIL = os.environ["PAPERCLIP_EMAIL"]
PC_PASSWORD = os.environ["PAPERCLIP_PASSWORD"]
# "channelId:agentId:AgentName,..." — the agent's company is looked up on start.
CHANNELS = {
    int(c): {"agent_id": a, "name": n}
    for c, a, n in (item.split(":") for item in os.environ["CHANNEL_MAP"].split(",") if item)
}
# Optional "companyId:channelId,..." — where unrouted decisions for a company go.
# Default: the first mapped channel of that company.
NOTIFY_CHANNELS = {
    c: int(ch) for c, ch in (i.split(":") for i in os.environ.get("NOTIFY_CHANNELS", "").split(",") if i)
}
# Optional "channelId,..." — attachments the owner posts there are saved into
# Paperless's consume folder (CONSUME_DIR) instead of going to the agent.
CONSUME_CHANNELS = {int(c) for c in os.environ.get("CONSUME_CHANNELS", "").split(",") if c}
CONSUME_DIR = Path(os.environ.get("CONSUME_DIR", "/consume"))
CONSUME_EXTS = {".pdf", ".png", ".jpg", ".jpeg"}
CONSUME_MAX_BYTES = 20 * 1024 * 1024
POLL_SECONDS = int(os.environ.get("POLL_SECONDS", "30"))
STATE_FILE = Path(os.environ.get("STATE_FILE", "/data/state.json"))
DISCORD_LIMIT = 1900
ATTENTION_KINDS = {"issue_thread_interaction", "approval", "blocker_attention"}
NO_PING = discord.AllowedMentions(everyone=False, roles=False, users=True)


def load_state() -> dict:
    try:
        s = json.loads(STATE_FILE.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        s = {}
    s.setdefault("threads", {})  # thread_id -> {issue_id, identifier, agent_name, seen: [comment ids]}
    s.setdefault("notified", {})  # dedupKey -> {company, channel, message, closed}
    s.setdefault("actions", {})  # interaction/approval id -> context for button clicks
    s.setdefault("chats", {})  # channel_id -> {issue_id, identifier, thread_id}: the standing conversation
    return s


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


def clip(text: str, n: int) -> str:
    return text if len(text) <= n else text[: n - 1] + "…"


class Paperclip:
    def __init__(self) -> None:
        self.http = httpx.AsyncClient(base_url=PC_URL, headers={"Origin": PC_URL}, timeout=30)

    async def login(self) -> None:
        # Paperclip rate-limits sign-ins (429 after a few quick restarts); retry
        # instead of failing on_ready and leaving the bot connected but idle.
        for wait in (15, 30, 60, 120, None):
            r = await self.http.post("/api/auth/sign-in/email", json={"email": PC_EMAIL, "password": PC_PASSWORD})
            if r.status_code != 429 or wait is None:
                break
            log.warning("Paperclip sign-in rate-limited; retrying in %ss", wait)
            await asyncio.sleep(wait)
        r.raise_for_status()
        log.info("signed in to Paperclip")

    async def request(self, method: str, path: str, **kw) -> httpx.Response:
        r = await self.http.request(method, path, **kw)
        if r.status_code == 401:
            await self.login()
            r = await self.http.request(method, path, **kw)
        r.raise_for_status()
        return r

    async def agent(self, agent_id: str) -> dict:
        return (await self.request("GET", f"/api/agents/{agent_id}")).json()

    async def create_issue(self, company_id: str, agent_id: str, title: str, body: str) -> dict:
        r = await self.request("POST", f"/api/companies/{company_id}/issues",
                               json={"title": title, "description": body,
                                     "assigneeAgentId": agent_id, "status": "todo"})
        return r.json()

    async def comments(self, issue_id: str) -> list[dict]:
        data = (await self.request("GET", f"/api/issues/{issue_id}/comments")).json()
        return data if isinstance(data, list) else data.get("comments", data.get("items", []))

    async def issue(self, issue_id: str) -> dict:
        return (await self.request("GET", f"/api/issues/{issue_id}")).json()

    async def set_status(self, issue_id: str, status: str) -> None:
        await self.request("PATCH", f"/api/issues/{issue_id}", json={"status": status})

    async def reopen(self, issue_id: str, status: str) -> None:
        """Make a standing chat wakeable again. A reply run that ends without
        setting a status leaves a 'missing disposition' recovery that holds the
        issue in `blocked`; resolve it (as the board) before reopening."""
        if status == "blocked":
            try:
                await self.request("POST", f"/api/issues/{issue_id}/recovery-actions/resolve",
                                   json={"outcome": "restored", "sourceIssueStatus": "todo",
                                         "resolutionNote": "Standing owner chat: reopened by the Discord bridge."})
                return
            except httpx.HTTPStatusError as e:
                if e.response.status_code not in (404, 409):
                    raise  # unexpected: surface it instead of silently leaving the chat blocked
                # 404/409: no active recovery action, a plain status change is enough
        await self.set_status(issue_id, "todo")

    async def comment(self, issue_id: str, body: str) -> dict:
        return (await self.request("POST", f"/api/issues/{issue_id}/comments", json={"body": body})).json()

    async def attention(self, company_id: str) -> dict:
        return (await self.request("GET", f"/api/companies/{company_id}/attention?limit=100")).json()

    async def interactions(self, issue_id: str) -> list[dict]:
        data = (await self.request("GET", f"/api/issues/{issue_id}/interactions")).json()
        return data if isinstance(data, list) else data.get("interactions", data.get("items", []))


intents = discord.Intents.default()
intents.message_content = True
client = discord.Client(intents=intents)
pc = Paperclip()
state = load_state()
COMPANY_OF_CHANNEL: dict[int, str] = {}
DEFAULT_CHANNEL: dict[str, int] = {}


@client.event
async def on_ready() -> None:
    global OWNER_ID
    if not OWNER_ID:
        OWNER_ID = (await client.application_info()).owner.id
    await pc.login()
    for ch, target in CHANNELS.items():
        company = (await pc.agent(target["agent_id"]))["companyId"]
        target["company_id"] = company
        COMPANY_OF_CHANNEL[ch] = company
        DEFAULT_CHANNEL.setdefault(company, ch)
    for company, ch in NOTIFY_CHANNELS.items():
        DEFAULT_CHANNEL[company] = ch
    log.info("logged in to Discord as %s; owner %s; channels %s; companies %s",
             client.user, OWNER_ID, list(CHANNELS), list(DEFAULT_CHANNEL))
    client.loop.create_task(poll_loop())
    client.loop.create_task(attention_loop())


async def save_attachments(msg: discord.Message) -> list[str]:
    saved = []
    for a in msg.attachments:
        ext = Path(a.filename).suffix.lower()
        if ext not in CONSUME_EXTS or a.size > CONSUME_MAX_BYTES:
            continue
        stem = "".join(ch if ch.isalnum() or ch in "-_" else "_" for ch in Path(a.filename).stem)[:60]
        name = f"discord-{msg.created_at:%Y%m%d-%H%M%S}-{a.id % 10000}-{stem}{ext}"
        tmp = CONSUME_DIR / (name + ".part")  # unsupported extension, so Paperless skips it until renamed
        await a.save(tmp)
        tmp.chmod(0o644)
        tmp.rename(CONSUME_DIR / name)
        saved.append(name)
    return saved


@client.event
async def on_message(msg: discord.Message) -> None:
    if msg.author.bot or msg.author.id != OWNER_ID:
        return
    if msg.attachments and msg.channel.id in CONSUME_CHANNELS:
        try:
            saved = await save_attachments(msg)
        except Exception:
            log.exception("saving attachments failed")
            await msg.add_reaction("⚠️")
        else:
            if saved:
                log.info("saved %d attachment(s) to Paperless consume", len(saved))
                await msg.add_reaction("📄")
            else:
                await msg.reply(f"Not saved: only {', '.join(sorted(CONSUME_EXTS))} up to 20 MB are accepted.",
                                mention_author=False)
    text = msg.content.strip()
    if not text:
        return

    # Reply inside a tracked thread -> comment that wakes the agent.
    if isinstance(msg.channel, discord.Thread) and str(msg.channel.id) in state["threads"]:
        t = state["threads"][str(msg.channel.id)]
        if any(ch["issue_id"] == t["issue_id"] for ch in state["chats"].values()):
            status = (await pc.issue(t["issue_id"]))["status"]
        else:
            status = None
        c = await pc.comment(t["issue_id"], f"@{t['agent_name']} {text}\n\n_(via Discord)_")
        t["seen"].append(c.get("id"))
        save_state(state)
        if status in ("done", "cancelled", "blocked"):
            now = (await pc.issue(t["issue_id"]))["status"]
            if now in ("done", "cancelled", "blocked"):
                await pc.reopen(t["issue_id"], now)
        await msg.add_reaction("📨")
        return

    target = CHANNELS.get(msg.channel.id)
    if not target:
        return
    # "/task ..." keeps the old behaviour: a separate issue + thread.
    if text.lower().startswith("/task "):
        await new_task(msg, target, text[6:].strip())
        return
    # Anything else is conversation: one standing issue + thread per channel.
    await chat(msg, target, text)


CHAT_INTRO = """Standing conversation between the owner and you, relayed from Discord.

- Reply to each owner message with a comment here: answer, or say what you will do.
- This issue is a chat, not a work item: do the real work in separate tasks you create and assign (link them in your reply), then report back here.
- Never mark this issue done or cancelled; leave it in progress between messages.
- Post exactly ONE comment per owner message: your reply. Every comment here is
  relayed to the owner's phone, so never post status notes, "already handled",
  "no action needed" or disposition confirmations. If a wake brings no new owner
  message, set the status to in_progress with no comment and stop.
"""


async def new_task(msg: discord.Message, target: dict, text: str) -> None:
    title = text.splitlines()[0][:80]
    issue = await pc.create_issue(target["company_id"], target["agent_id"], title,
                                  f"{text}\n\n_(from Discord, {msg.created_at:%Y-%m-%d %H:%M} UTC)_")
    ident = issue.get("identifier", issue["id"][:8])
    thread = await msg.create_thread(name=f"{ident} · {title}"[:100])
    state["threads"][str(thread.id)] = {"issue_id": issue["id"], "identifier": ident,
                                        "agent_name": target["name"], "seen": []}
    save_state(state)
    await thread.send(f"📋 **{ident}** created for {target['name']}. Replies land here; answer in this thread.")


CHAT_LOCKS: dict[int, asyncio.Lock] = {}
QUIET = discord.AllowedMentions.none()


async def chat_issue(channel_id: int, target: dict) -> dict | None:
    """The channel's standing chat if it still exists and belongs to the mapped agent."""
    c = state["chats"].get(str(channel_id))
    if not c:
        return None
    try:
        issue = await pc.issue(c["issue_id"])
    except httpx.HTTPStatusError as e:
        if e.response.status_code == 404:
            return None
        raise  # transient: keep the pointer, let the caller fail loudly
    if "agent_id" not in c:  # record from the first chat-mode release: learn its agent from the issue
        c["agent_id"] = issue.get("assigneeAgentId")
        save_state(state)
    if c["agent_id"] != target["agent_id"]:
        return None
    c["_status"] = issue["status"]  # reopened by chat() only after the owner's comment is saved
    return c


async def chat_thread(channel: discord.TextChannel, c: dict, target: dict) -> discord.Thread:
    try:
        thread = client.get_channel(c["thread_id"]) or await client.fetch_channel(c["thread_id"])
        if getattr(thread, "archived", False):
            await thread.edit(archived=False)
        return thread
    except discord.NotFound:
        pass
    # Fetch history first (a failure here must not orphan a new thread). Agent
    # replies the old thread already delivered count as seen; anything newer is
    # still relayed into the replacement.
    old = str(c.get("thread_id"))
    delivered = set(state["threads"].get(old, {}).get("seen", []))
    history = await pc.comments(c["issue_id"])
    seen = [x["id"] for x in history if x["id"] in delivered or x.get("authorType") != "agent"] if delivered \
        else [x["id"] for x in history]
    thread = await channel.create_thread(name=f"💬 Chat with {target['name']} · {c['identifier']}"[:100],
                                         type=discord.ChannelType.public_thread, auto_archive_duration=10080)
    state["threads"].pop(old, None)
    state["threads"][str(thread.id)] = {"issue_id": c["issue_id"], "identifier": c["identifier"],
                                        "agent_name": target["name"], "seen": seen}
    c["thread_id"] = thread.id
    save_state(state)
    await thread.send(f"💬 This is your ongoing chat with **{target['name']}** ({c['identifier']}). "
                      "Write here or in the channel; replies land here. Start a message with `/task ` "
                      "for a separate task instead.")
    return thread


async def chat(msg: discord.Message, target: dict, text: str) -> None:
    async with CHAT_LOCKS.setdefault(msg.channel.id, asyncio.Lock()):
        c = await chat_issue(msg.channel.id, target)
        if c is None:
            issue = await pc.create_issue(target["company_id"], target["agent_id"],
                                          f"💬 Chat with the owner ({target['name']})", CHAT_INTRO)
            c = state["chats"][str(msg.channel.id)] = {
                "issue_id": issue["id"], "identifier": issue.get("identifier", issue["id"][:8]),
                "agent_id": target["agent_id"], "thread_id": 0}
            save_state(state)
        # Persist the owner's words in Paperclip before any Discord call can fail,
        # and before reopening: reopening wakes the agent, which must see them.
        comment = await pc.comment(c["issue_id"], f"@{target['name']} {text}\n\n_(via Discord)_")
        if c.pop("_status", None) in ("done", "cancelled", "blocked"):
            now = (await pc.issue(c["issue_id"]))["status"]  # a human comment may already have reopened it
            if now in ("done", "cancelled", "blocked"):
                await pc.reopen(c["issue_id"], now)
        thread = await chat_thread(msg.channel, c, target)
        state["threads"][str(thread.id)]["seen"].append(comment.get("id"))
        save_state(state)
        await thread.send(f"> {clip(text, 1800)}", allowed_mentions=QUIET)
        await msg.add_reaction("💬")


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


# ── Decisions: attention feed -> Discord buttons ────────────────────────────

def link(label: str, href: str) -> discord.ui.Button:
    return discord.ui.Button(style=discord.ButtonStyle.link, label=label[:80], url=PC_LINK_BASE + href)


def button(label: str, custom_id: str, style: discord.ButtonStyle) -> discord.ui.Button:
    return discord.ui.Button(style=style, label=label[:80], custom_id=custom_id)


async def destination(item: dict) -> discord.abc.Messageable | None:
    meta = item["subject"].get("metadata") or {}
    issue_id = meta.get("issueId") or (item.get("relatedIssue") or {}).get("id")
    for thread_id, t in state["threads"].items():
        if t["issue_id"] == issue_id:
            return client.get_channel(int(thread_id)) or await client.fetch_channel(int(thread_id))
    agent_id = meta.get("createdByAgentId") or meta.get("assigneeAgentId")
    channel_id = next((c for c, tg in CHANNELS.items() if tg["agent_id"] == agent_id), None)
    channel_id = channel_id or DEFAULT_CHANNEL.get(item["companyId"])
    if not channel_id:
        return None
    return client.get_channel(channel_id) or await client.fetch_channel(channel_id)


def describe(item: dict) -> str:
    who = item.get("originAgentName") or "An agent"
    issue = item.get("relatedIssue") or {}
    where = f" · {issue['identifier']} {issue['title']}" if issue.get("identifier") else ""
    return f"<@{OWNER_ID}> **{who}** needs you — {item.get('whyNow', '')}\n**{item['subject']['title']}**{where}"


async def build_interaction(item: dict) -> tuple[str, discord.ui.View] | None:
    meta = item["subject"]["metadata"]
    iid, issue_id, kind = item["subject"]["id"], meta["issueId"], meta["kind"]
    inter = next((i for i in await pc.interactions(issue_id) if i["id"] == iid), None)
    if not inter or inter["status"] != "pending":
        return None
    payload = inter.get("payload") or {}
    text = describe(item)
    view = discord.ui.View(timeout=None)
    ctx = {"issue": issue_id, "kind": kind, "title": item["subject"]["title"]}

    if kind == "request_confirmation" and not payload.get("secretProposal"):
        text += f"\n{clip(payload.get('prompt', ''), 800)}"
        if payload.get("detailsMarkdown"):
            text += f"\n>>> {clip(payload['detailsMarkdown'], 900)}"
        if payload.get("toolAction"):
            text += "\n_Accepting runs the proposed action._"
        ctx["reason_required"] = bool(payload.get("rejectRequiresReason"))
        ctx["allow_reason"] = payload.get("allowDeclineReason", True)
        view.add_item(button(payload.get("acceptLabel") or "Accept", f"pc:acc:{iid}", discord.ButtonStyle.success))
        view.add_item(button(payload.get("rejectLabel") or "Reject", f"pc:rej:{iid}", discord.ButtonStyle.danger))
    elif kind == "ask_user_questions":
        questions = payload.get("questions") or []
        for q in questions:
            text += f"\n> {clip(q.get('prompt', ''), 600)}"
        q = questions[0] if len(questions) == 1 else None
        if q and q.get("selectionMode") == "single":
            opts = q.get("options") or []
            ctx.update(qid=q["id"], options=[o["id"] for o in opts])
            if len(opts) <= 4:
                for n, o in enumerate(opts):
                    view.add_item(button(o["label"], f"pc:ans:{iid}:{n}", discord.ButtonStyle.primary))
            else:
                sel = discord.ui.Select(custom_id=f"pc:sel:{iid}", placeholder="Choose an answer…",
                                        options=[discord.SelectOption(label=clip(o["label"], 100), value=str(n))
                                                 for n, o in enumerate(opts[:25])])
                view.add_item(sel)
            if q.get("allowOther"):
                view.add_item(button("Other…", f"pc:oth:{iid}", discord.ButtonStyle.secondary))
        else:
            text += "\n_Several questions — answer in Paperclip._"
    else:
        text += f"\n_{kind.replace('_', ' ')} — open in Paperclip._"

    href = (item.get("subject") or {}).get("href")
    if href:
        view.add_item(link("Open in Paperclip", href))
    state["actions"][iid] = ctx
    return text, view


async def build_approval(item: dict) -> tuple[str, discord.ui.View] | None:
    aid = item["subject"]["id"]
    text = describe(item)
    if item.get("detail"):
        text += f"\n{clip(json.dumps(item['detail'], ensure_ascii=False), 600)}"
    view = discord.ui.View(timeout=None)
    view.add_item(button("Approve", f"pc:apv:{aid}", discord.ButtonStyle.success))
    view.add_item(button("Reject", f"pc:apr:{aid}", discord.ButtonStyle.danger))
    if (item.get("subject") or {}).get("href"):
        view.add_item(link("Open in Paperclip", item["subject"]["href"]))
    state["actions"][aid] = {"kind": "approval", "title": item["subject"]["title"]}
    return text, view


async def notify(item: dict) -> None:
    kind = item["sourceKind"]
    if kind == "issue_thread_interaction":
        built = await build_interaction(item)
    elif kind == "approval":
        built = await build_approval(item)
    else:
        view = discord.ui.View(timeout=None)
        if (item.get("subject") or {}).get("href"):
            view.add_item(link("Open in Paperclip", item["subject"]["href"]))
        built = (describe(item), view)
    if built is None:
        return
    dest = await destination(item)
    if dest is None:
        log.warning("no destination for %s", item["dedupKey"])
        return
    text, view = built
    sent = await dest.send(clip(text, 1990), view=view, allowed_mentions=NO_PING)
    state["notified"][item["dedupKey"]] = {"company": item["companyId"], "channel": sent.channel.id,
                                           "message": sent.id, "closed": False,
                                           "subject": item["subject"]["id"], "kind": kind}
    if item["subject"]["id"] in state["actions"]:
        state["actions"][item["subject"]["id"]]["msg"] = [sent.channel.id, sent.id]
    save_state(state)
    log.info("notified %s (%s)", item["dedupKey"], kind)


async def close_message(channel_id: int, message_id: int, note: str) -> None:
    try:
        ch = client.get_channel(channel_id) or await client.fetch_channel(channel_id)
        m = await ch.fetch_message(message_id)
        await m.edit(content=clip(f"{m.content}\n{note}", 1990), view=None)
    except discord.NotFound:
        pass


async def attention_loop() -> None:
    while True:
        for company in sorted(DEFAULT_CHANNEL):
            try:
                feed = await pc.attention(company)
                live = set()
                for item in feed["items"]:
                    if item["sourceKind"] not in ATTENTION_KINDS:
                        continue
                    live.add(item["dedupKey"])
                    if item["dedupKey"] not in state["notified"]:
                        await notify(item)
                if feed.get("nextCursor"):
                    continue
                for key, n in list(state["notified"].items()):
                    if n["company"] == company and not n["closed"] and key not in live:
                        n["closed"] = True
                        await close_message(n["channel"], n["message"], "✔️ Resolved.")
                        save_state(state)
            except Exception:
                log.exception("attention poll failed for company %s", company)
        await asyncio.sleep(POLL_SECONDS)


class TextModal(discord.ui.Modal):
    def __init__(self, title: str, label: str, required: bool, done) -> None:
        super().__init__(title=clip(title, 45))
        self.field = discord.ui.TextInput(label=clip(label, 45), style=discord.TextStyle.paragraph,
                                          required=required, max_length=1000)
        self.add_item(self.field)
        self.done = done

    async def on_submit(self, interaction: discord.Interaction) -> None:
        await self.done(interaction, str(self.field.value).strip())


async def settle(interaction: discord.Interaction, ident: str, method: str, path: str,
                 body: dict, verb: str) -> None:
    """Call Paperclip, tell the owner (ephemeral), and strip the buttons."""
    await interaction.response.defer(ephemeral=True)
    try:
        await pc.request(method, path, json=body)
    except httpx.HTTPStatusError as e:
        await interaction.followup.send(f"❌ Paperclip said {e.response.status_code}: {e.response.text[:300]}",
                                        ephemeral=True)
        return
    await interaction.followup.send(f"✅ {verb}.", ephemeral=True)
    msg = (state["actions"].get(ident) or {}).get("msg")
    if msg:
        await close_message(msg[0], msg[1], f"✅ {verb} from Discord.")


@client.event
async def on_interaction(interaction: discord.Interaction) -> None:
    cid = (interaction.data or {}).get("custom_id", "")
    if not cid.startswith("pc:") or interaction.type not in (
            discord.InteractionType.component, discord.InteractionType.modal_submit):
        return
    if interaction.user.id != OWNER_ID:
        await interaction.response.send_message("Only the owner can answer these.", ephemeral=True)
        return
    _, action, ident, *rest = cid.split(":")
    ctx = state["actions"].get(ident)
    if ctx is None:
        await interaction.response.send_message("Lost the context for this one — open it in Paperclip.",
                                                ephemeral=True)
        return
    base = f"/api/issues/{ctx.get('issue')}/interactions/{ident}"

    if action == "acc":
        await settle(interaction, ident, "POST", f"{base}/accept", {}, "Accepted")
    elif action == "rej":
        if not ctx.get("allow_reason", True) and not ctx.get("reason_required"):
            await settle(interaction, ident, "POST", f"{base}/reject", {}, "Rejected")
            return

        async def reject(i: discord.Interaction, text: str) -> None:
            await settle(i, ident, "POST", f"{base}/reject", {"reason": text} if text else {}, "Rejected")

        await interaction.response.send_modal(
            TextModal("Reject", "Reason", bool(ctx.get("reason_required")), reject))
    elif action in ("ans", "sel"):
        idx = int(rest[0]) if action == "ans" else int(interaction.data["values"][0])
        body = {"answers": [{"questionId": ctx["qid"], "optionIds": [ctx["options"][idx]]}]}
        await settle(interaction, ident, "POST", f"{base}/respond", body, "Answered")
    elif action == "oth":
        async def other(i: discord.Interaction, text: str) -> None:
            body = {"answers": [{"questionId": ctx["qid"], "optionIds": [], "otherText": text}]}
            await settle(i, ident, "POST", f"{base}/respond", body, "Answered")

        await interaction.response.send_modal(TextModal("Your answer", "Answer", True, other))
    elif action == "apv":
        await settle(interaction, ident, "POST", f"/api/approvals/{ident}/approve", {}, "Approved")
    elif action == "apr":
        async def decline(i: discord.Interaction, text: str) -> None:
            await settle(i, ident, "POST", f"/api/approvals/{ident}/reject",
                         {"decisionNote": text} if text else {}, "Rejected")

        await interaction.response.send_modal(TextModal("Reject", "Note (optional)", False, decline))


if __name__ == "__main__":
    client.run(TOKEN, log_handler=None)
