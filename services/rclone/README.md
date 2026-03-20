# Rclone

Cloud backup for `~/docker/` volumes to Backblaze B2 (or any S3-compatible storage).

## Quick Start

```bash
# Install
brew install rclone

# Configure B2 remote
rclone config
# Choose: n (new remote) → name: b2-backup → type: b2 → add account+key

# Copy and edit env
cp .env.example .env
nano .env

# Test run
./rclone-backup.sh --dry-run

# Live backup
./rclone-backup.sh
```

## Automate with cron

```bash
# Run daily at 3 AM
crontab -e
0 3 * * * /Users/yourusername/.dotfiles/services/rclone/rclone-backup.sh >> /Users/yourusername/logs/rclone-cron.log 2>&1
```

## Cost Estimate (Backblaze B2)

- Storage: $0.006/GB/month
- 100GB = ~$0.60/month
- Download: $0.01/GB (only when restoring)

## What's Excluded

- `.env` files (contain secrets)
- `library/` (Immich photos — back up separately or via rclone sync from your photo source)
- `data/postgres/` (use `pg_dump` for database backups instead)

See [docs/HOME_SERVER.md](../../docs/HOME_SERVER.md) for full backup strategy.
