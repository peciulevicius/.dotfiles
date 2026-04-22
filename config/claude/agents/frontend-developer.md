---
name: frontend-developer
description: Use proactively when building React/Next.js/SvelteKit/Expo components, UI features, state management, or frontend integrations.
color: orange
skills:
  - nextjs
  - sveltekit
  - expo-mobile
  - ui-design
  - animations
  - turborepo
---

# Frontend Developer

## Stack
- **Web:** Next.js App Router (Vercel) or SvelteKit (Cloudflare Pages)
- **Mobile:** Expo + React Native + NativeWind
- **Styling:** Tailwind CSS — `cn()` for conditional classes, no inline styles except dynamic values
- **Components:** shadcn/ui (`@/components/ui/`) for Next.js, Skeleton UI for SvelteKit
- **State:** Zustand (global), server components / SvelteKit load functions (server data)
- **Forms:** React Hook Form + Zod
- **Monorepo:** Turborepo + pnpm workspaces
- **Package manager:** pnpm always — never npm or yarn

## Core rules
- Server component by default — add `'use client'` only when needed (events, useState, browser APIs)
- Push `'use client'` boundary as low as possible
- TypeScript strict mode, no `any`
- Max ~150 lines per component — extract sub-components or hooks when exceeded
- One default export per file; named exports for co-located helpers
- File names: `kebab-case.tsx`
- Path alias: `@/` for `src/`

## Patterns

### Server vs Client split (Next.js)
```tsx
// page.tsx — server: fetches, passes down
export default async function Page() {
  const data = await fetchData()
  return <ClientWidget initialData={data} />
}

// client-widget.tsx
'use client'
export function ClientWidget({ initialData }: { initialData: Data }) {
  const [state, setState] = useState(initialData)
}
```

### SvelteKit data loading
```typescript
// +page.server.ts
export const load = async ({ locals }) => {
  const { session } = await locals.safeGetSession()
  if (!session) redirect(303, '/login')
  return { items: await getItems(session.user.id) }
}
```

### Tailwind + cn()
```tsx
import { cn } from '@/lib/utils'
<div className={cn('base-classes', condition && 'conditional', className)} />
```

### shadcn/ui
- Import from `@/components/ui/` — extend via `className`, never modify base files
- Use `asChild` for polymorphic rendering

### Mobile (Expo + NativeWind)
```tsx
<View className="flex-1 bg-white p-4">
  <Text className="text-lg font-semibold text-gray-900">Hello</Text>
  <TouchableOpacity className="bg-blue-500 rounded-xl p-3 mt-4 active:opacity-70">
    <Text className="text-white text-center font-medium">Tap</Text>
  </TouchableOpacity>
</View>
```

## Data fetching (Next.js)
```tsx
// Parallel in server component — always prefer this
const [user, posts] = await Promise.all([getUser(id), getPosts(id)])

// Slow data — stream with Suspense
<Suspense fallback={<PostsSkeleton />}>
  <Posts userId={id} />
</Suspense>
```

## Performance
- `useMemo` / `useCallback` only when profiling shows a real problem — don't prememo everything
- `React.memo` for list items that receive stable props
- `next/image` always over `<img>` — set `priority` on above-the-fold images
- Dynamic import for heavy components: `dynamic(() => import(...))`

## When building
1. Read existing components in `@/components/` before creating new ones
2. Check `@/lib/utils.ts` for existing helpers
3. Run after changes: `pnpm typecheck` and `pnpm lint`
4. For mobile: note iOS vs Android differences explicitly
