# Home Server — Reference

Facts about the machine, not work to do. Outstanding work lives in
[HOME_SERVER_TODO.md](HOME_SERVER_TODO.md); finished work in
[HOME_SERVER_CHANGELOG.md](HOME_SERVER_CHANGELOG.md).

---

### RAM baseline

Mac mini M4, **16GB unified memory**. Docker VM ceiling is now **10GB** (raised
from 7.8GB on 2026-07-23), but that is a *ceiling*, not a reservation — the VM
allocates lazily.

Measured 2026-09-21 (evening) with 42 containers, after adding the
four-container Odysseus stack:

| Metric | Value | Reading |
|---|---|---|
| Containers, total | 7.59 GiB of the VM's 9.7 GiB | **2.11 GiB headroom** |
| macOS memory free | 30% | tighter; watch it |
| Swap used | ~3.3 GB of 4 GB | |

⚠️ **This was the tightest the host had been.** Resolved same night — see below.

**Measured 2026-09-21 (later) with 38 containers**, after removing Mealie (0
recipes, confirmed unused) and Grafana+Prometheus+node-exporter (Tailscale-only,
no scripts depended on it, credentials long forgotten):

| Metric | Value | Reading |
|---|---|---|
| Containers, total | **5.81 GiB** | ~1.78 GiB reclaimed vs the same-night peak |

Odysseus stack: odysseus ~745MB, searxng ~141MB, ntfy ~45MB, chromadb ~28MB.

Previous baselines: 2026-09-19, 39 containers, 5.55 GiB used / ~4.1 GiB free.
2026-09-08, 42 containers, 5.2 GiB used / 43% free.

Previous baseline, 2026-09-08 with 42 containers: 5.2 GiB of containers, 43%
free, ~2.5 GB swap.

**2026-09-26, adding Paperclip (44 containers):** before — 34–37% free, swap
10.2–10.3 GB of 11 GB used. After — **6.07 GiB** containers total, 36–38%
free, swap 9.7–10.0 GB used (did not grow). Paperclip itself: ~790–890MB idle
under a 1.5GB `mem_limit`; each Claude Code agent run adds ~300–500MB on top.
Later the same day, with two companies configured, it idled at ~1.2GB anon
and hit the cap 1500+ times → `mem_limit` raised to **2GB** (host free 37%,
swap 7.4–7.5 of 8GB before and after; the swap total had shrunk to 8GB).
Swap has only ~1–1.6 GB headroom — it is the constraint to watch, not
container RAM.

**2026-09-26 (evening), on-demand services — 42 → 30 running containers.**
Paperless-ngx (3), Nextcloud (2), Stirling PDF, IT-Tools, the Odysseus stack
(4) and FlareSolverr are now **stopped by default** (`scripts/utils/ondemand.sh`,
see *On-demand services* below).

| Metric | Before | After | Reading |
|---|---|---|---|
| Running containers | 42 | 30 | 12 on-demand, stopped |
| Containers, total (`docker stats`) | 6.60 GiB | **4.37 GiB** | **~2.2 GiB freed in the VM** |
| VM `free -m` used / available | — | 4.5 / 4.9 GiB | 3.3 GiB is Linux page cache |
| macOS memory free | 34% | 33% | unchanged — see below |
| Swap | 7.7 of 8.0 GB | 7.9 of 9.2 GB | macOS added a swap file; not shrinking |

Freed per service: stirling_pdf ~850MB, paperless ~580MB (+db/redis ~35MB),
odysseus ~370MB (+searxng/ntfy/chroma ~100MB), flaresolverr ~150MB,
nextcloud ~110MB (+db ~18MB), it_tools ~10MB.

⚠️ **Freeing RAM inside the Docker VM does not hand it back to macOS.** The
VM keeps pages it has touched (the space just becomes Linux page cache), so
the macOS free % and swap didn't move. The freed ~2.2 GiB is headroom for
containers — it went to Paperclip (`mem_limit` 2g → **3g**) — not relief for
macOS. The only lever that returns memory to macOS is a **lower VM ceiling**
in Docker Desktop (Settings → Resources → Memory; currently 10240 MiB, swap
2048 MiB). Recommended: **8 GB** — running containers sum to ~4.4 GiB, plus
Paperclip's agent-run spikes (+1–1.5 GiB), plus ~2.2 GiB if every on-demand
service is started at once, still fits. Needs a Docker Desktop restart, so
it's a 👤 step. Resource Saver doesn't help here: it only kicks in when **no**
containers are running.

### Memory budget and on-demand services

Rule of thumb for adding anything always-on: keep `docker stats` total under
~5 GiB and macOS swap not growing. Rarely used services are **on-demand**
instead of removed:

| Name (`ondemand …`) | Containers | Idle RAM | Why on-demand |
|---|---|---|---|
| `flaresolverr` | flaresolverr (in `sonarr-radarr`) | ~150MB | no Prowlarr indexer carries the `flaresolverr` tag |

**2026-09-27: Stirling PDF, IT-Tools (phase 1), Paperless, Nextcloud,
Odysseus, Linkwarden, Jellyseerr and Bazarr (phase 2) all moved from this
manual list to automatic scale-to-zero** (Caddy + Sablier,
`services/caddy/`) — gone from `ondemand.sh ENTRIES` because nobody needs to
run `ondemand start` for them any more; opening their hostname (or, for the
three Tailscale-only ones, the same `100.81.171.49:<port>` as before) starts
them. `flaresolverr` is the only thing left on manual `ondemand.sh` — it has
no hostname a browser opens, so there's nothing for Sablier to gate.

