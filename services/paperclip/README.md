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
| RAM | ~0.8GB after start, ~1.2GB idle once both companies are loaded; capped at 3GB (`mem_limit`: 1.5GB → 2GB → 3GB, all 2026-09-26) |
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
- **Gemini CLI: in the image, deliberately unused (dropped 2026-09-26).** No
  agent runs on `gemini_local`. Reasons: Google ended personal-account
  sign-in for the CLI, the only other paths are an API key or Vertex AI
  (Vertex needs a GCP project with billing), there is **no Gemini connection
  type** in Paperclip (connections exist only for Anthropic, OpenAI,
  OpenRouter and xAI), and the CLI's stored key kept corrupting: it encrypts
  the login with a key derived from **hostname + username**, and the
  container's default hostname (its ID) changes on every recreate →
  *"Corrupted credentials file"*. The compose file still pins
  `hostname: paperclip`, which fixes that last part if Gemini is ever wanted
  again. Gemini *models* are still used — through OpenRouter (see *AI
  connections*): the former Gemini agents run `openrouter/google/gemini-3.5-flash-lite`.
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
| — | *(none)* Gemini | no connection type exists | nobody — Gemini CLI is unused (see above) |

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
  `openrouter/qwen/qwen3-coder` 0.30 → 1.00 (QA),
  `openrouter/google/gemini-3.5-flash-lite` 0.30 → 2.50 (Studio Researcher +
  Growth & Content — the newest Gemini Flash under $0.50/M input; full
  `gemini-3.8-flash` is 0.75 → 3.75), and
  `openrouter/moonshotai/kimi-k2.5` 0.45 → 2.25 as the step-up option.
  Re-check slugs with `curl -s https://openrouter.ai/api/v1/models | jq` —
  `opencode models openrouter` in the container must list the same slug.

**Priority rule when picking a runtime:** *subscriptions first* (Claude,
ChatGPT/Codex — already paid) → *OpenRouter* (pay per token, $3/month cap per
agent). There is no free tier left in use (Gemini CLI dropped).
Claude Opus only for planning/architecture
(Studio CEO + CTO, Homelab Lead); Sonnet (`claude-sonnet-5`) for the other
Claude roles to save plan usage.

