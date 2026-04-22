---
name: develop
description: Implement a GitHub Issue end-to-end — read the issue, plan, build, test, commit, open PR. Use when given a GitHub issue number, URL, or feature description.
---

Implement the task described in $ARGUMENTS end-to-end.

## Step 1 — Read the task

Determine the input type:
- Issue number (e.g. `42`, `#42`) → run `gh issue view <number> --json title,body,labels,comments`
- GitHub URL → extract owner/repo/number, run the same command
- Raw text / screenshot → treat as the requirement directly

If it's an issue, read the full JSON output: title, body, acceptance criteria, labels, linked issues, any comments with design decisions.

## Step 2 — Understand the codebase

Before writing a single line:
- Read CLAUDE.md for project conventions
- Find the files most likely affected (`grep`, `glob` by feature area)
- Read existing patterns in adjacent code — match them exactly
- Check for existing utilities or components that can be reused

## Step 3 — Plan (ask if anything is unclear)

Draft a short implementation plan:
- Which files change and why
- Any new files needed
- Database migrations needed (new tables → RLS → types)
- API routes needed
- Tests to write

If the requirements are ambiguous or the scope is large, **ask one focused question** before building. For clear issues, skip ahead.

## Step 4 — Implement

Build the feature:
- Follow the project stack (check CLAUDE.md — Next.js or SvelteKit, Supabase, Stripe, etc.)
- TypeScript strict mode, no `any`
- Zod for all new API inputs
- RLS on any new Supabase tables
- shadcn/ui components for UI (check `@/components/ui/` first)
- pnpm, never npm

## Step 5 — Verify

Run these in order, stop and fix any failure before continuing:
```bash
pnpm typecheck 2>/dev/null || pnpm tsc --noEmit 2>/dev/null || echo "no typecheck script"
pnpm lint 2>/dev/null || echo "no lint script"
pnpm test:run 2>/dev/null || echo "no tests"
pnpm build 2>/dev/null || echo "skipping build"
```

## Step 6 — Commit

Use `/commit` skill or:
```bash
git add <specific files>
git commit -m "feat(scope): description

Closes #<issue-number>"
```

Conventional commit type based on what changed:
- New feature → `feat`
- Bug fix → `fix`
- Refactor only → `refactor`

## Step 7 — Open PR

```bash
gh pr create \
  --title "<same as commit subject>" \
  --body "## What
<1-2 sentence summary>

## Why
<context from the issue>

## Test plan
- [ ] <what you manually verified>
- [ ] <edge cases>

Closes #<issue-number>"
```

## Output

When done, print:
- Files changed (list)
- PR URL
- Any follow-up items that were out of scope
