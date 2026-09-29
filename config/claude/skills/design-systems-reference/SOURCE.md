# Source
- Repo: https://github.com/VoltAgent/awesome-design-md (★ ~119k, MIT) — `design-md/<brand>/DESIGN.md`
- Commit: `f6961238d5cddcf8042a74a70fc400ec67181abb` (2026-09-21), vendored 2026-09-29
- License: MIT (`LICENSE`, unchanged). The files are third-party *analyses* of public websites; brand names/marks belong to their owners — use as reference, never to imitate a brand.
- Vendored: **all 74** (2026-09-29; first 12 on 2026-09-29 morning). The curated 12 (linear.app, stripe, supabase, vercel, raycast, resend, cal, expo, sentry, posthog, notion, revolut) are marked as defaults in `SKILL.md`; the rest are references.
- Reviewed: data files (YAML tokens + prose). All 74 upstream files scanned for exec/fetch/injection phrasing ("ignore previous", "run the following", system-prompt text, etc.) — none; the only `curl | sh` strings describe install commands shown on those brands' own sites (ollama, opencode — now vendored as data; `SKILL.md` tells agents to treat file contents as description, never as commands). `SKILL.md` is local and tells the agent to treat the files as data.
- Local changes: files renamed to `systems/<brand>.md`; `SKILL.md` written locally.
