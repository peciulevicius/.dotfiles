# Agent maintenance handoff — 2026-09-30

Morning status checked on the Mac mini after the 07:00 finance refresh and
07:05 private snapshot. Source changes are in focused PRs; none were merged.
Read the service runbooks for current procedures, since this is a dated record.

**Follow-up, 10:50 Vilnius:** Wallet was removed at the user's request. Glance
now has direct IBKR/Trading 212 feeds; both need read-only credentials. A fresh
Paperclip Codex device login fixed its revoked refresh token. Ten active
unbound Claude roles now temporarily use Codex on their existing IDs. Original
Opus/Sonnet configs are saved; a staged cron check starts guarded recovery
after **Thursday, 1 October, 11:00 Vilnius**. Failed Claude probes retry hourly.
This update supersedes the earlier Wallet and Claude runtime observations.

**Follow-up, 11:30 Vilnius:** Kraken's read-only connector is in PR #49 and
the combined preview. The live widget, feed and private summary now include
IBKR, Trading 212 and Kraken, all unconfigured until owner credentials are
added. Glance returned HTTP 200 after the targeted update. The recovery helper
matches its repository source, has private permissions and exactly one cron
entry. All nine open PRs had passing checks and no merge conflicts; none
were merged. Automatic Claude/Codex code reviews still need activation.

## What is live

| Area | Verified result |
|---|---|
| Paperclip | Approved binding-comparison patch is running; health is `ok`. Five reporting links, three open issue assignments and three routines now point to the replacements. |
| Coach routine | Before the Codex takeover, the scheduled 06:30 run succeeded at 06:33 on the recovered Claude Sonnet agent. Studio standup remains paused. |
| Recovery state | Legacy OpenRouter watchdog is inactive. The separate subscription-switch helper tracks ten temporary Codex roles and their original settings. Automatic all-provider routing remains off. |
| Shared memory | All 31 current Paperclip agents have the shared guidance; a fresh preview reports zero pending writes. Private originals were backed up before installation. |
| Discord identities | The legacy jobs webhook is named **Homelab Jobs**. Kuma explicitly sends as **Uptime Kuma** and its repeat alerts are disabled. |
| Finance | Wallet removed from live Glance, served data and today's private summary. IBKR/Trading 212/Kraken each show unconfigured; account balances have not been reconciled. Kraken estimates EUR value from wallet quantities and spot midpoints. Historical Wallet summaries are excluded from new comparisons. |

Paperclip had no active or queued runs at the morning check. This does not
prevent an assignment or routine from starting another run later.

## Pull requests