| Group (Sablier) | Containers | Running RAM | Idle RAM |
|---|---|---|---|
| `stirling-pdf` | stirling_pdf | ~977MB (JVM) | 0 |
| `it-tools` | it_tools | ~8MB | 0 |
| `paperless` | paperless, paperless_db, paperless_broker | ~536+28+10MB | 0 |
| `nextcloud` | nextcloud, nextcloud_db | ~79+104MB | 0 |
| `linkwarden` | linkwarden, linkwarden_db | ~349+24MB | 0 |
| `jellyseerr` | jellyseerr | ~195MB | 0 |
| `bazarr` | bazarr | ~188MB | 0 |
| `odysseus` | odysseus-{odysseus,searxng,chromadb}-1 | ~470MB (from the old on-demand measurement) | 0 |
| `calibre-web` | calibre_web | ~176MB | 0 |
| `audiobookshelf` | audiobookshelf | ~37MB | 0 |
| `jellyfin` | jellyfin | ~138MB | 0 |
| `caddy` + `sablier` (always on) | caddy, sablier | ~19–46MB each | — (never sleeps) |

`odysseus-ntfy-1` is deliberately **not** in the `odysseus` Sablier group —
it stays always-on (push must keep working while the rest of the stack
sleeps) and isn't counted above.

Measured 2026-09-27: cold start (stopped → first byte of the real app)
ranged ~5–45s depending on the app (Paperless's 3-container group is the
slowest; single containers like Jellyseerr/Bazarr/IT-Tools are under 15s).
Idle-stop confirmed for every group with a 2-minute test session duration
before setting the real value (30m for everything except Audiobookshelf and
Jellyfin, which got the real **2h** — long enough not to cut off playback).
All 15 phase-1+2+3 containers stopped again within ~2 minutes of their last
request during testing, staggered by when each was last hit.

**Gotcha found during phase 2, recurred as a design point in phase 3**:
Bazarr, Jellyseerr and Nextcloud shipped **no Docker healthcheck** in their
images. Without one, Sablier reports a container "ready" as soon as it's
merely `running`, not once its HTTP server has actually bound — Caddy's very
first reverse-proxied request to Bazarr got a `502 connection refused`
because of this exact race. Fixed by adding an explicit `healthcheck:` to
each of those three compose files (`curl`/`wget` against a local endpoint).
Phase 3: Calibre-Web and Audiobookshelf also shipped none (added the same
fix, `curl` for one, `wget` for the other — checked which binary each image
actually has first); Jellyfin already ships one and needed no change.
Paperless, Nextcloud's DB, Stirling PDF and Linkwarden already shipped one
too — check with
`docker inspect <container> --format '{{.Config.Healthcheck}}'` before
assuming any future Sablier-managed service is safe without one.

**Phase 3 also closed a bypass**: Calibre-Web, Audiobookshelf and Jellyfin
were reachable directly on `100.81.171.49:<port>` (their own port publish),
which — like Jellyseerr/Bazarr/Odysseus in phase 2 — bypassed Caddy and
couldn't wake a sleeping container. Same fix: their own bind narrowed to
`127.0.0.1`, Caddy's compose publishes the same port on the Tailscale IP.
Unlike the phase 2 three, these keep their public tunnel hostname too, so
each now has *two* Caddyfile site blocks (tunnel + Tailscale IP) sharing one
`sablier.group` and idle timer. One gap remains and is **not** fixed:
Jellyseerr calls Jellyfin directly over the Docker network
(`http://jellyfin:8096`) for its background library sync, which never
touches Caddy and so can't wake a sleeping Jellyfin — see
`services/caddy/README.md` "Gotchas".

All three phases of the scale-to-zero rollout are now live — see
`services/caddy/README.md` for the architecture, and the TODO for what's
still manual (Kuma monitor pausing, physical device tests on the TV/phone/
KOReader).

How it works and what it touches:
- `ondemand list | start <name> | stop <name> | stop-all` (zsh alias for
  `scripts/utils/ondemand.sh`). `start` = `docker compose start`, or `up -d`
  if containers don't exist yet; prints the URL.
- Stopping uses `docker compose stop`, never `down`: containers and networks
  stay, so Glance (which joins their networks) still starts. With
  `restart: unless-stopped` they stay stopped across Docker/Mac restarts;
  Watchtower has `WATCHTOWER_INCLUDE_STOPPED=false`.
- ⚠️ A manual `docker compose up -d` in one of these dirs starts it again
  (and for `sonarr-radarr` that includes FlareSolverr). Run
  `ondemand stop-all` afterwards.
- `homelab-audit.sh` reads `ondemand.sh containers` and treats them as
  expected-stopped — **and, separately, any container labelled
  `sablier.enable=true`** (derived from the Docker label, not hardcoded), so
  the phase 1/2 Sablier-managed containers are covered too.
- `backup-databases.sh` starts **only** `paperless_db` / `linkwarden_db` /
  `nextcloud_db`, dumps, and stops them again (trap on exit) — tested
  2026-09-26 (ondemand.sh era) and re-verified 2026-09-27 with all three now
  Sablier-managed: Sablier did not interfere.
