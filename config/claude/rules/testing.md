# Testing Rules

## Stack
- **Unit/Integration:** Vitest + React Testing Library (web), Jest (legacy)
- **E2E:** Playwright
- **Mobile:** Jest + React Native Testing Library

## What to Test
```
✅ Test: business logic, data transformations, complex hooks, API handlers
✅ Test: error paths, edge cases, boundary conditions
❌ Skip: implementation details, internals of third-party libs
❌ Skip: snapshot tests (too brittle, low signal)
❌ Skip: testing the framework itself
```

## Vitest Setup
```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test/setup.ts'],
  },
  resolve: { alias: { '@': '/src' } },
})

// src/test/setup.ts
import '@testing-library/jest-dom'
```

## React Testing Library
```tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'

// Prefer: userEvent over fireEvent (more realistic)
// Prefer: getByRole over getByTestId (more accessible)
// Prefer: findBy* for async (returns promise) over waitFor + getBy*

test('submits form with valid data', async () => {
  const user = userEvent.setup()
  render(<LoginForm onSuccess={vi.fn()} />)

  await user.type(screen.getByLabelText('Email'), 'user@example.com')
  await user.type(screen.getByLabelText('Password'), 'secret123')
  await user.click(screen.getByRole('button', { name: 'Sign in' }))

  await waitFor(() => {
    expect(screen.getByText('Welcome!')).toBeInTheDocument()
  })
})
```

## API Route Testing (Next.js)
```typescript
// test the handler function directly — no HTTP layer needed
import { POST } from '@/app/api/items/route'

test('returns 400 for invalid input', async () => {
  const req = new Request('http://localhost/api/items', {
    method: 'POST',
    body: JSON.stringify({ name: '' }),  // invalid
  })

  const res = await POST(req)
  expect(res.status).toBe(400)

  const body = await res.json()
  expect(body.error).toBeDefined()
})
```

## Server Actions
```typescript
// test server actions directly
import { createItem } from '@/lib/actions/items'

test('creates item for authenticated user', async () => {
  vi.mocked(getUser).mockResolvedValue({ id: 'user-1' })

  const formData = new FormData()
  formData.set('name', 'Test Item')

  const result = await createItem(formData)
  expect(result).not.toHaveProperty('error')
})
```

## Mocking
```typescript
// vi.mock at module level
vi.mock('@/lib/supabase/server', () => ({
  createServerClient: vi.fn(() => mockSupabaseClient),
}))

// Factory pattern for complex mocks
function createMockUser(overrides?: Partial<User>): User {
  return { id: 'user-1', email: 'test@example.com', ...overrides }
}

// Spy on specific methods
const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
```

## Playwright (E2E)
```typescript
// playwright.config.ts — test against dev server
import { defineConfig } from '@playwright/test'
export default defineConfig({
  testDir: './e2e',
  use: { baseURL: 'http://localhost:3000' },
  webServer: { command: 'pnpm dev', url: 'http://localhost:3000' },
})

// e2e/auth.spec.ts
import { test, expect } from '@playwright/test'

test('user can sign in', async ({ page }) => {
  await page.goto('/login')
  await page.getByLabel('Email').fill('user@example.com')
  await page.getByLabel('Password').fill('password')
  await page.getByRole('button', { name: 'Sign in' }).click()

  await expect(page).toHaveURL('/dashboard')
  await expect(page.getByText('Welcome back')).toBeVisible()
})
```

## File Naming
```
src/
  components/
    button.tsx
    button.test.tsx        # co-located unit tests
  lib/
    format-currency.ts
    format-currency.test.ts
e2e/
  auth.spec.ts             # E2E tests at root
  checkout.spec.ts
```

## Run Commands
```bash
pnpm test              # unit + integration (watch mode)
pnpm test:run          # CI (no watch)
pnpm test:e2e          # Playwright E2E
pnpm test:coverage     # coverage report
```
