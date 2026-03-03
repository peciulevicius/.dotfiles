---
name: cloudflare
description: Cloudflare Pages deployment, R2 object storage, Turnstile CAPTCHA, Workers + Hono API, KV for rate limiting and sessions, WAF rules, Images CDN. Use when deploying to or building on the Cloudflare platform.
---

You are a Cloudflare platform expert. Apply these patterns for Pages, Workers, R2, KV, Turnstile, and Images.

---

## Cloudflare Products Quick Reference

| Product | Use Case | Free Tier |
|---------|----------|-----------|
| **Pages** | Static sites + SSR apps | Unlimited sites, 500 builds/month |
| **Workers** | Edge API functions | 100k req/day |
| **R2** | Object storage (zero egress) | 10 GB storage, 1M Class A ops |
| **KV** | Key-value store | 100k reads/day, 1k writes/day |
| **D1** | SQLite at the edge | 5 GB, 25M rows read/day |
| **Turnstile** | Privacy-friendly CAPTCHA | Unlimited |
| **Images** | Image CDN + resize | $5/month for 100k images |
| **WAF** | Web Application Firewall | Included with Pages |

---

## Cloudflare Pages

### Deploy via CLI
```bash
# Install Wrangler
pnpm add -D wrangler

# Login
npx wrangler login

# Deploy (Astro, SvelteKit, etc.)
npx wrangler pages deploy ./dist --project-name=my-site

# Deploy from CI/CD
npx wrangler pages deploy ./dist \
  --project-name=my-site \
  --branch=main \
  --commit-hash=$GITHUB_SHA
```

### wrangler.toml (Pages)
```toml
name = "my-site"
pages_build_output_dir = "dist"

[vars]
ENVIRONMENT = "production"

[[kv_namespaces]]
binding = "SESSIONS"
id = "your-kv-namespace-id"

[[r2_buckets]]
binding = "UPLOADS"
bucket_name = "my-uploads"
```

### Build Settings (Dashboard)
```
Framework preset:   Astro / SvelteKit / Next.js
Build command:      pnpm build
Build output:       dist / .svelte-kit/cloudflare
Root directory:     apps/landing (if monorepo)
Node.js version:    20
```

### Environment Variables (Pages)
```bash
# Via CLI
npx wrangler pages secret put DATABASE_URL
npx wrangler pages secret put SUPABASE_SERVICE_ROLE_KEY

# Variables visible to client (non-sensitive)
# Set in dashboard: Settings → Environment Variables
```

---

## Workers + Hono (Edge API)

```bash
pnpm create cloudflare@latest my-api -- --template hono
# or
pnpm add hono @hono/zod-validator
```

### Basic Hono API
```typescript
// src/index.ts
import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { zValidator } from '@hono/zod-validator'
import { z } from 'zod'

type Bindings = {
  DB: D1Database
  SESSIONS: KVNamespace
  UPLOADS: R2Bucket
  ENVIRONMENT: string
}

const app = new Hono<{ Bindings: Bindings }>()

// CORS
app.use('*', cors({
  origin: ['https://yourapp.com', 'http://localhost:3000'],
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE'],
}))

// Route with Zod validation
app.post('/api/contacts',
  zValidator('json', z.object({
    email: z.string().email(),
    name: z.string().min(1),
  })),
  async (c) => {
    const { email, name } = c.req.valid('json')

    await c.env.DB.prepare(
      'INSERT INTO contacts (email, name) VALUES (?, ?)'
    ).bind(email, name).run()

    return c.json({ success: true }, 201)
  }
)

// KV rate limiting
app.use('/api/*', async (c, next) => {
  const ip = c.req.header('CF-Connecting-IP') ?? 'unknown'
  const key = `rate:${ip}`
  const count = parseInt(await c.env.SESSIONS.get(key) ?? '0')

  if (count > 100) {
    return c.json({ error: 'Rate limit exceeded' }, 429)
  }

  await c.env.SESSIONS.put(key, String(count + 1), { expirationTtl: 60 })
  return next()
})

export default app
```

---

## R2 Object Storage

### Upload File
```typescript
// In a Worker or Pages Function
async function uploadToR2(c: Context) {
  const formData = await c.req.formData()
  const file = formData.get('file') as File

  if (!file) return c.json({ error: 'No file' }, 400)

  const key = `uploads/${Date.now()}-${file.name}`
  await c.env.UPLOADS.put(key, await file.arrayBuffer(), {
    httpMetadata: { contentType: file.type },
  })

  return c.json({
    key,
    url: `https://assets.yoursite.com/${key}`,
  })
}

