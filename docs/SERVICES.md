# Services

Docker Compose stacks for the Mac mini homelab. Each service lives in
`services/<name>/` with a `docker-compose.yml`, an `.env.example` and, where
useful, a README; `services/setup-services.sh` stages them into
`~/services/<name>/`.

Storage and backups: [HOME_SERVER_REFERENCE.md](HOME_SERVER_REFERENCE.md).
Rebuilding the host: [HOME_SERVER.md](HOME_SERVER.md).

## Access model

Every service is reachable on the Mac mini at `http://localhost:<port>` and
over Tailscale at `http://100.81.171.49:<port>`. Some are also published
through the Cloudflare Tunnel as `https://<name>.peciulevicius.com`.

- **Public hostname** where a phone or browser outside the tailnet needs it,
  or where HTTPS is required (mobile Obsidian, OPDS).
- **Tailscale only** for anything that controls other services, holds
  sensitive history, or has no need to be public.
- **Cloudflare Access** protects only the dashboard (`home.`). A wildcard
  policy was removed because native apps (Bitwarden, Immich, KOReader, the
  Obsidian plugin) cannot complete Access's interactive login; each service
  uses its own authentication.
- **Uploads over 100MB** fail through the tunnel (Cloudflare free plan); use
  the Tailscale address.

## Inventory

### Personal data

| Service | Purpose | Port | Public hostname |
|---|---|---|---|
| Immich | Photos and video (Google Photos replacement) | 2283 | `photos.` |
| Vaultwarden | Password manager (Bitwarden-compatible) | 8001 | `vault.` |
| Nextcloud | Files, calendar, contacts | 8080 | `cloud.` |
| Paperless-ngx | Scanned documents with OCR | 8000 | `papers.` |
| Linkwarden | Bookmarks with page archiving | 3005 | `links.` |
| CouchDB | Obsidian sync (Self-hosted LiveSync) | 5984 | `couchdb.` |
| Syncthing | Peer-to-peer folder sync | 8384 | — |
| Odysseus | AI workspace (history, memory, RAG) | 7001 | — |

### Reading and media

| Service | Purpose | Port | Public hostname |
|---|---|---|---|
| Calibre-Web | Ebook library and OPDS feed | 8083 | `books.` |
| Calibre | Library manager; content server for imports | 8888 | — |
| Audiobookshelf | Audiobooks and podcasts | 13378 | `listen.` |
| Storyteller | Read-along EPUB alignment (on demand) | 8087 | — |
| Jellyfin | Movies and TV | 8096 | `watch.` |
| Jellyseerr | Media requests | 5055 | — |
| Sonarr / Radarr | TV and movie automation | 8989 / 7878 | — |
| Prowlarr | Indexer manager | 9696 | — |
| FlareSolverr | Challenge solver for Prowlarr | 8191 | — |
| Bazarr | Subtitles | 6767 | — |
| Transmission | Download client | 9091 | — |
| LazyLibrarian | Ebook and audiobook automation | 5299 | — |
| FreshRSS | RSS reader | 8082 | `rss.` |

### Tools and operations

| Service | Purpose | Port | Public hostname |
|---|---|---|---|
| Glance | Dashboard (behind Cloudflare Access) | 7575 | `home.` |
| Uptime Kuma | Uptime monitoring and alerts | 3001 | `status.` |
| Pi-hole | DNS filtering | 8053 (UI), 53 | `pihole.` |
| Portainer | Docker management UI | 9000 | See note below |
| Stirling PDF | PDF tools | 8084 | `pdf.` |
| IT-Tools | Developer utilities | 8085 | `tools.` |
| Watchtower | Nightly image updates | — | — |
| rclone | Nightly backup to Cloudflare R2 (script, not a container) | — | — |

> **Note:** Portainer is listed in the tunnel setup script
> (`portainer.peciulevicius.com`), although it grants full control of Docker.
> Confirm whether the live tunnel exposes it; if so, consider removing the
> route and using it over Tailscale only.

---

## Setup

```bash
~/.dotfiles/services/setup-services.sh             # stage every service
~/.dotfiles/services/setup-services.sh immich      # or one
cd ~/services/<service>
nano .env                                          # fill in secrets and paths
docker compose up -d
```

`setup-services.sh` copies files rather than linking them, and never
overwrites an existing `.env`. After changing a file under `services/`,
re-stage it; the weekly audit reports drift.

