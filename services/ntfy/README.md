# ntfy — phone push notifications

**What:** [ntfy](https://github.com/binwiederhier/ntfy) (Apache-2.0 / GPL-3.0)
is a pub/sub push-notification server. Publish a message to a topic with a
`curl`/HTTP call, the phone app (subscribed to that topic) gets a push. Built
for the **Coach** agent in Paperclip to push its daily check-in summary and
decisions to the phone, but any script or service can publish to it.

| | |
|---|---|
| Image | `binwiederhier/ntfy` |
| URL | `http://100.81.171.49:8095` (Tailscale) · `http://127.0.0.1:8095` (on the Mac mini) |
| Exposure | Tailscale + localhost only. **No tunnel hostname** (see below). |
| Auth | `auth-default-access: deny-all` — every topic denies read+write until a user is explicitly granted access |
| Data | `./data/auth/auth.db` (users, tokens, ACLs), `./data/cache/cache.db` (message cache, 12h) |
| Health | `GET /v1/health` |

## Why a second, separate ntfy

`services/odysseus` already bundles an `ntfy` container (port 8091, no auth,
cache-only, no persistent user db). That one stays exactly as it is — **don't
touch it** — but it's wrong for this job for two reasons:

1. **Odysseus is on-demand** (scale-to-zero since 2026-09-26): all four of its
   containers, including its ntfy, stop after idle. A push that has to survive
   "is anything else awake right now" isn't reliable for a daily coaching
   summary.
2. **No auth.** Anyone who can reach port 8091 can publish to or read any
   topic. Fine for casual reminders; not fine for a topic carrying training
   and health context.

This standalone instance is always-on (no on-demand wrapper), has a persistent
auth database, and defaults every topic to deny-all.

## First-time setup

1. Stage and start:
   ```bash
   ~/.dotfiles/services/setup-services.sh ntfy
   cd ~/services/ntfy && docker compose up -d
   docker compose ps        # wait for "healthy"
   ```
2. Pick a private topic name with a random suffix so it can't be guessed or
   subscribed to by anyone who finds the base URL:
   ```bash
   TOPIC="coach-$(openssl rand -hex 4)"
   echo "$TOPIC"             # note it, then put it in ~/services/ntfy/.env as NTFY_TOPIC=...
   ```
3. Create two users — one for publishing (Coach agent), one for reading (the
   phone). Passwords are prompted interactively, not passed on the command
   line (keeps them out of shell history):
   ```bash
   docker exec -it ntfy ntfy user add --role=user publisher
   docker exec -it ntfy ntfy user add --role=user phone
   ```
4. Grant exactly the access each needs (deny-all is the default for everyone
   else, including these two users on every *other* topic):
   ```bash
   docker exec -it ntfy ntfy access publisher "$TOPIC" write-only
   docker exec -it ntfy ntfy access phone "$TOPIC" read-only
   ```
5. Generate a long-lived access token for each user (this is what goes into
   `.env` / the Paperclip secret / the phone app — **never the password**):
   ```bash
   docker exec -it ntfy ntfy token add publisher   # → publish token
   docker exec -it ntfy ntfy token add phone        # → read token
   ```
6. Save `NTFY_TOPIC`, `NTFY_PUBLISH_TOKEN`, `NTFY_READ_TOKEN` into
   `~/services/ntfy/.env` (placeholders already there from `.env.example`).
   These never get committed — `.env` is gitignored, and the tokens exist only
   in ntfy's own `auth.db` and this file.

### Test: publish, then verify it was stored

```bash
cd ~/services/ntfy
TOKEN=$(grep '^NTFY_PUBLISH_TOKEN=' .env | cut -d= -f2-)
TOPIC=$(grep '^NTFY_TOPIC=' .env | cut -d= -f2-)

curl -s -H "Authorization: Bearer $TOKEN" \
  -d "test message from setup" \
  "http://127.0.0.1:8095/$TOPIC"

READ_TOKEN=$(grep '^NTFY_READ_TOKEN=' .env | cut -d= -f2-)
curl -s -H "Authorization: Bearer $READ_TOKEN" \
  "http://127.0.0.1:8095/$TOPIC/json?poll=1&since=all"
```
The poll should return the just-published message as a JSON line. If it
returns `{"code":40101,...}` the token/topic access is wrong — re-check step 4.

## Reading the tokens later (never print them in chat)

```bash
grep -E '^NTFY_(TOPIC|PUBLISH_TOKEN|READ_TOKEN)=' ~/services/ntfy/.env
```

## Phone access

Over Tailscale, `http://100.81.171.49:8095` is enough — the ntfy iOS/Android
app supports adding a self-hosted server by URL, then subscribing to a topic
with a token (Settings → the topic → "Use different auth" or similar, pass the
**read** token, not the publish token).

**No public tunnel hostname is added.** It isn't needed: the phone has
Tailscale for every other Tailscale-only service already (Sonarr, Radarr,
Transmission, Syncthing, …), and adding a public hostname for a push server
just to save opening the Tailscale app first isn't worth the extra attack
surface. If that ever changes (e.g. Tailscale is unreliable on cellular for
this phone), the option is: add `ntfy.peciulevicius.com` to
`~/.cloudflared/config.yml` pointing at `http://ntfy:80` on this compose
network, add a DNS route, put Cloudflare Access in front of it (never expose
ntfy's own auth to the public internet as the only gate), then kickstart the
real cloudflared agent.

## Publishing from other services

Any container that needs to push a phone notification does the same thing the
Coach agent does — a plain `curl` with the publish token, from anywhere that
can reach `100.81.171.49:8095` or `ntfy:80` (if joined to this compose
network):

```bash
curl -H "Authorization: Bearer $NTFY_PUBLISH_TOKEN" \
  -H "Title: Coach — Daily check-in" \
  -d "Keep today's session. TSB -8, HRV normal, sleep 7.2h." \
  "http://100.81.171.49:8095/$NTFY_TOPIC"
```

## Backups

`./data/auth` (users/tokens/ACLs) is backed up as part of the normal
`~/services` sync in `rclone-backup.sh` — losing it means recreating users and
re-issuing tokens (annoying, not catastrophic; message history is not
recoverable regardless). `./data/cache` (the message cache, a live SQLite file
rewritten on every publish) is excluded — same class as Portainer's db and
Paperclip's embedded Postgres: rewritten continuously, would fail R2's MD5
check mid-upload, and its contents are transient notifications, not source of
truth.

## Operations

```bash
cd ~/services/ntfy
docker compose logs -f --tail=50
docker exec -it ntfy ntfy user list
docker exec -it ntfy ntfy access               # show the full ACL table
curl -s http://127.0.0.1:8095/v1/health
```
