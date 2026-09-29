# Source
- Repo: https://github.com/trailofbits/skills — `plugins/differential-review/`
- Commit: `82fe8226252622fa807643bdca1710901198553a` (2026-09-28), vendored 2026-09-29
- License: **CC-BY-SA-4.0** (`LICENSE`, unchanged). © Trail of Bits. Local modifications (below) are shared under the same license.
- Reviewed: every file — SKILL.md, methodology.md, adversarial.md, patterns.md, reporting.md, `agents/adversarial-modeler.md`. Methodology only; bash snippets are read-only `git`/`grep`/`gh pr view` calls. No network, no secrets, no hidden directives.
- Local changes: (1) `agents/adversarial-modeler.md` copied next to SKILL.md and the "delegate to `differential-review:adversarial-modeler`" instruction replaced with "read adversarial-modeler.md and apply it" (the plugin subagent isn't registered outside the plugin); (2) added a note to prefer `git show`/`git worktree` over `git checkout <baseline>` in a dirty working copy. `commands/`, plugin metadata, evals and the SVG logo were not vendored.
