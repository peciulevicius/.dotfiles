# Git Rules

## Conventional Commits
```
type(scope): short description   ← subject, max 72 chars, imperative, no period

[optional body]                  ← explain WHY, not what. Blank line after subject.
```

Types:
- `feat` — new feature
- `fix` — bug fix
- `chore` — maintenance, deps, config
- `docs` — documentation only
- `refactor` — code change with no behaviour change
- `test` — adding/fixing tests
- `style` — formatting, no logic change
- `perf` — performance improvement

Examples:
```
feat(auth): add magic link sign-in
fix(billing): prevent double-charge on retry
chore(deps): upgrade supabase-js to v2.39
docs(api): add webhook payload examples
refactor(dashboard): extract useMetrics hook
```

## Branch Naming
```
feat/short-description        # new features
fix/short-description         # bug fixes
chore/short-description       # maintenance
```

## Rules
- No `Co-Authored-By` trailers
- No `--no-verify` (fix the hook instead)
- No force-push to `main` / `master`
- Prefer new commits over `--amend` on shared branches
- Stage specific files, not `git add .` (avoids committing secrets)
- Never commit `.env`, `.env.local`, or files with API keys

## Before Committing
```bash
# Check for secrets accidentally staged
git diff --staged | grep -E "(sk_live|sk_test|eyJ|password|secret)" || echo "clean"

# Review what's actually staged
git diff --staged --stat
```

## PR Description Template
```markdown
## What
[1-2 sentence summary of the change]

## Why
[Context — what problem does this solve?]

## Test plan
- [ ] Manual test: [what you verified]
- [ ] Edge cases: [what could break]
```