**Switching an agent's harness.** An agent that already carries a Claude
binding can't be moved to a harness with no connection (Gemini, Codex): `PATCH
/api/agents/<id>` re-attaches the old binding and fails with *"Select an AI
connection compatible with the new harness and model"*, and a truthy
non-binding value breaks runs. Moving to OpenCode works in one PATCH (send
`adapterType`, `adapterConfig.model: "openrouter/…"` and the OpenRouter
binding together). For Codex, hire a replacement with the same
name/role/manager, copy its AGENTS.md section, then terminate the old agent —
that is how the Studio Researcher moved Claude → Gemini. The later move
Gemini → OpenCode (Researcher, Growth & Content, 2026-09-26) was a plain PATCH:
an agent with no binding has nothing for the API to restore.

**Changing a manager** is a plain `PATCH /api/agents/<id>`
`{"reportsTo":"<managerId>"}` — used for the department restructure.

### ⚠️ Memory while agents run

With two companies loaded the server idles at ~1.2GB anon RSS. At the old
1.5GB cap `memory.events` showed the limit hit 1500+ times before any agent
had run, and each Claude Code / Codex run adds a CLI process (~300–500MB) — a
guaranteed exit 137. Raised to **2GB** on 2026-09-26, allowed by the rule
*raise only when host `memory_pressure` free ≥ 30%* (it was 37%; swap
7.4–7.5 of 8GB, unchanged). Raised again to **3GB** the same evening: at 2GB `memory.events` `max` had
reached 12,687 with no agent running. Paid for by making six rarely used
services on-demand (~2.2 GiB freed in the Docker VM — see
`docs/HOME_SERVER_REFERENCE.md` → *Memory budget and on-demand services*).
Not 3.5GB: host free stayed at 33% and swap didn't shrink, because RAM freed
inside the VM isn't returned to macOS. Keep to **one agent working at a time**; if runs
die with exit 137, check `memory_pressure` and `sysctl vm.swapusage` before
raising again. Check the container's own pressure with
`docker exec paperclip cat /sys/fs/cgroup/memory.events` (`max` counts hits).

## Companies (configured 2026-09-26)

Two companies configured ("organizations" in the UI), a third (**Coach**)
drafted but not yet created — see its section below, it needs an interactive
board login this setup didn't have. All have **Require board approval for new
hires** on, and **every agent has timer heartbeats off**
(`runtimeConfig.heartbeat.enabled: false`, `wakeOnDemand: true`), so an agent
wakes only when a task is assigned to it, it is @mentioned, or a routine
fires.

### Homelab — weekly health & security reporting

Mission: *Weekly health and security reporting for Džiugas's Mac mini homelab.
Read reports, spot problems, recommend next actions as decisions. Never change
servers — changes are done by Džiugas with Claude Code.*

Org chart, grouped into departments with `reportsTo` (restructured
2026-09-26). Budget: *plan* = subscription limits, *$3* = $3/month hard-stop
OpenRouter budget. Status as of 2026-09-26.

```
Homelab Lead
├── Security:        Security Engineer → Security Analyst
├── Infrastructure:  DevOps/Homelab Engineer → Network Engineer, SRE / Monitoring, Storage & Backup Analyst
├── Knowledge:       Docs & TODO Keeper, Privacy & De-Google Advisor
└── Web:             Web Engineer (personal site)
```

| Department | Agent | Runtime / model | Reports to | Budget | Status |
|---|---|---|---|---|---|
| Leadership | Homelab Lead (CTO / Homelab Lead) | Claude Code, Opus 5 | board | plan | active (idle) |
| Security | Security Engineer — reviews every PR | Claude Code, Sonnet 5 | Lead | plan | paused |
| Security | Security Analyst — reads the weekly report | Codex | Security Engineer | plan | paused |
| Infrastructure | DevOps/Homelab Engineer — opens dotfiles PRs | Codex + `GH_TOKEN` | Lead | plan | paused |
| Infrastructure | Network Engineer — Tailscale, Pi-hole, Cloudflare tunnel/DNS | Codex | DevOps/Homelab Eng | plan | paused |
| Infrastructure | SRE / Monitoring — Uptime Kuma, Glance, alert tuning | OpenCode, `deepseek-v3.2` | DevOps/Homelab Eng | $3 | paused |
| Infrastructure | Storage & Backup Analyst | OpenCode, `deepseek-v3.2` | DevOps/Homelab Eng | $3 | paused |
| Knowledge | Docs & TODO Keeper | OpenCode, `deepseek-v3.2` + `GH_TOKEN` | Lead | $3 | paused |
| Knowledge | Privacy & De-Google Advisor — tracks `docs/guides/DEGOOGLE*.md` | OpenCode, `deepseek-v3.2` | Lead | $3 | paused |
| Web | Web Engineer — peciulevicius.com (perf, content, a11y) | Claude Code, Sonnet 5 | Lead | plan | paused |

Only **DevOps/Homelab Engineer** and **Docs & TODO Keeper** hold the
dotfiles `GH_TOKEN`. Network Engineer and SRE hand PR-ready diffs to the
DevOps/Homelab Engineer (their manager) rather than getting a copy of the
token — fewer holders, same result. The Privacy Advisor is advice-only; its
AGENTS.md repeats the standing De-Google decisions (Purelymail, no self-hosted
mail, never delete the Google account, Authenticator first, no Pixel, no
Proton/Tuta) so it doesn't relitigate them.

#### GitHub token for the Web Engineer (not done — 👤)

The Web Engineer targets `github.com/peciulevicius/peciulevicius.com`, but the
existing token only covers the dotfiles repo, so it **cannot open PRs yet**;
its AGENTS.md tells it to deliver changes as a patch in a task document until
then. To enable PRs:

1. GitHub → *Settings → Developer settings → Fine-grained tokens → Generate*:
   repository access **only `peciulevicius/peciulevicius.com`**, permissions
   *Contents* **read/write** + *Pull requests* **read/write**, an expiry.
2. Paperclip, Homelab company → *Company settings → Secrets → New secret*
   (e.g. *GitHub token (site PRs)*), paste the token. Keep a copy in
   Vaultwarden, never in `.env` (`env_file` would expose it to every agent).
3. Web Engineer → *Configuration → Environment* → `GH_TOKEN` = that secret
   (`latest`), i.e. the same `secret_ref` binding the DevOps/Homelab Engineer
   uses. Git auth then works exactly as in *GitHub access* below.

The DevOps/Homelab and Docs engineers work **only through PRs** on
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

Org chart, grouped into departments with `reportsTo` (2026-09-26). Every
agent was **created paused**; the board then resumed the whole Studio roster
in the UI on 2026-09-26 (16:13). Resumed ≠ working: heartbeats are off, so an
idle agent only wakes for an assigned task, an @mention or a routine.

```
CEO
├── Product:      Product Manager → UI/UX Designer, Technical Writer
├── Engineering:  CTO → Engineering Manager → Frontend, Backend, Mobile, QA
│                 CTO → DevOps Engineer, Security Engineer
├── Research:     Researcher
└── Marketing:    Head of Marketing (CMO) → Copywriter, Social Media Manager,
                  Community & Launch, SEO Specialist, Growth & Content
