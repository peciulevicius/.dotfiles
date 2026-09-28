# Transmission

Lightweight BitTorrent client with web UI. Downloads to the shared `/media/downloads/` directory where Sonarr and Radarr pick up completed files.

The stack is two containers: **`transmission-ts`** (a Tailscale sidecar that
owns the network) and **`transmission`** (which has no network of its own —
`network_mode: service:transmission-ts`). See [Tailscale sidecar](#tailscale-sidecar).

## Setup

```bash
cd ~/services/transmission
nano .env              # username/password + TS_AUTHKEY (see below)
docker compose up -d
# Open: http://localhost:9091
```

`TS_AUTHKEY`: Tailscale admin → Settings → Keys → *Generate auth key*,
**single-use** and **pre-approved** (no tags needed). It is only consumed on
the very first start; afterwards the node identity lives in
`./data/tailscale/tailscaled.state` and the key is spent. Losing that
directory means generating a new key. Rebuild from scratch on a new machine
the same way — the old `transmission-ts` node in the admin console can be
deleted.

## Port

| Port | Purpose |
|------|---------|
| 9091 | Web UI + RPC (published by `transmission-ts`) |
| ~~51413~~ | Peer port — **no longer published** (2026-09-28): all peer traffic goes through Mullvad, which has no port forwarding, so an inbound port on the home IP is useless |

## Integration

Sonarr, Radarr and LazyLibrarian connect to Transmission at
`http://transmission:9091` on the Docker network `media`. That name is now a
**network alias on `transmission-ts`**, not the Transmission container itself
— which is why nothing downstream had to change. Glance checks the same URL
(`/transmission/web/`, 401 counts as up).

## Tailscale sidecar

### Why

Goal: route torrent traffic through **Mullvad** so the ISP sees only
encrypted traffic to a VPN server, and trackers/peers see a Mullvad IP instead
of the home IP. The Tailscale **Mullvad add-on** (bought in the Tailscale admin
console, up to 5 devices per licence) exposes Mullvad's servers as ordinary
Tailscale exit nodes. Going through Tailscale instead of a standalone
Gluetun + Mullvad-WireGuard container means one account and one bill for both
the phone and this container, and no WireGuard keys to manage in `.env`.

Added 2026-09-26. The add-on is **not bought yet** — everything except the
exit node is built and tested.

### How it works

- `transmission-ts` runs `tailscaled` in **kernel mode** (`TS_USERSPACE=false`,
  `/dev/net/tun` + `NET_ADMIN`; Docker Desktop's Linux VM has the tun module,
  so `SYS_MODULE` isn't needed). It joins the tailnet as its own node,
  `transmission-ts`, with its own `100.x` address.
- `transmission` shares that container's network namespace, so every packet
  Transmission sends goes through the sidecar's routing table. Once an exit
  node is set, Tailscale's policy routing (table 52) sends the default route
  into `tailscale0`.
- `TS_ACCEPT_DNS=false` keeps Docker's embedded DNS (`127.0.0.11`), so
  container names still resolve. (Caveat for the leak test: DNS lookups for
  tracker hostnames then go through Docker's resolver, not Mullvad's DNS — check
  this explicitly.)
- `TS_AUTH_ONCE=true`: the auth key is only used when there is no saved login.
  Verified 2026-09-26 by recreating the stack with `TS_AUTHKEY` blanked — it
  came back as the same node, same IP.
- A health check (`/healthz` on `127.0.0.1:9002`, `TS_ENABLE_HEALTH_CHECK`)
  gates `transmission`'s start on the sidecar having a tailnet IP.
- The web UI is also reachable at the sidecar's own tailnet IP
  (`http://<transmission-ts 100.x>:9091`) — still behind Transmission's login.

### Gotchas

- **If `transmission-ts` restarts on its own, `transmission` is left with a
  dead network namespace** (only `lo`): web UI, RPC and Sonarr/Radarr all fail,
  and Glance shows Transmission down. `docker compose up -d` does *not* fix it.
  Fix: `docker restart transmission` (or
  `docker compose up -d --force-recreate`). Tested 2026-09-26.
- Recreate/restart both together — `docker compose up -d --force-recreate`,
  not `docker compose restart transmission-ts` alone.
- **Node key expiry:** the node was added with an untagged key, so its key
  expires after 180 days (2027-03-25). Disable key expiry for
  `transmission-ts` in the Tailscale admin console (Machines → … → *Disable key
  expiry*), or it drops off the tailnet.

### Exit node — live since 2026-09-28

Mullvad add-on bought; `transmission-ts` uses **`se-sto-wg-201.mullvad.ts.net`**
(Stockholm) with `--exit-node-allow-lan-access`. The choice is stored in the
node's prefs (`./data/tailscale`), so it survives restarts; `TS_EXTRA_ARGS` in
the compose only matters on a fresh login. Change node:
```bash
docker exec transmission-ts tailscale exit-node list --filter=SE
docker exec transmission-ts tailscale set --exit-node=<node> --exit-node-allow-lan-access=true
```
Leak check any time (Transmission runs as PUID 501 — test as that user; root
in the sidecar is tailscaled and deliberately *not* restricted):
```bash
docker exec -u 501 transmission curl -s https://am.i.mullvad.net/ip   # must be a Mullvad IP
curl -s https://am.i.mullvad.net/ip                                   # host = home IP
```

Peer port: Mullvad removed port forwarding in 2023, so Transmission is
passive-only (downloads work, slower on poorly seeded torrents, less seeding).
The published `51413` was removed.

### Kill switch — `killswitch.sh` (tested 2026-09-28)

Tailscale is **not** a kill switch on its own. Measured before the fix: with
the exit node set, `tailscale down` made containerboot exit, Docker restarted
the sidecar, and for the seconds before Tailscale reconnected traffic left on
the **home IP**. (An iptables rule added at runtime didn't help either — the
restart rebuilds the network namespace, and Tailscale resets the filter table.)

`killswitch.sh` is now the sidecar's entrypoint. On every start, *before*
Tailscale runs, it:
- adds `ip rule 5300: uidrange <PUID> → table 200`, where table 200 holds only
  the local Docker subnet and `unreachable default`. It sits *after*
  Tailscale's rules (5210–5270 → table 52), so with the exit node up, table
  52's `default dev tailscale0` wins and Transmission goes through Mullvad;
  in every other state (Tailscale starting, down, or up without an exit node)
  Transmission's traffic is unreachable instead of falling back.
- adds `ip rule 5200: tcp sport 9091 → main` so web-UI/RPC replies go out
  the normal way. Docker Desktop delivers published-port connections with a
  fake outside source (seen as `8.8.8.8`), so without it the reply follows
  the exit-node default into the tunnel and the UI times out. Only source
  port 9091 matches; peer traffic never does.

Test results (2026-09-28, as uid 501):

| Scenario | Result |
|---|---|
| Exit node up | `89.37.63.63` — Mullvad Stockholm ✅ |
| Sidecar (re)starting, first seconds | `Host is unreachable`, then Mullvad ✅ |
| Tailscale up, exit node cleared | `Host is unreachable` ✅ (root still sees home IP — expected) |
| Sidecar stopped | `transmission` has no network at all ✅ |
| Web UI via published port / Mac Tailscale IP | 401 (login) ✅ |
| Sonarr + Radarr download-client test | 200 ✅ |

⚠️ If `transmission-ts` restarts on its own, `transmission` keeps a handle on
the old (dead) network namespace — fail-closed, but it stops working until
`docker compose up -d --force-recreate transmission` in `~/services/transmission`.

Known, accepted: DNS for tracker hostnames uses Docker's resolver (home
connection), because `TS_ACCEPT_DNS=false` keeps container-name resolution.
That reveals *which trackers* are looked up to the resolver, not swarm
participation, which is what IP-based monitoring uses.

### Rollback

The pre-sidecar compose, Transmission config and image digest are in
`~/backups/transmission-2026-09-26/`. Restore
`docker-compose.yml.pre-sidecar` over `~/services/transmission/docker-compose.yml`
and `docker compose up -d --remove-orphans`; the `transmission` alias then
belongs to the Transmission container again.
