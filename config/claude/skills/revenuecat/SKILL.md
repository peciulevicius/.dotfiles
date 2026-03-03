---
name: revenuecat
description: Mobile subscription setup with RevenueCat for App Store + Google Play. Entitlements, offerings, React Native SDK, purchase flows, restore purchases, entitlement checks, webhook handler, Chartmogul connection. Use when implementing in-app subscriptions on iOS or Android.
---

You are a mobile monetization expert. Use RevenueCat to manage in-app subscriptions across iOS and Android.

## Why RevenueCat (Not Direct StoreKit/BillingClient)

- Handles Apple StoreKit 2 + Google Play Billing in one SDK
- Manages entitlements (what user can access) independently of store receipts
- Provides webhooks for subscription events (purchase, renewal, cancel, grace period)
- Connects to Chartmogul, Amplitude, PostHog, Mixpanel out of the box
- Required for proper cross-platform subscription state — stores don't talk to each other

---

## Setup

### 1. Install
```bash
npx expo install react-native-purchases react-native-purchases-ui
```

### 2. Configure (App.tsx or _layout.tsx)
```typescript
import Purchases, { LOG_LEVEL } from 'react-native-purchases'
import { Platform } from 'react-native'

async function initRevenueCat(userId?: string) {
  if (__DEV__) {
    Purchases.setLogLevel(LOG_LEVEL.DEBUG)
  }

  const apiKey = Platform.select({
    ios: process.env.EXPO_PUBLIC_REVENUECAT_IOS_KEY!,
    android: process.env.EXPO_PUBLIC_REVENUECAT_ANDROID_KEY!,
  })!

  await Purchases.configure({ apiKey })

  // Identify user (call after authentication)
  if (userId) {
    await Purchases.logIn(userId)
  }
}
```

### 3. Identify User (after sign-in)
```typescript
import Purchases from 'react-native-purchases'

// After Supabase auth sign-in
async function onUserSignedIn(userId: string) {
  const { customerInfo } = await Purchases.logIn(userId)
  // customerInfo.entitlements.active tells you what user has access to
}

// After sign-out
async function onUserSignedOut() {
  await Purchases.logOut()
}
```

---

## Entitlements & Offerings

### Dashboard Setup (RevenueCat Dashboard)
1. **Products** → Add App Store + Play Store product IDs
2. **Entitlements** → Create `pro` entitlement, attach products
3. **Offerings** → Create `default` offering with packages (monthly, annual)

### Fetch Offerings
```typescript
import Purchases, { PurchasesOffering } from 'react-native-purchases'

async function fetchOfferings(): Promise<PurchasesOffering | null> {
  try {
    const offerings = await Purchases.getOfferings()
    return offerings.current  // null if not configured in dashboard
  } catch (e) {
    console.error('Error fetching offerings', e)
    return null
  }
}
```

### Check Entitlement (Gate Features)
```typescript
import Purchases from 'react-native-purchases'

async function checkProAccess(): Promise<boolean> {
  try {
    const customerInfo = await Purchases.getCustomerInfo()
    return typeof customerInfo.entitlements.active['pro'] !== 'undefined'
  } catch (e) {
    return false  // fail open in debug, fail closed in prod
  }
}

// React hook for real-time entitlement status
import { useEffect, useState } from 'react'

export function usePurchases() {
  const [isPro, setIsPro] = useState(false)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    Purchases.getCustomerInfo()
      .then((info) => {
        setIsPro(typeof info.entitlements.active['pro'] !== 'undefined')
      })
      .finally(() => setIsLoading(false))

    // Listen for real-time updates (e.g., subscription renewed)
    const listener = Purchases.addCustomerInfoUpdateListener((info) => {
      setIsPro(typeof info.entitlements.active['pro'] !== 'undefined')
    })

    return () => listener.remove()
  }, [])

  return { isPro, isLoading }
}
```

---

## Purchase Flow

### Paywall Screen
```typescript
import Purchases, { PurchasesPackage, PURCHASES_ERROR_CODE } from 'react-native-purchases'

async function purchasePackage(pkg: PurchasesPackage) {
  try {
    const { customerInfo } = await Purchases.purchasePackage(pkg)

    if (typeof customerInfo.entitlements.active['pro'] !== 'undefined') {
      // Purchase successful — unlock features
      router.replace('/dashboard')
    }
  } catch (e: any) {
    if (e.code === PURCHASES_ERROR_CODE.PURCHASE_CANCELLED_ERROR) {
      // User cancelled — do nothing
      return
    }
    // Actual error
    Alert.alert('Purchase Failed', e.message)
  }
}

// Restore purchases (required by App Store guidelines)
async function restorePurchases() {
  try {
    const customerInfo = await Purchases.restorePurchases()
    const isPro = typeof customerInfo.entitlements.active['pro'] !== 'undefined'

    if (isPro) {
      Alert.alert('Restored!', 'Your subscription has been restored.')
    } else {
      Alert.alert('Nothing to restore', 'No active subscriptions found.')
    }
  } catch (e: any) {
    Alert.alert('Error', e.message)
  }
}
```

