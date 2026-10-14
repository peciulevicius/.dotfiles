# Source
- Repo: https://github.com/nateherkai/scroll-craft (MIT) — `plugins/nateherk-design/skills/scroll-craft/`
- Commit: `75d81f74e83692add18cd7a8a8e078b8a887a579`, vendored 2026-10-14
- License: MIT (`LICENSE`, unchanged).
- What: workflow + references + a small JS/CSS engine for premium, scroll-driven
  websites (eight page "grammars", a unique signature interaction per site,
  verification of scroll performance/contrast/encoding).
- Reviewed: `SKILL.md`, `references/`, `engine/`, `scripts/`. Only outbound
  network use is `scripts/kie.mjs` → **api.kie.ai** (paid AI image/video
  generation; uploads reference images there). It only runs with
  `KIE_AI_API_KEY`, which is **not set** — leave it unset unless deliberately
  buying assets. `doctor.mjs` runs local `ffmpeg`/Chrome to check the setup.
  No install hooks, no telemetry.
- Host deps: Node 18+, full ffmpeg (`brew install ffmpeg`), Playwright + Chrome
  for the verification step.
- Local changes: none.
