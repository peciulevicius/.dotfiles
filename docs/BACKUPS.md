# Backup Strategy

3-2-1 backup strategy for self-hosted services and personal data.

## The 3-2-1 Rule

- **3** copies of data
- **2** different storage media
- **1** offsite copy

## Backup Matrix

| Data | Mac mini SSD | Mac mini SSD 2 | B2 Cloud | Notes |
|------|-------------|----------------|----------|-------|
| Immich photos | ✅ Primary | ✅ nightly rsync | ✅ rclone | Primary backup |
| Docker configs | ✅ ~/docker/ | — | ✅ rclone | `.env` excluded |
| Obsidian vault | ✅ ~/obsidian-vault | — | ✅ git push | GitHub |
| Paperless docs | ✅ ~/docker/paperless-ngx | — | ✅ rclone | OCR + originals |
| Calibre library | ✅ ~/Books | — | ✅ rclone | metadata.db |
| MacBook | — | ✅ Time Machine | — | USB drive |

## Immich Photo Backup

The Mac mini has two SSDs. Nightly rsync from primary → secondary:

```bash
# scripts/backup-immich.sh (see docs/HOME_SERVER.md)
rsync -avz --delete ~/docker/immich/library/ /Volumes/BackupSSD/ImmichBackup/
```

Add to crontab:
```bash
crontab -e
0 2 * * * ~/.dotfiles/scripts/backup-immich.sh
```

## Docker Volume Backup (Rclone → B2)

```bash
# Set up rclone B2 remote first
brew install rclone
rclone config  # choose b2, name it b2-backup

# Stage rclone config
cd ~/docker/rclone
nano .env  # set RCLONE_REMOTE, BACKUP_DEST

# Test
~/.dotfiles/services/rclone/rclone-backup.sh --dry-run

# Run
~/.dotfiles/services/rclone/rclone-backup.sh
```

Automate:
```bash
crontab -e
0 3 * * * ~/.dotfiles/services/rclone/rclone-backup.sh >> ~/logs/rclone-cron.log 2>&1
```

## Database Backups

Docker volume backups don't include running database state reliably. Dump databases separately:

```bash
# Immich (PostgreSQL)
docker exec immich_postgres pg_dumpall -U immich > ~/backups/immich-$(date +%Y%m%d).sql

# Nextcloud (MariaDB)
docker exec nextcloud_db mysqldump -u root -p${DB_ROOT_PASSWORD} --all-databases > ~/backups/nextcloud-$(date +%Y%m%d).sql

# Paperless (PostgreSQL)
docker exec paperless_db pg_dumpall -U paperless > ~/backups/paperless-$(date +%Y%m%d).sql
```

Add to weekly cron.

## Obsidian Vault Backup

The vault is a git repo pushed to GitHub:

```bash
cd ~/obsidian-vault
git init
git remote add origin git@github.com:yourusername/obsidian-vault.git
```

`scripts/update.sh` auto-commits and pushes when run.

## Backblaze B2 Setup

Cost: ~$0.006/GB/month. 100GB of Docker configs (not photos) ≈ $0.60/month.

```bash
# Create account at backblaze.com
# Create a bucket: my-backup-bucket
# Create an App Key with write access to that bucket

rclone config
# New remote → name: b2-backup → type: b2
# Account: your B2 account ID
# Key: your B2 app key
```

## Restore Procedure

```bash
# List what's in B2
rclone ls b2-backup:my-backup-bucket/docker

# Restore a specific service
rclone copy b2-backup:my-backup-bucket/docker/immich ~/docker/immich-restore

# Or restore everything
rclone sync b2-backup:my-backup-bucket/docker ~/docker-restore
```

## Backup Monitoring

Uptime Kuma can monitor backup jobs via heartbeat URLs. After a successful backup, send a GET request to a Kuma heartbeat endpoint to confirm the job ran.

```bash
# At end of rclone-backup.sh, add:
curl -s "http://localhost:3001/api/push/<heartbeat-token>" > /dev/null
```
