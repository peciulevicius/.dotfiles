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

## Project Setup
Run `/new-project` at the start of any new project to scaffold `.claude/` config.
