# Cron jobs (Mac mini)

`crontab` in this directory is the authoritative copy of the Mac mini's
schedule. The live crontab is not stored anywhere else, so edit this file,
install it, and commit.

## Install

```bash
crontab < ~/.dotfiles/scripts/cron/crontab
crontab -l          # always read it back
```

⚠️ **`crontab <file>` silently fails on macOS** when the file sits outside your
home directory — it exits 0 and installs an *empty* crontab. Always pipe via
stdin (`crontab < file` or `cat file | crontab -`) and always verify with
`crontab -l` afterwards.

## What runs

| When | Job | Log |
|---|---|---|
| Sunday 04:00 | Database dumps → `~/backups/` | `~/logs/db-backup.log` |
| Daily 05:00 | rclone → Cloudflare R2 (runs `~/services/rclone/rclone-backup.sh`) | `~/logs/rclone-backup.log` |
| Monthly, 1st 06:00 | R2 restore spot-check + size history (`scripts/backup/r2-verify.sh`) | `~/logs/r2-verify.log` |
| Hourly | Kindle Scribe → Obsidian vault | `~/logs/kindle-sync.log` |
| Every 5 min | Heartbeat to Healthchecks.io (`heartbeat.sh`) — alerts from outside when pings stop, or when Docker is unresponsive | `~/logs/heartbeat.log` |
| Every 5 min | Host health snapshot for Glance (`homelab-status.sh`) | `~/logs/homelab-status.log` |
| Every 5 min | Calendar status snapshot for Glance (`calendar-status.sh`) | `~/logs/calendar-status.log` |
| Daily 07:00 | Finance providers → Glance portfolio (`finance-status.sh`) | `~/logs/finance-status.log` |
| Daily 07:05 | Private finance summary in `~/ai-memory` (`finance-memory-snapshot.sh`) | `~/logs/finance-memory-snapshot.log` |
| Every 15 min | Commit shared `~/ai-memory` edits (`ai-memory-commit.sh`) | `~/logs/ai-memory.log` |
| Sunday 09:00 | Homelab audit — drift, containers, backups, disk, secrets (`homelab-audit.sh`) | `~/logs/homelab-audit.log` |
| Sunday 09:30 | Paperclip reports feed — read-only snapshot for the Homelab agents (`paperclip-reports.sh`) | `~/logs/paperclip-reports.log` |
| Daily 06:30 | Image updates → Glance "Updates" widget (`update-report.sh`, reads WUD) | `~/logs/update-report.log` |
| Monday 09:00 | Weekly image-update summary to Discord (`update-report.sh --discord`) — a report, not an auto-update; upgrade with `upgrade-service.sh` | `~/logs/update-report.log` |
| Every 5 min | Paperclip usage-limit watchdog (notifications only; automatic switching is off) | `~/logs/paperclip-fallback.log` |
| Every 5 min | Guarded temporary Claude subscription restore (acts only after its saved due time and successful probe) | `~/logs/paperclip-subscription-switch.log` |
| Monthly, 1st 10:00 | Reminder to review prepaid AI credits | `~/logs/monthly-reminder.log` |

The schedule was compared with the live crontab on 2026-09-30. The old
30-minute Jellyfin/Audiobookshelf restart is removed; no SMB rescan or recurring
media-service restart runs now.

⚠️ **Check before reinstalling.** Until 2026-09-24 this file had fallen
behind the live schedule — it still pointed the backup at the repo copy and was
missing the two bottom jobs. Reinstalling it would have silently reverted the
2026-09-23 fix. `homelab-audit.sh` now diffs `crontab -l` against this file
weekly; to check by hand:

```bash
diff <(crontab -l | grep -v '^#' | grep . | sort) \
     <(grep -v '^#' ~/.dotfiles/scripts/cron/crontab | grep . | sort)
```

External drives have **no** cron job — they aren't permanently plugged in.
Instead `backup-external.sh` stamps `~/logs/external-backup-<drive>.last` on
success and the weekly audit fails once a drive's stamp is over 30 days old.

⚠️ **The backup job runs the staged copy in `~/services/rclone/`, and reads
`~/services/rclone/.env`** — the same place every service keeps its `.env`.
Until 2026-09-23 cron pointed at the repo copy instead, which read a second,
stale `.env`: the Immich photo backup was enabled in one file and silently off
in the one cron used. One script path, one `.env`.

The Kindle sync is hourly on purpose: Amazon's share links expire after 7 days,
so a slow poll loses exports.

## Notifications

Every job runs through [`../utils/run-with-notify.sh`](../utils/run-with-notify.sh),
which posts to Discord when a job **starts** failing and again when it
**recovers** — not on every run, so an hourly job that breaks sends one message
instead of 24 a day. If it stays broken it re-nags once every `REMIND_HOURS`
(default 24).

Keep uptime alerts, jobs, agent events and reminders separate:

