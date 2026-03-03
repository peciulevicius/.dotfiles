# API Rules (Next.js Route Handlers)

## Route Handler Structure
```typescript
// src/app/api/items/route.ts
import { NextResponse } from 'next/server'
import { z } from 'zod'
import { createServerClient } from '@/lib/supabase/server'

const createItemSchema = z.object({
  name: z.string().min(1).max(100),
  description: z.string().optional(),
})

export async function POST(req: Request) {
  // 1. Auth
  const supabase = createServerClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  // 2. Validate input
  const body = await req.json()
  const result = createItemSchema.safeParse(body)
  if (!result.success) {
    return NextResponse.json({ error: result.error.flatten().fieldErrors }, { status: 400 })
  }

  // 3. Business logic
  const { data, error } = await supabase
    .from('items')
    .insert({ ...result.data, user_id: user.id })
    .select()
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })

  // 4. Return
  return NextResponse.json(data, { status: 201 })
}
```

## Response Conventions
```typescript
// Success
return NextResponse.json(data)                        // 200
return NextResponse.json(data, { status: 201 })       // created
return new Response(null, { status: 204 })            // no content

// Error
return NextResponse.json({ error: 'message' }, { status: 400 })  // bad request
return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
return NextResponse.json({ error: 'Not found' }, { status: 404 })
return NextResponse.json({ error: 'Internal error' }, { status: 500 })

// Never expose internal errors to clients:
if (error) {
  console.error('DB error:', error)  // log internally
  return NextResponse.json({ error: 'Failed to create item' }, { status: 500 })  // generic to client
}
```

## Pagination
```typescript
// Cursor-based (prefer over offset for large datasets)
const { searchParams } = new URL(req.url)
const cursor = searchParams.get('cursor')  // last item ID
const limit = Math.min(Number(searchParams.get('limit') ?? 20), 100)

let query = supabase.from('items').select('*').order('created_at', { ascending: false }).limit(limit)
if (cursor) query = query.lt('created_at', cursor)

const { data } = await query
const nextCursor = data?.length === limit ? data[data.length - 1].created_at : null

return NextResponse.json({ data, nextCursor })
```

## Webhooks
```typescript
// Always verify webhook signatures before processing
// Stripe:
export async function POST(req: Request) {
  const body = await req.text()  // raw body — NOT req.json()
  const sig = req.headers.get('stripe-signature')!

  let event
  try {
    event = stripe.webhooks.constructEvent(body, sig, process.env.STRIPE_WEBHOOK_SECRET!)
  } catch {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 })
  }

  // Process synchronously — return 200 fast, do work async
  switch (event.type) {
    case 'checkout.session.completed':
      await handleCheckoutCompleted(event.data.object)
      break
  }

  return NextResponse.json({ received: true })
}
```

## Middleware (Auth Guard)
```typescript
// src/middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export async function middleware(req: NextRequest) {
  const res = NextResponse.next()
  const supabase = createServerClient(...)

  const { data: { user } } = await supabase.auth.getUser()

  if (!user && req.nextUrl.pathname.startsWith('/app')) {
    return NextResponse.redirect(new URL('/login', req.url))
  }

  return res
}

export const config = {
  matcher: ['/app/:path*', '/api/protected/:path*'],
}
```

## CORS (for external API consumers)
```typescript
const corsHeaders = {
  'Access-Control-Allow-Origin': process.env.ALLOWED_ORIGIN ?? '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
}

export async function OPTIONS() {
  return new Response(null, { headers: corsHeaders })
}

export async function GET(req: Request) {
  // ... handler logic
  return NextResponse.json(data, { headers: corsHeaders })
}
```

## File Naming
```
src/app/api/
  items/
    route.ts           # GET /api/items, POST /api/items
    [id]/route.ts      # GET /api/items/[id], PUT, DELETE
  auth/
    callback/route.ts
  webhooks/
    stripe/route.ts
    supabase/route.ts
```
