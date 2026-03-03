# Claude Code Complete Guide

Everything you need to know to get the most out of Claude Code — skills, sub-agents, statusline, settings, hooks, and more.

## Table of Contents

- [Quick Start](#quick-start)
- [What's Included in Dotfiles](#whats-included-in-dotfiles)
- [Status Line](#status-line)
- [Sub-Agents](#sub-agents)
- [Skills](#skills)
- [Skills Marketplace (skills.sh)](#skills-marketplace-skillssh)
- [Settings & Hooks](#settings--hooks)
- [Reusable Project Prompt](#reusable-project-prompt)
- [New Machine Setup](#new-machine-setup)

---

## Quick Start

```bash
# Set up everything on a new machine
~/.dotfiles/scripts/setup-claude.sh

# Just the statusline
~/.dotfiles/scripts/setup-claude.sh statusline-only

# Sync live agents back to dotfiles (after creating new agents)
~/.dotfiles/scripts/setup-claude.sh sync
```

---

## What's Included in Dotfiles

```
config/claude/
├── statusline.sh         # Status line script (3-line display)
├── settings.json         # Claude Code settings (statusline, thinking, etc.)
├── agents/               # 17 specialist sub-agents
│   ├── architect.md
│   ├── backend-developer.md
│   ├── code-reviewer.md
│   ├── data-engineer.md
│   ├── designer.md
│   ├── devops-engineer.md
│   ├── frontend-developer.md
│   ├── growth-hacker.md
│   ├── marketing-engineer.md
│   ├── mobile-developer.md
│   ├── pricing-strategist.md
│   ├── product-manager.md
│   ├── project-manager.md
│   ├── qa-engineer.md
│   ├── security-engineer.md
│   ├── support-engineer.md
│   └── technical-writer.md
└── skills/               # 22 custom skills
    ├── analytics-tracking/
    ├── angular/
    ├── animations/
    ├── astro/
    ├── cloudflare/
    ├── commit/
    ├── csharp/
    ├── email-marketing/
    ├── expo-mobile/
    ├── landing-page/
    ├── market-research/
    ├── nextjs/
    ├── product-spec/
    ├── revenuecat/
    ├── saas-patterns/
    ├── security-audit/
    ├── seo-content/
    ├── sql/
    ├── supabase/
    ├── sveltekit/
    ├── turborepo/
    └── ui-design/
```

---

## Status Line

The status line appears at the top of Claude Code and shows:

```
Claude Sonnet 4.6 | 45k / 200k | 22% used 45,231 | 78% remain 154,769 | thinking: On
current: ●●○○○○○○○○ 22%    | weekly: ●●●○○○○○○○ 34%
resets 3:45pm              | resets mar 8, 11:00am
```

**Line 1:** Model name, token usage, context %, thinking mode
**Line 2:** Progress bars for 5-hour limit, 7-day limit, extra usage
**Line 3:** Reset times for each limit

### How it works

The script at `config/claude/statusline.sh` receives JSON from Claude Code via stdin on every turn and outputs formatted text. It:

1. Parses token counts from the context window JSON
2. Fetches usage limits from `api.anthropic.com/api/oauth/usage` (cached 60s)
3. Gets the OAuth token from macOS Keychain or Linux credentials file
4. Renders colored progress bars

### Configuration

In `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.dotfiles/config/claude/statusline.sh"
  }
}
```

### Troubleshooting

- **No usage bars:** jq or curl missing, or not logged in with OAuth
- **"Claude" only shown:** Script returned empty — check if jq is installed
- **Colors wrong:** Terminal must support 24-bit color (most modern terminals do)

---

## Sub-Agents

Sub-agents are specialized AI assistants that handle specific types of tasks in their own isolated context window.

### Built-in Agents (automatic)

| Agent | Purpose |
|-------|---------|
| `Explore` | Fast read-only codebase search (Haiku model) |
| `Plan` | Research before presenting implementation plans |
| `general-purpose` | Complex multi-step tasks |

### Your Custom Agents

Stored in `~/.claude/agents/` (symlinked from `~/.dotfiles/config/claude/agents/`):

| Agent | When Claude uses it |
|-------|---------------------|
| `architect` | System design, tech stack decisions, ADRs |
| `backend-developer` | APIs, databases, server-side code |
| `code-reviewer` | Code quality, best practices, refactoring |
| `data-engineer` | SQL, data pipelines, BigQuery |
| `designer` | UI/UX, wireframes, design systems |
| `devops-engineer` | CI/CD, Docker, Kubernetes, cloud infra |
| `frontend-developer` | React, Vue, CSS, TypeScript |
| `growth-hacker` | Viral loops, acquisition, retention experiments, growth metrics |
| `marketing-engineer` | Marketing automation, analytics |
| `mobile-developer` | iOS, Android, React Native |
| `pricing-strategist` | Pricing tiers, packaging, WTP, freemium vs trial decisions |
| `product-manager` | PRDs, feature specs, roadmaps |
| `project-manager` | Project planning, timelines |
| `qa-engineer` | Testing, test plans, automation |
| `security-engineer` | Security audits, threat modeling |
| `support-engineer` | Troubleshooting, documentation |
| `technical-writer` | Docs, READMEs, guides |

### Creating a New Agent

```bash
# Via interactive command (recommended)
/agents

# Or manually create a .md file
cat > ~/.claude/agents/my-agent.md << 'EOF'
---
name: my-agent
description: What this agent does and when to use it. Include trigger keywords.
model: sonnet
tools: Read, Grep, Glob, Bash, Edit, Write
---

# My Agent

You are a specialist in X. When invoked...

## Responsibilities
- ...
EOF
```

**Important:** Write a good `description` — Claude uses it to decide when to delegate automatically.

### Agent File Format

```markdown
---
name: agent-name              # lowercase-with-hyphens
description: When to use it   # Claude reads this to decide delegation
model: sonnet                 # sonnet | opus | haiku | inherit
tools: Read, Grep, Bash       # omit for all tools
color: blue                   # UI color hint
---

System prompt for the agent...
```

### Agent Scopes

| Location | Scope |
|----------|-------|
| `~/.claude/agents/` | All your projects (personal) |
| `.claude/agents/` | Current project only |

### Adding an Agent to Dotfiles

```bash
# After creating a new agent in ~/.claude/agents/:
~/.dotfiles/scripts/setup-claude.sh sync

# Then commit it
cd ~/.dotfiles
git add config/claude/agents/
git commit -m "feat: add my-agent to claude agents"
```

---

## Skills

Skills extend Claude with reusable instructions and workflows. They're invoked with `/skill-name` or triggered automatically when relevant.

### Built-in Skills

| Skill | What it does |
|-------|-------------|
| `/simplify` | Reviews recent code changes for quality/efficiency, fixes issues in parallel |
| `/batch <task>` | Decomposes large tasks, spawns parallel agents per unit |
| `/debug` | Analyzes current session debug log |

### Creating a Skill

```bash
mkdir -p ~/.claude/skills/my-skill
cat > ~/.claude/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: What this skill does. Claude loads it when relevant.
---

When invoked, do the following:
1. Step one
2. Step two
EOF
```

### Skill Frontmatter Options

```yaml
---
name: deploy                     # /deploy to invoke
description: Deploy to prod      # Claude uses this for auto-trigger
disable-model-invocation: true   # Only YOU can invoke (not Claude auto)
user-invocable: false            # Only Claude can invoke (hidden from / menu)
allowed-tools: Bash, Read        # Restrict tools this skill can use
model: sonnet                    # Override model for this skill
context: fork                    # Run in isolated sub-agent context
agent: Explore                   # Which agent to use with context: fork
---
```

### When to use `disable-model-invocation: true`

Use this for skills with **side effects** you want to control:

```yaml
---
name: deploy
description: Deploy to production
disable-model-invocation: true   # You type /deploy, Claude doesn't auto-run it
---
```

### Skill Examples

**Git commit helper:**
```markdown
---
name: commit
description: Create a well-formatted git commit with conventional commits format
disable-model-invocation: true
---

Create a git commit for the current staged changes:

1. Run `git diff --staged` to see what's staged
2. Write a conventional commit message: `type(scope): description`
3. Types: feat, fix, chore, docs, refactor, test, style
4. Keep subject under 72 chars
5. Add body if the change needs explanation
```

**PR review:**
```markdown
---
name: review-pr
description: Review a GitHub pull request thoroughly
context: fork
agent: Explore
---

Review PR #$ARGUMENTS:

1. Run `gh pr view $ARGUMENTS` to get PR details
2. Run `gh pr diff $ARGUMENTS` to see changes
3. Check for bugs, security issues, performance problems
4. Provide structured feedback: Critical / Should Fix / Suggestions
```

### Skill Scopes

| Location | Scope |
|----------|-------|
| `~/.claude/skills/` | Personal (all projects) |
| `.claude/skills/` | Project-specific |

---

## Skills Marketplace (skills.sh)

[skills.sh](https://skills.sh) (also at [agentskills.io](https://agentskills.io)) is a directory of community-contributed skills for AI agents.

Claude Code natively supports the **Agent Skills open standard** — skills from this marketplace install directly.

### Installing Skills from the Marketplace

```bash
# Install a skill
npx skills add <owner/skill-name>

# Example: Vercel Labs skills
npx skills add vercel-labs/deploy-vercel
npx skills add vercel-labs/nextjs

# Browse all skills at: https://skills.sh
```

### What the Vercel Video Shows

The [YouTube video](https://www.youtube.com/watch?v=PkeC2hNQ9Zw) likely demonstrates using Claude Code with Vercel-specific skills for:
- Deploying to Vercel from within Claude Code
- Next.js development patterns
- Environment variable management

### Recommended Skills to Install

```bash
# Frontend / Vercel
npx skills add vercel-labs/nextjs          # Next.js patterns
npx skills add vercel-labs/deploy          # Deploy to Vercel

# General development
npx skills add anthropic/commit            # Smart commits
npx skills add anthropic/review            # Code review
```

---

## Settings & Hooks

### settings.json Reference

`~/.claude/settings.json`:

```json
{
  "alwaysThinkingEnabled": true,
  "statusLine": {
    "type": "command",
    "command": "~/.dotfiles/config/claude/statusline.sh"
  },
  "permissions": {
    "allow": [],
    "deny": []
  }
}
```

### Hooks

Hooks run shell commands at specific points in Claude's workflow:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "~/.dotfiles/scripts/validate-bash.sh" }
        ]
      }
    ],
    "PostToolUse": [],
    "Stop": [],
    "SubagentStart": [],
    "SubagentStop": []
  }
}
```

Hook events:
- `PreToolUse` — before Claude uses any tool
- `PostToolUse` — after Claude uses a tool
- `Stop` — when Claude finishes responding
- `SubagentStart` / `SubagentStop` — when sub-agents start/finish

Exit codes from hook scripts:
- `0` — allow the action
- `2` — block the action (Claude sees the stderr message)

### CLAUDE.md (Project Memory)

Create `.claude/CLAUDE.md` in any project to give Claude persistent context:

```markdown
# Project Name

## Stack
- Next.js 15, TypeScript, Tailwind CSS
- PostgreSQL via Drizzle ORM
- Deployed on Vercel

## Conventions
- Use `pnpm` (not npm)
- Components in `src/components/`, pages in `src/app/`
- Database queries in `src/lib/db/`

## Important Notes
- Never commit .env files
- Run `pnpm test` before committing
```

---

## Reusable Project Prompt

Copy this into `.claude/CLAUDE.md` for any new project and fill in the blanks:

```markdown
# [Project Name] — Claude Code Instructions

## Project Overview
[1-2 sentences describing what this project does]

## Tech Stack
- **Runtime:** Node.js / Python / Go / etc.
- **Framework:** [framework]
- **Database:** [database + ORM]
- **Deployment:** [platform]
- **Package manager:** [npm/pnpm/yarn/bun]

## Repository Structure
\`\`\`
src/
├── components/    # UI components
├── pages/         # Route pages
├── lib/           # Utilities
└── types/         # TypeScript types
\`\`\`

## Development Commands
\`\`\`bash
pnpm dev           # Start dev server
pnpm test          # Run tests
pnpm build         # Build for production
pnpm lint          # Lint code
\`\`\`

## Code Conventions
- [Language]: TypeScript strict mode / Python type hints / etc.
- [Style]: Prettier + ESLint / Black + Ruff / etc.
- [Commits]: Conventional Commits (feat/fix/chore/docs/refactor)
- [Testing]: Jest + React Testing Library / pytest / etc.

## Important Rules
- Never commit secrets (.env, API keys)
- Always run tests before committing
- [Project-specific rules...]

## Key Files
- `src/lib/db.ts` — Database client
- `src/middleware.ts` — Auth middleware
- [other important files...]

## When Helping Me
- Prefer [approach] over [other approach]
- Always add TypeScript types
- Write tests for new features
- Keep components under 200 lines
```

---

## New Machine Setup

```bash
# 1. Clone dotfiles
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 2. Run main installer (installs all tools)
./install.sh

# 3. Set up Claude Code specifically
./scripts/setup-claude.sh

# 4. Verify statusline works
# Open Claude Code — the 3-line status should appear at the top
```

### Manual Steps (if needed)

```bash
# Just the statusline
~/.dotfiles/scripts/setup-claude.sh statusline-only

# Verify settings
cat ~/.claude/settings.json

# List available agents
claude agents

# List skills
# Type / in Claude Code to see all skills
```

### After Creating New Agents/Skills

```bash
# Sync new agents from ~/.claude/agents/ back into dotfiles
~/.dotfiles/scripts/setup-claude.sh sync

# Then commit
cd ~/.dotfiles
git add config/claude/
git commit -m "feat: add new claude agents/skills"
git push
```

---

## See Also

- [Claude Code Docs](https://code.claude.com/docs)
- [Sub-agents](https://code.claude.com/docs/en/sub-agents)
- [Skills](https://code.claude.com/docs/en/skills)
- [Agent Skills Marketplace](https://skills.sh)
- [Hooks](https://code.claude.com/docs/en/hooks)
- `docs/BUSINESS_STACK_GUIDE.md` — Full product stack reference (frameworks, tools, how they connect)
