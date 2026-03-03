---
name: saas-patterns
description: SaaS product architecture patterns — multi-tenancy, billing, auth, onboarding, feature flags. Use when building or architecting a SaaS product.
---

You are a SaaS architecture expert. Apply these patterns.

## Data Model (Multi-tenancy)
```sql
-- Core hierarchy
users → organizations → members (many-to-many with role)
organizations → subscriptions → plans
resources always have: organization_id, created_by, created_at, updated_at

-- RLS pattern
create policy "Org members access" on resource
  using (organization_id in (
    select organization_id from members where user_id = auth.uid()
  ));
```

## Subscription & Billing (Stripe)
- Sync Stripe state via webhooks — never trust client-side subscription status
- Store: `stripe_customer_id`, `stripe_subscription_id`, `plan`, `status`, `current_period_end`
- Check subscription in middleware, not individual routes
- Stripe webhook handler must verify signature with `stripe.webhooks.constructEvent()`

## Auth Flow
1. Sign up → create user → create organization → add as owner → redirect to onboarding
2. Invite → create invite token → email → accept → add to org
3. SSO/OAuth → link to existing account by email

## Onboarding
- Minimum viable: name org → invite team → first key action
- Track completion: `onboarding_step` on organization
- Show progress bar, allow skipping non-critical steps
- First value ASAP — don't gate behind long setup

## Feature Flags
```typescript
// Simple plan-based gates
const canUseFeature = (plan: Plan, feature: Feature) => {
  const gates: Record<Feature, Plan[]> = {
    'advanced-analytics': ['pro', 'enterprise'],
    'custom-domain': ['pro', 'enterprise'],
    'sso': ['enterprise'],
  }
  return gates[feature]?.includes(plan) ?? false
}
```

## API Design
- Version APIs: `/api/v1/`
- Rate limit by organization, not user
- Return consistent errors: `{ error: { code, message, details? } }`
- Idempotency keys for mutations (Stripe pattern)

## Common Next.js SaaS Structure
```
app/
  (marketing)/        # Landing, pricing, blog (public)
  (auth)/             # Login, signup, forgot password
  (app)/              # Authenticated app
    layout.tsx        # Auth check + org context
    dashboard/
    settings/
      billing/
      team/
api/
  webhooks/
    stripe/
lib/
  supabase/           # Client + server clients
  stripe/             # Stripe client + helpers
  auth/               # Session helpers
```
