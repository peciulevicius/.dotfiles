---
name: analytics-tracking
description: PostHog setup + identify + capture events + feature flags + session recording. Sentry error boundaries + performance monitoring. Event naming conventions. RevenueCat events. Chartmogul Stripe connection. Use when adding analytics, error tracking, or revenue monitoring to any app.
---

You are an analytics and observability expert. Apply these patterns for PostHog, Sentry, RevenueCat, and Chartmogul.

## Install Everything Day 1 — Missing Early Data Is the Most Common Regret

---

## PostHog — User Behavior Analytics

### Install (Next.js)
```bash
pnpm add posthog-js posthog-node
```

```typescript
// lib/posthog.ts — client
import posthog from 'posthog-js'

export function initPostHog() {
  if (typeof window === 'undefined') return
  posthog.init(process.env.NEXT_PUBLIC_POSTHOG_KEY!, {
    api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST ?? 'https://app.posthog.com',
    capture_pageview: false,  // manual in App Router
    capture_pageleave: true,
    session_recording: { maskAllInputs: true },
  })
}

// lib/posthog-server.ts — server
import { PostHog } from 'posthog-node'
export const posthogServer = new PostHog(process.env.POSTHOG_KEY!, {
  host: process.env.POSTHOG_HOST ?? 'https://app.posthog.com',
})
```

```tsx
// providers/posthog-provider.tsx
'use client'
import posthog from 'posthog-js'
import { PostHogProvider } from 'posthog-js/react'
import { useEffect } from 'react'

export function PHProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => { initPostHog() }, [])
  return <PostHogProvider client={posthog}>{children}</PostHogProvider>
}
```

### Identify Users (on sign-in)
```typescript
import posthog from 'posthog-js'

// After successful auth
posthog.identify(user.id, {
  email: user.email,
  name: user.full_name,
  plan: subscription.plan,
  created_at: user.created_at,
  organization_id: org.id,
  organization_name: org.name,
})

// On sign-out
posthog.reset()
```

### Capture Events
```typescript
// Event naming: verb_noun in snake_case
posthog.capture('user_signed_up', { method: 'email' })
posthog.capture('project_created', { template: 'blank' })
posthog.capture('subscription_started', { plan: 'pro', billing: 'annual' })
posthog.capture('feature_used', { feature: 'export', format: 'pdf' })
posthog.capture('onboarding_step_completed', { step: 'invite_team', step_number: 2 })
posthog.capture('payment_failed', { reason: 'insufficient_funds' })

// Never capture PII as event names — use properties
// Bad: posthog.capture('john@email.com signed up')
// Good: posthog.capture('user_signed_up', { method: 'google' })
```

### Feature Flags
```typescript
// Client-side
const isEnabled = posthog.isFeatureEnabled('new-dashboard')
const variant = posthog.getFeatureFlag('pricing-experiment') // 'control' | 'variant-a'

// React hook
import { useFeatureFlagEnabled } from 'posthog-js/react'
const showBeta = useFeatureFlagEnabled('beta-feature')

// Server-side (Next.js)
const flags = await posthogServer.getAllFlags(userId)
const isEnabled = flags['new-feature'] === true
```

### Page View Tracking (Next.js App Router)
```tsx
'use client'
import { usePathname, useSearchParams } from 'next/navigation'
import { usePostHog } from 'posthog-js/react'
import { useEffect } from 'react'

export function PostHogPageView() {
  const pathname = usePathname()
  const searchParams = useSearchParams()
  const posthog = usePostHog()

  useEffect(() => {
    if (pathname && posthog) {
      posthog.capture('$pageview', {
        $current_url: window.location.href,
      })
    }
  }, [pathname, searchParams, posthog])

  return null
}
```

### Install (Expo/React Native)
```bash
npx expo install posthog-react-native
```
```tsx
import PostHog, { PostHogProvider } from 'posthog-react-native'

const client = new PostHog(process.env.EXPO_PUBLIC_POSTHOG_KEY!, {
  host: 'https://app.posthog.com',
})

// Wrap app
<PostHogProvider client={client}>
  <App />
</PostHogProvider>

// Usage
const posthog = usePostHog()
posthog.identify(user.id, { email: user.email })
posthog.capture('screen_viewed', { screen: 'Dashboard' })
```

