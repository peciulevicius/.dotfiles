# Glance

Dashboard/start page (`glanceapp/glance`), served at `home.peciulevicius.com`
and `http://100.81.171.49:7575` / `http://localhost:7575`. Config is
version-controlled here; the live copy is a **copy**, not a symlink — see
`~/.dotfiles/.claude/CLAUDE.md` and the `homelab-service` skill for the
copy → diff → recreate workflow.

## Layout (redesigned 2026-09-27)

**Home page**, one `full`-width column for services + one `small` side column
for everything else:

1. **`monitor` — "Always-On Services"**: a compact status grid, `check-url`
   against every service that is *not* Sablier-managed. 19 sites.
2. **`bookmarks`**: every service on the homelab, exactly once, grouped by
   purpose — **Media**, **Files & Docs**, **Security & Network**, **AI &
   Agents**, **Ops**. A 💤 prefix on the title marks a Sablier scale-to-zero
   service (`services/caddy/`) — asleep by default, opens on click.
3. **`docker-containers` — "Live Status"**: `running-only: true`. This is how
   a 💤 service's *current* awake/asleep state shows up without Glance ever
   polling it directly — when someone opens a sleeper and Sablier starts it,
   its container appears here; once Sablier stops it again it drops back out.

A one-line `html` legend sits under the bookmarks: 💤 means *sleeps when
idle, wakes when opened*, not *asleep right now* (the live state is the
**Sleeping apps** widget). Added 2026-09-28 after "5 / 11 awake" next to
eleven 💤 tiles read as a mismatch.

Side column: **Training**, **Coach team**, **Homelab health**, **Sleeping
apps** (all below), `server-stats`, `dns-stats`
(Pi-hole), `repository` (this repo), `calendar`, `weather`, `clock` — moved
here (2026-09-27) so the full-width column is 100% services.

## Homelab health widget (added 2026-09-27)

A `custom-api` widget at the top of the side column. It shows:
- Docker VM memory, macOS swap, and disk usage (Mac data volume and NAS)
- how long ago the R2 backup, the DB dumps and the T5/T7 drive backups ran
(the 💤 count, Paperclip queue, check-in age and Dietitian line moved to
their own widgets on 2026-09-28, see below)

Each value is coloured green, amber or red.

**How it works.** Glance can't see any of that from inside its container:
macOS swap, the APFS *data* volume (`df /` only shows the sealed system
volume, ~38%, while the real disk is ~90%), backup stamps in `~/logs`, the
Paperclip board and `~/.training`. So `scripts/utils/homelab-status.sh` runs on
the host every 5 minutes (cron) and writes
`~/services/glance/assets/status.json`.

Glance serves that directory at `/assets/` (`server.assets-path: /app/assets`,
mounted `./assets:/app/assets:ro`). The widget fetches
`http://localhost:8080/assets/status.json`, which is Glance talking to itself,
so it never touches another service and can't wake a sleeper.

The script computes a level (`ok` / `warn` / `bad`) for every value.
`assets/health.css` (loaded through `theme.custom-css-file`) colours the
`lvl-*` classes, because the stock palette has no amber. `setup-services.sh`
copies the files in `assets/` individually, so `status.json` is never
overwritten by staging.

Thresholds are in the script:

| Value | Amber | Red |
|---|---|---|
| Docker memory | 80% | 92% |
| macOS swap | 75% | 90% |
| Mac disk | 85% | 93% |
| NAS disk | 80% | 90% |
| R2 backup | 26 h | 50 h, or the last run didn't finish |
| DB dumps | 8 d | 15 d |
| T5 / T7 | 35 d | 60 d |
| Coach check-in | 26 h | 50 h |

## Training, Coach team and Sleeping apps widgets (added 2026-09-28)

Three more `custom-api` widgets read the **same** `status.json`:

- **Training:** days to IRONMAN 70.3 Luxembourg (11 Jul 2027), with
  fitness · fatigue · form (CTL · ATL · TSB). Also weight and body fat now, each
  with its change against 7 days earlier, and last night's HRV, resting HR and
  sleep. Then this week's done/planned sessions, TSS and hours, and today's
  planned session. Source: the TrainingPeaks MCP (`127.0.0.1:8092`), read-only
  tools only (`tp_auth_status`, `tp_get_fitness`, `tp_get_weekly_summary`,
  `tp_get_metrics`). The script caches the result for **30 min** in
  `~/.cache/homelab-status/tp.json`, so TrainingPeaks sees at most ~48 calls
  a day. If the TP cookie has expired, the widget says "TP login expired" and
  links nothing else (refresh steps: `services/trainingpeaks-mcp/README.md`).
  Form turns amber below −10 and red below −25.
- **Coach team:** the first 4 lines of the Coach's latest *Daily check-in*
  comment (markdown headers dropped), the Dietitian's `today.md` line, what
  Paperclip is waiting on you for, and links to the two Discord channels and
  Paperclip.
