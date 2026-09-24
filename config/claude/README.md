# Claude Code Configuration

Everything Claude Code needs, synced across machines via dotfiles.

## Structure

```
config/claude/
├── CLAUDE.md              # Global instructions — loaded every session
├── settings.json          # Settings (statusline, permissions, thinking)
├── settings.example.json  # Reference copy
├── statusline.sh          # 3-line status display (model, tokens, usage bars)
├── agents/                # 19 specialist sub-agents
├── skills/                # 32 reusable skill packs
├── rules/                 # 10 rule files (loaded on demand via @rules/)
├── commands/              # 2 slash commands (/new-project, /dotfiles)
└── hooks/                 # Shell hooks (notify-done.sh, etc.)
```

All files are symlinked to `~/.claude/` by `scripts/setup/setup-claude.sh`.

## Quick Setup

```bash
# New machine or just want to see options:
~/.dotfiles/scripts/setup/setup-claude.sh        # shows interactive menu

# Already set up, just resync after pulling:
~/.dotfiles/scripts/setup/setup-claude.sh update
```

## The 6 Things

| # | File/Dir | What it does |
|---|----------|-------------|
| 1 | `CLAUDE.md` | Persona + stack + behaviour — loaded every session |
| 2 | `rules/` | Detailed guidelines by topic (TypeScript, Git, React, etc.) |
| 3 | `skills/` | Auto-triggered or `/slash-invoked` instruction packs |
| 4 | `agents/` | Specialist subagents Claude delegates to automatically |
| 5 | `settings.json` | Permissions (allow/deny Bash), statusline, thinking |
| 6 | `commands/` | Manual slash commands you invoke explicitly |

## Agents (19)

| Agent | Used for |
|-------|---------|
| `architect` | System design, tech stack decisions |
| `backend-developer` | APIs, databases, server-side code |
| `code-reviewer` | Code quality, best practices |
| `database-admin` | Database management, optimization |
| `data-engineer` | SQL, data pipelines |
| `designer` | UI/UX, wireframes |
| `devops-engineer` | CI/CD, Docker, cloud infra |
| `frontend-developer` | React, components, CSS |
| `growth-hacker` | Acquisition, virality, retention |
| `marketing-engineer` | Marketing automation, analytics |
| `mobile-developer` | iOS, Android, React Native |
| `performance-engineer` | Optimization, profiling, benchmarking |
| `pricing-strategist` | Pricing tiers, packaging |
| `product-manager` | PRDs, roadmaps |
| `project-manager` | Planning, timelines |
| `qa-engineer` | Testing, test plans |
| `security-engineer` | Security audits, threat modeling |
| `support-engineer` | Troubleshooting, docs |
| `technical-writer` | READMEs, guides |

## Skills (32)

Invoke with `/name`, or Claude triggers them when the task matches (skills
marked *manual* have `disable-model-invocation: true`).

**Workflow**

| Skill | What it does |
|-------|---------|
| `check` | *manual* — pre-commit checks: lint, types, tests, gitleaks, audit |
| `commit` | *manual* — conventional commit from the staged diff |
| `debug` | *manual* — reproduce → locate → hypothesise → verify → fix |
| `develop` | Implement a GitHub issue end-to-end, open a PR |
| `jira` | Implement a pasted Jira ticket |
| `review` | *manual* — review local changes or a PR by number |
| `standup` | *manual* — standup summary from recent git activity |
| `testing` | Vitest/RTL, Playwright, Angular, xUnit/.NET — write and fix tests |
| `security-audit` | *manual* — OWASP checklist, RLS, secrets, webhooks |

**Stack**

| Skill | Covers |
|-------|---------|
| `analytics-tracking` | PostHog, Sentry, Chartmogul |
| `angular` | Angular + TypeScript (work) |
| `animations` | Framer Motion, Reanimated |
| `astro` | Astro sites, content collections |
| `cloudflare` | Pages, R2, Workers, Turnstile |
| `csharp` | C# / .NET / ASP.NET Core (work) |
| `email-marketing` | Resend + Loops.so |
| `expo-mobile` | React Native + Expo |
| `landing-page` | High-converting SaaS pages |
| `nextjs` | Next.js App Router patterns |
| `revenuecat` | Mobile in-app subscriptions |
| `saas-patterns` | Multi-tenancy, billing, auth |
| `seo-content` | Metadata, Core Web Vitals |
| `sql` | PostgreSQL queries (work) |
| `stripe` | Stripe payments, webhooks |
| `supabase` | Schema, RLS, auth, edge functions |
| `sveltekit` | SvelteKit, Cloudflare Pages |
| `turborepo` | Monorepo setup |
| `ui-design` | UI components, Tailwind, a11y |

**Product**

| Skill | What it does |
|-------|---------|
| `market-research` | *manual* — competitor analysis, positioning |
| `product-spec` | *manual* — PRDs, feature specs |

**Life** (no personal data in these files — facts come from live tools or
private memory at runtime)

| Skill | What it does |
|-------|---------|
| `personal-finance` | Budget tables, investing principles, read-only IBKR portfolio review, Lithuanian tax basics |
| `pkm-notes` | Obsidian + Kindle Scribe → `kindle_sync.py` pipeline, capture-first triage, reading list |

Project-only skills for the homelab (`homelab-service`, `credential-rotation`,
`homelab-audit`) live in the repo's own `.claude/skills/`, not here — they load
only when working inside `~/.dotfiles`.

## Rules (10)

Loaded on demand via `@rules/` references in `CLAUDE.md`:

| Rule file | Covers |
|-----------|--------|
| `typescript.md` | Strict mode, no `any`, Zod, naming |
| `git.md` | Conventional commits, branch naming, PR format |
| `react.md` | Server vs client, data fetching, hooks, Tailwind |
| `database.md` | Schema conventions, RLS, Supabase queries |
| `security.md` | Auth, secrets, input validation, webhooks |
| `testing.md` | Vitest, RTL, Playwright — what to test |
| `api.md` | Route handlers, response format, pagination |
| `mobile.md` | Expo, React Native, SecureStore, auth |
| `performance.md` | React rendering, bundles, images, caching |
| `env.md` | Environment variables, validation, secrets |

## Commands (2)

See `commands/README.md`. Type `/` in Claude Code to see everything invocable.

| Command | What it does |
|---------|-------------|
| `/new-project` | Scaffold `.claude/` config for a new project |
| `/dotfiles` | Pull latest dotfiles, check status, optionally run update.sh |

`/review`, `/debug`, `/check` and `/standup` used to exist as both commands and
skills — the command copies were removed 2026-09-24; they're skills now and
invoke the same way. `/pr`, `/docs` and `/deploy` were deleted earlier.
`setup-claude.sh update` now prunes symlinks left behind by deleted files.

## Hooks

Shell scripts that fire at specific points in Claude's workflow.

- `notify-done.sh` — fires a macOS/Linux desktop notification when Claude finishes responding. Useful for long-running tasks when you step away from the keyboard.

Configured in `settings.json` and stored in `config/claude/hooks/`. Add more as needed.

## Adding New Content

```bash
# After adding any file to this directory:
~/.dotfiles/scripts/setup/setup-claude.sh update

# Then commit
cd ~/.dotfiles
git add config/claude/
git commit -m "feat: add [thing]"
```

## See Also

- Full guide: `docs/CLAUDE_CODE_GUIDE.md`
- Claude Code docs: https://code.claude.com/docs
- Skills marketplace: https://skills.sh
