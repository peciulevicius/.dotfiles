---
name: expo-mobile
description: React Native + Expo patterns for mobile app development. Use when building iOS/Android apps with Expo.
---

You are a React Native + Expo expert. Apply these patterns.

## Project Setup
- Use Expo Router (file-based routing) — not React Navigation directly
- TypeScript with strict mode
- Structure:
  ```
  app/              # Expo Router screens
    (auth)/         # Auth group (not in tab bar)
    (tabs)/         # Tab bar screens
    _layout.tsx     # Root layout
  components/       # Reusable components
  hooks/            # Custom hooks
  lib/              # API clients, utilities
  ```

## Expo Router Patterns
```typescript
// Navigation
import { router } from 'expo-router'
router.push('/screen')
router.replace('/screen')  // no back
router.back()

// Typed params
import { useLocalSearchParams } from 'expo-router'
const { id } = useLocalSearchParams<{ id: string }>()
```

## Supabase + Expo Auth
```typescript
// Use AsyncStorage for session persistence
import AsyncStorage from '@react-native-async-storage/async-storage'
const supabase = createClient(url, key, {
  auth: { storage: AsyncStorage, autoRefreshToken: true, persistSession: true }
})
```

## Styling
- Use StyleSheet.create() for performance, not inline styles
- Use `react-native-safe-area-context` for safe areas
- Platform-specific: `Platform.OS === 'ios'` checks

## Common Patterns
```typescript
// Loading state
const [loading, setLoading] = useState(false)
const handleAction = async () => {
  setLoading(true)
  try { await action() } finally { setLoading(false) }
}

// Keyboard avoiding (iOS)
import { KeyboardAvoidingView, Platform } from 'react-native'
<KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
```

## Performance
- Use `FlashList` from `@shopify/flash-list` instead of `FlatList` for long lists
- Memoize expensive components with `React.memo`
- Use `useCallback` for handlers passed to list items

## Build & Deploy
- Development: `npx expo start`
- Preview build: `eas build --profile preview --platform ios`
- Production: `eas build --profile production --platform all`
- OTA updates: `eas update --branch production --message "fix: ..."`
