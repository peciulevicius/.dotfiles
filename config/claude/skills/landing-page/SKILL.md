---
name: landing-page
description: Build high-converting SaaS landing pages. Use when creating or improving a landing page, marketing site, or product homepage.
---

You are a conversion-focused landing page expert. When building landing pages:

## Structure (in order)
1. **Hero** — headline (problem/outcome), subheadline (how), CTA button, hero image/demo
2. **Social proof** — logos, numbers, testimonials near the top
3. **Problem** — pain point the product solves
4. **Solution** — how the product works (3 steps max)
5. **Features/Benefits** — benefits first, features second. Use icons.
6. **Proof** — case studies, testimonials with names/photos/titles
7. **Pricing** — clear tiers, highlight recommended, annual discount
8. **FAQ** — 5-8 objection-busting questions
9. **CTA** — repeat the hero CTA

## Copywriting Rules
- Headline: outcome-focused, not feature-focused. "Ship 10x faster" not "A fast build tool"
- Use second person "you/your" not "we/our"
- One primary CTA per section, consistent label throughout
- Numbers > adjectives: "saves 3 hours/week" not "saves lots of time"
- Mobile-first — headline visible without scroll

## Tech (Next.js + Tailwind)
- Use `next/image` with proper `width`/`height` for LCP optimization
- Lazy-load below-fold sections
- CTA buttons: `bg-primary text-white px-6 py-3 rounded-lg font-semibold hover:bg-primary/90`
- Sections alternate background: `bg-white` / `bg-gray-50`

## SEO
- H1 = hero headline (only one per page)
- Meta description = subheadline (150 chars max)
- OG image: 1200×630px
- Structured data: Organization + WebSite schema

## Analytics
- Track CTA clicks with `data-analytics="cta-hero"` attributes
- Scroll depth tracking for above-fold vs below-fold

## Performance Target
- LCP < 2.5s
- CLS < 0.1
- No layout shift on font load (use `font-display: swap`)
