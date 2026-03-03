Run pre-commit / pre-deploy checks on the current project. Checks lint, types, tests, and scans staged files for secrets.

## Step 1 — Lint

```bash
pnpm lint
```

If no `lint` script exists, try `pnpm eslint src/` or `pnpm biome check src/`.

## Step 2 — Type check

```bash
pnpm typecheck
```

If no `typecheck` script, try `npx tsc --noEmit`.

## Step 3 — Tests

```bash
pnpm test:run     # Vitest (no watch)
```

If no `test:run`, try `pnpm test -- --run` or `pnpm jest --passWithNoTests`.

## Step 4 — Secret scan

Check staged files for accidentally committed secrets:

```bash
git diff --staged | grep -E "(sk_live_|sk_test_|ghp_|eyJhbGci|password\s*=|secret\s*=|api_key\s*=)" | grep -v "\.env" | head -20
```

Flag any matches as **must fix before committing**.

## Step 5 — Report

```
## Check Results

✅ Lint        — passed
✅ Types       — passed
✅ Tests       — 42 passed, 0 failed
✅ Secrets     — none found

Ready to commit / deploy.
```

Or if anything failed:
```
## Check Results

✅ Lint        — passed
❌ Types       — 3 errors in src/lib/billing.ts
✅ Tests       — passed
✅ Secrets     — none found

Fix type errors before committing. Run /debug if you need help.
```

Don't fix the errors automatically — just report them clearly. The user decides whether to fix or proceed.