```

| Department | Agent | Runtime / model | Reports to | Budget | Status |
|---|---|---|---|---|---|
| Leadership | CEO | Claude Code, Opus 5 | board | plan | active |
| Product | Product Manager | Codex | CEO | plan | active |
| Product | UI/UX Designer | Claude Code, Sonnet 5 | PM | plan | resumed by board |
| Product | Technical Writer | OpenCode, `deepseek-v3.2` | PM | $3 | resumed by board |
| Engineering | CTO | Claude Code, Opus 5 | CEO | plan | resumed by board |
| Engineering | Engineering Manager | Codex | CTO | plan | resumed by board |
| Engineering | Frontend Developer | Codex | Eng Manager | plan | resumed by board |
| Engineering | Backend Developer | Claude Code, Sonnet 5 | Eng Manager | plan | resumed by board |
| Engineering | Mobile Developer (Expo/React Native) | Codex | Eng Manager | plan | resumed by board |
| Engineering | QA Engineer | OpenCode, `qwen3-coder` | Eng Manager | $3 | resumed by board |
| Engineering | DevOps Engineer | Codex | CTO | plan | resumed by board |
| Engineering | Security Engineer — reviews every PR | Claude Code, Sonnet 5 | CTO | plan | resumed by board |
| Research | Researcher | OpenCode, `gemini-3.5-flash-lite` | CEO | $3 | resumed by board |
| Marketing | Head of Marketing (CMO) | Claude Code, Sonnet 5 | CEO | plan | resumed by board |
| Marketing | Copywriter | Claude Code, Sonnet 5 | CMO | plan | resumed by board |
| Marketing | Social Media Manager | OpenCode, `deepseek-v3.2` | CMO | $3 | resumed by board |
| Marketing | Community & Launch — Reddit/HN/PH/Indie Hackers drafts | OpenCode, `deepseek-v3.2` | CMO | $3 | resumed by board |
| Marketing | SEO Specialist | OpenCode, `deepseek-v3.2` | CMO | $3 | resumed by board |
| Marketing | Growth & Content | OpenCode, `gemini-3.5-flash-lite` | CMO | $3 | resumed by board |

#### Marketing rules (in every marketing agent's AGENTS.md)

> Draft only. Never post, sign up, or contact anyone. The board posts from the
> studio's own accounts. Follow each platform's self-promotion rules; no fake
> reviews, no vote manipulation, no sockpuppets. Keep the brand faceless —
> never mention the founder's real name or peciulevicius.com.

**Why:** the studio is anonymous by design and has no accounts of its own for
agents to use; an agent that posts or signs up would either leak the
founder's identity or break a platform's terms (Reddit, HN and Product Hunt
all ban vote rings and sockpuppets, and many subreddits ban self-promotion
outright). So agents produce drafts as task documents and the board does the
posting. **Community & Launch** must read and quote each community's current
rules before drafting and say when a community forbids self-promotion.
Growth & Content moved from CEO to CMO (and role `cmo` → `general`, so the
CMO is the only `cmo`).

- Every AGENTS.md ends with a board section (≤12 lines): role, may/may not,
  "work only via tasks; code only as PRs; never commit secrets; repos may be
  PUBLIC; the board merges", and for engineers the stack (TS strict,
  Next.js/SvelteKit, Expo + NativeWind, Supabase + RLS, Zod, Tailwind, pnpm).
  The Security Engineer is the review gate for every PR.
- The Researcher was moved Claude Code → Gemini on 2026-09-26 by **hiring a
  replacement and terminating the original** (see *Switching an agent's
  harness*); its rubric section was copied over. Later the same day it and
  Growth & Content moved **Gemini CLI → OpenCode on OpenRouter**
  (`gemini-3.5-flash-lite`, $3/month each) when Gemini CLI was dropped — see
  *Codex / Gemini / OpenCode*.

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

### Coach — adaptive triathlon coaching (live, 2026-09-27)

Mission: *Adaptive triathlon coaching for IRONMAN 70.3 Luxembourg (11 Jul
2027). Protect consistency and health; adjust, never pile on.*

**Company, agent, MCP connections, secret and routine are all created.** Board
approval for new hires is on. Coach: `claude_local`, `claude-sonnet-5`,
heartbeat off + `wakeOnDemand`, `canCreateAgents: false`, 30-minute timeout.
AGENTS.md addendum applied (content also kept at
`services/paperclip/coach-agents-addendum.md` in this repo — edit there and
re-push, don't hand-edit the copy inside Paperclip).

**MCP connections — the "UI wizard only" claim below was wrong.** The guided
URL flow's own backend is a real, callable REST endpoint:
`POST /api/companies/<id>/tools/apps/connect` with `{"link":"<mcp url>",
"name":"…","authMode":"none"}` — no browser needed for a no-auth server. It
returns a `draft` connection plus the discovered tool catalog. Finish it with
`POST /api/companies/<id>/tools/apps/<connectionId>/finish` — pass
`enabledCatalogEntryIds`/`reviewedCatalogEntryIds` covering only whatever the
connection *currently* reports as quarantined (empty arrays if nothing is,
which was the case for both TP and Strava — sending the full catalog when
nothing is quarantined fails with *"Action review decisions must cover every
currently quarantined action exactly once"*) and
`"access":{"agentIds":["<coachAgentId>"]}` to scope it to Coach only. Finishing
creates a tool-access profile with `defaultAction: "deny"` and **no entries** —
you still have to grant tools explicitly:
`POST /api/tool-profiles/<profileId>/entries` with
`{"selectorType":"connection","effect":"include","connectionId":"<id>"}` opens
the whole connection in one call. Did this for both
`http://host.docker.internal:8092/mcp` (TrainingPeaks) and
`http://host.docker.internal:8093/mcp` (Strava).

