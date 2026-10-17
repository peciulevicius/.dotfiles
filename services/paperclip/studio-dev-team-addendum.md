## How the Studio builds (added by the board, 2026-10-15)

Every Studio product — mobile app, web app, landing page, waitlist — is a
**private GitHub repo** under `/Users/dziugaspeciulevicius/dev/studio/<name>`
(the owner's Mac, mounted here at the same path). You work in that real repo.

**Starting a new product:** `git init -b main` in
`/Users/dziugaspeciulevicius/dev/studio/<name>` (lowercase letters, digits,
dashes), add a README, `AGENTS.md` (copy the workflow section from
`carbstride/AGENTS.md`) and CI, commit on `main`. Within 2 minutes the host bot
creates the private GitHub repo and pushes it. After that first commit, never
commit to `main` again.

**Every change:**
1. One task = one branch + worktree:
   `git worktree add ../.worktrees/<repo>/<issue>-<slug> -b agent/<issue>-<slug> origin/main`.
   Only `agent/*` branches leave the machine.
2. Commit with conventional messages and an `Agent: <your role>` trailer. Your
   git identity is the owner's on purpose; don't change it. Don't push: the host
   bot pushes, opens the PR, runs the preview and posts the owner an iPhone link
   (Expo apps), a web link and screenshots, in the PR and in `#ai-studio`.
3. Before handing over: the repo's checks pass (typecheck, lint, tests). Try
   the branch yourself on the preview runner:
   `POST http://studio-preview:7301/preview {"repo":"<repo>","branch":"agent/…"}`
   (the agents' slot; add `"app":"web"` for `apps/web` in a monorepo), poll
   `GET /status?slot=agent` until `running`,
   `POST /test` and read the screenshots. The agents share that one slot; if
   it's busy (`409`), wait. The owner's slot belongs to the PR bot — never use
   `"slot":"owner"`.

**Review gate (replaces the Codex bot after 2026-10-29):** no PR goes to the
owner until
- **QA Engineer** has run the preview and checked the flows and screenshots at
  phone size;
- **Security Engineer** has reviewed the diff (secrets, auth, data storage,
  keys in the client bundle, dependency risk — `differential-review` skill);
- **CTO** has reviewed the code quality and architecture.
Each reviewer comments on the Paperclip issue with the PR link and either
"approved" or the changes needed; the author fixes on the same branch.

**Quality bar:** the owner's design standard, `/ai-memory/studio/DESIGN_STANDARD.md`.
Every product must look and feel like Chris Raroque's apps (ellieplanner.com,
lunabudgeting.com, mogulnetworking.com, amyfoodjournal.com): one promise, real
product UI, whitespace, one brand colour, native iOS feel, subtle premium
animations (Reanimated springs, haptics, number transitions). Designed in Claude
Design first and approved by the owner. No placeholder logic shipped as finished.

**Tools:** before looking for or installing any tool, read `/ai-memory/TOOLBOX.md` (what to use when, and what's been rejected). Before any idea reaches the owner or a Roast Room, run the competitor sweep it describes.

**Never:** commit secrets or `.env`, push or commit to `main` after the first
commit, rewrite another agent's branch, create store/payment/developer accounts
(owner steps), or spend money.
