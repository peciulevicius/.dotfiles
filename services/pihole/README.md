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

## Router DNS Setup

Set your router's DNS servers to:
1. **Primary:** Mac mini local IP (e.g. 192.168.1.100)
2. **Secondary:** 1.1.1.1 (fallback if Mac mini is down)

This routes all DNS queries through Pi-hole for ad blocking + local DNS.

## Local DNS Records

After starting, go to Pi-hole admin → Settings → Local DNS → DNS Records.
Add entries for all `*.peciulevicius.com` subdomains pointing to the Mac mini's local IP.
See `.env.example` for the full list.

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8053 | TCP | Web admin UI |
| 53 | TCP/UDP | DNS server |
