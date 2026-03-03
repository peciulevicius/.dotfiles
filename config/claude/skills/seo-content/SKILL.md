---
name: seo-content
description: SEO patterns for Next.js App Router (metadata API), SvelteKit, and Astro. JSON-LD structured data. Core Web Vitals (LCP, CLS, INP). Blog and content strategy. Use when optimizing for search engines or improving Core Web Vitals.
---

You are an SEO and web performance expert. Apply these patterns for Next.js, SvelteKit, and Astro.

---

## Core Web Vitals Targets (2026)

| Metric | Good | Needs Work | Poor |
|--------|------|-----------|------|
| LCP (largest content paint) | < 2.5s | 2.5–4s | > 4s |
| CLS (cumulative layout shift) | < 0.1 | 0.1–0.25 | > 0.25 |
| INP (interaction to next paint) | < 200ms | 200–500ms | > 500ms |

---

## Next.js App Router — Metadata API

### Static Metadata
```typescript
// app/layout.tsx or app/page.tsx
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: {
    default: 'Your App — Tagline',
    template: '%s | Your App',  // page titles become "Page | Your App"
  },
  description: 'Clear, benefit-focused description under 160 characters.',
  keywords: ['keyword1', 'keyword2'],
  authors: [{ name: 'Your Name' }],
  creator: 'Your Company',
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://yourapp.com',
    siteName: 'Your App',
    images: [{ url: '/og-image.png', width: 1200, height: 630, alt: 'Your App' }],
  },
  twitter: {
    card: 'summary_large_image',
    creator: '@yourhandle',
    images: ['/og-image.png'],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: { index: true, follow: true, 'max-image-preview': 'large' },
  },
  alternates: {
    canonical: 'https://yourapp.com',
  },
}
```

### Dynamic Metadata (per page)
```typescript
// app/blog/[slug]/page.tsx
export async function generateMetadata(
  { params }: { params: { slug: string } }
): Promise<Metadata> {
  const post = await getPost(params.slug)
  if (!post) return {}

  return {
    title: post.title,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      description: post.excerpt,
      images: [{ url: post.coverImage, width: 1200, height: 630 }],
      type: 'article',
      publishedTime: post.publishedAt,
      authors: [post.author],
    },
    alternates: {
      canonical: `https://yourapp.com/blog/${params.slug}`,
    },
  }
}
```

### Dynamic OG Images
```typescript
// app/og/route.tsx
import { ImageResponse } from 'next/og'

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)
  const title = searchParams.get('title') ?? 'Default Title'

  return new ImageResponse(
    (
      <div style={{ display: 'flex', width: '100%', height: '100%', background: '#1a1a2e', padding: 60 }}>
        <h1 style={{ color: 'white', fontSize: 64, fontWeight: 'bold' }}>{title}</h1>
      </div>
    ),
    { width: 1200, height: 630 }
  )
}
// Use: /og?title=My%20Post%20Title as OG image URL
```

### Sitemap
```typescript
// app/sitemap.ts
import { MetadataRoute } from 'next'

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const posts = await getAllPosts()

  return [
    { url: 'https://yourapp.com', lastModified: new Date(), changeFrequency: 'monthly', priority: 1 },
    { url: 'https://yourapp.com/pricing', lastModified: new Date(), changeFrequency: 'monthly', priority: 0.8 },
    ...posts.map((post) => ({
      url: `https://yourapp.com/blog/${post.slug}`,
      lastModified: new Date(post.updatedAt),
      changeFrequency: 'weekly' as const,
      priority: 0.6,
    })),
  ]
}
```

### Robots
```typescript
// app/robots.ts
import { MetadataRoute } from 'next'

export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: '*', allow: '/', disallow: ['/api/', '/dashboard/'] },
    sitemap: 'https://yourapp.com/sitemap.xml',
  }
}
```

---

## SvelteKit — SEO Patterns

```svelte
<!-- src/routes/+layout.svelte -->
<script>
  import { page } from '$app/stores'
</script>

<svelte:head>
  <title>{$page.data.title ?? 'Default Title'}</title>
  <meta name="description" content={$page.data.description ?? 'Default description'} />
  <link rel="canonical" href="https://yourapp.com{$page.url.pathname}" />

  <!-- OG -->
  <meta property="og:title" content={$page.data.title} />
  <meta property="og:description" content={$page.data.description} />
  <meta property="og:image" content={$page.data.ogImage ?? '/og-default.png'} />
  <meta property="og:url" content="https://yourapp.com{$page.url.pathname}" />

  <!-- Twitter -->
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content={$page.data.title} />
  <meta name="twitter:image" content={$page.data.ogImage ?? '/og-default.png'} />
