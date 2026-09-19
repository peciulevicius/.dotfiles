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

## The policy (decided 2026-09-19)

**Username: `peciulevicius` everywhere** the app allows it. Not `admin` — that
is the first username every automated attack tries, and it is free to change.

**Passwords — two kinds, and the distinction is the whole point:**

| Kind | Used for | How |
|---|---|---|
| **One memorised passphrase** | The Vaultwarden master password only | 4–6 random common words. The only password you ever type from memory. |
| **Generated random** | Every service | Generated in Vaultwarden, stored there, autofilled or pasted. Never memorised, never reused. |

The one exception is a password you genuinely have to **type by hand on a phone**
— CouchDB, entered in the LiveSync plugin on each device. There, use a **six
common words + two digits** passphrase (~62 bits): easy on a phone keyboard,
still far stronger than anything memorable-and-short.

❌ **Never one shared password across services.** One breach then becomes a total
breach, and the most exposed service sets the security of every other one.
❌ **Never a short memorable password on Vaultwarden** — it protects everything else.

⚠️ **One personal password was reused across many services** as of 2026-09-19
and is being retired. Treat any account still using it as compromised-by-reuse
until rotated. (The string itself is deliberately not written down here — this
repo is public.)

---

## Rename + rotate checklist

`.env`-backed services take effect on `docker compose up -d`. **The rest only
read `ADMIN_USER` / `GRAFANA_USER` at first initialisation** — the account
already exists in the app's database, so editing `.env` does nothing and the
rename has to happen in the app's own UI.

| Service | Where | Status |
|---|---|---|
| CouchDB | `.env` → recreate | ✅ done 2026-09-19 — `peciulevicius` + six-word passphrase |
| Transmission | `.env` → recreate | ✅ done 2026-09-19 — `peciulevicius` + 28-char random |
| Vaultwarden | Web vault → Account Settings | ⬜ master password — **do this one first and carefully** |
| Nextcloud | `cloud.peciulevicius.com` → Users | ⬜ UI only; `ADMIN_USER` in `.env` is inert now |
| Paperless-ngx | `papers.peciulevicius.com` → Admin → Users | ⬜ UI only |
| Grafana | `localhost:3000` → Profile | ⬜ UI only |
| Immich | `photos.peciulevicius.com` → Account | ⬜ account email/password; leave `DB_USERNAME=postgres` alone |
| Linkwarden | `links.peciulevicius.com` → Settings | ⬜ |
| Calibre-Web | `books.peciulevicius.com` → Admin | ⬜ |
| FreshRSS / Mealie / Audiobookshelf / Jellyfin / Uptime Kuma | each app's UI | ⬜ |
| NAS (`Džiugas` admin, `macmini` SMB) | NAS UI + macOS Keychain | ⬜ then remount the four shares |

⚠️ **`DB_USERNAME=postgres` in Immich, and the Postgres roles behind Paperless
and Linkwarden, are internal database roles.** Renaming those breaks the app.
Change the app's *login*, not the database role.

---

## Service credentials

| Service | Where the secret lives | Notes |
|---|---|---|
| CouchDB | `~/services/couchdb/.env` | User `peciulevicius`, six-word passphrase. ⚠️ **Publicly reachable** at `couchdb.peciulevicius.com` — never share this password with anything else |
| Vaultwarden | `~/services/vaultwarden/.env` | `ADMIN_TOKEN` |
| Nextcloud | `~/services/nextcloud/.env` | MariaDB root + app user |
| Immich / Paperless / Linkwarden | `~/services/<svc>/.env` | Postgres passwords |
| Transmission | `~/services/transmission/.env` | User `peciulevicius`, 28-char random (rotated 2026-09-19) |
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
