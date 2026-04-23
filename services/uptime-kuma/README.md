# Uptime Kuma

Self-hosted uptime monitoring with status pages and notifications.

## Ports

| Port | Service |
|------|---------|
| 3001 | Web UI (local) |

## Quick Start

```bash
docker compose up -d
```

Open `http://localhost:3001` to set up your admin account on first visit.

## Email Notifications (Resend SMTP)

Set up once in the UI. Uses Resend as SMTP relay — already in the SaaS stack, free tier (3000 emails/month), works with `peciulevicius.com`.

**Settings → Notifications → Add notification:**

| Field | Value |
|-------|-------|
| Notification Type | Email (SMTP) |
| Friendly Name | `Resend` |
| Hostname | `smtp.resend.com` |
| Port | `465` |
| Security | SSL/TLS |
| Username | `resend` |
| Password | Resend API key (from resend.com → API Keys) |
| From Email | `alerts@peciulevicius.com` |
| To Email | your personal email |

After saving, click **Test** — you should receive a test email within seconds.

> `alerts@peciulevicius.com` needs to be a verified sender in Resend. Your `peciulevicius.com`
> domain is already on Cloudflare — Resend will show DNS records to add (TXT + MX, ~2 min).

> **Future:** Once Migadu is set up (De-Google TODO #18), switch to `smtp.migadu.com:465`,
> username = full email address, password = Migadu app password.

After adding the channel: tick **"Default Enabled"** so all future monitors get alerts automatically.

## Monitors

Add in the UI (Add New Monitor → HTTP/HTTPS):

| Name | URL |
|------|-----|
| Immich | `http://localhost:2283` |
| Vaultwarden | `http://localhost:8001` |
| Nextcloud | `http://localhost:8080` |
| Jellyfin | `http://localhost:8096` |
| Syncthing | `http://localhost:8384` |
| Paperless | `http://localhost:8000` |
| Linkwarden | `http://localhost:3005` |
| Grafana | `http://localhost:3000` |
| Pi-hole | `http://localhost:8053` |
| Glance | `https://home.peciulevicius.com` |

## Rclone backup heartbeat (TODO #14)

Once email alerts are confirmed working, wire up the nightly backup heartbeat:

1. Uptime Kuma → Add Monitor → type: **Push**
2. Copy the heartbeat URL
3. Add to end of `~/.dotfiles/services/rclone/rclone-backup.sh`:
   ```bash
   curl -fs "https://uptime.peciulevicius.com/api/push/YOUR_KEY" > /dev/null || true
   ```
