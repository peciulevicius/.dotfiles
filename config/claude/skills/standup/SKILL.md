---
name: standup
description: Generate a standup summary from recent git activity across all repos.
disable-model-invocation: true
---

Generate a standup summary from recent git activity.

## Steps

1. Find all git repos in common project locations:
```bash
find ~/code ~/projects ~/work . -maxdepth 3 -name ".git" -type d 2>/dev/null | head -20
```

2. For each repo, get commits since yesterday:
```bash
git -C <repo> log --oneline --since="1 day ago" --author="$(git config user.name)" 2>/dev/null
```

3. Also check the current repo:
```bash
git log --oneline --since="1 day ago"
```

4. Format as a standup:

```
**Yesterday**
- [repo] feat: what was shipped

**Today**
- [what's planned based on open PRs or last context]

**Blockers**
- [anything that needs a decision or is stuck]
```

Keep it to bullet points. One line per commit group (don't list every commit — group by feature).
