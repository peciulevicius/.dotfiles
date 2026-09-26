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
| 51413 | BitTorrent peer connections, TCP + UDP (published by `transmission-ts`) |

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

### Switching the exit node on (after buying the Mullvad add-on)

1. 👤 Tailscale admin → Settings → **Mullvad VPN** → buy, then add
   `transmission-ts` (and the phone) to the allowed devices.
2. Pick a node from inside the sidecar:
   ```bash
   docker exec transmission-ts tailscale exit-node list            # all
   docker exec transmission-ts tailscale exit-node list --filter=SE # one country
   docker exec transmission-ts tailscale exit-node suggest          # nearest
   ```
3. In `docker-compose.yml` (repo, then copy to `~/services/transmission/`),
   uncomment and fill:
   ```yaml
   TS_EXTRA_ARGS: --exit-node=<mullvad-node> --exit-node-allow-lan-access=true
   ```
   `--exit-node-allow-lan-access` is required, not optional: the Docker
   network (Sonarr/Radarr/Glance) and published-port traffic arrive from
   local subnets, and without it Tailscale routes the replies into the tunnel,
   so the web UI and RPC go dark. It only affects locally-connected subnets;
   internet traffic still goes to Mullvad.
4. `docker compose up -d --force-recreate`, then the leak test:
   ```bash
   # must differ from `curl -s https://ifconfig.me` on the host
   docker exec transmission curl -s https://ifconfig.me
   docker exec transmission curl -s https://am.i.mullvad.net/connected
   ```
   Also add a magnet from a torrent-IP checker (e.g. ipleak.net's torrent
   test) and confirm the reported IP is Mullvad's.
5. Peer port: Mullvad removed port forwarding in 2023, so with the exit node
   on, inbound peer connections on `51413` stop working (Transmission becomes
   passive-only; downloads still work, slower on poorly-seeded torrents).
   The published port is harmless and kept for now.

### Kill switch — what is and isn't guaranteed

Checked against Tailscale's docs on 2026-09-26; state it precisely:

- **Sidecar stopped or crashed → no leak.** Tested: with `transmission-ts`
  stopped, `transmission` has only `lo` and every outbound connection fails.
  It never falls back to Docker's normal bridge.
- **Exit node set but offline/unreachable → not documented by Tailscale.**
  The exit-node docs don't say whether traffic is dropped or falls back. The
  only documented fail-close behaviour is for an exit node whose *key has
  expired* ("routes remain configured … but become unreachable"). An open
  feature request, tailscale/tailscale#19781 (May 2026), reports traffic
  silently falling back to direct routing when an exit node goes down, on all
  platforms including Linux, and asks for a real kill switch. Other reports
  (#10379) describe the opposite — the internet just stops.
- **So: do not treat Tailscale as a kill switch.** Once the exit node is on,
  test it empirically (block the exit node, e.g. switch to a bogus/offline one,
  and try `docker exec transmission curl https://ifconfig.me`). If it falls
  back, add an explicit iptables rule in the sidecar that only allows egress
  via `tailscale0` plus the local subnets. Tracked in `docs/HOME_SERVER_TODO.md`.

### Rollback

The pre-sidecar compose, Transmission config and image digest are in
`~/backups/transmission-2026-09-26/`. Restore
`docker-compose.yml.pre-sidecar` over `~/services/transmission/docker-compose.yml`
and `docker compose up -d --remove-orphans`; the `transmission` alias then
belongs to the Transmission container again.