Adding, removing or changing a service: follow the `homelab-service` project
skill (`.claude/skills/homelab-service/`), which covers staging, the Glance
homepage, the tunnel, backups, credentials and documentation.

### Public hostnames

```bash
~/.dotfiles/scripts/setup/setup-cloudflare-tunnel.sh
```

Logs in to Cloudflare, creates the tunnel, writes `~/.cloudflared/config.yml`
and creates DNS records for each hostname. After editing `config.yml`, reload
the tunnel with `launchctl kickstart -k "gui/$(id -u)/com.cloudflare.cloudflared"`
(`brew services restart` restarts an inactive duplicate agent; see
[HOME_SERVER_REFERENCE.md](HOME_SERVER_REFERENCE.md#two-cloudflared-launchagents)).

---

## Service notes

### Immich

Photos and videos from the phone, with face recognition, albums and map view.
Originals are on the NAS (`/Volumes/immich`); the database and thumbnails are on
the internal SSD. The mobile app uses the Tailscale URL. Details:
`services/immich/README.md`.

### Vaultwarden

Works with the official Bitwarden apps and browser extensions; self-hosting
includes premium features such as TOTP and attachments. Sign-ups are disabled
after setup. The admin panel is at `/admin`, protected by the hashed
`ADMIN_TOKEN` in `.env`.

### Nextcloud

Files, plus Calendar and Contacts (CalDAV/CardDAV) once those apps are enabled.
Collabora or OnlyOffice add document editing. Its Mail app is an IMAP client,
not a mail server.

### Paperless-ngx

Upload or email PDFs and photos of documents; Paperless runs OCR and suggests
tags, correspondents and document types. Organisation uses tags,
correspondents, document types and saved views rather than folders.

### Linkwarden

Saves links and archives the page content. Browser extension for one-click
saving; in Brave, Shields must be disabled for the Linkwarden site or saving
fails silently.

### CouchDB

Sync backend for Obsidian's Self-hosted LiveSync plugin. Public because mobile
Obsidian requires HTTPS; not behind Cloudflare Access because the plugin cannot
log in through it. Anonymous requests return 401. Details:
`services/couchdb/README.md` and [guides/NOTES.md](guides/NOTES.md).

### Syncthing

Peer-to-peer sync, used for the Obsidian vault between the Macs. On iOS the
only client is Möbius Sync. Passwords and photos are not synced this way.

### Odysseus

AI workspace. Tailscale-only: it holds conversation history and memories, and
its agent can execute code. Built from source; see
`services/odysseus/README.md` and [guides/SELF_HOSTED_AI.md](guides/SELF_HOSTED_AI.md).

### Calibre-Web, Calibre and LazyLibrarian

Calibre-Web serves the library and the OPDS feed
(`https://books.peciulevicius.com/opds`, HTTP Basic auth) used by KOReader.
The Calibre container runs the content server LazyLibrarian imports through.
Change the Calibre-Web default admin password on first login. Details,
including the SMB caveats: [guides/BOOKS.md](guides/BOOKS.md).

### Audiobookshelf

Audiobook and podcast streaming with progress sync; official iOS and Android
apps.

### Storyteller

Started only when aligning a book (`restart: "no"`, ~4GB memory). Details:
`services/storyteller/README.md`.

### Jellyfin and the media stack

| Step | Service |
|---|---|
| Indexers | Prowlarr (with FlareSolverr) |
| Requests | Jellyseerr (signs in with Jellyfin) |
| TV / movies | Sonarr / Radarr → Transmission (`http://transmission:9091`) |
| Subtitles | Bazarr, connected to Sonarr and Radarr |
| Library | Jellyfin: Movies `/media/movies`, TV `/media/tv` |

Downloads go to `/Volumes/media/downloads`; Sonarr and Radarr move finished
files into the library. Jellyfin does not notice new files on SMB reliably;
`scripts/utils/smb-watcher-rescan.sh` restarts it every 30 minutes until
Radarr/Sonarr are configured to notify Jellyfin directly.

Radarr and Sonarr have a release profile that rejects executables disguised as
media (see [HOME_SERVER_REFERENCE.md](HOME_SERVER_REFERENCE.md#malicious-releases-disguised-as-media)).

### FreshRSS

RSS reader. For mobile clients (Reeder, NetNewsWire), enable the Google Reader
API and set an API password in FreshRSS.

### Glance

Dashboard with service status, bookmarks and host stats, configured in
`services/glance/glance.yml`. Every service should appear there: a monitor
with a `check-url` (which requires joining the service's Docker network in
`services/glance/docker-compose.yml`) and a bookmark. Services stopped by design
(Storyteller) get a bookmark only.

### Uptime Kuma

HTTP monitors for each service, with Discord notifications. It runs on the
same machine it monitors; the external heartbeat (Healthchecks.io) covers the
case where the whole host is down.

### Pi-hole

DNS filtering for devices configured to use it. It blocks trackers, telemetry
and most web ads, but not ads served from the same domains as the content
(YouTube, Spotify, Twitch) or devices using DNS-over-HTTPS. Those need a
client-side blocker.

The router does not yet point at Pi-hole, so only manually configured devices
are filtered (about 3.6% of queries blocked as of 2026-09-08). Pointing the
router's DNS at the Mac mini (with `1.1.1.1` as fallback) is safe on its own.

> **Warning:** Do not add local DNS records pointing `*.peciulevicius.com` at
> the Mac mini without a local reverse proxy. Nothing on the Mac mini listens on
> 443; TLS and hostname-to-port routing happen inside the Cloudflare tunnel, so
> those records would break every service on the LAN. See the Pi-hole section of
> [HOME_SERVER_TODO.md](HOME_SERVER_TODO.md).

Pi-hole is pinned to an old release (2024.07.0); moving to v6 changes its
configuration format and should be done deliberately.

### Watchtower

Checks images nightly at 04:00 and recreates containers whose image changed.
With `WATCHTOWER_LABEL_ENABLE=false` (the default here) it watches **every
running container**, so floating tags (`latest`, `30-apache`, `16-alpine`) are
updated automatically. Pinned version tags never change and are reviewed
quarterly with `scripts/utils/check-image-updates.py`. Stopped containers are
ignored.

### rclone

Nightly backup to Cloudflare R2 (`services/rclone/rclone-backup.sh`, staged
copy in `~/services/rclone/`, run by cron). Setup and exclusions:
`services/rclone/README.md`.

---

## Mobile apps

Use the Tailscale URL for services without a public hostname.

| Service | App | Notes |
|---|---|---|
| Immich | Official app | Automatic photo backup |
| Vaultwarden | Bitwarden (official) | Set the self-hosted server URL at login |
| Jellyfin | Official app; Finamp or Amperfy for music | |
| Audiobookshelf | Official app | |
| Nextcloud | Official app for files | Calendar and contacts via the phone's own CalDAV/CardDAV |
| Paperless-ngx | Swift Paperless, Paperless Mobile, PaperNext | Third-party, maintained |
| Linkwarden | Official app | Share-sheet saving, offline cache |
| FreshRSS | Reeder, NetNewsWire, ReadKit, Fluent Reader, Unread | Google Reader API |
| Transmission | Transmissionic, NASCTL | Remote-control clients |
| Syncthing | Möbius Sync (iOS) | Free tier limited to 20MB; one-time purchase removes the limit |
| Uptime Kuma | KumaAlert, Uptime Kuma Manager | Push alerts and widgets |
| Pi-hole | Pi-hole Remote | |
| Calibre-Web | KOReader over OPDS | On the Kindle |

---

## Troubleshooting

| Problem | Check |
|---|---|
| Container will not start | `docker compose logs -f <service>` |
| Port already in use | `lsof -i :<port>` |
| Service cannot see its files | NAS mount; see [NAS.md](NAS.md#troubleshooting-a-service-cannot-see-its-files) |
| Disk space | `docker system df`, then `docker builder prune -af` |

> **Warning:** Do not run `docker system prune` or `docker image prune -a` on
> the Mac mini. They delete stopped containers and their images, including
> services stopped by design (Storyteller).

**Ports open but services unreachable (Docker Desktop).** Docker Desktop
allocates `/16` networks by default and runs out of the `172.16.0.0/12` range
after about 15 networks; later networks land in `192.168.x.x`, where the port
proxy accepts TCP but HTTP hangs. `~/.docker/daemon.json` (set by the installer)
must contain:

```json
"default-address-pools": [
  {"base": "172.16.0.0/12", "size": 24},
  {"base": "10.99.0.0/16", "size": 24}
]
```

Restart Docker Desktop, then recreate the affected services
(`docker compose down && docker compose up -d`).
