# Credential migration — moving every service into Bitwarden

Working checklist for giving each service a unique generated password stored in
Vaultwarden. Tick rows off as you go.

🚫 **No passwords in this file — this repo is public.** Values you still need to
transcribe live in `~/credentials-import.md` (chmod 600, outside the repo);
delete that file once the vault holds everything.

Status: **4 of ~18 services done.** Started 2026-09-19.

---

## The rule

- **One standard username** (stored in Vaultwarden, not written here) everywhere the app allows it. Not `admin` — that
  is the first username every automated attack tries.
- **One memorised passphrase**: the Vaultwarden master, and nothing else.
- **Everything else generated random** in Vaultwarden, copy-pasted when needed —
  including on the phone. No service password is ever typed from memory, so
  none of them need to be memorable.
- **Put the URL on every Bitwarden entry** so autofill offers the right one.

Tailscale IP for the internal services: `100.81.171.49`.

---

## Use this pass to change the email too

You are already visiting every service to change its password, and several use
the **Gmail address as the login**. Switch those to a per-service alias on
`peciulevicius.com` at the same time — `netflix@`, `bank@`, `github@`. The
catch-all means no alias needs creating first, and if one ever starts attracting
spam you know exactly which service leaked it.

Doing this later means a second pass through all eighteen.

### External accounts on Gmail → per-service aliases

Same pass, outside the homelab. Decided 2026-09-25 to do these together rather
than one at a time. Start with the ones whose mail feeds automation:

| Account | New login email | Why it matters |
|---|---|---|
| Amazon | `amazon@peciulevicius.com` | Kindle Scribe exports default to the account email → `kindle_sync` (until then a Gmail filter forwards them) |
| *(add as you go)* | `<service>@peciulevicius.com` | |

---

## ✅ Done

| Service | URL | Username | Notes |
|---|---|---|---|
| Vaultwarden | `https://vault.peciulevicius.com` | email | Master password changed 2026-09-19 |
| CouchDB | `https://couchdb.peciulevicius.com` | `<username>` | 32-char random, `.env`-backed |
| Transmission | `http://100.81.171.49:9091` | `<username>` | 28-char random, `.env`-backed |
| Pi-hole | `https://pihole.peciulevicius.com` | *(password only)* | 32-char random. Old one was **5 characters** on a public panel controlling DNS — assume exposed. **Glance keeps a copy** (`PIHOLE_PASSWORD`, DNS widget) since the v6 upgrade |

---

## ⬜ Resettable from the command line

Generate in Vaultwarden first, then run the command, then save.

| Service | URL | Username |
|---|---|---|
| Nextcloud | `https://cloud.peciulevicius.com` | `<username>` |
| Paperless-ngx | `https://papers.peciulevicius.com` | `<username>` |
| FreshRSS | `https://rss.peciulevicius.com` | `<username>` |
| Grafana | `http://100.81.171.49:3000` | `admin` |

```bash
# Nextcloud
OC_PASS='NEW_PASSWORD' docker exec -u www-data -e OC_PASS nextcloud \
  php occ user:resetpassword --password-from-env <username>

# Paperless-ngx  (interactive prompt)
docker exec -it paperless python3 /usr/src/paperless/src/manage.py \
  changepassword <username>

# FreshRSS
docker exec freshrss php /var/www/FreshRSS/cli/update-user.php \
  --user '<username>' --password 'NEW_PASSWORD'

# Grafana
docker exec grafana grafana cli admin reset-admin-password 'NEW_PASSWORD'
```

---

## ⬜ UI only — change inside the app

