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

## Step 2 — Move to In Progress (REQUIRED)

**Before doing anything else**, move the issue to "In Progress" on the project board.

```bash
# Get project and field IDs (run once, cache mentally)
PROJECT_ID=$(gh project list --owner peciulevicius --format json | python3 -c "import json,sys; [print(p['id']) for p in json.load(sys.stdin)['projects'] if p['number']==15]")

# Get Status field ID and option IDs
gh project field-list 15 --format json | python3 -c "
import json, sys
for f in json.load(sys.stdin)['fields']:
    if f['name'] == 'Status':
        print('field:', f['id'])
        for o in f.get('options',[]): print(o['name'], o['id'])
"

# Get item ID for this issue
gh project item-list 15 --format json | python3 -c "
import json, sys
for i in json.load(sys.stdin)['items']:
    if i['content'].get('number') == <ISSUE_NUMBER>:
        print(i['id'])
"

# Move to In Progress (option id: 47fc9ee4)
gh project item-edit \
  --project-id "$PROJECT_ID" \
  --id <ITEM_ID> \
  --field-id PVTSSF_lAHOApFIks4BVahZzhQ2e7o \
  --single-select-option-id 47fc9ee4
```

Known project constants (peciulevicius/.dotfiles, project #15):
- Project ID: `PVT_kwHOApFIks4BVahZ`
- Status field ID: `PVTSSF_lAHOApFIks4BVahZzhQ2e7o`
- Backlog: `f75ad846` | Ready: `61e4505c` | In progress: `47fc9ee4` | In review: `df73e18b` | Done: `98236657`

## Step 3 — Understand the codebase

Before writing any code:
- Read CLAUDE.md for conventions, stack, and rules
- Locate files most likely affected (grep for related function names, route paths, component names)
- Read 2-3 adjacent files to understand existing patterns — match them exactly
- Check `@/components/ui/` and `@/lib/` for reusable pieces

## Step 4 — Plan

State briefly:
- Which files change and why
- New files needed (if any)
- DB migrations needed (new table → RLS policy → type generation)
- New API routes needed
- Tests to write

If requirements are ambiguous or scope is large, ask **one focused question** before building. For clear issues, proceed immediately.

## Step 5 — Implement

Build the feature following the project stack (Next.js or SvelteKit, Supabase, Stripe, Tailwind — check CLAUDE.md):
- TypeScript strict mode, no `any`
- Zod on every new API boundary
- RLS on every new Supabase table
- shadcn/ui for new UI components (check existing ones first)
- pnpm, never npm

## Step 6 — Verify (fix failures before continuing)

```bash
pnpm typecheck 2>/dev/null || pnpm tsc --noEmit 2>/dev/null || echo "no typecheck"
pnpm lint 2>/dev/null || echo "no lint"
pnpm test:run 2>/dev/null || echo "no tests"
```

If typecheck or lint fails: fix it, don't skip it.

## Step 7 — Self-review

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
- **Manual steps remaining:** if any ACs require human action (UI clicks, external service setup), do NOT close the issue — note them explicitly

Fix any issues found before committing. If a security issue is found, fix it and note it in the PR.

## Step 8 — Commit (feature branch, never main)

Create a feature branch first:

```bash
git checkout -b feat/<short-description>   # or fix/ chore/ docs/
```

Stage only the files you changed (not `git add .`):

```bash
git add <specific files>
git commit -m "feat(scope): short description

Closes #<issue-number>"
```

Only add `Closes #N` if ALL acceptance criteria are done — including any manual steps. If manual steps remain, omit `Closes` and note them in the PR body instead.

## Step 9 — Open PR (do NOT merge it)

```bash
git push -u origin <branch>

gh pr create \
  --title "<same as commit subject line>" \
  --body "$(cat <<'EOF'
## What
<1-2 sentence summary of what changed>

## Why
<context from the issue>

## Test plan
- [ ] <what to manually verify>
- [ ] <edge cases to check>

## Manual steps remaining
<list any steps that still require human action — UI config, external service setup, etc.>
<if none, omit this section>

Closes #<issue-number>
EOF
)"
```

**Never merge the PR yourself.** Leave it open for review.

## Step 10 — Move to In Review

After opening the PR, move the issue to "In Review" on the project board:

```bash
gh project item-edit \
  --project-id PVT_kwHOApFIks4BVahZ \
  --id <ITEM_ID> \
  --field-id PVTSSF_lAHOApFIks4BVahZzhQ2e7o \
  --single-select-option-id df73e18b
```

## Step 11 — Done

Print:
- List of files changed
- PR URL
- Acceptance criteria status (✅ done / ⚠️ needs manual action / ❌ out of scope)
- Any follow-up issues worth creating
