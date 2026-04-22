---
name: jira
description: Implement a Jira ticket. Use when the user pastes a Jira ticket and wants it implemented.
---

Implement the Jira ticket provided in $ARGUMENTS (or pasted in context).

## Step 1 — Read the ticket

Extract:
- **Title** — what's being built
- **Description** — context and requirements
- **Acceptance criteria** — these are your definition of done
- **Labels / type** — bug, feature, tech debt, etc.

If acceptance criteria are missing or vague, list your assumptions before building and confirm with the user.

## Step 2 — Understand the codebase

Before touching any code:
- Read CLAUDE.md for conventions
- Find files most likely affected
- Read adjacent code for existing patterns — match them
- Check for reusable utilities or components

## Step 3 — Plan

For anything that touches >3 files or introduces new data models, briefly state:
- What files change
- Any new DB tables (need migration + RLS + types)
- Any new API routes
- Tests to write

Skip this for simple, clearly-scoped tickets.

## Step 4 — Implement

Build the feature following the project stack:
- TypeScript strict, no `any`
- Zod for all API inputs and form data
- RLS on any new Supabase tables
- pnpm, not npm

## Step 5 — Verify

```bash
pnpm typecheck 2>/dev/null || pnpm tsc --noEmit 2>/dev/null || echo "no typecheck"
pnpm lint 2>/dev/null || echo "no lint"
pnpm test:run 2>/dev/null || echo "no tests"
```

Fix any failures before continuing.

## Step 6 — Commit and summarise

Create a conventional commit referencing the ticket ID if available.

Then confirm each acceptance criterion is met:
- ✅ AC 1: [status]
- ✅ AC 2: [status]
- ⚠️ AC 3: [any caveats]
