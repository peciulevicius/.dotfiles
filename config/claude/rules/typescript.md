# TypeScript Rules

## Strict Mode Always
```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true
  }
}
```

## No `any` — Use These Instead
```typescript
unknown          // when type is truly unknown — narrow it before use
Record<string, unknown>  // for dynamic objects
never            // for exhaustive checks
satisfies        // validate shape without widening type
```

## Zod for Runtime Validation
```typescript
// Validate all external data: API inputs, form data, env vars, webhooks
import { z } from 'zod'

const schema = z.object({ email: z.string().email(), name: z.string().min(1) })
type Input = z.infer<typeof schema>  // derive type from schema, not the other way

// Env vars
const env = z.object({
  DATABASE_URL: z.string().url(),
  NEXT_PUBLIC_APP_URL: z.string().url(),
}).parse(process.env)
```

## Naming
```typescript
// Types/interfaces: PascalCase
type UserRole = 'owner' | 'admin' | 'member'
interface CreateUserInput { email: string; name: string }

// Functions: camelCase, verb-first
async function fetchUserById(id: string): Promise<User> {}
function formatCurrency(cents: number): string {}

// Constants: SCREAMING_SNAKE_CASE for true constants
const MAX_FILE_SIZE = 5 * 1024 * 1024

// Files: kebab-case
// user-profile.ts, create-org.ts (not userProfile.ts)
```

## Prefer `type` Over `interface` for New Code
```typescript
// type — composable, works with unions/intersections
type ApiResponse<T> = { data: T; error: null } | { data: null; error: string }

// interface — use only when extending is intentional
interface Repository<T> { findById(id: string): Promise<T | null> }
```

## Error Handling
```typescript
// Use Result pattern for expected failures
type Result<T, E = Error> = { ok: true; value: T } | { ok: false; error: E }

// Never swallow errors silently
try { ... } catch (e) {
  // always: log + rethrow, or return error, or show to user
  throw e  // or: return { ok: false, error: e }
}
```

## Import Order (enforced by ESLint)
```typescript
// 1. Node built-ins
import { readFile } from 'fs/promises'
// 2. External packages
import { z } from 'zod'
// 3. Internal packages (@my-product/*)
import { formatCurrency } from '@my-product/utils'
// 4. Local imports (@/ alias)
import { Button } from '@/components/ui/button'
// 5. Relative imports (avoid when @/ works)
import { helper } from './helper'
```
