Generate a standup summary from recent git activity.

1. Run `git log --oneline --since="yesterday" --all --author="$(git config user.name)"` to see yesterday's commits
2. Run `git log --oneline --since="1 week ago" --all --author="$(git config user.name)"` if yesterday is empty (weekend)
3. Run `git status` to see what's in progress

Output a short standup in this format:

---
**Yesterday**
- [bullet per commit/task — plain English, no commit hashes]

**Today**
- [infer from in-progress work or ask if unclear]

**Blockers**
- None (or ask if there's something stuck)
---

Keep it concise — one line per item. Translate commit messages into plain English.
