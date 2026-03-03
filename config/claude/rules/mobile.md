# Mobile Rules (Expo + React Native)

## Project Structure
```
src/
  app/              # Expo Router file-based routing
    (tabs)/         # Tab navigator
      index.tsx     # Home tab
      profile.tsx   # Profile tab
    (auth)/         # Auth screens (no tabs)
      login.tsx
      signup.tsx
    _layout.tsx     # Root layout (providers, fonts)
  components/       # Shared UI components
  hooks/            # Custom hooks
  lib/              # Utilities, API client, constants
  stores/           # Zustand state stores
```

## Expo Router
```typescript
// File-based routing — same concept as Next.js App Router
// app/(tabs)/_layout.tsx — defines tab bar
import { Tabs } from 'expo-router'

export default function TabLayout() {
  return (
    <Tabs screenOptions={{ tabBarActiveTintColor: '#007AFF' }}>
      <Tabs.Screen name="index" options={{ title: 'Home' }} />
      <Tabs.Screen name="profile" options={{ title: 'Profile' }} />
    </Tabs>
  )
}

// Navigation
import { router } from 'expo-router'
router.push('/profile')
router.replace('/(auth)/login')  // replace — no back button
router.back()
```

## NativeWind (Tailwind for RN)
```tsx
// Tailwind classes work on RN components
<View className="flex-1 bg-white p-4">
  <Text className="text-lg font-semibold text-gray-900">Hello</Text>
  <TouchableOpacity className="bg-blue-500 rounded-xl p-3 mt-4 active:opacity-70">
    <Text className="text-white text-center font-medium">Button</Text>
  </TouchableOpacity>
</View>

// Dynamic classes — use cn() or conditional strings
<View className={`flex-1 ${isActive ? 'bg-blue-50' : 'bg-white'}`} />
```

## Auth Tokens — SecureStore Only
```typescript
// NEVER use AsyncStorage for tokens/session data
import * as SecureStore from 'expo-secure-store'

// Store
await SecureStore.setItemAsync('session_token', token)

// Read
const token = await SecureStore.getItemAsync('session_token')

// Delete
await SecureStore.deleteItemAsync('session_token')

// AsyncStorage is fine for non-sensitive data (preferences, cache)
import AsyncStorage from '@react-native-async-storage/async-storage'
```

## Supabase Auth (mobile)
```typescript
// Use expo-secure-store adapter for session persistence
import { createClient } from '@supabase/supabase-js'
import * as SecureStore from 'expo-secure-store'

const ExpoSecureStoreAdapter = {
  getItem: (key: string) => SecureStore.getItemAsync(key),
  setItem: (key: string, value: string) => SecureStore.setItemAsync(key, value),
  removeItem: (key: string) => SecureStore.deleteItemAsync(key),
}

export const supabase = createClient(url, anonKey, {
  auth: {
    storage: ExpoSecureStoreAdapter,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,  // false for native
  },
})
```

## API Calls — No Secrets in App Bundle
```typescript
// Never call external APIs directly with secret keys from the app
// The app bundle can be inspected and keys extracted

// BAD: calling OpenAI directly from app
const response = await fetch('https://api.openai.com/v1/...', {
  headers: { Authorization: `Bearer ${OPENAI_KEY}` }  // extractable!
})

// GOOD: proxy through your own API
const response = await fetch(`${API_URL}/api/ai/generate`, {
  headers: { Authorization: `Bearer ${userToken}` }
})
```

## Platform-Specific Code
```typescript
import { Platform } from 'react-native'

// Inline
const shadow = Platform.select({
  ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.1 },
  android: { elevation: 3 },
})

// File-based (preferred for larger differences)
// component.ios.tsx   — iOS version
// component.android.tsx — Android version
```

## Images & Assets
```typescript
// Static assets — use require() or import
import logo from '@/assets/images/logo.png'
<Image source={logo} style={{ width: 100, height: 100 }} />

// Remote images — always set width/height
<Image
  source={{ uri: avatarUrl }}
  style={{ width: 40, height: 40, borderRadius: 20 }}
  contentFit="cover"   // expo-image
/>

// Use expo-image over RN Image — better caching, performance
import { Image } from 'expo-image'
```

## State Management
```typescript
// Zustand for global state (simpler than Redux for mobile)
import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import AsyncStorage from '@react-native-async-storage/async-storage'

type UserStore = {
  user: User | null
  setUser: (user: User | null) => void
}

export const useUserStore = create<UserStore>()(
  persist(
    (set) => ({ user: null, setUser: (user) => set({ user }) }),
    { name: 'user-store', storage: createJSONStorage(() => AsyncStorage) }
  )
)
```

## Push Notifications
```typescript
// Always request permissions before registering
import * as Notifications from 'expo-notifications'

async function registerForPushNotifications() {
  const { status } = await Notifications.requestPermissionsAsync()
  if (status !== 'granted') return null

  const token = await Notifications.getExpoPushTokenAsync({
    projectId: Constants.expoConfig?.extra?.eas?.projectId,
  })
  return token.data  // save this to your DB
}
```

## Performance
```typescript
// FlatList over ScrollView + map for lists
<FlatList
  data={items}
  renderItem={({ item }) => <ItemRow item={item} />}
  keyExtractor={(item) => item.id}
  getItemLayout={(_, index) => ({ length: 60, offset: 60 * index, index })}  // if fixed height
/>

// Memoize list items
const ItemRow = React.memo(({ item }: { item: Item }) => { ... })

// useCallback for handlers passed to list items
const handlePress = useCallback((id: string) => { ... }, [])
```
