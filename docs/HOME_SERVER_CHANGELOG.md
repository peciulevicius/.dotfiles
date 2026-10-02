# Home Server — Completed Work

Archive of finished items, moved out of `HOME_SERVER_TODO.md` on 2026-09-08 so
that file holds only outstanding work. Kept because the *why* behind a past fix
is often what you need when something similar breaks again.

Newest first-ish; dates are when the work was finished.

## 2026-10-02 — Immich DB password rotated, Google app passwords revoked

Immich's `DB_PASSWORD` was the old reused personal password (found
2026-09-22). Replaced with a random one via `ALTER USER` over stdin, then
`.env`; all four Immich containers came back healthy. All remaining Google
app passwords were deleted; nothing in the stack sends mail through Gmail.

## 2026-10-02 — Vaultwarden admin token rotated

The token disclosed via `docker inspect` on 2026-09-21 was replaced. New
`scripts/utils/vaultwarden-rotate-admin-token.sh` runs vaultwarden's hidden
`hash` prompt inside the live container under a pty, so the token never sits
in a command line or container config; only the Argon2id hash reaches `.env`.

## 2026-10-02 — Discord bot token + Paperclip admin password rotated

Both were exposed in a session transcript on 2026-10-01. Discord: Reset Token,
new value written straight into the bridge `.env`. `configure.sh` was not used
because it rewrote `CHANNEL_MAP` to Coach + Dietitian only, which would have
dropped the Studio/Homelab/Finance/Travel channels; it now seeds the map only
when it is empty. Paperclip: the UI has no password field, so it was changed via
Better Auth's API (`scripts/utils/paperclip-change-password.py`). The bridge's
restart then hit a sign-in 429 and sat connected to Discord but not relaying;
its login now retries with back-off.

## 2026-10-01 — xpub scan loop fixed

Symptom: Glance's finance card stopped updating; a rebuild hit a 15-minute
timeout. Cause: when a rebuild failed, `finance.json` stayed older than
`balances.json`, so the 2-minute watcher started a new full BTC scan every 2
minutes. They overlapped and kept triggering mempool.space 429s. Fixes: the
watcher takes a lock (`mkdir`, stale after 20 min); the scan falls back to
blockstream.info on 429 and remembers used address indices (full rescan weekly).
The scan also has a 150 s budget per run and saves its high-water mark, so a
throttled run resumes (provider shows stale) rather than timing out the rebuild.
Follow-up: the remaining stalls were not 429s but mempool.space hanging ~60 s on
some requests (blockstream.info answers in <1 s). The scan now tries
blockstream first, with a 15 s per-request timeout and mempool.space as the
fallback; a full 20+13-address scan completes in about a minute.
Lesson: a "run if output is older than input" trigger needs a lock and a
failure back-off, or one slow dependency turns it into a self-inflicted DoS.

## 2026-10-01 — Finance tab: editable balances, Accounts first

- New `services/balances-ui/` (port 8095, localhost + Tailscale only): a one-page
  form that edits `~/ai-memory/finance/balances.json`; Glance's Accounts card
  links to it. Why: Glance widgets are read-only, so editing from the dashboard
  needed a tiny writer. No login; access control is the Tailscale-only binding
  (don't tunnel it). Only changed fields are written, so a concurrent agent
  edit isn't clobbered.
- Accounts card now sits above Portfolio; the duplicate "Emergency fund" header
  is gone (it is still a row); the months-of-spending line shows only once
  `monthly_spend` is set. Portfolio holdings now show quantity (e.g. BTC amount).
- First payslip PDF dropped in `#ai-finance` was saved and ingested by Paperless
  (Paperless sleeps; the folder write still works).

## 2026-10-01 — payslip PDFs from Discord into Paperless

Attaching a PDF/image in `#ai-finance` now saves it to Paperless's consume
folder (bridge `CONSUME_CHANNELS`, `/consume` mount). Why: the Finance Manager
only sees text, and a payslip is a document to keep, not data to hand an agent.
The typed `payslip <amount>` still goes to the agent. Written as `.part` then
renamed to avoid half-read files. Gotcha: Paperless sleeps (Sablier), but the
folder write is independent of it. Mac-side `docker compose` mount uses
`${HOME}` so it follows the staged layout.

## 2026-10-01 — one skills directory

`homelab-service` moved from `.agents/skills/` (with symlinks from
`config/claude/skills/` and `.claude/skills/`) into `config/claude/skills/`,
and `.agents/` and `.claude/skills/` were deleted. Why: skills were split
across three paths and it was unclear which was authoritative; the Codex
discovery path was the only reason for it. `~/.claude/skills/homelab-service`
still resolves through the existing global link.

## 2026-10-01 — Glance finance refresh on change, BTC xpub, #ai-travel mapped

- **Why the Accounts card stayed empty:** the Finance Manager edits
  `~/ai-memory/finance/balances.json`, but Glance reads `finance.json`, which
  only `finance-status.sh` rebuilds (07:00). New
  `scripts/utils/finance-refresh-on-change.sh` (cron, every 2 min) rebuilds it
  when `balances.json` is newer and posts a note to `#ai-agents`. A no-op the
  rest of the time. Install by appending the line from `scripts/cron/crontab`
  (a full `crontab <` reinstall would drop one-shot lines).
- **No Discord reply earlier:** the balances were set from an issue created in
  the Paperclip UI. The bridge only relays replies for messages sent in a
  mapped channel; issue comments made elsewhere stay in Paperclip. Use
  `#ai-finance` to get the answer in Discord.
- **Ledger BTC:** `LEDGER_BTC_XPUBS` accepts an xpub/ypub/zpub, derived locally
  (stdlib; BIP84 vectors pass) with a 20-address gap limit, because Ledger
  rotates receive and change addresses. Reverses the earlier "no xpub" call:
  derivation is local and only single addresses leave the host; the trade-off
  is in `services/glance/README.md`. mempool.space returns 429 on bursts, so
  lookups are paced and retried.
- `#ai-travel` created by the owner and mapped to Travel Planner.
- **Follow-up:** Ledger Live exports an `xpub6…` for native-segwit accounts (path `84'/0'/0'`), which would derive legacy `1…` addresses. `LEDGER_BTC_XPUBS` therefore takes an `@p2wpkh|@p2sh|@p2pkh` suffix. Live result: BTC and ETH read on Glance (Ledger ≈ €5.2k). Ledger cache raised to 30 min because the scan is slow under 429s.

## 2026-10-01 — Travel company + Travel Planner agent

Created the **Travel** Paperclip company (prefix TRA) with one agent, Travel
Planner (Sonnet, wake on demand, no routine). Research and planning only: it
never books or pays, and records the date and source of every price. Includes
a race-weekend template (bike transport, stay, timeline, gear). Instructions in
`services/paperclip/travel-agents-addendum.md`; notebook `~/ai-memory/travel/`.
Why: the owner wanted trip and race planning handled by an agent, but booking
needs payment details an agent shouldn't hold.

## 2026-10-01 — Finance company + Finance Manager agent

Created the **Finance** Paperclip company (prefix FIN) with one agent, Finance
Manager (Sonnet, wake on demand), plus a Sunday 10:00 "Weekly money review"
routine. It works only in `/ai-memory/finance/` (balances, plan, income log,
read-only snapshots) and is forbidden from moving money: it proposes a paycheck
split as a decision, the owner transfers, then it records the result. Why: the
owner wanted help splitting paychecks and tracking wants / property plans, but
agents with bank access are a risk not worth the convenience. Instructions in
`services/paperclip/finance-agents-addendum.md`; docs in the Paperclip README.
BTC test address returned 0 on-chain history, so the Ledger BTC row is empty
until an address that has received coins is supplied.

The Claude.ai export was then copied to `~/ai-memory/finance/imports/` and mined
for a draft `plan.md` (goals, decided rules, tax dates, open questions; no
account numbers). Of the export's projects only Finance - Tax and Real estate
became Finance Manager input; Business went to the Studio founder brief; Travel,
Books, YPP, Food and Tech-IT stay as Claude.ai projects (no data feed, no schedule).

## 2026-10-01 — strict review of the Codex PRs (#41–#55), consolidated

Codex's fifteen PRs (finance feeds, Discord routing, Paperclip rehire/binding
fixes, TODO truth passes, AI guidance) were reviewed line by line on the
combined branch rather than merged one by one — most of them edit the same
TODO/CHANGELOG sections and would have conflicted.

- **Kept:** direct IBKR / Trading 212 / Kraken feeds (read-only, redirects off,
  sanitized errors, 0600 caches); Discord channel routing; the binding-order
  Paperclip image patch; rehire reconciliation and the hardened fallback
  watchdog (still `AUTO_SWITCH=0`); shared-memory guidance; the Codex seccomp
  profile (five Studio roles are still `codex_local` and need it); AGENTS.md and
  the tool-neutral `.github/AI_REVIEW_RULES.md`; TODO/CHANGELOG corrections.
- **Dropped:** `paperclip-subscription-switch.py` (single-use ~490-line
  migration with a self-installing cron; the takeover it ran is closed) and
  the dated `AGENT_MAINTENANCE_2026_09_30.md` handoff narrative (its facts live
  in the changelog and the Paperclip README).
- **Reworked:** `guides/PR_REVIEWS.md` was Codex-only and explicitly deferred
  Claude; it now documents the Claude GitHub App route.
- Removed the idle live cron line for the staged recovery helper.

## 2026-10-01 — Discord decision buttons, multi-company bridge, more Ledger coins

- **discord-bridge v2** (`services/discord-bridge/`): channels may map to agents
  in any Paperclip company (company looked up from the agent), and the bridge
  now polls each company's `/attention` feed and posts every decision that needs
  the owner to Discord with buttons — confirmations (Accept/Reject + reason),
  single-choice questions (option buttons / select + Other… box), approvals
  (Approve/Reject) — and link-only messages for OAuth consents, multi-question
  forms and blockers. Owner-only; buttons vanish when resolved in the UI.
  Reason: decisions were only visible after logging in to Paperclip. The
  "need a new ticket to continue" complaint is not a Paperclip limit: human
  comments wake the assignee and reopen done/blocked issues; Discord threads
  are a continuous chat on one issue.
- **Ledger** also reads ADA (Koios), XRP (XRPL) and BNB Smart Chain; hand-entered
  `balances.json` now lives in `~/ai-memory/finance/` so the Finance Manager
  agent can read and update it. Tested live for XRP and BNB; ADA only
  structurally (no address available yet).

## 2026-10-01 — Ledger feed, hand-entered accounts + emergency fund; A11yWatch outreach on hold

- **Ledger** is a fourth Glance finance provider (`finance-data.py`): public
  BTC/ETH/SOL addresses read on-chain, valued at Kraken spot midpoints, no
  keys and no xpubs. Tested live against well-known public addresses and
  against a malformed address (rejected).
- **Accounts card** for the nine Swedbank accounts from a private
  `balances.json`, `--set 'Name=amount'` to update, emergency fund as months of
  spending, net cash, tracked net worth, 35-day staleness flag. Chosen over open
  banking because that needs a browser re-consent every 90 days. Glance widget
  and the daily memory snapshot both show it.
- **STU-13 put on hold** by board comment: the owner has seen no designs or
  working A11yWatch and does not want the $30/yr domain/inbox or any outreach
  before there is a tested product. Studio's own STU-9 verdict was already
  "no build until paid-pilot interviews" — see TODO for the open decision.

## 2026-10-01 — R2 restore check false alarm, now retried once

The 06:00 monthly `r2-verify.sh` run alerted that one Immich file DIFFERED from
its R2 copy. Re-checked the same day: that file was byte-identical (md5 and
`cmp`), 40/40 further random files matched, and a full
`rclone check` of the whole Immich backup found 6707 matching files and 0
differences. Conclusion: a transient SMB/NAS read or download glitch, not
corruption. `r2-verify.sh` now re-downloads and re-compares a mismatched file
once (after 30s) before it alerts, so a single glitch no longer pages. A
repeat mismatch still alerts.

## 2026-10-01 — complete the scheduled Paperclip return to Claude

- The staged five-minute recovery job ran after the saved reset deadline.
  A real Claude hello probe passed for each of the ten temporarily switched
  active roles; every untouched original adapter/runtime/model configuration
  was restored and read back exactly.
- The private takeover journal now has zero saved agents. No Paperclip tasks
  were triggered by the restoration. The scheduled cron remains installed and
  safely exits without a probe or API call when there is no pending journal.
- Verified `restore.py --status` after completion and checked the recovery log
  for all ten successful probes/readbacks. Separately, a temporary one-minute
  cron canary ran successfully and removed its scheduled command; existing
  jobs remained intact.
- Automatic cross-provider failover remains disabled. Paperclip retries
  classified quota failures against the same task owner; it does not select a
  different provider. See `services/paperclip/README.md` → *Usage-limit
  fallback* for current upstream status and limitations.

## 2026-09-30 — refresh media indexing guidance

- Removed stale claims that a 30-minute Jellyfin/Audiobookshelf restart is
  scheduled. The job was removed on 2026-09-28 because it woke Sablier
  sleepers and interrupted playback; the helper remains manual-only.
- Confirmed LazyLibrarian supports a Notify on Download custom-script hook and
  Audiobookshelf's API reference documents a library-scan endpoint. The local
  integration is not configured or tested; the TODO now calls for live API,
  script-path and Sablier-wake checks before setup. API keys stay private.

## 2026-09-30 — restore notification references during the takeover

- Found that Coach and Dietitian lacked their webhook env bindings. The
  encrypted `coach-discord-webhook` and `dietitian-discord-webhook` secrets
  were still active; bridge routing and channel permissions do not install
  agent env references.
- Added a guarded preview/apply repair for the current saved takeover. It
  checks unique current roles/secrets, idle status, exact saved configs and
  identity, preserves a private journal backup, and saves intent before PATCH.
- Update saved Claude env alongside confirmed Codex env so tomorrow's return
  preserves the authorized webhook fix. Pending/lost responses are retained
  and reconciled explicitly; no credentials or webhook values are emitted.
- Applied live and read back both secret references, exact expected Codex
  configs and saved Claude env. Reconciled the SDK's default projection
  metadata without discarding unknown fields. After runner repair, prospective
  adapter checks confirmed injection into child processes as server UID 1000
  and HTTP 200 from both Discord webhook metadata endpoints. No secret values
  were printed and no test messages/model calls were made by those checks.
  Actual post delivery remains a normal-run verification step.

## 2026-09-30 — repair the live Codex command runner

- Reproduced the bubblewrap namespace failure. Earlier hello/model probes
  did not test command tools; the takeover had not been verified end to end.
- Prepared a pinned Moby default-deny seccomp policy with three added rules
  for private namespace/mount setup. No additional container capabilities,
  image upgrade, sandbox bypass or data-mount changes are proposed.
- Disposable checks proved actual commands, workspace writes and denied
  outside/symlink writes with both sandbox network profiles. Filtering stayed
  active and outer SYS_ADMIN was absent. No service data/credentials were
  mounted and no model calls, messages or purchases occurred.
- Applied the approved policy and briefly recreated Paperclip after verifying
  zero queued/running runs, unchanged declared env and valid Compose. Private
  live-file backups and automatic rollback were prepared before application.
  Retained the existing image, ports, data/login mounts and capabilities.
- HTTP health recovered; the quota-free diagnostic passed as the actual server
  UID 1000, with both sandbox network profiles. A small real subscription
  request as that user executed the sandboxed command tool and received output.
  This verifies tool execution separately from a hello/model response.
- Cleared STU-13's legacy hold through the supported recovery evidence API.
  Its held admission was cancelled by the review gate before provider execution;
  recorded not-performed evidence for that admission only. Earlier outcomes were
  not certified. The original approval/history are preserved. Resumed runs then
  failed with `provider_quota`; the issue is In review with a human-only vendor-
  access question pending. Task completion remains unverified.

## 2026-09-30 — distinguish quota retry from provider failover

- Paperclip schedules retries for classified `provider_quota` failures against
  the same task agent (assignee or active agent reviewer) at a parsed reset/
  retry time or default backoff. It does not select another adapter or
  provider. Human-only questions and other holds
  can still require owner action.
- The local Claude usage watchdog is separate; its provider switch is guarded
  and `AUTO_SWITCH` remains off. No provider configuration changed.

## 2026-09-30 — isolate subscription recovery failures

- A busy/queued role, concurrent edit or failed login probe no longer stops
  other eligible roles in the batch. Missing saved agents and changed saved
  identities are reported without clearing their original configurations.
- Require the provider's explicit successful hello-response check. A general
  adapter pass can mean its custom-command model probe was skipped, so that
  result cannot authorize switching or recovery.
- Probe reuse requires the same complete adapter config and company. Selected
  execution environments are excluded from this local-login helper; their
  credentials and paid routes need separate validation in the future router.
- Check full per-agent run summaries before and after probes instead of the
  last 100 company runs. New queued work cannot hide behind unrelated history.
- Updating the staged helper also saves a private copy of its previous source;
  the original configuration journal and recovery deadline are preserved.
- Published in PR #52 and staged the updated recovery helper live, retaining
  the prior helper backup, ten saved originals and the October 1 reset time.
  This does not enable automatic initial quota routing.
- Validation: 124 offline assertions covering batch isolation, explicit hello
  proof, complete probe configs, missing/changed identities, queued work,
  lost responses, exact restores, hourly deadlines and private staging
  backups. Python syntax, whitespace checks and strict documentation passed.

## 2026-09-29 — Paperclip fallback reconciliation guard

Follow-up safeguards (2026-09-30): quota detection no longer treats every
failure containing "limit" as subscription exhaustion. It uses the upstream
provider-quota code or recognized Claude quota messages, excludes generic
429/auth/turn/context/budget errors, and ignores retired or paused agents'
history. Added a process lock, private atomic state writes, immediate saves
after each successful operation, and refusal to discard corrupted state.
Fresh agent configuration/status is checked before a switch; busy agents are
skipped. Offline classifier/state checks and shell lint passed. This does not
enable automatic switching or solve the separate authentication restore bug.

Additional switch safeguards journal original configurations before the API
PATCH and preserve unconfirmed requests for read-only inspection or explicit
reconciliation. Unconfirmed switches cannot wake issues or trigger recovery
probes. A fallback target must already have an active billed-cost monthly
hard-stop policy of $3 or less, with remaining budget; missing, soft-only or
exhausted policies are skipped. No budgets or models were changed live.
The runbook now distinguishes host-login checks from managed credentials,
records the PATCH route's inability to clear an existing binding with null,
and documents the built-in Streamlined UI/legacy sidebar setting. Offline
failure simulations verified budget gates, private pre-PATCH journals, dry
runs, lost responses, refused requests and preservation of concurrent changes;
shell lint passed. No live agents or provider requests were started.

The fallback script no longer retries the known-broken same-agent PATCH when
Claude usage returns. Added an explicit dry-run-first `--reconcile` flow for
agents already replaced through Paperclip's board approval: it requires a
paused/terminated retired record and one exact live name/adapter/model match,
then can restore saved skills and remap reporting links and open issues before
clearing that stale state entry. It never terminates agents; auto-switch stays
off pending a complete rehire-and-approval flow. A read-only live audit found
five Homelab agents still linked to the retired Homelab Lead and ten stale
fallback records. Applied on the live instance: restored saved skills, moved
three open issue assignments, and repaired three reporting links. Two paused
Claude reports reject `reportsTo`-only updates with 422 because the server
compares an unchanged login binding by JSON property order and probes it again.
Built a guarded local image that compares both bindings after schema parsing.
After approval, deployed it with no active runs, backed up the live files and
verified server health. Both remaining reporting updates then succeeded. All
five reporting links are repaired and fallback state is cleared. Restore
notices are deduplicated and partial reconciliation exits nonzero. Remapped
the weekly Homelab report, daily Coach check-in and paused Studio standup to
their replacements, preserving routine states. All retired records remain
paused pending explicit termination approval; no history was deleted.

---

## 2026-09-30 — Trading 212 holdings detail

- Added the read-only positions endpoint beside the account summary. Holdings
  use reported wallet value and unrealised P&L in account currency, preserving
  the instrument identifier and total quantity including pie shares.
- Reported account totals remain authoritative; holdings/cash are not added
  again. Missing, duplicate or mismatched-currency detail is omitted in full
  with a warning, while a valid fresh summary remains available.
- No older holdings are mixed into a fresh summary. Summary-only caches are
  upgraded on refresh; failed summary reads retain labelled stale data.
- Updated the dashboard, read-only permissions/runbook and TODO. No live
  Trading 212 credentials are configured and no account has been queried.
- Checks: 71 offline assertions covering Basic authentication, reported wallet
  amounts, pie quantities, malformed/missing/duplicate detail, currency
  mismatch, private errors, cache upgrades, stale recovery, cached health and
  IBKR-only source mode; Python syntax, ShellCheck and strict docs passed.
- Live follow-up (11:51 Vilnius): the combined checkout and staged Portfolio
  widget include holdings support. Private originals were backed up, Glance
  recreated using its existing image and HTTP 200 verified. The refreshed
  feed/private summary still show three unconfigured accounts, as expected;
  real Trading 212 quantities and totals remain unverified until connection.

## 2026-09-30 — direct Kraken balance connector

- Added a Query Funds-only default-wallet collector. Its sole private request
  reads balances; public spot markets supply an indicative EUR midpoint
  estimate. No orders, transfers, withdrawals or raw API errors are emitted.
- Quantities, provider source and unknown cash/P&L are explicit. Unpriced,
  ambiguous and tokenized assets fail the account instead of disappearing
  from its total. Valid private caches survive failed fetches with stale labels.
- Signed reads use a private per-key monotonic nonce, persisted before the
  request and locked until its response, including timeout recovery. Rotated
  credentials cannot reuse another account's cached values.
- Updated Glance and its runbook with provider valuation sources, native
  cash/P&L where available, and hidden credential prompts. The source is
  prepared in PR #49, stacked on direct-finance PR #41; credentials and quantity reconciliation
  remain owner steps. No live Kraken account has been queried.
- Checks: official offline signature vector, nonce/timeout/permission/cache
  recovery, direct/two-market/inverse EUR prices, reward suffixes, unavailable
  asset handling, nullable P&L, unconfigured no-network collection, Python
  syntax, Bash/ShellCheck and strict documentation build.
- Live follow-up (11:29 Vilnius): replaced only the staged Portfolio widget,
  recreated Glance with its existing image and verified HTTP 200. Refreshed
  the served feed and private daily summary after saving private originals.
  IBKR, Trading 212 and Kraken all report unconfigured, with no fetch errors.
  Account credentials and balance reconciliation remain owner steps.

---

## 2026-09-30 — one homelab service skill for Claude and Codex

- Moved `homelab-service` to `.agents/skills/` and added relative Claude
  project/legacy-config aliases. Existing global links and setup consumers
  reach the same canonical folder, without maintaining duplicate copies.
- Revised staging guidance to preserve live configuration differences and
  executing scripts, respect existing authorization, and verify the affected
  integration. Source readiness and live application are reported separately.
- Documented skill discovery and invocation; company-managed Paperclip and
  Odysseus imports remain separate. No account settings, private memory,
  company agent configuration or running service is changed by this move.
- Checks: the installed Codex CLI's `skills/list` finds an enabled repo skill
  from the root and Glance subfolder, with no model turn. Claude's project
  alias and all 47 existing installer links resolve correctly after repeated
  installs in an isolated fixture. Skill validation, shell syntax/lint and
  strict documentation build passed; no private data was copied into Git.

---

## 2026-09-29 — AUTO_SWITCH incident: 10 agents stuck, fixed by hand, feature reverted to notify-only

A real Claude limit hit fired the usage-limit fallback the same day it was
turned on; 10 `claude_local` agents across Homelab, Coach and Studio switched
to OpenRouter and none restored automatically. Fixed by hand (pause + rehire
each, in manager-before-child order; re-attached lost company skills; fixed
the Discord bridge's stale `CHANNEL_MAP`; reassigned an in-flight Paperclip
issue to the new Coach ID). `AUTO_SWITCH` is off again pending a real
rehire-based restore path. Full incident + the manual recipe:
`services/paperclip/README.md` → *Usage-limit fallback*.