**One step is genuinely UI/human-only, by design.** The first time an agent's
run actually calls a tool on a fresh connection, Paperclip raises a
`connection_intent` interaction on that run's issue with
`resolverPolicy: "human_only"` and `addresseeUserId` set to your account — a
"Connect TrainingPeaks" / "Connect Strava" consent card. This is a governed
action (`effectiveResolverPolicySource: "governed_action"`) and correctly
cannot be approved by the board API session or by an agent on your behalf —
only you, in the UI (**Paperclip → Coach → the issue → the connection card →
Approve**), or `POST /api/issues/<issueId>/interactions/<id>/accept` run
*by you*. Read-only functional testing doesn't hit this gate:
`POST /api/tool-connections/<connectionId>/test-calls` with
`{"agentId":"<coachAgentId>","toolName":"tp_auth_status","parameters":{}}`
(and `query_activities` for Strava) both returned real data — TP auth valid,
Strava activities listed — confirming the plumbing end to end. The Daily
check-in's first real run stopped at exactly this gate; once you approve the
two cards it will complete on its own next firing (or **Run now**).

**Secrets.** `COACH_DISCORD_WEBHOOK` (see *Phone push* below), bound to Coach
only via `adapterConfig.env.COACH_DISCORD_WEBHOOK` as a `secret_ref`
(`version: "latest"`). ⚠️ An earlier pass created `ntfy-publish-token` /
`ntfy-topic` Paperclip secrets before the board decided ntfy's iOS app
wouldn't take token-only login and pushing is one-way anyway — those were
deleted and Coach's env binding cleared before Discord was wired in. The
standalone `ntfy` service itself was removed 2026-09-28 (unused).

**Phone push (Discord, not ntfy).** Coach posts to the `#ai-training-coach` Discord channel
via webhook — see *Phone push (Discord)* in
`coach-agents-addendum.md`/the live AGENTS.md for the exact call. The webhook
URL lives in `~/.config/homelab/coach-discord.env`
(`COACH_DISCORD_WEBHOOK`, chmod 600) and as the `COACH_DISCORD_WEBHOOK`
Paperclip secret above — never print either copy.

**Routine "Daily check-in"**, 06:30 Europe/Vilnius, assigned to Coach, project
"Coaching", `concurrencyPolicy: skip_if_active`, `catchUpPolicy: skip_missed`.
Fire it on demand with `POST /api/routines/<routineId>/run -d '{"source":
"manual"}'` (the `.../triggers/<id>/fire` path some versions expose is not
required — `run` alone is enough and is what this setup used).

