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
├── skills/                # 47 reusable skill packs (11 vendored third-party, see below)
├── rules/                 # 10 rule files (loaded on demand via @rules/)
├── commands/              # 2 slash commands (/new-project, /dotfiles)
└── hooks/                 # Shell hooks (notify-done.sh, etc.)
```

All files are symlinked to `~/.claude/` by `scripts/setup/setup-claude.sh`.

`homelab-service` is shared with Codex: its maintained source is
`.agents/skills/homelab-service/` at the repository root. Both
`config/claude/skills/homelab-service` and `.claude/skills/homelab-service`
are directory symlinks to it. The first preserves the existing setup/global
links; the second provides project discovery after cloning, with no global
setup required. Edit the canonical file once; neither alias holds a copy.
Other Claude skills stay in this tree. See `docs/AI_COLLABORATION.md`.

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

## Skills (47)

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
| `adaptive-endurance-coach` | Triathlon coach + sports nutrition (MIT, vendored from mprecilio20/adaptive-endurance-coach). TrainingPeaks is the source of truth via the local `trainingpeaks-mcp`; athlete memory in `~/.training/` |
| `personal-finance` | Budget tables, investing principles, read-only IBKR portfolio review, Lithuanian tax basics |
| `pkm-notes` | Obsidian + Kindle Scribe → `kindle_sync.py` pipeline, capture-first triage, reading list |

**Vendored third-party** (added 2026-09-29). Each folder has a `SOURCE.md`
with the upstream repo, the **pinned commit**, the license, exactly what was
reviewed, and any local edits. They are copied into the repo on purpose —
skills are instructions that agents with shell access follow, so nothing is
fetched at runtime and an update is a deliberate re-vendor + review.

| Skill | What it does | Source @ commit | License |
|-------|--------------|-----------------|---------|
| `frontend-design` | Design direction ("taste"): subject-grounded palette/type/layout plan, reviewed against AI-default looks, then built and self-critiqued. The default design skill. | anthropics/skills @ `8a1541c` | Apache-2.0 |
| `design-taste-frontend` | Heavier anti-slop rulebook for landing pages, portfolios and redesigns (brief → design read → dials → pre-flight checklist). ~35k tokens when loaded. | Leonxlnx/taste-skill @ `ce26fc2` | MIT |
| `web-design-guidelines` | UI audit against Vercel's Web Interface Guidelines, `file:line` findings. Rules vendored locally (upstream fetches them from `main` at runtime — removed). | vercel-labs/web-interface-guidelines @ `e3d624b` | MIT |
| `design-systems-reference` | All 74 awesome-design-md systems as DESIGN.md token sets; 12 marked as defaults (Linear, Stripe, Supabase, Vercel, Raycast, Resend, Cal.com, Expo, Sentry, PostHog, Notion, Revolut) — derive, don't clone. Local wrapper. | VoltAgent/awesome-design-md @ `f696123` | MIT |
| `playwright-cli` | Drive a real browser from the shell: snapshots, clicks, screenshots, tracing, test generation. CLI installed on the Mac mini 2026-09-29: `pnpm add -g @playwright/cli@0.1.22` (uses the installed Chrome; no separate browser download was needed). | microsoft/playwright-cli @ `b85c7a7` | Apache-2.0 |
| `vercel-react-best-practices` | 70 React/Next.js performance rules (waterfalls, bundle size, server, re-renders). | vercel-labs/agent-skills @ `063bee9` | MIT |
| `vercel-react-native-skills` | React Native / Expo performance rules (lists, animation, navigation, UI). | vercel-labs/agent-skills @ `063bee9` | MIT |
| `image-to-code` | Build a site from a screenshot/mockup: section-by-section analysis → faithful implementation. Upstream assumed Codex image generation — local "Claude adaptation" note: work from provided images, capture closer crops instead of generating. | Leonxlnx/taste-skill @ `ce26fc2` | MIT |
| `webapp-testing` | Scripted Python Playwright tests for local webapps + `with_server.py` (starts dev servers, runs the test, stops them). | anthropics/skills @ `8a1541c` | Apache-2.0 |
| `supply-chain-risk-auditor` | Dependency risk report (advisories, abandoned upstreams, publisher concentration, install scripts) via stdlib-only collector scripts that query public registries; never executes package code. Doesn't read `pnpm-lock.yaml` — pair with `pnpm audit`. | trailofbits/skills @ `82fe822` | CC-BY-SA-4.0 |
| `differential-review` | Trail of Bits' security review of a diff/PR: risk triage, git-blame on removed checks, blast radius, attacker modelling, written report. Complements `security-audit` (whole-codebase checklist). | trailofbits/skills @ `82fe822` | CC-BY-SA-4.0 |

The three first left out (image-to-code, webapp-testing, supply-chain-risk-auditor) and the remaining 62 design-system brands were vendored later the same day after the same review, at the user's request.

The same 11 skills are installed in the Paperclip **Studio** company — see
`services/paperclip/README.md` → *Skills*.

The homelab skills (`homelab-service`, `credential-rotation`, `homelab-audit`)
live here too since 2026-09-25 — one place for every skill. They only trigger
on homelab work, so they're harmless in other projects.

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

## Default model: `opusplan`

`settings.json` sets `"model": "opusplan"` (2026-09-26): **Opus while planning**
(plan mode — designing changes, judging risk), **Sonnet while executing**
(commands, edits, docs). Most homelab sessions are execution, so this keeps
the Pro plan's weekly limit for the moments where the stronger model matters.
Switch any time with `/model`. Note `settings.json` is **copied** into
`~/.claude` by `setup-claude.sh` (not symlinked) — re-run it, or edit both.