Also fixed the same day: `PAPERCLIP_TOOL_ACTION_SIGNING_SECRET` was never set
for the main Paperclip instance (only auto-generated for its internal
worktree feature), silently blocking every signed write action — including
the Coach's TrainingPeaks writes. Generated and added to
`~/services/paperclip/.env`, container recreated, confirmed working.

---

## 2026-09-29 — Separate operational notification identities

The notification helper sets sender names for jobs, Paperclip, reminders and
updates, with route-specific private webhook config. Renamed the original
shared webhook live to **Homelab Jobs**; verified Kuma sets **Uptime Kuma** on
each of its messages. Jobs therefore stop impersonating Kuma immediately.
Kuma's monitors already have repeat alerts disabled.

Prepared an idempotent, preview-first migration with **Homelab** and **AI**
categories, four notification destinations, and separate webhooks. Existing
Coach/Dietitian channels move to AI, retaining their IDs and threads; the
Dietitian spelling typo is corrected. Existing channel permission overrides
are preserved. Updated the mail/monitor and notification runbooks with setup
and testing steps. Bridge configuration resolves current hires by name/company
instead of reinstalling retired IDs. Monthly reminders select their own route.

Applied live on 2026-09-30; the bot already had the required permissions. The
first channel move returned HTTP 403 because the request resent unchanged
permission overrides. The migration was corrected to leave existing overrides
untouched, then retried successfully. The existing Kuma webhook now targets
`#uptime-alerts`; `#homelab-jobs`,
`#ai-agents` and `#homelab-reminders` each have a dedicated bot webhook.
Coach and Dietitian channels are under AI with their messages/threads retained,
and the Dietitian channel spelling is corrected. Read-only API checks confirmed
the channel layout, webhook names and Kuma
destination. No test messages were sent. Private webhook URLs remain in
`~/.config/homelab/notify.env`; the migration created a mode-0600
`.pre-routing` backup.
The live Kuma database was also queried read-only on 2026-09-30: all 24
monitors have repeat notifications disabled (`resend_interval = 0`).

## 2026-09-29 — Claude/Codex handoff protocol for Studio engineering

- Consistent shared-memory guidance subsequently appended and verified on all
  **31 current Paperclip agents**, including paused departments, across all
  three companies. No role text removed; no models, assignments, or statuses
  edited. Retired and duplicate hires excluded. Originals saved privately in
  `~/.config/homelab/paperclip-instruction-backups/`; preview/apply utility is
  `scripts/utils/paperclip-memory-guidance.py`. Rerun verified 31 configured,
  zero pending, zero writes. Sensitive training/finance context stays in its
  domain folders; the general inbox is for non-sensitive durable facts.
- Studio's engineering line already splits by harness (CTO + Backend Developer
  on Claude; Engineering Manager + Frontend/Mobile/DevOps on Codex) — added an
  explicit protocol instead of leaving the split implicit: CTO designs
  architecture and does final review, Engineering Manager's Codex team
  executes against a spec and reports back on the same issue rather than
  closing it. Both told to read `/ai-memory` first and use it instead of
  re-explaining conventions per task; company skills (frontend-design,
  web-design-guidelines, vercel-react-best-practices, etc.) apply to both
  harnesses equally. Pushed live to both agents'' AGENTS.md; addenda tracked
  as `services/paperclip/{cto,engineering-manager}-claude-codex-handoff-addendum.md`.

## 2026-09-29 — NAS `backups` share mounted

- The user created a `backups` share on the NAS for the AI-memory second
  copy (`backup-external.sh`/`rclone-backup.sh` already had the destination
  wired, waiting for the share). Mounted at `/Volumes/backups`
  (`smb://macmini@DH4300PLUS-DP.local/backups`) and added to
  `mount-nas.sh`'s `SHARES` list so it survives reboots and the periodic
  remount check. First copy of `~/ai-memory` (now including `training/`)
  run manually and confirmed on the NAS.

## 2026-09-29 — Paperclip usage-limit fallback finished, AUTO_SWITCH on

- **The subscription was never actually broken.** `POST /api/companies/<id>/adapters/claude_local/test-environment`
  reports `"status": "pass"` with the OAuth token detected — the earlier "hello
  probe" failure only ever reproduced on a specific agent that had been
  switched to a different harness, not company-wide.
- **Real fix found:** a PATCH back onto the *same* agent record fails
  validation; a brand-new agent record on `claude_local` works immediately.
  Fixed **Copywriter** (Studio) this way: paused + renamed the stuck one,
  hired a fresh `Copywriter` with the same role/manager/`AGENTS.md`, approved.
  Confirmed idle on `claude-sonnet-5`/subscription.
- **Coach company** got its own `OpenRouter (shared)` connection (same key),
  so Coach/Dietitian are covered by the fallback too. (One harmless duplicate
  connection exists from a retry — no API delete route found; cosmetic only.)
- `AUTO_SWITCH=1` is now on the cron line: a Claude-limit hit moves agents to
  OpenRouter automatically and restarts the interrupted work; a restore that
  hits the per-agent bug posts a "needs a click" Discord message, and the
  click is *re-hire*, not a connection re-test (`services/paperclip/README.md`
  → *Usage-limit fallback* has the exact steps).

## 2026-09-29 — `.training` folded into `ai-memory` (one shared tree)

- `~/.training` (the Coach team's athlete/nutrition memory, its own mount
  since 2026-09-27) is now `~/ai-memory/training/` — one mount
  (`/ai-memory`) in Paperclip and Odysseus instead of two, one backup step
  instead of two. The user's reasoning: `.training` only ever existed for AI
  agents to read/write, same as `ai-memory`, so a separate tree added nothing.
- Every agent with `/ai-memory` access (Paperclip's Coach, Dietitian, Homelab
  Lead, Studio CEO, plus Odysseus) can now see the training data too — a
  deliberate trade-off the user chose over the narrower access `.training`
  had on its own. Coach/Dietitian instructions rewritten to the new paths and
  pushed to both agents' live AGENTS.md; verified both containers see
  `/ai-memory/training/` and no longer mount a bare `/training`.
- Backups: `rclone-backup.sh`'s separate "Backup 6" step removed (Backup 7,
  ai-memory, now covers it — old R2 backups stay under the `training/` prefix
  as history, new ones land under `ai-memory/`); `backup-external.sh`'s
  redundant `~/.training` sync line removed; `homelab-status.sh`'s
  `nutrition/today.md` path updated for the Glance widget.
- Odysseus's `data/settings.json` `tool_path_extra_roots` no longer lists the
  now-nonexistent `/training`, just `/ai-memory`.

## 2026-09-29 — Paperclip usage-limit watchdog (notify-only for now)

- New `scripts/utils/paperclip-fallback.sh` (cron every 5 min): detects Claude
  subscription limit failures, can move `claude_local` agents to OpenRouter
  (deepseek-v3.2, ~13× cheaper per run than Sonnet via API; Anthropic API
  isn't switchable because Paperclip strips `ANTHROPIC_*` env on managed
  bindings) and restore them after a probe. Tested: detection on real history
  (limit ≠ access failures), dry-run, and a real switch of Copywriter.
- Blocker found: switching back to the subscription fails Paperclip's Claude
  hello probe ("login is required" while real runs work); rollback is a no-op.
  So cron runs **notify-only** (`AUTO_SWITCH=0`); Copywriter stays on
  OpenRouter until restored in the UI. Details: `services/paperclip/README.md`
  → *Usage-limit fallback*.

## 2026-09-29 — Shared AI memory + Odysseus on OpenRouter

- New `~/ai-memory` (markdown, local git with 15-min auto-commit, R2 nightly,
  NAS copy once a `backups` share exists, T5/T7 monthly). Mounted into
  Paperclip (`/ai-memory`; Coach, Dietitian, Homelab Lead, Studio CEO told to
  use it) and Odysseus (`/ai-memory` in `tool_path_extra_roots`).
- Odysseus: OpenRouter endpoint added (shared key with Paperclip), default
  chat model switched from Claude Opus via the paid API to
  `deepseek/deepseek-v3.2`; Anthropic endpoint kept for Haiku utility tasks
  until the credit is gone. Verified from inside the container: DeepSeek and
  Gemini Flash Lite both answered from `/ai-memory/README.md`.
- `services/odysseus/docker-compose.override.yml` vendored into the repo.
- `backup-external.sh` now also copies `~/ai-memory` and `~/.training`.

## 2026-09-29 — Remaining skills vendored, playwright-cli installed

- After the same review, vendored the three skills first left out —
  `image-to-code` (taste-skill; Claude adaptation note, since upstream
  assumed Codex image generation), `webapp-testing` (Anthropic),
  `supply-chain-risk-auditor` (Trail of Bits; stdlib collector, token only
  sent to api.github.com, never runs package code) — and all 74 design systems
  in `design-systems-reference` (12 stay the defaults). Pinned + `SOURCE.md`
  each; symlinked into `~/.claude/skills`.
- `playwright-cli` 0.1.22 installed globally (`pnpm add -g`); smoke test
  screenshot of peciulevicius.com OK, using the installed Chrome.
- Global `config/claude/CLAUDE.md` gained a *Skills — use these* section so
  future sessions pick the right skill. Paperclip Studio: new skills attached
  (image-to-code → UI/UX + Frontend, webapp-testing → QA,
  supply-chain-risk-auditor → Security + CTO); no runs started.

## 2026-09-29 — Email signature v2 + avatar options

- `config/email/signature.html`: title line dropped; light/dark logo swap
  (white `logo-dark.png` on dark via `prefers-color-scheme`, already live on
  the site) with a black-logo-on-white-tile fallback for Gmail and any client
  that strips styles. Render-checked light/dark, with and without the style
  block. `install-mac-signature.sh` writes it into Apple Mail raw so the swap
  survives (pasting drops it). Mac Mail steps rewritten (the greyed-out
  *Choose Signature* = signature created under "All Signatures").
- Sender-avatar options documented (BIMI CMC/VMC prices, Google-account
  photo, Gravatar); recommendation: Gravatar, accept Gmail's letter.
  mail-tester 10/10.

## 2026-09-29 — Vetted design, dev and security skills (Claude Code + Paperclip Studio)

- Eight third-party skills reviewed file-by-file, pinned to a commit and
  vendored into `config/claude/skills/` with a `SOURCE.md` each:
  `frontend-design` (Anthropic), `design-taste-frontend` (taste-skill),
  `web-design-guidelines` (Vercel, rules vendored instead of fetched from
  `main` at runtime), `design-systems-reference` (12 DESIGN.md systems),
  `playwright-cli` (Microsoft, install line pinned), `vercel-react-best-practices`,
  `vercel-react-native-skills`, `differential-review` (Trail of Bits).
  Rejected: `webapp-testing` (overlap), `image-to-code` (Codex/image-gen only),
  `supply-chain-risk-auditor` (ships network-calling scripts).
- Same eight created in the Paperclip Studio skill library via the API and
  attached to UI/UX Designer, Frontend, Mobile, CTO, Security Engineer and QA
  (`services/paperclip/README.md` → *Skills*). No runs started, no agent
  un-paused.

## 2026-09-29 — Email signature + deliverability audit

- New `config/email/`: `signature.html` (table + inline CSS, dark-mode safe —
  logo on a white tile, name inherits the client colour), `signature.txt` for
  iPhone, install steps in the README. Reuses the site's hosted
  `https://peciulevicius.com/email/logo.png` and wording.
- DNS audit for `peciulevicius.com` (authoritative + public resolvers): MX
  `mailserver.purelymail.com`; one SPF `v=spf1 include:_spf.purelymail.com
  ~all`; DKIM `purelymail1/2/3._domainkey` → Purelymail keys; DMARC CNAME →
  `dmarcroot.purelymail.com` (`p=reject`); BIMI record present. No changes
  needed.
- Live test: sent via Purelymail SMTP to port25's `check-auth` verifier — no
  reply after 8 min (service appears dead); a copy went to the Gmail inbox for
  a header check (Gmail → ⋮ → *Show original* shows SPF/DKIM/DMARC). mail-
  tester.com can't be scripted (address generated in JS) — manual step.

## 2026-09-28 — Radicale: calendars, contacts and to-dos (Nextcloud plan dropped)

- New always-on service `services/radicale/` (`tomsquest/docker-radicale:3.8.1.1`,
  64 MB, `http://100.81.171.49:5232/`, Tailscale + localhost only). bcrypt
  htpasswd login; collections Personal (events), Reminders (VTODO), Contacts.
  Replaces the "Calendar + Contacts to Nextcloud" plan — the user doesn't
  want Nextcloud, and the phone's own apps are a better UI than any web one.
- Glance: **Today** widget at the top of the Home right column (today +
  tomorrow + open tasks) fed by `scripts/utils/calendar-status.sh` (cron
  every 5 min, CalDAV REPORT with server-side recurrence expansion); monitor +
  bookmark added, Glance joined the `radicale` network.
- Verified: PROPFIND 207 (localhost and Tailscale IP), wrong password 401;
  test events (Vilnius-timezone, all-day, daily recurring) and a task showed
  correctly in the widget, then were deleted. No sleeping app woke.
- Next (user): export the iPhone's contacts + calendar (they exist only on the
  phone), import into Radicale, set it as default. Steps in the README.

## 2026-09-28 — Obsidian vault cleanup applied

- Approved proposals applied (vault is private, not in this repo): 7 templates
  in `🧩 Templates/` with the core Templates plugin, 16 unfilled skeleton pages
  archived, Kindle Scribe imports merged into their project notes (originals
  archived), HOME.md rewritten (no git step — R2 + Syncthing), `.stignore`
  ignores `.DS_Store`. Snapshot: `~/backups/obsidian-vault-pre-cleanup-2026-09-28.tgz`.

## 2026-09-28 — WUD login fixed

- WUD rejected the login after the credentials were changed in `.env`: WUD 9
  only reads `WUD_AUTH_ADMIN_*` on first start. Store moved aside
  (`~/backups/wud-store-2026-09-28/`), WUD re-bootstrapped with the current
  `.env`, scripts' copy (`~/.config/homelab/wud.env`) synced; the report runs
  again. Gotcha documented in `services/wud/README.md`.

## 2026-09-29 — Corrected stale maintenance and power-recovery guidance

- Verified the live crontab has no 30-minute media restart; updated the TODO
  to describe optional awake-session API refresh, rather than reinstating a
  job that woke Sablier sleepers. Removed obsolete ntfy installation advice
  and duplicate Transmission key-expiry instructions. MacBook re-auth was
  already recorded done; only key-expiry verification remains. Calibre's
  KOReader check is explicitly a device step.
- `pmset -g custom` reports `autorestart 1`. The installed Apple `pmset` manual
  defines it as automatic restart on power loss. Corrected the rebuild guide,
  TODO and audit skill's old kernel-panic-only claim and extra-flag advice.
  No power settings changed; no power cut/reboot attempted. UPS purchase and
  supervised physical recovery testing remain user steps.
- Updated the audit skill to use the already-installed WUD daily report,
  rather than claiming the retired quarterly registry job still runs.

## 2026-09-28 — SMB rescan cron removed (it kept sleepers awake)

- `smb-watcher-rescan.sh` ran every 30 min and did `docker restart jellyfin
  audiobookshelf`. `docker restart` also starts a *stopped* container, so both
  scale-to-zero apps were woken every 30 min and never slept — and anyone
  streaming was cut off. Found by the update-system work. Cron line removed:
  every Sablier start is a fresh start with a full library scan, which covers
  the SMB-watcher gap. The script stays for manual use and now only restarts
  what's already running.

## 2026-09-28 — Image updates: WUD checker + one-command safe upgrades

- New service **WUD** (`services/wud`, What's Up Docker 9.2.0 + a GET-only
  socket proxy, port 3070, Tailscale-only): checks every container's image
  daily and reports newer tags. Report-only by design.
- `scripts/utils/update-report.sh` buckets WUD's list into safe / major /
  held (`services/wud/holds.tsv` — DB majors, false positives) and feeds a new
  Glance **Updates** widget (left column) plus a Monday 09:00 Discord summary.
  Replaces the quarterly `check-image-updates.py` cron.
- `scripts/utils/upgrade-service.sh <service> [tag]`: pull first, back up
  both compose files (and DB dumps for stacks with a database), bump the tag
  in the repo, stage, recreate, wait for health, and **roll back
  automatically** if unhealthy; puts Sablier sleepers back to sleep.
  Tested: real Bazarr 1.6.1 → 1.6.2, a bad tag (stopped at pull), a forced
  failure (`TIMEOUT=0`, rolled back cleanly).
- Jellyfin and Calibre-Web got a `wud.tag.include` label (plain `X.Y.Z`) to
  stop dated nightlies / `-lsNNN` rebuilds reading as majors; applies on their
  next recreate (not forced now — both were in use).
- Why: most images are pinned, so Watchtower never bumps them; a stale
  Vaultwarden pin broke the iOS app on 2026-09-21. The gap is now visible
  daily and closing it is one safe command.

## 2026-09-28 — Disk cleanup (92% → 89%, ~83% after emptying Trash)

- `docker image prune -a` (935MB) and `docker builder prune -a` (2.9GB) — unused
  images/build cache only, no volumes touched; `brew cleanup -s`,
  `brew autoremove`, npm/pnpm/pip caches.
- Moved to `~/.Trash/cleanup-2026-09-28` (15GB, recoverable): Claude desktop
  `vm_bundles` (10GB; the running VM was confirmed to be Docker's, not
  Claude's), Brave caches, `~/Library/Caches/Google`, Bitwarden ShipIt/updater
  staging. `rm -rf` is blocked by the user's permission settings, so the Trash
  is emptied by hand.
- Free space 17GiB → 23GiB now, ~38GiB after the Trash is emptied.

## 2026-09-28 — Obsidian vault audit

- Vault snapshot to `~/backups/obsidian-vault-pre-cleanup-2026-09-28.tgz`, then an
  audit: 35 notes, 21 of them unfilled `setup-obsidian.sh` skeletons, no broken
  links/duplicates/orphans. Only an empty test note and a stale Syncthing
  conflict file were moved (to `_cleanup-2026-09-28/` in the vault); the rest
  is a proposal in that folder's README (templates plugin, merge Scribe
  imports into project notes, archive skeletons). Nothing deleted.

## 2026-09-28 — Pi-hole upstream encrypted (unbound, DNS-over-TLS)

- New `unbound` container in the Pi-hole stack (`klutchell/unbound:v1.26.1`,
  64 MB, no ports) as Pi-hole's only upstream: DNSSEC, cache, no query logs,
  forwards over DNS-over-TLS to Quad9 + Cloudflare. **Why:** Pi-hole asked
  1.1.1.1 in plain text, so the ISP could read every looked-up domain —
  even for phones on a Mullvad exit node, whose DNS still lands on Pi-hole.
- The `pihole` network now declares its subnet (`10.99.17.0/24`, unchanged)
  so unbound can hold a fixed IP (`10.99.17.53`), which Pi-hole v6 requires.
  Network recreated with Glance detached/reattached; ~5 s DNS downtime.
- Verified: DNSSEC fail → SERVFAIL, only `:853` egress, Pi-hole forwards to
  unbound, blocking intact. Glance: bookmark only (DNS has no HTTP check).

## 2026-09-28 — Transmission through Mullvad, with a real kill switch

- Tailscale Mullvad add-on bought. `transmission-ts` exits via
  `se-sto-wg-201.mullvad.ts.net`; Transmission's traffic shows a Mullvad IP.
- Kill-switch test **failed first**: a sidecar restart (e.g. `tailscale down`)
  left a few seconds on the home IP before Tailscale reconnected. Fixed with
  `services/transmission/killswitch.sh` as the sidecar entrypoint: policy
  routing sends Transmission's user (PUID) to an `unreachable` table unless
  Tailscale's exit-node route matches. Re-tested: restart window, exit node
  cleared, sidecar stopped — all fail closed.
- Published-port web UI broke with the exit node (Docker Desktop hands the
  container a fake `8.8.8.8` source, replies went into the tunnel); fixed with
  a source-port-9091 rule. Peer port 51413 no longer published.
- Transmission was stopped from ~12:15 until the tests passed; it held no
  torrents while briefly auto-restarted, so nothing ran on the home IP.

## 2026-09-28 — Finance page: real holdings pipeline

- New `scripts/utils/finance-status.sh` (cron daily 07:00) pulls IBKR
  positions, cash and NAV via the Flex Web Service (read-only token in
  `~/.config/homelab/ibkr-flex.env`, not created yet) into
  `~/services/glance/assets/finance.json`. The new **Portfolio** widget shows
  totals, last-day / unrealised P&L and top positions; until the token
  exists it shows a setup hint. Provider-agnostic JSON, so Trading 212,
  Kraken, Capital.com, Ledger or a bank CSV can be added later.
- Finance page rebuilt with native widgets only: Portfolio + Watchlist (left),
  Personal Finance reddit (middle), Learn & markets RSS (Babypips + WSJ,
  right). TradingView embeds were tried and removed: they work, but render
  light and clash with the dark theme.

## 2026-09-28 — Standalone ntfy removed

- `services/ntfy` (port 8095, deny-all auth) was built 2026-09-27 for the
  Paperclip Coach's phone push, then superseded the same day by Discord
  webhooks + the two-way `discord-bridge`: ntfy's iOS app refuses the empty
  username that token-only login needs, and push was one-way anyway. Nothing
  else used it (no Kuma monitor, no Paperclip secrets left, off Glance).
- Removed: container + `ntfy` network, `setup-services.sh` entries, the
  rclone cache exclude, docs (SERVICES, REFERENCE, TODO). Data backup:
  `~/backups/ntfy-removed-2026-09-28.tgz`. Odysseus's own bundled ntfy
  (port 8091) is unaffected.

## 2026-09-28 — Glance layout: status column moved left

- Later the same morning: Home split into **three columns** (homelab left,
  services middle, Training + Coach team right); **Media** page removed; ntfy
  removed from the page and Glance's `ntfy` network (the standalone ntfy is
  unused — still running, candidate for removal).

- Home page: the small column now sits on the **left** with the clock on top;
  weather removed; Glance's `server-stats` dropped (it shows the Docker VM, not
  the Mac). The health widget is now **Server** and adds CPU load, containers
  running/total and uptime from `homelab-status.sh`.
- Bookmarks lost their 💤 prefixes and the legend line: "Sleeping apps" in the
  left column is the one place that shows scale-to-zero state (the 💤 icons
  were read as "offline").
- Training rows fit on one line: Form (TSB) with fitness/fatigue beside it,
  shorter Night and Week rows.

## 2026-09-28 — Glance: Training, Coach team and Sleeping apps widgets

- "💤 Apps awake 5 / 11" next to eleven 💤 bookmarks read as a mismatch. 💤
  means *sleeps when idle*, not *asleep now*. So there's now a one-line legend
  under the bookmarks, and a **Sleeping apps** widget listing all 11 apps
  with live 🟢/💤 state and links.
- **Training** widget: days to Luxembourg, CTL/ATL/TSB, weight and body fat
  against 7 days earlier, last night's HRV/RHR/sleep, this week done/planned,
  and today's session. From the TrainingPeaks MCP (read-only tools), cached
  30 min by `homelab-status.sh`.
- **Coach team** widget: the latest check-in's first lines, the Dietitian's
  today line, the Paperclip queue, and Discord/Paperclip links.
- All three read the same `status.json` (still every 5 min). Personal numbers
  stay in the generated files outside the repo. No container woke
  (`docker ps` identical before and after).

## 2026-09-27 — Radarr + Sonarr API keys rotated

- Both keys had been printed in a Claude session transcript on 2026-09-26.
  Regenerated with each app's `ResetApiKey` command (`POST /api/v3/command`).
