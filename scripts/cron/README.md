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
| Daily 05:00 | rclone → Cloudflare R2 | `~/logs/rclone-backup.log` |
| Hourly | Kindle Scribe → Obsidian vault | `~/logs/kindle-sync.log` |

The Kindle sync is hourly on purpose: Amazon's share links expire after 7 days,
so a slow poll loses exports.

## Notifications

Every job runs through [`../utils/run-with-notify.sh`](../utils/run-with-notify.sh),
which posts to Discord when a job **starts** failing and again when it
**recovers** — not on every run, so an hourly job that breaks sends one message
instead of 24 a day. If it stays broken it re-nags once every `REMIND_HOURS`
(default 24).

Configure the webhook once:

```bash
mkdir -p ~/.config/homelab
cat > ~/.config/homelab/notify.env <<'EOF'
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
EOF
chmod 600 ~/.config/homelab/notify.env
```

Use the **same webhook Uptime Kuma already posts to** (Uptime Kuma → Settings →
Notifications → the Discord entry → copy the URL) so service up/down alerts and
job failures land in one channel. Without the file the wrapper is a silent
no-op — jobs must never fail just because notifications aren't set up.

State lives in `~/.local/state/homelab-jobs/<job>.state`.

## Why this exists

The Kindle sync failed every hour for ~73 days and nobody noticed. Two of the
four database dumps had **never once** succeeded. Both wrote their errors
faithfully to log files that nobody reads.

Note that exit codes only catch a job that *ran and failed*. A job that stops
being scheduled at all — cron wiped, machine asleep — is silent either way. For
that, add **Uptime Kuma push monitors**: Kuma alerts when the job stops checking
in. Not set up yet.
