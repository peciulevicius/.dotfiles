# Claude Code Complete Guide

Everything about the Claude Code setup in this dotfiles repo — the 6 things, how to set up, how to update, and how to start a new project.

## Table of Contents

- [The 6 Things](#the-6-things)
- [Setup & Update](#setup--update)
- [New Project Setup](#new-project-setup)
- [The 6 Things In Detail](#the-6-things-in-detail)
  - [1. Global CLAUDE.md](#1-global-claudemd)
  - [2. Rules](#2-rules)
  - [3. Skills](#3-skills)
  - [4. Agents](#4-agents)
  - [5. Settings](#5-settings)
  - [6. Commands](#6-commands)
- [Hooks](#hooks)
- [Status Line](#status-line)
- [Extending the Setup](#extending-the-setup)
- [Reference](#reference)

---

## The 6 Things

Everything Claude Code uses lives in `~/.claude/`. All 6 are managed from this dotfiles repo and symlinked automatically.

| # | Path | What it is | Status |
|---|------|------------|--------|
| 1 | `~/.claude/CLAUDE.md` | Global instructions loaded every session | ✅ |
| 2 | `~/.claude/rules/` | Detailed guidelines split by topic | ✅ 10 files |
| 3 | `~/.claude/skills/` | Auto-triggered or slash-invoked skill packs | ✅ 23 skills |
| 4 | `~/.claude/agents/` | Specialist subagents for delegation | ✅ 19 agents |
| 5 | `~/.claude/settings.json` | Permissions, statusline, hooks | ✅ |
| 6 | `~/.claude/commands/` | Manual slash commands (`/pr`, `/debug`, etc.) | ✅ 8 commands |

All files live in `config/claude/` in this repo and are symlinked to `~/.claude/` by `setup-claude.sh`.

---

## Setup & Update

### macOS / Linux — new machine

```bash
# 1. Clone dotfiles
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 2. Install tools (Homebrew, zsh, CLI tools, etc.)
./install.sh

# 3. Set up Claude Code — shows an interactive menu
./scripts/setup/setup-claude.sh
```

Running `setup-claude.sh` with no args shows a **numbered menu**:

```
What do you want to do?

  1) First-time setup       — full install, prompts for settings
  2) Update / resync        — sync agents, skills, rules, commands
  3) Statusline only        — just configure the statusline
  4) Sync agents → dotfiles — pull live agents back into repo
  q) Quit
```

Pick **1** on a new machine.

### Windows (PowerShell) — new machine

```powershell
# One-time: allow scripts to run
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Clone and set up
git clone https://github.com/peciulevicius/.dotfiles.git $HOME\.dotfiles
cd $HOME\.dotfiles
.\scripts\setup\setup-claude.ps1
```

This installs agents, skills, rules, commands, and `CLAUDE.md` into `~/.claude\` using **directory junctions** (no admin rights required). The statusline is macOS/Linux-only and is skipped on Windows.

### Windows (CMD)

```cmd
scripts\setup\setup-claude.bat
```

The `.bat` file calls the PowerShell script automatically — no need to launch PowerShell manually.

### Resync after pulling dotfiles

**macOS / Linux:**
```bash
~/.dotfiles/scripts/update.sh
```

**Windows (PowerShell):**
```powershell
.\scripts\update.ps1
```

Both scripts pull the latest dotfiles and resync Claude Code config automatically. **One script, no separate step.**

### macOS / Linux — direct modes (for scripting)

```bash
~/.dotfiles/scripts/setup/setup-claude.sh update          # non-interactive resync
~/.dotfiles/scripts/setup/setup-claude.sh install         # full setup, no menu
~/.dotfiles/scripts/setup/setup-claude.sh statusline-only
~/.dotfiles/scripts/setup/setup-claude.sh sync
```

### Windows — modes

```powershell
.\scripts\setup\setup-claude.ps1          # interactive (prompts for settings.json)
.\scripts\setup\setup-claude.ps1 update   # non-interactive resync
```

---

## New Project Setup

Type `/new-project` inside Claude Code at the start of any project. It runs as a **conversational discovery session** — not a form.

```
/new-project
```

### What it does

**Phase 1 — Discovery.** Claude asks open-ended questions about your idea, not just technical ones: who are the users, how will they find it, is there a paid component, web/mobile/both, constraints? It adapts based on your answers — 2-3 follow-ups at a time, not a 20-question interrogation.

**Phase 2 — Stack recommendation.** Based on the conversation, Claude recommends a specific stack with reasoning. Not a list of options — an actual recommendation with trade-offs explained. You can push back: *"why not SvelteKit instead?"* and Claude will either agree or defend the choice.

**Phase 3 — Refine.** Keep the conversation going until the stack feels right.

**Phase 4 — Confirm.** Claude shows a final summary and asks for a thumbs-up before writing any files.

**Phase 5 — Scaffold.** Creates two files:
- `.claude/CLAUDE.md` — project context: idea, stack, key file paths, dev commands, conventions, and the decisions made during discovery (why you chose X over Y)
- `.claude/settings.json` — project-level permissions tailored to your stack's tools

### What it does NOT do

`/new-project` only sets up the `.claude/` config. It does **not** scaffold the actual project (no `pnpm create next-app`, no file structure, no dependencies). That's intentional — the discovery is separate from the build. After `/new-project` you'd say *"now scaffold the project"* and Claude has full context to do it well.

### What gets saved

All decisions from the conversation are written into `.claude/CLAUDE.md`:
- The project idea and who it's for
- The full stack with rationale
- Key constraints and decisions made
- Dev commands, file paths, conventions

This file loads every session for that project, so Claude always has context.

### Scope: global vs project

| Global `~/.claude/` | Project `.claude/` |
|--------------------|--------------------|
| Your persona, preferences | This project's name, stack, paths |
| All rules (TypeScript, Git…) | Project-specific rules |
| All agents (code-reviewer…) | Project-specific agents |
| All skills | Project-specific skills |
| Your default permissions | Overrides for this project's tools |

The global setup applies to every project automatically. The project `.claude/` adds context on top.

---

## The 6 Things In Detail

### 1. Global CLAUDE.md

**File:** `config/claude/CLAUDE.md` → symlinked to `~/.claude/CLAUDE.md`

Loaded at the start of **every session**. Kept lean (~50 lines). Contains:
- Who you are and your stack
- Behaviour defaults (no filler, show code, etc.)
- `@rules/` references for detailed guidelines

```markdown
## Stack
- Web: Next.js + Supabase + Vercel
- Mobile: Expo + RevenueCat

## Defaults
- TypeScript strict. No any.
- pnpm always.
- Zod for all validation.

## Rules
@rules/typescript.md
@rules/git.md
```

The `@rules/file.md` syntax tells Claude to load that file when relevant — keeps CLAUDE.md small while making the full rules available.

### 2. Rules

**Directory:** `config/claude/rules/` → symlinked to `~/.claude/rules/`

Detailed guidelines split by topic. Claude loads them on demand via `@rules/` references in CLAUDE.md.

| File | Coverage |
|------|----------|
| `typescript.md` | Strict mode, no `any`, Zod, naming, error handling |
| `git.md` | Conventional commits, branch naming, PR format |
| `react.md` | Server vs client, data fetching, hooks, Tailwind |
| `database.md` | Schema conventions, RLS, migrations, Supabase queries |
| `security.md` | Auth, secrets, input validation, Stripe webhooks |
| `testing.md` | Vitest, RTL, Playwright — what to test and how |
| `api.md` | Route handlers, response format, pagination, webhooks |
| `mobile.md` | Expo, React Native, SecureStore, navigation, NativeWind |
| `performance.md` | React rendering, memoization, bundles, images, caching |
| `env.md` | Environment variables, validation, secrets, Vercel/Cloudflare |

**Adding a rule:**
1. Create `config/claude/rules/your-topic.md`
2. Add `@rules/your-topic.md` to `config/claude/CLAUDE.md`
3. Run `~/.dotfiles/scripts/setup/setup-claude.sh update` (symlink is created automatically)

### 3. Skills

**Directory:** `config/claude/skills/` → symlinked to `~/.claude/skills/`

Skills are reusable instruction sets. Claude loads only the `name` + `description` at startup (~100 tokens/skill), then reads the full `SKILL.md` when relevant. Two invocation modes:

- **Auto-triggered** — Claude decides when to use it based on your request and the skill description
- **Manual** — you type `/skill-name`

| Skill | Trigger |
|-------|---------|
| `analytics-tracking` | Adding PostHog, Sentry, Chartmogul |
| `angular` | Angular + TypeScript work |
| `animations` | Framer Motion, Reanimated, Moti |
| `astro` | Astro sites, content collections |
| `cloudflare` | Pages, R2, Workers, Turnstile |
| `commit` | `/commit` — smart git commit |
| `csharp` | C# / .NET / ASP.NET Core |
| `email-marketing` | Resend + Loops.so |
| `expo-mobile` | React Native + Expo |
| `landing-page` | High-converting SaaS landing pages |
| `market-research` | Competitor analysis, positioning |
| `nextjs` | Next.js App Router patterns |
| `product-spec` | PRDs, feature specs |
| `revenuecat` | Mobile subscriptions (iOS + Android) |
| `saas-patterns` | Multi-tenancy, billing, auth, onboarding |
| `security-audit` | Security review checklist |
| `seo-content` | Next.js metadata, JSON-LD, Core Web Vitals |
| `sql` | PostgreSQL queries and optimization |
| `stripe` | Stripe payments, webhooks, subscriptions |
| `supabase` | Schema, RLS, auth, edge functions |
| `sveltekit` | SvelteKit, form actions, Cloudflare Pages |
| `turborepo` | Monorepo setup, shared packages |
| `ui-design` | UI/UX, Tailwind, accessibility |

**Adding a skill:**
```bash
mkdir -p ~/.dotfiles/config/claude/skills/my-skill
cat > ~/.dotfiles/config/claude/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: What this does and when to trigger. Be specific — Claude uses this to decide.
---

When invoked, do:
1. Step one
2. Step two
EOF

# Then sync
~/.dotfiles/scripts/setup/setup-claude.sh update
```

**Skill frontmatter options:**
```yaml
---
name: deploy
description: Deploy to Vercel production
disable-model-invocation: true   # only YOU can invoke (not auto-triggered)
user-invocable: false            # only Claude auto-triggers (hidden from / menu)
allowed-tools: Bash, Read        # restrict available tools
model: sonnet                    # override model
context: fork                    # run as isolated subagent
---
```

Use `disable-model-invocation: true` for skills with side effects (deploy, send email, etc.).

### 4. Agents

**Directory:** `config/claude/agents/` → symlinked to `~/.claude/agents/`

Specialist subagents with their own personas, tool restrictions, and optional model overrides. Claude delegates to them automatically based on the `description` field.

| Agent | When used |
|-------|-----------|
| `architect` | System design, tech stack decisions, ADRs |
| `backend-developer` | APIs, databases, server-side code |
| `code-reviewer` | Code quality, best practices, refactoring |
| `database-admin` | Database management, optimization, migrations |
| `data-engineer` | SQL, data pipelines |
| `designer` | UI/UX, wireframes, design systems |
| `devops-engineer` | CI/CD, Docker, cloud infra |
| `frontend-developer` | React, components, CSS |
| `growth-hacker` | Virality, acquisition, retention experiments |
| `marketing-engineer` | Marketing automation, analytics |
| `mobile-developer` | iOS, Android, React Native |
| `performance-engineer` | Optimization, profiling, benchmarking |
| `pricing-strategist` | Pricing tiers, packaging, WTP |
| `product-manager` | PRDs, feature specs, roadmaps |
| `project-manager` | Planning, timelines |
| `qa-engineer` | Testing, test plans, automation |
| `security-engineer` | Security audits, threat modeling |
| `support-engineer` | Troubleshooting, documentation |
| `technical-writer` | Docs, READMEs, guides |

**Agent file format:**
```markdown
---
name: my-agent
description: Trigger keywords and when to use. Be specific.
model: sonnet        # sonnet | opus | haiku | inherit
tools: Read, Bash    # omit for all tools
color: blue
---

System prompt for this agent...
```

**Adding an agent to dotfiles:**
```bash
# If you created an agent in ~/.claude/agents/ manually:
~/.dotfiles/scripts/setup/setup-claude.sh sync

# Then commit it
cd ~/.dotfiles
git add config/claude/agents/
git commit -m "feat: add my-agent"
```

### 5. Settings

**File:** `config/claude/settings.json` → copied/merged to `~/.claude/settings.json`

```json
{
  "alwaysThinkingEnabled": true,
  "statusLine": {
    "type": "command",
    "command": "~/.dotfiles/config/claude/statusline.sh"
  },
  "permissions": {
    "allow": [
      "Bash(pnpm *)", "Bash(npm *)", "Bash(npx *)",
      "Bash(git *)", "Bash(gh *)", "Bash(supabase *)",
      "Bash(docker *)", "Bash(ls*)", "Bash(cat *)"
    ],
    "deny": [
      "Bash(rm -rf *)", "Bash(sudo rm *)",
      "Bash(curl * | bash)", "Bash(wget * | sh)",
      "Bash(chmod 777 *)", "Bash(dd *)"
    ]
  }
}
```

**Project-level settings** (`.claude/settings.json`) override the global ones for that project. Use them to allow project-specific commands:
```json
{
  "permissions": {
    "allow": ["Bash(vercel *)", "Bash(wrangler *)"]
  }
}
```

### 6. Commands

**Directory:** `config/claude/commands/` → symlinked to `~/.claude/commands/`

Manual slash commands you invoke explicitly (vs skills which auto-trigger).

| Command | What it does |
|---------|-------------|
| `/new-project` | Scaffold `.claude/` config for a new project |
| `/pr` | Create a GitHub PR with conventional title + body |
| `/review` | Review local changes or a PR by number |
| `/standup` | Generate standup from yesterday's git activity |
| `/debug` | Systematic debugging — root cause analysis |
| `/docs` | Generate or update documentation |
| `/deploy` | Deploy to production |
| `/check` | Run health check on project |

**Adding a command:**
```bash
cat > ~/.dotfiles/config/claude/commands/my-command.md << 'EOF'
Do X for $ARGUMENTS.

## Step 1
...
EOF

~/.dotfiles/scripts/setup/setup-claude.sh update
```

Use `$ARGUMENTS` to capture what you type after the slash command name.

---

## Hooks

Hooks are shell scripts that fire at specific points in Claude's workflow. Configured in `settings.json` and stored in `config/claude/hooks/`.

### notify-done.sh

Fires a macOS/Linux desktop notification when Claude finishes responding. Useful when you step away from long-running tasks (testing, analysis, building) — you get a notification when Claude is done instead of constantly checking back.

Example:
```
$ /some-long-task
[Claude thinking... notification fires when done]
```

Add more hooks to `config/claude/hooks/` as needed — they're auto-picked up by `setup-claude.sh`.

---

## Status Line

Shows at the top of Claude Code:

```
Claude Sonnet 4.6 | 45k / 200k | 22% used | thinking: On
current: ●●○○○○○○○○ 22%    | weekly: ●●●○○○○○○○ 34%
resets 3:45pm              | resets mar 8, 11:00am
```

Script: `config/claude/statusline.sh`. Parses token counts from Claude's context JSON and fetches usage from the Anthropic API (cached 60s, reads OAuth token from macOS Keychain).

**Troubleshooting:**
- No usage bars → `jq` or `curl` missing, or not logged in with OAuth
- Empty → check `jq` is installed (`brew install jq`)

---

## Extending the Setup

### File counts (current)

| Type | Count | Add more to |
|------|-------|-------------|
| Agents | 19 | `config/claude/agents/` |
| Skills | 23 | `config/claude/skills/` |
| Rules | 10 | `config/claude/rules/` |
| Commands | 8 | `config/claude/commands/` |
| Hooks | 1 | `config/claude/hooks/` |

### After adding anything

```bash
# Resync symlinks
~/.dotfiles/scripts/setup/setup-claude.sh update

# Commit
cd ~/.dotfiles
git add config/claude/
git commit -m "feat: add [whatever you added]"
git push
```

The next `update.sh` run on any machine will automatically pick up the new files.

---

## Reference

### All setup-claude.sh modes

```bash
./scripts/setup/setup-claude.sh            # full interactive install
./scripts/setup/setup-claude.sh update     # non-interactive resync (use for updates)
./scripts/setup/setup-claude.sh statusline-only
./scripts/setup/setup-claude.sh sync       # pull live agents back into dotfiles
./scripts/setup/setup-claude.sh agents-only
```

### Directory structure

```
config/claude/
├── CLAUDE.md              # global instructions → ~/.claude/CLAUDE.md
├── settings.json          # settings → ~/.claude/settings.json
├── settings.example.json  # reference copy
├── statusline.sh          # statusline script
├── agents/                # 19 agents → ~/.claude/agents/
├── skills/                # 23 skills → ~/.claude/skills/
├── rules/                 # 10 rules → ~/.claude/rules/
├── commands/              # 8 commands → ~/.claude/commands/
└── hooks/                 # shell hooks (notify-done.sh, etc.)
```

### All scripts in this repo

**macOS / Linux (bash):**

| Script | Interactive? | What it does |
|--------|-------------|-------------|
| `install.sh` | ✅ yes | Full machine setup — Homebrew, tools, symlinks |
| `scripts/setup/setup-claude.sh` | ✅ menu when no args | Claude Code setup (menu → pick 1–4) |
| `scripts/update.sh` | ❌ | Update all package managers + Claude Code |
| `scripts/backup/backup-dotfiles.sh` | ❌ | Backup configs to timestamped folder |
| `scripts/cleanup.sh` | ❌ | Clear caches (Homebrew, npm, pip, etc.) |
| `scripts/dev-check.sh` | ❌ | Health check — are all tools installed? |
| `scripts/setup/setup-gpg.sh` | ✅ yes | Set up GPG commit signing |

**Windows:**

| Script | Shell | What it does |
|--------|-------|-------------|
| `scripts/setup/setup-claude.ps1` | PowerShell | Claude Code setup (agents, skills, rules, CLAUDE.md) |
| `scripts/setup/setup-claude.bat` | CMD | Same — delegates to the `.ps1` |
| `scripts/update.ps1` | PowerShell | Update winget, npm, pnpm, dotfiles, Claude Code |
| `scripts/update.bat` | CMD | Same — delegates to the `.ps1` |

"Interactive" means it pauses and asks you questions. Non-interactive scripts run to completion without prompts.

### Related docs

- [Claude Code docs](https://code.claude.com/docs)
- [skills.sh marketplace](https://skills.sh)
