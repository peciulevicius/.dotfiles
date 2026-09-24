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
| Every 30 min | Restart Jellyfin + Audiobookshelf so they see new NAS files (`smb-watcher-rescan.sh`) | `~/logs/smb-rescan.log` |
| Sunday 09:00 | Homelab audit — drift, containers, backups, disk, secrets (`homelab-audit.sh`) | `~/logs/homelab-audit.log` |
| Quarterly, 1st 10:00 | Pinned images with a newer upstream release (`check-image-updates.py`) — a reminder, not an auto-update | `~/logs/image-updates.log` |

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
