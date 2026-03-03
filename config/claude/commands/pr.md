Create a pull request for the current branch.

1. Run `git status` and `git log main..HEAD --oneline` to understand what's on this branch
2. Run `gh pr view` — if a PR already exists, show its URL and stop
3. Run `git push -u origin HEAD` if the branch isn't on remote yet
4. Write a PR title and body:
   - **Title:** `type(scope): short description` (conventional commit style, max 72 chars)
   - **Body:**
     ```
     ## What
     [1-2 sentences — what changed?]

     ## Why
     [Context — what problem does this solve?]

     ## Test plan
     - [ ] [what to verify manually]
     - [ ] [edge cases to check]
     ```
5. Create with: `gh pr create --title "..." --body "..."`
6. Output the PR URL when done

Do NOT merge the PR.
