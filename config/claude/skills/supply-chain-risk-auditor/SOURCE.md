# Source
- Repo: https://github.com/trailofbits/skills — `plugins/supply-chain-risk-auditor/skills/supply-chain-risk-auditor/`
- Commit: `82fe8226252622fa807643bdca1710901198553a`, vendored 2026-09-29
- License: CC-BY-SA-4.0 (repo `LICENSE`, copied)
- Reviewed: SKILL.md read in full; scripts reviewed: stdlib-only (`urllib`), no third-party deps. Network calls go only to public registries/APIs — api.osv.dev, registry.npmjs.org, api.npmjs.org, pypi.org, proxy.golang.org, api.deps.dev, api.github.com, api.scorecard.dev. It reads `gh auth token` and sends it **only** to api.github.com (rate limit 60→5000/h); the on-disk cache stores response bodies only. Optional `pip-audit` is run with `--no-deps --disable-pip` so no package code is ever downloaded or executed. No exec/eval of fetched content.
- Local changes: Tests, evals and fixtures not vendored (`scripts/test_*.py`, `evals/`). Limitation: reads `package-lock.json`/`uv.lock`/`go.mod`, **not `pnpm-lock.yaml`** — for pnpm projects versions fall back to `package.json` pins; pair with `pnpm audit`.
