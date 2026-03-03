---
name: turborepo
description: Turborepo monorepo setup for apps/ + packages/ structure. Shared packages for types, Zod validators, Supabase client, utils, and design tokens. Next.js + SvelteKit + Expo + Astro in one repo. Pipeline config with caching. Use when setting up or working in a monorepo.
---

You are a Turborepo monorepo expert. Apply these patterns for TypeScript monorepos with multiple apps.

---

## Monorepo Structure

```
my-product/
├── apps/
│   ├── web/               # Next.js or SvelteKit web app
│   ├── mobile/            # Expo React Native app
│   └── landing/           # Astro marketing site
├── packages/
│   ├── db/                # Supabase client + generated types
│   ├── types/             # Shared TypeScript types/interfaces
│   ├── validators/        # Zod schemas (shared validation)
│   ├── utils/             # Pure utility functions
│   └── design/            # Design tokens (colors, spacing)
├── turbo.json
├── package.json
└── pnpm-workspace.yaml
```

---

## Initial Setup

```bash
# Create new Turborepo
npx create-turbo@latest my-product --package-manager pnpm

# Or initialize in existing project
pnpm add turbo --save-dev -w
```

### pnpm-workspace.yaml
```yaml
packages:
  - 'apps/*'
  - 'packages/*'
```

### Root package.json
```json
{
  "name": "my-product",
  "private": true,
  "scripts": {
    "dev": "turbo run dev",
    "build": "turbo run build",
    "lint": "turbo run lint",
    "type-check": "turbo run type-check",
    "clean": "turbo run clean && rm -rf node_modules"
  },
  "devDependencies": {
    "turbo": "latest",
    "typescript": "^5.0.0"
  }
}
```

### turbo.json
```json
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env.*local"],
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "!.next/cache/**", ".svelte-kit/**", "dist/**", ".output/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "lint": {
      "outputs": []
    },
    "type-check": {
      "dependsOn": ["^build"],
      "outputs": []
    },
    "clean": {
      "cache": false
    }
  }
}
```

---

## Shared Packages

### packages/db — Supabase Client
```typescript
// packages/db/package.json
{
  "name": "@my-product/db",
  "version": "0.0.1",
  "exports": {
    ".": "./src/index.ts",
    "./types": "./src/types/db.types.ts"
  },
  "dependencies": {
    "@supabase/supabase-js": "^2.0.0"
  }
}

// packages/db/src/index.ts
export { createBrowserClient, createServerClient } from './client'
export type { Database } from './types/db.types'

// packages/db/src/client.ts
import { createBrowserClient as createSupabaseBrowser } from '@supabase/ssr'
import type { Database } from './types/db.types'

export function createBrowserClient() {
  return createSupabaseBrowser<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}

// Generate types: supabase gen types typescript --local > packages/db/src/types/db.types.ts
```

### packages/types — Shared TypeScript Types
```typescript
// packages/types/package.json
{
  "name": "@my-product/types",
  "version": "0.0.1",
  "exports": { ".": "./src/index.ts" }
}

// packages/types/src/index.ts
export interface User {
  id: string
  email: string
  full_name: string | null
  avatar_url: string | null
  created_at: string
}

export interface Organization {
  id: string
  name: string
  slug: string
  plan: 'free' | 'pro' | 'enterprise'
  created_at: string
}

export type Plan = 'free' | 'pro' | 'enterprise'
export type Role = 'owner' | 'admin' | 'member'

export interface ApiResponse<T> {
  data: T | null
  error: string | null
}
```

### packages/validators — Zod Schemas
```typescript
// packages/validators/package.json
{
  "name": "@my-product/validators",
  "version": "0.0.1",
  "exports": { ".": "./src/index.ts" },
  "dependencies": { "zod": "^3.0.0" }
}

// packages/validators/src/index.ts
import { z } from 'zod'

export const createOrgSchema = z.object({
  name: z.string().min(2).max(50),
  slug: z.string().min(2).max(30).regex(/^[a-z0-9-]+$/),
})

export const updateProfileSchema = z.object({
  full_name: z.string().min(1).max(100).optional(),
  avatar_url: z.string().url().optional(),
})

export const inviteTeamSchema = z.object({
  email: z.string().email(),
  role: z.enum(['admin', 'member']),
})

export type CreateOrgInput = z.infer<typeof createOrgSchema>
export type UpdateProfileInput = z.infer<typeof updateProfileSchema>
```

