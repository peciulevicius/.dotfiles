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
- **Backblaze B2 (old):** $0.006/GB/month + $0.01/GB egress — the reason this
  migrated to R2: a full restore off B2 bills egress, a full restore off R2 doesn't

Configs + Obsidian vault + DB dumps + Calibre books run **~2.9GB** — under the
free tier, **$0/month**. See `BACKUP_IMMICH_PHOTOS` below before enabling it —
that one is priced differently.

## Immich photo/video backup — opt-in, read before enabling

`BACKUP_IMMICH_PHOTOS=true` in `.env` turns on Backup 5: originals only
(`/Volumes/immich/upload/upload`, ~73GB), excluding `encoded-video/` and
`thumbs/` (regenerable by Immich) and `backups/` (Immich's own DB snapshot —
redundant with Backup 3, which already dumps `immich_postgres` via
`pg_dump` and ships it to R2 separately).

⚠️ **Off by default on purpose.** Turning it on hands the next 5am cron run a
~73GB **first** upload — hours, depending on home upload speed — and moves the
combined R2 bill from $0 to **~$1/month** (73GB − 10GB free tier × $0.015).
Every run after the first is incremental (rclone only transfers new/changed
files), so the cost and time only spike once.

Enable it deliberately, ideally by running the script by hand first so you see
the initial transfer rather than discovering it in tomorrow's cron log:

```bash
echo 'BACKUP_IMMICH_PHOTOS=true' >> .env
./rclone-backup.sh --dry-run    # see what would transfer, size and file count
./rclone-backup.sh              # run the real (large, first) upload
```

Full reasoning — why originals only, why this is the second offsite layer
alongside the T5 drive plan — in
[HOME_SERVER_TODO.md](../../docs/HOME_SERVER_TODO.md), "Get one copy of the
photos out of the building."

## What's excluded from backup

- `.env` files (contain secrets)
- Database data dirs (`data/postgres/`, `data/prometheus/`)
- Large media (`jellyfin/data/`, `sonarr-radarr/data/`, `audiobookshelf/audiobooks/`)
- Obsidian plugins and workspace state (`.obsidian/plugins/`, `.obsidian/workspace*`)
- Immich `encoded-video/`, `thumbs/`, `backups/` — see above (only with
  `BACKUP_IMMICH_PHOTOS=true`; Immich itself is excluded entirely by default)

See [docs/HOME_SERVER.md](../../docs/HOME_SERVER.md) for full backup strategy.
