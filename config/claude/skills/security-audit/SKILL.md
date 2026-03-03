---
name: security-audit
description: OWASP security checklist for SaaS products. Supabase RLS verification, auth hardening, input validation, secret management, Stripe webhook security, CSP headers, XSS prevention, rate limiting, mobile token security, dependency auditing. Run after every major feature.
disable-model-invocation: true
---

Run a security audit on the current codebase. Work through each section systematically.

## Security Audit Checklist

### 1. Supabase Row Level Security (RLS)

Check every table:

```sql
-- Verify RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';

-- All tables should have rowsecurity = true
-- Check policies exist:
SELECT tablename, policyname, cmd, qual FROM pg_policies WHERE schemaname = 'public';
```

Questions to verify:
- [ ] RLS enabled on **every** table in the `public` schema?
- [ ] Every table has at least one policy (not just enabled but empty)?
- [ ] Policies tested with different user roles (anon, authenticated, service_role)?
- [ ] No `SECURITY DEFINER` functions that bypass RLS unintentionally?
- [ ] `auth.uid()` used correctly in policies (not `auth.jwt()` for row-level checks)?
- [ ] Organization/tenant isolation: resources filtered by org membership?

### 2. Authentication & Authorization

- [ ] All authenticated routes protected server-side (middleware, load functions, or server actions)?
- [ ] Session validated on **server** — never trust client-sent session/user data?
- [ ] JWT tokens validated via Supabase `getUser()` (not just `getSession()` which can use stale data)?
- [ ] Password reset tokens are single-use and expire quickly (< 1 hour)?
- [ ] Magic link tokens are single-use?
- [ ] OAuth state parameter validated to prevent CSRF?
- [ ] Refresh tokens stored securely (httpOnly cookies, not localStorage)?
- [ ] Account enumeration prevented (same response for "email not found" vs "wrong password")?

### 3. Input Validation

- [ ] **Every** API endpoint validates input with Zod (or equivalent)?
- [ ] **Every** form action validates input server-side (not just client-side)?
- [ ] File uploads: type, size, and extension validated?
- [ ] URL parameters sanitized before database queries?
- [ ] Pagination/limit params have maximum bounds (prevent `limit=999999`)?
- [ ] User IDs from requests cross-referenced against session user (never trust `userId` from body)?

```typescript
// Bad: trusts client-sent userId
const { userId } = await req.json()
await db.from('items').select().eq('user_id', userId)

// Good: uses session
const { data: { user } } = await supabase.auth.getUser()
await db.from('items').select().eq('user_id', user.id)
```

### 4. Secrets & Environment Variables

- [ ] `.env.local` in `.gitignore`?
- [ ] No secrets hardcoded in source files (API keys, passwords)?
- [ ] No `NEXT_PUBLIC_` / `PUBLIC_` prefix on server-only secrets?
- [ ] `SUPABASE_SERVICE_ROLE_KEY` only used server-side?
- [ ] `STRIPE_SECRET_KEY` only used server-side?
- [ ] Secrets rotated after any potential exposure?

```bash
# Check for potential secret leaks in codebase
grep -r "sk_live_\|sk_test_\|eyJ\|SUPABASE_SERVICE" src/ --include="*.ts" --include="*.tsx"
```

### 5. Stripe Webhook Security

