# Rclone

Cloud backup for `~/services/` configs and Obsidian vault to Cloudflare R2.

**Storage:** Cloudflare R2 — 10GB free tier, no egress fees.

## First-time setup

### 1. Create R2 bucket and API token

1. Cloudflare dashboard → R2 → **Create bucket** → name: `peciulevicius-backups`
2. R2 → **Manage R2 API tokens** → Create token → **Object Read & Write** → copy Access Key ID + Secret

### 2. Configure rclone remote

```bash
rclone config
# n → new remote
# name: r2
# type: s3
# provider: Cloudflare
# access_key_id: <paste Access Key ID>
# secret_access_key: <paste Secret>
# endpoint: https://<account-id>.r2.cloudflarestorage.com
# Leave everything else blank → save
```

Your Cloudflare account ID is in the R2 dashboard URL or top-right of the R2 page.

### 3. Configure env

```bash
cp .env.example .env
# Edit DOCKER_DIR to your actual services path
nano .env
```

### 4. Test and run

```bash
./rclone-backup.sh --dry-run   # verify without transferring
./rclone-backup.sh             # live backup
```

## Automate (cron at 5am daily)

```bash
crontab -e
# Add:
0 5 * * * /Users/dziugaspeciulevicius/.dotfiles/services/rclone/rclone-backup.sh >> /Users/dziugaspeciulevicius/logs/rclone-cron.log 2>&1
```

## Migrate from B2 to R2

If switching from Backblaze B2, use the migration helper:

```bash
./migrate-b2-to-r2.sh
```

This syncs existing data from B2 to R2, updates your `.env`, and runs a dry-run to confirm everything works.

## Cost

- **Cloudflare R2:** 10GB free, $0.015/GB/month after that, **no egress fees**
- **Backblaze B2 (old):** $0.006/GB/month + $0.01/GB egress

## What's excluded from backup

- `.env` files (contain secrets)
- Database data dirs (`data/postgres/`, `data/prometheus/`)
- Large media (`jellyfin/data/`, `sonarr-radarr/data/`, `audiobookshelf/audiobooks/`)
- Obsidian plugins and workspace state (`.obsidian/plugins/`, `.obsidian/workspace*`)

See [docs/HOME_SERVER.md](../../docs/HOME_SERVER.md) for full backup strategy.
