---
name: debug
description: Systematically debug an issue. Use when something is broken and you need to find and fix the root cause.
disable-model-invocation: true
---

Systematically debug the issue described in $ARGUMENTS (or ask me to describe it if no arguments provided).

## Process

### 1. Reproduce
- Get the exact error message, stack trace, or unexpected behaviour
- Identify the minimal steps to reproduce
- Confirm: is it consistent or intermittent?

### 2. Locate
- Read the stack trace — start at the top-most frame in **our code** (not library internals)
- `grep` for the function/method/route mentioned in the error
- Read the relevant files — understand what they're supposed to do

### 3. Hypothesise
- Form 1-3 specific hypotheses about what could cause this
- Rank by likelihood — start with the most obvious

### 4. Verify (don't fix yet)
- Add targeted logging or run the code mentally
- Confirm or rule out each hypothesis
- Check recent git changes in the affected files: `git log -10 --oneline -- <file>`

### 5. Fix
- Make the minimal change that fixes the root cause
- Do not refactor surrounding code while fixing
- Do not add error handling for the impossible case — fix the actual bug

### 6. Verify the fix
```bash
pnpm typecheck 2>/dev/null || pnpm tsc --noEmit 2>/dev/null
pnpm test:run 2>/dev/null || echo "no tests"
```

### 7. Commit
```bash
git commit -m "fix(scope): short description of what was wrong"
```

## Common patterns to check first
- `undefined` access → missing null check, wrong async/await, race condition
- Type error → mismatched schema, Zod mismatch, DB types out of date
- Auth error → `getUser()` vs `getSession()`, missing RLS policy, wrong client (browser vs server)
- Network error → wrong env var, CORS, missing header, webhook signature failure
- Build error → missing env var in `env.ts`, circular import, missing `'use client'`
