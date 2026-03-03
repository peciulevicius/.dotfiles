---
name: astro
description: Astro static + content sites. Island architecture. Content collections with MDX blog. Astro DB (D1/Turso edge database). Cloudflare Pages deployment. Tailwind + React/Svelte islands. SEO defaults. Use when building marketing sites, landing pages, or content-heavy sites with Astro.
---

You are an Astro expert. Apply these patterns for content sites and marketing pages.

## Why Astro

- Zero JavaScript by default — only hydrate what's interactive
- Best Lighthouse scores out of any framework
- Content Collections with TypeScript safety for blogs/docs
- Works with React, Svelte, Vue components in the same project
- First-class Cloudflare Pages support

---

## Project Structure

```
src/
├── components/
│   ├── ui/              # Reusable UI (Button, Card, Badge)
│   ├── sections/        # Landing page sections (Hero, Pricing, FAQ)
│   └── islands/         # Interactive components (ContactForm, Navbar)
├── content/
│   ├── blog/            # .md / .mdx blog posts
│   └── config.ts        # Collection schema definitions
├── layouts/
│   ├── BaseLayout.astro # HTML shell + SEO
│   └── BlogLayout.astro # Blog post layout
├── pages/
│   ├── index.astro      # Homepage
│   ├── blog/
│   │   ├── index.astro  # Blog listing
│   │   └── [slug].astro # Individual post
│   └── api/             # API routes (SSR only)
└── styles/
    └── global.css       # Tailwind + custom CSS
```

---

## Getting Started

```bash
pnpm create astro@latest my-site -- --template minimal
cd my-site
pnpm astro add tailwind
pnpm astro add react    # or svelte, vue
pnpm astro add sitemap  # auto-generates sitemap.xml
pnpm astro add cloudflare  # for CF Pages deployment
```

---

## Base Layout (SEO Ready)

```astro
---
// src/layouts/BaseLayout.astro
interface Props {
  title: string
  description: string
  ogImage?: string
  noIndex?: boolean
}

const {
  title,
  description,
  ogImage = '/og-default.png',
  noIndex = false,
} = Astro.props

const canonicalURL = new URL(Astro.url.pathname, Astro.site)
const fullTitle = title === 'Home' ? 'Your Brand — Tagline' : `${title} | Your Brand`
---
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="generator" content={Astro.generator} />

    <title>{fullTitle}</title>
    <meta name="description" content={description} />
    {noIndex && <meta name="robots" content="noindex" />}
    <link rel="canonical" href={canonicalURL} />

    <!-- OG -->
    <meta property="og:title" content={fullTitle} />
    <meta property="og:description" content={description} />
    <meta property="og:image" content={new URL(ogImage, Astro.site)} />
    <meta property="og:url" content={canonicalURL} />
    <meta property="og:type" content="website" />

    <!-- Twitter -->
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content={fullTitle} />
    <meta name="twitter:description" content={description} />
    <meta name="twitter:image" content={new URL(ogImage, Astro.site)} />

    <!-- Favicon -->
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <link rel="sitemap" href="/sitemap-index.xml" />
  </head>
  <body class="bg-white text-gray-900 antialiased">
    <slot />
  </body>
</html>
```

---

## Content Collections

```typescript
// src/content/config.ts
import { defineCollection, z } from 'astro:content'

const blog = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    description: z.string(),
    publishedAt: z.date(),
    updatedAt: z.date().optional(),
    author: z.string().default('Your Name'),
    coverImage: z.string().optional(),
    tags: z.array(z.string()).default([]),
    draft: z.boolean().default(false),
  }),
})

export const collections = { blog }
```

```astro
---
// src/pages/blog/index.astro
import { getCollection } from 'astro:content'
import BaseLayout from '@/layouts/BaseLayout.astro'

const posts = await getCollection('blog', ({ data }) => !data.draft)
const sorted = posts.sort((a, b) =>
  b.data.publishedAt.valueOf() - a.data.publishedAt.valueOf()
)
---
<BaseLayout title="Blog" description="Insights and updates from our team.">
  <main class="max-w-4xl mx-auto px-4 py-16">
    <h1 class="text-4xl font-bold mb-8">Blog</h1>
    <div class="space-y-8">
      {sorted.map((post) => (
        <article>
          <a href={`/blog/${post.slug}`} class="group">
            <h2 class="text-xl font-semibold group-hover:text-blue-600">
              {post.data.title}
            </h2>
            <p class="text-gray-600 mt-1">{post.data.description}</p>
          </a>
        </article>
      ))}
    </div>
  </main>
</BaseLayout>
```

