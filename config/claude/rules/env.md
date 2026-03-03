# Environment Variables Rules

## Naming Conventions

```bash
# Next.js
NEXT_PUBLIC_*     # exposed to browser — safe for anon keys, public URLs, publishable keys
# (no prefix)     # server-only — secrets, service role keys, API keys with write access

# SvelteKit
PUBLIC_*          # exposed to browser
# (no prefix)     # server-only

# Expo
EXPO_PUBLIC_*     # bundled into app — treat as public, no secrets
```

## What Goes Where

```bash
# ✅ Safe for NEXT_PUBLIC_ / browser
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...        # read-only with RLS
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
NEXT_PUBLIC_APP_URL=https://myapp.com
NEXT_PUBLIC_POSTHOG_KEY=phc_...

# ❌ Server-only — never NEXT_PUBLIC_
SUPABASE_SERVICE_ROLE_KEY=eyJ...            # bypasses RLS
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
RESEND_API_KEY=re_...
OPENAI_API_KEY=sk-...
DATABASE_URL=postgresql://...
```

## Validate at Startup

```typescript
// src/lib/env.ts — validate all env vars at startup, fail fast
import { z } from 'zod'

const serverSchema = z.object({
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  STRIPE_SECRET_KEY: z.string().startsWith('sk_'),
  STRIPE_WEBHOOK_SECRET: z.string().startsWith('whsec_'),
  RESEND_API_KEY: z.string().min(1),
  DATABASE_URL: z.string().url(),
})

const clientSchema = z.object({
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1),
  NEXT_PUBLIC_APP_URL: z.string().url(),
})

// Throws at startup if anything is missing — fail fast, not silently
export const serverEnv = serverSchema.parse(process.env)
export const clientEnv = clientSchema.parse({
  NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
  // ... map each one explicitly (tree-shaking + type safety)
})
```

## File Structure

```bash
.env                  # committed — defaults, non-secret shared config
.env.local            # NOT committed — local overrides, secrets for dev
.env.production       # NOT committed — production secrets
.env.example          # committed — template showing what vars are needed (no values)
```

```bash
# .env.example (always keep this updated)
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=
SUPABASE_SERVICE_ROLE_KEY=
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
RESEND_API_KEY=
DATABASE_URL=
```

## .gitignore

```gitignore
.env.local
.env.production
.env.*.local
# Never commit actual secrets
```

## Multiple Environments

```bash
# Use different Stripe modes, not different keys
# test mode (local/staging): sk_test_... + pk_test_...
# live mode (production):     sk_live_... + pk_live_...

# Supabase: separate projects for dev and prod
# dev: .env.local → https://xxxdev.supabase.co
# prod: Vercel env vars → https://xxxprod.supabase.co

# Never point local dev at production DB
```

## Vercel / Cloudflare — Setting Env Vars

```bash
# Vercel CLI
vercel env add STRIPE_SECRET_KEY production
vercel env add STRIPE_SECRET_KEY preview
vercel env pull .env.local   # pull remote vars to local

# Cloudflare Pages
wrangler pages secret put STRIPE_SECRET_KEY
```

## Type-Safe Access

```typescript
// Don't access process.env directly throughout the codebase
// Import from the validated env module

// BAD: scattered, no validation
const key = process.env.STRIPE_SECRET_KEY!   // ! is a lie

// GOOD: validated once at startup
import { serverEnv } from '@/lib/env'
const stripe = new Stripe(serverEnv.STRIPE_SECRET_KEY)
```