| Service | URL | Username / email |
|---|---|---|
| Immich | `https://photos.peciulevicius.com` | email → switch to an alias |
| Linkwarden | `https://links.peciulevicius.com` | email → switch to an alias |
| Mealie | `https://recipes.peciulevicius.com` | email → switch to an alias |
| Calibre-Web | `https://books.peciulevicius.com` | `<username>` |
| Jellyfin | `https://watch.peciulevicius.com` | `<username>` |
| Audiobookshelf | `https://listen.peciulevicius.com` | `<username>` |
| Uptime Kuma | `https://status.peciulevicius.com` | `<username>` |
| Portainer | `https://portainer.peciulevicius.com` | `<username>` |
| Syncthing | `http://100.81.171.49:8384` | `<username>` |
| Bazarr | `http://100.81.171.49:6767` | `<username>` |
| LazyLibrarian | `http://100.81.171.49:5299` | `<username>` |
| Jellyseerr | `http://100.81.171.49:5055` | via Jellyfin |
| NAS (UGOS) | `https://nas.peciulevicius.com` | personal admin account (in Vaultwarden) |
| NAS SMB service account | *(macOS Keychain)* | `macmini` |

---

## ⬜ API keys, not passwords

Copy each from **Settings → General → API Key** into Bitwarden as a secure note.

| Service | URL |
|---|---|
| Sonarr | `http://100.81.171.49:8989` |
| Radarr | `http://100.81.171.49:7878` |
| Prowlarr | `http://100.81.171.49:9696` |

---

## No login at all — skip

Glance (`home.`), Stirling PDF (`pdf.`), IT-Tools (`tools.`), Calibre desktop
(`:8888`), Prometheus (`:9090`).

---

## Also belongs in Bitwarden

| Thing | Where it lives |
|---|---|
| Gmail app password | `pkm/config.py`, Uptime Kuma SMTP, Calibre-Web SMTP — **one password, three consumers** |
| Discord webhook | `~/.config/homelab/notify.env` |
| Cloudflare tunnel credentials | `~/.cloudflared/*.json` |
| R2 / rclone | `~/.config/rclone/rclone.conf` |
| Cloudflare account login + 2FA | Vaultwarden — the account owns DNS, the tunnel, R2, Pages/Workers; 2FA must not live in Google Authenticator |
| Cloudflare API token `dotfiles-automation` (account-wide: Zone/DNS, Workers, Turnstile, Email Routing, Access, Tunnel — replaced the DNS-only `dotfiles-dns` 2026-09-25) | `~/.config/homelab/cloudflare.env` |
| Purelymail `dziugas@` password | Vaultwarden + `~/.config/homelab/purelymail.env` (mail-switch script) |
| Healthchecks.io ping URL | `~/.config/homelab/heartbeat.env` |
| TrainingPeaks cookie / Strava tokens | `~/services/trainingpeaks-mcp/.env`, `~/services/strava-mcp/data/.strava-mcp.env` |
| Supabase CLI login (peciulevicius.com) | macOS keychain via `supabase login`; DB password not needed (CLI uses a temporary login role) — keep it in Vaultwarden only |

---

## Why most of these can't just be edited in a `.env`

Only three services read their password from a file at runtime. Knowing which
kind you are dealing with saves guessing:

| Kind | Where the password lives | Editable in a file? |
|---|---|---|
| Runtime env var — CouchDB, Transmission, Pi-hole | Read from `.env` on **every start** | ✅ edit, then `docker compose up -d --force-recreate` |
| Init-only env var — Nextcloud, Paperless, Grafana | Read **once**, to create the account | ❌ inert now; the account lives in the app's database |
| App account — everything else | **Salted hash** in the app's database | ❌ plaintext unrecoverable by design |
| Internal DB role — Immich/Paperless/Linkwarden Postgres | `.env` **and** the role inside the DB | ⚠️ both together, or the app cannot connect |

---

## ⚠️ Open issues to settle during this pass

- **Immich's Postgres password is the old reused personal password.**
  Internal-only, but changing it needs `ALTER USER` inside Postgres *and* the
  `.env` updated together, or Immich loses its database. Deliberate session.
- **Nextcloud has two accounts** — the standard username, and a second `admin` whose
  display name is confusingly the same as the standard username. Pick one, delete the other.
- **Retire the old reused personal password** everywhere it still appears.
- **`.env` files are excluded from the R2 backup.** A restore gives you configs
  with **no secrets** — Vaultwarden is the only copy. Keep an emergency export
  of the vault somewhere offline.
