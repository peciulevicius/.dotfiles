# discord-bridge

Two-way chat between Discord and the Paperclip **Coach** team (Coach +
Dietitian). Built 2026-09-27 because the webhook the agents post through is
one-way, and opening Paperclip on the phone to file a task was too much
friction for "tired today, push Thursday's run".

## How it works

```
you: message in #ai-training-coach ──► bridge ──► Paperclip issue assigned to Coach
                                          └──► Discord thread "COA-12 · tired today"
Coach comments on the issue ──► bridge polls (30s) ──► posted in that thread
you: reply in the thread ──► bridge ──► issue comment "@Coach …" (the @mention wakes it)
```

- One channel per agent, set by `CHANNEL_MAP`
  (`channelId:agentId:AgentName,…`). Currently `#ai-training-coach` → Coach
  and `#ai-training-dietitian` → Dietitian.
- Only messages from `DISCORD_OWNER_ID` are relayed; everyone else, and all
  bots (including the agents' own webhook posts), is ignored.
- A reply in the thread becomes a comment with an `@AgentName` mention, because
  Paperclip wakes an agent on a mention (`issue_comment_mentioned`). A plain
  comment is not guaranteed to wake it.
- Approvals and decisions are **not** relayed as buttons. When an agent raises
  a decision, approve it in Paperclip (`http://100.81.171.49:3100`), or reply
  in the thread ("approved") and the agent reads that as a comment.
- The agents' scheduled posts (daily check-in, plans) go out through their own
  webhooks, not the bridge: Coach → `#ai-training-coach`
  (`COACH_DISCORD_WEBHOOK`), Dietitian → `#ai-training-dietitian`
  (`DIETITIAN_DISCORD_WEBHOOK`).
- State (thread → issue, relayed comment IDs) lives in `./data/state.json`.
  Losing it only means old threads stop receiving replies.

No ports are published: the bridge only makes outbound connections (the Discord
gateway, and Paperclip at `http://paperclip:3100` over Paperclip's Docker
network). It signs in to Paperclip with the board account, the same way the
scripts in `services/paperclip/README.md` do.

## Setup from scratch

1. **Create the bot** at <https://discord.com/developers/applications> →
   *New Application* → name it (e.g. "Coach Team").
   - *Bot* → **Reset Token** → copy it (shown once).
   - *Bot* → enable **Message Content Intent** (privileged; without it the
     bot sees empty messages).
   - *OAuth2 → URL Generator* → scopes `bot`; permissions *View Channels*,
     *Send Messages*, *Create Public Threads*, *Send Messages in Threads*,
     *Read Message History*, *Add Reactions*. Open the generated URL and add
     the bot to your server.
2. **Create `#ai-training-dietitian`** next to `#ai-training-coach` (plus a
   webhook in it for the Dietitian's scheduled posts — Channel settings →
   Integrations → Webhooks).
3. **No IDs to copy.** `configure.sh` signs in to Paperclip with the private
   board credentials and resolves the current Coach and Dietitian in the
   Coach company. It fails before writing when a name is missing or ambiguous,
   so rerunning setup cannot reinstall retired agent IDs. It reads each channel's ID from its webhook
   (a GET on a webhook URL returns `channel_id`), and the bridge treats the
   bot application's owner as the only allowed user.
4. **Stage and configure:**
   ```bash
   ~/.dotfiles/services/setup-services.sh discord-bridge
   ~/.dotfiles/services/discord-bridge/configure.sh
   ```
   `configure.sh` asks only for the token (hidden), writes it and the channel map to
   `~/services/discord-bridge/.env` (chmod 600), builds and starts the
   container, and prints the log. The Paperclip login is already filled in from
   `~/.config/homelab/paperclip-admin.env`.
5. **Test:** post "test — reply with one line" in `#ai-training-coach`. A
   thread opens with `📋 COA-n created`, and the Coach's reply appears there
   within about a minute of its run finishing.

## Operating

```bash
docker logs -f discord-bridge            # relay activity, errors
cd ~/services/discord-bridge && docker compose up -d --build   # after editing bridge.py
```

- **Add an agent or channel:** append `channelId:agentId:Name` to
  `CHANNEL_MAP` in `.env`, then `docker compose up -d`.
- **Rotate the bot token:** Developer Portal → *Reset Token*, then re-run
  `configure.sh`.
- **Separate operational notifications:** see
  [the cron notification runbook](../../scripts/cron/README.md#notifications).
  Creating notification channels/webhooks requires *Manage Channels* and
  *Manage Webhooks* on the bot's server role; ordinary two-way chat needs
  neither. The existing bot lacked those management permissions on 2026-09-29.
- **Paperclip password changed:** update `PAPERCLIP_PASSWORD` in `.env` too
  (the `credential-rotation` skill lists this copy).

## Failure modes

- **Bot online but ignores messages:** Message Content Intent is off, or the
  message wasn't sent by the owner (`DISCORD_OWNER_ID`, or the bot app's owner).
- **`401` loops in the log:** the Paperclip password in `.env` is stale.
- **Thread gets no reply:** the agent is paused, or its run failed. Check the
  issue in Paperclip. The bridge only relays comments; it never retries
  runs.