</svelte:head>
```

```typescript
// src/routes/blog/[slug]/+page.server.ts
export async function load({ params }) {
  const post = await getPost(params.slug)
  return {
    post,
    title: post.title,
    description: post.excerpt,
    ogImage: post.coverImage,
  }
}
```

---

## Astro — SEO (Built-in)

```astro
---
// src/layouts/BaseLayout.astro
const { title, description, ogImage = '/og-default.png' } = Astro.props
const canonicalURL = new URL(Astro.url.pathname, Astro.site)
---
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width" />
    <title>{title}</title>
    <meta name="description" content={description} />
    <link rel="canonical" href={canonicalURL} />
    <meta property="og:title" content={title} />
    <meta property="og:description" content={description} />
    <meta property="og:image" content={new URL(ogImage, Astro.site)} />
    <meta name="twitter:card" content="summary_large_image" />
    <!-- Sitemap auto-generated with @astrojs/sitemap integration -->
  </head>
  <body><slot /></body>
</html>
```

---

## JSON-LD Structured Data

### Organization (homepage)
```tsx
// components/JsonLd.tsx
export function OrganizationJsonLd() {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{
        __html: JSON.stringify({
          '@context': 'https://schema.org',
          '@type': 'Organization',
          name: 'Your Company',
          url: 'https://yourapp.com',
          logo: 'https://yourapp.com/logo.png',
          sameAs: ['https://twitter.com/yourhandle', 'https://github.com/youorg'],
        }),
      }}
    />
  )
}
```

### Blog Article
```tsx
export function ArticleJsonLd({ post }: { post: Post }) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{
        __html: JSON.stringify({
          '@context': 'https://schema.org',
          '@type': 'BlogPosting',
          headline: post.title,
          description: post.excerpt,
          image: post.coverImage,
          author: { '@type': 'Person', name: post.author },
          publisher: { '@type': 'Organization', name: 'Your Company', logo: '/logo.png' },
          datePublished: post.publishedAt,
          dateModified: post.updatedAt,
          mainEntityOfPage: { '@type': 'WebPage', '@id': `https://yourapp.com/blog/${post.slug}` },
        }),
      }}
    />
  )
}
```

### SaaS Product FAQ
```tsx
export function FaqJsonLd({ faqs }: { faqs: { q: string; a: string }[] }) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{
        __html: JSON.stringify({
          '@context': 'https://schema.org',
          '@type': 'FAQPage',
          mainEntity: faqs.map(({ q, a }) => ({
            '@type': 'Question',
            name: q,
            acceptedAnswer: { '@type': 'Answer', text: a },
          })),
        }),
      }}
    />
  )
}
```

---

## Performance Optimizations

### LCP (make main content load fast)
```tsx
// next/image with priority for above-fold images
<Image src="/hero.webp" alt="Hero" width={1200} height={600} priority />

// Preload critical fonts
// app/layout.tsx
import { Inter } from 'next/font/google'
const inter = Inter({ subsets: ['latin'], display: 'swap' })

// Preconnect to external origins
<link rel="preconnect" href="https://fonts.googleapis.com" />
```

### CLS (prevent layout shifts)
```tsx
// Always set width + height on images
<Image src={img} alt="..." width={800} height={400} />

// Reserve space for dynamic content
<div style={{ minHeight: '200px' }}>
  {isLoading ? <Skeleton /> : <Content />}
</div>

// Use Suspense boundaries with fallbacks that match content size
<Suspense fallback={<PostListSkeleton />}>
  <PostList />
</Suspense>
```

### INP (reduce interaction delay)
```tsx
// Debounce search inputs
const debouncedSearch = useDebouncedCallback(handleSearch, 300)

// Use useTransition for non-urgent updates
const [isPending, startTransition] = useTransition()
startTransition(() => { setFilteredItems(filter(items, query)) })

// Virtualize long lists
import { useVirtualizer } from '@tanstack/react-virtual'
```

---

## Content Strategy Checklist

- [ ] Each page has unique title + description
- [ ] Canonical URLs set on all pages
- [ ] sitemap.xml generated and submitted to Google Search Console
- [ ] robots.txt allows crawling of public pages
- [ ] OG image (1200×630) for every key page
- [ ] JSON-LD on homepage (Organization) and blog posts (Article)
- [ ] FAQ JSON-LD on pricing/feature pages
- [ ] Core Web Vitals measured (Lighthouse, PageSpeed Insights)
- [ ] LCP < 2.5s, CLS < 0.1, INP < 200ms
- [ ] Blog with 2+ posts per month targeting long-tail keywords
- [ ] Internal linking between related content