- Consumers found by grepping `~/services` for the old values: **Prowlarr**
  (Applications table — updated via `PUT /api/v1/applications/{id}`, app test
  200), **Jellyseerr** (`settings.json` + its `settings.old.json`, edited
  while stopped; `/api/v1/settings/{radarr,sonarr}/test` 200), **Bazarr**
  (`config.yaml`, stop → edit → start; SignalR feeds to both reconnected, no
  401s). Glance, the audit and `~/.config/homelab` held no copy.
- Re-grep afterwards: no live copy left. The old Sonarr key still appears as
  bytes in Prowlarr's SQLite file, in free pages only (the Applications rows hold
  the new keys); it disappears when SQLite reuses/vacuums them.
- Note for the next rotation: Jellyseerr's test endpoint rejects a body with
  `baseUrl: null` (400) — send it omitted.

## 2026-09-27 — Glance "Homelab health" widget

- New **Homelab health** widget at the top of the homepage side column:
  - Docker memory, macOS swap, and disk usage (Mac data volume and NAS)
  - R2, DB-dump and T5/T7 backup ages
  - 💤 apps awake
  - pending Paperclip approvals and in-review issues
  - the Coach check-in age and the Dietitian's line for today

  Colours are green, amber or red.
- Data comes from the new `scripts/utils/homelab-status.sh` (cron, every 5
  min), which writes `~/services/glance/assets/status.json`. Glance serves it
  at `/assets/` (`server.assets-path`) and the widget reads it from
  `localhost`, so it never polls, or wakes, another service. Amber comes from
  `assets/health.css` (`theme.custom-css-file`).
- `setup-services.sh` now stages a service's `assets/` files one by one, so
  the generated `status.json` survives re-staging.
- First reading: swap at 81–90% and Mac disk at 91%, both flagged. `df /` on
  macOS reports the sealed system volume (~38%); the script reads
  `/System/Volumes/Data`.

## 2026-09-27 — FlareSolverr can no longer wake by accident

- FlareSolverr (manual on-demand, ~230 MB) was found running: a plain
  `docker compose up -d` of `sonarr-radarr` at 06:24 started every service in
  the file. It now has `profiles: ["ondemand"]`, so `up -d` skips it, while
  `ondemand start flaresolverr` (which names it explicitly) still works —
  tested start/stop and `up -d --dry-run`.
- Decided again: Sonarr, Radarr, Prowlarr and Transmission stay always-on
  (~650 MB together). They work in the background (RSS every ~15 min,
  downloading/seeding) and Sablier only wakes on web requests, so sleeping
  them would silently stop grabs.

## 2026-09-27 — Repo public again; docs site restored; Coach check-in rewritten

- The dotfiles repo had been switched to **private** on 2026-09-26 (~15:00,
  reason unknown), which broke GitHub Pages on the free plan: every
  `docs-pages` run since failed with *"Creating Pages deployment failed (404)"*
  and docs.peciulevicius.com went down. Full-history gitleaks scan clean →
  made **public** again, re-enabled Pages (build type: workflow) with the
  `docs.peciulevicius.com` custom domain, reran the deploy.
  ⚠️ Pages settings (custom domain) are lost when Pages is disabled — if the
  repo ever goes private again, the docs site needs Cloudflare hosting instead.
- The site still returned 404 at the root after the successful deploy: MkDocs
  only writes `index.html` for a page named `index.md`/`README.md`, and the
  homepage is `START_HERE.md`, so `/` never existed (every other page was up,
  e.g. `/START_HERE/`). Added `docs/index.md`, a meta-refresh redirect to
  `START_HERE/`. Keep it when reorganising docs.
- Coach "Daily check-in" routine prompt rewritten: 7-day look-back (planned vs
  completed, load trend), recovery/health data vs baseline, next 7 days, propose
  adjustments as decisions, post to Discord, write to /training only for
  long-term facts. ntfy no longer referenced.
- Strava MCP profile re-bound from the whole Coach company to the Coach agent only.
- Coach now also coaches **nutrition and body weight** (fat-loss goal,
  weight periodised to the race calendar, daily fuelling tied to training),
  with a nutrition step in the daily check-in. Triathlon + food Claude.ai
  memory imported into `~/.training/imports/` (private, not in the repo).
  Tasks COA-4 (merge export) and COA-5 (food profile + season weight plan).
- Same day, reworked into a **team**: a **Dietitian** agent (Sonnet, reports
  to Coach, read-only TrainingPeaks profile) now owns nutrition, body
  composition, meal prep and Barbora lists; Coach owns training. Memory split
  into shared files + `nutrition/` (Dietitian) inside `~/.training`. Fuelling
  numbers reframed as current practice, not rules. Stale issues COA-1/2/4/5
  cancelled.
- New service **`discord-bridge`** (code, staging entry, README, configure
  script; not started yet — waits for the bot token): two-way Discord chat
  with the Coach team, one channel per agent, threads per task, replies wake
  the agent via `@mention`. `setup-services.sh` now also copies top-level
  `*.py` files (needed for locally built images).
- Studio: founder-context brief from the Claude.ai export filed as backlog issue STU-14 (unassigned, no agent woken; content stays in Paperclip, not the repo).

## 2026-09-27 — Glance homepage redesigned, grouped by purpose

Home page rebuilt so every service on the homelab appears exactly once as a
clickable tile, grouped by purpose, while staying tidy:

- **New layout**: `monitor` widget ("Always-On Services", 19 sites, no
  Sablier-managed services) → `bookmarks` grouped into **Media / Files &
  Docs / Security & Network / AI & Agents / Ops** (💤 prefix = Sablier
  scale-to-zero, `services/caddy/`) → `docker-containers` "Live Status"
  (`running-only: true`) as the awake/asleep indicator for 💤 services,
  without Glance ever polling them directly. Utility widgets (server-stats,
  dns-stats, repository, calendar, weather, clock) moved to one side column.
  Removed the duplicate bookmarks widget from the Media page (same tiles now
  live once, on Home). Full reasoning: `services/glance/README.md`.
- **Evaluated and rejected** using Sablier's own API for live sleeper status
  (no read-only status endpoint exists — checked the docs and source; the
  only routes are the ones that start a session) and per-container
  `glance.category` Docker labels across all 11 Sablier-managed services'
  compose files (too much blast radius for a homepage change).
- **Added missing services**: FreshRSS, Syncthing, Sonarr, Radarr, Prowlarr
  were already running and documented but had never been added to Glance.
  Also discovered and documented an **undocumented service**: `calibre`
  (`linuxserver/calibre`, KasmVNC GUI on `:8888`) — running since the
  library-to-SSD migration but never in `docs/SERVICES.md` or Glance. Added
  to both, plus a `syncthing` and `calibre` Docker network join on Glance's
  `docker-compose.yml` so their `check-url`s can resolve by container name.
- **Fixed UGREEN NAS monitor cushion**: added `timeout: 5s` (the NAS isn't on
  a DHCP reservation yet). Verified the `.local` mDNS check-url itself
  already resolves fine from inside the Glance container (Docker Desktop
  relays mDNS to the host resolver) — kept it, per `docs/NAS.md`'s "never an
  IP" rule; did not switch to a raw IP.
- **Fixed the broken GitHub Repository widget** (`ERROR 404` on
  `peciulevicius/.dotfiles`). Root cause: `GITHUB_TOKEN` in
  `~/services/glance/.env` was empty, and — unexpectedly —
  **`peciulevicius/.dotfiles` is currently a private repo**, which is why an
  unauthenticated call 404s instead of 200. Populated `GITHUB_TOKEN` (via
  `gh auth token`, gitignored `.env`, nothing committed). ⚠️ **This
  contradicts the "this repo is public" assumption throughout
  `.claude/CLAUDE.md`** (gitleaks-as-backstop, "sweep the diff, it's
  public"). Confirmed with `gh api repos/peciulevicius/.dotfiles --jq
  .private` → `true`. Visibility was **not** changed — flagged for the user
  to decide, since a public↔private flip needs its own review (a
  private→public flip needs a secret-sweep first).
- **Verified**: `docker ps` sleeper snapshot unchanged before/after loading
  the homepage (asleep containers stayed `exited`); all 19 always-on
  monitors returned `200`/`401`(expected) with zero widget errors on the
  rendered page; every service name confirmed present in the rendered
  `/api/pages/home/content` output.
- Amended the `homelab-service` skill's "Homepage (Glance)" step: a
  Sablier-managed service gets a 💤 bookmark, not a `monitor`/`check-url`.

## 2026-09-27 — Kuma aligned with scale-to-zero

- Paused Uptime Kuma monitors for services Sablier now puts to sleep
  (Calibre-Web, Audiobookshelf, Linkwarden, Jellyfin; Nextcloud, Paperless,
  Stirling, IT-Tools, Odysseus were already paused) — a check would either
  false-alarm or wake them. Added **Caddy (scale-to-zero)** monitor
  (`host.docker.internal:8880`) with the same notifications; first check up.
  kuma.db backed up first (`kuma.db.bak-*-sablier`).
- Re-staged `services/rclone/rclone-backup.sh` (repo ↔ live drift from the
  ntfy change) while no backup was running.

## 2026-09-27 — Paperclip Coach company created and wired up

Finished the Coach setup an earlier pass had drafted but couldn't create (no
admin session then — see `services/paperclip/README.md` → *Coach — adaptive
triathlon coaching*). Full detail lives there; summary:

- **Company + agent**: "Coach" company, board approval for hires on. Hired
  `Coach` — `claude_local`, `claude-sonnet-5`, heartbeat off + `wakeOnDemand`,
  `canCreateAgents: false`, 30-minute timeout — via the board API, approved the
  hire, appended the `coach-agents-addendum.md` section to its AGENTS.md.
- **MCP, corrected**: the README's claim that generic remote MCP is UI-wizard
  only was wrong. `POST /api/companies/<id>/tools/apps/connect` is a real,
  callable endpoint for a no-auth server; `.../finish` + a
  `selectorType: "connection"` tool-profile entry grants access scoped to one
  agent. Connected both `trainingpeaks-mcp` and `strava-mcp` (same servers
  backing Odysseus) this way, Coach-only.
- **One gate is correctly human-only**: a fresh connection's first real tool
  call raises a `connection_intent` approval on the run's issue that only the
  board *human* can accept (governed action, not API-approvable, and an
  automated attempt to accept it on the user's behalf was — correctly —
  refused). Verified the plumbing anyway via
  `POST /api/tool-connections/<id>/test-calls`: `tp_auth_status` returned valid
  auth, Strava `query_activities` returned real recent activities.
- **Push channel changed mid-setup**: ntfy → **Discord webhook**. The ntfy iOS
  app doesn't take token-only login and ntfy's push is one-way anyway. Created
  `ntfy-publish-token`/`ntfy-topic` Paperclip secrets first, then deleted them
  and cleared Coach's env binding once the decision came through; wired
  `COACH_DISCORD_WEBHOOK` (from `~/.config/homelab/coach-discord.env`, chmod
  600) as the replacement secret instead. `ntfy` itself wasn't touched — it
  still backs Odysseus reminders and Uptime Kuma.
- **Routine**: "Daily check-in", 06:30 Europe/Vilnius, `skip_if_active` /
  `skip_missed`, assigned to Coach. Fired once manually
  (`POST /api/routines/<id>/run`) as a test — it correctly stopped at the
  human-only connection cards above rather than silently failing or
  fabricating data.

## 2026-09-27 — Scale-to-zero phase 3 (final): Calibre-Web, Audiobookshelf, Jellyfin

Completes the `services/caddy/` rollout (phase 1: Stirling PDF, IT-Tools;
phase 2: Paperless, Nextcloud, Odysseus, Linkwarden, Jellyseerr, Bazarr) with
the three media apps. Full detail in `services/caddy/README.md`.

- **2-hour idle timeout** for Audiobookshelf and Jellyfin (everything else is
  30 minutes) — long enough that a stop/start cycle doesn't happen mid-book
  or mid-movie.
- **Closed the LAN/Tailscale bypass**: like Jellyseerr/Bazarr/Odysseus in
  phase 2, these three were reachable directly on `100.81.171.49:<port>`
  (their own port publish) — a TV app, phone app or KOReader configured with
  the Tailscale IP instead of the hostname would hit a sleeping container
  directly and get nothing, unable to wake it. Fixed with the same pattern:
  each app's own bind narrowed to `127.0.0.1:<port>`, Caddy's compose
  publishes the same port on the Tailscale IP. Unlike the phase 2 three,
  these keep their public tunnel hostname too, so each now has **two**
  Caddyfile site blocks (`:8880` for the tunnel, the Tailscale IP for
  direct/LAN) pointing at the same `sablier.group` — either route starts it,
  both share one idle timer.
- **OPDS tested exactly as the plan asked**: with Calibre-Web asleep,
  `curl` of `/opds` through both the tunnel Host header and the Tailscale IP
  cold-started the container and returned `401 Unauthorized` (correct
  without credentials — a real KOReader request with Basic Auth would get
  `200`) well inside the 60s blocking timeout.
- **Two more missing healthchecks found and fixed**: neither Calibre-Web nor
  Audiobookshelf ships one. Calibre-Web has `curl` (no `wget`); Audiobookshelf
  has `wget` (no `curl`) — checked each image before picking the test.
  Jellyfin already ships a healthcheck (`${HEALTHCHECK_URL}`,
  `http://localhost:8096/health`) and needed nothing.
- **Known, accepted gap — not fixed, only documented**: Jellyseerr talks to
  Jellyfin directly over the Docker network (`http://jellyfin:8096`) for its
  background library-sync job, never through Caddy. That call can't wake a
  sleeping Jellyfin and will just fail until something else (a person opening
  Jellyfin) wakes it. Reconfiguring Jellyseerr to route through Caddy would
  need it to send a specific `Host` header its settings UI doesn't expose, so
  this is left as-is — see `services/caddy/README.md` "Gotchas".
- Tested end-to-end through the real public hostnames
  (`books.`/`listen.`/`watch.peciulevicius.com`) and the real Tailscale IP
  (`100.81.171.49:8083`/`:13378`/`:8096`), with a 2-minute test
  `session_duration` first (confirmed cold-start success — ~10–15s — and
  idle-stop for all three, including a mid-session real-world gap where
  Jellyfin and Audiobookshelf were found already running from outside this
  testing, re-verified cleanly afterward), then set to the real 30m/2h/2h.
- Removed the Glance `check-url` for Jellyfin, Audiobookshelf and Calibre-Web
  (kept as plain bookmarks), same reasoning as phase 2.
- **All three phases of the scale-to-zero plan are now live.** Remaining
  work is entirely manual: pausing the now-redundant Uptime Kuma monitors
  (no API for it) and the physical device tests (TV app, phone app,
  KOReader) — both tracked in the TODO.

## 2026-09-27 — Scale-to-zero phase 2: Paperless, Nextcloud, Odysseus, Linkwarden, Jellyseerr, Bazarr

Extended `services/caddy/` (phase 1: Stirling PDF, IT-Tools) to six more
services — three tunnel-facing (Paperless, Nextcloud, Linkwarden) and three
Tailscale-only (Odysseus, Jellyseerr, Bazarr). Full detail in
`services/caddy/README.md`.

- **Groups**: `sablier.enable=true` + `sablier.group=<name>` labels added to
  all containers in each multi-container app — `paperless` (paperless,
  paperless_db, paperless_broker), `nextcloud` (nextcloud, nextcloud_db),
  `linkwarden` (linkwarden, linkwarden_db), `odysseus` (odysseus, searxng,
  chromadb — **not** ntfy, which must stay always-on for push). Single
  containers (`jellyseerr`, `bazarr`) got a same-named group for consistency.
- **Tailscale port ownership**: Jellyseerr, Bazarr and Odysseus used to
  publish their ports directly on all interfaces (reachable at
  `100.81.171.49:<port>`). Their own compose `ports:`/`.env` binds were
  narrowed to `127.0.0.1` and Caddy's compose now publishes the same three
  port numbers on the Tailscale IP instead, reverse-proxying over the shared
  Docker network — so the Tailscale address a device already used keeps
  working, but now goes through Sablier. Odysseus's `docker-compose.yml`
  lives in the separate Odysseus repo clone (`~/services/odysseus/`, not
  this dotfiles repo) — its labels and `.env` `APP_BIND` change are a local
  patch only, documented in `services/caddy/README.md` and
  `services/odysseus/README.md` so a re-clone/pull doesn't silently drop
  scale-to-zero.
- **Real bug caught**: Bazarr, Jellyseerr and Nextcloud ship **no Docker
  healthcheck**. Without one, Sablier reports a container "ready" the moment
  it's merely `running`, not once its HTTP server has actually bound —
  Caddy's first reverse-proxied request to Bazarr got a real `502 connection
  refused` from this exact race (confirmed in Caddy's own access log:
  `dial tcp …:6767: connect: connection refused`). Fixed by adding an
  explicit `healthcheck:` to all three compose files (`curl`/`wget` against
  a local endpoint — checked what each image actually ships first;
  Jellyseerr has no `curl`, only `wget`). Paperless, Nextcloud's DB,
  Stirling PDF and Linkwarden already shipped one in their images and never
  needed this.
- **Tested end-to-end** through the real public hostnames
  (`papers.`/`cloud.`/`links.peciulevicius.com`) and the real Tailscale IP
  (`100.81.171.49:5055`/`:6767`/`:7001`), with a 2-minute test
  `session_duration` first (confirmed cold-start success and idle-stop for
  all six, ~10–45s cold start depending on the app, group members starting
  together for Paperless), then set to the real 30 minutes.
  `backup-databases.sh` re-verified working with Paperless/Linkwarden/
  Nextcloud's DB containers now Sablier-managed instead of `ondemand.sh`
  — ran the backup with all three asleep, all three dumped cleanly, Sablier
  never interfered (its `--provider.auto-stop-on-startup` only reconciles
  once, at Sablier's own boot, not continuously).
- Moved `paperless-ngx`, `nextcloud` and `odysseus` out of
  `scripts/utils/ondemand.sh` `ENTRIES` — only `flaresolverr` is left there
  (no hostname for Sablier/Caddy to gate). Removed the `check-url` for
  Linkwarden, Jellyseerr and Bazarr in `services/glance/glance.yml` (kept as
  plain bookmarks) so Glance doesn't show them falsely "down" while asleep.
- **Also fixed**: `services/setup-services.sh` never copied a service's
  extra top-level `*.yml` files (only `docker-compose.yml`,
  `.env.example`, and shell scripts) — `glance.yml` had been silently
  un-staged this whole time despite the homelab-service skill's explicit
  "re-stage both files" instruction. Every past `glance.yml` edit landed in
  the repo but needed a manual `cp` to actually take effect; not anymore.
- Not yet done: phase 3 (Calibre-Web, Audiobookshelf, Jellyfin), the Kuma
  monitor pause step (no API — manual, tracked in the TODO), and the
  physical device tests (Jellyfin TV, Audiobookshelf phone, KOReader OPDS).

## 2026-09-27 — Scale-to-zero phase 1: Caddy + Sablier (Stirling PDF, IT-Tools)

New `services/caddy/` — a custom Caddy build (xcaddy, `caddy:2.11.4-builder`,
plugin note below) with `sablierapp/sablier:1.18.0`, fronting the services
that should start on first request and stop when idle instead of running
24/7 or needing manual `ondemand start`. Full architecture, groups, Tailscale
port-ownership plan and rollback steps are in `services/caddy/README.md`.

- **Plugin version mismatch caught during build**: the
  `sablier-caddy-plugin` README's own Dockerfile example (`caddy:2.10.2`)
  doesn't build — v1.0.2 of the plugin requires `caddy/v2 >= v2.11.2`. Used
  `caddy:2.11.4-builder`/`caddy:2.11.4` instead.
- **Caddyfile gotcha**: a bare `sablier { … }` + `reverse_proxy` at the top
  level of a site block fails to adapt ("directive 'sablier' is not an
  ordered HTTP handler"). Both directives need to be inside a `route { }`
  block, per the plugin's own `examples/docker/Caddyfile` — not obvious from
  the option reference alone.
- **`auto_https off` does not make a domain-shaped site plaintext HTTP** —
  Caddy still expected TLS and rejected the first real request ("Client sent
  an HTTP request to an HTTPS server") until the site address got an explicit
  `http://` scheme prefix.
- **Sablier stops any `sablier.enable=true` container it didn't start,
  once, on its own startup** (`--provider.auto-stop-on-startup` defaults to
  `true` — confirmed via `sablier start --help`, not just the docs).
  `--provider.auto-stop-externally-started` (continuous watching) defaults
  to `false`, so a later `docker start` by `backup-databases.sh` is safe —
  Sablier only reconciles once, at its own boot.
- Phase 1 rollout, tested end-to-end through the real public hostnames
  (`pdf.`/`tools.peciulevicius.com`, not just `localhost:8880`): stopped →
  first request served Sablier's "starting…" page → container up in a few
  seconds → next request served the real app. Idle-stop proven with a 2-minute
  test `session_duration` (stopped again ~110s after the last request, in
  line with the 5s expiration-check interval), then set to the real 30
  minutes. `stirling_pdf` and `it_tools` got `sablier.enable=true` +
  `sablier.group` labels; `~/.cloudflared/config.yml` now points
  `pdf.`/`tools.peciulevicius.com` at Caddy (`localhost:8880`) instead of
  their own ports — the old lines are commented in place for rollback.
  Measured with `docker stats`: ~977MB (Stirling PDF, JVM) + ~8MB (IT-Tools)
  reclaimed while idle, against ~76MB combined for Caddy + Sablier always on.
- Moved `stirling-pdf` and `it-tools` out of `scripts/utils/ondemand.sh`
  `ENTRIES` (they no longer need manual start/stop) and taught
  `homelab-audit.sh`'s container check to also treat any container labelled
  `sablier.enable=true` as expected-stopped, derived from the Docker label
  rather than a hardcoded name list — a later phase or a new
  Sablier-managed service needs no further edit there. `setup-services.sh`
  now also stages `Dockerfile`/`Caddyfile` (it previously only copied
  `docker-compose.yml`, `.env.example` and shell scripts), and the drift
  check in `homelab-audit.sh` now watches both filenames too.
- Not yet done: phases 2 (Paperless, Nextcloud, Odysseus, Linkwarden,
  Jellyseerr, Bazarr) and 3 (Calibre-Web, Audiobookshelf, Jellyfin), the Kuma
  monitor/pause step (no API — manual), and the physical device tests
  (Jellyfin TV, Audiobookshelf phone app, KOReader OPDS) — tracked in the TODO.

## 2026-09-27 — Standalone ntfy + Paperclip Coach groundwork

- New always-on `services/ntfy/` (port 8095, Tailscale + localhost only,
  persistent auth, `auth-default-access: deny-all`), separate from the
  on-demand ntfy bundled in Odysseus. A `publisher` user (write-only) and a
  `phone` user (read-only) each got their own access token on a private,
  randomly-suffixed topic — tested end-to-end (publish → poll returned the
  message; anonymous publish/read both 403). Glance monitor + bookmark added,
  its network wired into `services/glance/docker-compose.yml`, backup exclude
  added for the live message cache in `rclone-backup.sh` (the auth db itself
  is not excluded). Uptime Kuma monitor is a manual UI step — no
  monitor-creation API exists — noted in the TODO.
- `services/paperclip/docker-compose.yml` now mounts `${HOME}/.training` at
  `/training` (read-write, confirmed writable) for the planned Coach agent's
  persistent memory — same "never put it under `/paperclip`" rule as the
  `/reports` mount, for the same chown-crash reason.
- Verified both `trainingpeaks-mcp` (`:8092/mcp`) and `strava-mcp` (`:8093/mcp`)
  respond to an MCP `initialize` call from *inside* the Paperclip container via
  `host.docker.internal` — the Coach agent's MCP wiring will work once
  connected.
- **Coach company itself is not created** — the admin password moved to
  Vaultwarden (see below) and this batch had no board session. Full recipe
  (company, agent, AGENTS.md addendum, secrets, routine) written up in
  `services/paperclip/README.md`, ready to run once signed in.
- Fixed a stale recipe: the board sign-in snippet in the README still read
  `PAPERCLIP_ADMIN_PASSWORD` from `.env` — that line was removed when the
  password moved to Vaultwarden. It now prompts interactively instead.

## 2026-09-26 — Subscriptions tracker + monthly money reminder

- Private list of subscriptions and prepaid credits (Claude, OpenRouter,
  Anthropic API, domains, Purelymail, R2, TrainingPeaks…) lives in the Obsidian
  vault (`💰 Finance/Subscriptions & Credits.md`), not in this public repo.
- Cron, 1st of each month 10:00 → Discord "💳 Monthly money check": check
  prepaid balances and update that note. Test notification sent.
- Claude Code default model → `opusplan` (Opus plans, Sonnet executes).

## 2026-09-26 — Disk: 18 → 23GiB free (92% → 89%)

**Why:** the weekly audit flagged the internal SSD at 92%. The cleanup only
touched things that regenerate. Anything personal or ambiguous went to the
👤 list under *💾 Disk* in `HOME_SERVER_TODO.md`, with exact commands.

- **Docker (~3.4GB in the VM):** removed 5 images that no container of any
  state used. All belonged to removed services or superseded tags:
  `vaultwarden/server:1.35.4`, `grafana/grafana:11.6.0`,
  `prom/prometheus:v3.2.1`, `prom/node-exporter:v1.9.0` and
  `mealie:v2.6.0`, 2.7GB together. `docker builder prune -af` freed another
  675MB. Each image was checked against `docker ps -a` before removal. Kept on
  purpose, although no container uses them: **Storyteller** (2.77GB,
  on-demand, container removed), `python:3.12-slim` (base for the local MCP
  builds) and `alpine`. `Docker.raw` shrank from 50GB to 47GB once Docker
  Desktop TRIMmed, so no restart was needed.
- **Homebrew** `brew cleanup -s`: 428MB. **npm cache** 2.4GB → 226MB. The pnpm
  store and yarn cache were already empty. **pip cache**: 29MB.
- **`~/logs`:** gzipped the 180 files older than 30 days. Nothing was deleted,
  and the directory went from 47MB to 5.9MB.
- **Left in place on purpose:** the Squirrel/ShipIt staging for Bitwarden,
  Notion and VS Code (2.6GB). Their ShipIt daemons were live with updates
  waiting to install, and deleting that staging mid-install risks a
  half-updated Bitwarden. Quit and reopen those apps first, then delete it (on
  the 👤 list).
- **Measuring gotcha:** on macOS, `df -h /` reports the sealed *system*
  volume (11GiB used, 40%). The number that matters is
  `df -h /System/Volumes/Data`.
- The biggest item not yet cleared is Claude desktop's `vm_bundles` (10GB),
  then Chrome (~9.4GB). Both are the user's call.

---

## 2026-09-26 — On-demand services to free RAM; Paperclip 2g → 3g

**Why:** macOS swap was 7.7 of 8 GB with 34% free and the Docker VM at its
10 GB ceiling; Paperclip had hit its 2 GB cap 12,687 times while idle. Rather
than remove rarely used services (Nextcloud/Paperless keep-or-remove was still
undecided), they are now **stopped by default** and started when needed.

- **On-demand set** (user decision): Paperless-ngx (+db, broker), Nextcloud
  (+db), Stirling PDF, IT-Tools, the Odysseus stack (odysseus, searxng,
  chromadb, ntfy) and **FlareSolverr** — Prowlarr has the FlareSolverr proxy
  on tag `flaresolverr`, but none of the 6 indexers carries that tag, so
  nothing used it. All composes already had `restart: unless-stopped`
  (none `always`), so `docker compose stop` survives Docker/Mac restarts;
  Watchtower skips stopped containers (`WATCHTOWER_INCLUDE_STOPPED=false`).
- **`scripts/utils/ondemand.sh`** (`ondemand` zsh alias): `list`, `start`,
  `stop`, `stop-all`, `containers`. One map in the script is the source of
  truth for the audit and the backup.
- **Measured:** 42 → 30 running containers, `docker stats` total 6.60 →
  **4.37 GiB** (~2.2 GiB freed in the VM). macOS free 34% → 33%, swap 7.7 of
  8.0 → 7.9 of 9.2 GB — **no macOS relief**, because RAM freed inside the VM
  stays with the VM as page cache. Only lowering Docker Desktop's memory
  ceiling returns it (recommended 8 GB, left to the user — needs a Docker
  restart).
- **Paperclip `mem_limit` 2g → 3g**, recreated, healthy (~950MB after start).
  Not 3.5g: that needed ≥45% host free and falling swap.
- **Monitoring:** Glance monitors for the five web services removed (they'd
  sit red); bookmarks moved to an *On demand* group (with Storyteller), and
  the docker-containers widget set to `running-only: true`. Uptime Kuma
  monitors 3, 5, 13, 14, 25 paused (`active=0`, Kuma stopped, backup
  `kuma.db.bak-20260926-ondemand`). `homelab-audit.sh` skips on-demand
  containers → audit green apart from the pre-existing 91% disk warning.
- **Backups:** `backup-databases.sh` now starts a stopped DB container on its
  own (never the app), waits for `pg_isready` / `mariadb-admin ping`, dumps
  and stops it again via an EXIT trap. A missing DB container is now an error,
  not a silent skip. Tested: paperless (482K) and nextcloud (3.6M) dumps
  complete, both DB containers back to Exited. rclone file backups unchanged
  — files at rest also avoid Odysseus's live-SQLite BadDigest.
- **Not changed:** Docker Desktop settings. Resource Saver only engages
  with zero running containers, so it can't help here.

## 2026-09-26 — Paperclip: Gemini CLI dropped, Marketing dept, departments

- **Gemini CLI dropped.** Google ended personal sign-in for the CLI, Vertex
  needs GCP billing, Paperclip has no Gemini connection type and the stored
  API key kept corrupting (hostname-derived encryption). Studio **Researcher**
  and **Growth & Content** moved `gemini_local` → `opencode_local` on
  OpenRouter, model `openrouter/google/gemini-3.5-flash-lite` (newest Gemini
  Flash under $0.50/M input; checked against `openrouter.ai/api/v1/models`
  and `opencode models openrouter`), $3/month hard-stop each. One PATCH each —
  agents with no binding have nothing for the API to restore. The CLI stays
  in the image, unused.
- **Studio Marketing department** (hired paused): Head of Marketing (CMO,
  Claude Sonnet) → Copywriter (Sonnet), Social Media Manager, Community &
  Launch, SEO Specialist (OpenCode `deepseek-v3.2`, $3/month each) + Growth &
  Content moved under the CMO. Every marketing AGENTS.md carries the *draft
  only / never post / no sockpuppets / faceless brand* rule — why: the studio
  is anonymous and agents have no accounts; posting would leak identity or
  break platform rules.
- **Homelab departments:** new Network Engineer (Codex), SRE / Monitoring and
  Privacy & De-Google Advisor (OpenCode, $3/month), Web Engineer for
  peciulevicius.com (Claude Sonnet) — all paused. `reportsTo` regrouped via
  PATCH: Security (Security Engineer → Security Analyst), Infrastructure
  (DevOps/Homelab Engineer → Network, SRE, Storage & Backup), Knowledge and
  Web under the Lead. The Web Engineer has no GitHub token for its repo yet
  (TODO). Studio already had Product/Engineering/Research departments.
- The board resumed the whole Studio roster in the UI the same afternoon;
  heartbeats stay off, so idle agents cost nothing until assigned.

## 2026-09-26 — Paperclip: connections, full org chart, GitHub for Homelab

- **OpenRouter connection** (company-shared API key, installed company-wide)
  in both companies, from `OPENROUTER_API_KEY`. Only `opencode_local` can use
  it (model `openrouter/…`). Cheap defaults: `deepseek-v3.2`, `qwen3-coder`,
  `kimi-k2.5` as step-up. Every OpenRouter agent has a **$3/month** hard-stop
  budget.
- **Gemini:** Paperclip has no Gemini connection type — `gemini_local` uses the
  CLI's own login. That login had silently broken: Gemini CLI encrypts it with
  a key derived from hostname + username, and the container's hostname (its
  ID) changes on every recreate. Compose now pins **`hostname: paperclip`**;
  the key must be entered once more (TODO).
