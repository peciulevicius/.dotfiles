# Claude Code Configuration

Everything Claude Code needs, synced across machines via dotfiles.

## Structure

```
config/claude/
├── CLAUDE.md              # Global instructions — loaded every session
├── settings.json          # Settings (statusline, permissions, thinking)
├── settings.example.json  # Reference copy
├── statusline.sh          # 3-line status display (model, tokens, usage bars)
├── agents/                # 17 specialist sub-agents
├── skills/                # 22 reusable skill packs
├── rules/                 # 7 rule files (loaded on demand via @rules/)
└── commands/              # 6 slash commands (/pr, /debug, etc.)
```

All files are symlinked to `~/.claude/` by `scripts/setup-claude.sh`.

## Quick Setup

```bash
# New machine or just want to see options:
~/.dotfiles/scripts/setup-claude.sh        # shows interactive menu

# Already set up, just resync after pulling:
~/.dotfiles/scripts/setup-claude.sh update
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

## Agents (17)

| Agent | Used for |
|-------|---------|
| `architect` | System design, tech stack decisions |
| `backend-developer` | APIs, databases, server-side code |
| `code-reviewer` | Code quality, best practices |
| `data-engineer` | SQL, data pipelines |
| `designer` | UI/UX, wireframes |
| `devops-engineer` | CI/CD, Docker, cloud infra |
| `frontend-developer` | React, components, CSS |
| `growth-hacker` | Acquisition, virality, retention |
| `marketing-engineer` | Marketing automation, analytics |
| `mobile-developer` | iOS, Android, React Native |
| `pricing-strategist` | Pricing tiers, packaging |
| `product-manager` | PRDs, roadmaps |
| `project-manager` | Planning, timelines |
| `qa-engineer` | Testing, test plans |
| `security-engineer` | Security audits, threat modeling |
| `support-engineer` | Troubleshooting, docs |
| `technical-writer` | READMEs, guides |

## Skills (22)

| Skill | Trigger |
|-------|---------|
| `analytics-tracking` | PostHog, Sentry, Chartmogul |
| `angular` | Angular + TypeScript (work) |
| `animations` | Framer Motion, Reanimated |
| `astro` | Astro sites, content collections |
| `cloudflare` | Pages, R2, Workers, Turnstile |
| `commit` | `/commit` — smart git commit |
| `csharp` | C# / .NET / ASP.NET Core (work) |
| `email-marketing` | Resend + Loops.so |
| `expo-mobile` | React Native + Expo |
| `landing-page` | High-converting SaaS pages |
| `market-research` | Competitor analysis, positioning |
| `nextjs` | Next.js App Router patterns |
| `product-spec` | PRDs, feature specs |
| `revenuecat` | Mobile in-app subscriptions |
| `saas-patterns` | Multi-tenancy, billing, auth |
| `security-audit` | OWASP checklist |
| `seo-content` | Metadata, Core Web Vitals |
| `sql` | PostgreSQL queries (work) |
| `supabase` | Schema, RLS, auth, edge functions |
| `sveltekit` | SvelteKit, Cloudflare Pages |
| `turborepo` | Monorepo setup |
| `ui-design` | UI components, Tailwind, a11y |

## Rules (7)

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

## Commands (6)

See `commands/README.md` for usage. Type `/` in Claude Code to see the full list.

## Adding New Content

```bash
# After adding any file to this directory:
~/.dotfiles/scripts/setup-claude.sh update

# Then commit
cd ~/.dotfiles
git add config/claude/
git commit -m "feat: add [thing]"
```

## See Also

- Full guide: `docs/CLAUDE_CODE_GUIDE.md`
- Claude Code docs: https://code.claude.com/docs
- Skills marketplace: https://skills.sh
