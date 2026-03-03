# Performance Rules

## React Rendering

```typescript
// Memoize expensive computations
const sorted = useMemo(() => items.sort(compareByDate), [items])

// Memoize callbacks passed to child components
const handleDelete = useCallback((id: string) => deleteItem(id), [deleteItem])

// Memoize components that receive stable props
const ExpensiveList = React.memo(({ items }: { items: Item[] }) => { ... })

// When NOT to memoize:
// - Simple components that render fast
// - When props change every render anyway
// - Premature optimization — profile first
```

## Next.js — Server vs Client

```tsx
// Prefer server components — zero JS sent to browser
// Move 'use client' boundary as low as possible

// BAD: 'use client' on a parent that just passes data
'use client'
export default function Page() {
  const [open, setOpen] = useState(false)
  return <div><HugeStaticSection /><Dialog open={open} /></div>
}

// GOOD: server component, only Dialog is client
export default function Page() {
  return <div><HugeStaticSection /><DialogClient /></div>
}
// dialog-client.tsx: 'use client' — small, targeted
```

## Bundle Size

```bash
# Analyse bundle
npx @next/bundle-analyzer   # Next.js
npx vite-bundle-visualizer  # Vite/SvelteKit

# Check package size before installing
npx bundlephobia <package-name>
```

```typescript
// Dynamic import for heavy components
const RichEditor = dynamic(() => import('@/components/rich-editor'), {
  loading: () => <EditorSkeleton />,
  ssr: false,  // if browser-only
})

// Tree-shake: import named exports, not whole libs
import { format } from 'date-fns'           // ✅ tree-shakable
import dateFns from 'date-fns'              // ❌ full bundle

import { Button } from '@/components/ui'    // ✅ named
import * as UI from '@/components/ui'       // ❌ imports everything
```

## Images

```tsx
// Next.js Image — always use it, never <img>
import Image from 'next/image'
<Image
  src="/hero.jpg"
  alt="Hero"
  width={1200}
  height={600}
  priority     // add for above-the-fold images (LCP element)
  sizes="(max-width: 768px) 100vw, 50vw"
/>

// SVGs — import as components (avoid img tag for icons)
import Logo from '@/assets/logo.svg'
```

## Database Queries

```typescript
// N+1 pattern — the classic perf killer
// BAD:
const posts = await getPosts()
for (const post of posts) {
  post.author = await getUser(post.userId)  // N extra queries!
}

// GOOD: join in a single query
const { data } = await supabase
  .from('posts')
  .select('*, author:users(id, name, avatar_url)')

// Select only needed columns
.select('id, title, created_at')  // not .select('*')

// Add indexes for frequent query patterns
// (see database.md for indexing rules)
```

## Caching (Next.js)

```typescript
// Static data — cache indefinitely, revalidate on demand
const { data } = await supabase.from('plans').select('*')
// Next.js caches fetch() by default in server components

// Revalidate on a schedule
fetch(url, { next: { revalidate: 3600 } })  // 1 hour

// Revalidate after mutations
import { revalidatePath, revalidateTag } from 'next/cache'
await revalidatePath('/dashboard')

// Dynamic data — opt out of caching
fetch(url, { cache: 'no-store' })
// OR: use unstable_noStore()
import { unstable_noStore as noStore } from 'next/cache'
noStore()
```

## Core Web Vitals

```
LCP (Largest Contentful Paint) — target < 2.5s
  → preload hero images (priority prop)
  → avoid render-blocking resources
  → use CDN for static assets

CLS (Cumulative Layout Shift) — target < 0.1
  → always set width/height on images
  → reserve space for dynamic content (skeleton screens)
  → avoid inserting content above existing content

INP (Interaction to Next Paint) — target < 200ms
  → debounce expensive event handlers
  → defer non-critical JS
  → use transitions for UI updates
```

## Profiling

```bash
# React DevTools Profiler — find slow renders
# In browser: React DevTools → Profiler tab → Record → interact → stop

# Next.js
ANALYZE=true pnpm build   # with @next/bundle-analyzer

# Lighthouse
npx lighthouse http://localhost:3000 --view

# Web Vitals in code
import { onLCP, onCLS, onINP } from 'web-vitals'
onLCP(({ value }) => console.log('LCP', value))
```
