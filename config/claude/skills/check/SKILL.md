---
name: check
description: Run pre-commit / pre-deploy checks. Runs lint, types, tests, and scans for secrets. Use before committing or deploying.
disable-model-invocation: true
---

Run all pre-commit checks on the current project.

## 1. Type check
```bash
pnpm typecheck 2>/dev/null || pnpm tsc --noEmit 2>/dev/null || npx tsc --noEmit 2>/dev/null
```

## 2. Lint
```bash
pnpm lint 2>/dev/null || npx eslint . 2>/dev/null
```

## 3. Tests
```bash
pnpm test:run 2>/dev/null || pnpm test -- --run 2>/dev/null
```

## 4. Secret scan (staged files only)
```bash
git diff --staged | grep -iE "(sk_live|sk_test|eyJ[a-zA-Z0-9]{20,}|password\s*=|secret\s*=|api_key\s*=)" && echo "⚠️  Possible secret in staged changes — review before committing" || echo "✓ No obvious secrets in staged changes"
```

## 5. Dependency audit
```bash
pnpm audit --audit-level=high 2>/dev/null || echo "audit unavailable"
```

## Report

After running all checks, print a summary:
```
✓ Types — OK
✓ Lint — OK
✓ Tests — 42 passed
✓ Secrets — clean
⚠️ Audit — 1 high severity (describe it)
```

Fix any failures before proceeding. For audit issues, assess if the package is actually used in a way that exposes the vulnerability.
