# WUD — image update checker

[What's Up Docker](https://github.com/getwud/wud) (`getwud/wud:9.2.0`) lists
which containers have a newer image tag. Added 2026-09-28.

**URL:** <http://100.81.171.49:3070> (Tailscale) · `http://localhost:3070`.
Login: `WUD_AUTH_ADMIN_USER` / `WUD_AUTH_ADMIN_PASSWORD` in
`~/services/wud/.env` (Vaultwarden: *WUD*). No tunnel hostname.

## Why

Watchtower (`services/watchtower`) refreshes every container's *current* tag
nightly, but most images are pinned to a version (`sonarr:4.0.20`,
`jellyfin:10.10.7`, …) — a pinned tag never moves, so Watchtower does nothing
for them. That's deliberate (a surprise major can migrate a database one-way),
but it hid a Vaultwarden bug for three releases on 2026-09-21. WUD makes the
gap visible every day instead of once a quarter.

WUD only **reports**. It is not allowed to update anything: its update
triggers aren't configured, and its Docker access is read-only.

## How it fits together

```
WUD (daily 06:00, asks registries)  ──API──►  scripts/utils/update-report.sh
      │ read-only                                (daily 06:30 + Mon 09:00 --discord)
wud-socket-proxy (GET only)                       │
      │                                           ▼
/var/run/docker.sock              ~/services/glance/assets/updates.json
                                                  │
                                    Glance "Updates" widget (left column)
                                    weekly Discord summary

you:  scripts/utils/upgrade-service.sh <service> [tag]   ← the only way tags change
```

- **Socket proxy** (`tecnativa/docker-socket-proxy:v0.5.0`): WUD talks to
  Docker through it with `CONTAINERS=1 IMAGES=1 INFO=1 POST=0` — list and
  inspect only, no writes.
- **Buckets** (`update-report.sh`): *safe* (patch/minor → candidate for
  `upgrade-service.sh`), *major* (read the release notes), *held*
  (`services/wud/holds.tsv`: database majors and known false positives —
  still listed, never offered). Digest-only refreshes of floating tags
  (`latest`, `release`) are Watchtower's job and aren't counted.
- **Glance never gets the WUD login** — it reads the JSON the report writes.

## Upgrading a service

```bash
~/.dotfiles/scripts/utils/upgrade-service.sh bazarr            # tag from WUD's report
~/.dotfiles/scripts/utils/upgrade-service.sh bazarr 1.6.2      # explicit tag
~/.dotfiles/scripts/utils/upgrade-service.sh paperless-ngx 3.2.1 --image paperless-ngx/paperless-ngx
~/.dotfiles/scripts/utils/upgrade-service.sh bazarr 1.6.2 --commit   # + git commit/push
```

It pulls first (a wrong tag fails before anything changes), backs up both
compose files to `~/backups/upgrades/<svc>-<time>/`, dumps databases if the
stack has one, bumps the tag in the repo, copies it to `~/services/<svc>/`,
recreates, and waits for the healthcheck (or 45 s without restarts). If it
isn't healthy within 5 min (`TIMEOUT=`), it **restores the old compose files
and recreates on the old tag** — repo and live copy end up exactly as before.
Scale-to-zero containers that were asleep are put back to sleep. Tested
2026-09-28: a real Bazarr 1.6.1 → 1.6.2, a bad tag (stopped at pull), and a
forced failure (`TIMEOUT=0`, rolled back cleanly).

For majors, read the notes in `docs/HOME_SERVER_TODO.md` → *pinned images*
first — several are one-way data migrations that need their own backup.

## Tag filters

WUD compares semver tags. Images with odd tag schemes get a label so only
real releases count, e.g. Jellyfin and Calibre-Web:

```yaml
labels:
  - "wud.tag.include=^\\d+\\.\\d+\\.\\d+$$"   # $$ = a literal $ in compose
```

(Labels apply when the container is next recreated.)

## Gotchas

- **WUD 9 won't start without an admin user** (`Authentication is
  mandatory`) — the credentials in `.env` are required, not optional. The
  scripts read a copy in `~/.config/homelab/wud.env` (chmod 600).
- **Changing the admin login:** `WUD_AUTH_ADMIN_*` are **bootstrap** values —
  read only on the very first start, then stored in `data/wud.sqlite`. Editing
  `.env` later does nothing (seen 2026-09-28: "Username or password error").
  To change it: edit `.env`, then `docker compose stop wud`, move
  `data/wud.sqlite*` aside (it's only a cache), `docker compose up -d wud`,
  and update `WUD_USER`/`WUD_PASSWORD` in `~/.config/homelab/wud.env` so
  `update-report.sh` keeps working.
- `data/` holds a live SQLite cache — excluded from the R2 backup; it rebuilds
  on the next daily check.
- ~100–150 MB RAM (limit 192 MB) + ~10 MB for the proxy.
