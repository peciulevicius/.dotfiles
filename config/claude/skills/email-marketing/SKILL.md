---
name: email-marketing
description: Resend (transactional email with React Email templates) + Loops.so (event-triggered drip sequences and campaigns). Welcome, onboarding, trial expiry, re-engagement flows. Use when setting up transactional email or marketing automation.
---

You are an email marketing expert for developer-built products. Use Resend for transactional email and Loops.so for marketing automation.

---

## Stack

| Tool | Purpose |
|------|---------|
| **Resend** | Transactional email (receipts, magic links, notifications) via API |
| **React Email** | React component templates for Resend |
| **Loops.so** | Event-triggered drip sequences + campaigns + contact management |

---

## Resend — Transactional Email

### Install
```bash
pnpm add resend @react-email/components
```

### Setup
```typescript
// lib/email.ts
import { Resend } from 'resend'
export const resend = new Resend(process.env.RESEND_API_KEY)
```

### React Email Template
```tsx
// emails/welcome.tsx
import {
  Body, Button, Container, Head, Html, Img,
  Preview, Section, Text, Hr
} from '@react-email/components'

interface WelcomeEmailProps {
  userName: string
  confirmUrl: string
}

export function WelcomeEmail({ userName, confirmUrl }: WelcomeEmailProps) {
  return (
    <Html>
      <Head />
      <Preview>Welcome to {APP_NAME}, {userName}!</Preview>
      <Body style={{ fontFamily: 'sans-serif', backgroundColor: '#f9fafb' }}>
        <Container style={{ maxWidth: '600px', margin: '0 auto', padding: '40px 20px' }}>
          <Text style={{ fontSize: '24px', fontWeight: 'bold', color: '#111827' }}>
            Welcome, {userName}!
          </Text>
          <Text style={{ color: '#6b7280', lineHeight: '1.6' }}>
            Thanks for signing up. Click below to confirm your email and get started.
          </Text>
          <Section style={{ textAlign: 'center', margin: '32px 0' }}>
            <Button
              href={confirmUrl}
              style={{
                backgroundColor: '#2563eb',
                color: '#fff',
                padding: '12px 24px',
                borderRadius: '6px',
                fontWeight: '600',
              }}
            >
              Confirm Email
            </Button>
          </Section>
          <Hr style={{ borderColor: '#e5e7eb' }} />
          <Text style={{ fontSize: '12px', color: '#9ca3af' }}>
            If you didn't sign up, ignore this email.
          </Text>
        </Container>
      </Body>
    </Html>
  )
}
```

### Send Email
```typescript
// app/api/auth/confirm/route.ts (or server action)
import { resend } from '@/lib/email'
import { WelcomeEmail } from '@/emails/welcome'
import { render } from '@react-email/render'

export async function sendWelcomeEmail(user: { email: string; name: string }) {
  const html = await render(WelcomeEmail({
    userName: user.name,
    confirmUrl: `${process.env.NEXT_PUBLIC_APP_URL}/confirm?token=...`,
  }))

  await resend.emails.send({
    from: 'Your App <hello@yourdomain.com>',
    to: user.email,
    subject: `Welcome to ${APP_NAME}!`,
    html,
  })
}
```

### Standard Email Templates to Create
```
emails/
  welcome.tsx              # After sign up — confirm email
  magic-link.tsx           # Passwordless login link
  invite.tsx               # Team member invitation
  subscription-receipt.tsx # Payment confirmation
  trial-ending.tsx         # 3 days before trial ends
  payment-failed.tsx       # Card declined
  reset-password.tsx       # Password reset link
```

### DNS Setup (Resend)
1. Add domain in Resend dashboard
2. Add SPF, DKIM, DMARC records to your DNS
3. Verify — this is required for deliverability

---

## Loops.so — Marketing Automation

Loops handles: drip sequences, campaigns, contact sync, unsubscribe management.

### Install SDK
```bash
pnpm add loops
```

### Setup
```typescript
// lib/loops.ts
import { LoopsClient } from 'loops'
export const loops = new LoopsClient(process.env.LOOPS_API_KEY!)
```

### Sync Contact on Sign Up
```typescript
// Call after user is created in Supabase
await loops.createContact(user.email, {
  userId: user.id,
  name: user.full_name,
  source: 'signup',
  plan: 'free',
  signedUpAt: new Date().toISOString(),
})
```

### Update Contact on Plan Change
```typescript
await loops.updateContact(user.email, {
  plan: 'pro',
  upgradedAt: new Date().toISOString(),
})
```

### Trigger Events (for automated sequences)
```typescript
// Trigger event → Loops runs the matching sequence
await loops.sendEvent(user.email, 'user_signed_up')
await loops.sendEvent(user.email, 'trial_started', { trialEndDate: endDate.toISOString() })
await loops.sendEvent(user.email, 'onboarding_completed')
await loops.sendEvent(user.email, 'first_project_created')
await loops.sendEvent(user.email, 'subscription_cancelled', { cancellationReason })
```

### Transactional Emails via Loops
```typescript
// For transactional emails you want tracked in Loops
await loops.sendTransactionalEmail({
  transactionalId: 'your-loops-template-id',
  email: user.email,
  dataVariables: {
    userName: user.name,
    resetUrl: 'https://...',
  },
})
```

---

## Email Sequences to Build

### 1. Welcome / Onboarding (Loops drip)
```
Day 0  → Welcome + confirm email (Resend transactional)
Day 1  → "Did you set up X?" — first key action prompt
Day 3  → Feature highlight: most-used feature
Day 7  → Case study / social proof
Day 14 → "How's it going?" — feedback ask
```

### 2. Trial Expiry (Loops drip, triggered by event)
```
7 days before  → "Your trial ends in 7 days" + upgrade CTA
3 days before  → Feature recap + what they'll lose
1 day before   → Urgency + discount offer (optional)
Day 0 (expired) → "Trial ended" + save work CTA
```

### 3. Churned User (Loops drip)
```
Day 1  → "We're sorry to see you go" + feedback survey
Day 7  → "Here's what's new since you left" (if improvements made)
Day 30 → Win-back offer (discount or extended trial)
```

### 4. Engagement Drip (Loops campaign)
```
Monthly → Product updates + changelog highlights
Quarterly → Case studies + customer stories
Ad hoc → New feature announcements
```

---

## Deliverability Checklist

- [ ] Custom domain configured in Resend (not resend.dev)
- [ ] SPF record: `v=spf1 include:amazonses.com ~all`
- [ ] DKIM records added and verified
- [ ] DMARC policy: `v=DMARC1; p=quarantine; rua=mailto:dmarc@yourdomain.com`
- [ ] From address is `name@yourdomain.com` (not gmail/outlook)
- [ ] Unsubscribe header present in all marketing emails
- [ ] List-Unsubscribe header for campaigns
- [ ] Test emails with mail-tester.com before launch

---

## Environment Variables
```bash
RESEND_API_KEY=re_...
LOOPS_API_KEY=...
NEXT_PUBLIC_APP_URL=https://yourapp.com
```
