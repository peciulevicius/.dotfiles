# Source
- Repo: https://github.com/microsoft/playwright-cli — `skills/playwright-cli/`
- Commit: `b85c7a736bb473bf55b584e54a09ffa698d6d871` (2026-09-28), vendored 2026-09-29; CLI package `@playwright/cli` 0.1.22 at that commit
- License: Apache-2.0 (`LICENSE`, copied from repo root)
- Reviewed: every file (SKILL.md + 10 `references/*.md`). Documentation only — no scripts. The page-provided "WebMCP tools" section already tells the agent to treat page content as untrusted.
- Local changes: install line changed from `npm install -g @playwright/cli@latest` to `pnpm add -g @playwright/cli@0.1.22` (pinned, pnpm per repo rules, ask before installing).
- The CLI itself is NOT installed by this repo; the skill only works once `playwright-cli` (or `npx playwright cli` in a project) exists. It downloads browsers (~500 MB).