**Dietitian (added 2026-09-27) — Coach is now a two-agent team.** A second
`claude_local` Sonnet agent, **Dietitian** (reports to Coach, heartbeat off,
own Discord webhook secret `DIETITIAN_DISCORD_WEBHOOK` → `#ai-training-dietitian`, copy in `~/.config/homelab/dietitian-discord.env`), owns food, body weight and
composition (Garmin Index S2 → TrainingPeaks), weight periodisation, training/
race fuelling, meal prep and Barbora shopping lists; Coach owns training.
Instructions: `dietitian-agents-addendum.md` (Coach's: `coach-agents-addendum.md`).

**Studio's Claude/Codex handoff (2026-09-29).** CTO (Claude) and Engineering
Manager (Codex) got an explicit protocol appended to their AGENTS.md — CTO
designs + reviews, Engineering Manager's Codex team (Frontend, Mobile, DevOps)
executes against a spec and reports back on the issue rather than closing it.
Tracked as `cto-claude-codex-handoff-addendum.md` and
`engineering-manager-claude-codex-handoff-addendum.md`. Both harnesses already
share `/ai-memory` and this company's skills (same container, same mount —
nothing harness-specific needed).
Memory split inside `/ai-memory/training/` (its own `/training` mount until
2026-09-29, folded into the shared `/ai-memory` tree — see below): shared
files at the root (`athlete_profile.md`, `race_calendar.md`, `preferences.md`,
`conversations/`, `imports/`); Coach writes `plans/`, `coaching_notes.md`,
`progress_reviews/`; Dietitian writes `nutrition/` (incl. `today.md`, which
the daily check-in quotes). They hand work to each other as Paperclip tasks.
Fuelling numbers are *current practice*, not rules — both agents may propose
changes.

TrainingPeaks access for the Dietitian is a separate tool profile,
**"TrainingPeaks (read-only)"** (`profileKey: tp-readonly`), created with
`POST /api/companies/<id>/tools/profiles` (`profileKey` is required) and one
`catalog_entry` include per `tp_get_*`/`tp_list_*`/`tp_search_*`/`tp_auth_*`/
`tp_analy*` tool (39), then bound to the agent. A test write call as the
Dietitian does not execute (it hits the signed-approval path, which is
unconfigured on this instance).

**Shared memory `/ai-memory` (2026-09-29).** `~/ai-memory` is mounted
read-write at `/ai-memory` (outside `/paperclip`, same chown reason as
`/training`). The Coach, Dietitian, Homelab Lead and Studio CEO got a
"Shared memory — /ai-memory" section in their AGENTS.md (read the README
first; write durable facts to `inbox/<date>-<agent>.md`; never delete others'
notes; no secrets). Odysseus sees the same folder. Details:
`docs/HOME_SERVER_REFERENCE.md` → *Shared AI memory*.

**Claude.ai memory import.** The athlete's triathlon and food Claude.ai
projects (memory, docs, chats) were copied from the account export into
`~/ai-memory/training/imports/claude-ai-2026-09-27/` (path moved 2026-09-29
along with the rest of `~/.training`); nothing unrelated to training or
food. TrainingPeaks stays the source of truth for FTP, thresholds, zones and
weight; old chat numbers are history only.

