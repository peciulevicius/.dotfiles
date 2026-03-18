# Self-Hosted Services

Run your own cloud on a Mac mini (or any Docker host). 13 services covering photos, passwords, files, documents, and more.

## Service Overview

| Service | URL | Port | Replaces |
|---------|-----|------|----------|
| [Immich](#immich) | photos.peciulevicius.com | 2283 | Google Photos |
| [Vaultwarden](#vaultwarden) | vault.peciulevicius.com | 8001 | Bitwarden Cloud |
| [Nextcloud](#nextcloud) | cloud.peciulevicius.com | 8080 | Google Drive |
| [Uptime Kuma](#uptime-kuma) | status.peciulevicius.com | 3001 | StatusCake |
| [FreshRSS](#freshrss) | rss.peciulevicius.com | 8082 | Feedly |
| [Ollama + Open WebUI](#ollama) | ai.peciulevicius.com | 3030 | OpenAI API |
| [Syncthing](#syncthing) | sync.peciulevicius.com | 8384 | Dropbox |
| [Portainer](#portainer) | portainer.peciulevicius.com | 9000 | Docker Desktop |
| [Watchtower](#watchtower) | — | — | Manual updates |
| [Homarr](#homarr) | home.peciulevicius.com | 7575 | Start page |
| [Paperless-ngx](#paperless-ngx) | papers.peciulevicius.com | 8000 | Paper filing |
| [Calibre-Web](#calibre-web) | books.peciulevicius.com | 8083 | Kindle Cloud |
| [Rclone](#rclone) | — | — | Cloud backup |

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
| Ollama | http://localhost:11434 | HTTP |
| Open WebUI | http://localhost:3030 | HTTP |
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

### Ollama + Open WebUI

**What:** Run AI models locally. Open WebUI gives you a ChatGPT-like interface. Models stored on T7 SSD.

**Why:** Private AI chat — no data sent to OpenAI/Anthropic. Good for experimenting with open-source models.

**How to use:**
1. Open http://localhost:3030, create admin account
2. Chat like ChatGPT — select model from dropdown (llama3.2:3b is pre-installed)
3. **Pull more models:** `docker exec ollama ollama pull mistral` or use the UI
4. See [NOTES.md](NOTES.md) for Obsidian integration

```bash
cd ~/services/ollama
docker compose up -d
docker exec ollama ollama pull llama3.2:3b
# Open WebUI: http://localhost:3030
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

See [BACKUPS.md](BACKUPS.md) for the full backup strategy.

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

### Service URLs

| Service | URL |
|---------|-----|
| Dashboard (Homarr) | https://home.peciulevicius.com |
| Vaultwarden | https://vault.peciulevicius.com |
| Immich (photos) | https://photos.peciulevicius.com |
| Nextcloud | https://cloud.peciulevicius.com |
| Open WebUI (AI) | https://ai.peciulevicius.com |
| Paperless-ngx | https://papers.peciulevicius.com |
| FreshRSS | https://rss.peciulevicius.com |
| Uptime Kuma | https://status.peciulevicius.com |
| Syncthing | https://sync.peciulevicius.com |
| Calibre-Web | https://books.peciulevicius.com |
| Portainer | https://portainer.peciulevicius.com |

### Local Access

Services also remain accessible locally via `http://localhost:<port>` and via Tailscale at `http://100.x.x.x:<port>`.

### Security Note

These are public URLs — anyone with the subdomain can reach the login page. Each service requires authentication. For extra protection, consider adding [Cloudflare Access](https://developers.cloudflare.com/cloudflare-one/applications/) (zero-trust) in front of sensitive services.

## Backup Strategy

See [BACKUPS.md](BACKUPS.md) for the full 3-2-1 backup strategy.

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