| Sender | Channel | Private config key |
|---|---|---|
| Uptime Kuma | `#uptime-alerts` | Stored in Kuma; not used by jobs |
| Homelab Jobs / Homelab Updates | `#homelab-jobs` | `DISCORD_JOBS_WEBHOOK_URL` |
| Paperclip | `#ai-agents` | `DISCORD_AGENTS_WEBHOOK_URL` |
| Homelab Reminders | `#homelab-reminders` | `DISCORD_REMINDERS_WEBHOOK_URL` |

The migration groups uptime, jobs and reminders under **Homelab**, and agent
events plus the existing Coach/Dietitian chats under **AI**. It fixes the
`ai-training-dietitial` spelling without replacing the channel: messages,
threads, webhook URLs and bridge IDs survive. Existing channel permission
overrides are preserved; new destinations copy the current homelab channel's
overrides. No channels or messages are deleted.

For the existing shared webhook, preview and migrate with:

```bash
python3 ~/.dotfiles/scripts/utils/configure-discord-notifications.py
python3 ~/.dotfiles/scripts/utils/configure-discord-notifications.py --apply
```

The migration uses the bridge bot's private token. Its server role needs
**Manage Channels** and **Manage Webhooks** (also allowed in the target
category/channels). It reuses matching channels and its own webhooks, moves
Kuma's existing webhook without changing Kuma's saved URL, and saves private
job URLs with mode 600. A failure can leave some channels created; rerun to
finish. It does not post test messages. Applied live on 2026-09-30; the bot
already had the required permissions. The first channel move returned HTTP
403 because the request resent unchanged permission overrides; the migration
was corrected to leave them untouched and then completed successfully.
Read-only API checks confirmed the channels, webhooks and Kuma destination;
message delivery still needs the Kuma UI test.

In Discord: **Server Settings → Roles → COACH_BOT → Permissions**, enable
**Manage Channels** and **Manage Webhooks**, then save. Allow these in target
category overrides too if denied there. Administrator is unnecessary.
After applying, use Kuma's notification **Test** button: only `#uptime-alerts`
should receive its message. For a job route check, run in Bash:

```bash
source ~/.dotfiles/scripts/lib/notify.sh
notify_discord "Routing check" "Manual job notification test" info jobs
```

Repeat with `agents` or `reminders` as the fourth argument to check those
destinations. To test two-way chat, use the bridge README's one-line message;
that invokes an agent and consumes its normal usage allowance.

For manual configuration, create one webhook per destination and save:

```bash
mkdir -p ~/.config/homelab
cat > ~/.config/homelab/notify.env <<'EOF'
DISCORD_JOBS_WEBHOOK_URL=https://discord.com/api/webhooks/...
DISCORD_AGENTS_WEBHOOK_URL=https://discord.com/api/webhooks/...
DISCORD_REMINDERS_WEBHOOK_URL=https://discord.com/api/webhooks/...
EOF
chmod 600 ~/.config/homelab/notify.env
```

The legacy `DISCORD_WEBHOOK_URL` remains a jobs fallback; the migration points
it at the jobs webhook so old scripts cannot post through Kuma. Before
migration, routes without their own webhook still share that destination, but
the helper sets separate sender names. `notify_discord title message level
route` selects a route (default `jobs`); unknown routes are ignored. Webhook
sender names do not require separate Discord bot applications. Missing config
is a silent no-op so a notification outage cannot fail the underlying job.

The original shared webhook's default name was changed live to **Homelab
Jobs** on 2026-09-29. Kuma explicitly sets **Uptime Kuma** on its messages, so
jobs no longer appear to come from Kuma before the channel migration either.

State lives in `~/.local/state/homelab-jobs/<job>.state`.

## Why this exists

The Kindle sync failed every hour for ~73 days and nobody noticed. Two of the
four database dumps had **never once** succeeded. Both wrote their errors
faithfully to log files that nobody reads.

Note that exit codes only catch a job that *ran and failed*. A job that stops
being scheduled at all — cron wiped, machine off — is silent either way, and so
is everything on this machine when the power goes. That is what the heartbeat
covers: `heartbeat.sh` pings **Healthchecks.io** every 5 minutes, and
Healthchecks alerts (email, phone, Discord) from its own servers when the pings
stop. It pings `/fail` instead when Docker is unresponsive, since Uptime Kuma is
a container and goes blind at the same moment.

### Setting up the heartbeat (once)

1. Create a free account at <https://healthchecks.io> and add a check:
   period **5 minutes**, grace **10 minutes**.
2. Add a notification channel there — email at minimum; the Discord webhook
   works too, since Healthchecks sends it from outside the house.
3. On the Mac mini:
   ```bash
   mkdir -p ~/.config/homelab
   echo 'HEARTBEAT_PING_URL=https://hc-ping.com/<uuid>' > ~/.config/homelab/heartbeat.env
   chmod 600 ~/.config/homelab/heartbeat.env
   ~/.dotfiles/scripts/utils/heartbeat.sh --test     # expect "sent: ok"
   ```
4. Reinstall the crontab (above). Healthchecks shows the check go green.

The ping URL is a credential — anyone holding it can keep the check green. It
lives only in `~/.config/homelab/`; a gitleaks rule blocks it from being
committed. The weekly audit fails while the file is missing or the last
successful ping is over an hour old.
