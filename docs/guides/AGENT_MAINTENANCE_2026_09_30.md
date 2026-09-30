# Agent maintenance handoff — 2026-09-30

Morning status checked on the Mac mini after the 07:00 finance refresh and
07:05 private snapshot. Source changes are in focused PRs; none were merged.
Read the service runbooks for current procedures, since this is a dated record.

## What is live

| Area | Verified result |
|---|---|
| Paperclip | Approved binding-comparison patch is running; health is `ok`. Five reporting links, three open issue assignments and three routines now point to the replacements. |
| Coach routine | The scheduled 06:30 run succeeded at 06:33 on the current Claude Sonnet agent. Studio standup remains paused. |
| Recovery state | `active: false`, no switched or unconfirmed agents, no pending reconciliation. Automatic switching remains off. |
| Shared memory | All 31 current Paperclip agents have the shared guidance; a fresh preview reports zero pending writes. Private originals were backed up before installation. |
| Discord identities | The legacy jobs webhook is named **Homelab Jobs**. Kuma explicitly sends as **Uptime Kuma** and its repeat alerts are disabled. |
| Wallet | Actual Glance feed refreshed at 07:00: Wallet is configured, healthy and not stale. The private daily snapshot was written at 07:05. IBKR is still unconfigured. |

Paperclip had no active or queued runs at the morning check. This does not
prevent an assignment or routine from starting another run later.

## Pull requests

