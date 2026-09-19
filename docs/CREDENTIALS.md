# Credentials — where they live and what to change

No secrets in this file. It records **where** each credential is used, so a
rotation doesn't silently break something three weeks later.

Master copy of every password belongs in **Vaultwarden**
(`vault.peciulevicius.com`). Anything not there yet is listed as outstanding in
[HOME_SERVER_TODO.md](HOME_SERVER_TODO.md).

---

## The Gmail app password — used in three places

⚠️ **Gmail needs a 16-character app password** (`abcd efgh ijkl mnop`), not the
account password. With 2FA on, the account password is rejected with
`AUTHENTICATIONFAILED` — this is exactly how the Kindle sync died.

Generate at: Google Account → Security → 2-Step Verification → **App passwords**.

When it changes, update **all three**, or the ones you miss fail silently:

| # | Where | What it does | How to change |
|---|---|---|---|
| 1 | `pkm/config.py` → `EMAIL_PASSWORD` | **IMAP** — Kindle Scribe exports into the vault, hourly | Edit the file on the Mac mini (gitignored, not in the repo). Test: `~/.dotfiles/pkm/.venv/bin/python3 ~/.dotfiles/pkm/kindle_sync.py` |
| 2 | Uptime Kuma → Settings → Notifications → **"Uptime Kuma"** (SMTP) | **SMTP** — email alerts when a service goes down | `status.peciulevicius.com`, edit the notification, hit **Test** |
| 3 | Calibre-Web → Admin → SMTP settings | **SMTP** — Send-to-Kindle to `peciulevicius-scribe@kindle.com` | `books.peciulevicius.com` |

**If the app password was revoked, all three broke at once.** Only #1 was
noticed, because it logs every hour. #2 and #3 fail only when they try to send,
so check them after rotating.

Note #2 is largely redundant now — Discord covers alerting, and the Discord
notification is set to *Default enabled* + *Apply on all existing monitors*, so
all 21 monitors already report there.

**This all goes away with the email migration.** Moving to Purelymail changes
`IMAP_SERVER` in `pkm/config.py` and the SMTP host in #2 and #3 — see
[guides/DEGOOGLE.md](guides/DEGOOGLE.md).

---

## Discord webhook

`~/.config/homelab/notify.env` (chmod 600, outside the repo) —
`DISCORD_WEBHOOK_URL`. The **same webhook Uptime Kuma posts to**, so service
up/down and cron job failures land in one channel.

Used by `scripts/lib/notify.sh`, which every cron job runs through. If the file
is missing, notifications are a silent no-op and jobs still run normally.

---

## Service credentials

| Service | Where the secret lives | Notes |
|---|---|---|
| CouchDB | `~/services/couchdb/.env` | User `obsidian`. ⚠️ **Publicly reachable** at `couchdb.peciulevicius.com` — this one should never share a password with anything else |
| Vaultwarden | `~/services/vaultwarden/.env` | `ADMIN_TOKEN` |
| Nextcloud | `~/services/nextcloud/.env` | MariaDB root + app user |
| Immich / Paperless / Linkwarden | `~/services/<svc>/.env` | Postgres passwords |
| Transmission | `~/services/transmission/.env` | Changed from defaults |
| NAS (`Džiugas` admin, `macmini` SMB) | NAS UI + macOS Keychain | ⚠️ Currently reused passwords — rotation is outstanding |

Every `.env` under `~/services/` is **excluded from the R2 backup**
(`rclone-backup.sh` has `--exclude "**/.env"`). That is deliberate — but it
means **a restore from R2 gives you configs with no secrets**. Vaultwarden is
the only copy. Keep it current.

---

## Rotation checklist

1. Generate a unique password (never reuse across services)
2. Store it in Vaultwarden **first**, before changing anything
3. Update the `.env` or app setting
4. `docker compose up -d` in that service's directory
5. Verify the service still works before closing the terminal
