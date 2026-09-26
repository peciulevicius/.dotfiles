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
**credential** for its model provider. The only pay-per-token credential is
OpenRouter (capped at $3/month per agent, see *AI connections*).

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
- **Gemini:** there is **no Gemini connection type** in Paperclip (AI
  connections exist only for Anthropic, OpenAI, OpenRouter and xAI), so
  `gemini_local` agents always use the CLI's own login, like Codex. Either put
  `GEMINI_API_KEY=` in `.env` (preferred — survives anything; the key must be
  *restricted to the Gemini API* in Google Cloud) and `docker compose up -d`,
  or `docker exec -it -u node paperclip gemini` → *Use Gemini API key* / OAuth.
  ⚠️ The CLI encrypts that stored login with a key derived from **hostname +
  username**. Docker's default hostname is the container ID, which changes on
  every recreate, so the login silently became *"Corrupted credentials file"*
  after the next `docker compose up -d` (found 2026-09-26). The compose file
  now pins `hostname: paperclip`; the login made before that pin is
  unreadable and has to be entered once more.
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

- **Hermes / Pi: not available.** `hermes_local` and `pi_local` adapters are
  compiled in, but the image ships neither CLI (`which hermes pi` → nothing),
  and Hermes can't be pip-installed either: the image's Python 3.13 has no
  `pip`/`ensurepip`, so `python3 -m venv` fails. Anything installed into
  `./data` by hand would also be invisible to upgrades. Every role planned for
  Hermes runs on **OpenCode + OpenRouter** instead — which is also the only
  harness Paperclip's OpenRouter connection is compatible with.
- **No local Ollama models for agents**: RAM is too tight (see below).

### AI connections (2026-09-26)

A *connection* is a Paperclip-managed credential an agent binds to
(`runtimeConfig.aiConnection`). They are per company.

| Company | Connection | Type | Used by |
|---|---|---|---|
| both | *My Claude subscription* | Anthropic, subscription (personal, default) | every `claude_local` agent |
| both | **OpenRouter (shared)** | OpenRouter, API key, company-shared, installed company-wide | every `opencode_local` agent |
| — | *(none)* Codex | CLI login (`codex login --device-auth`) | `codex_local` agents |
| — | *(none)* Gemini | CLI login / `GEMINI_API_KEY` — no connection type exists | `gemini_local` agents |

- The OpenRouter connection was created from `OPENROUTER_API_KEY` in `.env`
  (`POST /api/companies/<id>/ai-connections`,
  `{"provider":"openrouter","method":"api_key","ownership":"shared",…}`), then
  installed for the whole company (`PUT /api/tool-connections/<id>/installs`
  with `{"targetType":"company"}`). Without the install a bind fails with
  *"This connection is not permitted for this agent"*.
- OpenRouter is only compatible with `opencode_local`, and only with a model
  written `openrouter/<vendor>/<model>`.
- Cheap models in use (OpenRouter prices, $/M tokens in → out, checked
  2026-09-26): `openrouter/deepseek/deepseek-v3.2` 0.27 → 0.40 (default),
  `openrouter/qwen/qwen3-coder` 0.30 → 1.00 (QA), and
  `openrouter/moonshotai/kimi-k2.5` 0.45 → 2.25 as the step-up option.
  Re-check slugs with `curl -s https://openrouter.ai/api/v1/models | jq` —
  `opencode models openrouter` in the container must list the same slug.

**Priority rule when picking a runtime:** *subscriptions first* (Claude,
ChatGPT/Codex — already paid) → *free tiers* (Gemini) → *OpenRouter* (pay per
token, $3/month cap per agent). Claude Opus only for planning/architecture
(Studio CEO + CTO, Homelab Lead); Sonnet (`claude-sonnet-5`) for the other
Claude roles to save plan usage.