| PR | Changes |
|---|---|
| [41 — Direct finance feeds](https://github.com/peciulevicius/.dotfiles/pull/41) | Replaces Wallet with direct IBKR/Trading 212 summaries, separate source/status/date, private native caches and coverage-aware daily memory. Live widget/feed migrated; credentials and account reconciliation remain user steps. |
| [42 — Paperclip recovery](https://github.com/peciulevicius/.dotfiles/pull/42) | Rehire/reference repairs and guarded binding comparison, plus the reversible same-ID Codex takeover and staged scheduled recovery. Originals are saved before writes; concurrent edits and failed probes retain them. |
| [43 — Shared AI guidance](https://github.com/peciulevicius/.dotfiles/pull/43) | `AGENTS.md`/`CLAUDE.md` entry points, documentation and memory rules, reusable instruction rollout, CLI approval guidance. Fixed the failed strict documentation build on the original branch. |
| [44 — Discord](https://github.com/peciulevicius/.dotfiles/pull/44) | Separate routes/senders, idempotent channel/category migration, preserved permissions/history, Dietitian typo correction, bridge lookup of current hires, notification runbooks. |
| [45 — PR reviews](https://github.com/peciulevicius/.dotfiles/pull/45) | Guarded subscription-based Claude review workflow, shared review rules and Codex/Claude activation guide. Account setup remains required. |
| [46 — TODO corrections](https://github.com/peciulevicius/.dotfiles/pull/46) | Removed stale media restart/advice, corrected completed Tailscale work and power-loss recovery documentation, updated the Claude audit skill. |
| [47 — Combined draft](https://github.com/peciulevicius/.dotfiles/pull/47) | Checks the focused changes together. Review and merge the focused PRs individually; close this draft after they land. |
| [48 — This handoff](https://github.com/peciulevicius/.dotfiles/pull/48) | Dated live status, source changes, checks and remaining owner steps. |
| [49 — Kraken](https://github.com/peciulevicius/.dotfiles/pull/49) | Stacked on #41. Query Funds-only default-wallet collector, indicative EUR prices, private nonce/cache recovery, explicit coverage and hidden setup prompts. Widget/feed staged live; credentials remain an owner step. |

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

For today's unbound subscription roles, use:

```bash
python3 scripts/utils/paperclip-subscription-switch.py --status
python3 scripts/utils/paperclip-subscription-switch.py --restore
```

The second command previews exact original configurations. Recovery after
the saved reset time requires a real Claude response before applying them.
The staged helper survives a Git checkout change. Paused roles and managed
bindings are excluded; duplicate hires are unnecessary for this takeover.

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

The 31 current agents are configured after the takeover as follows; these are configuration facts,
not a benchmark of which model is best:

| Configuration | Agents |
|---|---:|
| Claude Sonnet 5 (paused managed roles) | 2 |
| Codex, model not explicitly set (10 temporary + 8 existing) | 18 |
| OpenRouter DeepSeek v3.2 | 8 |
| OpenRouter Gemini 3.5 Flash Lite | 2 |
| OpenRouter Qwen3 Coder | 1 |

All 11 current OpenRouter agents have active $3 monthly hard-stop policies.
The subscription roles have no such paid-fallback policies yet, so the guarded
manual switch will skip them until a policy is explicitly configured. The
Codex agents rely on defaults; inspect actual successful run models before
pinning a role/model split. The takeover changed ten runtimes and preserved
pause/resume settings and paid budgets. No benchmark runs were started.

## Shared memories and skills

Claude Code and Codex on this Mac mini can read `~/ai-memory`; Paperclip and
Odysseus use `/ai-memory`. Read its README and relevant project/domain note.
The folder provides durable handoffs, not shared live chat state. All current
Paperclip agents now receive instructions to use it. Cross-company access is
possible; the ownership/privacy rules are instructions, not filesystem ACLs.

Portable `SKILL.md` content can be reused across tools. Existing Claude skill
folders are not automatically discovered by host Codex. Paperclip injects its
assigned company skills at run time. See
[AI collaboration guide in PR 43](https://github.com/peciulevicius/.dotfiles/pull/43)
for the paths and boundaries.

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
python3 scripts/utils/paperclip-subscription-switch.py --status
python3 scripts/utils/paperclip-memory-guidance.py
python3 scripts/utils/configure-discord-notifications.py
bash scripts/utils/finance-status.sh --health
```

Expect an inactive legacy fallback with empty switched/unconfirmed lists;
the separate subscription journal shows ten switched roles until Claude
recovery succeeds; 31 memory entries already configured with zero pending
writes; and a Discord plan that stops with exit 2 while permissions are
missing. Finance health shows IBKR, Trading 212 and Kraken unconfigured,
without errors or balances. This is expected until credentials are saved.
In Glance, open **Finance** and confirm its update time and three provider
rows. In Paperclip, inspect the current Coach's Codex adapter and repaired
organization chart. A normal message to Coach can verify the next real run;
the status previews themselves start no runs. After Thursday's reset, the
journal should empty only when real Claude probes and exact restores succeed.

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
   [PR review setup in PR 45](https://github.com/peciulevicius/.dotfiles/pull/45).
4. **Sidebar:** Settings → Experimental → **Streamlined UI** off restores the
   fuller legacy navigation. This presentation setting affects the instance;
   it is currently on. No UI build change was applied.
5. **Finance:** follow `services/glance/README.md` → Finance to save IBKR
   Flex, Trading 212 and Kraken read-only credentials with hidden prompts.
   Refresh and compare each account's quantities/value against its app before
   relying on the total. Kraken covers the default wallet and does not supply
   cost basis or unrealised P&L. Trading 212 holdings detail is still a TODO.
6. **Other credentials/devices:** Odysseus's current admin
   password/2FA, hardware checks and destructive maintenance remain in the TODO.

For remaining CLI command approval pop-ups, use `/permissions` → **Approve for
me**, or resume the installed CLI with:

```bash
codex --approve-for-me resume --last
```

Routine saved approvals were reused. Repository guidance cannot change the
active client's sandbox permission mode.
