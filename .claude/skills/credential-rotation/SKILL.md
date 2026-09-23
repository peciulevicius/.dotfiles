---
name: credential-rotation
description: Rotate a password, API key, token or email address used by a homelab service, without silently breaking the other services that store their own copy of it. Use for the credential-migration pass, after any secret is exposed, or when changing a login a service depends on.
---

# Credential rotation

**The lesson this skill exists for:** on 2026-09-19 Transmission's password was
rotated. Radarr, Sonarr *and* LazyLibrarian each stored their own copy of that
login — all three silently failed every download handoff for three days.
Nothing in Transmission looked wrong. **Rotating a secret is only done when
every consumer has been updated and tested.**

Never print a secret value into the chat or a commit. This repo is public;
values live in `~/services/<svc>/.env`, `~/.config/homelab/`, or Vaultwarden.

## 1. Find every consumer before changing anything

```bash
OLD='<old value>'   # don't echo it back
grep -rlF "$OLD" ~/services/ ~/.config/homelab/ ~/.dotfiles/pkm/config.py 2>/dev/null
```

Also check copies that live in app **databases**, which grep can't see:

| Consumer | Where its copy lives | Update via |
|---|---|---|
| Radarr / Sonarr → Transmission | download client settings | `PUT /api/v3/downloadclient/{id}`, then `POST …/test` |
| LazyLibrarian → Transmission | `data/config.ini` `[TRANSMISSION]` | stop → edit → start (see ⚠️ below) |
| Calibre-Web → SMTP | `/config/app.db` `settings` table | Admin → E-mail Server Settings, *Send test email* |
| Uptime Kuma → SMTP | `/app/data/kuma.db` `notification` table | Settings → Notifications → Test |
| `kindle_sync.py` → IMAP | `pkm/config.py` (gitignored) | edit, run once by hand |
| Jellyseerr → Radarr/Sonarr/Jellyfin | its settings | UI (API keys, rarely rotated) |
| Bazarr / Prowlarr → *arr | API keys only | only if an *arr API key is rotated |

## 2. Change the source

- **App login** — change in the app, save the new value in Vaultwarden.
- **Database password (Postgres)** — change the *database user first*, then
  `.env`, then recreate. `.env` alone breaks the app's DB connection:
  ```bash
  docker exec <db_container> psql -U postgres -c "ALTER USER <user> WITH PASSWORD '<new>';"
  # update DB_PASSWORD in ~/services/<svc>/.env, then:
  cd ~/services/<svc> && docker compose up -d
  ```
- **Vaultwarden `ADMIN_TOKEN`** — generate, hash with `vaultwarden hash` piped
  on stdin to a `--rm` container (a secret passed as an argument stays
  visible in `docker inspect`), put the hash in `.env`, recreate.
- **Push/webhook URLs** (Uptime Kuma, Discord) — regenerate in the app; the
  URL itself is the secret.

## 3. Update every consumer

⚠️ **Apps that rewrite their config on shutdown** (LazyLibrarian): `docker
restart` flushes the old in-memory config back over your edit. Always:
```bash
docker stop <svc> && <edit the file> && docker start <svc>
grep <key> <file>    # confirm it survived startup
```

## 4. Verify each consumer, not the source

For every row found in step 1, run its test (API `…/test`, the app's *Send
test* button, a manual run). Then:
```bash
grep -rlF "$OLD" ~/services/ ~/.config/homelab/ 2>/dev/null   # must print nothing
```
Also delete stale backups that still carry the old value (e.g.
`config.ini.bak`).

## 5. Record it

- Tick the service in `docs/CREDENTIAL_MIGRATION.md` (no values).
- If a consumer was found broken, note it in `docs/HOME_SERVER_CHANGELOG.md`.
- Email-address changes: do password + email in the same visit (see TODO
  step 6); change Vaultwarden's own address **last**.
