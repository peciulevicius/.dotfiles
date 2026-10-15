# Studio preview runner (+ the Studio dev pipeline)

Lets the Paperclip **Studio** dev team build real products in real repos
while the owner tests every change on his phone with one tap. **Every Studio
product** (mobile app, web app, landing page, waitlist) is a private GitHub repo
under `~/dev/studio/<name>`. Pilot: **Carbstride**
(`~/dev/studio/carbstride`, `peciulevicius/carbstride`).

## How the pipeline fits together

```
Paperclip agents (CTO, Mobile, Backend, QA, Security)
  └─ work in ~/dev/studio/<repo>, one git worktree + `agent/*` branch per task
       (mounted into Paperclip at the same absolute path as on the Mac)
  └─ try their branch on studio-preview  ──►  screenshots on the issue
scripts/utils/studio-pr-bot.py  (host cron, every 2 min)
  └─ pushes agent/* branches, opens a PR per branch
  └─ previews the newest change, runs the screenshot test
  └─ comments iPhone link + web link + screenshots on the PR and in #ai-studio
Owner
  └─ taps the iPhone link (Expo Go, Tailscale on) or opens the web link
  └─ merges the PR on GitHub when happy
```

## The runner

`studio-preview` (this folder) is one container with Node, pnpm and headless
Chromium. It holds **two preview slots**, each running one branch as a dev
server. **owner** (port 8081, published on Tailscale) is used only by the PR
bot, so the links on a PR keep showing that PR. **agent** (port 8082, internal)
is where agents try their own work. Each runs: an Expo app (served to the phone via Expo Go and as a
web build) or a website (Next via `next dev`, Astro/Vite/SvelteKit via their
`dev` script). Any git repo directly under `~/dev/studio` can be previewed. A new request replaces the running one. It joins the `paperclip`
network so agents reach it at `http://studio-preview:7301`.

| Endpoint | What |
|---|---|
| `POST /preview {"repo":"carbstride","branch":"agent/…","slot":"agent"}` (slot defaults to agent; the bot uses owner) | check the branch out into `~/dev/studio/.previews/<repo>` and start it (async; `409` while another is starting) |
| `GET /status[?slot=owner\|agent]` | per slot: state (`preparing → installing → starting → running`, or `failed`/`crashed`), links, log tail, last test |
| `POST /test {"slot":…}` | Playwright at iPhone size (390×844): home + up to 8 in-app links, one PNG each + `index.html`; fails on uncaught page errors |
| `GET /p?repo=…&branch=…` | **per-PR link** (what the bot posts): opens that branch — Expo Go for apps, the browser for websites — starting it in the owner slot first if another PR holds it, behind a self-refreshing "starting…" page (~1 min) |
| `GET /open` | Expo apps: 302 to `exp://100.81.171.49:8081`, so a tap on the phone opens Expo Go |
| `GET /qr.png` | Expo apps: QR of the same link |
| `GET /artifacts/…` | screenshots (under `~/dev/studio/.previews/artifacts/`) |

Ports are bound to the **Tailscale IP only** (7301 API/links, 8081 Expo) plus
`127.0.0.1:7301` for the host bot; nothing is on the LAN or the tunnel.

**Phone:** install Expo Go, keep Tailscale on, tap the link from the PR or
Discord. Native modules Expo Go doesn't ship (RevenueCat, HealthKit, OAuth
redirect schemes…) need a one-time development build instead (owner step,
see below); until then those screens can only be checked on the web build.

## Setup from scratch

1. `mkdir -p ~/dev/studio/.worktrees ~/dev/studio/.previews`, clone each
   Studio repo to `~/dev/studio/<name>`. A new repo needs nothing else.
2. `services/setup-services.sh` (or copy this folder to
   `~/services/studio-preview/`, `.env` from `.env.example`), then
   `docker compose up -d --build`.
3. Paperclip mounts `~/dev/studio` at the same path and sets the agents' git
   identity — the **owner's** name and GitHub no-reply email, so commits count
   on his profile; agents add an `Agent: <role>` trailer — plus
   `safe.directory` (`services/paperclip/docker-compose.yml`). Each Studio
   project's workspace `cwd` points at its repo.
4. Cron (in `scripts/cron/crontab`):
   `*/2 * * * * python3 ~/.dotfiles/scripts/utils/studio-pr-bot.py >> ~/logs/studio-pr-bot.log 2>&1`.
   It uses the owner's own `git`/`gh` credentials, pushes only `agent/*`
   branches, never `main`, and posts to `#ai-studio` through
   `~/.config/homelab/studio-discord.env`.

## Why it's built this way

- **Separate container, not inside Paperclip:** Paperclip has a 3 GB limit and
  idles at ~1 GB; a Metro bundler plus Chromium inside it would get agents
  killed (exit 137). The runner is capped at 2.5 GB with one slot.
- **Same absolute path everywhere:** git worktrees store absolute paths; a
  worktree created at `/work/...` in a container is broken on the Mac.
- **Host bot pushes, not agents:** no GitHub token or deploy key inside the
  agents' container; everything reaching GitHub goes through one small script.
- **Two slots, not one:** with one shared slot an agent's own test replaced a
  PR's preview while the bot was screenshotting it (2026-10-15). Two dev
  servers plus one Chromium fit the 2.5 GB cap; more would not. Older PRs keep
  their last screenshots; the owner slot shows the newest PR.

## Failure modes

- `409 busy` — another preview is still building; poll `/status`.
- `failed` with a pnpm error — lockfile out of date on that branch; the agent
  fixes it in its branch.
- Phone says "could not connect" — Tailscale off on the phone, or the preview
  was replaced by a newer one (check `/status`).
- Expo Go says the SDK is unsupported — Expo Go only runs the latest SDK; keep
  the app on it (`npx expo install --fix`).

## Next (owner steps, when wanted)

- Free Expo account + `EXPO_TOKEN` → EAS Update per PR: permanent links that
  work without the runner and for every PR at once.
- Apple Developer account ($99/yr) → development build + TestFlight, needed
  for RevenueCat, HealthKit and real OAuth.