- **Hermes/Pi not usable:** neither CLI is in the image and the image's Python
  has no pip/ensurepip, so Hermes can't be installed without hand-patching
  `./data`. All Hermes roles run on OpenCode + OpenRouter instead.
- **Researcher → Gemini** by hire-replacement (a Claude-bound agent can't be
  PATCHed to a connection-less harness — the old binding is re-attached);
  paused until the Gemini login works. **Storage & Backup Analyst → OpenCode**
  on OpenRouter via PATCH.
- **Full org**, every new agent **paused**, heartbeats off, no agent creation,
  AGENTS.md board section ≤12 lines. Studio adds CTO, Engineering Manager,
  Frontend/Backend/Mobile developers, UI/UX Designer, Security Engineer (PR
  gate), QA (OpenRouter), DevOps, Technical Writer (OpenRouter), Growth &
  Content (Gemini). Homelab adds Security Engineer (PR gate), DevOps/Homelab
  Engineer (Codex) and Docs & TODO Keeper (OpenRouter). Claude models: Opus 5
  for CEO/CTO/Lead, Sonnet 5 for the other Claude roles.
- **GitHub for Homelab:** `GITHUB_TOKEN_HOMELAB` stored as a Paperclip secret
  and bound as `GH_TOKEN` to the two PR-opening agents only; git authenticates
  via `gh auth git-credential`, nothing written to disk. **Why not env
  passthrough:** `env_file` would hand the token to every agent in both
  companies.
- Memory flat: host free 34% → 37%, swap 7.38 → 7.33GB of 8GB; container
  1.08GiB of 2GiB.

## 2026-09-26 — Paperclip companies configured (Homelab + Studio)

- **Homelab** company: mission set, board approval for hires on. Wizard CEO
  renamed **Homelab Lead** (Claude Code); **Security Analyst** (Codex) and
  **Storage & Backup Analyst** (Claude Code) hired and **paused**. Project
  *Weekly Reports*, routine *Homelab weekly report* Sunday 10:00 Vilnius.
- **Reports feed:** new `scripts/utils/paperclip-reports.sh` (cron Sunday
  09:30) writes a read-only snapshot — audit, backup log, containers,
  disk/memory, Kuma statuses, TODO index; no `.env`, redaction backstop — to
  `~/services/paperclip/reports`, mounted `:ro` at `/reports`. **Why a feed and
  not access:** agents with a shell on the host would be one prompt away from
  changing servers; a read-only file makes "report, don't touch" structural.
- First attempt mounted it at `/paperclip/reports:ro` → crash loop: the
  entrypoint `chown -R`s `/paperclip` as root. Moved to `/reports`.
- **Studio** company: mission set. CEO reused (Claude Code); **Product
  Manager** (Codex) and **Researcher** (Claude Code) hired via hire request +
  approval. AGENTS.md sections carry the idea rubric, ruled-out list, stack and
  security rules (≤15 lines each). *Idea Pipeline* is the active project; task
  STU-2 (20 ideas → top 3 with 6-week MVPs) waits in **backlog** so nothing
  runs until the user starts it. *Daily standup* routine created **paused**
  (≈25–35 runs/week).
- All agents: timer heartbeats off. `mem_limit` 1.5GB → **2GB** (idle had
  reached ~1.2GB anon; host free 37%, above the 30% rule).
- Researcher/Storage Analyst stay on Claude Code until an OpenRouter key exists.

## 2026-09-26 — Audit reminds about stale pre-change backups

- `homelab-audit.sh` fails (→ weekly Discord) when a `*.bak-*` / `*.pre-*` file
  under `~/services` is older than 7 days. Those copies (kuma.db, .env, compose)
  are taken before risky edits and were never cleaned up; now they nag.

## 2026-09-26 — Music setup removed (keep Spotify)

Decision: **keep Spotify, drop self-hosted music.** The beets + Jellyfin music
library (deployed the same morning) and Lidarr were removed before any music
was added.

**Why:**
- **There is no owned collection to serve.** Everything listened to is
  streamed; building a library meant buying ~1,700 liked songs album by album
  or downloading them, and neither was going to happen. An empty library plus
  a cron job, a container and a Glance tile is pure upkeep.
- **Spotify isn't Google**, so it doesn't block the de-Googling goal. The
  Google piece is **YouTube Music / YouTube Premium** — that gets cancelled
  instead (👤 TODO).
- The liked-songs list (merged export) is kept **privately in the Obsidian
  vault**, not in this public repo, in case a library is ever worth building.

**Removed:**
- **beets** — container + image, `services/beets/`, `scripts/utils/beets-import.sh`,
  its `*/10` cron line (live crontab reinstalled from `scripts/cron/crontab`
  and diffed), the `*.yaml` config-copy glob in `setup-services.sh` (beets'
  `config.yaml` was its only user), Glance monitor + 2 bookmarks + the `beets`
  network, and Uptime Kuma monitor #27 (monitor, notification link and 224
  heartbeats deleted with Kuma stopped; db backed up first).
- **Lidarr** — container + image, `services/lidarr/`, `setup-services.sh`
  entries, Glance monitor + 3 bookmarks, docs rows, and the **Lidarr
  application in Prowlarr** (Prowlarr now syncs to Sonarr and Radarr only).
  It had 0 artists and an empty queue. It shared the `media` network, which
  stays for the rest of the media stack. No tunnel hostname or Kuma monitor
  existed for it.
- **Jellyfin** — the read-only `music/Library` mount; recreated, healthy,
  Movies (23) and TV (2 series / 40 episodes) intact. A Music library was
  never created (the API key was never provided).
- **Docs** — SERVICES.md (tables, sections, Tailscale list; Finamp marked *not
  used*), HOME_SERVER_REFERENCE.md, services/README.md, NAS.md.

**Left behind:** `/Volumes/media/music/` (116K of beets test leftovers —
`rm -rf` was permission-blocked for Claude) and the staged
`~/services/{beets,lidarr}` dirs. Both are 👤 TODO items.

---

## 2026-09-26 — Paperclip (multi-agent orchestration), Tailscale only

- **Deployed** `ghcr.io/paperclipai/paperclip:2026.916.1` (`services/paperclip/`),
  single container with embedded Postgres, `authenticated/private` mode, port
  3100 bound to `127.0.0.1` + `100.81.171.49` only. First admin created and
  the instance claimed via the browser-claim API, then sign-ups closed
  (`PAPERCLIP_AUTH_DISABLE_SIGN_UP=true`, verified: sign-up now 400, login
  200). Admin credential in `~/services/paperclip/.env` pending Vaultwarden.
- **Why Docker, not native launchd:** the image ships the `claude`, `codex`,
  `gemini` and `opencode` CLIs and the `*_local` adapters run them in-container,
  so reaching the host CLI was never needed. Native would hand agents running
  with `dangerouslySkipPermissions` the whole home directory. Cost: the
  container's Claude Code needs its own login (`claude setup-token` →
  `CLAUDE_CODE_OAUTH_TOKEN`), since the host login is in the Keychain.
- **Why embedded Postgres:** swap was at ~10.3 of 11 GB before deploying; a
  second (Postgres) container was not affordable. 1.5GB `mem_limit`.
- **Memory:** before 34–37% free / swap 10.2–10.3 GB; after 36–38% free / swap
  9.7–10.0 GB, 6.07 GiB containers total. Idle ~800–900MB.
- **Gotcha found:** Glance's first check got **403** — Paperclip rejects
  hostnames not in `PAPERCLIP_ALLOWED_HOSTNAMES`; added `paperclip` and
  `host.docker.internal`.
- Glance monitor + Tailscale Only bookmark + `paperclip` network; Uptime Kuma
  monitor #28 cloned from beets' row (backup `kuma.db.bak-20260926-paperclip`);
  rclone excludes the live DB dir and agent CLI logins, keeps Paperclip's
  daily dumps and `master.key`. Watchtower disabled (migrations on upgrade).
- No agents or API keys configured — see `services/paperclip/README.md`.

## 2026-09-26 — Music library: beets + NAS folders (no downloader)

- **Folders:** `/Volumes/media/music/Incoming/` and `Library/` on the NAS
  media share. Containers see them as `777`, same as `movies/` and `tv/`.
- **beets** (`lscr.io/linuxserver/beets:2.14.1-ls354`, `services/beets/`):
  mounts `/Volumes/media/music` at `/music`; `import: move/write/quiet`,
  `quiet_fallback: asis`; plugins musicbrainz, fetchart, embedart, lastgenre,
  scrub, duplicates, web. Web UI on 8337, Tailscale only; Glance monitor +
  bookmarks (Home → Tailscale Only, Media → Manage) and an Uptime Kuma
  monitor (cloned from CouchDB's in `kuma.db`, same notifications; backup
  `kuma.db.bak-20260926-beets`). ~50MB RAM.
- **Import trigger:** `scripts/utils/beets-import.sh`, cron `*/10` through
  `run-with-notify.sh`. **Why cron:** inotify never fires on SMB. It waits
  for `Incoming/` to be quiet for 2 min (half-copied albums) and takes a
  lock (long imports).
- **Deliberately no downloader** — no Lidarr/slskd/indexers. Music is bought
  DRM-free (Bandcamp, Qobuz, iTunes) and dropped in by hand.
- **Config lives in the repo** as `services/beets/config.yaml`, bind-mounted
  over `/config/config.yaml`, because `services/**/data/` is gitignored.
  `setup-services.sh` now also copies `*.yaml`. Found: Docker Desktop fails
  the first `up` of a file mount nested inside another bind mount
  (`outside of rootfs`) until the mountpoint file exists — README says to
  `touch` it.
- **Jellyfin:** `music/Library` mounted read-only at `/media/music` (beets
  owns tags and layout). The Music *library* itself is not created yet —
  no Jellyfin API key saved; TODO.
- **Tested:** a 2-second silent MP3 generated with ffmpeg in the beets
  container (tagged artist/album) → `Incoming/` → script → imported as-is
  into `Library/Zzbeetstest Artist/Zzsilent Album/01 Silence.mp3`, source
  folder pruned. Also ran through `run-with-notify.sh` on an empty
  `Incoming/` (clean exit 0). Test data removed from beets; the deleted file
  lingers as an `.smbdelete*` ghost held by Docker Desktop's VM (TODO).
- Backups: `~/services/beets/` is already in the nightly R2 sync — no
  `rclone-backup.sh` change.

## 2026-09-26 — Liked-songs list merged (private, in the vault)

- Spotify liked songs (Exportify CSV) + YouTube Music library (Takeout) +
  Spotify "Linkin Park Best of" merged and de-duplicated → 1,673 songs, 929+
  artists, stored in the Obsidian vault (`🙋 Personal/Music/`), not in this
  public repo. Used as the buying list for the Jellyfin music library.

## 2026-09-26 — Transmission behind a Tailscale sidecar (Mullvad-ready)

- New `transmission-ts` container (`tailscale/tailscale:v1.102.5`, kernel mode,
  own tailnet node). `transmission` now uses
  `network_mode: service:transmission-ts`; the sidecar publishes 9091 and
  51413/tcp+udp and carries the `transmission` alias on `media`, so
  Sonarr/Radarr/LazyLibrarian needed no changes.
- **Why:** route torrent traffic through a Mullvad exit node via the Tailscale
  Mullvad add-on (one account for phone + container, no WireGuard keys in
  `.env`) — replaces the Gluetun plan. Add-on not bought yet; exit-node line is
  prepared but commented in the compose file.
- Verified: node logs in and survives a recreate with the auth key blanked
  (`TS_AUTH_ONCE`, state in `data/tailscale`); web UI 200 with login on
  localhost, Mac mini Tailscale IP and the sidecar's own IP; Sonarr + Radarr
  `downloadclient/testall` valid; Prowlarr healthy (no download clients of its
  own); egress still the home IP as expected; 51413 still published; with the
  sidecar stopped Transmission has no network at all (no fallback leak).
- Glance: added a Transmission **monitor** (`http://transmission:9091/transmission/web/`,
  401 = up) — it only had bookmarks before, so the alias is now watched.
