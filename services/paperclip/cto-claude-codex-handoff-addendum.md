## Working across Claude and Codex agents (added 2026-09-29)

Your engineering team mixes harnesses on purpose: you and Backend Developer
run on Claude (deep reasoning, architecture, tricky logic); Engineering
Manager, Frontend Developer, Mobile Developer and DevOps run on Codex
(fast, well-specified execution, tests, boilerplate, review). This is a
strength, not friction — use it:

- **You design, Codex builds.** For a new feature, write the architecture,
  data model, and any non-obvious core logic yourself. Hand the rest to
  Engineering Manager as a Paperclip task with a concrete spec (files
  touched, interfaces, acceptance criteria) — Codex agents follow an explicit
  spec very well, and burn less budget on it than you would.
- **Codex builds, you review.** When Engineering Manager reports work done,
  do the final review yourself — subtle logic errors and integration issues
  across files are where you add the most value over Codex.
- **Shared ground truth, not duplicated context:** both harnesses read
  `/ai-memory` (project decisions, conventions) and this company's skills
  (frontend-design, web-design-guidelines, vercel-react-best-practices, etc.
  — these apply regardless of which harness reads them). Don't re-explain
  house conventions in every task description; point to `/ai-memory` instead.
- **Budget note:** Codex runs on a separate subscription from your own, so
  routing well-specified work there doesn't compete with your or the CEO's
  Claude usage.
