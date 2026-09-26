# Paperclip — multi-agent orchestration

**What:** [Paperclip](https://github.com/paperclipai/paperclip) (MIT) runs a
"company" of AI agents: you are the **board**, you hire a CEO agent, it breaks
goals into tasks, hires other agents (with your approval) and reports back on
tickets. Paperclip itself is only the control plane — the actual work is done
by agent harnesses it drives: Claude Code, Codex, Gemini CLI, OpenCode, Hermes,
OpenClaw, or plain HTTP/process adapters.

Companion walkthrough used for this setup: NetworkChuck's
[paperclip-guide](https://github.com/theNetworkChuck/paperclip-guide) (tested
on 2026.916.1 — the same version pinned here).

| | |
|---|---|
| Image | `ghcr.io/paperclipai/paperclip:2026.916.1` (arm64, ~6.7GB — it bundles four agent CLIs) |
| URL | `http://100.81.171.49:3100` (Tailscale) · `http://127.0.0.1:3100` (on the Mac mini) |
| Exposure | Tailscale + localhost only. **No tunnel hostname.** Not reachable on the LAN IP. |
| Auth | `authenticated` / `private` mode, email + password (Better Auth). Sign-ups closed after the first admin claimed the instance. |
| Database | Embedded PostgreSQL inside the container (`data/instances/default/db`) |
| RAM | ~850–900MB idle, capped at 1.5GB (`mem_limit`) |
| Health | `GET /api/health` → `{"status":"ok",…}` |

## Why it is built this way

- **Docker, not native launchd.** The upstream image already ships `claude`,
  `codex`, `gemini` and `opencode`, and the `*_local` adapters exec them
  *inside the container*. So Docker does not need to reach the host's
  `claude` — it has its own, which just needs its own login (below). Native
  install was rejected: agents run with `dangerouslySkipPermissions: true` by
  default (headless runs can't answer prompts), and natively that means an
  unattended agent with your whole home directory, Keychain and SSH keys. In
  the container it can only touch `./data`.
- **Embedded Postgres, not a `postgres:17` sidecar.** The host is swap-bound
  (≈10 of 11GB swap in use on 2026-09-26). One container instead of two, and
  it is upstream's own quickstart shape.
- **Pinned tag, Watchtower off.** Stable releases run DB migrations on start;
  upgrade deliberately (bump the tag, read `releases/v*.md` upstream first).
- **Port bound to `127.0.0.1` and `100.81.171.49` explicitly**, not `0.0.0.0`,
  so the LAN can't reach it. If Tailscale is down when Docker starts, the
  second binding fails — `docker compose up -d` again once Tailscale is up.
- **`PAPERCLIP_ALLOWED_HOSTNAMES` must list every hostname used to reach it**,
  including `paperclip` (Glance, on the Docker network) and
  `host.docker.internal` (Uptime Kuma). A missing name returns **403**, which
  is what a red Glance monitor meant on first deploy.

## First-time setup (already done 2026-09-26)

```bash
~/.dotfiles/services/setup-services.sh paperclip   # stage + create .env
# edit ~/services/paperclip/.env: BETTER_AUTH_SECRET (openssl rand -hex 32),
#   PAPERCLIP_ALLOWED_HOSTNAMES (add the MagicDNS name)
cd ~/services/paperclip && docker compose up -d
```

Then create the first admin: open the URL, **Sign up**, click **Claim this
instance** (upstream's browser claim, only offered in `authenticated/private`
mode). Afterwards set `PAPERCLIP_AUTH_DISABLE_SIGN_UP=true` in `.env` and
`docker compose up -d` so nobody else on the tailnet can register.

The admin email/password generated during setup sit in
`~/services/paperclip/.env` as a reference copy (Paperclip doesn't read them).
**Move them to Vaultwarden and delete those two lines.**

⚠️ **Don't lose the admin password.** No SMTP is configured, so there is no
reset email, and upstream's recovery command (`paperclipai auth bootstrap-ceo
--force`) refuses to run in this container: it needs
`/paperclip/instances/default/config.json`, which only `paperclipai onboard`
creates — the Docker image configures itself from env vars instead (checked
2026-09-26: *"No config found … Run paperclip onboard first"*). Vaultwarden is
the recovery path.

## Adding agents

Paperclip calls this "hiring". Every agent needs a **runtime** (adapter) and a
**credential** for its model provider. Nothing paid is configured yet.

### Claude Code (recommended first — you already have a subscription)

The container has its own `claude` binary; the one on the Mac mini's host is
logged in, but that login lives in the macOS Keychain and cannot be mounted
into a Linux container. Pick one:

**A. Subscription token (cleanest):**

```bash
claude setup-token          # on the Mac mini host; prints a long-lived OAuth token
```

Put it in `~/services/paperclip/.env` as `CLAUDE_CODE_OAUTH_TOKEN=…`, then
`cd ~/services/paperclip && docker compose up -d`. Every `claude_local` agent
picks it up. Usage counts against your Claude plan limits, not API billing.

**B. Log the container's CLI in interactively:**

```bash
docker exec -it paperclip claude      # then /login, open the printed URL
```

The login is stored in `data/.claude/` (container `$HOME` is `/paperclip`),
so it survives restarts. It is deliberately excluded from the R2 backup.

**C. In the UI:** agent → **Harness / Runtime** → *Choose a managed
connection* (subscription or API key, stored encrypted by Paperclip).

With A or B the Runtime tab shows *"Existing authentication, not managed by
Connections"* — that is correct.

### Codex / Gemini / OpenCode

Same pattern, each needs its own credential — none are set up:

- **Codex:** `OPENAI_API_KEY` in `.env`, or `docker exec -it paperclip codex login`.
- **Gemini:** `docker exec -it paperclip gemini` → OAuth (persists in
  `data/.gemini/`), or a `GEMINI_API_KEY` that is *restricted to the Gemini
  API* in Google Cloud (unrestricted keys are rejected). Given the de-Googling
  goal, prefer not to.
- **Local model via Ollama (free, slow):** use the **OpenCode** runtime.
  Ollama runs natively on the host and the container reaches it at
  `http://host.docker.internal:11434` (verified reachable). Create
  `~/services/paperclip/data/.config/opencode/opencode.json`:

  ```json
  {
    "$schema": "https://opencode.ai/config.json",
    "provider": {
      "ollama": {
        "npm": "@ai-sdk/openai-compatible",
        "name": "Ollama (Mac mini)",
        "options": { "baseURL": "http://host.docker.internal:11434/v1" },
        "models": { "qwen2.5:7b": { "name": "qwen2.5 7B" } }
      }
    }
  }
  ```

  then pick model `ollama/qwen2.5:7b` on the agent. *Untested end to end* — a
  7B model is weak at multi-step agent work; treat it as a toy or a cheap
  "scanner" role, not a CEO.

### ⚠️ Memory while agents run

Idle is ~900MB of the 1.5GB cap. Each Claude Code run adds a Node process
(~300–500MB). Keep to **one agent working at a time** at first; if runs die
with exit 137, the cap was hit — raise `mem_limit` only after checking
`memory_pressure` and `sysctl vm.swapusage` on the host.

## First company + first task

1. Open the URL and log in. The wizard asks for an **organization** name (the
   docs say "company" — same thing), then your first agent: name it, runtime
   **Claude Code**. Skip the "connect a model" screen if you used option A/B.
2. If the CEO's first run fails with *"terminal access failure"*, the CLI
   isn't logged in — do A or B above, then **Inbox → Retry**.
3. **Board → Settings → General:** write a Description (the company's
   mission) and turn on **Require board approval for new hires**.
4. **Agents → (CEO) → Instructions → AGENTS.md:** append what its job is.
5. **Projects → New project**, then create a task inside it and **assign it
   to the CEO** — assigning is what wakes an agent (so does an @mention).
   Task modes: *Agent* (does the work), *Ask* (answer only), *Plan* (plan for
   your review).
6. Approve hire requests from the CEO under **Decisions / Inbox**.

## Operations

```bash
cd ~/services/paperclip
docker compose logs -f --tail=50
curl -s 127.0.0.1:3100/api/health | jq '{status,bootstrapStatus,databaseBackup}'
# CLI (most commands need a board login: `… paperclipai auth login` first)
docker exec -it paperclip sh -c 'cd /app && node cli/node_modules/tsx/dist/cli.mjs cli/src/index.ts --help'
```

## Backups

- Paperclip dumps its own DB **daily, 14 days retention** into
  `data/instances/default/data/backups/`; the nightly rclone job ships those.
  The live `data/instances/default/db/` is excluded (a live Postgres copied
  file-by-file is not a restorable backup).
- `data/instances/default/secrets/master.key` **is** backed up: agent secrets
  in the DB are encrypted with it, and a dump without the key is useless for
  them.
- Agent CLI logins (`.claude/`, `.codex/`, `.gemini/`) are excluded.
- Restore: stop the container, restore `data/`, then restore the newest dump
  per upstream `docs/deploy/database.md`.

## Upgrading

```bash
# bump the tag in services/paperclip/docker-compose.yml, then:
cp ~/.dotfiles/services/paperclip/docker-compose.yml ~/services/paperclip/
cd ~/services/paperclip && docker compose pull && docker compose up -d
```

Read upstream `releases/v<version>.md` first. Migrations run automatically on
start.
