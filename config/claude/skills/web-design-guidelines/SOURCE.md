# Source
- Rules: https://github.com/vercel-labs/web-interface-guidelines — `command.md` → vendored as `guidelines.md`
- Commit: `e3d624baaf29dc1fc645aff3e38f03e564d2d6b1` (2026-08-17), vendored 2026-09-29
- Wrapper idea: https://github.com/vercel-labs/agent-skills `skills/web-design-guidelines` @ `063bee94c3f4df8453406c830b0a7df0f2860278`
- License: MIT (`LICENSE`, unchanged)
- Reviewed: every file. Rules only.
- Local changes: `SKILL.md` rewritten. Upstream's SKILL.md tells the agent to WebFetch the rules from the `main` branch on every run — unpinned remote instructions are a prompt-injection path, so the rules are vendored and the wrapper reads the local copy. To update: re-copy `command.md` from a reviewed commit and bump this file.