---

## Sentry — Errors + Performance

### Install (Next.js)
```bash
pnpm add @sentry/nextjs
npx @sentry/wizard@latest -i nextjs
```

```typescript
// sentry.client.config.ts
import * as Sentry from '@sentry/nextjs'

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 0.1,        // 10% of transactions
  replaysOnErrorSampleRate: 1.0, // 100% on errors
  replaysSessionSampleRate: 0.1, // 10% of sessions
  integrations: [Sentry.replayIntegration()],
})
```

### Error Boundaries
```tsx
import * as Sentry from '@sentry/nextjs'

// Wrap risky sections
<Sentry.ErrorBoundary fallback={<ErrorFallback />}>
  <RiskyComponent />
</Sentry.ErrorBoundary>

// app/error.tsx (Next.js)
'use client'
export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  useEffect(() => { Sentry.captureException(error) }, [error])
  return <div>Something went wrong. <button onClick={reset}>Retry</button></div>
}
```

### Identify Users (link errors to users)
```typescript
Sentry.setUser({ id: user.id, email: user.email })
// On sign-out:
Sentry.setUser(null)
```

### Manual Error Capture
```typescript
try {
  await riskyOperation()
} catch (error) {
  Sentry.captureException(error, {
    tags: { feature: 'export', format: 'pdf' },
    extra: { userId, resourceId },
  })
  throw error
}
```

### Install (Expo)
```bash
npx expo install @sentry/react-native
```
```typescript
import * as Sentry from '@sentry/react-native'
Sentry.init({ dsn: process.env.EXPO_PUBLIC_SENTRY_DSN, tracesSampleRate: 0.2 })
```

---

## RevenueCat Events → PostHog/Chartmogul

Set up RevenueCat webhooks to your backend, then:
```typescript
// app/api/webhooks/revenuecat/route.ts
export async function POST(req: Request) {
  const event = await req.json()
  const { type, app_user_id, product_id, price_in_purchased_currency } = event

  if (type === 'INITIAL_PURCHASE') {
    await posthogServer.capture({
      distinctId: app_user_id,
      event: 'subscription_started_mobile',
      properties: { product_id, revenue: price_in_purchased_currency },
    })
  }

  if (type === 'CANCELLATION') {
    await posthogServer.capture({
      distinctId: app_user_id,
      event: 'subscription_cancelled_mobile',
      properties: { product_id },
    })
  }

  return Response.json({ received: true })
}
```

---

## Chartmogul — Revenue Dashboard

Connect Stripe directly (no code needed):
1. Chartmogul Settings → Integrations → Stripe → Connect
2. Historical data imports automatically
3. RevenueCat: Settings → Integrations → Chartmogul → add Data Source UUID

Key metrics to watch: MRR, ARR, Churn Rate, LTV, ARPU, Net Revenue Retention.

---

## Event Naming Conventions

```
Pattern: verb_noun (snake_case)

Auth:       user_signed_up, user_signed_in, user_signed_out, password_reset_requested
Onboarding: onboarding_started, onboarding_step_completed, onboarding_completed, onboarding_skipped
Billing:    subscription_started, subscription_upgraded, subscription_downgraded, subscription_cancelled, payment_failed
Features:   [feature]_used, [feature]_created, [feature]_deleted, [feature]_shared
Growth:     invite_sent, invite_accepted, referral_clicked
Errors:     error_shown (with error_type property)

Properties: always add context
  - plan: 'free' | 'pro' | 'enterprise'
  - source: where the action came from
  - method: how (e.g., 'email' | 'google' | 'github')
```

---

## Checklist: Analytics Setup Complete When...

- [ ] PostHog initialized on first page load
- [ ] `identify()` called on every sign-in
- [ ] `reset()` called on every sign-out
- [ ] Key conversion events captured (sign_up, subscription_started)
- [ ] Sentry DSN configured for both client + server
- [ ] Sentry user context set on sign-in
- [ ] Error boundaries on critical sections
- [ ] RevenueCat webhook handler live (if mobile)
- [ ] Chartmogul connected to Stripe
