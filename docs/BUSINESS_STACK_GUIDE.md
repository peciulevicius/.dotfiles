# Business Stack Guide

Complete reference for building products: landing page → web app → mobile app. Stack options, tool choices, and how everything connects.

---

## Table of Contents

- [Stack Paths](#stack-paths)
- [Web Framework Comparison](#web-framework-comparison)
- [Mobile Framework Comparison](#mobile-framework-comparison)
- [Backend & Database](#backend--database)
- [Analytics & Revenue](#analytics--revenue)
- [UI & Component Sharing](#ui--component-sharing)
- [Email Marketing](#email-marketing)
- [Deployment & Infrastructure](#deployment--infrastructure)
- [Idea to Product Journey](#idea-to-product-journey)
- [Claude Skills Reference](#claude-skills-reference)

---

## Stack Paths

### Path A: TypeScript Monorepo (recommended default)
**Best when:** web app is primary, mobile is secondary, you want one language everywhere.

```
Landing page  → Astro on Cloudflare Pages
Web app       → Next.js on Vercel  (or SvelteKit for better perf/DX)
Mobile        → Expo + React Native
Backend/DB    → Supabase
Shared        → Turborepo: types, Zod schemas, Supabase client, utils
```

### Path B: SvelteKit + Expo (escape React, keep TypeScript)
**Best when:** you want to leave React but keep TypeScript + Expo code sharing.

```
Landing page  → Astro on Cloudflare Pages
Web app       → SvelteKit on Cloudflare Pages or Vercel
Mobile        → Expo + React Native
Backend/DB    → Supabase
Note          → Less JSX code sharing than Path A, but SvelteKit DX is superior
```

### Path C: SvelteKit + Flutter (mobile as first-class product)
**Best when:** mobile app IS the product, beautiful native UI matters most, OK learning Dart.

```
Landing page  → Astro on Cloudflare Pages
Web app       → SvelteKit on Cloudflare
Mobile        → Flutter (iOS + Android)
Backend/DB    → Supabase (has Dart + JavaScript SDKs)
Note          → Zero code sharing between web and mobile
```

### Path D: Cloudflare-First (modern edge stack)
**Best when:** full Cloudflare ecosystem, edge-first performance, low infra cost.

```
Landing page  → Astro on Cloudflare Pages
Web app       → React Router v7 (Remix) on Cloudflare Workers
Mobile        → Expo + React Native
Backend       → Cloudflare Workers (Hono) + D1 or Supabase
Storage       → Cloudflare R2
```

---

## Web Framework Comparison

| Framework | Perf | Bundle | Cloudflare | Ecosystem | DX | Verdict |
|---|---|---|---|---|---|---|
| **Next.js** | 850 RPS | ~70 KB | Limited (adapter) | Massive | Good | Safe default |
| **SvelteKit** | 1,200 RPS (+41%) | ~20-40 KB | Excellent | Growing fast | Excellent | Best Next.js alternative |
| **Remix / RR v7** | Good | Medium | Excellent (official) | Medium | Good | Cloudflare-first |
| **Astro** | Good | ~0 JS | Excellent | Large | Excellent | Content + marketing only |

**Recommendation:** If uncertain about Next.js, choose SvelteKit:
- TypeScript (same as Next.js)
- 41% faster, 65% smaller bundles
- Simpler mental model (no RSC complexity)
- Excellent Cloudflare Pages support
- Works with Supabase, Stripe, everything

---

## Mobile Framework Comparison

| Framework | Language | Code Sharing with Web | Performance | Verdict |
|---|---|---|---|---|
| **Expo + React Native** | TypeScript | ✅ Types, Supabase, Zod, utils | Excellent (New Architecture) | Best if web is primary |
| **Flutter** | Dart | ❌ | Excellent (120fps Impeller) | Best if mobile is primary |
| **Kotlin Multiplatform** | Kotlin | ❌ | Native | Native UI per platform |

**Keep Expo.** The New Architecture (JSI/Fabric/TurboModules) is production-standard in 2026:
- 83% adoption in active projects
- 40x faster native communications
- Performance gap with Flutter has closed significantly

If you add Flutter, you add Dart and lose TypeScript code sharing.

---

## Backend & Database

### Supabase (recommended)
- PostgreSQL with RLS (Row Level Security)
- Auth (email, magic link, OAuth)
- Realtime subscriptions
- Edge Functions (Deno)
- Storage (S3-compatible)

```bash
# Key commands
supabase db diff --schema public              # generate migration
supabase db push                              # apply to production
supabase gen types typescript --local > packages/types/db.types.ts
```

### Cloudflare D1 (alternative for Cloudflare-first)
- SQLite at the edge
- Works natively in Workers
- Good for simple CRUD, not complex queries

---

## Analytics & Revenue

### User Behavior
**PostHog** — funnels, DAU/MAU, retention cohorts, feature flags, A/B tests, session recording.

```typescript
// identify on every sign-in
posthog.identify(user.id, { email, name, plan })

// capture key events (verb_noun snake_case)
posthog.capture('subscription_started', { plan: 'pro' })
posthog.capture('project_created', { template: 'blank' })
```

### Errors & Performance
**Sentry** — errors + crashes + performance monitoring (web + mobile, same SDK pattern).

### Payments
- **Stripe** — web subscriptions and one-time payments
- **RevenueCat** — mobile in-app subscriptions (required for App Store / Google Play billing)
  - Apple and Google take 15-30% — RevenueCat manages entitlements across stores

### Business Dashboard
**Chartmogul** — aggregates Stripe + RevenueCat into one MRR/ARR/churn view.

**Connect everything from day 1.** Missing early data is the most common regret.

### Tool Summary
```
PostHog      → user behavior: how are users using the product?
Sentry       → errors: what's broken?
Stripe       → web money
RevenueCat   → mobile money (App Store + Google Play)
Chartmogul   → business health: MRR, churn, LTV
BetterUptime → uptime monitoring
```

---

## UI & Component Sharing

### Web
- **Tailwind CSS** — mandatory baseline
- **shadcn/ui** (Next.js) — best SaaS components, you own the code
- **Skeleton UI** or **Flowbite Svelte** (SvelteKit) — Svelte-native components

### Mobile (Expo)
- **NativeWind v4** — Tailwind syntax on React Native
- Write `className="text-blue-500 font-semibold"` identically on web and mobile

### What Can Be Shared (Turborepo Packages)

```
packages/
  types/        ← TypeScript types (works everywhere)
  validators/   ← Zod schemas (Expo + any web framework)
  db/           ← Supabase client (same @supabase/supabase-js everywhere)
  utils/        ← pure business logic (formatters, calculations)
  design/       ← design tokens (colors, spacing as JS constants)
```

JSX components **cannot** be shared between Next.js and Expo. But types + validators + Supabase + utils is 40-60% of the shared value anyway.

---

## Email Marketing

### Resend (transactional)
- API-first email sending
- React Email templates
- Reliable delivery with custom domains

### Loops.so (marketing automation)
- Event-triggered drip sequences
- Contact sync from Supabase
- Welcome, onboarding, trial-expiry, re-engagement flows

```typescript
// Sync contact on signup
await loops.createContact(user.email, { userId: user.id, plan: 'free' })

// Trigger sequence
await loops.sendEvent(user.email, 'trial_started', { trialEndDate })
```

---

## Deployment & Infrastructure

### Recommended by Framework

| App | Platform | Notes |
|-----|----------|-------|
| Astro landing | Cloudflare Pages | Zero cost, excellent performance |
| Next.js web app | Vercel | Best Next.js support |
| SvelteKit web app | Cloudflare Pages | Official adapter, edge SSR |
| Expo mobile | EAS (Expo Application Services) | OTA updates, build service |

### Cloudflare Ecosystem
| Product | Use |
|---------|-----|
| **Pages** | Astro + SvelteKit hosting |
| **R2** | Object storage (zero egress fees) |
| **Workers** | Edge API (use Hono) |
| **Turnstile** | Free CAPTCHA on forms |
| **KV** | Rate limiting, session storage |
| **WAF** | DDoS + firewall (free with Pages) |
| **Images** | Image CDN + resizing |

---

## Idea to Product Journey

### Phase 1: Validate
1. `/market-research` → `/product-spec`
2. Astro landing on Cloudflare Pages + email capture (Resend)
3. PostHog + Sentry on landing day 1
4. Get 10 people to say "I want this" before building

### Phase 2: Foundation
1. Turborepo scaffold (apps/ + packages/)
2. Supabase schema + RLS policies
3. Web app (Next.js or SvelteKit)
4. Stripe integration
5. PostHog identify + key events

### Phase 3: Core Product
1. `/saas-patterns` — multi-tenancy, billing, auth, onboarding
2. PostHog events + feature flags
3. Resend welcome emails + Loops onboarding sequence
4. `/security-audit` after every feature

### Phase 4: Mobile
1. Add Expo to Turborepo (`apps/mobile/`)
2. NativeWind + Expo Router
3. RevenueCat (App Store + Play Store)
4. EAS build + App Store / Play Store submission

### Phase 5: Grow
1. Chartmogul MRR dashboard
2. PostHog retention cohort analysis
3. SEO: Astro blog + Next.js/SvelteKit metadata
4. Loops.so campaigns
5. Growth experiments (growth-hacker agent)

---

## Claude Skills Reference

Skills activate with `/skill-name` or automatically when context matches.

### Web Development
| Skill | Trigger |
|-------|---------|
| `/nextjs` | Next.js App Router, server components, server actions |
| `/sveltekit` | SvelteKit routing, load functions, form actions |
| `/astro` | Astro static sites, content collections, islands |
| `/ui-design` | UI components, Tailwind, accessibility |

### Mobile
| Skill | Trigger |
|-------|---------|
| `/expo-mobile` | React Native + Expo, navigation, native APIs |
| `/revenuecat` | In-app subscriptions, App Store, Play Store |
| `/animations` | Framer Motion (web) + Reanimated + Moti (mobile) |

### Backend & Data
| Skill | Trigger |
|-------|---------|
| `/supabase` | Schema design, RLS, auth, queries, edge functions |
| `/saas-patterns` | Multi-tenancy, billing, onboarding |
| `/turborepo` | Monorepo setup, shared packages |
| `/sql` | PostgreSQL queries, optimization |

### Product & Business
| Skill | Trigger |
|-------|---------|
| `/market-research` | Market analysis, competitor research |
| `/product-spec` | PRDs, feature specs |
| `/landing-page` | High-converting landing pages |
| `/analytics-tracking` | PostHog, Sentry, RevenueCat events |
| `/email-marketing` | Resend + Loops.so setup and sequences |
| `/seo-content` | Metadata, Core Web Vitals, structured data |
| `/cloudflare` | Pages, R2, Workers, Turnstile, KV |

### Infrastructure & Security
| Skill | Trigger |
|-------|---------|
| `/security-audit` | OWASP checklist for SaaS stack |
| `/angular` | Angular + TypeScript (work projects) |
| `/csharp` | C#/.NET backend (work projects) |
| `/commit` | Git commit with conventional commits |

### Agents (auto-invoked by Claude)
| Agent | Purpose |
|-------|---------|
| `architect` | System design, tech stack decisions |
| `growth-hacker` | Viral loops, acquisition, retention experiments |
| `pricing-strategist` | Pricing tiers, WTP research, packaging |
| `product-manager` | PRDs, roadmaps, feature prioritization |
| `designer` | UI/UX design decisions |
| `frontend-developer` | React, CSS implementation |
| `backend-developer` | APIs, databases |
| `mobile-developer` | iOS, Android, React Native |
| `devops-engineer` | CI/CD, Docker, cloud infra |
| `security-engineer` | Threat modeling, security review |

---

## See Also

- `docs/CLAUDE_CODE_GUIDE.md` — Claude Code skills and agents reference
- `docs/MODERN_CLI_TOOLS.md` — CLI tools guide
- `config/claude/skills/` — Skill source files
- `config/claude/agents/` — Agent source files
