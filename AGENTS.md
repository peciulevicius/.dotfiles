# Agent guidance

This file is the repository entry point for Codex and other tools that support
`AGENTS.md`. Read [docs/AI_COLLABORATION.md](docs/AI_COLLABORATION.md) for the
tool map, documentation workflow, and shared-memory boundaries. Then read the
relevant service README and TODO section before changing operational code.

## Working in this repository

- Keep changes on a focused branch and submit them as a pull request; do not
  push directly to `main`.
- Treat `docs/HOME_SERVER_TODO.md` as outstanding work and
  `docs/HOME_SERVER_CHANGELOG.md` as completed work. Update the appropriate
  document when a task changes that status.
- Follow the service's README and nearby scripts as the source of truth. Avoid
  duplicating setup instructions when a maintained runbook already exists.
- Never commit credentials, tokens, private exports, or generated personal
  data. Keep machine-specific state in ignored files or the external shared
  memory described in `docs/AI_COLLABORATION.md`.
- When working on the Mac mini, read `~/ai-memory/README.md` and the relevant
  project note before cross-project or operational work. Follow its privacy,
  inbox, and ownership rules; do not copy private memory into this repository.
- Make operational changes only when the task calls for them. Prefer a
  read-only preview first and document any live follow-up clearly.
- Before editing, inspect `git status` and preserve unrelated user changes.
- Run the checks relevant to the changed files and report what was run.

## Approval preferences

Routine edits, focused branches, commits, pushes to those branches, and opening
PRs are authorized within the user's requested work. Proceed without asking
for each step. Ask before major operational changes, irreversible termination,
deleting data, rewriting shared history, or merging/deploying a PR when that
action has not already been authorized. Prepare the concrete change and its
recovery plan before asking. Sandbox and account permission requirements still
apply; these instructions do not change a client's permission mode.

## Code Review Rules

Read `.github/AI_REVIEW_RULES.md` when available. Focus on concrete introduced
bugs, with the failing scenario and file/line. Check secret handling, partial
recovery and saved state, stale agent references, accidental wakes/retries,
notification routing, and whether separately staged live files were updated.
Skip style preferences and mechanical checks already enforced by CI. Never
copy private memory into a review or merge a PR on the user's behalf.

## Where to look

- Repository overview: [README.md](README.md)
- Service index: [services/README.md](services/README.md)
- Utility scripts: [scripts/README.md](scripts/README.md) and
  [docs/UTILITY_SCRIPTS.md](docs/UTILITY_SCRIPTS.md)
- Current home-server work: [docs/HOME_SERVER_TODO.md](docs/HOME_SERVER_TODO.md)
- Verified system facts: [docs/HOME_SERVER_REFERENCE.md](docs/HOME_SERVER_REFERENCE.md)
- Completed changes: [docs/HOME_SERVER_CHANGELOG.md](docs/HOME_SERVER_CHANGELOG.md)