// Get file
async function getFromR2(c: Context) {
  const key = c.req.param('key')
  const object = await c.env.UPLOADS.get(key)

  if (!object) return c.json({ error: 'Not found' }, 404)

  return new Response(object.body, {
    headers: {
      'Content-Type': object.httpMetadata?.contentType ?? 'application/octet-stream',
      'Cache-Control': 'public, max-age=31536000',
    },
  })
}
```

### Public Bucket (via custom domain)
1. R2 Dashboard → Bucket → Settings → Public Access
2. Add custom domain: `assets.yoursite.com`
3. Files served directly via CDN — no Worker needed for reads

---

## Turnstile CAPTCHA

### Client-Side
```tsx
// components/TurnstileWidget.tsx (React)
import { useEffect, useRef } from 'react'

declare global {
  interface Window {
    turnstile: {
      render: (container: string | HTMLElement, options: object) => string
      remove: (widgetId: string) => void
    }
  }
}

export function TurnstileWidget({ onSuccess }: { onSuccess: (token: string) => void }) {
  const ref = useRef<HTMLDivElement>(null)
  const widgetId = useRef<string>()

  useEffect(() => {
    if (!ref.current) return

    widgetId.current = window.turnstile?.render(ref.current, {
      sitekey: process.env.NEXT_PUBLIC_TURNSTILE_SITE_KEY!,
      callback: onSuccess,
    })

    return () => {
      if (widgetId.current) window.turnstile?.remove(widgetId.current)
    }
  }, [])

  return (
    <>
      <script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer />
      <div ref={ref} />
    </>
  )
}
```

### Server-Side Verification
```typescript
// Verify in your API route / server action
async function verifyTurnstile(token: string, ip?: string): Promise<boolean> {
  const res = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      secret: process.env.TURNSTILE_SECRET_KEY,
      response: token,
      remoteip: ip,
    }),
  })
  const data = await res.json() as { success: boolean }
  return data.success
}

// Usage in route handler
export async function POST(req: Request) {
  const body = await req.json()
  const ip = req.headers.get('CF-Connecting-IP') ?? undefined

  const isHuman = await verifyTurnstile(body.turnstileToken, ip)
  if (!isHuman) return Response.json({ error: 'CAPTCHA failed' }, { status: 400 })

  // Process form...
}
```

---

## KV — Rate Limiting + Sessions

```typescript
// Rate limit: max requests per window per key
async function rateLimit(
  kv: KVNamespace,
  key: string,
  limit: number,
  windowSeconds: number
): Promise<{ allowed: boolean; remaining: number }> {
  const current = parseInt(await kv.get(`rl:${key}`) ?? '0')

  if (current >= limit) {
    return { allowed: false, remaining: 0 }
  }

  await kv.put(`rl:${key}`, String(current + 1), { expirationTtl: windowSeconds })
  return { allowed: true, remaining: limit - current - 1 }
}

// Session storage
async function setSession(kv: KVNamespace, sessionId: string, data: object) {
  await kv.put(`session:${sessionId}`, JSON.stringify(data), {
    expirationTtl: 86400,  // 24 hours
  })
}

async function getSession<T>(kv: KVNamespace, sessionId: string): Promise<T | null> {
  const raw = await kv.get(`session:${sessionId}`)
  return raw ? JSON.parse(raw) as T : null
}
```

---

## D1 (SQLite at Edge)

```bash
# Create database
npx wrangler d1 create my-db

# Apply migrations
npx wrangler d1 execute my-db --local --file=./migrations/0001_init.sql

# Query from Worker
```

```typescript
// In Hono Worker
app.get('/users/:id', async (c) => {
  const { id } = c.req.param()
  const result = await c.env.DB.prepare(
    'SELECT * FROM users WHERE id = ?'
  ).bind(id).first()

  if (!result) return c.json({ error: 'Not found' }, 404)
  return c.json(result)
})
```

---

## Headers & Security (Pages)

```toml
# public/_headers (Cloudflare Pages)
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: camera=(), microphone=(), geolocation=()

/api/*
  Cache-Control: no-store

/*.js
  Cache-Control: public, max-age=31536000, immutable

/*.css
  Cache-Control: public, max-age=31536000, immutable
```

```toml
# public/_redirects
/old-page   /new-page   301
/blog/*     /posts/:splat  301
```

---

## Environment Variables Pattern
```bash
# .dev.vars (local development — never commit)
DATABASE_URL=...
TURNSTILE_SECRET_KEY=...

# Production secrets via CLI
npx wrangler secret put TURNSTILE_SECRET_KEY
npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY
```
