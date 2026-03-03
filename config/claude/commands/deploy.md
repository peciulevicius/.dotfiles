Deploy the current project to production (or staging if $ARGUMENTS is "staging").

**Important:** This command has `disable-model-invocation: true` — you must type `/deploy` explicitly. Claude will never auto-trigger a deployment.

## Step 1 — Pre-flight checks

```bash
git status        # must be clean (no uncommitted changes)
git log origin/main..HEAD --oneline   # show unpushed commits
```

Warn if:
- There are uncommitted changes (ask to stash or commit first)
- Not on `main`/`master` for a production deploy

## Step 2 — Run /check first

Run the full pre-deploy check (lint + types + tests). If anything fails, stop and report what failed. Do not deploy with a broken build.

## Step 3 — Detect deployment target

Read `.claude/CLAUDE.md` for the stack. Look for:
- `Vercel` → deploy with Vercel CLI
- `Cloudflare Pages` → deploy with Wrangler
- `Expo` / `EAS` → build and submit with EAS
- If unclear, ask before proceeding

## Step 4 — Confirm

For production deploys, always confirm:
```
Deploying to PRODUCTION.

Project: [name from CLAUDE.md]
Target:  [Vercel / Cloudflare / EAS]
Branch:  [current branch]

Type "yes" to continue, anything else to cancel.
```

For staging, proceed without confirmation.

## Step 5 — Deploy

**Vercel:**
```bash
vercel deploy --prod   # production
vercel deploy          # staging/preview
```

**Cloudflare Pages:**
```bash
pnpm build
wrangler pages deploy ./out --project-name [project-name]
```

**Expo (EAS):**
```bash
eas build --platform all --profile production
eas submit --platform all
```

## Step 6 — Report

Output the deployment URL. If there were any warnings during deploy, surface them.

If the deploy fails, show the error and suggest next steps — don't retry automatically.
