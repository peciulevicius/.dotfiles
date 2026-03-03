---
name: sveltekit
description: SvelteKit App Router alternative. File-based routing. Load functions (server + universal). Form actions (native form handling without JS). Cloudflare Pages adapter. Supabase SSR integration. Built-in transitions/animations. Use when building web apps or sites with SvelteKit.
---

You are a SvelteKit expert. Apply these patterns for SvelteKit applications.

## Why SvelteKit (vs Next.js)

- 41% faster than Next.js, 65% smaller bundles
- Simpler mental model — no RSC complexity, no hydration mismatches
- Form Actions handle mutations without JavaScript (progressive enhancement)
- Built-in transitions with zero deps (`transition:fade`, `animate:flip`)
- TypeScript everywhere — load functions are fully typed
- 300% YoY developer growth in 2026

---

## Project Structure

```
src/
├── lib/
│   ├── server/          # Server-only code (DB, secrets)
│   │   ├── supabase.ts  # Server Supabase client
│   │   └── auth.ts      # Auth helpers
│   ├── supabase.ts      # Browser Supabase client
│   └── utils.ts         # Shared utilities
├── routes/
│   ├── +layout.svelte   # Root layout (providers, nav)
│   ├── +layout.server.ts # Root load (session check)
│   ├── +page.svelte     # Home page
│   ├── (marketing)/     # Route group (no URL segment)
│   │   ├── pricing/
│   │   └── blog/
│   └── (app)/           # Authenticated area
│       ├── +layout.server.ts  # Auth guard
│       ├── dashboard/
│       └── settings/
├── app.html             # HTML template
└── app.css              # Global styles
```

---

## Routing

```
src/routes/
  +page.svelte           # /
  about/+page.svelte     # /about
  blog/+page.svelte      # /blog
  blog/[slug]/+page.svelte  # /blog/:slug
  (app)/dashboard/+page.svelte  # /dashboard (no (app) in URL)
  api/webhook/+server.ts    # /api/webhook (API route)
```

---

## Load Functions

```typescript
// src/routes/blog/[slug]/+page.server.ts
import type { PageServerLoad } from './$types'
import { error } from '@sveltejs/kit'

export const load: PageServerLoad = async ({ params, locals }) => {
  // `locals` contains session/user from hooks.server.ts
  const post = await getPost(params.slug)

  if (!post) {
    error(404, { message: 'Post not found' })
  }

  return { post }  // available as `data` in +page.svelte
}
```

```svelte
<!-- src/routes/blog/[slug]/+page.svelte -->
<script lang="ts">
  import type { PageData } from './$types'
  export let data: PageData  // fully typed from load function
</script>

<h1>{data.post.title}</h1>
<article>{@html data.post.content}</article>
```

### Universal Load (runs on server + client)
```typescript
// +page.ts (NOT +page.server.ts)
export const load = async ({ fetch, params }) => {
  // `fetch` is enhanced — works on server + client
  const res = await fetch(`/api/posts/${params.slug}`)
  return { post: await res.json() }
}
```

---

## Form Actions (No JavaScript Needed)

```typescript
// src/routes/contact/+page.server.ts
import type { Actions } from './$types'
import { fail, redirect } from '@sveltejs/kit'
import { z } from 'zod'

const schema = z.object({
  email: z.string().email(),
  message: z.string().min(10),
})

export const actions = {
  default: async ({ request, locals }) => {
    const formData = await request.formData()
    const raw = Object.fromEntries(formData)

    const result = schema.safeParse(raw)
    if (!result.success) {
      return fail(400, {
        errors: result.error.flatten().fieldErrors,
        values: raw,
      })
    }

    await sendEmail(result.data)
    redirect(303, '/thank-you')
  },

  // Named action: use:enhance with action="?/subscribe"
  subscribe: async ({ request }) => {
    const data = await request.formData()
    const email = data.get('email')
    await addToNewsletter(email as string)
    return { success: true }
  },
}
```

```svelte
<!-- src/routes/contact/+page.svelte -->
<script lang="ts">
  import { enhance } from '$app/forms'
  import type { ActionData } from './$types'
  export let form: ActionData  // result from action
</script>

<!-- Works without JS (progressive enhancement) -->
<!-- `use:enhance` adds JS-powered UX on top -->
<form method="POST" use:enhance>
  <input type="email" name="email" value={form?.values?.email ?? ''} />
  {#if form?.errors?.email}
    <p class="error">{form.errors.email[0]}</p>
  {/if}

  <textarea name="message">{form?.values?.message ?? ''}</textarea>

  <button type="submit">Send</button>
</form>

{#if form?.success}
  <p>Subscribed!</p>
{/if}
```

---

## Supabase SSR Integration

```bash
pnpm add @supabase/supabase-js @supabase/ssr
```

