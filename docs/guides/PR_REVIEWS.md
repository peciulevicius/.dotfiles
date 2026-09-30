# Automatic AI pull request reviews

CI checks syntax, docs and secret leaks. AI reviews are separate and need
their own provider connection. This repository has a Claude review workflow;
Codex's hosted GitHub reviewer is configured in the user's Codex settings.

## Current setup (checked 2026-09-30)

| Reviewer | Prepared | Required to activate |
|---|---|---|
| Codex | Review requests posted on PRs 41–43; repo rules are in `AGENTS.md` | Connect this repository in Codex and enable automatic reviews |
| Claude | `.github/workflows/claude-pr-review.yml`, shared review rules | Subscription OAuth secret and repository variable, then merge the workflow PR |

The Codex bot replied that its GitHub connection needs setup. The GitHub
connector used by a local Codex session does not automatically activate
hosted code reviews. As checked on 2026-09-30, this repository has neither the
`CLAUDE_CODE_OAUTH_TOKEN` secret nor the `CLAUDE_PR_REVIEW_ENABLED` variable;
the Claude workflow therefore skips its review job. Neither reviewer is
running automatically yet.

## Codex

1. Open [Codex GitHub connection settings](https://chatgpt.com/codex/cloud/settings/connectors)
   and grant access to `peciulevicius/.dotfiles`.
2. In Codex settings, choose this repository under **Review code** and enable
   **Automatic review**. Configure review triggers for new PRs and pushes.
3. On an existing PR, comment `@codex review`. A bot reply asking you to
   connect GitHub is a setup failure, not a completed review.

The repo's `AGENTS.md` **Code Review Rules** section directs Codex to
`.github/AI_REVIEW_RULES.md`. See the official
[Codex GitHub review guide](https://developers.openai.com/codex/integrations/github/).
Hosted review usage is subject to the account's allowance.

## Claude with the existing subscription

Generate a long-lived Claude Code token locally with `claude setup-token`.
Store it as the repository secret **`CLAUDE_CODE_OAUTH_TOKEN`**; do not paste
it into chat, a PR, a tracked file, or a command's `--body` argument. The
GitHub CLI can prompt for the secret without putting it in shell history:

```bash
gh secret set CLAUDE_CODE_OAUTH_TOKEN --repo peciulevicius/.dotfiles
gh variable set CLAUDE_PR_REVIEW_ENABLED --body true --repo peciulevicius/.dotfiles
```

Merge the workflow PR, then open or push to a non-draft PR. The action uses
the built-in GitHub token to post **Claude PR review** comments as
`github-actions[bot]`; installing the Claude GitHub App is not required for
this configuration. It cannot push code because repository contents are
read-only. This setup does not configure an Anthropic API key or paid API
fallback. Subscription usage still counts and an exhausted allowance can
fail a review until reset; rerun the failed review job after it resets.

The workflow reviews `opened`, `synchronize`, `reopened`, and `ready_for_review`
events. It skips drafts, forks, and disabled repositories. It uses Sonnet,
at most 20 turns and 15 minutes, cancels stale runs on a new push, reads
approved rules from the base branch, and disables code edits, shell commands
and subprocess agents. Action versions are pinned. Full model output is not
published in logs. Review findings are advisory and never auto-merge a PR.

Disable reviews without deleting the secret:

```bash
gh variable set CLAUDE_PR_REVIEW_ENABLED --body false --repo peciulevicius/.dotfiles
```

See the official [Claude Code GitHub Actions guide](https://code.claude.com/docs/en/github-actions)
and [action configuration](https://github.com/anthropics/claude-code-action/blob/main/docs/configuration.md).
To save quota, keep one reviewer automatic and invoke the other for changes
that merit a second opinion. Both can be enabled if their allowances permit.