```astro
---
// src/pages/blog/[slug].astro
import { getCollection, getEntry } from 'astro:content'
import BlogLayout from '@/layouts/BlogLayout.astro'

export async function getStaticPaths() {
  const posts = await getCollection('blog', ({ data }) => !data.draft)
  return posts.map((post) => ({ params: { slug: post.slug }, props: { post } }))
}

const { post } = Astro.props
const { Content } = await post.render()
---
<BlogLayout
  title={post.data.title}
  description={post.data.description}
  ogImage={post.data.coverImage}
  publishedAt={post.data.publishedAt}
>
  <Content />
</BlogLayout>
```

---

## Island Architecture (Interactive Components)

```astro
---
// Static by default — zero JS
// Add client: directive to hydrate

import ContactForm from '@/components/islands/ContactForm.tsx'  // React
import NewsletterSignup from '@/components/islands/Newsletter.svelte'  // Svelte
---

<!-- Hydrate when visible (lazy loading) -->
<ContactForm client:visible />

<!-- Hydrate immediately (above fold) -->
<NewsletterSignup client:load />

<!-- Hydrate on idle (non-critical) -->
<SomeWidget client:idle />

<!-- Hydrate only on mobile -->
<MobileMenu client:media="(max-width: 768px)" />

<!-- Static — never hydrates -->
<StaticCard />
```

---

## Astro.config.mjs — Full Config

```javascript
// astro.config.mjs
import { defineConfig } from 'astro/config'
import tailwind from '@astrojs/tailwind'
import react from '@astrojs/react'
import sitemap from '@astrojs/sitemap'
import cloudflare from '@astrojs/cloudflare'

export default defineConfig({
  site: 'https://yoursite.com',
  output: 'static',  // 'server' for SSR, 'hybrid' for mixed
  adapter: cloudflare(),  // for Cloudflare Pages
  integrations: [
    tailwind({ applyBaseStyles: false }),
    react(),
    sitemap(),
  ],
  image: {
    service: { entrypoint: 'astro/assets/services/sharp' },
  },
  vite: {
    resolve: {
      alias: { '@': '/src' },
    },
  },
})
```

---

## Cloudflare Pages Deployment

```bash
# Preview locally with Cloudflare runtime
pnpm astro build && npx wrangler pages dev ./dist

# Deploy via Wrangler
npx wrangler pages deploy ./dist --project-name=my-site
```

Or connect GitHub repo in Cloudflare Pages dashboard:
- Build command: `pnpm build`
- Output directory: `dist`
- Node version: `20`

---

## Astro DB (Edge Database)

```bash
pnpm astro add db
```

```typescript
// db/config.ts
import { defineDb, defineTable, column } from 'astro:db'

const EmailCapture = defineTable({
  columns: {
    id: column.number({ primaryKey: true }),
    email: column.text({ unique: true }),
    source: column.text({ default: 'landing' }),
    createdAt: column.date({ default: NOW }),
  },
})

export default defineDb({ tables: { EmailCapture } })
```

```astro
---
// src/pages/index.astro — email capture form
import { db, EmailCapture } from 'astro:db'

if (Astro.request.method === 'POST') {
  const form = await Astro.request.formData()
  const email = form.get('email')?.toString()

  if (email) {
    await db.insert(EmailCapture).values({ email }).onConflictDoNothing()
    return Astro.redirect('/thank-you')
  }
}
---
<form method="POST">
  <input type="email" name="email" placeholder="your@email.com" required />
  <button type="submit">Get Early Access</button>
</form>
```

---

## Performance Tips

```astro
<!-- Optimize images — Astro handles it automatically -->
<Image src={heroImage} alt="Hero" width={1200} height={600} loading="eager" />
<Image src={cardImage} alt="Card" width={400} height={300} loading="lazy" />

<!-- Prefer <Image> over <img> for automatic WebP conversion + sizing -->

<!-- Inline critical CSS (Astro does this for Tailwind automatically) -->
<!-- Defer non-critical scripts -->
<script src="/analytics.js" defer is:inline></script>
```

---

## Landing Page Pattern

```astro
---
// src/pages/index.astro
import BaseLayout from '@/layouts/BaseLayout.astro'
import Hero from '@/components/sections/Hero.astro'
import Features from '@/components/sections/Features.astro'
import Pricing from '@/components/sections/Pricing.astro'
import FAQ from '@/components/sections/FAQ.astro'
import CTA from '@/components/sections/CTA.astro'
import Footer from '@/components/Footer.astro'
import Navbar from '@/components/islands/Navbar.tsx'  // Interactive
---
<BaseLayout title="Home" description="Your tagline here.">
  <Navbar client:load />
  <main>
    <Hero />
    <Features />
    <Pricing />
    <FAQ />
    <CTA />
  </main>
  <Footer />
</BaseLayout>
```