```typescript
// src/hooks.server.ts
import { createServerClient } from '@supabase/ssr'
import type { Handle } from '@sveltejs/kit'
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public'

export const handle: Handle = async ({ event, resolve }) => {
  event.locals.supabase = createServerClient(
    PUBLIC_SUPABASE_URL,
    PUBLIC_SUPABASE_ANON_KEY,
    {
      cookies: {
        get: (key) => event.cookies.get(key),
        set: (key, value, options) => event.cookies.set(key, value, { ...options, path: '/' }),
        remove: (key, options) => event.cookies.delete(key, { ...options, path: '/' }),
      },
    }
  )

  event.locals.safeGetSession = async () => {
    const { data: { session } } = await event.locals.supabase.auth.getSession()
    if (!session) return { session: null, user: null }

    const { data: { user }, error } = await event.locals.supabase.auth.getUser()
    if (error) return { session: null, user: null }

    return { session, user }
  }

  return resolve(event, {
    filterSerializedResponseHeaders(name) {
      return name === 'content-range' || name === 'x-supabase-api-version'
    },
  })
}
```

```typescript
// src/app.d.ts
import type { SupabaseClient, Session, User } from '@supabase/supabase-js'
import type { Database } from '$lib/server/db.types'

declare global {
  namespace App {
    interface Locals {
      supabase: SupabaseClient<Database>
      safeGetSession: () => Promise<{ session: Session | null; user: User | null }>
    }
    interface PageData {
      session: Session | null
      user: User | null
    }
  }
}
```

```typescript
// src/routes/(app)/+layout.server.ts — Auth guard
import { redirect } from '@sveltejs/kit'
import type { LayoutServerLoad } from './$types'

export const load: LayoutServerLoad = async ({ locals }) => {
  const { session, user } = await locals.safeGetSession()

  if (!session) redirect(303, '/login')

  return { session, user }
}
```

---

## API Routes (Server-Side)

```typescript
// src/routes/api/webhooks/stripe/+server.ts
import type { RequestHandler } from './$types'
import { json, error } from '@sveltejs/kit'

export const POST: RequestHandler = async ({ request, locals }) => {
  const body = await request.text()
  const sig = request.headers.get('stripe-signature') ?? ''

  let event
  try {
    event = stripe.webhooks.constructEvent(body, sig, STRIPE_WEBHOOK_SECRET)
  } catch (err) {
    error(400, 'Webhook signature invalid')
  }

  switch (event.type) {
    case 'customer.subscription.created':
      await handleSubscriptionCreated(event.data.object)
      break
  }

  return json({ received: true })
}
```

---

## Cloudflare Pages Adapter

```bash
pnpm add -D @sveltejs/adapter-cloudflare
```

```javascript
// svelte.config.js
import adapter from '@sveltejs/adapter-cloudflare'
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte'

export default {
  preprocess: vitePreprocess(),
  kit: {
    adapter: adapter({
      routes: {
        include: ['/*'],
        exclude: ['<all>'],
      },
    }),
  },
}
```

```toml
# wrangler.toml
name = "my-app"
compatibility_date = "2024-01-01"
pages_build_output_dir = ".svelte-kit/cloudflare"

[[kv_namespaces]]
binding = "CACHE"
id = "your-kv-id"
```

```typescript
// Access Cloudflare bindings in load functions
export const load: PageServerLoad = async ({ platform }) => {
  const kv = platform?.env?.CACHE  // KV Namespace
  const db = platform?.env?.DB     // D1 Database
}
```

---

## Built-in Transitions

```svelte
<script>
  import { fade, fly, scale, slide } from 'svelte/transition'
  import { flip } from 'svelte/animate'
  import { cubicOut } from 'svelte/easing'

  let items = [...]
  let show = false
</script>

<!-- Page transitions -->
{#if show}
  <div transition:fade={{ duration: 200 }}>
    Content fades in and out
  </div>
{/if}

<!-- Fly from bottom -->
{#if show}
  <div transition:fly={{ y: 20, duration: 300, easing: cubicOut }}>
    Slides in from below
  </div>
{/if}

<!-- Animate list reorder -->
{#each items as item (item.id)}
  <div animate:flip={{ duration: 300 }}>
    {item.name}
  </div>
{/each}

<!-- Stagger with delay -->
{#each items as item, i}
  <div in:fly={{ y: 12, delay: i * 60, duration: 250 }}>
    {item.name}
  </div>
{/each}
```

---

## Reactive Stores

```typescript
// src/lib/stores/user.ts
import { writable, derived } from 'svelte/store'
import type { User } from '@supabase/supabase-js'

export const user = writable<User | null>(null)
export const isPro = derived(user, ($user) => $user?.user_metadata?.plan === 'pro')
```

```svelte
<script>
  import { user, isPro } from '$lib/stores/user'
</script>

{#if $isPro}
  <ProFeature />
{:else}
  <UpgradePrompt />
{/if}
```

---

## Environment Variables

```typescript
// Public vars (safe in browser)
import { PUBLIC_SUPABASE_URL, PUBLIC_POSTHOG_KEY } from '$env/static/public'

// Private vars (server only)
import { SUPABASE_SERVICE_KEY, STRIPE_SECRET_KEY } from '$env/static/private'

// Dynamic env (runtime)
import { env } from '$env/dynamic/private'
const value = env.MY_VAR
```

---

## Checklist

- [ ] `hooks.server.ts` sets up Supabase on every request
- [ ] `app.d.ts` typed locals and page data
- [ ] Auth guard in `(app)/+layout.server.ts`
- [ ] Form actions validate with Zod + return errors
- [ ] `use:enhance` on all forms for JS enhancement
- [ ] Cloudflare adapter configured
- [ ] Environment variables in `$env/static/private` (never hardcoded)
