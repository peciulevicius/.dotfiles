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
| RAM | ~0.8GB after start, ~1.2GB idle once both companies are loaded; capped at 2GB (`mem_limit`, raised from 1.5GB 2026-09-26) |
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

Same pattern, each needs its own credential:

- **Codex — logged in (ChatGPT subscription), 2026-09-26.** Done with
  `docker exec -it paperclip codex login --device-auth`; check with
  `docker exec paperclip codex login status`. Paperclip symlinks that
  `auth.json` into each `codex_local` agent's own `CODEX_HOME`, so every Codex
  agent shares the one subscription login.
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

- **Gemini: not set up** (de-Googling — the user decides). **No local Ollama
  models for agents either**: RAM is too tight (see below).

### ⚠️ Memory while agents run

With two companies loaded the server idles at ~1.2GB anon RSS. At the old
1.5GB cap `memory.events` showed the limit hit 1500+ times before any agent
had run, and each Claude Code / Codex run adds a CLI process (~300–500MB) — a
guaranteed exit 137. Raised to **2GB** on 2026-09-26, allowed by the rule
*raise only when host `memory_pressure` free ≥ 30%* (it was 37%; swap
7.4–7.5 of 8GB, unchanged). Keep to **one agent working at a time**; if runs
die with exit 137, check `memory_pressure` and `sysctl vm.swapusage` before
raising again. Check the container's own pressure with
`docker exec paperclip cat /sys/fs/cgroup/memory.events` (`max` counts hits).

## Companies (configured 2026-09-26)

Two companies ("organizations" in the UI). Both have **Require board approval
for new hires** on, and **every agent has timer heartbeats off**
(`runtimeConfig.heartbeat.enabled: false`, `wakeOnDemand: true`), so an agent
wakes only when a task is assigned to it, it is @mentioned, or a routine
fires.

### Homelab — weekly health & security reporting

Mission: *Weekly health and security reporting for Džiugas's Mac mini homelab.
Read reports, spot problems, recommend next actions as decisions. Never change
servers — changes are done by Džiugas with Claude Code.*

| Agent | Role | Runtime | Status |
|---|---|---|---|
| Homelab Lead (CTO / Homelab Lead) | `ceo`, reports to the board | Claude Code | active (idle) |
| Security Analyst | `security` → Lead | Codex | **paused** |
| Storage & Backup Analyst | `devops` → Lead | Claude Code (→ Hermes/OpenCode on OpenRouter later) | **paused** |

- Project **Weekly Reports** (in progress). Leftover wizard project
  *Onboarding* with task PEC-1 is untouched.
- Routine **Homelab weekly report**: Sunday **10:00 Europe/Vilnius**, assigned
  to the Lead, `skip_if_active`, `skip_missed`. The Lead reads `/reports`,
  writes one short report document on the run's task and raises one board
  decision per problem. It delegates to an analyst only by asking the board to
  resume that analyst — so a normal week costs **one** Claude Code run.

**Why the agents can't touch anything:** they have no route to the host. The
only input is a read-only directory the host fills — the reports feed below.
The "never change servers" rule is in every AGENTS.md too, but the mount is
what enforces it.

#### Reports feed

```
host cron, Sun 09:30  scripts/utils/paperclip-reports.sh
   └─ writes  ~/services/paperclip/reports/{latest.md, weekly-YYYY-MM-DD.md}
                  │  mounted read-only
                  ▼
container     /reports   ← read by the Sunday 10:00 routine
```

The script (09:30, after the 09:00 audit cron) writes one markdown file:
`homelab-audit.sh` output (run fresh), the tail of the newest
`~/logs/rclone-*.log`, `docker ps -a` names/status plus top memory users,
`df`/`memory_pressure`/swap, Uptime Kuma's last status per active monitor
(`sqlite3 -readonly` on `kuma.db`, name + status + time only), and the
*Who does what* index from `docs/HOME_SERVER_TODO.md`. It never reads a
`.env`; a final Perl pass redacts `password|secret|token|api_key|webhook=…`
values and Discord webhook URLs as a backstop, and strips ANSI colours. Eight
weeks of `weekly-*.md` are kept for week-over-week comparison.