**Switching an agent's harness.** An agent that already carries a Claude
binding can't be moved to a harness with no connection (Gemini, Codex): `PATCH
/api/agents/<id>` re-attaches the old binding and fails with *"Select an AI
connection compatible with the new harness and model"*, and a truthy
non-binding value breaks runs. Moving to OpenCode works in one PATCH (send
`adapterType`, `adapterConfig.model: "openrouter/…"` and the OpenRouter
binding together). For Gemini/Codex, hire a replacement with the same
name/role/manager, copy its AGENTS.md section, then terminate the old agent —
that is how the Studio Researcher moved to Gemini.

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

| Agent | Reports to | Runtime (model) | Budget cap | Status |
|---|---|---|---|---|
| Homelab Lead (CTO / Homelab Lead) | board | Claude Code (Opus 5) | plan limits | active (idle) |
| Security Analyst — reads the weekly report | Lead | Codex | plan limits | **paused** |
| Security Engineer — reviews every PR | Lead | Claude Code (Sonnet 5) | plan limits | **paused** |
| DevOps/Homelab Engineer — opens dotfiles PRs | Lead | Codex + `GH_TOKEN` | plan limits | **paused** |
| Docs & TODO Keeper | Lead | OpenCode → OpenRouter `deepseek-v3.2` + `GH_TOKEN` | $3/month | **paused** |
| Storage & Backup Analyst | Lead | OpenCode → OpenRouter `deepseek-v3.2` | $3/month | **paused** |

The two engineers work **only through PRs** on
`github.com/peciulevicius/.dotfiles`: they have no route to the host, so the
board merges and Džiugas applies merged changes on the Mac mini with Claude
Code. Their AGENTS.md says so, plus "the repo is PUBLIC, never commit a
secret".

#### GitHub access for the Homelab engineers

- `GITHUB_TOKEN_HOMELAB` (fine-grained PAT: this repo only, *Contents* +
  *Pull requests* read/write) was copied from `.env` into a **Paperclip
  secret** *GitHub token (dotfiles PRs)* in the Homelab company, and bound as
  `adapterConfig.env.GH_TOKEN` (`{"type":"secret_ref",…,"version":"latest"}`)
  on **DevOps/Homelab Engineer** and **Docs & TODO Keeper** only.
- Git uses it through gh, never a stored credential:
  `git -c credential.helper= -c credential.helper='!gh auth git-credential' clone|push …`,
  `gh pr create`. Nothing writes the token to a file, remote URL or commit.
  Verified from inside the container 2026-09-26 (`gh api
  repos/peciulevicius/.dotfiles`, `git ls-remote`).
- ⚠️ `env_file: .env` passes **every** `.env` line into the container, so
  after the next recreate the token would also sit in the environment of every
  agent in both companies. The container was deliberately *not* recreated
  after the token was added. Before the next `docker compose up -d`, move the
  `GITHUB_TOKEN_HOMELAB=` line out of `.env` (the Paperclip secret is now the
  copy that matters; keep the original in Vaultwarden).
- Rotate: new PAT → *Company settings → Secrets → GitHub token → new version*
  (bindings use `latest`, nothing else to change).

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

| Agent | Reports to | Runtime (model) | Budget cap | Status |
|---|---|---|---|---|
| CEO | board | Claude Code (Opus 5) | plan limits | active (idle) |
| Product Manager | CEO | Codex | plan limits | active (idle) |
| Researcher | CEO | Gemini CLI (`auto`) | free tier | **paused** until the Gemini login is redone |
| Growth & Content | CEO | Gemini CLI (`auto`) | free tier | **paused** |
| CTO | CEO | Claude Code (Opus 5) | plan limits | **paused** |
| Security Engineer — reviews every PR | CTO | Claude Code (Sonnet 5) | plan limits | **paused** |
| DevOps Engineer | CTO | Codex | plan limits | **paused** |
| Engineering Manager | CTO | Codex | plan limits | **paused** |
| Frontend Developer | Eng Manager | Codex | plan limits | **paused** |
| Backend Developer | Eng Manager | Claude Code (Sonnet 5) | plan limits | **paused** |
| Mobile Developer (Expo/React Native) | Eng Manager | Codex | plan limits | **paused** |
| QA Engineer | Eng Manager | OpenCode → OpenRouter `qwen3-coder` | $3/month | **paused** |
| UI/UX Designer | PM | Claude Code (Sonnet 5) | plan limits | **paused** |
| Technical Writer | PM | OpenCode → OpenRouter `deepseek-v3.2` | $3/month | **paused** |

- Every AGENTS.md ends with a board section (≤12 lines): role, may/may not,
  "work only via tasks; code only as PRs; never commit secrets; repos may be
  PUBLIC; the board merges", and for engineers the stack (TS strict,
  Next.js/SvelteKit, Expo + NativeWind, Supabase + RLS, Zod, Tailwind, pnpm).
  The Security Engineer is the review gate for every PR.
- The Researcher was moved Claude Code → Gemini on 2026-09-26 by **hiring a
  replacement and terminating the original** (see *Switching an agent's
  harness*); its rubric section was copied over. The Gemini login in the
  container is currently unreadable (hostname issue above), so it stays paused
  until `GEMINI_API_KEY` is set or the login is redone.

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
6. **Budgets** (`budgetMonthlyCents`) only cap API-key spend: Paperclip's
   only budget metric is `billed_cents` (hard stop at 100% auto-pauses the
   agent, soft alert at 80%, resets on the 1st, UTC). Every OpenRouter agent
   has a **$3/month** policy (`PATCH /api/agents/<id>/budgets`
   `{"budgetMonthlyCents":300}` — setting the field on a PATCH of the agent
   itself did *not* create the policy). There is no run or token cap for
   subscription agents; the per-run limits used instead are
   `maxTurnsPerRun: 100` (Claude Code) and `timeoutSec: 1800` (all new
   agents). Watch **Audit → Costs** and the plans' own limits.

### Un-pausing a department (phased rollout)

Everything new is paused with timer heartbeats off, so the org costs nothing
until you start a phase. To start one, resume the agents for that phase only —
UI: agent → **Resume**, or `POST /api/agents/<id>/resume` — then assign a task
(backlog → Todo). Pause them again when the phase is done. Suggested phases:

1. **Studio planning:** CEO + Product Manager (already active) + Researcher
   (after the Gemini login) → STU-2.
2. **Studio build:** CTO → Engineering Manager → Frontend/Backend/Mobile, with
   **Security Engineer and QA always resumed together with any developer**
   (they are the PR gate). DevOps Engineer only when CI/deploy work exists.
3. **Studio launch:** UI/UX Designer, Technical Writer, Growth & Content.
4. **Homelab PRs:** DevOps/Homelab Engineer + Homelab Security Engineer (+
   Docs & TODO Keeper for doc sweeps).

Keep to one working agent at a time on this host (see *Memory*).

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
  # codex_local, gemini_local or opencode_local (opencode also needs the
  # OpenRouter binding in runtimeConfig.aiConnection, see AI connections):
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
