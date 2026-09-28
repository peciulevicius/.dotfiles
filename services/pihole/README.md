# Pi-hole

Network-wide ad blocker and local DNS server. Blocks ads at the DNS level for all devices on your network.

Also provides local DNS resolution for `*.peciulevicius.com` — so devices on your home WiFi can access services directly without going through Cloudflare.

## Setup

```bash
cd ~/services/pihole
nano .env              # set password, local IP
docker compose up -d
# Open: http://localhost:8053/admin
```

## v6 notes

Upgraded to Pi-hole v6 on 2026-09-25. Config lives in
`data/etc-pihole/pihole.toml`; the compose file sets it through `FTLCONF_*`
env vars (those keys become read-only in the web UI). `/` returns 403 — point
health checks at `/admin/`. The old lighttpd redirect file is gone (no lighttpd
in v6). Glance's DNS widget logs in with the same password — rotate both
together. See `docs/SERVICES.md` → Pi-hole.

## Router DNS Setup

Set your router's DNS servers to:
1. **Primary:** Mac mini local IP (e.g. 192.168.1.100)
2. **Secondary:** 1.1.1.1 (fallback if Mac mini is down)

This routes all DNS queries through Pi-hole for ad blocking + local DNS.

## Local DNS Records

After starting, go to Pi-hole admin → Settings → Local DNS → DNS Records.
Add entries for all `*.peciulevicius.com` subdomains pointing to the Mac mini's local IP.
See `.env.example` for the full list.

## Encrypted upstream — unbound (2026-09-28)

**Why.** Pi-hole used to ask `1.1.1.1` in plain DNS, so the home ISP (Telia)
could read every domain any device looked up — including phones on a Mullvad
exit node, because Tailscale sends their DNS to this Pi-hole, which then
queried the internet in the clear from the home connection.

**What.** The `unbound` service in this same compose stack
(`klutchell/unbound:v1.26.1`, distroless, 64 MB limit, no published ports) is
Pi-hole's only upstream. It caches, validates DNSSEC, logs no queries, and
forwards everything over **DNS-over-TLS (port 853)** to Quad9
(`9.9.9.9`, `149.112.112.112`, `dns.quad9.net`) and Cloudflare (`1.1.1.1`,
`1.0.0.1`, `cloudflare-dns.com`). The ISP now sees only encrypted TLS to those
four IPs. Quad9/Cloudflare still see the queries (that's inherent to any
upstream resolver) but not who you are beyond the home IP.

**How it's wired.**
- Config is inline in `docker-compose.yml` (`configs: unbound-forward-tls`),
  mounted into the image's `custom.conf.d/` — no extra file to stage.
- Pi-hole v6 needs an **IP** upstream, so unbound has a fixed address,
  `10.99.17.53`, which required declaring the `pihole` network's subnet
  (`10.99.17.0/24`, the one Docker had auto-assigned) in the compose — Docker
  only allows `ipv4_address` on user-configured subnets. `UPSTREAM_DNS` in
  `.env` = `10.99.17.53#53`.
- Changing the network block needs the network recreated: Glance is attached
  to `pihole`, so `docker network disconnect pihole glance`, then
  `docker compose down && docker compose up -d`, then
  `docker network connect pihole glance`. Pi-hole is down ~5 s.

**Verified 2026-09-28:** unbound resolves; `sigfail.ippacket.stream` and
`dnssec-failed.org` → SERVFAIL, `sigok…` → NOERROR, `ad` flag set; unbound's
only outbound connections are TCP `:853` (no plain `:53`); Pi-hole's log shows
`forwarded … to 10.99.17.53`; queries via `127.0.0.1` and `100.81.171.49`
resolve and `doubleclick.net` still returns `0.0.0.0`.

**Check any time:**
```bash
docker exec pihole pihole-FTL --config dns.upstreams      # [ 10.99.17.53#53 ]
dig @100.81.171.49 dnssec-failed.org | grep status         # SERVFAIL = DNSSEC on
docker run --rm --network container:unbound busybox netstat -tn   # only :853
```

**Rollback (plain DNS, instant):**
```bash
docker exec pihole pihole-FTL --config dns.upstreams '["1.1.1.1","1.0.0.1"]'
```
That lasts until the next Pi-hole recreate (compose sets it from `.env`); to
make it permanent set `UPSTREAM_DNS=1.1.1.1;1.0.0.1` in `~/services/pihole/.env`
and `docker compose up -d`. If unbound is down, Pi-hole can't resolve anything
— that's the failure mode to recognise (check `docker ps | grep unbound`).

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8053 | TCP | Web admin UI |
| 53 | TCP/UDP | DNS server |