⚠️ **Mounted at `/reports`, not `/paperclip/reports`.** The image's
entrypoint runs `chown -R` on `/paperclip` as root at every start; a
read-only mount inside it makes `chown` fail and the container crash-loops
(hit on 2026-09-26, fixed by moving the mount).

Run it by hand any time: `~/.dotfiles/scripts/utils/paperclip-reports.sh`,
then **Routines → Homelab weekly report → Run now** to test the agent side.

### Studio — faceless indie studio

Mission: *Faceless indie studio: find, validate, design, build and launch
small useful apps and content under an anonymous brand. Nothing ships, gets
published, or spends money without board approval.*

| Agent | Role | Runtime | Status |
|---|---|---|---|
| CEO | `ceo`, reports to the board | Claude Code | active (idle) |
| Product Manager | `pm` → CEO | Codex | active (idle) |
| Researcher | `researcher` → CEO | Claude Code (→ Hermes/OpenCode on OpenRouter later) | active (idle) |

- The wizard's CEO was reused. An earlier Product Manager (Claude Code) had
  been terminated in the UI; the new one was filed as a hire request and
  approved, the same path the approval wall forces on the CEO.
- AGENTS.md per role: Paperclip's generated text stays on top; a short
  *"Your job — … (added by the board)"* section is appended (≤15 lines). The
  CEO and Researcher sections carry the idea rubric from the private Obsidian
  note (*adjacent paid product? · 100 buyers without ads? · MVP in ~6 weeks of
  evenings?* plus problem/payer/revenue/first-10/kill criteria) and the
  ruled-out list (faceless content **as** the business; ads-dependent, big-team
  or regulated ideas). Stack defaults and "no secrets, PRs only, board approves
  merges" are in CEO and PM. Brand names and anonymity detail stay in the vault,
  not in Paperclip.
- Projects: **Idea Pipeline** (in progress — the one active project),
  *Studio Brand* (planned), *Onboarding* (wizard leftover, STU-1 untouched).
- First task **STU-2** *"Generate 20 app ideas against the rubric, score them,
  recommend 3 with 6-week MVP scopes"*: assigned to the CEO, **Planning** mode,
  status **backlog**. Paperclip doesn't wake an assignee for a backlog task
  (`issue-assignment-wakeup.ts` returns early), so nothing runs until you move
  it to **Todo**.
- Routine **Daily standup**: weekdays **17:00 Europe/Vilnius**, CEO
  facilitates, adapted from NetworkChuck's tested prompt (fan-out sub-task per
  active agent → collect → Q&A → one digest; "blocked with blockers" as the
  wait state). **Created paused.** Cost when on: every weekday ~1 CEO run +
  2 briefs + up to 2 Q&A + routed questions ≈ **5–7 agent runs/day, ~25–35 a
  week**, split across the Claude and ChatGPT subscriptions. It closes early
  when nobody worked, but it still wakes the CEO. Turn it on only while
  the Idea Pipeline is actually moving.

## Keeping usage down (the rules this setup follows)

1. **Timer heartbeats off** on every agent. Wakes come from assignments,
   @mentions and routines only. If you enable one, use ≥ 24h
   (`intervalSec: 86400`).
2. **Paused unless needed.** Homelab analysts stay paused; resume one for a
   specific task, pause it again after.
3. **One active project per company.** Park the rest as *planned*.
4. **Routines are the only schedule.** Homelab: one run a week. Studio
   standup: paused until there's work to stand up about.
5. **Backlog is a safe parking spot**: assigned-but-backlog never wakes
   anyone. Move to Todo to start.
6. **Budgets** (`budgetMonthlyCents`) only cap API-key spend. With
   subscription logins, watch **Audit → Costs** and the plans' own limits.

