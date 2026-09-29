# Source
- Repo: https://github.com/anthropics/skills — `skills/webapp-testing/`
- Commit: `8a1541c4a3ffa5a20a5a91de0dcf3f0bab1d1ef4`, vendored 2026-09-29
- License: Apache-2.0 (`LICENSE.txt`, unchanged)
- Reviewed: Every file read: SKILL.md, `scripts/with_server.py` (starts the given local dev-server commands, polls localhost ports, runs your command, then kills the servers — no network beyond localhost), `examples/*.py` (Playwright against localhost/file://). Nothing fetched or sent anywhere.
- Local changes: None. Needs Python Playwright (`pip install playwright && playwright install chromium`) in the project where it runs; `playwright-cli` is the lighter default for ad-hoc browsing.