### RevenueCat Paywall UI (pre-built)
```tsx
import RevenueCatUI, { PAYWALL_RESULT } from 'react-native-purchases-ui'

// Present a paywall configured in the RevenueCat dashboard
async function showPaywall() {
  const result = await RevenueCatUI.presentPaywallIfNeeded({
    requiredEntitlementIdentifier: 'pro',
  })

  switch (result) {
    case PAYWALL_RESULT.PURCHASED:
    case PAYWALL_RESULT.RESTORED:
      // User subscribed or restored
      break
    case PAYWALL_RESULT.CANCELLED:
      // User dismissed
      break
  }
}
```

---

## Webhook Handler (Backend)

```typescript
// app/api/webhooks/revenuecat/route.ts (Next.js)
import { posthogServer } from '@/lib/posthog-server'
import { supabaseAdmin } from '@/lib/supabase-admin'

const REVENUECAT_WEBHOOK_AUTH = process.env.REVENUECAT_WEBHOOK_AUTH!

export async function POST(req: Request) {
  // Verify auth header
  const authHeader = req.headers.get('Authorization')
  if (authHeader !== REVENUECAT_WEBHOOK_AUTH) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const event = await req.json()
  const { type, app_user_id, product_id, price_in_purchased_currency, currency } = event.event

  switch (type) {
    case 'INITIAL_PURCHASE':
      await supabaseAdmin.from('profiles').update({ plan: 'pro' }).eq('id', app_user_id)
      await posthogServer.capture({
        distinctId: app_user_id,
        event: 'subscription_started_mobile',
        properties: { product_id, revenue: price_in_purchased_currency, currency },
      })
      break

    case 'RENEWAL':
      await posthogServer.capture({
        distinctId: app_user_id,
        event: 'subscription_renewed_mobile',
        properties: { product_id },
      })
      break

    case 'CANCELLATION':
      // Note: access continues until period end — don't downgrade yet
      await posthogServer.capture({
        distinctId: app_user_id,
        event: 'subscription_cancelled_mobile',
        properties: { product_id },
      })
      break

    case 'EXPIRATION':
      // Access actually ends — downgrade now
      await supabaseAdmin.from('profiles').update({ plan: 'free' }).eq('id', app_user_id)
      break

    case 'BILLING_ISSUE':
      // Payment failed — notify user
      break
  }

  return Response.json({ received: true })
}
```

### Set Webhook in RevenueCat Dashboard
1. Project Settings → Webhooks → Add Webhook
2. URL: `https://yourapp.com/api/webhooks/revenuecat`
3. Authorization: set a secret and add to `REVENUECAT_WEBHOOK_AUTH` env var

---

## Chartmogul Integration

In RevenueCat Dashboard → Integrations → Chartmogul:
1. Add your Chartmogul API key
2. Add your Chartmogul Data Source UUID
3. RevenueCat automatically syncs subscription events → Chartmogul
4. View mobile revenue alongside Stripe in Chartmogul MRR dashboard

---

## Environment Variables
```bash
EXPO_PUBLIC_REVENUECAT_IOS_KEY=appl_...
EXPO_PUBLIC_REVENUECAT_ANDROID_KEY=goog_...
REVENUECAT_WEBHOOK_AUTH=your_secret_here
```

---

## Testing

RevenueCat provides a **sandbox environment**:
- iOS: use sandbox App Store accounts (Settings → App Store → Sandbox Account)
- Android: use Google Play test tracks
- RevenueCat dashboard → Customer → search by user ID to debug purchase state

```typescript
// In __DEV__, you can also use Purchases.setSimulatesAskToBuyInSandbox(true) for iOS
```

---

## Checklist

- [ ] RevenueCat project created for iOS + Android
- [ ] Products configured in App Store Connect + Google Play Console
- [ ] Entitlements created (`pro`) in RevenueCat dashboard
- [ ] Default offering configured with packages
- [ ] SDK initialized on app start
- [ ] `logIn(userId)` called after authentication
- [ ] `logOut()` called on sign-out
- [ ] Purchase flow with error handling implemented
- [ ] Restore purchases button on paywall (App Store requirement)
- [ ] Webhook endpoint live + authorized
- [ ] Chartmogul connected
- [ ] Sandbox purchases tested on both platforms
