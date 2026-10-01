# discord-bridge

Two-way chat between Discord and Paperclip agents in **any company**, plus
Discord buttons for every decision that needs you (v2, 2026-10-01). Built
2026-09-27 because the webhook the agents post through is
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
  and `#ai-training-dietitian` → Dietitian. The bridge looks up each agent's
  company on start, so channels may point at agents in different companies
  (Studio CEO, Homelab Lead, a Finance Manager, …).
- Only messages from `DISCORD_OWNER_ID` are relayed; everyone else, and all
  bots (including the agents' own webhook posts), is ignored.
- A reply in the thread becomes a comment with an `@AgentName` mention, because
  Paperclip wakes an agent on a mention (`issue_comment_mentioned`). A plain
  comment is not guaranteed to wake it.
- **Decisions arrive as Discord messages with buttons** (and @mention you, so
  your phone buzzes). Every 30s the bridge reads each company's Paperclip
  *attention* feed (`GET /api/companies/<id>/attention`, the same list as the
  Inbox) and posts anything new:

  | Paperclip item | Discord message |
  |---|---|
  | `request_confirmation` | Accept / Reject buttons (Reject opens a reason box) |
  | `ask_user_questions`, one single-choice question | one button per option (select menu if >4), plus **Other…** (free-text box) |
  | `ask_user_questions` with several or multi-select questions | text + link to Paperclip |
  | `connection_intent` (e.g. Connect TrainingPeaks), `suggest_tasks`, verdict/checkbox requests | text + link — these need the Paperclip UI by design (OAuth consent) |
  | approval (hire, etc.) | Approve / Reject buttons |
  | blocked issue needing attention | text + link |

  Clicking calls Paperclip's own `accept` / `reject` / `respond` /
  `approve` endpoints as the board account, so it is exactly the same action
  as clicking in the UI. Only `DISCORD_OWNER_ID` can click. An item resolved
  elsewhere gets its buttons removed on the next poll. Where it is posted: in
  the Discord thread of that issue if there is one, else the channel of the
  agent that raised it, else the company's first mapped channel
  (`NOTIFY_CHANNELS` overrides). The first start after upgrading posts
  everything already pending.
- **Chatting back and forth:** a reply in a thread is a comment on the same
  issue, so the conversation keeps its context. Paperclip's server wakes the
  assignee on any human comment unless the issue is `done`/`cancelled`, and a
  human comment on a done/cancelled/blocked issue reopens it first
  (`issues.ts` implicit reopen) — so no follow-up ticket is needed from here.
- The agents' scheduled posts (daily check-in, plans) go out through their own
  webhooks, not the bridge: Coach → `#ai-training-coach`
  (`COACH_DISCORD_WEBHOOK`), Dietitian → `#ai-training-dietitian`
  (`DIETITIAN_DISCORD_WEBHOOK`).
- State (thread → issue, relayed comment IDs, which decisions were already
  posted and their button context) lives in `./data/state.json`. Losing it
  means old threads stop receiving replies, old buttons say "lost the
  context" (use the Open link), and pending decisions are re-posted once.

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

- **Add an agent or channel:** create the channel (give the bot *View
  Channel*, *Send Messages*, *Create Public Threads*), copy its ID (Developer
  Mode → right-click → Copy Channel ID), append `channelId:agentId:Name` to
  `CHANNEL_MAP` in `.env`, then `docker compose up -d`. For a new
  organisation also make a webhook in the channel for that company's
  scheduled posts.
- **Rotate the bot token:** Developer Portal → *Reset Token*, then re-run
  `configure.sh`.
- **Separate operational notifications:** see
  [the cron notification runbook](../../scripts/cron/README.md#notifications).
  Creating notification channels/webhooks requires *Manage Channels* and
  *Manage Webhooks* on the bot's server role; ordinary two-way chat needs
  neither. The bot already had those permissions when routing was applied on
  2026-09-30; the first channel move failed because the request resent
  unchanged permission overrides. The migration was corrected and completed;
  the separate Kuma message test is still pending.
- **Paperclip password changed:** update `PAPERCLIP_PASSWORD` in `.env` too
  (the `credential-rotation` skill lists this copy).

## Failure modes

- **Bot online but ignores messages:** Message Content Intent is off, or the
  message wasn't sent by the owner (`DISCORD_OWNER_ID`, or the bot app's owner).
- **`401` loops in the log:** the Paperclip password in `.env` is stale.
- **Buttons do nothing / "interaction failed":** the bridge was down or
  restarting when you clicked; click again. "Lost the context" means
  `state.json` was reset — use *Open in Paperclip*.
- **A decision never shows up in Discord:** it is not in the company's
  attention feed (check the Paperclip Inbox), the company has no mapped
  channel, or it is a kind outside the table above.
- **Thread gets no reply:** the agent is paused, or its run failed. Check the
  issue in Paperclip. The bridge only relays comments; it never retries
  runs.
