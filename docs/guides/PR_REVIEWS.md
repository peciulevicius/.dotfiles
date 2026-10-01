# Codex pull request reviews

CI checks syntax, docs and secret leaks. Codex's hosted GitHub reviewer is a
separate integration from the GitHub connector used by local Codex sessions.
Claude reviews are intentionally deferred so routine PRs do not consume the
Claude subscription allowance.

## Current setup (checked 2026-10-01)

The repository has shared review rules in `AGENTS.md` and
`.github/AI_REVIEW_RULES.md`. Automatic hosted reviews are **not enabled yet**;
the owner must connect this repository and enable them in Codex settings.

## Codex

1. Connect GitHub to Codex and grant access to `peciulevicius/.dotfiles`.
2. In [Codex review settings](https://app.chatgpt.com/settings/code-review),
   choose this repository under **Review code** and enable **Automatic
   review**. Choose whether reviews run on new PRs, pushes, or both.
3. On an existing PR, comment `@codex review`. A bot reply asking you to
   connect GitHub means setup is still incomplete.

The repo's `AGENTS.md` **Code Review Rules** section directs Codex to
`.github/AI_REVIEW_RULES.md`. Codex's GitHub review focuses on serious
findings (typically P0/P1), so it complements CI rather than replacing it.

OpenAI counts reviews performed through GitHub against the account's **Code
Review usage**. This is plan-based Codex usage, not an OpenAI API-key workflow;
check the account's usage page for its current allowance. A ChatGPT API key
does not enable hosted GitHub reviews. See the official
[Codex GitHub review guide](https://learn.chatgpt.com/docs/third-party/github)
and [Codex pricing and usage](https://learn.chatgpt.com/docs/pricing).

Claude's subscription-backed workflow was removed from this proposal. Revisit
it only if the owner explicitly chooses to spend Claude plan usage on CI
reviews.
