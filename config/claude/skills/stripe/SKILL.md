---
name: stripe
description: Stripe web payments — Checkout Sessions, subscriptions, Customer Portal, webhooks, free trials, invoice handling. Use when implementing billing or payments in Next.js or SvelteKit.
---

## Setup

```typescript
// src/lib/stripe.ts
import Stripe from 'stripe'

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2024-06-20',
  typescript: true,
})
```

```bash
# Test webhooks locally
stripe listen --forward-to localhost:3000/api/webhooks/stripe
```

## Products & Prices

Set these up in the Stripe Dashboard, then store the price IDs in env vars:
```bash
STRIPE_PRICE_STARTER_MONTHLY=price_xxx
STRIPE_PRICE_PRO_MONTHLY=price_xxx
STRIPE_PRICE_PRO_YEARLY=price_xxx
```

Never hardcode price IDs in code — they differ between test and live environments.

## Checkout Session

```typescript
// src/app/api/billing/checkout/route.ts
export async function POST(req: Request) {
  const supabase = createServerClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const { priceId } = await req.json()

  // Get or create Stripe customer
  const { data: profile } = await supabase
    .from('profiles')
    .select('stripe_customer_id')
    .eq('id', user.id)
    .single()

  let customerId = profile?.stripe_customer_id
  if (!customerId) {
    const customer = await stripe.customers.create({
      email: user.email,
      metadata: { supabase_user_id: user.id },
    })
    customerId = customer.id
    await supabase
      .from('profiles')
      .update({ stripe_customer_id: customerId })
      .eq('id', user.id)
  }

  const session = await stripe.checkout.sessions.create({
    customer: customerId,
    mode: 'subscription',
    payment_method_types: ['card'],
    line_items: [{ price: priceId, quantity: 1 }],
    success_url: `${process.env.NEXT_PUBLIC_APP_URL}/dashboard?upgrade=success`,
    cancel_url: `${process.env.NEXT_PUBLIC_APP_URL}/pricing`,
    subscription_data: {
      trial_period_days: 14,  // remove if no trial
      metadata: { supabase_user_id: user.id },
    },
  })

  return NextResponse.json({ url: session.url })
}
```

## Customer Portal

```typescript
// src/app/api/billing/portal/route.ts
export async function POST(req: Request) {
  const supabase = createServerClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const { data: profile } = await supabase
    .from('profiles')
    .select('stripe_customer_id')
    .eq('id', user.id)
    .single()

  if (!profile?.stripe_customer_id) {
    return NextResponse.json({ error: 'No billing account' }, { status: 400 })
  }

  const session = await stripe.billingPortal.sessions.create({
    customer: profile.stripe_customer_id,
    return_url: `${process.env.NEXT_PUBLIC_APP_URL}/dashboard/billing`,
  })

  return NextResponse.json({ url: session.url })
}
```

## Webhooks

```typescript
// src/app/api/webhooks/stripe/route.ts
export async function POST(req: Request) {
  const body = await req.text()  // raw text — NOT req.json()
  const sig = req.headers.get('stripe-signature')!

  let event: Stripe.Event
  try {
    event = stripe.webhooks.constructEvent(body, sig, process.env.STRIPE_WEBHOOK_SECRET!)
  } catch {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 })
  }

  const supabase = createServiceClient()  // service role for webhook handlers

  switch (event.type) {
    case 'checkout.session.completed': {
      const session = event.data.object as Stripe.CheckoutSession
      await handleCheckoutCompleted(supabase, session)
      break
    }
    case 'customer.subscription.updated':
    case 'customer.subscription.deleted': {
      const sub = event.data.object as Stripe.Subscription
      await syncSubscription(supabase, sub)
      break
    }
    case 'invoice.payment_failed': {
      const invoice = event.data.object as Stripe.Invoice
      await handlePaymentFailed(supabase, invoice)
      break
    }
  }

  return NextResponse.json({ received: true })
}

async function syncSubscription(supabase: SupabaseClient, sub: Stripe.Subscription) {
  const userId = sub.metadata.supabase_user_id
  if (!userId) return

  await supabase.from('subscriptions').upsert({
    user_id: userId,
    stripe_subscription_id: sub.id,
    stripe_customer_id: sub.customer as string,
    status: sub.status,                              // active, trialing, past_due, canceled
    price_id: sub.items.data[0].price.id,
    current_period_end: new Date(sub.current_period_end * 1000).toISOString(),
    cancel_at_period_end: sub.cancel_at_period_end,
  }, { onConflict: 'user_id' })
}
```

## DB Schema

```sql
-- subscriptions table
create table subscriptions (
  id                      uuid primary key default gen_random_uuid(),
  user_id                 uuid references auth.users(id) on delete cascade unique,
  stripe_subscription_id  text unique,
  stripe_customer_id      text,
  status                  text not null,   -- active, trialing, past_due, canceled, incomplete
  price_id                text,
  current_period_end      timestamptz,
  cancel_at_period_end    boolean default false,
  created_at              timestamptz default now(),
  updated_at              timestamptz default now()
);

alter table subscriptions enable row level security;
create policy "Users read own subscription" on subscriptions
  for select using (user_id = auth.uid());

-- Add to profiles
alter table profiles add column stripe_customer_id text;
```

## Check Subscription Status

```typescript
// src/lib/billing.ts
export async function getSubscription(supabase: SupabaseClient) {
  const { data } = await supabase
    .from('subscriptions')
    .select('status, price_id, current_period_end, cancel_at_period_end')
    .single()

  const isActive = data?.status === 'active' || data?.status === 'trialing'
  return { subscription: data, isActive }
}
```

## Env Vars

```bash
STRIPE_SECRET_KEY=sk_test_...          # server only
STRIPE_WEBHOOK_SECRET=whsec_...        # server only
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...   # safe for browser
STRIPE_PRICE_STARTER_MONTHLY=price_...
STRIPE_PRICE_PRO_MONTHLY=price_...
```