**Talking to Coach from the phone:** open Paperclip (Tailscale,
`100.81.171.49:3100`), Coach company → create a task ("tired today", "push
Thursday's run to Friday", "away 2–5 Oct") — task assignment wakes it even
though its heartbeat is off. Approve or reject the decision it raises under
**Approvals**/the issue's connection cards; it only touches TrainingPeaks
after that.

## Skills (Studio, 2026-09-29)

Eleven vetted third-party skills are installed in the **Studio** company's
skill library and attached to the agents that build things. The canonical,
reviewed copies live in `config/claude/skills/<name>/` (each with a
`SOURCE.md`: upstream repo, pinned commit, license, review notes) and are the
same ones Claude Code uses — details in `config/claude/README.md` → *Skills*.

| Agent | Skills added (plus the default `paperclip` skill it already had) |
|---|---|
| UI/UX Designer | `frontend-design`, `design-taste-frontend`, `web-design-guidelines`, `design-systems-reference`, `image-to-code` |
| Frontend Developer (Codex) | `frontend-design`, `web-design-guidelines`, `design-systems-reference`, `vercel-react-best-practices`, `image-to-code` |
| Mobile Developer (Codex) | `frontend-design`, `design-systems-reference`, `vercel-react-native-skills` |
| CTO | `frontend-design`, `web-design-guidelines`, `vercel-react-best-practices`, `differential-review`, `supply-chain-risk-auditor` |
| Security Engineer | `differential-review`, `supply-chain-risk-auditor` |
| QA Engineer (OpenCode) | `playwright-cli`, `web-design-guidelines`, `webapp-testing` |

**How they were installed (API, no UI needed).** Paperclip's GitHub import
only takes unmodified upstream folders pinned to a commit, and several of our
copies carry reviewed local edits (the pinned guidelines, the pinned
Playwright install line, the Trail of Bits agent note). So each skill was
created as a company-managed skill from the local folder:
`POST /api/companies/<id>/skills` with `{name, slug, description, markdown:
<SKILL.md>, sharingScope: "company"}`, then one
`PATCH /api/companies/<id>/skills/<skillId>/files` `{path, content}` per
supporting file. The first eight plus `image-to-code` classify as trust level **`assets`** (no
executable scripts); `webapp-testing` and `supply-chain-risk-auditor` (added
later on 2026-09-29, along with all 74 design systems in
`design-systems-reference`) are **`scripts_executables`** — reviewed Python
(a localhost dev-server wrapper; a stdlib registry collector that never runs
package code). To check attachments, read `desiredSkills` in
`GET /api/agents/<id>/skills` — its `entries` list the whole company library. Attaching them used
`POST /api/agents/<agentId>/skills/sync` with `{mode: "add", desiredSkills:
["paperclipai/paperclip/paperclip", "company/<companyId>/<slug>", …]}` —
listing the default `paperclip` skill explicitly so it can't be dropped. This
only edits agent config (recorded as a `skill-sync` config revision); it
starts no run, and paused agents stay paused. Check with
`GET /api/agents/<agentId>/skills`.

**Updating a skill:** re-vendor and review in `config/claude/skills/`, then
re-upload the changed files with the same `PATCH …/files` call (the library
keeps version history: `GET …/skills/<skillId>/versions`).

- `playwright-cli` needs the `playwright-cli` binary; it is **not** installed in
  the Paperclip image. In a project with Playwright, `npx playwright cli` works;
  otherwise the QA agent must ask before installing anything.
- OpenCode agents share the container's `~/.claude/skills` (Paperclip warns
  about this); the Claude and Codex agents get an ephemeral per-run copy.

## Usage-limit fallback (2026-09-29)

When the Claude Pro subscription hits its limit, `claude_local` runs fail with
*"ACP agent reported a terminal limit failure"* (`errorCode acpx_turn_failed`,
no reset time anywhere in the run, log or events). Paperclip has no built-in
fallback, so `scripts/utils/paperclip-fallback.sh` (cron, every 5 min) does it:

- **Detects** failed runs whose error mentions a *limit* (not "access failure")
  in the last 15 min, across all companies.
- **Switches** (with `--switch`, or automatically when `AUTO_SWITCH=1`) every
  non-paused `claude_local` agent to `opencode_local` +
  `openrouter/deepseek/deepseek-v3.2` on the company's shared OpenRouter
  connection, saving each agent's exact config in
  `~/.config/homelab/paperclip-fallback/state.json` (chmod 600), then
  @mentions the agent on the interrupted issue so the work resumes. Discord gets
  a "⚡ Claude limit hit" post.
- **Checks recovery** (hourly probe, or `--restore`): a tiny `claude -p` Haiku
  request inside the container. The script no longer PATCHes the same agent
  back to Claude because that path is known to fail; it reports that a fresh
  hire is needed.
- **Reconciles manual rehires:** `--reconcile` is a dry-run by default. When a
  saved old ID is paused/terminated and explicitly named retired, it requires
  exactly one live agent with the saved name, adapter and model. `--reconcile
  --apply` then adds the saved skills, remaps active agents' `reportsTo` links
  and open issue assignments, and clears that state record only if every API
  write succeeds. It never renames or terminates the retired agent. Check
  third-party references such as the Discord bridge separately.
- `--status`, `--dry-run`.

**Why OpenRouter, not Anthropic API credit:** Paperclip strips `ANTHROPIC_*` /
`CLAUDE_CODE_OAUTH_TOKEN` from an agent's env whenever a managed AI connection
is bound (`stripAiAuthBindings`), and there is no Anthropic API-key connection,
so "same Claude, pay per token" isn't available. OpenRouter is also cheaper: a
typical run (~100k input / ~8k output tokens) is ≈ $0.40 on Sonnet via API vs
≈ $0.03 on deepseek-v3.2 — roughly 13× less. Quality is lower; it's a stop-gap.
The switch uses the connection's `grantId` (listed on
`GET /api/companies/<id>/ai-connections`), which the PATCH requires.

