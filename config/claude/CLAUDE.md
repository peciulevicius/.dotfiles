# Global Claude Code Instructions

## Who I Am
Džiugas — full-stack TypeScript developer. Building a SaaS product (landing + web app + mobile app) and a personal site. Day job uses Angular + C#/.NET.

## Stack
- **Web:** Next.js (Vercel) or SvelteKit (Cloudflare Pages)
- **Mobile:** Expo + React Native + NativeWind
- **Backend/DB:** Supabase (Postgres + RLS + Auth + Storage)
- **Payments:** Stripe (web) + RevenueCat (mobile)
- **Analytics:** PostHog + Sentry + Chartmogul
- **Email:** Resend + Loops.so
- **Infra:** Cloudflare (Pages, R2, Workers, Turnstile)
- **Monorepo:** Turborepo + pnpm workspaces
- **IDE:** WebStorm (primary), VS Code

## Defaults
- TypeScript strict mode always. No `any`.
- `pnpm` — never `npm` or `yarn` unless forced.
- Zod for all runtime validation (forms, API inputs, env vars).
- Conventional commits: `feat`, `fix`, `chore`, `docs`, `refactor`.
- No Co-Authored-By trailers in commits.
- Tailwind for styling. shadcn/ui for components (Next.js), Skeleton UI (SvelteKit).
- `@/` path alias for `src/`.

## Behaviour
- Be concise. Skip filler ("Great question!", "Certainly!").
- Show code, not descriptions of code.
- Prefer editing existing files over creating new ones.
- Don't add comments to code I didn't change.
- Don't add error handling for impossible cases.
- Don't suggest refactors beyond what's asked.
- When uncertain about approach, ask before building.

## Skills — use these
Vetted and pinned in `~/.dotfiles/config/claude/skills/` (sources in each `SOURCE.md`).
- Building UI → `frontend-design`; landing pages/redesigns → also `design-taste-frontend`; "make it feel like X" → `design-systems-reference`
- Building from a screenshot/mockup → `image-to-code`
- UI/UX/accessibility audit → `web-design-guidelines`
- React / Next.js → `vercel-react-best-practices`; Expo / React Native → `vercel-react-native-skills`
- Browser testing/screenshots → `playwright-cli` (installed globally); scripted local webapp tests → `webapp-testing`
- Security review of a diff/PR → `differential-review`; dependency risk → `supply-chain-risk-auditor` (+ `pnpm audit` — it doesn't read `pnpm-lock.yaml`)

## Rules (loaded on demand)
@rules/typescript.md
@rules/git.md
@rules/react.md
@rules/database.md
@rules/security.md
@rules/testing.md
@rules/api.md
@rules/mobile.md
@rules/performance.md
@rules/env.md

## Shared AI memory (Mac mini)

For cross-project or homelab work, read `~/ai-memory/README.md`,
`people-and-preferences.md`, and the relevant project note when the shared
memory directory is available. Follow its inbox and ownership rules. Never
copy secrets, private chat exports, or personal memory into a repository.

## Project Setup
Run `/new-project` at the start of any new project to scaffold `.claude/` config.