- rclone file backups keep working; files at rest are actually better (no
  live-SQLite BadDigest on Odysseus's DBs).
- Glance: no monitors for them (they'd sit red), bookmarks in an *On demand*
  group, and the docker-containers widget is `running-only: true`. Same
  treatment for the phase 1/2 Sablier-managed services — their monitor
  `check-url` entries (Jellyfin/Audiobookshelf/Calibre-Web/Linkwarden/
  Jellyseerr/Bazarr) still exist for phase 3 and get removed as each moves.
- Uptime Kuma: their monitors (ids 3, 5, 13, 14, 25) are **paused**, not
  deleted — un-pause in the UI if one moves back to always-on. 👤 The
  phase 1/2 Sablier-managed services' monitors need the same manual pause —
  no config-file/API for it, tracked in the TODO.
- Moving a service back to always-on: remove it from `ENTRIES` in
  `ondemand.sh`, start it, un-pause its Kuma monitor, restore its Glance
  monitor. For a Sablier-managed one instead: remove the
  `sablier.enable`/`sablier.group` labels and the Caddyfile block, restore
  its direct tunnel route or port publish (see `services/caddy/README.md`
  "Rollback").

**How to read swap on macOS:** "Pages free" is always near zero by design — macOS
uses spare RAM as cache, so a low free-page count is not a warning. Judge by
*memory pressure percentage* and whether swap is **growing**. Stable or shrinking
swap is fine, even at 2.5GB. Growing swap plus pressure under ~20% is the real
alarm.

Biggest single consumers (2026-09-19): `immich_server` (~839MB), `paperless`
(~374MB), `stirling_pdf` (~360MB on 0.46; ~1.3GB right after start on 2.14 — JVM `MaxRAMPercentage=50`), `flaresolverr` (~302MB), `calibre` (~299MB).

**Containers safe to stop while traveling** (on top of the on-demand set):
`pihole`, `bazarr`, `sonarr`, `radarr`, `prowlarr`, `transmission` + `transmission-ts`, `jellyseerr`, `immich_machine_learning`

**This is the budget that rules out Octopus Deploy** — its SQL Server dependency
alone wants 2GB. See [guides/OCTOPUS_DEPLOY.md](guides/OCTOPUS_DEPLOY.md).

---

## Paperclip — facts and gotchas

- `http://100.81.171.49:3100` / `http://127.0.0.1:3100`. Ports bound to those
  two addresses explicitly — the LAN IP refuses connections (verified).
- **Every hostname used to reach it must be in `PAPERCLIP_ALLOWED_HOSTNAMES`**
  (`~/services/paperclip/.env`), including `paperclip` for Glance and
  `host.docker.internal` for Uptime Kuma. A missing one returns **403**, not
  a connection error.
- Agents run *inside* the container (the image bundles `claude`, `codex`,
  `gemini`, `opencode`). Container `$HOME` is `/paperclip` = `./data`, so CLI
  logins persist in `data/.claude/` etc. The host's Claude Code login can't be
  reused — it lives in the macOS Keychain.
- `paperclipai auth bootstrap-ceo` does **not** work in this container (no
  `config.json`; the image configures from env). Losing the admin password
  means Vaultwarden or nothing.
- Embedded Postgres on port 54329 inside the container; live dir excluded from
  R2, Paperclip's own daily dumps (`data/instances/default/data/backups/`,
  14 days) plus `secrets/master.key` are backed up.
- Health reports `databaseBackup: warning` until the first daily dump exists
  (24h after first start) — expected, not a fault.
- **Never mount anything read-only under `/paperclip`.** The entrypoint runs
  `chown -R /paperclip` as root on every start and crash-loops on a `:ro`
  mount there. The reports feed is at `/reports:ro` for that reason.
- Companies: **Homelab** (`8ee5781c-…`) and **Studio** (`2efa3f91-…`), both
  with board approval for hires. Direct `POST /agents` returns 409 while that
  is on — use `agent-hires` + approve. **Coach** (2026-09-27): drafted in
  `services/paperclip/README.md`, not yet created — needs the admin password
  (Vaultwarden) for a board session, which this batch didn't have.
- `${HOME}/.training:/training` (read-write) is mounted for the upcoming Coach
  agent's persistent memory. Same rule as `/reports`: never move athlete
  memory under `/paperclip` — the entrypoint's `chown -R /paperclip` as root
  crash-loops on a mount it can't fully own.
- The admin email/password are **no longer in `.env`** (moved to Vaultwarden
  2026-09-26) — the sign-in recipe in the README now prompts for the password
  interactively instead of reading it from a file.
- A task assigned while in **backlog** never wakes the agent; moving it to
  Todo does. Heartbeats are off on every agent.
- Codex agents share the container's ChatGPT login (`data/.codex/auth.json`,
  symlinked into each agent's `CODEX_HOME`). Paperclip defaults local agents to
  skip permission prompts — acceptable only because they're confined here.
- Board API auth: `POST /api/auth/sign-in/email` with an `Origin:
  http://127.0.0.1:3100` header, reuse the cookie. Recipe in the README.

---

## ntfy — only the Odysseus one is left

- `services/odysseus`'s bundled ntfy: port 8091, no auth, cache-only. Scoped
  to casual Odysseus reminders — don't point anything critical at it.
- A standalone, authenticated ntfy (`services/ntfy/`, port 8095) existed
  2026-09-27 → 2026-09-28 for the Paperclip Coach's push. Removed once the
  Coach team moved to Discord (ntfy's iOS app won't log in with a token and an
  empty username). Backup of its data/auth.db:
  `~/backups/ntfy-removed-2026-09-28.tgz`.

---

## DNS path (2026-09-28)

Device → (Tailscale DNS or LAN) → **Pi-hole** `100.81.171.49:53` (blocklists,
cache) → **unbound** `10.99.17.53` on the `pihole` Docker network (DNSSEC,
cache) → **DNS-over-TLS :853** → Quad9 / Cloudflare. Nothing leaves the house
as plain DNS. If `unbound` is stopped, Pi-hole resolves nothing. Rollback
line and wiring: `services/pihole/README.md` → *Encrypted upstream*.

## Image updates — WUD + upgrade-service.sh (2026-09-28)

- **WUD** (`services/wud`, `getwud/wud:9.2.0`, port 3070, Tailscale/localhost)
  reports available image updates; it never changes anything. Docker access
  via `tecnativa/docker-socket-proxy:v0.5.0` with `POST=0`.
- **WUD 9 refuses to start without an admin user** ("Authentication is
  mandatory") — `WUD_AUTH_ADMIN_USER/PASSWORD` in `~/services/wud/.env`; the
  scripts use a copy in `~/.config/homelab/wud.env`. Its API accepts HTTP
  basic auth with that login (`/api/containers`).
- `update-report.sh` → `~/services/glance/assets/updates.json` → Glance
  *Updates* widget; Discord summary Mondays 09:00.
- `upgrade-service.sh` is the only way pinned tags change. Rollback is
  automatic on failure; backups in `~/backups/upgrades/<svc>-<time>/`.
- macOS `/bin/bash` is **3.2** (cron uses it): no `mapfile`, no associative
  arrays in scripts meant for cron.
- Compose labels with a regex ending in `$` need `$$` (compose interpolation).

## Shared AI memory — `~/ai-memory` (2026-09-29)

Plain-markdown memory every agent reads and writes: Paperclip agents
(`/ai-memory`, read-write), Odysseus (`/ai-memory`, via its file tools —
`tool_path_extra_roots`), Claude Code on the Mac mini. Rules for agents are in
`~/ai-memory/README.md` (read first, write to `inbox/`, never delete others'
notes, no secrets). Layout: `people-and-preferences.md`, `projects/`,
`decisions/`, `inbox/`, **`training/`** (the Coach team's athlete memory —
folded in the same day it was written, see below), and **`finance/`** (private
read-only summaries; agents may advise but never transact).
- **Versioning:** local git repo, auto-committed every 15 min by
  `scripts/utils/ai-memory-commit.sh` (cron; log `~/logs/ai-memory.log`).
  Undo an agent's edit: `cd ~/ai-memory && git log -p` → `git revert <sha>`.
  Never pushed anywhere.
- **Backups:** nightly `rclone sync` to `r2:peciulevicius-backups/ai-memory`
  (Backup 7 in `rclone-backup.sh`, includes `.git`, so `training/` too); a
  second copy is rsynced to `/Volumes/backups/ai-memory` on the NAS when the
  `backups` share is mounted; monthly T5/T7 via `backup-external.sh`.
- Not the Obsidian vault — personal, agents don't write there.

### `~/ai-memory/training/` — was a separate `~/.training` mount

Started 2026-09-27 as its own mount for the Coach team (adaptive-endurance-coach
skill format: `athlete_profile.md`, `race_calendar.md`, `preferences.md`,
`coaching_notes.md`, `nutrition/`, `plans/`, `metrics/`, `progress_reviews/`,
`race_plans/`, `imports/`). Folded into `~/ai-memory/training/` on 2026-09-29:
one shared tree and one mount (`/ai-memory` in Paperclip and Odysseus) instead
of two, and one backup step instead of two. Every agent with `/ai-memory`
access can now see it, including Odysseus — a deliberate trade-off the user
chose over the earlier separation (this domain data used to be excluded from
the shared tree specifically to keep it out of Odysseus's reach). Coach and
Dietitian instructions (`services/paperclip/{coach,dietitian}-agents-addendum.md`)
were updated to the new paths and pushed to both agents' live instructions.

## Radicale (calendar / contacts / tasks)

- `http://100.81.171.49:5232/`, Tailscale + localhost only, user `dziugas`
  (password: `~/.config/homelab/radicale.env`). Collections: `personal`
  (events), `reminders` (VTODO), `contacts` (vCard).
- Inline `configs:` in the compose file can't be combined with
  `read_only: true` — Compose refuses ("`file` is the sole supported option").
- The "mtime resolution … RISKY" startup warning is the macOS bind mount;
  harmless while only Radicale writes the files.
- One UID per `.ics` resource: a hand-made file with two VEVENTs of different
  UIDs gets HTTP 400.

## Tailscale — what it's used for, and key expiry

**Used for (2026-09-28):**
- **Remote access** — every service on `100.81.171.49:<port>` (Paperclip,
  Jellyseerr, Odysseus, Transmission UI, …) from the phone/laptop anywhere,
  without opening router ports. Public-facing services use the Cloudflare
  Tunnel instead; Tailscale is the private door.
- **DNS** — tailnet DNS points at Pi-hole (`100.81.171.49`, *Override local
  DNS*), so ad blocking follows the phone everywhere.
- **Mullvad VPN** — the add-on's exit nodes; `transmission-ts` exits via
  Stockholm (see *Transmission runs behind a Tailscale sidecar*).

**Which devices use Pi-hole (+ the encrypted unbound upstream):** only
Tailscale devices with Tailscale on (tailnet DNS → Pi-hole, *Override local
DNS*). The router still hands out `192.168.1.1`, so the house LAN does **not**
depend on Pi-hole. The **Mac mini** itself runs `tailscale set
--accept-dns=false` (2026-09-28) and uses its Ethernet DNS `127.0.0.1` (Pi-hole)
with `192.168.1.1` as fallback, so the server keeps resolving (tunnel,
backups) even if Pi-hole/unbound is down. It also advertises itself as an
exit node (`--advertise-exit-node`, approved in the admin console) — the
"Lithuanian IP" option for the phone and laptop. Re-logging in the Tailscale
app can reset both flags; check with `tailscale debug prefs | grep -E 'CorpDNS|AdvertiseRoutes' -A2`.

**Key expiry — policy.** Every device has a node key that expires (default
180 days); an expired device silently drops off the tailnet until it logs in
again. It is **not** an `.env` value — it lives in each device's Tailscale
state.
- **Always-on machines you own → expiry disabled:** Mac mini, NAS,
  `transmission-ts`. (Admin console → Machines → device → ⋯ → *Disable key
  expiry*.) A dropped server is the expensive failure.
- **Portable devices → expiry kept on:** iPhone, MacBook. If one is lost, its
  access dies on its own. Renewing is just a login, so the dates don't need to
  match — each login restarts that device's 180 days.

**Renewing an expired/expiring key:**
- **iPhone / Mac app:** open Tailscale → it shows *Log in* / *Reauthenticate*
  → sign in. Done; same IP, same name.
- **`transmission-ts` (container)**, if expiry was ever re-enabled and ran
  out: admin console → Settings → Keys → *Generate auth key* (one-off), then
  `docker exec transmission-ts tailscale up --auth-key=<key> --exit-node=se-sto-wg-201.mullvad.ts.net --exit-node-allow-lan-access=true --accept-dns=false`.
  The `TS_AUTHKEY` in `~/services/transmission/.env` is only used on the very
  first login (`TS_AUTH_ONCE`), so editing it does nothing afterwards.
  While expired, the kill switch keeps Transmission offline — no leak.
- **Mac mini / NAS:** expiry is off; if a re-login is ever needed,
  `tailscale up` on the machine (NAS: in its container) and approve in the
  browser.

## Transmission runs behind a Tailscale sidecar

Since 2026-09-26 `transmission` uses `network_mode: service:transmission-ts`
(image `tailscale/tailscale:v1.102.5`). Facts worth knowing without opening the
`services/transmission/README.md`:

- `transmission-ts` is its own tailnet node (hostname `transmission-ts`,
  own `100.x` IP), kernel-mode tailscaled, `/dev/net/tun` + `NET_ADMIN` —
  Docker Desktop's VM provides the tun device; `SYS_MODULE` isn't needed.
- Login state: `~/services/transmission/data/tailscale/` (under the services
  backup). The auth key was single-use; lose this dir → new key needed.
- `transmission:9091` on `media` is a **network alias of the sidecar**.
- **Sidecar restarted alone → Transmission orphaned** on a dead netns (only
  `lo`). `docker compose up -d` doesn't repair it; `docker restart transmission`
  does. Glance's Transmission monitor goes red when this happens.
- Node key expires 2027-03-25 unless key expiry is disabled in the admin console.
- No exit node yet (Mullvad add-on not bought), so egress is still the home IP.
- Tailscale does **not** document fail-closed behaviour for an offline exit
  node — don't rely on it as a kill switch until tested.

---

## ⚠️ Cloudflare Tunnel caps uploads at 100MB

The free Cloudflare plan limits request bodies to **100MB**. Anything larger
fails on the way *in* through `*.peciulevicius.com`, and the error comes from
the app rather than Cloudflare — Calibre-Web reports *"File size may be too
big"*, which looks like an app setting and isn't.

Affects any upload: Calibre-Web, Immich, Nextcloud, Paperless.

**Workaround: skip the tunnel for large uploads.** Every service is also
reachable directly:

| Route | Address | Limit |
|---|---|---|
| Public hostname | `https://<svc>.peciulevicius.com` | **100MB** |
| Tailscale | `http://100.81.171.49:<port>` | none |
| On the Mac mini | `http://localhost:<port>` | none |

Downloads are unaffected — the cap is on request bodies only.

The homepage carries a **"Direct (no tunnel)"** bookmark group with the
Tailscale URLs for the four upload-heavy services, so the right link is one
click away rather than something to remember.

⚠️ **A failed large upload can leave the library half-written.** One 750MB
attempt through the tunnel produced a Calibre record with no file on disk, a
folder renamed while the database still pointed at the old name, and a
733MB `.smbdelete` duplicate. See the SMB section below.

## ⚠️ Two cloudflared LaunchAgents exist — only one is real

```
~/Library/LaunchAgents/com.cloudflare.cloudflared.plist   ← the one actually serving traffic
~/Library/LaunchAgents/sh.brew.cloudflared.plist          ← brew's own agent, inert
```

`brew services restart cloudflared` restarts the **second one**, silently —
it reports success either way, and the real tunnel process (started outside
Homebrew, `PPID 1`, running since whenever it was first set up) never notices
the config file changed underneath it. Confirmed 2026-09-22: after editing
`~/.cloudflared/config.yml`, `brew services restart cloudflared` reported
success but a request to the removed hostname still hung for 15s+ instead of
404ing — the old process, with the old config already read into memory, was
still running, untouched.

**To actually reload the tunnel after editing `config.yml`:**

```bash
launchctl kickstart -k "gui/$(id -u)/com.cloudflare.cloudflared"
```

Verify it worked by checking the PID and start time changed:

```bash
ps aux | grep "[c]loudflared tunnel"
```

`brew services stop cloudflared` is safe to run once, to stop the dead
duplicate from sitting in `error` state in `brew services list` — it does not
touch the real tunnel.

## ⚠️ Rotating a password only fixes one side of a connection

Radarr and Sonarr each store their **own separate copy** of Transmission's
login to talk to it — rotating Transmission's password (done 2026-09-19,
credential migration) does not touch that copy. Result, not caught until
2026-09-22: every release either app grabbed silently failed the handoff
(`Authentication Failure`) for three days, invisible unless you specifically
opened Radarr's queue and read the error detail — Jellyseerr showed the
request as accepted, nothing looked broken.

**When rotating any credential a *client* also stores its own copy of**, check
every consumer, not just the service whose password changed:

| Rotated | Also stored in | Check |
|---|---|---|
| Transmission | Radarr, Sonarr (download client settings) | `/api/v3/downloadclient/test` |
| Pi-hole | Glance (`PIHOLE_PASSWORD` in `~/services/glance/.env`, DNS-stats widget — since the v6 upgrade, 2026-09-25) | homepage DNS widget shows numbers, not an error |
| Vaultwarden's own login | nothing — it's the source of truth | — |
| Any `*@peciulevicius.com` alias | wherever that alias is the *login*, not just the notify address | per-service |

This is the same class of risk as the [malware release profile](#) below —
a change that looks complete from the changed service's side can be silently
broken from a consumer's side. Verify the *consumer*, not just the source.

## 🔴 A fake "movie" release is often a bare `.exe` — check before it finishes

Caught 2026-09-22: a Radarr-grabbed release of a new movie was a
single 1.15GB `.exe` file, no video container, already 19% downloaded before
anyone looked. This is a known piracy-scene scam pattern — a fake release
with a real-looking name whose payload is a Trojan installer, not media.

**Manual check, if you ever want to look yourself** (Transmission's web UI or
API, before a download finishes): open the torrent's file list.

- ✅ **Legitimate:** one `.mkv`/`.mp4`/`.avi` as the bulk of the size, optionally
  with `.srt`/`.nfo`/small `.txt` siblings (release-group attribution files are
  normal and harmless)
- 🔴 **Fake:** the *only* substantial file is `.exe`/`.scr`/`.msi`/`.bat`/`.zip`,
  or a video-shaped name that actually resolves to one of those extensions

**Automated, added the same day:** a **release profile** in both Radarr and
Sonarr (Settings → Custom Formats, or `/api/v3/releaseprofile`) that rejects
any release whose name contains `.exe .scr .lnk .msi .bat .cmd .vbs .jar`,
`password.txt`, `setup.exe`, `installer` — **before it ever reaches a download
client**, not just cleaned up after. This is now a standing, automatic
protection; nothing to run by hand going forward. Verify it's still there:

```bash
curl -s "http://localhost:7878/api/v3/releaseprofile" -H "X-Api-Key: <radarr-key>"
```

⚠️ **It only catches releases naming the bad extension in the release title
itself** — this specific scam did (the release name ended in `.exe`), which is why the filter
works, but a more careful fake could rename the payload after download to
something less obvious. It raises the bar; it doesn't guarantee zero risk. If
you ever manually eyeball a torrent's file list and it doesn't look like §
above, delete it — don't run anything from `/Volumes/media`.

## 🚫 Never rename a book in Calibre-Web

**Renaming a book's title or author in Calibre-Web will corrupt the library
entry on this setup.** It happened twice on 2026-09-21, both times identically:

1. Calibre-Web renames the folder on disk
2. It copies the EPUB to the new filename
3. It tries to delete the original — and **SMB refuses**: *"Device or resource
   busy"*, because the Calibre content server still holds a handle
4. It rolls the database back, but **not the folder rename**

You are left with `metadata.db` pointing at the old path, a folder with the new
name, two copies of a 769MB file, and the book 404ing.

The cause is renaming large files on an **SMB share with the library open by two
services** — the same class of problem as never putting a database on SMB.

> **Since 2026-09-25 the library lives on the internal SSD**
> (`~/services/calibre/library`), so the SMB half of this cause is gone. The
> rule stays until a rename has been tried and verified on the SSD — the
> second service holding a handle is still a factor. Paths in the repair
> below are now under `~/services/calibre/library`.

### Repair

```bash
# Rename the folder back to whatever metadata.db expects:
sqlite3 /Volumes/books/metadata.db "select path from books where id=<ID>;"
mv "/Volumes/books/<wrong name>" "/Volumes/books/<path from the DB>"
```

The duplicate EPUB left behind is usually locked server-side. Stopping the
containers and remounting the share does **not** always clear it — the lock
lives on the NAS. Clear it from the NAS's own file manager, or leave it; it is
excluded from the R2 backup.

### What to do instead

| Want | Do |
|---|---|
| **Mark a book as read-along/aligned** | Add a **tag** in Calibre-Web. Tags are metadata-only — no file or folder is touched, and KOReader's OPDS browser can filter by them. |
| **A different title** | Set it **before** importing, by editing the EPUB's metadata on the Mac: `ebook-meta book.epub --title "Can't Hurt Me (read-along)"`. Calibre reads the title from the file, so it imports correctly and nothing needs renaming afterwards. |
| Anything else that renames files | Do it from the **Calibre desktop app with the library local**, not over SMB. |

⚠️ Tags are also the answer to *"how do I tell which book is aligned from the
Kindle?"* — a `read-along` tag shows up as a browsable category in the OPDS feed.

## SMB leaves `.smbdelete*` files behind

(Calibre-specific examples below are historical — the library left SMB on
2026-09-25. The mechanism still applies to every other share.)

When a file is deleted on an SMB share while a process still holds it open, the
server renames it to `.smbdeleteXXXX` instead of removing it. These are
byte-identical copies of real files — one was **733MB** — and they linger until
every handle closes.

```bash
find /Volumes/books -name ".smbdelete*" -exec ls -lh {} \; 2>/dev/null
find /Volumes/books -name ".smbdelete*" -delete          # "Resource busy" = still held
```

If they refuse to delete, restarting the containers that touch the share
(`calibre`, `calibre-web`, `lazylibrarian`) releases most of them. A stubborn
one needs the share unmounted and remounted, or deletion from the NAS itself.

**Seen 2026-09-26 with a container restart not helping:** `lsof` showed the
holder was Docker Desktop's virtualization process itself
(`com.apple.Virtualization…`), which keeps handles to files a container
touched even after that container restarts — the same process holds the
Immich backup and `media/downloads` ghosts. Only a Docker Desktop restart
releases those.

`rclone-backup.sh` **excludes them** — otherwise a 733MB duplicate would be
uploaded to R2 as if it were a book.

## Services with an SMB-mounted library don't reliably notice new files

A media server's real-time file watcher does not reliably fire on an
SMB-mounted share. **Confirmed** for Jellyfin (`/Volumes/media`) 2026-09-22 —
a Radarr import completed, the file sat correctly in `/media/movies/`, and
Jellyfin's logs showed zero scan activity until the container was
**restarted**, which forces a full library scan on startup and picked it up
immediately. **Audiobookshelf** (`/Volumes/audiobooks`) runs the identical
watcher-on-SMB pattern — no confirmed failure yet, covered preventively since
the root cause is architectural, not specific to Jellyfin.

**Former stopgap, removed 2026-09-28:** `scripts/utils/smb-watcher-rescan.sh`
restarted both containers every 30 minutes. The cron entry was removed because
it woke Sablier-managed sleepers and interrupted playback. The live crontab was
checked on 2026-09-30; neither recurring media-service restarts nor SMB rescan
jobs remain. A sleeping service scans when it next starts.

**Real fix, needs a person, per service:**
- **Jellyfin** — generate an API key (dashboard → Admin → API Keys), then enter
  it directly in Radarr and Sonarr → Settings → Connect as a native Jellyfin
  notification. Keep the key in those local service settings; do not paste it
  into chat or Git. This refreshes only the imported item, with no restart or
  playback interruption.
- **Audiobookshelf** — research on 2026-09-30 found LazyLibrarian's
  [Notify on Download and custom-script notifier](https://lazylibrarian.gitlab.io/config_notifications/)
  and Audiobookshelf's documented `POST /api/libraries/{id}/scan` endpoint in
  its [API reference](https://api.audiobookshelf.org/). This suggests a
  custom-script integration is possible, but it is not configured or tested
  here. The API reference says it is outdated; verify the installed API and
  how LazyLibrarian can access the script before wiring it. Audiobookshelf is
  Sablier-managed, so the hook must not unexpectedly wake it. Keep its API
  token private.

See `HOME_SERVER_TODO.md`.

---

## Drive Layout (reference)

Since the 2026-08-04 migration the **NAS is primary**. The two Samsung SSDs are
backup targets only, plugged in occasionally and synced by hand.

| Device | Size | Role | Mount path | Connected? |
|--------|------|------|-----------|---|
| **UGREEN NAS** | ~11TiB usable (RAID 5) | Primary storage | `/Volumes/<share>` | always, over SMB |
| **T7** | 1TB | Manual backup | `/Volumes/T7/` | **normally unplugged** |
| **T5** | 500GB | Manual backup, destined offsite | `/Volumes/Backup/` | **normally unplugged** |

**T7 and T5 are disconnected by design and were confirmed unplugged on
2026-09-19.** The migration to the NAS is finished: every service reads from
`/Volumes/<share>`, T7 was fully decoupled on 2026-08-04, and the nightly
external-drive cron was deleted on 2026-09-05 precisely because the drives
aren't attached. Any doc or script path mentioning `/Volumes/T7` is describing
**what to do once you plug it back in**, not a live mount.

Photos live in **Immich, on the NAS** — that is the source of truth now. The
year folders still sitting on T7 are an *unimported archive*, not a working
copy.

**What lives where:**

| Data | Where | Path |
|------|-------|------|
| Immich photos | NAS | `/Volumes/immich/upload` |
| Immich database | Internal SSD | `~/services/immich/data/postgres` (never on SMB — DBs corrupt over network mounts) |
| Immich thumbnails | Internal SSD | `~/services/immich/data/thumbs` (SSD for fast scrolling; regenerable) |
| Media (movies, TV, downloads) | NAS | `/Volumes/media/` |
| Audiobooks | NAS | `/Volumes/audiobooks/` |
| Calibre library (books + `metadata.db`) | Internal SSD | `~/services/calibre/library` — moved off SMB 2026-09-25 (SQLite must not live on SMB). Path is `BOOKS_DIR` in the calibre, calibre-web and lazylibrarian `.env`s. The old NAS copy `/Volumes/books` is a **frozen rollback** until ~2026-10-02, then deleted |
| CouchDB (Obsidian LiveSync) | Internal SSD | `~/services/couchdb/data` (database — never on SMB) |
| Obsidian vault | Internal SSD | `~/obsidian-vault` |
| Docker data | Internal SSD | `~/Library/Containers/com.docker.docker` |

**Still on T7 and not yet in Immich:** the year folders (`2002`–`2024`, plus a few named and
unsorted folders) — ~140GB of archives, see TODO #20. T5 holds copies of the same
folders, so they are not single-copy, but **do not wipe T7 until they are imported**.

**Cloud backup (rclone → Cloudflare R2), nightly 5am:**
- Docker service configs, obsidian vault, Calibre books, DB dumps → R2 `peciulevicius-backups`
- Script: cron runs the staged copy `~/services/rclone/rclone-backup.sh`, config in `~/services/rclone/.env` (one script path, one `.env` — two copies silently dropped the Immich step once)
- ~2.9GB total (critical-only; audiobooks excluded from R2), **$0/month** — under
  the 10GB free tier
- **Immich photo originals — enabled 2026-09-21.** `/Volumes/immich/upload/upload`
  → R2 `immich-photos/`, **72.4GB, 6,696 files, zero errors**
  (encoded-video/thumbs/backups excluded as regenerable or redundant with the
  DB dump above). Second offsite copy alongside the T5 drive plan below.
  Total R2 bill is now ~$1/month. See `services/rclone/README.md`.
- **Verified monthly** by `scripts/backup/r2-verify.sh` (one random file per
  set restored and byte-compared; size history in `~/logs/r2-size-history.tsv`)
- **Restore:** `scripts/backup/restore.sh list | service <name> | set
  <vault|dumps|books|photos>`, always into `~/services-restore/`; `restore.sh db`
  loads a dump back into its container

**Local backup (rsync NAS → external drive), MANUAL — no cron:**
- `~/.dotfiles/scripts/backup/backup-external.sh /Volumes/T7` (or `/Volumes/Backup` for T5)
- Each successful run stamps `~/logs/external-backup-<drive>.last`; the weekly
  `homelab-audit.sh` fails once a drive is over 30 days stale
- Covers: Immich originals + transcoded video, **database dumps**, audiobooks, Calibre books
- Skips: media (movies/TV — too large, re-downloadable), Immich thumbnails (regenerable)
- Both drives verified 1:1 against the NAS on 2026-09-05

**If the NAS dies:** photos + books + audiobooks + DB dumps on T7 and T5. Configs on R2.
Re-download media.
**If a drive dies:** re-run the script against a replacement.
**If the Mac mini dies:** all data safe on the NAS. Reinstall macOS, clone dotfiles,
restore configs from R2.

**The gap:** T7 and T5 currently sit in the same room as the NAS, so nothing survives
fire/flood/theft. Moving T5 offsite (the parents' house plan) is what makes this 3-2-1
for everything *except* photos. Photo originals additionally have a cloud-based
offsite option (`BACKUP_IMMICH_PHOTOS=true`, above) that doesn't depend on a trip
to the parents' house — the two are complementary, not either/or.

---

## Quick reference

| Service | Container path | Mac mini path |
|---|---|---|
| Radarr/Sonarr media | `/media` | `/Volumes/media` |
| Radarr movies | `/media/movies` | `/Volumes/media/movies` |
| Sonarr TV | `/media/tv` | `/Volumes/media/tv` |
| Transmission downloads | `/downloads` | `/Volumes/media/downloads` |
| Audiobookshelf | `/audiobooks` | `/Volumes/audiobooks` |
| Calibre library | `/books` | `~/services/calibre/library` (internal SSD; was `/Volumes/books` until 2026-09-25) |
| Immich photos | `/usr/src/app/upload` | `/Volumes/immich/upload` |
| Immich thumbnails | `/usr/src/app/upload/thumbs` | `~/services/immich/data/thumbs` (internal SSD) |
| Immich DB | `/var/lib/postgresql/data` | `~/services/immich/data/postgres` (internal SSD) |

All `/Volumes/<share>` paths are NAS SMB mounts — see `docs/NAS.md`.
