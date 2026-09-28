# Caddy + Sablier — scale-to-zero

Why: the Mac mini is memory-bound (16 GB shared between macOS and the Docker
VM). A handful of services are opened a few times a week at most. Instead of
running them 24/7 (or stopping them by hand with `ondemand.sh`), Caddy fronts
them and asks **[Sablier](https://github.com/sablierapp/sablier)** to start
the container(s) on the first request and stop them again after a period of
no traffic.

## How it works

```
cloudflared → Caddy (127.0.0.1:8880) → Sablier (start/stop via Docker socket)
                                      → reverse_proxy → the app's container
```

- `cloudflared` still terminates the public hostname and forwards to a local
  port — it just forwards *several* hostnames to the same port (8880) now,
  because Caddy tells them apart by the `Host` header cloudflared preserves.
- Caddy is a custom build (`Dockerfile`, xcaddy) with the
  [`sablier-caddy-plugin`](https://github.com/sablierapp/sablier-caddy-plugin)
  compiled in — there's no prebuilt image
  ([issue #10](https://github.com/sablierapp/sablier-caddy-plugin/issues/10)).
- Sablier watches the Docker socket. Any container labelled
  `sablier.enable=true` is one it's allowed to start/stop; `sablier.group=x`
  groups containers that must start together (an app + its DB).
- Two strategies, picked per app (see the Caddyfile):
  - **`blocking`** — hold the request until the app answers (timeout 60s).
    For native apps (Jellyfin on a TV, Audiobookshelf on the phone, KOReader
    over OPDS) that can't render a "loading" page.
  - **`dynamic`** — serve a "starting…" page to a browser, which polls and
    redirects once the app is up. For tools opened directly in a browser.
- `session_duration` is how long the container stays running after the last
  request Sablier sees pass through Caddy. Streaming counts as continuous
  requests, so an active Jellyfin/Audiobookshelf stream keeps it alive.

## Rollout

Each phase: add the `sablier.enable`/`sablier.group` labels, add the
Caddyfile block, point `~/.cloudflared/config.yml` at Caddy for that
hostname (or, for Tailscale-only apps, let Caddy own the Tailscale-facing
port), test with a short `session_duration` (2m) to prove start+stop both
work, then set the real duration and reload cloudflared.

| Phase | Services | Strategy | Idle | Status |
|---|---|---|---|---|
| 1 | Stirling-PDF, IT-Tools | dynamic | 30m | done 2026-09-27 |
| 2 | Paperless, Nextcloud, Odysseus, Linkwarden, Jellyseerr, Bazarr | blocking (dynamic for Odysseus) | 30m | done 2026-09-27 |
| 3 | Calibre-Web, Audiobookshelf, Jellyfin | blocking | 30m / 2h / 2h | done 2026-09-27 |

## Groups

| Group | Containers |
|---|---|
| `stirling-pdf` | stirling_pdf |
| `it-tools` | it_tools |
| `paperless` | paperless, paperless_db, paperless_broker |
| `nextcloud` | nextcloud, nextcloud_db |
| `odysseus` | odysseus-odysseus-1, odysseus-searxng-1, odysseus-chromadb-1 (labelled locally — see "Odysseus is special" below) |
| `linkwarden` | linkwarden, linkwarden_db |
| `jellyseerr` | jellyseerr |
| `bazarr` | bazarr |
| `calibre-web` | calibre_web |
| `audiobookshelf` | audiobookshelf |
| `jellyfin` | jellyfin |

Odysseus's bundled ntfy stays **out** of the `odysseus` group on purpose, so
reminders still arrive while the app sleeps.

## Tailscale-only apps

Jellyseerr, Bazarr and Odysseus were reachable directly on
`100.81.171.49:<port>` (their own `docker compose` port publish). A direct
hit like that bypasses Caddy entirely and can't wake a sleeping container —
so scale-to-zero needs Caddy to *own* that Tailscale-facing port instead:

1. The app's own port publish was narrowed to `127.0.0.1:<port>:<port>`
   (still reachable on localhost for debugging, no longer on Tailscale).
2. Caddy's compose publishes the same port number on the Tailscale IP
   (`100.81.171.49:<port>:<port>`) and reverse-proxies to the app over the
   shared Docker network by container name — the host port publish on the
   app side is irrelevant to that path.
3. `100.81.171.49:5055` (Jellyseerr), `:6767` (Bazarr) and `:7001` (Odysseus)
   now go through Sablier the same as the tunnel-facing hostnames.

**Calibre-Web, Audiobookshelf and Jellyfin get the same treatment, in
addition to their public tunnel hostname** (they're not Tailscale-only —
these three also have `books.`/`listen.`/`watch.peciulevicius.com`). LAN
clients, a TV app, or KOReader configured with the Tailscale IP instead of
the hostname were hitting `100.81.171.49:8083`/`:13378`/`:8096` directly,
bypassing Caddy — a sleeping container there just refused the connection
instead of waking. Same fix: their own port publish narrowed to
`127.0.0.1:<port>:<port>`, Caddy's compose publishes the same port number on
the Tailscale IP, and the Caddyfile has **two** site blocks per app — one on
`:8880` for the tunnel, one on the Tailscale IP for direct/LAN access — both
pointing at the same `sablier.group`, so either route starts it and both
share the same idle timer.

**Odysseus is special**: its `docker-compose.yml` lives in the Odysseus repo
clone (`~/services/odysseus/`, cloned by `services/odysseus/setup.sh` from
`github.com/odysseus-dev/odysseus`), not in this dotfiles repo. The
`sablier.enable`/`sablier.group=odysseus` labels and the `APP_BIND=127.0.0.1`
change were applied **locally to that live file**, not committed anywhere —
document it here so a future re-clone/update of Odysseus knows to reapply
them. `ntfy` (bundled in the same compose file) keeps `APP_BIND`/`NTFY_BIND`
untouched — it must stay always-on.

## Backups

`scripts/backup/backup-databases.sh` starts a stopped DB container directly
with `docker start` (not through Caddy/Sablier), dumps it, and stops it again
itself. Sablier's own reconciliation (`--provider.auto-stop-on-startup`,
default `true`) only runs once, at Sablier's own boot — it does not
continuously watch for externally-started containers unless
`--provider.auto-stop-externally-started` is set (it isn't here). Verified
2026-09-27: ran the backup with `paperless_db`, `linkwarden_db` and
`nextcloud_db` all asleep — all three dumped cleanly and Sablier never
touched them.

## Monitoring

- **Glance**: the "Services" monitor widget's `check-url` for every
  Sablier-managed app was removed (kept `url` for the link only) — a
  `check-url` hits the container directly, which would either show a false
  "down" for a sleeping app or, if pointed at the public hostname instead,
  silently wake it every polling interval. They're still on the homepage as
  plain bookmarks in their category groups. The `docker-containers` widget
  already uses `running-only: true`, so a sleeping container just doesn't
  list — no change needed there.
- **Uptime Kuma**: monitors for the Sablier-managed apps should be **paused**
  (same reasoning as Glance) — 👤 manual, Kuma has no config file, do it in
  the UI: Settings → the affected monitors → Pause. Add two **new** active
  monitors instead: one HTTP monitor on `http://100.81.171.49:8880` (or
  through the tunnel) hitting Caddy, and one on `sablier:10000/api/health` or
  the container's health status, so Caddy/Sablier being down is still caught
  even though the apps it fronts are expected to look stopped.
- **homelab-audit.sh**: the "Containers" check treats any container with the
  Docker label `sablier.enable=true` as expected-stopped automatically
  (`docker ps -aq --filter label=sablier.enable=true`), the same way it
  already treats `ondemand.sh containers` — no hardcoded list to maintain.

## Rollback

Per phase, per hostname:

1. `~/.cloudflared/config.yml` — restore the hostname's line to point
   straight at the app's own port (the pre-Caddy lines are commented out
   inline in that file's history / `scripts/setup/setup-cloudflare-tunnel.sh`
   git history — `git log -p` on this repo's copy of the tunnel script has
   the original `SERVICES` map).
2. For a Tailscale-only app: restore its own compose `ports:` bind from
   `127.0.0.1:<port>:<port>` back to `<port>:<port>` (or
   `0.0.0.0:<port>:<port>`), re-copy to `~/services/<svc>`, recreate.
3. Reload the real tunnel agent:
   `launchctl kickstart -k "gui/$(id -u)/com.cloudflare.cloudflared"`.
4. Remove the `sablier.enable`/`sablier.group` labels (optional — a label on
   a container Caddy never routes to does nothing).
5. `docker compose stop caddy sablier` if nothing is using them any more.

## Gotchas

- Caddy binds `127.0.0.1:8880` — cloudflared and Caddy must be on the same
  host (they are: both run on the Mac mini).
- `auto_https off` and `admin off` are set globally in the Caddyfile — TLS is
  terminated at Cloudflare, and Caddy has no public admin API to protect.
- A stopped app's *own* published port (e.g. Stirling-PDF's `8084`) still
  answers if hit directly on localhost — Docker doesn't remove a port publish
  just because Sablier stopped the container, it just won't accept
  connections. That's fine; nothing but a human at the console hits it.
- Sablier's `dynamic` loading page polls the app itself, not Caddy — don't
  point `dynamic`'s `display_name`/theme assets at anything that also needs
  waking.
- **A container with no Docker healthcheck can make Sablier report "ready"
  before it actually is.** Without one, Sablier's readiness check is just
  "is the container in the `running` state" — for an app whose HTTP server
  takes a couple more seconds to bind after the process starts (common:
  Node, Python/gunicorn, PHP-FPM), Caddy's very first reverse-proxied
  request can land in that gap and get a `502`. Caught on Bazarr in phase 2;
  fixed there and pre-emptively on Jellyseerr and Nextcloud by adding a
  `healthcheck:` to their compose files. Before adding a new
  Sablier-managed service, check
  `docker inspect <container> --format '{{.Config.Healthcheck}}'` — if it's
  `<nil>`, add one (`curl`/`wget` against a local endpoint is usually enough;
  check what the image actually has with
  `docker exec <container> sh -c 'which curl wget nc'` before picking one).
- Editing `Caddyfile` or `docker-compose.yml` here follows the same
  copy-not-symlink rule as every other service: re-copy to
  `~/services/caddy/` and `docker compose up -d --build caddy` (rebuild is
  needed for `Dockerfile` changes; a Caddyfile-only change just needs
  `docker compose restart caddy` after the re-copy, since it's bind-mounted).
- `setup-services.sh` only copied `docker-compose.yml`, `.env.example` and
  `*.sh` before phase 1 — it now also copies `Dockerfile`/`Caddyfile` (added
  for this service) and any other top-level `*.yml` a service ships (added
  during phase 2, after `glance.yml` turned out to have never been staged by
  it at all). If a future service adds yet another config file type, extend
  `stage_service()` again rather than relying on a manual `cp`.
- **A client that talks to a Sablier-managed app over the Docker network
  directly (not through Caddy) won't wake it and won't notice it's asleep
  until the call fails.** Jellyseerr talks to Jellyfin this way
  (`http://jellyfin:8096` from inside the `media`/`jellyfin` networks, for
  its periodic library-sync job and for browsing) — that traffic never
  passes through Caddy, so it can't trigger Sablier and will just error out
  while Jellyfin is asleep. This is a known, accepted gap: reconfiguring
  Jellyseerr to reach Jellyfin through Caddy would need Jellyseerr to send a
  specific `Host` header Caddy could match on, which its settings UI doesn't
  expose. In practice this means Jellyseerr's background sync silently no-ops
  while Jellyfin naps, and picks back up once something else (a person
  opening Jellyfin) wakes it — not ideal, but not a correctness problem
  either. If Jellyseerr's sync logs start showing repeated connection errors
  to Jellyfin, that's why.
