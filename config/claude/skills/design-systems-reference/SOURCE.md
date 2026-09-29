# Source
- Repo: https://github.com/VoltAgent/awesome-design-md (★ ~119k, MIT) — `design-md/<brand>/DESIGN.md`
- Commit: `f6961238d5cddcf8042a74a70fc400ec67181abb` (2026-09-21), vendored 2026-09-29
- License: MIT (`LICENSE`, unchanged). The files are third-party *analyses* of public websites; brand names/marks belong to their owners — use as reference, never to imitate a brand.
- Vendored subset (12 of 74): linear.app, stripe, supabase, vercel, raycast, resend, cal, expo, sentry, posthog, notion, revolut — picked for SaaS / dev-tool / fintech / mobile work.
- Reviewed: data files (YAML tokens + prose). All 74 upstream files scanned for exec/fetch/injection phrasing ("ignore previous", "run the following", system-prompt text, etc.) — none; the only `curl | sh` strings describe install commands shown on those brands' own sites (ollama, opencode — not vendored). `SKILL.md` is local and tells the agent to treat the files as data.
- Local changes: files renamed to `systems/<brand>.md`; `SKILL.md` written locally.