- [ ] Webhook signature verified with `stripe.webhooks.constructEvent()`?
- [ ] Raw body used for signature verification (not parsed JSON)?
- [ ] Webhook endpoint returns 200 quickly, processes async?
- [ ] Idempotency handled (same event processed twice shouldn't double-charge)?

```typescript
// Required pattern
export async function POST(req: Request) {
  const body = await req.text()  // raw text, NOT req.json()
  const sig = req.headers.get('stripe-signature')!

  let event
  try {
    event = stripe.webhooks.constructEvent(body, sig, process.env.STRIPE_WEBHOOK_SECRET!)
  } catch (err) {
    return Response.json({ error: 'Invalid signature' }, { status: 400 })
  }
  // ...
}
```

### 6. Content Security Policy (CSP)

- [ ] CSP headers configured?
- [ ] `script-src` doesn't include `unsafe-inline` or `unsafe-eval` unnecessarily?
- [ ] External script domains allowlisted (PostHog, Sentry, Stripe)?

```typescript
// next.config.ts
const ContentSecurityPolicy = `
  default-src 'self';
  script-src 'self' 'nonce-{nonce}' https://js.stripe.com https://challenges.cloudflare.com;
  connect-src 'self' https://*.supabase.co https://api.stripe.com;
  frame-src https://js.stripe.com;
  img-src 'self' data: https:;
`.replace(/\n/g, '')

// SvelteKit: set in hooks.server.ts via setHeaders
```

### 7. XSS Prevention

- [ ] User-generated HTML sanitized with DOMPurify before rendering?
- [ ] `dangerouslySetInnerHTML` (React) only used with sanitized content?
- [ ] `{@html}` (Svelte) only used with sanitized content?
- [ ] Svelte escapes by default — are you using `{@html}` anywhere unnecessarily?

```typescript
import DOMPurify from 'isomorphic-dompurify'

// Before rendering user HTML
const safeHtml = DOMPurify.sanitize(userContent, {
  ALLOWED_TAGS: ['p', 'b', 'i', 'a', 'ul', 'ol', 'li'],
  ALLOWED_ATTR: ['href'],
})
```

### 8. Rate Limiting

- [ ] Auth endpoints rate-limited (login, signup, password reset)?
- [ ] Email sending rate-limited per user?
- [ ] API endpoints rate-limited?
- [ ] Rate limiting is server-side (not just client-side)?

```typescript
// Upstash Redis rate limiting (Next.js)
import { Ratelimit } from '@upstash/ratelimit'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '10 s'),  // 10 req per 10s
})

const { success } = await ratelimit.limit(ip)
if (!success) return Response.json({ error: 'Too many requests' }, { status: 429 })
```

### 9. Mobile Security (Expo)

- [ ] Auth tokens stored in `expo-secure-store` (NOT AsyncStorage)?
- [ ] No API keys or secrets in the app bundle (check `app.json` and `constants/`)?
- [ ] Certificate pinning configured for sensitive APIs?
- [ ] Deep link URL validation prevents open redirects?
- [ ] Biometric authentication used for sensitive operations?

```typescript
import * as SecureStore from 'expo-secure-store'

// Store token securely
await SecureStore.setItemAsync('auth_token', token)

// Retrieve
const token = await SecureStore.getItemAsync('auth_token')

// Bad: never use AsyncStorage for sensitive data
// AsyncStorage is plaintext on device
```

### 10. Dependencies

```bash
# Check for vulnerabilities
npm audit --audit-level=high

# Or with pnpm
pnpm audit --audit-level=high

# Update outdated dependencies
pnpm outdated

# Check for known malicious packages
npx is-website-vulnerable https://yoursite.com
```

- [ ] `npm audit` shows zero high/critical vulnerabilities?
- [ ] Dependencies updated within last 3 months?
- [ ] Lock file committed to git?
- [ ] No packages from untrusted sources?

---

## Summary Report Format

After completing the checklist, provide:

```
## Security Audit Results — [Date]

### ✅ Passed (X items)
- RLS enabled on all tables
- Webhook signatures verified
- ...

### ⚠️ Issues Found (X items)
- [CRITICAL] Description + file:line + fix
- [HIGH] Description + file:line + fix
- [MEDIUM] Description + recommendation

### 📋 Not Applicable
- Mobile security (no mobile app yet)
- ...

### Recommended Next Steps
1. Fix CRITICAL items immediately
2. Schedule HIGH items for this sprint
3. Add MEDIUM items to backlog
```
