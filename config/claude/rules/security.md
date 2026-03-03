# Security Rules

## The Non-Negotiables

1. **Never trust client-sent user/org IDs** — always derive from session server-side
2. **RLS on every table** — no exceptions, even "internal" tables
3. **Validate every input with Zod** — API routes, server actions, form actions, webhooks
4. **Secrets server-side only** — no `NEXT_PUBLIC_` on service keys
5. **Verify Stripe webhooks** — always `stripe.webhooks.constructEvent()` with raw body

## Auth
```typescript
// Always use getUser() not getSession() for server-side auth
// getSession() can return stale/unverified data
const { data: { user }, error } = await supabase.auth.getUser()
if (!user || error) redirect('/login')

// Never trust userId from request body
// Bad:
const { userId } = await req.json()
// Good:
const { data: { user } } = await supabase.auth.getUser()
const userId = user.id
```

## Secrets
```bash
# .env.local — never commit
SUPABASE_SERVICE_ROLE_KEY=...   # server only
STRIPE_SECRET_KEY=...           # server only
RESEND_API_KEY=...              # server only

# Public (safe in browser)
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=...
```

```typescript
// Validate env vars at startup
const env = z.object({
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  STRIPE_SECRET_KEY: z.string().startsWith('sk_'),
}).parse(process.env)
```

## API Input Validation
```typescript
// Every route handler and server action validates input
export async function POST(req: Request) {
  const body = await req.json()
  const result = schema.safeParse(body)
  if (!result.success) {
    return Response.json({ error: result.error.flatten() }, { status: 400 })
  }
  // use result.data — typed and validated
}
```

## Stripe Webhooks
```typescript
export async function POST(req: Request) {
  const body = await req.text()  // raw text — NOT req.json()
  const sig = req.headers.get('stripe-signature')!

  let event
  try {
    event = stripe.webhooks.constructEvent(body, sig, process.env.STRIPE_WEBHOOK_SECRET!)
  } catch {
    return Response.json({ error: 'Invalid signature' }, { status: 400 })
  }
  // process event.type
}
```

## Rate Limiting (auth endpoints)
```typescript
// Use Upstash Redis or Cloudflare KV
// Apply to: /api/auth/*, password reset, email sending, public APIs
const { success } = await ratelimit.limit(ip)
if (!success) return Response.json({ error: 'Too many requests' }, { status: 429 })
```

## XSS
```typescript
// Never render user HTML without sanitizing
import DOMPurify from 'isomorphic-dompurify'
const safe = DOMPurify.sanitize(userHtml, { ALLOWED_TAGS: ['p', 'b', 'i', 'a'] })

// In Next.js: avoid dangerouslySetInnerHTML — if needed, always sanitize first
// In Svelte: avoid {@html} — if needed, always sanitize first
// Svelte escapes {variable} by default ✓
```

## Mobile (Expo)
```typescript
// Auth tokens in SecureStore — NOT AsyncStorage
import * as SecureStore from 'expo-secure-store'
await SecureStore.setItemAsync('session', token)

// No secrets in app bundle — they're extractable
// Use server-side APIs instead of calling external services directly from the app
```

## Dependency Audit
```bash
pnpm audit --audit-level=high   # before shipping
pnpm outdated                   # monthly review
```
