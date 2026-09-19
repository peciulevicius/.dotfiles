What to do now, in order

1. Add those three passwords to Bitwarden — with the URLs, so autofill works. 5 minutes.
2. Generate the Gmail app password. Still the single blocker on the Kindle sync, dead 73 days. Then put it in pkm/config.py — and remember it's used in two other places.
3. Cloudflare Email Routing. Free, unblocks the whole email migration.
4. Then walk docs/CREDENTIALS.md service by service at your own pace.


# Credentials — where they live and what to change

🚫 **No secrets in this file, ever — this repo is public on GitHub.** It records
**where** each credential is used and how to change it, so a rotation doesn't
silently break something three weeks later.

Real values live in `~/services/<svc>/.env` (gitignored), `~/.config/homelab/`,
or Vaultwarden. While migrating everything into Bitwarden, a scratch worksheet
at `~/credentials-import.md` (outside this repo, chmod 600) holds the values —
delete it once the vault is populated.

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

**Random everywhere, including CouchDB** (decided 2026-09-19). The workflow is
always: open Bitwarden, copy, paste — on the phone too. Nothing but the
Vaultwarden master is ever typed from memory, so there is no reason for any
service password to be memorable.

❌ **Never one shared password across services.** One breach then becomes a total
breach, and the most exposed service sets the security of every other one.
❌ **Never a short memorable password on Vaultwarden** — it protects everything else.

⚠️ **One personal password was reused across many services** as of 2026-09-19
and is being retired. Treat any account still using it as compromised-by-reuse
until rotated. (The string itself is deliberately not written down here — this
repo is public.)

---

## Every service — the full inventory

**One row per login.** The **URL column is what Bitwarden needs** as the item's
URI so autofill offers the right entry. For Tailscale-only services use the
`100.81.171.49` address as the URI — that is what you actually open.

Tailscale IP: `100.81.171.49` · Locally, `localhost` works for the same ports.

### Public (via Cloudflare Tunnel)

| Service | URL for Bitwarden | Username | Secret lives | Done |
|---|---|---|---|---|
| Vaultwarden | `https://vault.peciulevicius.com` | your email | **the master password** | ✅ changed 2026-09-19 |
| Immich | `https://photos.peciulevicius.com` | email | app account | ⬜ |
| Nextcloud | `https://cloud.peciulevicius.com` | `peciulevicius` | app account | ⬜ |
| Paperless-ngx | `https://papers.peciulevicius.com` | `peciulevicius` | app account | ⬜ |
| FreshRSS | `https://rss.peciulevicius.com` | `peciulevicius` | app account | ⬜ |
| Uptime Kuma | `https://status.peciulevicius.com` | `peciulevicius` | app account | ⬜ |
| Calibre-Web | `https://books.peciulevicius.com` | `peciulevicius` | app account | ⬜ |
| Pi-hole | `https://pihole.peciulevicius.com` | *(password only)* | app account | ⬜ |
| Linkwarden | `https://links.peciulevicius.com` | email | app account | ⬜ |
| Mealie | `https://recipes.peciulevicius.com` | email | app account | ⬜ |
| Jellyfin | `https://watch.peciulevicius.com` | `peciulevicius` | app account | ⬜ |
| Audiobookshelf | `https://listen.peciulevicius.com` | `peciulevicius` | app account | ⬜ |
| Portainer | `https://portainer.peciulevicius.com` | `peciulevicius` | app account | ⬜ |
| **CouchDB** | `https://couchdb.peciulevicius.com` | `peciulevicius` | `~/services/couchdb/.env` | ✅ 2026-09-19, 32-char random |
| NAS (UGOS) | `https://nas.peciulevicius.com` | `Džiugas` | NAS UI | ⬜ ⚠️ reused |
| Glance dashboard | `https://home.peciulevicius.com` | *(no login)* | — | n/a |
| Stirling PDF | `https://pdf.peciulevicius.com` | *(no login)* | — | n/a |
| IT-Tools | `https://tools.peciulevicius.com` | *(no login)* | — | n/a |

### Tailscale-only (not exposed publicly)

| Service | URL for Bitwarden | Username | Secret lives | Done |
|---|---|---|---|---|
| Sonarr | `http://100.81.171.49:8989` | *(API key / form auth)* | app account | ⬜ |
| Radarr | `http://100.81.171.49:7878` | *(API key / form auth)* | app account | ⬜ |
| Prowlarr | `http://100.81.171.49:9696` | *(API key / form auth)* | app account | ⬜ |
| Bazarr | `http://100.81.171.49:6767` | `peciulevicius` | app account | ⬜ |
| Jellyseerr | `http://100.81.171.49:5055` | via Jellyfin | app account | ⬜ |
| **Transmission** | `http://100.81.171.49:9091` | `peciulevicius` | `~/services/transmission/.env` | ✅ 2026-09-19, 28-char random |
| LazyLibrarian | `http://100.81.171.49:5299` | `peciulevicius` | app account | ⬜ |
| Calibre (desktop) | `http://100.81.171.49:8888` | *(no login)* | — | n/a |
| Grafana | `http://100.81.171.49:3000` | `peciulevicius` | `~/services/grafana/.env` (init only) | ⬜ UI |
| Prometheus | `http://100.81.171.49:9090` | *(no login)* | — | n/a |
| Syncthing | `http://100.81.171.49:8384` | `peciulevicius` | app account | ⬜ |

