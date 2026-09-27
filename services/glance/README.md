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

Side column: `server-stats`, `dns-stats` (Pi-hole), `repository` (this repo),
`calendar`, `weather`, `clock` — moved here (2026-09-27) so the full-width
column is 100% services.

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
