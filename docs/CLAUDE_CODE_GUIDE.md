# Claude Code guide

How the Claude Code configuration in this repository is structured, installed
and extended.

## Components

Claude Code reads its user configuration from `~/.claude/`. Everything below is
maintained in `config/claude/` and linked into `~/.claude/` by
`scripts/setup/setup-claude.sh`.

| Path in `~/.claude/` | Source | Purpose |
|---|---|---|
| `CLAUDE.md` | `config/claude/CLAUDE.md` | Global instructions loaded in every session |
| `rules/` | `config/claude/rules/` | Topic guidelines referenced from `CLAUDE.md` |
| `skills/` | `config/claude/skills/` | Skills, invoked automatically or with `/name` |
| `agents/` | `config/claude/agents/` | Specialised subagents |
| `commands/` | `config/claude/commands/` | Slash commands |
| `settings.json` | `config/claude/settings.json` | Permissions, hooks, status line |
| — | `config/claude/hooks/` | Hook scripts referenced from `settings.json` |

The current inventory of skills, agents and commands is in
[config/claude/README.md](https://github.com/peciulevicius/.dotfiles/blob/main/config/claude/README.md).

Project-specific skills for this repository (`homelab-service`,
`credential-rotation`, `homelab-audit`) live in `.claude/skills/` at the
repository root and apply only when working in this repository.

---

## Installation and updates

### macOS / Linux

```bash
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
./scripts/setup/setup-claude.sh      # interactive menu
```

| Option | Action |
|---|---|
| 1 | First-time setup (prompts for `settings.json`) |
| 2 | Resync agents, skills, rules and commands |
| 3 | Status line only |
| 4 | Copy agents created in `~/.claude/agents/` back into the repository |

Non-interactive modes:

```bash
./scripts/setup/setup-claude.sh install
./scripts/setup/setup-claude.sh update
./scripts/setup/setup-claude.sh statusline-only
./scripts/setup/setup-claude.sh sync
./scripts/setup/setup-claude.sh agents-only
```

### Windows

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser    # once
git clone https://github.com/peciulevicius/.dotfiles.git $HOME\.dotfiles
cd $HOME\.dotfiles
.\scripts\setup\setup-claude.ps1           # interactive
.\scripts\setup\setup-claude.ps1 update    # non-interactive resync
```

On Windows the configuration is linked with directory junctions, which need no
administrator rights. `scripts\setup\setup-claude.bat` runs the PowerShell
script from CMD. The status line is not installed on Windows.

### Keeping machines in sync

`scripts/update.sh` (macOS/Linux) and `scripts\update.ps1` (Windows) pull the
dotfiles and resync the Claude Code configuration as part of the normal update.

---

## Global instructions (`CLAUDE.md`)

Loaded at the start of every session and kept short. It describes the default
stack, working conventions, and references rule files:

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

`@rules/<file>.md` references let Claude load detailed guidance when relevant
without enlarging every session's context.

## Rules

| File | Coverage |
|---|---|
| `typescript.md` | Strict mode, no `any`, Zod, naming, error handling |
| `git.md` | Conventional commits, branch naming, pull request format |
| `react.md` | Server vs client components, data fetching, hooks, Tailwind |
| `database.md` | Schema conventions, RLS, migrations, Supabase queries |
| `security.md` | Authentication, secrets, input validation, Stripe webhooks |
| `testing.md` | Vitest, React Testing Library, Playwright |
| `api.md` | Route handlers, response format, pagination, webhooks |
| `mobile.md` | Expo, React Native, SecureStore, navigation, NativeWind |
| `performance.md` | Rendering, memoisation, bundles, images, caching |
| `env.md` | Environment variables, validation, secrets, Vercel/Cloudflare |

To add a rule: create `config/claude/rules/<topic>.md`, reference it from
`config/claude/CLAUDE.md`, and run `setup-claude.sh update`.

## Skills

A skill is a directory containing `SKILL.md`. Claude loads only each skill's
`name` and `description` at startup and reads the full file when the skill is
relevant, or when it is invoked with `/<name>`.

The skills cover three areas:

- **Workflows:** `develop`, `review`, `commit`, `check`, `debug`, `standup`,
  `jira`, `testing` (Vitest, Playwright, Angular, xUnit)
- **Frameworks and platforms:** Next.js, SvelteKit, Astro, Angular, Expo,
  Supabase, Stripe, RevenueCat, Cloudflare, Turborepo, C#/.NET, SQL
- **Product work:** landing pages, SEO, analytics, email marketing, market
  research, product specifications, UI design, security audits, SaaS patterns
- **Personal:** `personal-finance` (read-only by default), `pkm-notes`
  (Obsidian and the Kindle import)

Create a skill:

```bash
mkdir -p ~/.dotfiles/config/claude/skills/my-skill
cat > ~/.dotfiles/config/claude/skills/my-skill/SKILL.md <<'EOF'
---
name: my-skill
description: What it does and when to use it. Claude uses this text to decide.
---

1. Step one
2. Step two
EOF
~/.dotfiles/scripts/setup/setup-claude.sh update
```

Optional frontmatter:

```yaml
disable-model-invocation: true   # only invoked manually
user-invocable: false            # only invoked by Claude; hidden from the / menu
allowed-tools: Bash, Read        # restrict tools
model: sonnet                    # model override
context: fork                    # run as an isolated subagent
```

Use `disable-model-invocation: true` for skills with side effects, such as
deploying or sending email.

## Agents

Agents are subagents with their own instructions, tool restrictions and
optional model. Claude delegates to them based on their `description`.

| Area | Agents |
|---|---|
| Engineering | `architect`, `backend-developer`, `frontend-developer`, `mobile-developer`, `data-engineer`, `database-admin`, `devops-engineer`, `performance-engineer`, `security-engineer`, `qa-engineer` |
| Review and documentation | `code-reviewer`, `technical-writer`, `support-engineer` |
| Product and growth | `product-manager`, `project-manager`, `designer`, `pricing-strategist`, `growth-hacker`, `marketing-engineer` |

Agent file format:

```markdown
---
name: my-agent
description: When to use this agent. Be specific.
model: sonnet        # sonnet | opus | haiku | inherit
tools: Read, Bash    # omit for all tools
color: blue
---

System prompt for the agent.
```

An agent created directly in `~/.claude/agents/` can be copied into the
repository with `setup-claude.sh sync`, then committed.

## Commands

Slash commands in `config/claude/commands/` are invoked explicitly; `$ARGUMENTS`
holds the text typed after the command.

| Command | Purpose |
|---|---|
| `/new-project` | Discovery session that writes a project's `.claude/` configuration |
| `/dotfiles` | Status and maintenance of this repository |

`/check`, `/debug`, `/review` and `/standup` are skills (see above); they are
invoked the same way.

```bash
cat > ~/.dotfiles/config/claude/commands/my-command.md <<'EOF'
Do X for $ARGUMENTS.
EOF
~/.dotfiles/scripts/setup/setup-claude.sh update
```

## Settings

`config/claude/settings.json` is merged into `~/.claude/settings.json`:

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

A project's `.claude/settings.json` overrides these for that project, for
example to allow `vercel` or `wrangler`.

## Hooks

Hook scripts live in `config/claude/hooks/` and are wired up in `settings.json`.

| Hook | Behaviour |
|---|---|
| `notify-done.sh` | Desktop notification when Claude finishes responding |
| `typecheck.sh` | Type check after file edits |

## Status line

`config/claude/statusline.sh` (and `statusline.ps1`) shows the model, context
usage and plan usage:

```
<model> | 45k / 200k | 22% used | thinking: On
current: ●●○○○○○○○○ 22%    | weekly: ●●●○○○○○○○ 34%
resets 3:45pm              | resets mar 8, 11:00am
```

Usage is read from the Anthropic API with the OAuth token from the macOS
Keychain and cached for 60 seconds. If the bars are missing, check that `jq`
and `curl` are installed and that Claude Code is logged in with OAuth.

---

## New projects

Run `/new-project` in Claude Code at the start of a project. It is a
conversation rather than a form:

1. **Discovery:** users, distribution, monetisation, platforms and constraints.
2. **Stack recommendation:** one recommended stack with its trade-offs.
3. **Refinement:** until the stack is agreed.
4. **Confirmation:** a summary before any file is written.
5. **Output:** `.claude/CLAUDE.md` (idea, stack, paths, commands, conventions
   and the decisions made) and `.claude/settings.json` (permissions for the
   stack's tools).

It does not scaffold the application itself; ask for that afterwards, with the
context already in place.

| Global (`~/.claude/`) | Project (`.claude/`) |
|---|---|
| Preferences and defaults | Project name, stack and paths |
| All rules, agents and skills | Project-specific rules, agents and skills |
| Default permissions | Permission overrides for the project's tools |

---

## After adding anything

```bash
~/.dotfiles/scripts/setup/setup-claude.sh update
cd ~/.dotfiles && git add config/claude/ && git commit -m "feat(claude): add <name>" && git push
```

Other machines pick the change up on their next `update.sh` run.

## Related

- [guides/CLAUDE_WORKFLOW.md](guides/CLAUDE_WORKFLOW.md) — using the tools from idea to deployment
- [Claude Code documentation](https://code.claude.com/docs)