### Not a web login

| Thing | What | Where |
|---|---|---|
| Gmail app password | IMAP + SMTP | 3 places — see the top of this file |
| Discord webhook | job + service alerts | `~/.config/homelab/notify.env` |
| Cloudflare | tunnel + DNS | `~/.cloudflared/` credentials JSON |
| Tailscale | tailnet auth | Tailscale app, Google SSO ⚠️ |
| R2 (rclone) | cloud backup | `~/.config/rclone/rclone.conf` |
| NAS SMB (`macmini`) | share mounts | NAS UI + macOS Keychain |
| Postgres / MariaDB roles | internal only | `~/services/<svc>/.env` — ⚠️ never rename, app breaks |

---

## ⚠️ The email migration touches most of these

Several services use **`dziugaspeciulevicius@gmail.com` as the login itself** —
Vaultwarden, Immich, Linkwarden and Mealie above, plus every "Sign in with
Google" account.

When the mailbox moves to Purelymail, each of those needs its **login address
changed inside the app**, not just the mail forwarded. Change the address first,
while you can still receive at the old one to confirm the change — a service
whose login email you can no longer receive at is a service you can't reset
into.

Order that works:

1. New address forwards **to** Gmail (free Cloudflare Email Routing) — zero risk
2. Change the login email in each service, verifying as you go
3. Only then flip the MX records and stop using Gmail

Also update at the same time: `EMAIL_ADDRESS` and `IMAP_SERVER` in
`pkm/config.py`, and the SMTP host in Uptime Kuma and Calibre-Web.

See [guides/DEGOOGLE.md](guides/DEGOOGLE.md).

---

## Why most passwords can't be changed from a file

A reasonable assumption is that every password sits in a `.env` somewhere and
can be rewritten. It doesn't work that way, and the distinction decides how each
service gets rotated:

| Kind | Where the password lives | Can it be changed from a file? |
|---|---|---|
| **Runtime env var** — CouchDB, Transmission, Pi-hole | Read from `.env` on **every container start** | ✅ Edit `.env`, `docker compose up -d --force-recreate` |
| **Init-only env var** — Nextcloud, Paperless, Grafana | Read **once**, at first initialisation, to create the account | ❌ The `.env` value is now inert. The account exists in the app's database. |
| **App account** — everything else | A **salted hash** in the app's own database | ❌ The plaintext is unrecoverable by design. Change it in the app. |
| **Internal DB role** — Immich/Paperless/Linkwarden Postgres | `.env` **and** the role inside the database | ⚠️ Both must change together, or the app can't connect |

So "the password is in the docker file somewhere" is true for exactly three
services. For the rest, the file that created the account no longer controls it.

### Command-line resets, where they exist

Four services can be reset without the UI. Generate the password in Vaultwarden
first, then run the matching command:

```bash
# Nextcloud
OC_PASS='NEW_PASSWORD' docker exec -u www-data -e OC_PASS nextcloud \
  php occ user:resetpassword --password-from-env peciulevicius

# Paperless-ngx  (interactive prompt)
docker exec -it paperless python3 /usr/src/paperless/src/manage.py \
  changepassword peciulevicius

# FreshRSS
docker exec freshrss php /var/www/FreshRSS/cli/update-user.php \
  --user peciulevicius --password 'NEW_PASSWORD'

# Grafana
docker exec grafana grafana cli admin reset-admin-password 'NEW_PASSWORD'
```

Everything else is the app's own UI — there is no shortcut.

⚠️ **Sonarr, Radarr and Prowlarr use an API key, not a password.** Copy each
from Settings → General → API Key and store it as a secure note.

---

## Renaming: what actually works

`.env`-backed services take effect on `docker compose up -d`. **The rest only
read `ADMIN_USER` / `GRAFANA_USER` at first initialisation** — the account
already exists in the app's database, so editing `.env` does nothing and the
rename has to happen in the app's own UI.

⚠️ **`DB_USERNAME=postgres` in Immich, and the Postgres roles behind Paperless
and Linkwarden, are internal database roles.** Renaming those breaks the app.
Change the app's *login*, not the database role.

---

## Backups do not contain your secrets

Every `.env` under `~/services/` is **excluded from the R2 backup**
(`rclone-backup.sh` has `--exclude "**/.env"`). That is deliberate — but it
means **a restore from R2 gives you configs with no secrets**. Vaultwarden is
the only copy. Keep it current, and keep an emergency export of the vault
somewhere offline.

---

## Rotation checklist

1. Generate a unique password (never reuse across services)
2. Store it in Vaultwarden **first**, before changing anything
3. Update the `.env` or app setting
4. `docker compose up -d` in that service's directory
5. Verify the service still works before closing the terminal