**⚠️ The restore problem — real, but per-agent, not company-wide.** Switching
*to* OpenRouter works (tested on Copywriter, no run started). Switching *back*
to the subscription can fail on a specific agent: Paperclip validates the new
binding and refuses the PATCH with *"The selected AI connection failed
validation in this agent's environment"*, while
`POST /api/companies/<id>/adapters/claude_local/test-environment`
(company-wide) reports `"status": "pass"` at the very same time — so this
is **not** the subscription or the login; it's specific to an agent that has
run under a different harness. `config-revisions/…/rollback` doesn't help
either: switching harness doesn't create a revision to roll back to, so it
returns 200 and changes nothing.

**The actual fix, confirmed 2026-09-29: pause + rename the stuck agent, hire a
fresh one with the same name, role, manager and `AGENTS.md`.** A PATCH back
onto the *same* agent record is what fails; a brand-new agent record on
`claude_local` from the start works immediately (that's exactly how Copywriter
was fixed — see below). Re-testing or reconnecting the subscription in the UI
does **not** fix this, since the connection was never the problem.

**⚠️ Incident, same day: `AUTO_SWITCH=1` was turned on, a real limit hit fired
it, and the restore bug hit *every* switched agent, not just one.** 10 agents
across all 3 companies (Homelab Lead; Coach, Dietitian; CEO, CTO, Head of
Marketing, Security Engineer, Backend Developer, Copywriter, UI/UX Designer)
got switched and none restored automatically. Fixing it by hand surfaced
three knock-on problems beyond the PATCH failure itself. The old script did
not handle these; `--reconcile` now repairs them for already-hired exact
replacements:
1. **Manager references break.** CEO, CTO and Coach are managers — giving
   them a new agent ID orphans every direct report's `reportsTo` (and
   *their* reports, transitively). Fix order matters: rehire root-first
   (no manager, or manager not itself being replaced), then children,
   PATCHing `reportsTo` to each new ID as you go — including agents that
   were *not* switched themselves (e.g. Engineering Manager, DevOps, the
   whole marketing team all pointed at the old CEO/CTO/Head of Marketing).
2. **Company skills are lost.** `adapterConfig.paperclipSkillSync` lives on
   the agent record; a rehire starts with none. `--reconcile` restores the
   saved keys with `POST /api/agents/<id>/skills/sync` in `add` mode, so other
   assignments are preserved.
3. **Anything hardcoding the old agent ID goes stale.** The Discord bridge's
   `CHANNEL_MAP` (`~/services/discord-bridge/.env`) pins Coach/Dietitian by
   ID — update and `docker compose up -d` there. `--reconcile` reassigns open
   Paperclip issues from the old ID to the matching replacement; external
   references such as the Discord map still need a separate update.

The replacements were hired manually. A live audit later found five Homelab
agents still reporting to the retired Homelab Lead ID, and the local fallback
state still listed all ten old IDs. `--reconcile` now repairs saved skills,
reporting links, and open issue assignments for already-hired exact
replacements. It leaves unrelated agents and retired records alone.

**So `AUTO_SWITCH` is off again**, same day it was turned on. Switching
*away* is safe to automate; restore is not, until it does a real
pause+rehire with the three remaps above instead of a bare PATCH — that's
follow-up work, not done yet. Until then: a limit hit only **notifies**
(`⚡ Claude limit hit`), and you either wait for the subscription to reset or
run `--switch` by hand. When the subscription is back, use `--reconcile` to
preview any already-hired replacements, then `--reconcile --apply` to repair
their links. If no replacement exists, hire a fresh Claude agent through the
board approval flow; `--restore` deliberately refuses the broken same-agent
PATCH. Auto-switch remains off until a complete rehire-and-approval workflow
can safely handle future incidents.

**Coach company:** an `OpenRouter (shared)` connection was added 2026-09-29
(`POST /api/companies/<id>/ai-connections`, same key), so Coach/Dietitian are
covered too. ⚠️ Two identical connections exist there from a retry — harmless
(same key twice), tidy up in Company settings → AI connections when
convenient; no `DELETE` route was found for it via the API.

