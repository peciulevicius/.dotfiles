Review the current changes or a specified PR.

## If $ARGUMENTS is a PR number or URL
1. Run `gh pr view $ARGUMENTS` for description
2. Run `gh pr diff $ARGUMENTS` for the diff

## If no argument (review local changes)
1. Run `git diff HEAD` for unstaged changes
2. Run `git diff --staged` for staged changes
3. If nothing, run `git diff main..HEAD` for branch changes

## Review Checklist

For each changed file, check:

**Correctness**
- Does the logic do what it claims?
- Are there off-by-one errors, wrong conditions, missing cases?
- Are async operations awaited correctly?

**Security**
- Is user input validated (Zod)?
- Are secrets server-side only?
- Is RLS in place for any new tables?
- Could this introduce XSS, injection, or auth bypass?

**TypeScript**
- No `any` used?
- Are types inferred correctly or explicitly typed?
- Are error cases typed and handled?

**Performance**
- Are there N+1 query patterns?
- Are heavy computations memoized?
- Are images optimized?

**Conventions**
- Does it follow the patterns in `.claude/CLAUDE.md`?
- Consistent naming?
- No unnecessary abstractions?

## Output Format

```
## Review

### ✅ Looks good
- [thing that's done well]

### 🔴 Must fix
- `file.ts:42` — [issue and suggested fix]

### 🟡 Should fix
- `file.ts:67` — [issue and suggested fix]

### 💡 Suggestions
- [optional improvements]
```

Focus on real issues. Don't nitpick style if it's consistent.
