# Self-Hosted Services

Run your own cloud on a Mac mini (or any Docker host). 23 services covering photos, passwords, files, documents, media, and more.

## Service Overview

### Core Services

| Service | URL | Port | Replaces |
|---------|-----|------|----------|
| [Immich](#immich) | photos.peciulevicius.com | 2283 | Google Photos |
| [Vaultwarden](#vaultwarden) | vault.peciulevicius.com | 8001 | Bitwarden Cloud |
| [Nextcloud](#nextcloud) | cloud.peciulevicius.com | 8080 | Google Drive |
| [Uptime Kuma](#uptime-kuma) | status.peciulevicius.com | 3001 | StatusCake |
| [FreshRSS](#freshrss) | rss.peciulevicius.com | 8082 | Feedly |
| [Syncthing](#syncthing) | Tailscale only | 8384 | Dropbox |
| [Portainer](#portainer) | Tailscale only | 9000 | Docker Desktop |
| [Watchtower](#watchtower) | — | — | Manual updates |
| [Homarr](#homarr) | home.peciulevicius.com | 7575 | Start page |
| [Paperless-ngx](#paperless-ngx) | papers.peciulevicius.com | 8000 | Paper filing |
| [Calibre-Web](#calibre-web) | books.peciulevicius.com | 8083 | Kindle Cloud |
| [Rclone](#rclone) | — | — | Cloud backup |

### Utility Services

| Service | URL | Port | Replaces |
|---------|-----|------|----------|
| [Pi-hole](#pi-hole) | pihole.peciulevicius.com | 8053, 53 | Router DNS + ad blocker |
| [Stirling PDF](#stirling-pdf) | pdf.peciulevicius.com | 8084 | Adobe Acrobat |
| [IT-Tools](#it-tools) | tools.peciulevicius.com | 8085 | Online dev tools |
| [Audiobookshelf](#audiobookshelf) | listen.peciulevicius.com | 13378 | Audible |
| [Linkwarden](#linkwarden) | links.peciulevicius.com | 3005 | Pocket / Raindrop |
| [Mealie](#mealie) | recipes.peciulevicius.com | 9925 | Paprika / online recipes |

### Media Stack

| Service | URL | Port | Purpose |
|---------|-----|------|---------|
| [Jellyfin](#jellyfin) | watch.peciulevicius.com | 8096 | Media server (Plex alternative) |
| [Sonarr](#sonarr--radarr--prowlarr) | sonarr.peciulevicius.com | 8989 | TV show management |
| [Radarr](#sonarr--radarr--prowlarr) | radarr.peciulevicius.com | 7878 | Movie management |
| [Prowlarr](#sonarr--radarr--prowlarr) | prowlarr.peciulevicius.com | 9696 | Indexer manager |
| [Transmission](#transmission) | downloads.peciulevicius.com | 9091 | BitTorrent client |

## Prerequisites

- macOS with Docker Desktop or OrbStack installed
- 16GB+ RAM recommended (varies by active services)
- Tailscale installed (for remote access)

## Quick Start

```bash
# Clone or pull dotfiles
cd ~/.dotfiles

# Stage all services to ~/services/
./services/setup-services.sh

# Or stage one at a time
./services/setup-services.sh immich
```

Then for each service:

```bash
cd ~/services/<service>
nano .env          # fill in passwords/settings
docker compose up -d
```

## Service Details

---

### Immich

**What:** Google Photos replacement — auto-backup photos from your phone, face recognition, shared albums, map view. All photos stored on your T7 SSD.

**Why:** Own your photos instead of paying Google/iCloud for storage. No compression, no AI training on your data.

**How to use:**
1. Open http://localhost:2283 and create your account
2. Install the **Immich** app on iOS/Android
3. In the app: set server URL to `http://100.81.171.49:2283` (Tailscale IP)
4. Enable auto-backup — all photos/videos sync to your Mac mini
5. Browse photos via the web UI — search by face, location, or date

```bash
cd ~/services/immich
docker compose up -d
```

---

### Vaultwarden

**What:** Self-hosted Bitwarden password manager. Works with all official Bitwarden apps and browser extensions.

**Why:** Full Bitwarden premium features (TOTP, file attachments, emergency access) for free, data stays on your server.

**How to use:**
1. Open http://localhost:8001 and register (signups disabled after setup)
2. Install **Bitwarden** browser extension + mobile app
3. In the app: tap the gear icon → set server URL to `http://100.81.171.49:8001`
4. Login with your account — passwords sync across all devices
5. Admin panel: `http://localhost:8001/admin` (use ADMIN_TOKEN from .env)

```bash
cd ~/services/vaultwarden
docker compose up -d
```

---

### Nextcloud

**What:** Google Drive + Docs + Calendar + Contacts replacement. File storage, document editing, shared folders.

**Why:** Private cloud storage you control. Good for sharing files, collaborative editing, and keeping contacts/calendars off Google.

**How to use:**
1. Open http://localhost:8080, login with your account
2. **Files:** Upload files via web UI or install the Nextcloud desktop/mobile app for auto-sync
3. **Contacts & Calendar:** Settings → install Contacts and Calendar apps → sync to your phone via CalDAV/CardDAV
4. **Collabora/OnlyOffice:** Install from the Apps section for Google Docs-like editing
5. **Email for password reset:** Settings → Administration → Basic settings → Email server (configure SMTP, e.g. Resend or Gmail SMTP)

**Useful apps to install** (from the Apps menu):
- Notes, Tasks, Contacts, Calendar, Talk (video calls)

```bash
cd ~/services/nextcloud
docker compose up -d
```

---

### Syncthing

**What:** Peer-to-peer file sync between your devices. No cloud, no servers — devices talk directly to each other (or via Tailscale).

**Why:** Sync your Obsidian vault between Mac mini, laptop, and phone without trusting a third party. Also works for any folder you want synced.

**How to use:**
1. Open http://localhost:8384 (Mac mini Syncthing UI)
2. Install Syncthing on your **other device** (laptop: `brew install syncthing`, phone: Möbius Sync for iOS / Syncthing for Android)
3. **Connect devices:**
   - On Mac mini UI: Actions → Show ID → copy the device ID
   - On your laptop/phone: Add Remote Device → paste the Mac mini ID
   - Accept the device on the Mac mini UI when prompted
4. **Share a folder:**
   - On Mac mini UI: Add Folder → set path to your Obsidian vault (e.g. `/var/syncthing/data/obsidian`)
   - Share it with your other device
   - On the other device: accept the shared folder, set local path
5. Files sync automatically whenever both devices are online

**What to sync:**
- Obsidian vault (primary use case)
- Any folder you want on multiple devices

**What NOT to sync with Syncthing:**
- Passwords (Vaultwarden handles that with Bitwarden protocol)
- Photos (Immich handles that)

```bash
cd ~/services/syncthing
docker compose up -d
# Open: http://localhost:8384
```

---

### Uptime Kuma

**What:** Monitoring dashboard that pings your services and alerts you when something goes down. Think "is my stuff running?" at a glance.

**Why:** Know immediately if Immich, Vaultwarden, or any service crashes — instead of finding out when you need it.

**How to use:**
1. Open http://localhost:3001, create admin account
2. Click **Add New Monitor** for each service:
   - **Type:** HTTP(s)
   - **URL:** `http://localhost:2283` (Immich), `http://localhost:8001` (Vaultwarden), etc.
   - **Interval:** 60 seconds
3. Set up **notifications** (optional): Settings → Notifications → add Telegram, Discord, email, etc.
4. You get a status dashboard showing uptime history for all services

**Recommended monitors:**
| Monitor | URL | Type |
|---------|-----|------|
| Immich | http://localhost:2283 | HTTP |
| Vaultwarden | http://localhost:8001 | HTTP |
| Nextcloud | http://localhost:8080 | HTTP |
| Paperless | http://localhost:8000 | HTTP |
| Syncthing | http://localhost:8384 | HTTP |

```bash
cd ~/services/uptime-kuma
docker compose up -d
# Open: http://localhost:3001
```

---

### Portainer

**What:** Docker management UI — see all containers, restart them, view logs, manage volumes and networks. Visual alternative to `docker compose` commands.

**Why:** Instead of SSH-ing in and running `docker ps` / `docker logs`, you get a web dashboard. Great for quick restarts and debugging.

**How to use:**
1. Open http://localhost:9000, create admin account
2. Select **Local** environment
3. **Containers** tab: see all running containers, start/stop/restart, view logs
4. **Stacks** tab: see Docker Compose groups
5. **Volumes** tab: see persistent data

**Portainer vs Uptime Kuma:**
- **Portainer** = manage Docker (restart containers, view logs, deploy new ones)
- **Uptime Kuma** = monitor uptime (is it responding? alert me if not)
- Use both — Portainer to fix things, Uptime Kuma to know when things break

```bash
cd ~/services/portainer
docker compose up -d
# Open: http://localhost:9000
```

---

### Paperless-ngx

**What:** Digital document archive with OCR. Scan or upload receipts, contracts, invoices, letters — it OCRs them and makes them searchable.

**Why:** Go paperless. Instead of a filing cabinet, upload PDFs/photos of documents and find them instantly by searching the text content.

**How to use:**
1. Open http://localhost:8000, login (admin / password from .env)
2. **Upload documents:** drag and drop PDFs, photos of receipts, scanned letters
3. Paperless automatically:
   - OCRs the document (extracts text from images/PDFs)
   - Suggests tags, correspondent, and document type
4. **Organize:** create Tags (e.g. "tax", "medical", "warranty"), Correspondents (e.g. "Bank", "Insurance"), Document Types (e.g. "Invoice", "Contract")
5. **Search:** full-text search across all documents — find that receipt from 2 years ago

**What to upload:**
- Tax documents, receipts, invoices
- Contracts, warranties, insurance papers
- Medical records, prescriptions
- Any paper you'd otherwise file in a drawer

**Mobile:** use the Paperless mobile app or email documents to your Paperless instance.

```bash
cd ~/services/paperless-ngx
docker compose up -d
# Open: http://localhost:8000
```

---

### FreshRSS

**What:** RSS reader — subscribe to blogs, news sites, YouTube channels, Reddit subs. All updates in one place.

**Why:** Follow content without social media algorithms. Get exactly what you subscribe to, nothing more.

**How to use:**
1. Open http://localhost:8082, complete setup wizard
2. Add RSS feeds: Subscription management → Add feed → paste URL
3. Most sites have RSS — look for the RSS icon or try adding `/feed` or `/rss` to the URL
4. Mobile: use any RSS app (NetNewsWire, Reeder) with FreshRSS's API

```bash
cd ~/services/freshrss
docker compose up -d
# Open: http://localhost:8082
```

---

### Watchtower

**What:** Auto-updater for Docker containers. Checks for new images daily and restarts containers with the latest version.

**Why:** Set and forget — your services stay up to date without manual `docker compose pull`.

**How to use:** Nothing to do — it runs in the background. Check logs with:
```bash
docker logs watchtower
```

Only updates containers with the label `com.centurylinklabs.watchtower.enable=true` (all our service configs include this).

```bash
cd ~/services/watchtower
docker compose up -d
```

---

### Homarr

**What:** Dashboard/start page — one page with links to all your services.

**Why:** Instead of remembering ports, bookmark one page with all your service links.

**How to use:**
1. Open http://localhost:7575
2. Add tiles for each service with their URLs and icons
3. Set as your browser homepage on the Mac mini

```bash
cd ~/services/homarr
docker compose up -d
# Open: http://localhost:7575
```

---

### Calibre-Web

**What:** Ebook library server. Upload EPUBs/PDFs, read in browser, or download to Kindle/e-reader via OPDS.

**Why:** Manage your ebook collection. Send books to Kindle, read in browser, organize by author/tag.

**How to use:**
1. Open http://localhost:8083 (admin / admin123 — change immediately)
2. Upload books via the web UI (Admin → Add books)
3. **Kindle:** Settings → enable "Send to Kindle" with your Kindle email
4. **Mobile/e-reader:** connect via OPDS at `http://100.81.171.49:8083/opds`
5. Books stored on T7 SSD at `/Volumes/T7/calibre-books`

```bash
cd ~/services/calibre-web
docker compose up -d
# Open: http://localhost:8083
```

---

### Rclone

**What:** Cloud backup script — syncs your `~/services/` data to Backblaze B2 (or any S3-compatible storage).

**Why:** 3-2-1 backup: your data exists on Mac mini + T7 SSD + cloud. If the Mac mini dies, you can restore everything.

**How to use:**
```bash
# Set up B2 remote (one time)
brew install rclone
rclone config  # add Backblaze B2 remote

# Configure
cd ~/services/rclone
nano .env  # set B2 bucket name, remote name

# Test
~/.dotfiles/services/rclone/rclone-backup.sh --dry-run

# Run
~/.dotfiles/services/rclone/rclone-backup.sh
```

See [HOME_SERVER.md](HOME_SERVER.md) for the full backup strategy.

### Pi-hole

**What:** Network-wide ad blocker and local DNS server. Blocks ads at the DNS level for every device on your network — no browser extensions needed. Also provides local DNS so `*.peciulevicius.com` resolves on your home WiFi without going through Cloudflare.

**Why:** Ads blocked network-wide (phones, smart TVs, everything). Local DNS fixes the "can't access home.peciulevicius.com on WiFi" issue.

**How to use:**
1. Open http://localhost:8053/admin, login with password from .env
2. **Local DNS:** Settings → Local DNS → DNS Records → add all `*.peciulevicius.com` → Mac mini local IP
3. **Router:** Set your router's primary DNS to Mac mini IP, secondary to 1.1.1.1
4. All devices on the network now have ads blocked + local DNS resolution

```bash
cd ~/services/pihole
docker compose up -d
# Open: http://localhost:8053/admin
```

---

### Stirling PDF

**What:** All-in-one PDF tool. Merge, split, compress, convert, rotate, add watermarks, OCR, and more — all locally processed.

**Why:** No uploading PDFs to random websites. Everything runs on your server.

```bash
cd ~/services/stirling-pdf
docker compose up -d
# Open: http://localhost:8084
```

---

### IT-Tools

**What:** Collection of developer utilities — hash generators, UUID generators, base64 encoders, JWT decoders, cron expression builders, and 50+ more tools.

**Why:** One bookmark instead of a dozen random websites.

```bash
cd ~/services/it-tools
docker compose up -d
# Open: http://localhost:8085
```

---

### Audiobookshelf

**What:** Audiobook and podcast server. Upload audiobooks, stream from any device, track listening progress across devices.

**Why:** Own your audiobook library. Import from Audible or add your own files. Mobile app for offline listening.

**How to use:**
1. Open http://localhost:13378, create admin account
2. Upload audiobooks via the web UI or point to a folder
3. Install the Audiobookshelf app on iOS/Android
4. Set server URL and login — books sync with listening progress

```bash
cd ~/services/audiobookshelf
docker compose up -d
# Open: http://localhost:13378
```

---

### Linkwarden

**What:** Bookmark manager that archives web pages. Save links, organize with collections and tags, and never lose a page to link rot — Linkwarden saves a copy of every page.

**Why:** Bookmarks that survive deleted pages. Full-text search across all saved content.

**How to use:**
1. Open http://localhost:3005, create account
2. Install the browser extension for one-click saving
3. Organize with collections and tags

```bash
cd ~/services/linkwarden
docker compose up -d
# Open: http://localhost:3005
```

---

### Mealie

**What:** Recipe manager and meal planner. Import recipes from any URL (auto-extracts ingredients and steps), organize by category, plan weekly meals, generate shopping lists.

**Why:** Save recipes without the blog spam. Share a family recipe book. Plan meals and generate a shopping list.

**How to use:**
1. Open http://localhost:9925, login (changeme@example.com / MyPassword — change immediately)
2. Click "Create" → paste a recipe URL → Mealie extracts it
3. Organize by category (breakfast, dinner, dessert, etc.)
4. Use the meal planner for weekly planning

```bash
cd ~/services/mealie
docker compose up -d
# Open: http://localhost:9925
```

---

### Jellyfin

**What:** Self-hosted media server. Stream your movie and TV collection from any device — web, mobile, smart TV, Roku, Fire TV.

**Why:** Your own Netflix. No subscriptions, no content disappearing, no tracking.

**How to use:**
1. Open http://localhost:8096, run the setup wizard
2. Add media libraries: Movies → `/media/movies`, TV Shows → `/media/tv`
3. Install Jellyfin app on your devices (iOS, Android, smart TV, Fire TV, Roku)
4. Media is managed by Sonarr (TV) and Radarr (movies) — see below

```bash
# Create media directories first
mkdir -p /Volumes/T7/media/{movies,tv,downloads}

cd ~/services/jellyfin
docker compose up -d
# Open: http://localhost:8096
```

---

### Sonarr + Radarr + Prowlarr

**What:** Media automation stack. Prowlarr manages indexers (where to search), Sonarr automates TV show downloads, Radarr automates movie downloads. All three work together.

**How it works:**
1. **Prowlarr** connects to indexers (trackers, usenet providers)
2. **Sonarr/Radarr** search Prowlarr for content, send downloads to Transmission
3. **Transmission** downloads the files to `/media/downloads/`
4. **Sonarr/Radarr** move completed files to `/media/tv/` or `/media/movies/`
5. **Jellyfin** reads from `/media/tv/` and `/media/movies/`

**Setup order:**
1. Start all containers: `cd ~/services/sonarr-radarr && docker compose up -d`
2. Prowlarr (http://localhost:9696) — add indexers
3. Sonarr (http://localhost:8989) — add Prowlarr, add Transmission (`http://transmission:9091`), set root folder `/media/tv`
4. Radarr (http://localhost:7878) — add Prowlarr, add Transmission (`http://transmission:9091`), set root folder `/media/movies`

```bash
cd ~/services/sonarr-radarr
docker compose up -d
```

---

### Transmission

**What:** Lightweight BitTorrent client with web UI. Downloads to the shared media directory where Sonarr and Radarr pick up completed files.

```bash
cd ~/services/transmission
docker compose up -d
# Open: http://localhost:9091
```

---

## Remote Access (Cloudflare Tunnel)

All services are accessible via HTTPS through a Cloudflare Tunnel. This provides real TLS certificates, no port forwarding, and works from anywhere.

### Setup

```bash
~/.dotfiles/scripts/setup/setup-cloudflare-tunnel.sh
```

The script will:
1. Login to Cloudflare (opens browser)
2. Create a tunnel
3. Create DNS records for all subdomains
4. Configure and start the tunnel as a background service

### Service Directory

Every service is accessible three ways: localhost (on the Mac mini), Tailscale (from any device on your tailnet), and public HTTPS (via Cloudflare Tunnel + Access gate).

**Core:**

| Service | Port | Tailscale | Public |
|---------|------|-----------|--------|
| Homarr (dashboard) | 7575 | http://100.81.171.49:7575 | https://home.peciulevicius.com |
| Vaultwarden | 8001 | http://100.81.171.49:8001 | https://vault.peciulevicius.com |
| Immich (photos) | 2283 | http://100.81.171.49:2283 | https://photos.peciulevicius.com |
| Nextcloud | 8080 | http://100.81.171.49:8080 | https://cloud.peciulevicius.com |
| Paperless-ngx | 8000 | http://100.81.171.49:8000 | https://papers.peciulevicius.com |
| FreshRSS | 8082 | http://100.81.171.49:8082 | https://rss.peciulevicius.com |
| Uptime Kuma | 3001 | http://100.81.171.49:3001 | https://status.peciulevicius.com |
| Calibre-Web | 8083 | http://100.81.171.49:8083 | https://books.peciulevicius.com |

**Utilities:**

| Service | Port | Tailscale | Public |
|---------|------|-----------|--------|
| Pi-hole | 8053 | http://100.81.171.49:8053/admin | https://pihole.peciulevicius.com |
| Stirling PDF | 8084 | http://100.81.171.49:8084 | https://pdf.peciulevicius.com |
| IT-Tools | 8085 | http://100.81.171.49:8085 | https://tools.peciulevicius.com |
| Audiobookshelf | 13378 | http://100.81.171.49:13378 | https://listen.peciulevicius.com |
| Linkwarden | 3005 | http://100.81.171.49:3005 | https://links.peciulevicius.com |
| Mealie | 9925 | http://100.81.171.49:9925 | https://recipes.peciulevicius.com |

**Media:**

| Service | Port | Tailscale | Public |
|---------|------|-----------|--------|
| Jellyfin | 8096 | http://100.81.171.49:8096 | https://watch.peciulevicius.com |
| Sonarr | 8989 | http://100.81.171.49:8989 | https://sonarr.peciulevicius.com |
| Radarr | 7878 | http://100.81.171.49:7878 | https://radarr.peciulevicius.com |
| Prowlarr | 9696 | http://100.81.171.49:9696 | https://prowlarr.peciulevicius.com |
| Transmission | 9091 | http://100.81.171.49:9091 | https://downloads.peciulevicius.com |

**Tailscale-only (no public URL):**

| Service | Port | Tailscale |
|---------|------|-----------|
| Syncthing | 8384 | http://100.81.171.49:8384 |
| Portainer | 9000 | http://100.81.171.49:9000 |
**Mobile apps (use Tailscale URLs to bypass Cloudflare Access gate):**

| App | Server URL |
|-----|-----------|
| Bitwarden | http://100.81.171.49:8001 |
| Immich | http://100.81.171.49:2283 |
| Jellyfin | http://100.81.171.49:8096 |
| Audiobookshelf | http://100.81.171.49:13378 |

All localhost URLs follow the pattern `http://localhost:<port>`.

### Security — Cloudflare Access (Zero Trust)

All services behind the Cloudflare Tunnel are protected by a [Cloudflare Access](https://developers.cloudflare.com/cloudflare-one/applications/) policy. This adds an email-based authentication gate in front of every service — users must verify their email before seeing any login page.

**Setup:**
1. Go to [Cloudflare Zero Trust dashboard](https://one.dash.cloudflare.com/) → Access → Applications
2. Create a **Self-hosted application**:
   - Application domain: `*.peciulevicius.com`
   - Session duration: 24 hours (or your preference)
3. Create a **policy**:
   - Policy name: `Email allowlist`
   - Action: Allow
   - Include rule: Emails — add your email address(es)
4. Save — all `*.peciulevicius.com` subdomains now require email verification before loading

**Why Syncthing and Portainer are Tailscale-only:**
- **Syncthing** uses its own device authentication and has a sensitive admin UI — no reason to expose it publicly
- **Portainer** has full Docker control — too dangerous to put on the public internet even behind Cloudflare Access

**What this means for daily use:**
- First visit to any service: Cloudflare asks for your email, sends a code, you verify once
- After that, you're authenticated for 24 hours across all subdomains
- No one else can even see the login pages without passing the email check

## Post-Deploy Setup

Manual steps after deploying all services on a new machine.

### Pi-hole Local DNS

Add DNS records so `*.peciulevicius.com` resolves to the Mac mini on the local network (bypasses Cloudflare when on home WiFi):

1. Open Pi-hole admin: http://localhost:8053/admin
2. Go to Local DNS → DNS Records
3. Add an entry for each subdomain pointing to the Mac mini's local IP:
   - `home`, `vault`, `photos`, `cloud`, `papers`, `rss`, `status`, `books`
   - `pihole`, `pdf`, `tools`, `links`, `recipes`, `listen`
   - `watch`, `sonarr`, `radarr`, `prowlarr`, `downloads`
   - All as `<subdomain>.peciulevicius.com` → Mac mini local IP

### Router DNS

Set the router's DNS to use Pi-hole:
- Primary DNS: Mac mini local IP
- Fallback DNS: `1.1.1.1`

This enables network-wide ad blocking and local DNS resolution for all devices on WiFi.

### Media Stack

1. **Prowlarr** (http://localhost:9696) → add indexers
2. **Sonarr** (http://localhost:8989) → Settings → Download Clients → add Transmission (`localhost:9091`)
3. **Radarr** (http://localhost:7878) → Settings → Download Clients → add Transmission (`localhost:9091`)
4. **Sonarr/Radarr** → Settings → General → copy API key, then in Prowlarr → Settings → Apps → add Sonarr + Radarr
5. **Jellyfin** (http://localhost:8096) → add libraries: Movies (`/media/movies`), TV Shows (`/media/tv`)

## Backup Strategy

See [HOME_SERVER.md](HOME_SERVER.md) for the full 3-2-1 backup strategy.

## Troubleshooting

**Container won't start:**
```bash
docker compose logs -f <service>
```

**Port already in use:**
```bash
lsof -i :<port>
```

**Out of disk space:**
```bash
docker system df
docker system prune
```

**Ports open but services unreachable (Docker Desktop on Mac):**

Docker Desktop allocates `/16` subnets by default, which exhausts the `172.16.0.0/12` range after ~15 networks. New services get `192.168.x.x` subnets that Docker Desktop's port proxy can't forward correctly — TCP connects but HTTP hangs.

Fix (already handled by the dotfiles installer):
```bash
# Ensure ~/.docker/daemon.json has default-address-pools with /24 size
cat ~/.docker/daemon.json
# Should include:
# "default-address-pools": [
#   {"base": "172.16.0.0/12", "size": 24},
#   {"base": "10.99.0.0/16", "size": 24}
# ]

# Then restart Docker Desktop and recreate affected services:
cd ~/services/<service> && docker compose down && docker compose up -d
```
