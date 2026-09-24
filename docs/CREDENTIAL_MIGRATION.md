# Credential migration

Checklist for giving every service a unique generated password stored in
Vaultwarden, and for moving email-based logins to per-service aliases on the
own domain.

> **Warning:** This repository is public. No passwords or usernames belong in
> this file. Values still to be transcribed are in `~/credentials-import.md`
> (mode 600, outside the repository); delete that file once the vault holds
> everything.

Status: **4 of ~16 services done** (started 2026-09-19).

---

## Rules

- **One standard, non-default username** wherever the application allows it
  (stored in Vaultwarden). `admin` is the first name automated attacks try.
- **One memorised passphrase:** the Vaultwarden master password.
- **Every other password is generated** by Vaultwarden and pasted when needed,
  including on the phone.
- **Every entry has its URL set**, so autofill offers the right credential.
- **Change the email in the same visit.** Services that use the Gmail address as
  the login move to a per-service alias (`immich@`, `github@`, …). The domain's
  catch-all means aliases need no setup, and an alias that attracts spam
  identifies which service leaked it. Doing email separately would double the
  number of logins.
- **After rotating a password, update every client that stores its own copy**
  (see the `credential-rotation` project skill and
  [HOME_SERVER_REFERENCE.md](HOME_SERVER_REFERENCE.md#credentials-stored-by-clients)).

Internal services are reached at the Tailscale address `100.81.171.49`.

---

## Done

| Service | URL | Login | Notes |
|---|---|---|---|
| Vaultwarden | `https://vault.peciulevicius.com` | Email | Master password changed 2026-09-19 |
| CouchDB | `https://couchdb.peciulevicius.com` | Standard username | 32-character random, from `.env` |
| Transmission | `http://100.81.171.49:9091` | Standard username | 28-character random, from `.env` |
| Pi-hole | `https://pihole.peciulevicius.com` | Password only | 32-character random. The previous 5-character password was on a public panel and is treated as exposed. |

---

## Reset from the command line

Generate the password in Vaultwarden first, then run the command, then save.

| Service | URL |
|---|---|
| Nextcloud | `https://cloud.peciulevicius.com` |
| Paperless-ngx | `https://papers.peciulevicius.com` |
| FreshRSS | `https://rss.peciulevicius.com` |

```bash
# Nextcloud
OC_PASS='NEW_PASSWORD' docker exec -u www-data -e OC_PASS nextcloud \
  php occ user:resetpassword --password-from-env '<username>'

# Paperless-ngx (interactive prompt)
docker exec -it paperless python3 /usr/src/paperless/src/manage.py \
  changepassword '<username>'

# FreshRSS
docker exec freshrss php /var/www/FreshRSS/cli/update-user.php \
  --user '<username>' --password 'NEW_PASSWORD'
```

---

## Change in the application

| Service | URL | Login |
|---|---|---|
| Immich | `https://photos.peciulevicius.com` | Email → alias |
| Linkwarden | `https://links.peciulevicius.com` | Email → alias |
| Calibre-Web | `https://books.peciulevicius.com` | Standard username |
| Jellyfin | `https://watch.peciulevicius.com` | Standard username |
| Audiobookshelf | `https://listen.peciulevicius.com` | Standard username |
| Uptime Kuma | `https://status.peciulevicius.com` | Standard username |
| Portainer | `https://portainer.peciulevicius.com` | Standard username |
| Syncthing | `http://100.81.171.49:8384` | Standard username |
| Bazarr | `http://100.81.171.49:6767` | Standard username |
| LazyLibrarian | `http://100.81.171.49:5299` | Standard username |
| Jellyseerr | `http://100.81.171.49:5055` | Via Jellyfin |
| NAS (UGOS) | `https://nas.peciulevicius.com` | Personal admin account |
| NAS SMB service account | macOS Keychain | `macmini` — update the Keychain entry and remount the shares after changing it |

---

## API keys

Copy each from **Settings → General → API Key** into Vaultwarden as a secure
note.

| Service | URL |
|---|---|
| Sonarr | `http://100.81.171.49:8989` |
| Radarr | `http://100.81.171.49:7878` |
| Prowlarr | `http://100.81.171.49:9696` |

---

## No login

Glance (`home.`), Stirling PDF (`pdf.`), IT-Tools (`tools.`), Calibre desktop
(`:8888`).

---

## Other secrets to store in Vaultwarden

| Secret | Location |
|---|---|
| Gmail app password | `pkm/config.py`, Uptime Kuma SMTP, Calibre-Web SMTP — one password, three consumers |
| Discord webhook | `~/.config/homelab/notify.env` |
| Cloudflare tunnel credentials | `~/.cloudflared/*.json` |
| R2 / rclone | `~/.config/rclone/rclone.conf` |

---

## Where passwords are stored

| Type | Storage | Change by editing a file? |
|---|---|---|
| Runtime environment variable (CouchDB, Transmission, Pi-hole) | Read from `.env` on every start | Yes — edit, then `docker compose up -d --force-recreate` |
| Initialisation-only variable (Nextcloud, Paperless) | Read once to create the account | No — the account now lives in the application database |
| Application account (all others) | Salted hash in the application database | No — change it in the application |
| Internal database role (Immich, Paperless, Linkwarden Postgres) | `.env` **and** the role inside the database | Only both together, or the application loses its database |

---

## Open issues

- **Immich's Postgres password is an old reused password.** It is internal only,
  but changing it requires `ALTER USER` in Postgres and the `.env` update
  together. Procedure in [HOME_SERVER_TODO.md](HOME_SERVER_TODO.md).
- **Nextcloud has two accounts**: the standard one and an `admin` account with
  the same display name. Keep one.
- **Retire the old reused password** wherever it still appears.
- **`.env` files are excluded from the R2 backup**, so a restore contains no
  secrets. Vaultwarden is the only copy; keep an encrypted offline export of the
  vault.