### packages/utils — Pure Utilities
```typescript
// packages/utils/src/index.ts

// Formatters
export function formatCurrency(cents: number, currency = 'USD'): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency }).format(cents / 100)
}

export function formatDate(date: string | Date): string {
  return new Intl.DateTimeFormat('en-US', { month: 'short', day: 'numeric', year: 'numeric' }).format(new Date(date))
}

export function formatRelativeTime(date: string | Date): string {
  const rtf = new Intl.RelativeTimeFormat('en', { numeric: 'auto' })
  const diff = (new Date(date).getTime() - Date.now()) / 1000
  if (Math.abs(diff) < 60) return rtf.format(Math.round(diff), 'second')
  if (Math.abs(diff) < 3600) return rtf.format(Math.round(diff / 60), 'minute')
  if (Math.abs(diff) < 86400) return rtf.format(Math.round(diff / 3600), 'hour')
  return rtf.format(Math.round(diff / 86400), 'day')
}

// String utils
export function slugify(str: string): string {
  return str.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')
}

export function truncate(str: string, maxLength: number): string {
  if (str.length <= maxLength) return str
  return str.slice(0, maxLength - 3) + '...'
}

export function generateId(prefix?: string): string {
  const id = Math.random().toString(36).slice(2, 11)
  return prefix ? `${prefix}_${id}` : id
}
```

### packages/design — Design Tokens
```typescript
// packages/design/src/tokens.ts
export const colors = {
  brand: {
    50: '#eff6ff',
    500: '#3b82f6',
    600: '#2563eb',
    700: '#1d4ed8',
    900: '#1e3a8a',
  },
  // ... etc
} as const

export const spacing = {
  xs: 4, sm: 8, md: 16, lg: 24, xl: 32, '2xl': 48,
} as const

// In tailwind.config.ts — extend with these tokens
// In NativeWind — same tokens via withTV or direct usage
```

---

## Using Packages in Apps

```typescript
// In any app (web, mobile, landing):
import { createBrowserClient } from '@my-product/db'
import type { User, Organization } from '@my-product/types'
import { createOrgSchema } from '@my-product/validators'
import { formatCurrency, slugify } from '@my-product/utils'
```

```json
// apps/web/package.json
{
  "dependencies": {
    "@my-product/db": "workspace:*",
    "@my-product/types": "workspace:*",
    "@my-product/validators": "workspace:*",
    "@my-product/utils": "workspace:*"
  }
}
```

---

## Running the Monorepo

```bash
# Dev all apps simultaneously
pnpm dev

# Dev only specific app
pnpm dev --filter=web
pnpm dev --filter=mobile
pnpm dev --filter=landing

# Build only what changed (Turborepo caches)
pnpm build --filter=web...  # web + all its dependencies

# Run command in specific package
pnpm --filter=@my-product/db supabase gen types typescript --local > src/types/db.types.ts

# Install package in specific app
pnpm add stripe --filter=web
pnpm add @stripe/stripe-js --filter=web
```

---

## Expo in Turborepo

```json
// apps/mobile/package.json
{
  "name": "mobile",
  "scripts": {
    "dev": "expo start",
    "build": "eas build",
    "type-check": "tsc --noEmit"
  },
  "dependencies": {
    "@my-product/types": "workspace:*",
    "@my-product/validators": "workspace:*",
    "@my-product/utils": "workspace:*"
  }
}
```

```javascript
// apps/mobile/metro.config.js — required for workspace packages
const { getDefaultConfig } = require('expo/metro-config')
const { FileStore } = require('metro-cache')
const path = require('path')

const projectRoot = __dirname
const workspaceRoot = path.resolve(projectRoot, '../..')

const config = getDefaultConfig(projectRoot)
config.watchFolders = [workspaceRoot]
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, 'node_modules'),
  path.resolve(workspaceRoot, 'node_modules'),
]
config.cacheStores = [new FileStore({ root: path.join(projectRoot, '.metro-cache') })]

module.exports = config
```

---

## TypeScript Config

```json
// packages/typescript-config/base.json (shared tsconfig)
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "skipLibCheck": true,
    "isolatedModules": true,
    "esModuleInterop": true,
    "declaration": true,
    "declarationMap": true
  }
}
```

---

## What Can Be Shared

| Package | Next.js | SvelteKit | Expo | Astro |
|---------|---------|-----------|------|-------|
| `types` | ✅ | ✅ | ✅ | ✅ |
| `validators` (Zod) | ✅ | ✅ | ✅ | ✅ |
| `db` (Supabase) | ✅ | ✅ | ✅ | ✅ |
| `utils` (pure JS) | ✅ | ✅ | ✅ | ✅ |
| `design` (tokens) | ✅ | ✅ | ✅ | ✅ |
| JSX components | ✅ | ❌ | ❌ | ❌ |
| Svelte components | ❌ | ✅ | ❌ | ❌ |

**JSX components cannot be shared between Next.js and Expo.** But types + validators + Supabase + utils is 40–60% of the value.
