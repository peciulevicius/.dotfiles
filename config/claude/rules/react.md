# React / Next.js Rules

## Component Defaults
```tsx
// Server component by default (no directive needed)
// Add 'use client' only when you need: useState, useEffect, events, browser APIs

// File = one default export, named exports for helpers
export default function UserCard({ user }: { user: User }) {}

// Props: inline type for simple, named type for reuse
type ButtonProps = { label: string; onClick: () => void; disabled?: boolean }
export default function Button({ label, onClick, disabled = false }: ButtonProps) {}
```

## Server vs Client Split
```tsx
// Pattern: server fetches data, passes to client for interactivity
// src/app/dashboard/page.tsx (server)
export default async function DashboardPage() {
  const data = await fetchDashboardData()       // runs on server
  return <DashboardClient initialData={data} />  // client handles interaction
}

// src/components/dashboard-client.tsx
'use client'
export function DashboardClient({ initialData }: { initialData: DashboardData }) {
  const [data, setData] = useState(initialData)
  // ...
}
```

## Data Fetching (Next.js App Router)
```tsx
// Prefer server components with direct async/await
const user = await getUser(id)  // no useEffect, no loading state

// Parallel fetching
const [user, posts] = await Promise.all([getUser(id), getPosts(id)])

// Stream slow data with Suspense
<Suspense fallback={<PostsSkeleton />}>
  <Posts userId={id} />  {/* async server component */}
</Suspense>
```

## Server Actions
```typescript
// src/lib/actions/items.ts
'use server'
import { revalidatePath } from 'next/cache'
import { z } from 'zod'

const schema = z.object({ name: z.string().min(1) })

export async function createItem(formData: FormData) {
  const { data, error } = schema.safeParse(Object.fromEntries(formData))
  if (error) return { error: error.flatten().fieldErrors }

  await db.items.create({ name: data.name })
  revalidatePath('/dashboard')
}
```

## Hooks Rules
```typescript
// Custom hooks: always prefix with `use`, extract from components when logic is reused
function useSubscription(userId: string) {
  // data fetching, subscription, derived state
  return { plan, isLoading, upgrade }
}

// No: useEffect for derived state (use useMemo/derived state instead)
// No: useEffect for event handlers (use event handlers directly)
// No: nested ternaries in JSX (extract to variables or components)
```

## Component Size
- Max ~150 lines per component file
- Extract sub-components when JSX gets complex
- Extract hooks when logic gets complex
- One component per file (except tiny co-located helpers)

## Tailwind
```tsx
// cn() for conditional classes (clsx + tailwind-merge)
import { cn } from '@/lib/utils'
<div className={cn('base-classes', condition && 'conditional', className)} />

// No inline styles except dynamic values (colors from DB, user-set widths)
// No arbitrary values when Tailwind has a scale value (use p-4 not p-[16px])
```

## shadcn/ui
- Import from `@/components/ui/` (you own the code)
- Extend with `className` prop, don't modify base component files
- Use `asChild` for polymorphic components
