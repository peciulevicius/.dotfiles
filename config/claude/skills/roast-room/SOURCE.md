# Source
- Repo: https://github.com/nateherkai/roast-room (MIT): `.claude/skills/roast-room/`
  plus the seven seat agents from `.claude/agents/council-*.md`, copied into
  `agents/` here so the skill is self-contained.
- Commit: `f5e7b63`, vendored 2026-10-14.
- License: MIT (`LICENSE`, unchanged).
- What: a "board meeting" on one business decision. Seven simulated advisors
  (Bezos, Paul Graham, Hormozi, Gary Vaynerchuk, Dan Martell, Gino Wickman,
  Buffett), each grounded in a `brains/<name>/` folder compiled from their
  public work, argue over three rounds; the Chair writes a scored verdict.
- Reviewed: `SKILL.md`, `references/`, `brains/` (markdown only),
  `scripts/check_quotes.py` (reads the brains, no network). No install hooks,
  no telemetry. The optional live-room web app (`app/`) is not vendored: it
  stays in `~/dev/roast-room`.
- Local changes: none to upstream files. `agents/` is an added copy.
- Cost: a full council is ~21 agent runs (~1M tokens). Use `--quick`.
- Where it is used: Claude Code (global skill; the `council-*` sub-agent types
  are not registered outside `~/dev/roast-room`, so it falls back to
  `general-purpose` per `references/round-prompts.md`), and the Studio CEO in
  Paperclip (sequential, see `services/paperclip/studio-roast-room-addendum.md`).
