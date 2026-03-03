---
name: nextjs
description: Next.js App Router patterns — server components, server actions, data fetching, auth, middleware. Use when building Next.js applications.
---

You are a Next.js App Router expert. Apply these patterns.

## File Structure
```
app/
  layout.tsx              # Root layout (HTML, providers)
  page.tsx                # Home route
  (marketing)/            # Route group — no URL segment
  (app)/                  # Authenticated area
    layout.tsx            # Auth check
    dashboard/page.tsx
  api/
    webhooks/route.ts
components/
  ui/                     # shadcn/ui components
  [feature]/              # Feature-specific components
lib/
  supabase/
    client.ts             # Browser client
    server.ts             # Server component client
  actions/                # Server actions
```

## Server vs Client Components
```typescript
// Server component (default) — no 'use client'
// Can: async/await, access DB, read headers/cookies
// Cannot: useState, useEffect, event handlers, browser APIs

// Client component — add 'use client' at top
// Can: useState, useEffect, events, browser APIs
// Cannot: async/await directly, DB access

// Pattern: server fetches, client renders interactively
// Server component wraps client, passes data as props
```

## Data Fetching
```typescript
// Server component — direct async
export default async function Page({ params }: { params: { id: string } }) {
  const data = await fetchData(params.id)  // cached by default
  return <ClientComponent data={data} />
}

// Parallel fetching
const [user, posts] = await Promise.all([getUser(id), getPosts(id)])

// Opt out of caching
const data = await fetch('/api/data', { cache: 'no-store' })

// Revalidate on interval
const data = await fetch('/api/data', { next: { revalidate: 60 } })
```

## Server Actions
```typescript
// app/actions/items.ts
'use server'
import { revalidatePath } from 'next/cache'

export async function createItem(formData: FormData) {
  const name = formData.get('name') as string
  // validate, save to DB
  await db.items.create({ name })
  revalidatePath('/dashboard')  // invalidate cache
}

// In component: <form action={createItem}>
// Or: const result = await createItem(formData)
```

## Middleware (Auth)
```typescript
// middleware.ts (root)
export function middleware(request: NextRequest) {
  const token = request.cookies.get('session')
  if (!token && request.nextUrl.pathname.startsWith('/app')) {
    return NextResponse.redirect(new URL('/login', request.url))
  }
}
export const config = { matcher: ['/app/:path*'] }
```

## Route Handlers
```typescript
// app/api/items/route.ts
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)
  const id = searchParams.get('id')
  return Response.json({ data })
}

export async function POST(request: Request) {
  const body = await request.json()
  // validate body
  return Response.json({ id: newItem.id }, { status: 201 })
}
```

## Performance
- `loading.tsx` for streaming skeleton UI
- `Suspense` boundaries around slow data fetches
- `next/image` for all images, `next/font` for fonts
- Dynamic imports: `const Component = dynamic(() => import('./Heavy'))`
- Metadata API: export `metadata` or `generateMetadata` from pages
