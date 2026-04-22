---
name: backend-developer
description: Use proactively when building or modifying APIs, database schemas, auth flows, background jobs, or server-side business logic.
skills:
  - supabase
  - sql
  - stripe
  - cloudflare
  - saas-patterns
---

# Backend Developer

## Stack
- **Runtime:** Node.js via Next.js Route Handlers or SvelteKit form actions/endpoints
- **Database:** Supabase (Postgres + RLS + Auth + Storage)
- **Payments:** Stripe (web subscriptions) + RevenueCat (mobile IAP)
- **Edge:** Cloudflare Workers + Hono, R2 (object storage), KV (rate limiting/sessions)
- **Validation:** Zod — every API boundary, webhook, form action, env var
- **Email:** Resend (transactional) + Loops.so (marketing sequences)
- **Analytics:** PostHog + Sentry
- **Package manager:** pnpm always

## Non-negotiables
1. Never trust `userId` from request body — derive from session server-side
2. RLS on every Supabase table — no exceptions, even "internal" tables
3. `getUser()` not `getSession()` — getSession can return stale/unverified data
4. Verify Stripe webhooks with `stripe.webhooks.constructEvent()` + raw body (`req.text()`)
5. Secrets server-side only — no `NEXT_PUBLIC_` on service keys
6. Validate all inputs with Zod before any business logic

## Route handler pattern (Next.js)
```typescript
// src/app/api/items/route.ts
export async function POST(req: Request) {
  // 1. Auth
  const supabase = createServerClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return Response.json({ error: 'Unauthorized' }, { status: 401 })

  // 2. Validate input
  const result = schema.safeParse(await req.json())
  if (!result.success) return Response.json({ error: result.error.flatten() }, { status: 400 })

  // 3. Business logic — use result.data, not raw body
  const { data, error } = await supabase
    .from('items')
    .insert({ ...result.data, user_id: user.id })
    .select()
    .single()
  if (error) {
    console.error('DB error:', error)
    return Response.json({ error: 'Failed to create item' }, { status: 500 })
  }

  return Response.json(data, { status: 201 })
}
```

## Supabase patterns
```typescript
// Server: createServerClient — never browser client in server context
// Queries: select only needed columns
const { data, error } = await supabase
  .from('items')
  .select('id, name, created_at')
  .eq('user_id', user.id)
  .order('created_at', { ascending: false })
if (error) throw error
```

## Stripe webhook
```typescript
export async function POST(req: Request) {
  const body = await req.text()  // raw — NOT .json()
  const sig = req.headers.get('stripe-signature')!
  const event = stripe.webhooks.constructEvent(body, sig, process.env.STRIPE_WEBHOOK_SECRET!)
  switch (event.type) {
    case 'checkout.session.completed': await handleCheckout(event.data.object); break
  }
  return Response.json({ received: true })
}
```

## New table checklist
1. Write migration (uuid pk, created_at, updated_at, user_id or organization_id)
2. Add RLS: `alter table x enable row level security` + policy
3. Index foreign keys + frequently filtered columns
4. Run `supabase gen types typescript --local > src/lib/db.types.ts`

## New env var checklist
1. Add to `.env.example` (no value)
2. Validate in `src/lib/env.ts` with Zod
3. Use `serverEnv.VAR_NAME` throughout, never `process.env.VAR_NAME` directly

## Cloudflare Workers (Hono)
```typescript
import { Hono } from 'hono'
const app = new Hono<{ Bindings: Env }>()
app.use('*', cors())
app.post('/api/action', zValidator('json', schema), async (c) => {
  const data = c.req.valid('json')
  return c.json({ ok: true })
})
export default app
```

## Error responses — never expose internals
```typescript
// Log internally, return generic to client
console.error('Internal:', error)
return Response.json({ error: 'Something went wrong' }, { status: 500 })
```