- Found: if the sidecar restarts alone, Transmission keeps a dead netns;
  `docker restart transmission` fixes it (`compose up -d` doesn't). Documented.
- Kill-switch claim checked against Tailscale docs: fail-close is only
  documented for expired exit-node keys, not an offline exit node, and
  tailscale/tailscale#19781 reports fallback — so it's a TODO test, not an
  assumption. Backup of the old setup: `~/backups/transmission-2026-09-26/`.

## 2026-09-26 — First external-drive backups (T5 + T7)

- `backup-external.sh` run to both drives: Immich originals + encoded video,
  DB dumps, audiobooks, Calibre books. Stamps written; `homelab-audit.sh` now
  reports all checks passed. Repeat ~monthly (audit warns at 30 days); T5 still
  to go offsite.
- `.gitignore`: `pkm/config.py*` so backups of the credentials file (the
  mail-switch left one in the repo, holding the revoked Gmail password — moved
  to `~/backups/pkm/`) can never be committed.

## 2026-09-26 — GDPR data-request tool

- New `scripts/utils/gdpr-export.mjs`: dependency-free Node script that exports
  (`export <email>`) or deletes (`delete <email>`, dry run unless `--yes`) one
  person's data in a Supabase project, driven by a per-project
  `gdpr.config.json`. Writes nothing / refuses when the address matches nothing.
  Canonical copy here; vendored into `peciulevicius.com` as `npm run gdpr:*`.
  Usage, config format and the GDPR obligations it supports:
  [UTILITY_SCRIPTS.md](UTILITY_SCRIPTS.md#gdpr-exportmjs).

## 2026-09-26 — Removed one-time scripts

Scripts whose job is finished for good, deleted so the repo only holds tools
that still run. Recover any of them with `git log --all -- <path>` and
`git show <commit>^:<path>`.

- `scripts/utils/mail-switch-purelymail.sh` — moved kindle_sync IMAP and Uptime
  Kuma SMTP from Gmail to Purelymail; done 2026-09-26, Gmail app password
  since revoked.
- `scripts/utils/migrate-calibre-to-ssd.sh` — moved the Calibre library from
  `/Volumes/books` to `~/services/calibre/library`; done 2026-09-25. Its
  rollback loop now lives in the Calibre item of `HOME_SERVER_TODO.md` until
  the NAS copy is deleted (~2026-10-02); that deletion is manual (UGOS) and
  never needed the script.
- `services/rclone/migrate-b2-to-r2.sh` — Backblaze B2 → Cloudflare R2
  backup migration; done 2026-04-22, `RCLONE_REMOTE=r2` since.

## 2026-09-26 — 2FA off Google Authenticator; Gmail app password revoked; Pi-hole via Tailscale

- All TOTP codes moved to **Bitwarden Authenticator** (the top de-Google risk:
  seeds no longer sync to the Google account being left). Ente Auth kept as a
  possible second copy later.
- Gmail app password revoked — nothing uses it since the Purelymail switch.
- Tailscale admin → DNS: nameserver `100.81.171.49` (Pi-hole) with **Override
  local DNS** → Pi-hole ad blocking on every Tailscale device, any network.

## 2026-09-26 — TODO truth pass

Every open item in `HOME_SERVER_TODO.md` re-checked against the live system.
Finished and not yet recorded elsewhere:

- **Calibre-Web profile email is `dziugas@peciulevicius.com`** (checked in
  `app.db`), so its *Send test email* lands in the Purelymail inbox.
- **kindle_sync runs against `imap.purelymail.com`** from the 10:00 cron run
  onwards (log).
- **Branded email signature page is live** at
  `peciulevicius.com/email/signature/` (200 on the Worker).
- **Tailscale's `localhost` node identified** — it is the iPhone
  (`iphone13mini`; iOS reports its hostname as `localhost`).
- Stale lines fixed: the Pi-hole "pinned at 2024.07.0" warning (v6 since
  2026-09-25), the mail-switch step references, the website's "PR #46 /
  supabase login / apply v1.5.0" lines, janioniu's "Astro 7 still open".
- Not done, still open (checked): T7 stamp missing, `autorestartatconnect`
  unset, MacBook Tailscale key expired, `~/services/{mealie,grafana}` and
  `~/credentials-import.md` still present, LazyLibrarian still 1 book "Have".
  Tailscale DNS: the tailnet resolver already shows `100.81.171.49`, so the
  nameserver looks added — Override-local-DNS + cellular test left open.

## 2026-09-26 — Mail consumers off Gmail; Calibre-Web password rotated

- `mail-switch-purelymail.sh`: kindle_sync IMAP and Kuma SMTP → Purelymail
  (`dziugas@`), verified (kindle_sync dry-run connects to imap.purelymail.com).
  Calibre-Web SMTP → Purelymail by hand (password encrypted in app.db).
- Calibre-Web login password regenerated and stored in Vaultwarden (credential
  migration: 5 of ~18 done).
- Gotcha: Calibre-Web's test mail goes to the *profile* email, not the sender;
  and Amazon must approve the new sender address for Send-to-Kindle.

## 2026-09-26 — peciulevicius.com on the Worker; Supabase migrations applied

- Domain moved from Pages to the Worker (user). Supabase CLI linked from the
  Mac mini via `supabase login` (browser) — `supabase link` uses a temporary
  login role, so **no DB password is stored anywhere**. v1.5.0 (RLS lockdown,
  server-only RPCs, `newsletter_sends`) + v1.6.0 (drop dead realtime/comment
  tables) applied with `supabase db push`; verified live. Details in the
  website repo's `docs/DONE.md` and `supabase/README.md`.

## 2026-09-26 — Calibre backup confirmed from the SSD path

- The 05:00 R2 backup read `~/services/calibre/library` (not the NAS) and
  completed ("Calibre books backup complete"), as did Immich originals and
  `~/.training`.

## 2026-09-26 — Jellyseerr: Radarr/Sonarr marked as default servers

- Both were `isDefault: false`, so approved requests had no default target and
  could silently not reach Radarr/Sonarr. Set to default via the Jellyseerr
  settings API (found during the overnight Radarr 6 upgrade check).

## 2026-09-26 — Overnight major image upgrades (Stirling PDF, Prowlarr, Radarr)

One at a time, each verified before the next. Before each: container stopped,
config dir tarred and old image digest recorded in
`~/backups/<svc>-2026-09-26/` (not in the repo). Old images removed only after
the new one passed.

- **Stirling PDF `frooodle/s-pdf:0.46.2` → `stirlingtools/stirling-pdf:2.14.3`.**
  Took 2.14.3, not 3.0.0 — 3.0.0 was released 2026-09-24, two days earlier.
  Breaking change that mattered: 1.x+ enables login by default
  (`admin`/`stirling`) and ignores the old `DOCKER_ENABLE_SECURITY` — replaced
  with `SECURITY_ENABLELOGIN=false`, otherwise the public `pdf.` hostname would
  have served a login page with a published default password. Existing
  `settings.yml` was read as-is (`enableLogin: false`). Verified: status
  `2.14.3 UP`, a two-page merge through `/api/v1/general/merge-pdfs` (PDFKit
  confirms 2 pages, text `Page A|Page B`), `pdf.peciulevicius.com` 200 without
  login, Glance's `check-url` (`http://stirling_pdf:8080/`) 200 from inside the
  Glance container, container `healthy`. Memory after start ~1.3GB (was ~360MB
  on 0.46) — watch it.
- **Prowlarr `1.37.0` → `2.6.5`** (linuxserver). 2.0 = .NET 8 and removal of
  Basic auth (falls back to Forms) — no impact, all three *arr apps already
  use Forms. DB migrated forward on first start (to schema 43+). Verified:
  API reports `2.6.5.5623` on .NET 8.0.27, all 6 indexers still listed and
  enabled, `/api/v1/indexer/testall` 6/6 valid, `/api/v1/applications/testall`
  Sonarr + Radarr both valid, health list empty (the only prior entry was
  "update available").
- **Radarr `5.28.0` → `6.4.4`** (linuxserver). 6.0 = .NET 8, Basic auth
  removed (Forms already in use), movie-file tokens no longer allowed in the
  *folder* format (ours is `{Movie Title} ({Release Year})` — unaffected),
  and new quality profiles default to "Original" language (existing six
  profiles keep English). Queue was empty at upgrade time. Verified: API
  reports `6.4.4.10685` on .NET 8.0.27, movies 30 / with file 23 — identical
  before and after, Transmission download-client test valid, root folder
  `/media/movies` accessible, 4 indexers still synced, Prowlarr → Radarr app
  test valid, Jellyseerr's saved Radarr connection re-tested through
  `/api/v1/settings/radarr/test` (6 profiles, root `/media/movies`), health
  empty.

## 2026-09-25 — Pi-hole blocklists; website PR sweeps

- Pi-hole: HaGeZi Multi Pro + TIF medium added (1.18M domains), common
  services spot-checked. Tailscale DNS override still a 👤 step.
- peciulevicius.com: PRs #47 (v1.6.0 cleanup migration file, fixes), #48
  (drop Google Fonts), #49 (/privacy page, corrected) merged → v1.11.1. #46
  rebased, waits for the Pages → Worker move.
- janioniuvynuogynas.lt: #4 ImgBot, #7 launch prep, #9 Astro 7 + adapter 14
  (audit 8 → 0 prod advisories), #10 semantic-release (first release v1.0.0)
  merged. Found and fixed: production contact/waitlist forms returned 500 —
  secrets only reached the build, never the Worker; deploy.yml now syncs
  runtime secrets. Stale remote branches deleted.

## 2026-09-25 — Phone apps: server side ready

- FreshRSS API access enabled (`cli/reconfigure.php --api-enabled`) for Reeder.
- Checked reachability for the apps' APIs: FreshRSS greader, Paperless,
  Linkwarden (v2.16), Pi-hole v6 auth (Pi-hole Remote needs v6 — now met).
- Per-app connection table added to `SERVICES.md`; Amperfy dropped (it speaks
  Subsonic/Ampache, not Jellyfin — Finamp is the Jellyfin client).

## 2026-09-25 — TODO clean-up: finished items

Every ticked, struck-through or "done" line was deleted from
`HOME_SERVER_TODO.md` so it holds only open work. Most were already recorded in
the entries below; these were not:

- **janioniuvynuogynas.lt live** — nameservers moved from Hostinger to
  Cloudflare, apex + `www` on the Worker, Turnstile keys + `SITE_URL` set, PR #5
  merged; PR #6 (merged same day) fixed unknown paths returning 500 instead of
  404 and redirected `www` (and the `lt` variants) to the apex.
- **`.gitleaksignore`** now carries the rotated Kuma push token's fingerprint,
  so full-history scans stop flagging it.
- **Cloudflare account** (login + 2FA, API token) added to
  `CREDENTIAL_MIGRATION.md` — it was only tracked as the tunnel credentials file.
- Coach docs (SERVICES.md AI Coach table, Glance monitors, both READMEs)
  verified current.

## 2026-09-25 — TrainingPeaks MCP reachable from claude.ai

- New automation token (`~/.config/homelab/cloudflare.env`, account-wide:
  Zone/DNS/Workers/Turnstile/Email Routing/Access/Tunnel) replaced the DNS-only one.
- Access app "TrainingPeaks MCP" with Managed OAuth for claude.ai, then DNS +
  tunnel ingress `tp-mcp.peciulevicius.com` → `:8092`. Unauthenticated `/mcp`
  → 401; OAuth discovery endpoints answer. Details in the service README.

## 2026-09-25 — Monitoring tidy-up

- Uptime Kuma: deleted the removed Mealie's monitor; added **Odysseus**
  (`host.docker.internal:7001`) and **CouchDB** (`:5984/_up`) monitors, cloned
  from the Kuma self-check so they share its Discord + SMTP notifications
  (done in `kuma.db` with the container stopped, backup kept). Both up.
- Prowlarr: removed the stale Readarr application (Readarr was removed 2026-09-19).
- `~/services/glance/.env` (now holds the Pi-hole password) → chmod 600.

## 2026-09-25 — Odysseus RAG over the Obsidian vault

- Vault mounted read-only into `personal_docs/obsidian` (host override file),
  indexed 57 chunks; search returns Training Log, Gear & Nutrition, HOME.
  Details + re-index command in `services/odysseus/README.md`.
- User accepted that snippets go to cloud models when those are used.

## 2026-09-25 — TODO truth pass: verified, ticked, collapsed

Every open item in `HOME_SERVER_TODO.md` was checked against the live system
(read-only: `docker ps`, `crontab -l`, `tailscale status`, `pmset`, `dig`,
SQLite reads of Kuma/Calibre-Web/Odysseus config, file existence under
`~/.config/homelab` — no secret values read). The TODO went 1,428 → ~1,070
lines, with a 👤 / Claude "Who does what" index under *Next up*. Done or
superseded, and moved out:

- **Purelymail** bought; `peciulevicius.com` + the `dziugas@` mailbox live;
  MX/SPF/DKIM/DMARC/BIMI all on Purelymail (`dig MX` →
  `mailserver.purelymail.com`); Cloudflare Email Routing disabled. Old steps
  superseded: "Email Routing → forward to Gmail", "pick Purelymail vs Migadu",
  the signup gotcha (kept in `guides/EMAIL.md`).
- **Healthchecks.io dead-man's switch live** — `heartbeat.env` in place, `*/5`
  cron, log silent (errors only) since 08:30.
- **Kuma "Rclone Backup" push token rotated** (`kuma-reset-push-token.sh`);
  the leaked one is dead. Its `.gitleaksignore` fingerprint is still open.
- **Odysseus**: cloud models (default Opus 5.5, task/utility Haiku 4.5,
  Anthropic endpoint) replace the `qwen2.5:7b` / `llama3.2:3b` default plan;
  the Anthropic-key question is settled (in use). **IMAP/SMTP account for
  `dziugas@` on Purelymail configured 2026-09-25** (993 implicit TLS, 465
  SSL). Homelab + coaching skills and memories imported. Dropped as
  superseded: `ai.peciulevicius.com` (Tailscale-only by decision), the
  Phase-1 compose/port-7000 plan, Cookbook, `qwen3:8b`.
- **Tailscale key expiry disabled** on `macmini` and `ugreen-nas` (no expiry
  in `tailscale status`). Found instead: the MacBook Air's key expired
  2026-09-02 — now a TODO.
- **NAS SSH enabled** (port 22 answers).
- **Disk**: Trash (2.7GB) and `~/Downloads` (1.1GB) emptied; 32GiB free (84%).
- **Karakeep ×3 and actual-budget** containers are gone; the Storyteller
  container is removed too (compose kept, `restart: "no"`).
- **Kindle sync** verified running hourly (still on Gmail until the switch).
- **Plaintext vault exports** (2026-09-21 scare) — deleted same day,
  `~/Downloads` has no `bitwarden_export*`.
- **Mac mini auto-login** dropped: FileVault stays on (2026-09-22 decision),
  so auto-login isn't possible.

Also collapsed the duplicates (Google Authenticator ×3, the credential pass
×3, Odysseus ×4, LiveSync ×2, Disk ×2, power-outage ×2, Kindle OTA/Searchable
PDF ×2) into one section each. Removed the 2026-09-21 "nothing in the stack
uses email" audit note, because it was wrong: three consumers use Gmail.

## 2026-09-25 — Calibre library moved off SMB onto the internal SSD

- Ran `scripts/utils/migrate-calibre-to-ssd.sh` (dry run, then `--apply`):
  `/Volumes/books` → `~/services/calibre/library`, 1.08GB. Checksum pass
  clean, `PRAGMA integrity_check` ok on both copies, `BOOKS_DIR` switched in
  the calibre / calibre-web / lazylibrarian `.env`s (old ones kept as
  `.env.pre-ssd-migration` — rollback is in the script header). The 6
  `.smbdelete*` orphans were left behind by design.
- Why: `metadata.db` is SQLite, and SQLite on SMB was the root cause of every
  Calibre-Web failure (disk I/O error, busy renames, `.smbdelete` copies,
  "malformed" from a stale mount).
- Verified: 38 books / 72 formats / 147 files before and after; all three
  containers mount `/books` from the SSD; Calibre-Web login +
  `books.peciulevicius.com` 200 with no DB errors in its log, OPDS answers
  (401 Basic — needs the user's login, so the KOReader check is still
  manual); LazyLibrarian `ebook_dir=/books` unchanged, writable, "Database
  check found 0 errors".
- Backups needed no change: the staged `rclone-backup.sh` was already current
  (reads `BOOKS_DIR` from calibre's `.env`, excludes `calibre/library/**` from
  the services set so it isn't uploaded twice).
- `/Volumes/books` stays on the NAS as the rollback until ~2026-10-02.

## 2026-09-25 — Pinned image bumps (same-major only)

One service at a time; compose + image digest saved to
`~/backups/<svc>-2026-09-25/` before each, so rollback is the old tag.

- **it-tools** `2023.11.2-7d94e11` → `2024.10.22-7ca5933` (latest upstream;
  stateless). Home, a deep link and `tools.peciulevicius.com` all 200.
- **CouchDB** `3.5.0` → `3.5.2` (patch). `/_up` ok, server reports 3.5.2,
  `obsidian` DB present, `couchdb.peciulevicius.com` 200.
- **Calibre-Web** `0.6.24` → `0.6.27` (patch). Login + `books.peciulevicius.com`
  200, OPDS answers 401 Basic (auth required, as before), container reads 38
  books from `/books/metadata.db`. The `xdg-desktop-menu` traceback in the
  log is the universal-calibre mod and harmless.
- **Bazarr** `1.5.1` → `1.6.1` (minor). API reports 1.6.1, health list empty,
  no errors in the log.
- **Jellyfin** `10.10.6` → `10.10.7` (last 10.10 patch). Healthy, `/System/Info/Public`
  reports 10.10.7, `watch.peciulevicius.com/health` 200. **10.11 deliberately
  not taken** — it migrates the library DB to EF Core one-way; plan in the TODO.
- **Uptime Kuma** `1.23.16` → `1.23.17` (last 1.x patch). Healthy, local +
  `status.peciulevicius.com` 200, all monitors beating again after restart
  (only the stale **Mealie** monitor is down — Mealie was removed; delete that
  monitor). **2.x deliberately not taken** — one-way DB migration; plan in TODO.
- **Syncthing** `1.29.6` → `1.30.0` (last 1.x). Healthy, REST reports v1.30.0,
  the one folder is `idle` with 45 files and 0 errors (both peers were
  offline before and after — not caused by the bump). **2.x not taken** — it
  replaces the LevelDB index with SQLite (one-way); plan in TODO.
- **Transmission** `4.0.6` → `4.1.3` (minor). RPC up (401 unauthenticated as
  expected); Radarr's and Sonarr's download-client tests both pass — the
  consumer-side check that matters here.
- **Sonarr** `4.0.14` → `4.0.20` (patch). API reports 4.0.20.3014; the only
  health item before ("new update available") is gone, none new.
- **Radarr** `5.18.4` → `5.28.0` (last 5.x). API reports 5.28.0.10274; only
  health item is the v6 update notice. **6.x not taken** (major).
- **Prowlarr** `1.31.2` → `1.37.0` (last 1.x). API reports 1.37.0.5076; app
  sync tests pass for Sonarr + Radarr. The third app, **Readarr**, fails — it
  was removed 2026-09-19 and is still configured in Prowlarr (was already
  failing before the bump); delete it there. **2.x not taken** (major).
- **Jellyseerr** `2.5.0` → `2.7.3` (minor). `/api/v1/status` reports 2.7.3,
  still initialized against Jellyfin, settings migrations applied cleanly, no
  errors; reachable over Tailscale. (Upstream has since merged into
  *Seerr* — a rename to track, not done here.)
- **FreshRSS** `1.24.3` → `1.30.0` (minor). constants.php reports 1.30.0, local +
  `rss.peciulevicius.com` 200, user and its one feed intact (no feed errors).
  A manual `actualize-user.php` prints "failed!" — that only means 0 feeds
  were due (the script exits non-zero when nothing updated), not an error.
- **Audiobookshelf** `2.17.7` → `2.36.1` (minor, same major). `/status` reports
  2.36.1; six schema migrations (2.19.1 → 2.35.0) all logged UPGRADE END;
  library items / books / users / progress identical before and after
  (31/31/1/2); `listen.peciulevicius.com` 200. ⚠️ 2.26 introduced the new
  refresh-token auth — if the mobile app shows logged out, just sign in
  again. Migrations are forward-only: rollback = restore
  `~/backups/audiobookshelf-2026-09-25/data.tgz` + old tag, not just the tag.
- **Stirling PDF** `0.36.5` → `0.46.2` (last 0.x). `/api/v1/info/status` UP
  0.46.2, `pdf.peciulevicius.com` 200, a real merge of two test PDFs via the
  API returned a valid PDF. **1.x/2.x/3.x not taken** — major rewrites
  (new image name, login/DB changes).
- **Linkwarden** `v2.9.3` → `v2.16.3` (minor). `pg_dump` taken first
  (`~/backups/linkwarden-2026-09-25/linkwarden.pgdump`) — the Prisma
  migrations are forward-only, so rollback is restore-the-dump + old tag.
  41 migrations applied ("All migrations have been successfully applied"),
  healthy, links/collections/users identical before and after (619/54/1),
  local + `links.peciulevicius.com` 200. Postgres stays 16.
- **Paperless-ngx** `2.14.7` → `2.20.15` (last 2.x). `pg_dump` first
  (`~/backups/paperless-ngx-2026-09-25/paperless.pgdump`); Django migrations
  all applied (0 unapplied), healthy, documents/tags/users identical
  (14/1/3), local + `papers.peciulevicius.com` 200. `document_sanity_checker`
  reports only INFO-level "no OCR data" on image-only docs (pre-existing).
  **3.x not taken** (major) — and Paperless is still a keep/remove decision.

## 2026-09-25 — Pi-hole 2024.07.0 → v6 (2026.09.0)

- Highest-priority pin: over a year old, public at `pihole.peciulevicius.com`.
  Now Core 6.4.3 / Web 6.6 / FTL 6.7.1.
- v6 env vars: `WEBPASSWORD` → `FTLCONF_webserver_api_password`, `PIHOLE_DNS_`
  → `FTLCONF_dns_upstreams`, `FTLCONF_LOCAL_IPV4` removed, plus
  `FTLCONF_dns_listeningMode: ALL` (bridge network). `.env` keys unchanged —
  compose maps the existing `PIHOLE_PASSWORD`/`UPSTREAM_DNS` to the new names.
- The lighttpd `99-redirect.conf` mount was dropped (no lighttpd in v6).
- Automatic migration: setupVars/pihole-FTL.conf → `pihole.toml`, gravity DB
  v15 → v20, FTL DB v12 → v19; old files in `migration_backup_v6/`. One-way —
  rollback is the pre-upgrade tarball in `~/backups/pihole-2026-09-25/` + the
  old image (digest recorded there).
- Glance's DNS widget broke by design (v5 token API is gone): now
  `service: pihole-v6` + `PIHOLE_PASSWORD` in Glance's `.env`; the stale
  `PIHOLE_API_KEY` was removed. Glance's monitor `check-url` → `/admin/`,
  because v6 answers `/` with 403.
- Verified: container healthy; `dig @127.0.0.1` resolves; `/admin/` 200
  locally and through the tunnel; `/api/auth` accepts the password; upstreams
  1.1.1.1/1.0.0.1 and 76k gravity domains carried over; Glance widget shows
  live query counts. Uptime Kuma already checked `/admin/`.

## 2026-09-25 — Global gitignore fixes; website clean-up PR

- `config/git/.gitignore_global` no longer ignores `lib/`, `var/` or `*.sql`
  globally: they silently dropped new `src/lib/*` files and Supabase migrations
  from commits in every JS/Supabase repo (found by the website agents, who had
  to `git add -f`). Dumps (`*.dump`, `dump.sql`, …) are still ignored.
- peciulevicius.com PR #45 (PostHog removed, own newsletter finished, realtime
  and RLS hardened) and a follow-up Astro 7 / Tailwind 4 PR — backlog in that
  repo's `docs/TODO.md`.
- Kindle Scribe exports now go to `kindle@peciulevicius.com`; format must be
  *Convert to text* + *Attach searchable PDF* (NOTES.md).

## 2026-09-25 — Odysseus model fixes; mail-switch script in repo

- Diagnosed qwen2.5:7b failing with TP/Strava: Ollama's default ~4k context
  truncates the 13–19k-token coach prompt. Decision: coach runs on cloud
  models. Details in `services/odysseus/README.md`.
- Task/utility model `claude-sonnet-5` → `claude-haiku-4-5-20251001`: Sonnet 5
  rejects `temperature`, which Odysseus only strips for Opus; auto-titles had
  failed 35× since the switch.
- `scripts/utils/mail-switch-purelymail.sh` (kindle_sync + Kuma SMTP →
  Purelymail) moved into the repo so the TODO step doesn't point at a temp dir.

## 2026-09-25 — Strava MCP working, connected to Odysseus

- Auth wizard done by the user; token file chmod 600.
- Every tool failed with `'coroutine' object has no attribute 'get_athlete'`:
  upstream asks for `fastmcp>=2.12.4`, pip picked 4.0.8, where
  `ctx.get_state()` is async. Build now pins `fastmcp>=2.12.4,<3` (got
  2.14.7); `query_activities` returns real runs/rides.
- Added to Odysseus (`http://host.docker.internal:8093/mcp`) → 11 tools.

## 2026-09-25 — TrainingPeaks connected to Claude Code and Odysseus

- Cookie saved via the clipboard command (1797 chars — the reason `read -s`
  hung). `tp_auth_status` valid; `tp_get_metrics` returns Garmin-uploaded HRV,
  sleep stages etc., confirming no Garmin connector is needed.
- `claude mcp add --scope user --transport http trainingpeaks http://127.0.0.1:8092/mcp`.
- Odysseus: `~/.training:/training` bind mount + `tool_path_extra_roots`,
  TrainingPeaks MCP row (`http://host.docker.internal:8092/mcp`); restart
  showed 85 tools connected and skills stayed at 4 (duplicate-adoption bug
  stays fixed).
- **Fixed a latent override bug**: `ports: []` never removed SearXNG's 8080
  mapping (compose merges lists); the recreate failed on *port is already
  allocated* and Odysseus sat in `Created` for ~2 min. Now `ports: !reset []`.
  Documented in `services/odysseus/README.md`.

## 2026-09-25 — Purelymail DNS in, Kuma token script, TP cookie paste fix

- **Email DNS** added via the Cloudflare API (token in
  `~/.config/homelab/cloudflare.env`): Purelymail ownership TXT, SPF
  *replaced* (Cloudflare's include removed), 3× DKIM CNAME, DMARC CNAME,
  autoconfig CNAME, autodiscover SRV. Resend's `send.` records untouched.
  **MX not swapped yet** — Email Routing blocks every MX write and the token
  can't disable it; needs one dashboard click. Details in `guides/EMAIL.md` §5.
- **`scripts/utils/kuma-reset-push-token.sh`** — Kuma 1.23's edit form has no
  Reset Token button (the docs we'd written assumed one). The script rotates
  a push monitor's token in `kuma.db` with the container stopped, rewrites the
  consumer's `.env` and sends a test push, without printing the token.
- **TrainingPeaks cookie** — the `read -rs` command hung on Enter: macOS
  Terminal's 1024-byte line cap is shorter than the cookie. README now reads
  it from the clipboard with `pbpaste` and clears the clipboard after.

## 2026-09-25 — All Claude skills in one place

The three homelab skills (`homelab-service`, `credential-rotation`,
`homelab-audit`) moved from the repo's `.claude/skills/` into
`config/claude/skills/`, next to the other 33. Having skills in two places was
confusing, and the "project-only" scoping bought nothing — those skills only
trigger on homelab work, so they're harmless in other projects. The repo's
`.claude/` now holds only its `CLAUDE.md` (plus the gitignored
`settings.local.json`). `setup-claude.sh update` relinked them; all docs that
pointed at the old path are updated.

## 2026-09-25 — AI coach stack built (auth pending)

- **`adaptive-endurance-coach` skill** (MIT, vendored) in Claude Code
  (`config/claude/skills/`) and Odysseus (`data/skills/coaching/`, single
  top-level SKILL.md — no nested copies). Adds a "This setup" section mapping
  tool names between Claude Code and Odysseus. Shared athlete memory in
  `~/.training/`, backed up to R2 as **Backup 6**.
- **`trainingpeaks-mcp`** (upstream v3.2.0, 85 tools) on `127.0.0.1:8092`
  behind `mcp-proxy` (upstream is stdio-only; `mcp-proxy` lives in its own
  venv because it breaks on the newer `mcp` library tp-mcp needs). Verified
  reachable from Odysseus's own MCP client. `tp_get_metrics` returns TP's
  daily metrics unfiltered, so Garmin's pushed health + body-comp data comes
  through — **no Garmin connector needed**. Unofficial cookie auth; the cookie
  is full-account access and expires every few weeks (refresh steps in its
  README).
- **`strava-mcp`** (eddmann) on `127.0.0.1:8093` for Odysseus — Claude Code
  keeps using the claude.ai connector. OAuth tokens in `data/.strava-mcp.env`,
  excluded from R2 (it isn't named `.env`, so it would have been uploaded).
- Both localhost-only (never Tailscale/tunnel), on Glance, in
  `setup-services.sh` and SERVICES.md.
- `rclone-backup.sh` fallbacks fixed (`b2-backup` → `r2`,
  `peciulevicius-services-backup` → `peciulevicius-backups`).
- Waiting on the user: Garmin→TP Daily Health Stats toggle, the TP cookie,
  a Strava API app + one OAuth run. Then one Odysseus restart for the
  `~/.training` bind mount + `tool_path_extra_roots`, and the two MCP servers
  added in its UI.

## 2026-09-24 — Pinned images get a quarterly review

`scripts/utils/check-image-updates.py` reads each pinned tag from
`services/*/docker-compose.yml`, lists the registry's tags (Docker Hub, GHCR —
`lscr.io` resolves there — and GitLab) and reports the newest release of the
same shape (`16-alpine` only against `NN-alpine`; date-style versions only
against date-style), classed patch/minor/major, with database majors flagged
as data migrations. Legacy tags that merely look newer (LinuxServer's
Calibre-Web once carried Calibre's 5.x versions) are excluded per image.
Report-only; a quarterly cron job posts the list to Discord. Kept out of the
weekly audit on purpose: with most pins behind at any given time it would be
permanently red, and a check that is always red gets ignored.

## 2026-09-24 — cleanup.sh no longer prunes the homelab's stopped services

`scripts/cleanup.sh` ran `docker container prune`, `image prune -a` and
`volume prune` on every host. On the Mac mini that deletes Storyteller (stopped
by design, `restart: "no"`) and its 2.77GB image, and any volume not attached
to a running container — the exact commands HOME_SERVER_TODO.md says never to run
there. It now detects the homelab host (compose files in `~/services`) and
only removes the build cache and dangling images; `DOCKER_FULL_PRUNE=1`
restores the full prune.

## 2026-09-24 — Cloud PRs triaged: #34/#35 merged, #36/#40 closed with cherry-picks

A cloud Claude session opened six PRs. Each was reviewed against the live
system before anything landed.

- **#35 (CI: gitleaks, shellcheck, strict docs build)** — merged as-is after a
  rebase.
- **#34 (backup reliability)** — merged after two fixes: the cron label
  (`"SMB rescan"` vs live `"SMB library rescan"`, which would have failed the
  new crontab-diff audit weekly) and the restore/verify fallback bucket (the
  non-existent `peciulevicius-services-backup`, only used when `.env` is
  missing — i.e. exactly a disaster rebuild). Live crontab reinstalled from the
  repo (now identical, 7 jobs). First `r2-verify.sh` run: all five sets
  restored a byte-identical file.
- **#36 / #40 (docs "professional rewrite")** — closed. Their tone rewrites
  halved BOOKS/KINDLE_SETUP/DEGOOGLE and deleted settled decisions ("can't
  wipe the Scribe", the capture-friction diagnosis, "don't re-research",
  the why/caught lines), and #40's SERVICES.md rewrite dropped post-deploy
  wiring, access rationale and the Mobile Apps section. **Kept by
  cherry-pick:** the privacy scrub (NAS serial, router MAC, remote-access URL,
  Send-to-Kindle address, employer/colleague/bank/family names, DRM tooling;
  `settings.local.json` untracked everywhere), the changelog redaction, and the
  UTILITY_SCRIPTS refresh.
- **Hand-applied** the other real fixes from those PRs: Mealie hostname out of
  `setup-cloudflare-tunnel.sh`, `guides/EMAIL.md` into the docs nav, stale
  `/pr`/`/docs`/`/deploy` and command counts out of CLAUDE_CODE_GUIDE. Also
  scrubbed what the PRs missed: the NAS admin *login* name (half a credential)
  and piracy indexer / release names (generic labels now; Prowlarr IDs and
  every gotcha kept). Your name as a public author identity stays.

## 2026-09-24 — Repo crontab had fallen behind; audit now checks it

`scripts/cron/crontab` is documented as the authoritative schedule, but it
still ran the backup from the **repo** copy (`~/.dotfiles/services/rclone/…`)
— the exact path the 2026-09-23 fix moved away from — and was missing the
`smb-watcher-rescan.sh` and `homelab-audit.sh` jobs. The next
`crontab < scripts/cron/crontab` would have silently re-broken the Immich
photo backup and dropped two jobs. File brought in line with
`scripts/cron/README.md`. ⚠️ The two added lines were reconstructed from the
docs, not copied from the live crontab — the first audit run shows any
difference.

Three gaps closed in the same pass, all "nothing notices" failures:

- **`homelab-audit.sh` diffs `crontab -l` against the repo file**, so the two
  can't drift apart unnoticed again.
- **External-drive staleness.** `backup-external.sh` writes
  `~/logs/external-backup-<drive>.last` on success and reports the previous
  run's age at start; the audit fails past 30 days. Replaces the nightly cron
  removed 2026-09-05 (drives aren't always connected), after which T5 went
  seven weeks stale unnoticed.
- **`scripts/sync.sh` enables the gitleaks pre-commit hook** on every run and
  warns if gitleaks is missing. `core.hooksPath` is per-clone and `install.sh`
  runs once per machine, so older clones (the MacBook) never got it.

### `restore.sh` can now restore everything that is backed up

It could only restore the service-config set. The vault, DB dumps, Calibre
library and Immich originals, which are the irreplaceable parts, had no restore
path, so a disaster would have meant writing rclone commands from memory.
Added `restore.sh set <vault|dumps|books|photos>`. `db` now detects MariaDB
dumps (Nextcloud's) instead of piping them into `psql`, and connects to the
`postgres` maintenance database for `pg_dumpall` output. `all` uses
`rclone copy` rather than `sync`, so it can't delete sets already restored
next to it. Defaults now say R2, not B2.

### Calibre-off-SMB migration scripted (not yet run)

`scripts/utils/migrate-calibre-to-ssd.sh` moves the whole library (1.1GB) to
`~/services/calibre/library`: SQLite over SMB is behind every Calibre-Web
failure so far. Whole library rather than a metadata-only split, because a
split needs three services to agree on two paths and the book folders are
what Calibre-Web renames. The backup scripts no longer hardcode
`/Volumes/books`: they read `BOOKS_DIR` from `~/services/calibre/.env`, so the
backups move with the library.

### Monthly R2 restore check

New `scripts/backup/r2-verify.sh`, cron'd for the 1st of each month: one
random file per backup set is downloaded and byte-compared with the original,
and bucket sizes go to `~/logs/r2-size-history.tsv`, failing on a >5% shrink.
"All backups complete" only proves an upload ran — this proves a restore
works. Tested here against a local stand-in for R2 (a corrupted file and a
shrunk set both fail it). Not yet run against the real bucket.

## 2026-09-24 — External dead-man's switch (code; account setup pending)

Every alert here ran on the Mac mini, so the 2026-09-22 power cut went
unreported. `scripts/utils/heartbeat.sh` now pings Healthchecks.io every five
minutes from cron; Healthchecks alerts from its own servers when the pings
stop. It pings `/fail` when Docker does not answer within 20s, because Uptime
Kuma is a container and is blind at the same moment. The ping URL is a
credential and lives only in `~/.config/homelab/heartbeat.env`; a new gitleaks
rule (`healthchecks-ping-url`) blocks it from being committed, and the weekly
audit fails while it is missing or the last successful ping is over an hour
old. Not wrapped in `run-with-notify.sh` — it would nag every five minutes
while unconfigured; the audit reports that weekly instead.

## 2026-09-24 — Odysseus memories and skills repaired

- **Memory re-import.** The 2026-09-23 import ran on qwen2.5:7b with a 4k
  context — it saw part of the export, merged ~40 facts into one blob (later
  deleted), saved skill descriptions as memories; **none of the export
  survived**. Rewritten as 130 atomic facts directly through `MemoryManager`
  inside the container (no model involved), 12 pinned; vector index rebuilt
  (startup only rebuilds an *empty* index). 3 → 131 memories; 15-fact
  spot-check matched the export.
- **Skills.** Removed 32 nested ownerless `SKILL.md` copies that `app.py`
  would have adopted into `general/` on every restart; pruned the 29 dev
  skills plus one extractor draft — only the homelab skills remain (coding
  stays in Claude Code).
- **Background model.** Task + utility models were empty (fell back to the
  4k local model); now `claude-sonnet-5` (API-billed). Default chat stays
  `claude-opus-5-5`.
- Backups: `data/{memory,settings}.json.bak-2026-09-24`. Scratch files holding
  personal facts removed from container and host `/tmp`.

## 2026-09-24 — CI on every push: secrets, shellcheck, docs

`.github/workflows/checks.yml` runs on every push to every branch:

- **gitleaks** over the pushed commits — the server-side backstop for the
  pre-commit hook, which is per-clone and silently skips when gitleaks isn't
  installed (how the 2026-09-23 commit got in from the MacBook). Pushed
  commits only, so the one dead token still in history doesn't fail every run.
- **`shellcheck -S error`** on every tracked script. Errors only: the warning
  level flags ~40 intentional patterns, and an always-red check gets ignored.
  The one existing error (`scripts/utils/utils.sh` had no shell directive — it
  is sourced, never run) is fixed.
- **`mkdocs build --strict`** — `docs-pages.yml` only built after a push to
  `main`, so a docs break surfaced after it had landed.

## 2026-09-24 — Claude config: setup-claude.sh was silently linking nothing

- **`setup-claude.sh` had linked nothing since the scripts reorg (31dbaa2)** —
  `DOTFILES_DIR` resolved to `scripts/`, so it looked for a nonexistent
  `scripts/config/claude`. That's why dead command symlinks piled up and
  `/dotfiles` never got linked. Fixed the depth; it now also prunes dead
  symlinks pointing into `config/claude` (removed 7).
- Removed duplicate `check`/`debug`/`review`/`standup` commands — the skills
  remain and are invoked the same way (the deletions landed in the
  HOME_SERVER.md commit by accident; same intent). `check` now uses gitleaks;
  `debug` reports root cause / fix / prevention and commits only if asked.
- Devops agent: dropped the removed Grafana/Prometheus stack and the
  ineffective `brew services restart cloudflared` (→ `launchctl kickstart`).
- New global skills: `personal-finance` (IBKR connector, read-only by
  default), `pkm-notes`, `testing` (Vitest/Playwright + Angular + xUnit). No
  personal data in them — details come from Odysseus memory at runtime.

## 2026-09-24 — HOME_SERVER.md rewritten for the NAS architecture

The linked "set up from scratch" guide still described the pre-2026-08-04
T7-primary setup. Rewritten (773 → 353 lines) against the current facts in
`HOME_SERVER_REFERENCE.md`, `SERVICES.md`, `NAS.md` and the live compose files:
architecture, prerequisites (incl. getting into Vaultwarden when it's what
you're rebuilding), step-by-step rebuild with the pmset/FileVault, copy-not-
symlink staging and real-cloudflared-agent caveats, R2/DB-dump/Immich restores,
cron, and an if-something-breaks table. The old narrative stays in git history.
Unverified spots are marked "check" rather than guessed (whether a Time Machine
target is still active; whether the tunnel setup script reuses a tunnel).

## 2026-09-23 (later still) — Nightly backup had silently dropped the Immich photos

**Note:** **Corrects the 2026-09-21 entry that said "let the nightly cron pick it up,
no further change needed" — that was wrong.** Cron ran
`~/.dotfiles/services/rclone/rclone-backup.sh` (the repo copy), and the script
loads `.env` from its own directory — a second, stale `.env` that never got
`BACKUP_IMMICH_PHOTOS=true`. The flag had been set in `~/services/rclone/.env`,
which only the manual runs read. So after the one manual 72GB upload, every
nightly run backed up everything *except* new photos while reporting "All
backups complete". Same trap would have hit today's `HEARTBEAT_URL` move.

Fix: cron now runs the staged copy (`~/services/rclone/rclone-backup.sh`),
matching every other service; the stale repo-side `.env` (a strict subset,
gitignored, never committed) was moved out to
`~/services/rclone/.env.retired-repo-copy`. Dry-run of the exact cron command
confirms the Immich step and heartbeat are active. No photos lost — rclone is
incremental, so the next run uploads the gap.

`homelab-audit.sh` now also fails if Immich backup is enabled but didn't run
in the last day, since "All backups complete" alone can't tell.

## 2026-09-23 (later) — Automation: pre-commit secret hook, weekly audit, project skills

Built so the recurring misses from this week stop depending on anyone
remembering them.

- **`.githooks/pre-commit`** runs gitleaks on staged changes and blocks the
  commit on a hit. `.gitleaks.toml` extends the default rules with an Uptime
  Kuma push-token rule — the defaults missed the real leak; the new rule
  finds it in history (committed 2026-05-09). Tested by staging a fake token:
  blocked, nothing committed. `install.sh` sets `core.hooksPath` on every
  clone; all three installers now install gitleaks. The hook warns and
  allows if gitleaks is missing, rather than bricking commits on a fresh
  machine.
- **`scripts/utils/homelab-audit.sh`** — repo-vs-live drift, containers down
  or unhealthy (skipping `restart: no` on-demand services), R2 backup success
  in the last day, DB dump age, disk usage, gitleaks on the last 8 days of
  commits, hook enabled. Cron'd Sundays 9AM through `run-with-notify.sh`, so
  a failure reaches Discord. First run: all green.
- **Project skills in `.claude/skills/`** (load only in this repo, not in
  other projects): `homelab-service` (add/remove checklist — staging, Glance,
  tunnel, backups, credentials, docs), `credential-rotation` (find and test
  every consumer; stop→edit→start for apps like LazyLibrarian; ALTER USER
  before `.env` for Postgres), `homelab-audit` (runs the script, then the
  judgment checks: full-history secrets, pinned images, stale credentials,
  docs vs reality).
- **Odysseus reads the same `SKILL.md` format natively** (`data/skills/<category>/<name>/SKILL.md`,
  plus a GitHub-URL importer), so these can be imported there. Claude Code
  agents have no direct Odysseus equivalent.

## 2026-09-23 — Public-repo secret audit

Ran `gitleaks` over all 492 commits (no leaks) and separately searched full
history for every specific secret value seen during recent sessions —
Transmission, Gmail app password, Vaultwarden admin token, the old reused
personal password, all *arr API keys, the R2 access key, the Discord webhook.
**None have ever been committed.**

One real find: the **Uptime Kuma push token** was hardcoded in
`rclone-backup.sh` (`HEARTBEAT_URL`). Anyone holding it can report the nightly
backup as healthy, which would hide a real failure. Moved to
`~/services/rclone/.env` (gitignored), placeholder in `.env.example`, script
now skips the ping with a warning if unset. Note: The old token is still in git
history — **regenerate it in Uptime Kuma** (the backup push monitor → reset
token) and update `.env`; that makes the leaked one worthless without
rewriting history.

## 2026-09-22 (power outage) — Auto-restart gap found, monitoring gap found, two research questions settled

**2026-09-29 correction:** the setting interpretation below was wrong.
Apple's installed `pmset` manual defines `autorestart` as restart on power
loss, and it is already enabled. Use the corrected rebuild guide and TODO;
do not run the extra-flag command from this historical entry.

**Power outage — Mac mini never came back on its own.** `pmset -g` showed
`autorestart 1` (restart-after-kernel-panic) but **`autorestartatconnect` was
never set at all** — the actual "power on when AC returns" setting is a
separate, easy-to-miss flag. Needs `sudo pmset -a autorestartatconnect 1`
(interactive password, so this is a command for the user, not something run
in-session).

**Warning:** This alone doesn't give full unattended recovery — FileVault is on.
Every cold power-on hits FileVault's pre-boot disk-password screen, which has
no unattended-unlock path in macOS. **Decided 2026-09-22: keep FileVault on.**
The trade-off was made deliberately — recovering from an outage still needs a
person physically present once, but every one of 30+ services' `.env`
credentials stays encrypted at rest if the machine is ever stolen. The
alternative (turn off FileVault for full auto-recovery) was rejected as the
wrong trade for a box holding that many live secrets.

**Important:** **Real gap found: Uptime Kuma and Discord alerting run on the same machine
that lost power.** Confirmed no external (off this network) monitor exists at
all. When the whole house loses power, nothing can alert about it, because the
alerter is also without power. Needs a genuinely external heartbeat service
(e.g. Healthchecks.io free tier) that expects a periodic ping *from* the Mac
mini and alerts when the ping stops arriving — the inverse of how Kuma
currently works. Tracked in `HOME_SERVER_TODO.md`.

**Settled, don't re-research: no custom OS exists for Kindle Scribe hardware.**
Asked after watching an e-ink tablet comparison video. Unlike Boox (commodity
Android SoC), Amazon's Scribe silicon has no alternative-OS path — the Vera
jailbreak + KOReader is the ceiling for this device. Full writeup in
`guides/BOOKS.md`. The honest trade-off if note-taking quality matters more
than this project's reading goal: a Supernote Manta is a genuinely better
writing device, but that's a second-device purchase, not a Scribe fix.

**Settled, don't re-research: stay on Paperless-ngx over Papra.** Papra is
lighter (1 container vs 2, ~524MB vs ~1.5GB) with a nicer UI, but **has no OCR
at all** — a hard blocker for a document-archive use case. Paperless-ngx also
has ~8x the community size. Revisit only if Papra ships OCR.

**Self-hosted music: no new service needed.** Checked — Jellyfin has no music
library configured yet and there's no music folder on the NAS, but Jellyfin
already natively supports music as a library type. Adding a `/Volumes/media/music`
folder and pointing Jellyfin at it as a new library is the whole task; no
Navidrome/Airsonic deployment needed unless a more music-specific UI is
wanted later.


## 2026-09-21 (later) — Email audit corrected, TODO resequenced

**Correction: the earlier email audit was wrong.** It checked container *environment
variables* and concluded only `kindle_sync.py` used email. Two more consumers
store their SMTP settings in **SQLite**, where an env check cannot see them:

- **Calibre-Web** — `smtp.gmail.com:587` in `/config/app.db`, for Send-to-Kindle
- **Uptime Kuma** — an active `smtp` notification in `/app/data/kuma.db`,
  alongside the Discord one

So revoking the Gmail app password breaks both. Calibre-Web has no fallback and
**fails silently**. `guides/EMAIL.md` now documents all three consumers, carries
a two-part audit command (env *and* database), and orders the runbook so both
are repointed and tested before the app password is revoked.

**Removed a stray container.** `relaxed_ritchie` (vaultwarden 1.35.4) was left
running from the `vaultwarden hash` debugging. Note: **Its pre-hash `ADMIN_TOKEN`
remained visible in the container config for ~4 hours**, readable by anything
that could run `docker inspect`. Container and its anonymous volume removed;
rotating the token is now step 3 of the TODO. Lesson recorded: `docker inspect`
exposes every container's full command line, so secrets must arrive on stdin to
a `--rm` container — and you must verify it actually exited.

**Found 212 cleartext passwords in `~/Downloads`** — unencrypted Bitwarden
exports from the Vaultwarden scare, never cleaned up. Now step 1.

**Resequenced `HOME_SERVER_TODO.md`** into an explicit 1–9 path with a table
saying *why* each step sits where it does, rather than competing numbered
sections. Older detail moved under "Detail and standing items". Refreshed the
SSD section (it had hit 15GiB/92%, not the 29GB recorded) and added the
warning that `docker image prune -a` would delete Storyteller.

## 2026-09-22 (later still) — Same credential bug hit a third service, plus a real find

Asked "will this hit other services too" after the Radarr/Sonarr fix — checked
rather than assumed:

- **LazyLibrarian had the identical bug**, and worse: its stored Transmission
  password was still the user's actual old, reused personal password (the
  same one flagged earlier in the credential migration project), sitting in a
  live config file rather than just a doc. Fixed — but the fix didn't stick on
  the first try: `docker restart` let LazyLibrarian flush its own in-memory
  config back to disk on shutdown, silently reverting the edit. Second attempt
  used `docker stop` → edit while fully dead → `docker start`, which held.
  Also deleted `config.ini.bak`/`.bak2`, which carried the same old password.
- **Bazarr, Jellyseerr, Prowlarr are unaffected** — confirmed each only stores
  API keys for Radarr/Sonarr/Jellyfin, never a Transmission login, so nothing
  in the credential rotation touches them.
- **Hardened LazyLibrarian's release filter** (`reject_words`) with the same
  `.exe/.scr/.msi/.bat/.cmd/.vbs/.jar/installer` terms added to Radarr/Sonarr
  earlier tonight — the malware-disguised-as-media risk applies to ebook/
  audiobook indexers exactly the same way.
- **Found a real, separate issue while checking:** `~/services/immich/.env`'s
  `DB_PASSWORD` is also the same old reused personal password — never rotated
  during the credential migration. Internal-only (not exposed outside the
  Docker network), so not fixed tonight at midnight without testing — the
  correct sequence (ALTER the Postgres user first, then update `.env`, or
  Immich's DB connection breaks entirely) is written out in
  `HOME_SERVER_TODO.md`.
- **Renamed `jellyfin-rescan.sh` → `smb-watcher-rescan.sh`** and extended it to
  also restart Audiobookshelf, which runs an identical watcher on an
  identically SMB-mounted library (`/Volumes/audiobooks`) — no confirmed
  failure yet, added preventively since the root cause is architectural.
- Added a standing warning to TODO step 6 (the credential migration pass):
  after rotating any password, grep every service's config for the old value,
  not just assume the one service you changed is the only consumer.

## 2026-09-22 (later still) — Finished download didn't appear in Jellyfin

Two separate gaps, not "just needed to wait":

1. **Radarr had the file on disk but hadn't registered it** (`hasFile: false`
   despite the `.mp4` already sitting in `/media/movies/`). Forced with
   `POST /api/v3/command {"name":"DownloadedMoviesScan"}` — resolved in
   seconds, so this one likely would have cleared on its own next scheduled
   check, just not instantly.
2. **Jellyfin never noticed the new file at all** — confirmed real, not a
   timing issue: `/Library/Refresh` needs auth (401, no key configured), and
   even after Radarr's import completed, zero scan/refresh activity appeared
   in Jellyfin's logs. This is the same class of limitation already
   documented for other services on this NAS — Jellyfin's real-time file
   watcher does not reliably see changes on an SMB-mounted share. Restarting
   the container (forces a full scan on startup) picked it up immediately,
   confirmed via `ffprobe` running against the exact file in the fresh logs.

**Added `scripts/utils/jellyfin-rescan.sh`**, cron'd every 30 minutes via the
existing `run-with-notify.sh` wrapper — restarts Jellyfin so this stops being
a manual step for every future download. This is the blunt fix (a few
seconds of playback interruption for anyone actively streaming, every 30
min); the surgical one is a native Radarr/Sonarr → Jellyfin "Connect"
integration that refreshes just the new item with no restart, gated on one
thing only a person can do — generate a Jellyfin API key in its dashboard.
Tracked in `HOME_SERVER_TODO.md`.

## 2026-09-22 (later) — Download pipeline was silently broken, then served malware

**Root cause of "requested movies never appear in Transmission":** Radarr and
Sonarr were both still authenticating to Transmission as `admin` with the old
password. The 2026-09-19 credential migration rotated Transmission to
the standard username + a new generated password, but never updated the *other
side* of that connection — each app stores its own separate copy of the
download client's login. Every release either app grabbed was silently
failing at the handoff with `Authentication Failure` / `downloadClientUnavailable`,
invisible unless you specifically checked Radarr's queue detail. Fixed both
via the API, verified each connection test passes clean.

**Important:** **While confirming the fix, one of the two retried releases turned out to
be malware.** A movie release from one of the Prowlarr indexers was a single
1.15GB `.exe` file — no
video container, no subtitles, nothing else in the torrent. Already 19%
downloaded (223MB) by the time it was caught. Real releases are never a bare
executable.

- Deleted the torrent and its data from Transmission
- Cleared a `.smbdelete*` remnant it left behind on the NAS (same SMB-can't-
  delete-an-open-handle issue documented elsewhere in this file)
- Blocklisted the release in Radarr via `DELETE /api/v3/queue/{id}?blocklist=true`
  (a raw `POST /api/v3/blocklist` call silently did nothing — the queue
  endpoint's blocklist flag is the one that actually works)
- Triggered a fresh search; a legitimate release should replace it

**Added a release profile to both Radarr and Sonarr** rejecting
`.exe .scr .lnk .msi .bat .cmd .vbs .jar`, `password.txt`, `setup.exe`,
`installer` in a release name — this class of fake release gets auto-rejected
before ever reaching a download client, not just cleaned up after the fact.

## 2026-09-22 — Removed Mealie and Grafana/Prometheus, verified the RAM claim

**Mealie:** confirmed 0 real recipes in the data directory despite the folder
existing — genuinely never used, not just forgotten about. **Grafana +
Prometheus + node-exporter:** confirmed Tailscale-only (never in
`~/.cloudflared/config.yml`, so no public exposure existed), zero scripts in
this repo read its data, and the login itself was already forgotten. Both
removed: containers stopped, `~/services/{mealie,grafana}` deleted, repo
entries removed, Glance homepage monitors/bookmarks/networks removed, the
`recipes.peciulevicius.com` tunnel ingress rule removed and verified (now
404s instead of hanging on a dead port), the dead `grafana/data/**` rclone
exclude removed. 42 → 38 containers.

**Found while restarting the tunnel: two competing cloudflared LaunchAgents.**
`brew services restart cloudflared` reported success but the real
traffic-serving process — started outside Homebrew, a separate
`com.cloudflare.cloudflared.plist` — never noticed the config change. Fixed
with `launchctl kickstart -k gui/$(id -u)/com.cloudflare.cloudflared`,
verified via PID/start-time change and a live curl to both a working and the
now-removed hostname. Documented in `HOME_SERVER_REFERENCE.md` so the next
tunnel edit doesn't lose 20 minutes to the same trap.

**Tested, did not just assume, whether this frees headroom for bigger Odysseus
models.** Loaded `qwen2.5:7b` before and after: swap still grew to 8.19GB
total (7.31GB used) post-removal, memory free still 22% — statistically the
same as the 23%/7.1GB swap measured earlier the same night. **The ~1.78GiB
reclaimed is a real, permanent baseline improvement, but it does not unlock a
larger model tier** — something else reabsorbed it. The ~8B ceiling in
`.claude/CLAUDE.md` stands unchanged.

## 2026-09-21 (actually final) — Immich offsite backup ran clean

**Flipped `BACKUP_IMMICH_PHOTOS=true` and ran it.** Verified R2 pricing live
against Cloudflare's own pricing page first ($0.015/GB-month, 10GB free, free
egress — matched what was already documented). Dry run predicted 72.4 GiB /
6,696 files; the real run landed exactly that, zero errors.

**First attempt crashed — self-inflicted.** Fixed the portainer.db/celerybeat
BadDigest bug (see above) by `cp`-ing the corrected script over the *live*
file while the backup was still running against it. Bash reads a script
incrementally; changing its length under a running interpreter corrupts its
read position, and it hit a syntax error a few steps later and died mid-run.
No data was lost — services/Obsidian/DB-dumps had already completed before
the crash, and Immich's own object count in R2 was confirmed at 0 before the
retry, so nothing was left half-written. **Lesson: never overwrite a script
file while it may still be executing** — wait for the run to finish, or write
to a temp file and `mv` it in atomically instead of `cp` in place. Restarted
clean; the second run went start to finish with no intervention.

Checked but did not yet act on: R2 API token scope (the setup docs never
directed scoping it to one bucket — should be verified/tightened in the
Cloudflare dashboard), Cloudflare account 2FA (not tracked in the credential
checklist at all despite controlling DNS/Tunnel/Email/R2), Nextcloud's actual
user files (83MB, currently fully excluded from any backup), and audiobooks
(18GB, would add ~$0.28/month to enable the same way as photos).

## 2026-09-21 (final) — Fixed live drift instead of just flagging it, caught a stale setup guide

**Went back and actually fixed what the drift sweep found**, rather than
leaving it as a footnote. `jellyfin`, `transmission` and `sonarr-radarr`'s live
`docker-compose.yml` still defaulted `MEDIA_DIR` to `/Volumes/T7/media` (dead —
`.env` already overrides it to the NAS on all three, confirmed before touching
anything) — re-staged from the repo, which already had the right default.
**Immich's live config used a hardcoded `TZ: Europe/Vilnius` env var** where
the repo bind-mounts `/etc/localtime:ro` (portable, follows the host
automatically). Applied the repo version, recreated `immich_server`, and
verified the container's clock still matches the host exactly post-recreate.

**Found `HOME_SERVER.md` describes an architecture that stopped existing on
2026-08-04.** It's the linked "set up a new Mac mini from scratch" guide, and
it still tells a reader to `mkdir -p /Volumes/T7/media`, point Immich's
Postgres/upload/model-cache at a T7 volume, and put Calibre books on T7 — the
pre-NAS-migration setup, when T7 was primary storage instead of a decoupled
manual backup target. Three other docs (`SERVICES.md` ×2, `UTILITY_SCRIPTS.md`)
linked to it as "the backup strategy," which meant the actually-current backup
facts in `HOME_SERVER_REFERENCE.md` weren't where a reader would land. Added a
banner to the top of `HOME_SERVER.md` making the historical status explicit and
pointing at current docs, repointed all three stale links, and updated
`START_HERE.md`'s index row and `.claude/CLAUDE.md`'s file list to match. A full
rewrite of the ~750-line body against the NAS architecture is tracked as its
own item in `HOME_SERVER_TODO.md` — too large to do as a drive-by fix.

## 2026-09-21 (later still) — Offsite photo backup plan, fastembed cache leak fixed

**Added an opt-in cloud offsite copy of Immich originals.** `rclone-backup.sh`
gets a new Backup 5, guarded by `BACKUP_IMMICH_PHOTOS` (default `false`):
`/Volumes/immich/upload/upload` (~73GB) → R2 `peciulevicius-backups/immich-photos`.
Excludes `encoded-video/` and `thumbs/` (regenerable by Immich) and `backups/`
(Immich's own DB snapshot, already redundant with the `pg_dump` of
`immich_postgres` that Backup 3 ships separately). Left off by default on
purpose — turning it on hands the next cron run a multi-hour first upload and
moves the R2 bill from $0 to ~$1/month; the TODO now has the exact commands to
enable it deliberately, by hand, before it ever reaches a cron run. This is a
second, complementary offsite layer alongside the existing T5-to-parents'-house
plan, not a replacement for it.

**Found and fixed a real leak while testing the above.** A `--dry-run` of the
existing Backup 1 (services configs) showed `.incomplete` partial model blobs
from `odysseus/data/fastembed_cache/` being swept into the backup — a cache
directory the existing huggingface/local excludes didn't cover. Added the
exclude; same regenerable-cache class as the other two, ~97MB.

## 2026-09-21 — Local model benchmarks, disk cleanup, email runbook

**Models.** Benchmarked all three local models on the same real training
question, 100% GPU via native Ollama. `qwen2.5:7b` (20.1 tok/s, 4.8 GB) is the
only one that engaged with the numbers in the question — it becomes the chat
default. `llama3.2:3b` (42.9 tok/s, 2.5 GB) is twice as fast but shallow, so it
takes Odysseus's background calls (titles, tagging). **Removed `qwen3:4b`** —
dominated on both axes: 2445 tokens and 80s to answer what the 7B answered in
479 and 30s. Ollama's `"think": false` does not suppress reasoning cleanly.

**Cookbook ruled out permanently.** Docker on macOS has no GPU passthrough, so
Cookbook scans the *container*, not the M4 — it reports `No GPU`, rates 1.5B
models "PERFECT" and offers 70 GB downloads. Verified no stray download ever
landed: `data/huggingface/` is 72 KB and the writable layer 74.8 MB.

**Disk was at 92%** (15 GiB free), not the ~29 GB previously recorded. Freed
6.05 GB of Docker build cache and 477 MB of Homebrew cache → **22 GiB**.
**Note:** Learned: the 2.77 GB "unused" image is **Storyteller**, merely stopped —
`docker image prune -a` would have deleted it. Dangling-only reclaimed 0 B.

**Email audit.** Checked all 43 containers and every script: `pkm/kindle_sync.py`
is the **only** consumer of email (IMAP). Uptime Kuma and `notify.sh` use
Discord webhooks; **no container has SMTP configured**. So the Purelymail
migration breaks nothing — it is a 3-line change in one gitignored file.

**Wrote [guides/EMAIL.md](./guides/EMAIL.md)** — a from-cold runbook: the four
moving parts, provider comparison with the IMAP requirement that eliminates
Proton/Tuta/Zoho, the signup dropdown gotcha (it is the *admin user's* address,
not your domain), all seven DNS records, rollback via re-enabling Email Routing,
verification commands, and the permanent Gmail funnel for contacts who have the
old address. Fixed stale status rows in `START_HERE.md` (Odysseus listed as
"not started") and `DEGOOGLE.md` (email listed as "not started").

## 2026-09-21 — Odysseus deployed, read-along verified, Calibre repaired

### Odysseus running on 7001

Four containers — odysseus, chromadb, searxng, ntfy — with the local model
served by **native Homebrew Ollama**, not a container. Verified from inside the
container: it sees `qwen3:4b` over `host.docker.internal:11434`.

Three things this setup needed that upstream's defaults don't give you:

- **Port 7001, not 7000** — macOS AirPlay Receiver owns 7000, which upstream's
  own `.env.example` warns about.
- **`OLLAMA_HOST=0.0.0.0:11434`** — Ollama binds loopback by default, so the
  container cannot reach it. This is the sort of thing that reads as "the model
  isn't working" rather than a networking setting.
- **A compose override dropping SearXNG's host port** — upstream publishes
  `127.0.0.1:8080`, which collides with Nextcloud. Odysseus talks to it over
  the compose network, so the mapping was never needed. Kept in
  `docker-compose.override.yml` so `git pull` cannot clobber it.

**Tailscale-only, deliberately.** It holds health and finance history and its
agent executes code; the iPhone is already on the tailnet, so a public hostname
would add exposure and buy nothing.

Measured: ~960MB for the four containers, 686MB image, host headroom down to
**2.11 GiB**. SearXNG is the first to drop if that bites.

**Warning:** Cookbook caveat worth remembering: upstream's compose says *"Inside
Docker, 'Local' means the Odysseus container."* Docker on macOS has no GPU
passthrough, so anything Cookbook serves "locally" is CPU-only and its hardware
scan measures the container. That is almost certainly the real cause of the
2026 entry below recorded as *"Ollama + Open WebUI — removed, not enough RAM."*

### Decided against OpenRouter

The obvious choice for multi-model access, rejected on research: 5.5% top-up
fee, **1-year credit expiry**, 24-hour refund window buried in fine print,
Discord-only support, a reported account compromise with ten card charges in 30
minutes, some providers silently serving quantized models — and its $113M
Series B was led by **CapitalG, Alphabet's investment arm**, which is a poor
fit in the middle of a de-Googling project. One direct Anthropic key covers the
need; Odysseus supports multiple backends natively if that changes.

### Read-along confirmed working

The whole books chain works end to end: Storyteller alignment → Calibre-Web →
OPDS → KOReader, highlighting words during real narration. Self-hosted
Whispersync, with Amazon nowhere in it.

**Note:** Playback **speed** does nothing on Kindle — upstream implements `setSpeed`
for mpv, MPlayer, ffmpeg-pipe and generic GStreamer but not the Kindle
backends, and the call sits in a `pcall` so it fails silently. Workaround is
`ffmpeg -filter:a atempo=` on the M4B *before* aligning.

### Calibre library repaired twice, and the cause named

Renaming a book in Calibre-Web corrupted the library entry two separate times:
it renames the folder, copies the 769MB EPUB, fails to delete the original
because SMB reports it busy, then rolls back the database without undoing the
folder rename. Repaired by renaming the folder back to the path `metadata.db`
expected.

Root cause is `metadata.db` being **SQLite on an SMB share** — the same rule
that keeps Immich's Postgres on the internal SSD. `disk I/O error` opening a
shelf, `Device or resource busy` on renames, and `.smbdelete` duplicates are all
the same problem. Moving the 1.1GB library to the SSD is now a TODO.

## 2026-09-20 — Kindle Scribe jailbroken, KOReader + read-along

Done with **Vera** on firmware 5.19.6. Earlier than `guides/BOOKS.md` predicted —
that guide was written while Vera's Scribe port still read as *pending*, and the
plan had been to wait and watch kindlemodding.org.

`;kpm` is available on the device, so the rest of the books plan is now live
work rather than a waiting game: KOReader over Calibre-Web's OPDS feed, custom
screensavers, and UsbNetLite for the SSH push script.

Verified while planning it: `https://books.peciulevicius.com/opds` answers with
**HTTP Basic auth**, which KOReader's OPDS client speaks natively, and it is not
behind Cloudflare Access — an Access challenge would block the reader the same
way it blocks the Obsidian LiveSync plugin. So the intended setup works as
designed.

The recommendations, with reasoning about what to skip, are in
[guides/BOOKS.md](guides/BOOKS.md#what-to-install-after-the-jailbreak).

---

### Storyteller deployed for read-along books

`services/storyteller/` on port 8087 (8001 is Vaultwarden). Verified running —
HTTP 200, **340 MB idle** — then stopped again, which is how it is meant to
live: `restart: "no"`, brought up only to align a book.

It exists because KOReader's audiobook plugin plays Audiobookshelf audiobooks
but **cannot highlight text during real narration** — an audio file has no map
from seconds to words. Storyteller transcribes the audio, force-aligns it
against the ebook, and emits an EPUB 3 with Media Overlays, which does.

**Note:** The ~4GB figure is for alignment, not idle, and that is the same headroom
Odysseus is earmarked for on a host already swapping 4.1GB. Batch use only.

**Note:** Media Overlay support in `audiobook.koplugin` is still *work in progress*, so
align one book and confirm the Kindle highlights it before doing a shelf.

Data on the internal SSD (SQLite), excluded from R2 — the audio is bulky and
regenerable; the aligned EPUBs belong in Calibre-Web, which is backed up.

## 2026-09-19 — Verification, backups, CouchDB

A "just verify what's running" session that turned up two silent failures.

### Fixed: two of four database dumps had never worked

`linkwarden_db` was dumped as role `linkwarden` (it is `postgres`), and
`nextcloud_db`'s `mariadb-dump` ran with no password while `MYSQL_ROOT_PASSWORD`
is set. Only immich and paperless had ever landed in `~/backups/`. The script
also exited 0 regardless, so nothing ever reported it.

Fixed, and `backup-databases.sh` now counts errors and exits non-zero. All four
verified: immich 129M, paperless 432K, linkwarden 1.7M, nextcloud 3.5M. The
MariaDB password is read from the container's own env, so it stays out of the repo.

The earlier Aug 16 + 23 gap did **not** recur — Aug 30, Sep 6, Sep 13 all landed.

### Found, not fixed: the Kindle sync has been dead since early July

~1,763 consecutive hourly failures with `[AUTHENTICATIONFAILED] Invalid
credentials` — the Gmail app password in `pkm/config.py` is no longer valid.
Needs a new app password generated by hand; still outstanding.

### Added: Discord alerts for cron jobs

`scripts/utils/run-with-notify.sh` wraps each job and posts to the same Discord
webhook Uptime Kuma uses, on **transitions** (ok→fail, fail→ok) rather than
every run, re-nagging daily while still broken. `scripts/cron/crontab` is now
the authoritative copy of the schedule, which previously lived only in the live
crontab.

**Note:** Learned the hard way: **`crontab <file>` silently installs an empty crontab**
on macOS when the file is outside home — exits 0, wipes everything. Pipe via
stdin and always `crontab -l` to verify.

### Cleaned up: karakeep and actual-budget removed for real

Containers stopped, images deleted (karakeep 2.1GB, alpine-chrome 958MB,
meilisearch 234MB, actual-budget 548MB), `services/karakeep/` and
`services/actual-budget/` deleted from the repo, and both dropped from
`setup-services.sh` and `services/README.md`. Docker went from 44.78GB to
35.47GB of images. Data directories under `~/services/` are still there.

Also unmounted a duplicate SMB mount: `/Volumes/media-1` was the same NAS share
mounted a second time by IP (`192.168.1.73`) alongside the mDNS mount at
`/Volumes/media`. Nothing referenced it.

### Fixed: the tunnel setup script pointed `links` at the wrong port

`setup-cloudflare-tunnel.sh` mapped `links.peciulevicius.com` to **3006
(Karakeep)**, but Linkwarden is on **3005** — so re-running it on a fresh
machine would have broken the bookmark manager's URL. Corrected, and
`couchdb` → 5984 added so a rebuild recreates the LiveSync hostname too.

### Added: Discord webhook configured, alerts verified live

`~/.config/homelab/notify.env` created with the same webhook Uptime Kuma uses.
Test post returned HTTP 204. Cron job failures now actually reach Discord.

### Tried and failed: the Gmail account password does not work for IMAP

Filling `EMAIL_PASSWORD` with the Google **account** password was rejected with
`AUTHENTICATIONFAILED`. Gmail IMAP requires a **16-character app password** when
2FA is on. The field was cleared rather than left holding an account password in
plaintext. The three places that password is used were mapped — `pkm/config.py`, Uptime Kuma SMTP, Calibre-Web Send-to-Kindle
— because a revoked one breaks all three and only the first one is noisy.

### Removed: Readarr

Checked before removing rather than assuming: **0 authors, 0 books, 0 grab
history** in `readarr.db`. It had never acquired anything, and it is archived
upstream. Container, image (300MB), repo directory and every reference in
`dev-check.sh`, `nas-watchdog.sh`, `NAS.md` and the Calibre compose comments
are gone. LazyLibrarian is the book pipeline.

**Note:** Worth knowing: LazyLibrarian has **0 books downloaded** too (47 known, 1
author). The pipeline is configured, not proven.

Data directories for karakeep (238MB), actual-budget (80KB) and readarr (49MB)
were moved out of `~/services/` to `~/.Trash/homelab-removed-20260919/`.

### Credential policy set, first two services rotated

Username standardised on **one non-default name** (not `admin` — the first username
every automated attack tries). Passwords split into two kinds: one memorised
passphrase for the Vaultwarden master, generated random for everything else,
with a six-word passphrase reserved for the one password actually typed by hand
on a phone (CouchDB in the LiveSync plugin).

Rotated and verified: **Vaultwarden master password** (by hand), **CouchDB**
(standard username + 32-char random — old credentials rejected, `obsidian`
database intact, anonymous requests 401 on every path including `/`) and
**Transmission** (standard username + 28-char random).

The passphrase idea was dropped the same day: since every password is copied
out of Bitwarden anyway — on the phone too — nothing but the vault master is
ever typed, so there is no reason for a service password to be memorable.
Random everywhere.

Every service was inventoried with the URL to store in the Bitwarden entry, so
autofill matches (this lived in `docs/CREDENTIALS.md`, later folded into the
out-of-repo worksheet `~/credentials-import.md` — see the note below). It also flags that
several logins *are* the Gmail address (Vaultwarden, Immich, Linkwarden,
Mealie), which the email migration has to change inside each app — not just
forward.

**Note:** Discovered while planning it: `ADMIN_USER` / `GRAFANA_USER` in the other
`.env` files are **inert** — they are read only at first initialisation, so the
account already exists in each app's database and editing `.env` changes
nothing. Those renames are UI work; the checklist is in `~/credentials-import.md`.

### Kindle sync restored after ~73 days, and a silent data-loss bug fixed

A new Gmail app password brought it back, set via a throwaway helper that
prompted without echoing so the secret never touched shell history or a
transcript (removed after use; recoverable with
`git show 50c21f9:scripts/setup/set-kindle-password.sh`). Google's
app-passwords page listed **none**, confirming the old one was deleted rather
than expired, so Uptime Kuma's SMTP alerts and Calibre-Web's Send-to-Kindle
broke at the same moment and stayed broken silently.

**Nothing was lost in the outage:** the inbox holds zero Amazon export emails,
so no notebooks were sent during those 73 days. Consistent with the capture
friction the notes guide describes — the Scribe was not being used.

While verifying that, found a real bug. `.processed_ids` stored IMAP **sequence
numbers** (51, 52, 61, 64-68), which are positional and renumber whenever mail
leaves the mailbox. A stored number can therefore match a different email later:
either a new export is silently skipped and its Amazon link expires after 7
days, or an already-imported note is written to the vault twice. Both silent.

Fixed: searches and fetches by UID, and dedupes on the RFC822 **Message-ID**
header. Message-ID is globally unique and travels with the mail, so it survives
the planned move to Purelymail — UIDs would not, as they reset on a UIDVALIDITY
change or provider move. Falls back to a sha256 of `Subject|Date|From` when a
message carries no Message-ID. The 8 stale sequence numbers were dropped, safe
because the inbox contains no Amazon mail to re-import.

### Calibre-Web "database disk image is malformed" — stale bind mounts

Not corruption. `metadata.db` passed `PRAGMA integrity_check` on the host the
whole time. `/books` **inside the container** was returning EBADF: the host had
remounted the SMB share while the container kept running, so its bind mount
still pointed at the dead mount instance, and SQLite reading through that fd
reports the file as malformed.

A scan found **five more containers in the same state** — Jellyfin (movies and
TV), Sonarr, Radarr and Bazarr were all blind to `/media` and had said nothing.
`docker compose restart` re-resolves the bind mount; all twelve NAS-backed
mounts verified healthy afterwards.

The existing `nas-watchdog.sh` could not catch this: it checks that shares are
mounted **on the host** and that containers are **running**, and both were true.
It now also probes from inside each container and restarts any stack whose bind
mount has gone stale, reporting it to Discord.

**Note:** Worth noting the underlying rule this bumps into: `metadata.db` is SQLite
living on an SMB share, which the repo's own guidance says never to do. It
survived this time because the file was only being *read* through a dead fd
rather than written. Moving the Calibre library metadata onto the internal SSD
is the real fix and is now an open TODO.

### Cloudflare Email Routing live, catch-all verified

`peciulevicius.com` now receives mail: `contact@`, `hello@`, `dziugas@` and a
catch-all, all forwarding to Gmail. Verified by delivering to an address that
was never created, which confirms the catch-all is active and that every local
part at the domain reaches the inbox.

Receive-only, though — Cloudflare provides no SMTP, so Gmail's "Send mail as"
cannot send from the custom address. Fine for signups, weak for correspondence,
and the concrete reason to stop deferring Purelymail.

### Docs site build fixed

`mkdocs build --strict` was failing on main. The cause was a link added earlier
that day from `START_HERE.md` to `../scripts/cron/README.md` — outside the docs
tree, so mkdocs cannot resolve it and strict mode turns that warning into a
failure. Now an absolute GitHub URL.

Also removed two brittle anchors into the changelog (em dashes slugify
unpredictably) and fixed three genuinely wrong in-page anchors that had been
broken for readers: `#sonarr--radarr--prowlarr`, `#grafana--prometheus` and
`#setup--update` all use single hyphens once slugified. Verified by running the
exact CI command locally — exit 0, no warnings.

### Security: Pi-hole had a 5-character password, publicly exposed

Auditing the `.env` files turned it up: `PIHOLE_PASSWORD` was 5 characters and
contained a common word, on `pihole.peciulevicius.com` — a public admin panel
that controls DNS for the whole network. Anyone into it could silently redirect
any domain. Rotated to 32-char random and verified DNS still resolves. Treat the
old password as exposed.

Same audit found **Immich's Postgres role still uses the old reused personal
password**. Internal-only, so lower risk, but changing it needs `ALTER USER`
inside the database and the `.env` updated together — left for a deliberate
session. Nextcloud, Paperless, Linkwarden and the Vaultwarden admin token all
checked out as 32–64 char random.

Also found **two Nextcloud accounts**: the standard one, and a second `admin`
whose display name is confusingly the same as the standard username.

### Credentials documentation moved out of the repo entirely

`docs/CREDENTIALS.md` was created and then deleted the same day. The reasoning:
a secret-free "map" in the public repo and a separate worksheet holding the real
values meant two files to keep in sync, and the map is not what you reach for
while actually moving passwords into Bitwarden.

Everything — the per-service table with URLs and usernames, the CLI reset
commands, the Gmail app-password procedure, and the known issues — now lives in
**`~/credentials-import.md`**, outside the repo, chmod 600, to be deleted once
the vault is populated.

What stays in the repo is the *rule*, in `.claude/CLAUDE.md`: this repo is
public, so no password, token or webhook URL may ever land in it — not even in
documentation.

### Added: CouchDB for Obsidian LiveSync

`services/couchdb/` — single-node, CORS for `app://obsidian.md`, `obsidian`
database created, data on the internal SSD. Live at
`https://couchdb.peciulevicius.com` (tunnel) and on the tailnet. Anonymous
requests 401. Deliberately **not** behind Cloudflare Access: an interactive
Access policy blocks the plugin, which cannot do a browser login.

**Note:** Do not bind-mount `local.ini` into `/opt/couchdb/etc/local.d/`. The stock
entrypoint chowns everything under `/opt/couchdb` under `set -e`, a macOS bind
mount cannot be chowned, and the container dies **with empty `docker logs`**.
The compose file mounts at `/config` and copies it in.

### Reconciled: karakeep and actual-budget

Both were recorded as removed while still running. Now genuinely stopped and
removed, and karakeep is out of `setup-services.sh`. Data kept in `~/services/`;
`docker compose up -d` restores either. Host went to 39% free.

### Fixed: `~/docker` vs `~/services`

`setup-services.sh` moved staging to `~/services` long ago; `update.sh` and
`dev-check.sh` still looked in `~/docker`. So update.sh had been silently
pulling **zero** images, and dev-check reported services unstaged on a machine
with all of them.

### Decided: Octopus Deploy is not happening here

Ruled out on measured RAM, not principle — its SQL Server dependency wants
~3–4GB against ~4.1GiB of Docker headroom on a host already swapping 3GB.
Research preserved in [guides/OCTOPUS_DEPLOY.md](guides/OCTOPUS_DEPLOY.md) so it
does not get re-proposed.

### Reorganised the docs

Reference material (RAM baseline, drive layout, path mappings) moved out of the
TODO into [HOME_SERVER_REFERENCE.md](HOME_SERVER_REFERENCE.md). The TODO holds
only outstanding work again.

---

## NAS — arrival and migration (Jul–Aug 2026)

**Status (Jul 2026):** NAS arrived (UGREEN DH4300 Plus, warranty until 2028-07). Drives ordered — 3× IronWolf Pro 6TB recert (ST6000NE000) €230 each from [datablocks.dev](https://datablocks.dev), preorder arriving **~Jul 27–31**.

**Done (pre-drives, Jul 22):**
- [x] NAS on network at 192.168.1.73 via WiFi extender ethernet port (100Mbps — extender is the bottleneck, acceptable for now)
- [x] `nas.peciulevicius.com` → UGOS Pro web UI, via existing cloudflared tunnel on Mac mini (ingress: `http://192.168.1.73:9999`). No Docker needed on NAS.
- [x] UGREENlink remote access active (fallback access path; link kept in Vaultwarden)

**Still to do (pre-drives):** moved to `HOME_SERVER_TODO.md` → "NAS — remaining
follow-ups" (the NAS UI settings) and "Router DHCP reservation for the NAS"
(MAC in the router's client list). Tracked there, not here — this file is finished
work only. The reservation is no longer load-bearing: everything addresses the
NAS by mDNS (`DH4300PLUS-DP.local`) since 2026-09-05.

**Migration done (2026-08-04)**
- [x] RAID 5 pool created (3× 6TB IronWolf Pro = ~11TiB usable), Btrfs
- [x] SMB on; shares: `media`, `immich`, `audiobooks`, `books`, `unsorted`; service account `macmini` (ASCII name — a non-ASCII character in the personal admin account name breaks SMB auth)
- [x] Tailscale via Docker container on NAS (`ugreen-nas`, 100.95.228.35) — remote SMB/Finder
- [x] Full copy T7 → NAS (~680GB incl. 142G photo archives → `unsorted`), zero errors
- [x] All services switched to NAS paths (`/Volumes/media` etc.); Immich Postgres moved to internal SSD (`~/services/immich/data/postgres`) — DBs must not live on SMB
- [x] Reboot-proof mounts: `scripts/utils/mount-nas.sh` + `com.peciulevicius.mount-nas` LaunchAgent
- [x] Glance tile for NAS

---

### ~~1. Calibre-Web — finish setup~~ — done (2026-05-09)

Bookshelves skipped (not needed). Send to Kindle configured via Gmail SMTP — the device's `@kindle.com` address approved and working.


### ~~2. Uptime Kuma notifications~~ — done (2026-05-09)

Gmail SMTP configured (smtp.gmail.com:465, app password). Email alerts working.


### ~~5. Set up Obsidian vault sync via Syncthing~~ — done (2026-05-08)

`obsidian-vault` folder shared in Syncthing across Mac mini, MacBook, and iPhone. Real-time sync working.



### ~~8. Bazarr — subtitle provider~~ — done (2026-05-09)

OpenSubtitles.com configured, Default language profile set with English. Applied to all series and movies. 71 Wanted items queued — downloading automatically.


### ~~13. Show Mac host stats in monitoring~~ — done (2026-05-07)

Homebrew node_exporter running at port 9100, scraped by Prometheus (`job="mac-host"`). Custom Grafana dashboard (`mac-host.json`) provisioned — shows real 16GB RAM, swap, CPU, disk, network. Glance `server-stats` widget updated to show actual host figures.


### ~~14. Uptime Kuma — rclone backup heartbeat~~ — done (2026-05-09)

Push monitor added in Uptime Kuma. Heartbeat URL wired into `rclone-backup.sh` — pings up on success, down on failure. R2 backup verified working across all 4 targets.


### 15. ~~Migrate backups from B2 to Cloudflare R2~~ — done (2026-04-22)

Migrated to Cloudflare R2. Nightly rclone backup running at 5am. R2 at ~1.3GB (critical-only: vaultwarden, paperless docs, obsidian vault, db dumps, calibre books). B2 bucket purged and can be deleted from Backblaze dashboard.


### ~~16. Docker VM resource limits~~ — done (2026-07-23)

Docker Desktop VM bumped from 7.8GB → 10GB RAM, swap 1GB → 2GB (via
`settings-store.json`). Also enabled AutoStart so Docker launches on login
after a reboot/power cut. All 40 containers verified back up, key services
responding (photos/vault/home/watch/nas all 200).

---


### ~~17. Kindle Scribe → Obsidian automation~~ — done (2026-05-08)

**Goal:** Automatically sync Kindle Scribe handwritten/typed notes to the Obsidian vault so notes taken on the Scribe appear on all synced devices (MacBook, Mac mini, iPhone, eventually Windows work laptop).

**How it works:** Scribe exports a notebook as TXT via email (Share → Send to email). A script fetches those emails, extracts the text, and routes it to the correct vault folder based on the notebook name.

**Existing infrastructure:**
- Vault structure + templates: `scripts/setup/setup-obsidian.sh`
- Routing rules documented: `docs/guides/NOTES.md` (Kindle Scribe → Obsidian Routing table)
- Syncthing sync: TODO #7

**To build — `pkm/kindle_sync.py` (IMAP-based, provider-agnostic):**

1. Connect to email via IMAP (works with any provider — Gmail now, easy to switch later)
2. Search for unread emails from `do-not-reply@amazon.com` with subject containing "from your Kindle"
3. Parse email subject to extract notebook name
4. Download TXT content from the download link in the email body
5. Route to correct vault folder using keyword matching (same rules as `docs/guides/NOTES.md`)
6. Save as `.md` with frontmatter:
   ```yaml
   ---
   source: Kindle Scribe
   exported: YYYY-MM-DD
   notebook: [original notebook name]
   ---
   ```
7. Filename: `YYYY-MM-DD_NotebookName.md` (append `_v2`, `_v3` if exists — never overwrite)
8. Mark email as read after processing
9. Optional: git commit + push to `obsidian-vault` private repo

**Directory structure:**
```
pkm/
├── kindle_sync.py       # main script
├── config.py            # IMAP creds, vault path, routing rules, toggles
└── requirements.txt     # imaplib is stdlib, requests for download link
```

~~Steps completed (2026-05-08):~~
- Script at `pkm/kindle_sync.py` — IMAP-based, provider-agnostic
- Exports as **Searchable PDF** from Scribe → email → script grabs `.txt` + `.pdf`
- Saves to `📥 Imports/YYYY-MM-DD_HH-MM_name.md` + `.pdf` attachment
- Hourly cron job running, logs to `~/logs/kindle-sync.log`
- Gmail app password configured in `pkm/config.py` (gitignored)


### ~~19. T7 → T5 full backup~~ — done (2026-07-09)

**What was done:**
- Renamed T5 volume from `ImmichBackup` → `Backup` (`diskutil rename`)
- Created `scripts/backup/backup-t5.sh` — rsync T7 → T5 covering:
  - `/Volumes/T7/immich/upload` → `/Volumes/Backup/immich/upload` (photos)
  - `/Volumes/T7/audiobooks` → `/Volumes/Backup/audiobooks`
  - `/Volumes/T7/calibre-books` → `/Volumes/Backup/calibre-books`
  - Skips `/Volumes/T7/media/` — movies/TV too large for 500GB T5
- Updated cron: 3am daily now runs `backup-t5.sh` (replaces `backup-immich.sh`)
- Fixed `backup-immich.sh` path references from `/Volumes/ImmichBackup` → `/Volumes/Backup`

**Recovery posture as of 2026-09-05** (superseded by the NAS migration — kept for history;
current posture is in the Drive Layout section below):
| If... | Photos | Audiobooks | Books | Services config |
|-------|--------|------------|-------|----------------|
| NAS fails | T7 + T5 | T7 + T5 | T7 + T5 + R2 | R2 |
| A drive fails | re-run `backup-external.sh` | same | same | R2 |
| Fire/theft | nothing offsite (all in one room) | nothing offsite | R2 | R2 |

**The real remaining gap:** both external drives sit next to the NAS, so nothing survives
fire, flood or theft. Moving T5 offsite is what makes this genuinely 3-2-1.


---

## Done

- [x] ~~Books & audio automation (Jul 2026)~~ — LazyLibrarian fully configured: 4 Torznab indexers via Prowlarr, Transmission download client, PostProcessor auto-moves EPUBs to Calibre and MP3s to Audiobookshelf. Click "Wanted" → fully hands-off. See `docs/guides/BOOKS.md` for setup notes and gotchas.

- [x] ~~Kindle library → Calibre-Web (Apr 2026)~~ — ~30 purchased books converted to EPUB and imported into Calibre-Web
- [x] ~~Calibre-Web — organising books (Apr 2026)~~ — year-end books processed and organised
- [x] ~~Media stack setup~~ — Sonarr/Radarr/Prowlarr/Transmission/Jellyfin fully connected, remote path mapping fixed, Narcos S1-S3 downloaded and playing
- [x] ~~Cloudflare DNS cleanup~~ — deleted stale CNAMEs: `sync`, `portainer`, `ai`, `sonarr`, `radarr`, `prowlarr`, `downloads`
- [x] ~~Cloudflare Access (wildcard)~~ — removed `*.peciulevicius.com` Zero Trust gate; was breaking all native apps (Bitwarden, Immich, etc.). Each service has its own login screen — Access wasn't needed.
- [x] ~~Cloudflare Access (Glance only)~~ — added Access policy on `home.peciulevicius.com` only. GitHub SSO (primary) + email OTP (fallback). 1-month session. Other services unaffected.
- [x] ~~Homarr → Glance migration~~ — replaced Homarr with Glance (YAML config, responsive). Four pages: Home, Feed, Media, Finance.
- [x] ~~Glance internal links~~ — fixed `host.docker.internal` → Tailscale IP (`100.81.171.49`) so all links work from any device (phone, laptop, etc.)
- [~] Actual Budget — was marked removed in favour of Wallet by Budget Bakers, but the `actual-budget` container is **still running** as of 2026-09-05. Either finish removing it or drop the strikethrough; right now the notes and reality disagree.
- [x] ~~Passkey migration~~ — all 5 services (Amazon, Binance, GitHub, Google, PSN) re-registered with Bitwarden
- [~] Karakeep — tried as a Linkwarden replacement and reverted, but `karakeep`, `karakeep-chrome` and `karakeep-meilisearch` are **still running** as of 2026-09-05 (three containers' worth of RAM). Either stop them or drop the strikethrough.
- [x] ~~Linkwarden~~ — restored as primary bookmark manager on port 3005, `links.peciulevicius.com`
- [x] ~~Grafana + Prometheus configured~~ — datasource connected, dashboards imported, password set
- [x] ~~Bazarr connected~~ — Sonarr/Radarr API keys configured, subtitle provider still needed
- [x] ~~Kindle library → Calibre-Web (Apr 2026)~~ — ~30 purchased books converted to EPUB in Calibre and synced to the Mac mini Calibre-Web
- [x] ~~Audible AAX → Audiobookshelf (Apr 2026)~~ — converted 28 AAX audiobooks to M4B via `scripts/convert-audiobooks.sh` (ffmpeg stream copy, chapters preserved). Synced to Mac mini Audiobookshelf.
- [x] ~~B2 backup cleanup (Apr 2026)~~ — deleted Immich photos (7GB), Linkwarden (644MB), Audiobookshelf (890MB) from B2. Down from 9.7GB to 1.2GB. Immich backup disabled (using T5 local). Script fixed: `pipefail` + error counter.
- [x] ~~Cloudflared plist fix~~ — brew service was missing `tunnel run` args, created proper `com.cloudflare.cloudflared.plist` launch agent
- [x] ~~Docker Desktop watchdog~~ — `scripts/utils/docker-watchdog.sh` + launchd agent runs every 5min; restarts Docker Desktop if containers lose internet (Docker proxy dies intermittently)
- [x] ~~NordPass cancelled~~ — subscription ended, passwords in Vaultwarden
- [x] ~~Jellyseerr~~ — media request/discovery UI for Jellyfin (Tailscale-only, port 5055)
- [x] ~~Bazarr~~ — automated subtitle management for Sonarr/Radarr (Tailscale-only, port 6767)
- [x] ~~Grafana + Prometheus~~ — monitoring stack with Node Exporter (Tailscale-only, ports 3000/9090/9100)
- [x] ~~Restart stopped services~~ — all 33 containers confirmed running (all have `restart: unless-stopped`)
- [x] ~~Homarr cleanup~~ — removed containers, images, Docker network, updated setup script
- [x] ~~Tunnel security split~~ — moved Sonarr/Radarr/Prowlarr/Transmission to Tailscale-only, added Portainer to public tunnel
- [x] ~~Mealie~~ — setup complete
- [x] ~~Linkwarden~~ — setup complete, browser extensions installed (Chrome; Brave needs Shields disabled for the site), phone PWA added
- [x] ~~Calibre-Web `metadata_dirtied` bug~~ — fixed: ran `CREATE TABLE` SQL
- [x] ~~Radarr Docker volumes~~ — compose already has `/media` mount
- [x] ~~Pi-hole 403 on root~~ — fixed: lighttpd redirect config mounted
- [x] ~~Transmission credentials~~ — changed from defaults (see .env on Mac Mini)
- [x] ~~Homarr dashboard~~ — configured with all services, organized into categories (Main, Media, Utilities, System, Direct Access)
- [x] ~~Linkwarden bookmarks~~ — 621 bookmarks imported (services + browser bookmarks)
- [x] ~~Uptime Kuma monitors~~ — all services monitored
- [x] ~~Ollama + Open WebUI~~ — removed (not enough RAM, using Claude instead)
- [x] ~~NordPass → Vaultwarden~~ — passwords migrated, subscription cancelled (Apr 2026)
- [x] ~~Radarr/Sonarr auto-cleanup~~ — `removeCompletedDownloads` + `removeFailedDownloads` enabled via API
- [x] ~~Ollama/Open WebUI containers~~ — stopped, removed from setup-services.sh
- [x] ~~Audiobookshelf subdomain~~ — fixed: books → listen
- [x] ~~B2 cloud backup~~ — nightly cron at 5am, services + obsidian-vault + Immich photos all backed up
- [x] ~~Immich photos B2 backup~~ — added `/Volumes/T7/immich/upload` to rclone-backup.sh
- [x] ~~Disk full (Apr 2026)~~ — T7 at 100% (17MB free). Cleared 480GB duplicate downloads from `downloads/complete/`, deleted 156GB old photo copies from APFS `TimeMachine` volume, removed 2.5GB ollama-models. Now at 140GB free.
- [x] ~~SSH enabled~~ — Remote Login turned on via System Settings, `ssh macmini` works via Tailscale
- [x] ~~Jellyfin delete fix~~ — removed `:ro` from media volume mounts so Jellyfin can delete files
- [x] ~~mac-mini.sh expanded~~ — added `services up/down/restart/status`, `cleanup`, `disk`, `ssh on/off` commands
- [x] ~~Ollama containers still running~~ — `ollama` and `open_webui` still in `~/services/ollama/`, should remove when home

---
## 2026-09-29 — BudgetBakers finance view + private AI summaries

### Wallet page-size fix and private health checks

The Wallet API accepts up to 200 items per page for accounts and categories,
but rejects a 200-item request for budgets with HTTP 400 (`limit must be at
most 20`). `finance-status.sh` uses a 20-item page for budgets and retains
200-item pages for the other collections. Confirmed against the saved token:
the provider returns `ok: true`; token and account values were not printed.
The follow-up `--health` mode reads cached provider booleans without fetching
or printing balances, positions, error text or credentials. Setup instructions
now use it instead of printing credential files. Corrected the stale TODO
claim that Wallet still needed a token. See `services/glance/README.md`.

Live morning verification, 2026-09-30: the 07:00 scheduled refresh produced
a healthy, configured, non-stale Wallet provider in the actual Glance feed.
The private daily snapshot exists and was written at 07:05. IBKR remains
unconfigured pending its credentials. Only health booleans and file metadata
were inspected; no generated amounts were copied into the repository.

- Extended `finance-status.sh` with BudgetBakers Wallet's read-only REST API
  (bearer token), account balances, current-month budget versus actual, and
  separate provider caches (IBKR 30m; Wallet 6h). Combined net worth and the
  provider breakdown feed Glance's Portfolio widget; unavailable providers
  remain explicit and stale data is retained on fetch errors.
- Added private daily finance snapshots under `~/ai-memory/finance/` and a
  README with agent read-only rules. Cron runs the snapshot job after the
  finance refresh. Credentials and generated amounts stay outside this repo.
- Added setup docs and a TODO for the user's Wallet token and remaining IBKR
  setup. No credentials were added.


## 2026-09-30 — replace Wallet aggregation with direct broker reports

- Removed BudgetBakers Wallet requests, balances and budgets from the finance
  collector, Glance card and new private summaries at the user's request. The
  earlier HTTP 400 fix succeeded at transport level; it did not reconcile
  Wallet's amounts against the user's accounts.
- Added Trading 212's read-only account-summary API beside IBKR Flex. Values,
  dates and status are separate per broker. The EUR total covers connected
  investments, not full personal net worth. Neither broker has credentials
  configured yet; setup and numerical reconciliation remain user tasks.
- IBKR now rejects missing NAV, missing currency, non-finite values and
  multi-account reports. Removed misleading daily P&L/unrealised percentages.
  Trading 212's reported total is used once, without adding cash/holdings again.
- Native caches are private and credential-specific, stale fetches remain
  labelled, and controlled errors cannot echo request tokens. Snapshot
  comparisons require matching source coverage/schema/currency and fresh,
  complete data; legacy Wallet records are not treated as portfolio history.
- Live follow-up: replaced only the staged Glance Portfolio widget, recreated
  Glance with its existing image, regenerated the served JSON and today's
  private summary, and archived obsolete served caches outside the assets
  directory. Private originals are backed up. The refreshed feed contains
  IBKR/Trading 212 only, both honestly unconfigured; no Wallet values remain.
- Validation: Python/Bash syntax, ShellCheck, cached-health privacy checks,
  offline account-total/FX/cache/rotation/report/snapshot checks. Live broker
  balances are not verified until their credentials are connected.


## 2026-09-30 — temporary Paperclip subscription takeover

- A real Codex request exposed a revoked container refresh token despite the
  CLI's logged-in status. The account owner completed a new device login;
  real subscription probes then passed in all three companies.
- Temporarily switched all ten active unbound Claude roles to the existing
  Codex subscription on their same agent IDs. Paused roles and OpenRouter
  roles were preserved. No tasks were triggered. All 31 current agents still
  pass the shared-memory guidance check.
- Original Opus/Sonnet models and complete configs are saved before each
  PATCH in private atomic state. The helper refuses paid-key/managed routes,
  busy targets and concurrent config changes, and retains recovery intent on
  partial failures. Codex uses the workspace sandbox and CLI engine.
- Installed a staged recovery helper and a five-minute cron check without
  changing any existing jobs. It survives repo branch changes and makes no
  probes until Thursday, 1 October, 11:00 Vilnius. Claude must answer a real
  probe before any original is restored; failures retry hourly. No automatic
  paid fallback or all-provider routing was enabled.
- Upstream issue #14023 and PR #14027 already cover binding removal and
  unchanged-binding validation; both remain open. No duplicate was filed.
- Validation: Python syntax; offline exact switch/restore, saved-state,
  deadline, quota failure, concurrent-edit and timeout scenarios; live Codex
  probes, ten verified PATCH responses, recovery preview and installed cron
  verification. The real return to Claude waits for tomorrow's reset.