- **Sleeping apps:** all 11 Sablier groups with 🟢 awake / 💤 asleep and a
  link to each (clicking wakes it). Awake apps sort first. State comes from
  `docker ps`, never from requesting the app.

Personal numbers (weight, HRV, check-in text) exist only in the generated
files under `~/services/glance/assets/` and `~/.cache/`, which are outside
the repo. Nothing personal is committed.

**Refresh:** the script runs every 5 min (cron). The widgets re-read the file
every minute, and each footer shows "updated HH:MM · refreshes every 5 min".
TrainingPeaks data can be up to 30 min old on top of that.

**If it looks stale:** the "updated HH:MM" line at the bottom is the
script's last run. Run `~/.dotfiles/scripts/utils/homelab-status.sh --print`
(the output contains no secrets) and check `~/logs/homelab-status.log`. The
Paperclip board password is read from `~/.config/homelab/paperclip-admin.env`
and only ever sent to the local API. "Paperclip unreachable" means the login
failed or the container is down.

**Feed / Media / Finance pages** are unchanged except the **Media** page's
own `bookmarks` widget was removed — those tiles now live once, on Home, in
the Media group. Feed/Media/Finance keep their reddit/release/market feeds.

## Why no `check-url` for Sablier-managed (💤) services

`services/caddy/` fronts ~11 services with scale-to-zero. Hitting one of
those containers directly with a `check-url`:

- **times out** while it's asleep (the container isn't running to answer), or
- **wakes it** on every poll interval, if pointed at the public hostname
  instead — defeating the point of scale-to-zero.

**Evaluated and rejected**, 2026-09-27:

- **Sablier's own API** (`http://sablier:10000`, reachable from Glance if it
  joined the `caddy_default` network) — checked the docs
  (`sablierapp.dev/reference`, `/how-to-guides/readiness/`) and the source.
  There is **no read-only status endpoint**. The only HTTP routes are
  `/api/strategies/{blocking,dynamic}`, which are the routes the *reverse
  proxy* calls to start a session — hitting them from Glance would start the
  group, the exact thing to avoid.
- **`docker-containers` widget filtered by `glance.category` label** — Glance
  supports this via a Docker label on each container, but that means adding
  `labels: glance.category: sleepers` to all ~11 Sablier-managed services'
  `docker-compose.yml` files and recreating each one — out of scope for a
  homepage change, and each recreate is a small availability blip for no
  real gain over what's below.

**What's actually in place instead**: the existing `running-only: true`
`docker-containers` widget already does the right thing for free — a
stopped/asleep container simply doesn't appear in it (no false "down"), and
a container Sablier just started appears the moment it's up, all without
Glance issuing a single request to the app itself. Combined with the 💤
bookmark, that's "state without waking" without touching 11 other services.

## UGREEN NAS check-url

`http://DH4300PLUS-DP.local:9999/` (mDNS `.local`) — kept as documented in
`docs/NAS.md` ("never an IP — its IP drifted three times"), **not** switched
to a raw IP. Verified 2026-09-27: `docker exec glance getent hosts
DH4300PLUS-DP.local` resolves correctly (Docker Desktop on macOS relays
`.local`/mDNS queries from containers to the host resolver), and the monitor
shows `200 OK`. Added `timeout: 5s` (up from Glance's 3s default) as a
cushion against the occasional slow resolve, since the NAS isn't on a DHCP
reservation yet (see `HOME_SERVER_TODO.md`).

## GitHub Repository widget

Shows `peciulevicius/.dotfiles`. The repo is **public**, so the widget needs
**no token** — leave `GITHUB_TOKEN` empty in `~/services/glance/.env`
(unauthenticated API: 60 requests/hour, plenty for a homepage).

History (2026-09-27): the widget showed `404` because the repo had briefly
been made private. A `gh auth token` (the user's full-scope GitHub login
token) was put into Glance's `.env` as a quick fix — **removed the same day**:
a container env var is the wrong place for a token that can push to every
repo. If a private repo ever needs showing, use a fine-grained token scoped
to that one repo with read-only *Metadata* + *Contents*.

## Networks

Glance joins one Docker network per service it needs to reach by container
name for a `check-url` (see `docker-compose.yml`). Added 2026-09-27:
`calibre` (the linuxserver/calibre GUI, `services/calibre/`) and `syncthing`
— both were missing, so those two services could only ever be bookmarks, not
monitored.

## Adding a new service to this page

See the `homelab-service` skill's "Adding a service" step 5 — amended
2026-09-27: a Sablier-managed (scale-to-zero) service gets a 💤-prefixed
bookmark in the right purpose group, **not** a `monitor` entry with
`check-url` (see "Why no check-url" above). Everything else still gets a
`monitor` entry + bookmark + a network join if its `check-url` needs one.
