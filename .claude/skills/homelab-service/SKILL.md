---
name: homelab-service
description: Add, remove, or change a Docker service in the Mac mini homelab (services/<svc>/). Use whenever a service is deployed, removed, renamed, or its docker-compose.yml / scripts change. Covers staging to ~/services, the Glance homepage, Cloudflare Tunnel, backups, credentials and docs — the steps that were repeatedly missed.
---

# Homelab service change checklist

Every item below exists because it was skipped at least once and broke
something. Work through the relevant section top to bottom; don't report done
until the verification block passes.

## ⚠️ The rule that bites most

`~/services/<svc>/` is a **copy** made by `services/setup-services.sh`, not a
symlink. Editing `services/<svc>/…` in the repo changes **nothing** that is
running. After any edit (except `.env`):

```bash
cp ~/.dotfiles/services/<svc>/<file> ~/services/<svc>/<file>
diff ~/.dotfiles/services/<svc>/<file> ~/services/<svc>/<file>   # must be silent
cd ~/services/<svc> && docker compose up -d                       # recreate to apply
```

Never `cp` over a **script that is currently running** (e.g. `rclone-backup.sh`
mid-backup) — bash reads scripts incrementally and the running process
crashes. Check `pgrep -fl <script>` first.

## Adding a service

1. **Repo files** — `services/<svc>/docker-compose.yml`, `.env.example`
   (placeholders only, never real values), `README.md` (what/why/how).
   Bind ports to what's needed; Tailscale-only services must not get a tunnel.
2. **setup-services.sh** — add to both `SERVICES=(…)` and `SERVICE_PORTS=(…)`.
3. **Stage and start** — run `services/setup-services.sh` (it never overwrites
   an existing `.env`), fill `~/services/<svc>/.env`, `docker compose up -d`.
4. **Secrets** — generate the password in Vaultwarden (username
   `peciulevicius`, entry has the URL for autofill). Add a row to
   `docs/CREDENTIAL_MIGRATION.md` — **no values**, repo is public.
5. **Homepage (Glance)** — in `services/glance/glance.yml` add a monitor with
   `check-url` **and** a bookmark; add the service's Docker network to
   `services/glance/docker-compose.yml` (both the service's `networks:` list
   and the top-level `external: true` block). Then re-stage both files and
   `docker compose up -d` Glance — an unrestaged glance.yml keeps showing the
   old state.
6. **Public access (only if it should be public)** — add a hostname to
   `~/.cloudflared/config.yml` and a DNS route, then reload the **real**
   tunnel agent:
   `launchctl kickstart -k "gui/$(id -u)/com.cloudflare.cloudflared"`
   (`brew services restart cloudflared` restarts a dead duplicate agent and
   silently does nothing). Verify with `curl -o /dev/null -w '%{http_code}'`.
7. **Monitoring** — Uptime Kuma monitor for it.
8. **Backups** — decide explicitly:
   - service data under `~/services/<svc>/` is backed up by default;
   - Postgres/MariaDB data dirs → exclude in `services/rclone/rclone-backup.sh`
     and add a dump to `scripts/backup/backup-databases.sh` instead;
   - live SQLite files the container rewrites constantly → exclude (they fail
     R2's MD5 check mid-upload);
   - regenerable caches, media, model downloads → exclude.
9. **Mobile app** — add a row to the Mobile Apps table in `docs/SERVICES.md`.
10. **If it touches a shared credential or email** — see the
    `credential-rotation` skill; check every consumer.

## Removing a service

1. Confirm it's actually unused (data dir contents, logs, dependents via
   `grep -r <svc> ~/.dotfiles/scripts ~/services/*/docker-compose.yml`).
2. `cd ~/services/<svc> && docker compose down`.
3. Remove it from Glance (monitor + bookmark + network, both files), re-stage,
   recreate Glance, **then** `docker network rm <network>` (it stays "in use"
   until Glance lets go).
4. Remove the tunnel hostname if any, kickstart the real cloudflared agent,
   confirm the hostname now 404s.
5. Remove from `setup-services.sh` (both arrays), rclone excludes that
   reference it, `backup-databases.sh` if dumped.
6. `git rm -r services/<svc>`. Deleting `~/services/<svc>` needs `rm -rf` —
   ask the user to run it.
7. Docs — remove from `docs/SERVICES.md` (every table), note in
   `docs/HOME_SERVER_CHANGELOG.md` *why* it was removed.

## Docs (same commit, always)

- `docs/SERVICES.md` — service tables, remote-access table, mobile apps
- `docs/HOME_SERVER_REFERENCE.md` — facts (RAM, paths, gotchas found)
- `docs/HOME_SERVER_TODO.md` — anything left undone
- `docs/HOME_SERVER_CHANGELOG.md` — what changed and why, newest at top
- `.claude/CLAUDE.md` container count if it changed

## Verification — all must pass

```bash
docker ps --format '{{.Names}}\t{{.Status}}' | grep <svc>        # up (or gone)
~/.dotfiles/scripts/utils/homelab-audit.sh                        # drift + health
curl -s localhost:7575 | grep -ic <svc>                           # on/off homepage
git status --short && git diff --staged --stat                    # everything staged
```

Commit (the pre-commit hook runs gitleaks), then **push** — other machines
sync via `scripts/sync.sh`.
