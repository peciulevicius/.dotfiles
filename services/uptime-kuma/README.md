# Uptime Kuma

Uptime monitoring, status pages, and service down/recovery notifications.
Installed image: `louislam/uptime-kuma:1.23.17`; container `uptime_kuma`.

## Ports

| Port | Service |
|------|---------|
| 3001 | Web UI (local) |

## Quick Start

```bash
docker compose up -d
```

Open `http://localhost:3001` to set up your admin account on first visit.

## Notification scope

Kuma sends monitor **down** and **recovery** events. Cron job failures, image
update reports, agent quota/restore events, and reminders use separate
webhooks; their sender is not Kuma.

The live audit on 2026-09-29 found `resend_interval = 0` on every monitor,
so repeat down notifications are disabled. Most HTTP monitors have three
retries before declaring a failure. Keep **Resend Notification** at zero in
each monitor to retain transition-only alerts.

Discord migration is prepared in
[`configure-discord-notifications.py`](../../scripts/utils/configure-discord-notifications.py).
It moves Kuma's existing webhook into `#uptime-alerts`, retaining the saved
URL, and creates separate job/agent/reminder webhooks. The live bot still
needs **Manage Channels** and **Manage Webhooks** before that migration can
run. Until then the helper distinguishes job senders in the existing channel.
See [notification routing](../../scripts/cron/README.md#notifications).

Email already uses **Purelymail**, configured 2026-09-26. See the maintained
[email guide](../../docs/guides/EMAIL.md) for SMTP settings. SMTP credentials
are saved in Kuma's private configuration; do not copy them into this repo.

## Monitors and backup heartbeat

Configure monitors in the UI. Addresses must be reachable **from the Kuma
container**; `localhost` there refers to Kuma itself. Use the Mac mini's
reachable address or a hostname appropriate to the service's Docker network.

Some services are deliberately paused or started on demand. Their monitors
may remain paused; review the service runbook before enabling one. The live
roster includes Paperclip, CouchDB, Glance, Pi-hole, Immich, Vaultwarden and
the media stack; the UI is the source of truth for current addresses/status.

The **Rclone Backup** push monitor is already wired to nightly backups. Its
live expected interval is 86,399 seconds. The push URL is a credential kept
outside Git. Missing a daily push produces a down event and the next success
produces recovery. This is separate from job execution alerts in
`#homelab-jobs`.

For a machine-wide outage (when Kuma itself cannot run), the external
[Healthchecks heartbeat](../../scripts/cron/README.md#setting-up-the-heartbeat-once)
covers the Mac mini.
