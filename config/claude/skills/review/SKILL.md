---
name: review
description: Review the current changes or a specified PR. Checks for correctness, security, performance, and adherence to project conventions.
disable-model-invocation: true
---

Review the code changes in $ARGUMENTS (PR number) or the current branch diff if no argument given.

## 1. Get the diff

If given a PR number:
```bash
gh pr diff <number>
gh pr view <number> --json title,body,labels
```

If reviewing current branch:
```bash
git diff main...HEAD
git log main...HEAD --oneline
```

## 2. Review checklist

Go through each changed file. Flag issues under these categories:

### Correctness
- Logic errors, off-by-one, wrong conditional
- Missing error handling for realistic failure modes
- Async/await gaps (missing await, unhandled promise)
- Race conditions

### Security (always check these)
- `userId` from request body instead of session → flag immediately
- Missing Zod validation on API inputs
- Missing RLS on new Supabase tables
- Secrets in code or `NEXT_PUBLIC_` for server-only keys
- Stripe webhooks without `constructEvent()`
- SQL injection risk (rare with Supabase client, but check raw queries)
- XSS via `dangerouslySetInnerHTML` without sanitisation

### TypeScript
- `any` usage → flag, suggest proper type
- Non-null assertions (`!`) without justification
- Missing error narrowing

### Performance
- N+1 queries (loop with DB call inside)
- Missing indexes for new query patterns
- Unnecessary re-renders (missing memo/callback)
- Large bundles (heavy imports in client components)

### Conventions (match this project)
- Conventional commit format
- kebab-case file names
- Server component by default, `'use client'` only when needed
- pnpm not npm
- No Co-Authored-By trailers

## 3. Format the review

```
## Review: <PR title or branch name>

### ✅ Looks good
- [what's well done]

### ⚠️ Suggestions
- `file.ts:42` — [suggestion, not blocking]

### ❌ Must fix
- `file.ts:17` — [blocking issue with explanation]

### Summary
[1-2 sentence overall assessment — ship / needs work / needs discussion]
```

Approve small/clean changes directly. For large changes, focus on the highest-risk areas first.