## Adding or changing agents

The approval wall is on in both companies, so a direct create returns
`409: Direct agent creation requires board approval`. Either:

- **Ask the CEO/Lead in a task** ("hire a … on Codex") — it files a hire
  request with its `paperclip-create-agent` skill; approve it under
  **Approvals**. Or
- **API, as the board.** Sign in once to get a session cookie (keep the
  password out of shell history and output):

  ```bash
  PW=$(grep '^PAPERCLIP_ADMIN_PASSWORD=' ~/services/paperclip/.env | cut -d= -f2-)
  jq -n --arg e dziugas@peciulevicius.com --arg p "$PW" '{email:$e,password:$p}' |
    curl -s -c /tmp/pc.cj -H 'Content-Type: application/json' \
      -H 'Origin: http://127.0.0.1:3100' --data @- \
      http://127.0.0.1:3100/api/auth/sign-in/email -o /dev/null -w '%{http_code}\n'
  pc() { curl -s -b /tmp/pc.cj -H 'Origin: http://127.0.0.1:3100' -H 'Content-Type: application/json' "$@"; }
  pc http://127.0.0.1:3100/api/companies | jq '.[]|{id,name}'
  # hire request (creates a pending agent + approval); adapterType can also be
  # codex_local or opencode_local:
  pc -X POST http://127.0.0.1:3100/api/companies/<companyId>/agent-hires -d '{
    "name":"…","role":"researcher","reportsTo":"<managerId>",
    "adapterType":"claude_local",
    "runtimeConfig":{"heartbeat":{"enabled":false,"wakeOnDemand":true}},
    "permissions":{"canCreateAgents":false}}'
  pc -X POST http://127.0.0.1:3100/api/approvals/<approvalId>/approve -d '{}'
  pc -X POST http://127.0.0.1:3100/api/agents/<agentId>/pause
  # append to AGENTS.md: GET then PUT /api/agents/<id>/instructions-bundle/file {path,content}
  rm /tmp/pc.cj
  ```

  Other endpoints used for this setup: `PATCH /api/companies/<id>`
  (`description`, `requireBoardApprovalForNewAgents`), `PATCH /api/agents/<id>`,
  `POST /api/companies/<id>/projects`, `POST /api/companies/<id>/issues`
  (`status:"backlog"`, `workMode:"planning"`), `POST
  /api/companies/<id>/routines` + `POST /api/routines/<id>/triggers`
  (`{"kind":"schedule","cronExpression":"0 10 * * 0","timezone":"Europe/Vilnius"}`).
  Full reference: `/app/docs/api/*.md` inside the container.

- Paperclip defaults every local agent to skip its CLI's permission prompts
  (`dangerouslySkipPermissions` / `dangerouslyBypassApprovalsAndSandbox`) —
  headless runs can't answer them. That's acceptable only because the agent is
  confined to this container (see *Why it is built this way*).

### Switching Researcher / Storage Analyst to OpenRouter (later)

They run on Claude Code for now because there's no `OPENROUTER_API_KEY` yet.
Once the key is in `~/services/paperclip/.env` (`docker compose up -d`), switch
each to **OpenCode** (`opencode_local`, model `openrouter/<model>`) or a
**Hermes** agent on OpenRouter: agent → **Harness / Runtime**, or `PATCH
/api/agents/<id>` with the new `adapterType`/`adapterConfig`. That moves the
cheap, high-volume research/scan work off the Claude plan.

### Export / import

**Board → Settings → Export** (pick Agents, Projects, Skills, Routines, Tasks)
downloads one zip — a full copy of a company minus approvals, costs and
activity. CLI inside the container:
`paperclipai company export <id> --out ./x` and
`paperclipai company import ./x --target new --new-company-name "…" --dry-run`
(then `--yes`; add `--collision skip` to avoid `-2` duplicates of bundled
skills). Secrets bound to agent env by ID don't travel — unbind before export.

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
