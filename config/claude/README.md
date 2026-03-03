# Claude Code Configuration

Everything Claude Code needs, synced across machines via dotfiles.

## Structure

```
config/claude/
├── statusline.sh         # Status line script (3-line display with usage bars)
├── settings.json         # Claude Code settings (sync to ~/.claude/settings.json)
├── agents/               # Sub-agent definitions (17 specialists)
│   ├── architect.md
│   ├── backend-developer.md
│   ├── code-reviewer.md
│   ├── data-engineer.md
│   ├── designer.md
│   ├── devops-engineer.md
│   ├── frontend-developer.md
│   ├── growth-hacker.md      ← NEW
│   ├── marketing-engineer.md
│   ├── mobile-developer.md
│   ├── pricing-strategist.md ← NEW
│   ├── product-manager.md
│   ├── project-manager.md
│   ├── qa-engineer.md
│   ├── security-engineer.md
│   ├── support-engineer.md
│   └── technical-writer.md
└── skills/               # Reusable skill definitions (22 skills)
    ├── analytics-tracking/   ← PostHog, Sentry, RevenueCat events
    ├── angular/              ← Angular patterns (work)
    ├── animations/           ← Framer Motion + Reanimated + Moti
    ├── astro/                ← Astro static sites + content collections
    ├── cloudflare/           ← Pages, R2, Workers, Turnstile, KV
    ├── commit/               ← Git conventional commits
    ├── csharp/               ← C#/.NET (work)
    ├── email-marketing/      ← Resend + Loops.so
    ├── expo-mobile/          ← React Native + Expo
    ├── landing-page/         ← High-converting landing pages
    ├── market-research/      ← Market analysis
    ├── nextjs/               ← Next.js App Router patterns
    ├── product-spec/         ← PRDs and feature specs
    ├── revenuecat/           ← Mobile in-app subscriptions
    ├── saas-patterns/        ← Multi-tenancy, billing, auth
    ├── security-audit/       ← OWASP checklist for SaaS
    ├── seo-content/          ← Metadata, Core Web Vitals, JSON-LD
    ├── sql/                  ← PostgreSQL queries (work)
    ├── supabase/             ← Schema, RLS, auth, edge functions
    ├── sveltekit/            ← SvelteKit routing, load, actions
    ├── turborepo/            ← Monorepo setup + shared packages
    └── ui-design/            ← UI components, Tailwind, a11y
```

## Quick Setup

```bash
# Full setup (run on new machine after ./install.sh)
~/.dotfiles/scripts/setup-claude.sh

# Just the statusline
~/.dotfiles/scripts/setup-claude.sh statusline-only

# Sync new agents you created back into dotfiles
~/.dotfiles/scripts/setup-claude.sh sync
```

## Status Line

Shows model, token usage, context %, thinking mode, and usage limits:

```
Claude Sonnet 4.6 | 45k / 200k | 22% used 45,231 | 78% remain 154,769 | thinking: On
current: ●●○○○○○○○○ 22%    | weekly: ●●●○○○○○○○ 34%
resets 3:45pm              | resets mar 8, 11:00am
```

Configured in `settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.dotfiles/config/claude/statusline.sh"
  }
}
```

## Settings

`settings.json` is the canonical settings file. The setup script syncs it to `~/.claude/settings.json`.

Key settings:
- `alwaysThinkingEnabled` — enable extended thinking
- `statusLine` — custom status line script

## Agents

Agent `.md` files in `agents/` are symlinked to `~/.claude/agents/` by the setup script. Claude automatically uses them when relevant based on their `description` field.

To add a new agent:
1. Create `.md` file in `agents/` OR use `/agents` in Claude Code
2. Run `~/.dotfiles/scripts/setup-claude.sh agents-only` (or let the symlink auto-work)
3. Commit to dotfiles

## Skills

Skill directories in `skills/` are symlinked to `~/.claude/skills/` by the setup script.

Each skill is a directory with `SKILL.md`:
```
skills/my-skill/
└── SKILL.md
```

You can also install community skills from [skills.sh](https://skills.sh):
```bash
npx skills add vercel-labs/deploy
```

## See Also

- Full guide: `docs/CLAUDE_CODE_GUIDE.md`
- Claude Code docs: https://code.claude.com/docs