| PR | Changes |
|---|---|
| [41 — Wallet](https://github.com/peciulevicius/.dotfiles/pull/41) | Budget pages use the API's 20-item maximum. Added cached health output that omits balances, holdings, credentials and error text. Corrected the stale token TODO and recorded the live morning refresh. |
| [42 — Paperclip recovery](https://github.com/peciulevicius/.dotfiles/pull/42) | Rehire/reference repairs, guarded server binding comparison, retired-record preflight, quota classification, process lock, private atomic state writes, pre-PATCH recovery journal and budget checks. Includes restore constraints and sidebar instructions. |
| [43 — Shared AI guidance](https://github.com/peciulevicius/.dotfiles/pull/43) | `AGENTS.md`/`CLAUDE.md` entry points, documentation and memory rules, reusable instruction rollout, CLI approval guidance. Fixed the failed strict documentation build on the original branch. |
| [44 — Discord](https://github.com/peciulevicius/.dotfiles/pull/44) | Separate routes/senders, idempotent channel/category migration, preserved permissions/history, Dietitian typo correction, bridge lookup of current hires, notification runbooks. |
| [45 — PR reviews](https://github.com/peciulevicius/.dotfiles/pull/45) | Guarded subscription-based Claude review workflow, shared review rules and Codex/Claude activation guide. Account setup remains required. |
| [46 — TODO corrections](https://github.com/peciulevicius/.dotfiles/pull/46) | Removed stale media restart/advice, corrected completed Tailscale work and power-loss recovery documentation, updated the Claude audit skill. |
| [47 — Combined draft](https://github.com/peciulevicius/.dotfiles/pull/47) | Checks the focused changes together. Review and merge the focused PRs individually; close this draft after they land. |

The host's cron executes scripts directly from `~/.dotfiles`. Its checkout is
left on `preview/overnight-fixes-2026-09-30` so the fixes coexist. Switching it
back to an older branch before the focused changes land can restore older cron
code. Main was not changed. Separately staged `~/services` files are copies;
they are not updated merely by changing the repository.

## Provider switching and model audit

This installation does **not** yet provide a reliable Claude ↔ Codex →
OpenRouter automatic chain. `AUTO_SWITCH=0` stays in effect. The watchdog
detects recognized Claude quota failures and notifies; it does not mistake
generic 429, login, context, turn or budget failures for an exhausted plan.

The remaining restore constraints are concrete:

- The managed binding's validation can fail while the separate host-login
  test passes. They can use different credentials and environments.
- The PATCH route preserves an existing AI binding when the request omits it
  or sends null. A saved unbound original therefore cannot clear OpenRouter
  with that request.
- The deployed binding-order patch fixes unchanged-binding comparisons; it
  does not prove a cross-provider round trip works.
- A manual fallback now requires an existing active monthly billed-cost hard
  stop of $3 or less, with remaining budget. It never raises or creates a cap.
  A running request can still overshoot before its cost is reported.

Original configurations are saved before a switch request. A lost response
leaves an unconfirmed journal entry; inspect it with `--reconcile` before any
recovery probe. Reconciliation preserves unknown or concurrent changes.

The 31 current agents are configured as follows; these are configuration facts,
not a benchmark of which model is best:

| Configuration | Agents |
|---|---:|
| Claude Opus 5 | 3 |
| Claude Sonnet 5 | 9 |
| Codex, model not explicitly set | 8 |
| OpenRouter DeepSeek v3.2 | 8 |
| OpenRouter Gemini 3.5 Flash Lite | 2 |
| OpenRouter Qwen3 Coder | 1 |

All 11 current OpenRouter agents have active $3 monthly hard-stop policies.
The subscription roles have no such paid-fallback policies yet, so the guarded
manual switch will skip them until a policy is explicitly configured. The
eight Codex agents rely on defaults; inspect their actual successful run model
before pinning one. No live model, budget or pause/resume settings were changed
during this audit, and no benchmark runs were started.

## Shared memories and skills

Claude Code and Codex on this Mac mini can read `~/ai-memory`; Paperclip and
Odysseus use `/ai-memory`. Read its README and relevant project/domain note.
The folder provides durable handoffs, not shared live chat state. All current
Paperclip agents now receive instructions to use it. Cross-company access is
possible; the ownership/privacy rules are instructions, not filesystem ACLs.

Portable `SKILL.md` content can be reused across tools. Existing Claude skill
folders are not automatically discovered by host Codex. Paperclip injects its
assigned company skills at run time. See
[AI collaboration](../AI_COLLABORATION.md) for the paths and boundaries.

## Checks and how to verify

CI checked documentation, shell lint and secrets on the focused PRs and combined
tree. The original `e8c2c5c` documentation failure in PR 43 is fixed. The Claude
review job is intentionally skipped while activation is disabled.

Offline simulations covered Discord's permission guard, retained channel IDs
and permissions, private config modes, idempotent migration and no messages;
watchdog quota classification, corrupt-state preservation, budget gates,
pre-PATCH journals, lost/refused requests and concurrent changes; and cached
finance health output with private data omitted. No repository test suite was
added. These offline checks used no live notifications or paid provider requests.

From the Mac mini repository root:

```bash
bash scripts/utils/paperclip-fallback.sh --status
python3 scripts/utils/paperclip-memory-guidance.py
python3 scripts/utils/configure-discord-notifications.py
bash scripts/utils/finance-status.sh --health
```

Expect an inactive fallback with empty switched/unconfirmed lists; 31 memory
entries already configured and zero pending writes; a Discord plan that stops
with exit 2 while permissions are missing; and healthy Wallet booleans with no
amounts printed. In Glance, open **Finance** and confirm its update time. In
Paperclip, inspect the current Coach's successful 06:30 run and the repaired
organization chart. These previews start no agent runs.

## Setup still needed

1. **Discord:** Server Settings → Roles → **COACH_BOT** → enable **Manage
   Channels** and **Manage Webhooks**. Administrator is not needed. Then run
   the migration preview and `--apply`. It creates **Homelab** and **AI**
   categories; separates uptime/jobs/agent/reminder channels; moves existing
   coaching channels and fixes the Dietitian typo while retaining IDs/history.
   The installed monthly reminder cron line also needs its prepared route
   argument when the reviewed crontab is installed.
2. **Retired agents:** all 11 obsolete Coach/Studio records pass current
   reference checks. They remain paused because termination is irreversible
   and the specific approval is still pending. The old Homelab Lead is excluded
   from that plan; no history was deleted.
3. **PR reviews:** connect the repository in Codex hosted review settings.
   For Claude, create/upload `CLAUDE_CODE_OAUTH_TOKEN`, enable
   `CLAUDE_PR_REVIEW_ENABLED`, and merge the reviewed workflow when ready.
   GitHub currently has neither the secret nor enable flag. Follow
   [PR review setup](PR_REVIEWS.md).
4. **Sidebar:** Settings → Experimental → **Streamlined UI** off restores the
   fuller legacy navigation. This presentation setting affects the instance;
   it is currently on. No UI build change was applied.
5. **Other credentials/devices:** IBKR Flex setup, Odysseus's current admin
   password/2FA, hardware checks and destructive maintenance remain in the TODO.

For remaining CLI command approval pop-ups, use `/permissions` → **Approve for
me**, or resume the installed CLI with:

```bash
codex --approve-for-me resume --last
```

Routine saved approvals were reused. Repository guidance cannot change the
active client's sandbox permission mode.