**Copywriter (Studio)** was the switch test agent (2026-09-29) and hit the
restore bug. Fixed the same day: the stuck one is paused and renamed
*"Copywriter (retired 2026-09-29, harness-switch bug)"*; a fresh `Copywriter`
was hired (`claude_local`, `claude-sonnet-5`, same manager, same `AGENTS.md`)
and approved. Confirmed idle, no `aiConnection` override needed (falls back to
the company default, same as every other Sonnet agent in Studio).
It's idle with no tasks. Restore it in the UI (agent → Configuration → Claude,
*My Claude subscription*, model `claude-sonnet-5`) once the validation passes.

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

1. **Studio planning:** CEO + Product Manager + Researcher → STU-2.
2. **Studio build:** CTO → Engineering Manager → Frontend/Backend/Mobile, with
   **Security Engineer and QA always resumed together with any developer**
   (they are the PR gate). DevOps Engineer only when CI/deploy work exists.
3. **Studio launch:** UI/UX Designer, Technical Writer, then the Marketing
   department (Head of Marketing first; it delegates to Copywriter, Social,
   Community & Launch, SEO, Growth & Content).
4. **Homelab PRs:** DevOps/Homelab Engineer + Homelab Security Engineer (+
   Docs & TODO Keeper for doc sweeps).
5. **Homelab departments as needed:** Infrastructure (Network Engineer, SRE /
   Monitoring, Storage & Backup — under DevOps/Homelab Engineer), Knowledge
   (Privacy & De-Google Advisor), Web (Web Engineer — after its GitHub token).

Note: on 2026-09-26 the board resumed the whole Studio at once. That costs
nothing while no tasks are assigned, but a CEO fan-out (e.g. the standup
routine) can now wake several agents in parallel — see *Memory* before
assigning broad work.

Keep to one working agent at a time on this host (see *Memory*).

## Adding or changing agents

The approval wall is on in both companies, so a direct create returns
`409: Direct agent creation requires board approval`. Either:

- **Ask the CEO/Lead in a task** ("hire a … on Codex") — it files a hire
  request with its `paperclip-create-agent` skill; approve it under
  **Approvals**. Or
- **API, as the board.** Sign in once to get a session cookie (keep the
  password out of shell history and output):

  ⚠️ The admin password is **no longer in `.env`** (moved out 2026-09-26) —
  read it from `~/.config/homelab/paperclip-admin.env`
  (`PAPERCLIP_ADMIN_PASSWORD`, chmod 600, kept permanently outside the repo)
  into a shell variable, never print it. Vaultwarden holds a backup copy under
  the same name. Cookie jar goes in a scratch dir you control (e.g.
  `$CLAUDE_JOB_DIR/tmp` for an agent run, `/tmp` for a human), and delete it
  when done:

  ```bash
  PW=$(grep '^PAPERCLIP_ADMIN_PASSWORD=' ~/.config/homelab/paperclip-admin.env | cut -d= -f2-)
  CJ=/tmp/pc.cj   # or $CLAUDE_JOB_DIR/tmp/pc.cj for an agent run
  jq -n --arg e dziugas@peciulevicius.com --arg p "$PW" '{email:$e,password:$p}' |
    curl -s -c "$CJ" -H 'Content-Type: application/json' \
      -H 'Origin: http://127.0.0.1:3100' --data @- \
      http://127.0.0.1:3100/api/auth/sign-in/email -o /dev/null -w '%{http_code}\n'
  unset PW
  pc() { curl -s -b "$CJ" -H 'Origin: http://127.0.0.1:3100' -H 'Content-Type: application/json' "$@"; }
  pc http://127.0.0.1:3100/api/companies | jq '.[]|{id,name}'
  # hire request (creates a pending agent + approval); adapterType can also be
  # codex_local or opencode_local (opencode also needs the
  # OpenRouter binding in runtimeConfig.aiConnection, see AI connections):
  pc -X POST http://127.0.0.1:3100/api/companies/<companyId>/agent-hires -d '{
    "name":"…","role":"researcher","reportsTo":"<managerId>",
    "adapterType":"claude_local",
    "runtimeConfig":{"heartbeat":{"enabled":false,"wakeOnDemand":true}},
    "permissions":{"canCreateAgents":false}}'
  pc -X POST http://127.0.0.1:3100/api/approvals/<approvalId>/approve -d '{}'
  pc -X POST http://127.0.0.1:3100/api/agents/<agentId>/pause
  # append to AGENTS.md: GET then PUT /api/agents/<id>/instructions-bundle/file {path,content}
  # sign out, then drop the cookie jar:
  pc -X POST http://127.0.0.1:3100/api/auth/sign-out -d '{}' >/dev/null
  rm "$CJ"
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
