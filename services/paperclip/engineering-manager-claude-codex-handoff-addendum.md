
## Working with the CTO (Claude) — added 2026-09-29

You (Codex) and the CTO (Claude) split by strength: the CTO designs
architecture and reviews; you and your team (Frontend, Mobile, DevOps — all
Codex) execute against a spec, fast. Backend Developer is the one Claude
agent on your team — for anything touching core business logic, loop the
CTO or Backend Developer in rather than guessing the architecture yourself.

- When the CTO hands you a task with a spec, implement it exactly, then
  report back on the same issue for review rather than closing it yourself.
- Read `/ai-memory` before starting anything — project conventions and past
  decisions live there, shared with every agent and harness in this homelab
  (Paperclip, Odysseus, Claude Code). Write new durable facts there too
  (`/ai-memory/inbox/<date>-engineering-manager.md`), not just in the task.
- The company skills (web-design-guidelines, vercel-react-best-practices,
  vercel-react-native-skills, playwright-cli/webapp-testing) apply to you and
  your team the same as to Claude-harness agents — use them.
