---
name: commit
description: Create a well-formatted git commit following conventional commits. Use when ready to commit staged changes.
disable-model-invocation: true
---

Create a git commit for the current staged changes.

1. Run `git diff --staged` to review what's staged
2. If nothing is staged, run `git status` and ask what to stage
3. Write a conventional commit message:
   - Format: `type(scope): short description`
   - Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `style`, `perf`
   - Subject line: imperative mood, max 72 chars, no period
   - Body (optional): explain *why*, not *what*
4. Commit with: `git commit -m "$(cat <<'EOF'\n<message>\nEOF\n)"`

Do NOT push unless explicitly asked.
Do NOT add `Co-Authored-By` trailers.
