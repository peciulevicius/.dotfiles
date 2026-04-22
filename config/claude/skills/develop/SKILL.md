---
name: develop
description: Implement a GitHub Issue end-to-end — read the issue, plan, build, self-review, test, commit, open PR. Use when given a GitHub issue number, URL, or feature description.
---

Implement the task described in $ARGUMENTS end-to-end, without stopping for confirmation unless something is genuinely ambiguous.

## Step 1 — Read the task

Determine the input type:
- Issue number (`42`, `#42`) → `gh issue view <number> --json title,body,labels,comments,assignees`
- GitHub URL → extract owner/repo/number, run the same command
- Raw text or screenshot → treat it as the requirement directly

Read everything: title, body, acceptance criteria, labels, comments (comments often have design decisions).

If the repo has a GitHub Project board, move the issue to "In Progress":
```bash
gh issue edit <number> --add-label "in-progress" 2>/dev/null || true
```

## Step 2 — Understand the codebase

Before writing any code:
- Read CLAUDE.md for conventions, stack, and rules
- Locate files most likely affected (grep for related function names, route paths, component names)
- Read 2-3 adjacent files to understand existing patterns — match them exactly
- Check `@/components/ui/` and `@/lib/` for reusable pieces

## Step 3 — Plan

State briefly:
- Which files change and why
- New files needed (if any)
- DB migrations needed (new table → RLS policy → type generation)
- New API routes needed
- Tests to write

If requirements are ambiguous or scope is large, ask **one focused question** before building. For clear issues, proceed immediately.

## Step 4 — Implement

Build the feature following the project stack (Next.js or SvelteKit, Supabase, Stripe, Tailwind — check CLAUDE.md):
- TypeScript strict mode, no `any`
- Zod on every new API boundary
- RLS on every new Supabase table
- shadcn/ui for new UI components (check existing ones first)
- pnpm, never npm

## Step 5 — Verify (fix failures before continuing)

```bash
pnpm typecheck 2>/dev/null || pnpm tsc --noEmit 2>/dev/null || echo "no typecheck"
pnpm lint 2>/dev/null || echo "no lint"
pnpm test:run 2>/dev/null || echo "no tests"
```

If typecheck or lint fails: fix it, don't skip it.

## Step 6 — Self-review

Before committing, review your own diff critically:

```bash
git diff
```

Check for:
- **Security:** any `userId` from request body? missing Zod validation? missing RLS? secrets in code?
- **Correctness:** does every acceptance criterion actually work? any edge cases missed?
- **TypeScript:** any `any`, non-null assertions without reason, missing error narrowing?
- **Conventions:** matches existing patterns in the codebase? correct file naming? pnpm not npm?
- **Scope creep:** did you change anything outside what the issue asked for?

Fix any issues found before committing. If a security issue is found, fix it and note it in the PR.

## Step 7 — Commit

Stage only the files you changed (not `git add .`):

```bash
git add <specific files>
git commit -m "feat(scope): short description

Closes #<issue-number>"
```

Commit type: `feat` for new features, `fix` for bugs, `refactor` for restructuring.

## Step 8 — Open PR

```bash
gh pr create \
  --title "<same as commit subject line>" \
  --body "$(cat <<'EOF'
## What
<1-2 sentence summary of what changed>

## Why
<context from the issue — what problem this solves>

## Test plan
- [ ] <what to manually verify>
- [ ] <edge cases to check>

Closes #<issue-number>
EOF
)"
```

## Step 9 — Done

Print:
- List of files changed
- PR URL
- Acceptance criteria status (✅ done / ⚠️ partial / ❌ out of scope)
- Any follow-up issues worth creating
