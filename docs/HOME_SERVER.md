# Mac mini Setup Guide

Your Mac mini M4 is a second desk computer, not a complicated server. With a KVM switch you use the same keyboard, mouse, and monitor for both your MacBook and Mac mini — just press a button to switch.

This guide covers everything: what it's for, how to set it up, how photos work, how backups work, and what to do when things break.

---

## What It's Actually For

The Mac mini is most useful as:

| Role | What that means |
|------|----------------|
| **Photo hub** | Your phone backs up photos to it wirelessly and automatically — your own Google Photos, no subscription |
| **MacBook backup target** | Your MacBook backs up to it automatically via Time Machine |
| **Second workstation** | Always-on machine you can leave long jobs running on |
| **Remote access** | SSH in from anywhere if you need to check something |

That's it. You don't need to run databases, AI models, or anything else on it unless a specific need comes up.

---

## Things You Need to Understand First

### Does the Mac mini need Time Machine?

No. Time Machine is for your MacBook — it backs up **to** the Mac mini. The Mac mini's own data (photos) is protected separately by a nightly copy to the second SSD.

Think of it this way:
- **MacBook** → Time Machine → **Mac mini's 500GB SSD** (MacBook is backed up)
- **Mac mini photos on 1TB** → rsync every night → **Mac mini's 500GB SSD** (photos are backed up)

The Mac mini itself doesn't need backing up. If it dies, you reinstall macOS and set it up again — the photos and MacBook backup are on the SSDs, untouched.

### Sleep vs Locked — what's the difference?

These look the same from the outside (screen is off) but are completely different:

| State | What's happening | SSH works? | Immich syncs? | Backup runs? |
|-------|-----------------|-----------|--------------|-------------|
| **Sleeping** | Machine is off | ❌ No | ❌ No | ❌ No |
| **Screen locked** | Fully running, screen just off | ✅ Yes | ✅ Yes | ✅ Yes |

When you walk away and the screen goes black, the Mac mini is still fully running — that's screen lock, not sleep. Everything keeps working. Sleep is a separate state that shuts down the processor to save power.

**Should you prevent sleep?** Only if you want:
- Phone photos to sync automatically while you're asleep
- Nightly 3am backup to actually run
- SSH to work when you're not home

If you're only using the Mac mini when you're sitting at your desk, sleep is fine. But as a photo backup hub, preventing sleep makes more sense.

### What is Docker and why use it?

Docker runs services like Immich in isolated containers instead of installing them directly on macOS.

Without Docker, installing a complex app like Immich would mean: installing Postgres, Redis, Python dependencies — all directly on your Mac, writing files everywhere, conflicting with other things, being a mess to update or remove.

With Docker, each service runs in its own self-contained box. One command to start it. One command to stop it. One command to wipe it and start fresh. Completely isolated from the rest of your system.

You don't need to understand Docker deeply to use it. You just run `docker compose up -d` and it works.

### How do phone photos work with Immich?

No cables involved. It works like this:

1. Install Immich on your phone
2. Enter your Mac mini's address
3. Enable automatic backup in the app

After that, whenever your phone is connected to home WiFi, Immich silently uploads any new photos in the background. You don't do anything. You open the Immich web interface on any device and your photos are all there — searchable, organised by date, with face recognition and map view.

When you're away from home, Immich syncs over Tailscale (your private network) when you open the app.

---

## Your Storage Setup

You have two external SSDs. Both stay permanently connected to the Mac mini.

| Drive | Size | What goes on it |
|-------|------|-----------------|
| T7 (1TB) | Primary | Immich photos + Time Machine (both MacBook and Mac mini) |
| T5 (500GB) | Backup | Nightly copy of Immich photos from the T7 |

**Why this split?**

The backup drive (T5) must hold a copy of your photos. Using the smaller drive (T5) as the backup and the larger drive (T7) as primary means:
- T7 handles active data — photos grow here over time
- T5 can back up up to 500GB of photos. When your library exceeds that, you'll need a larger backup drive.

Time Machine for both machines lives on T7 because it's the larger drive and can accommodate both system backups alongside the Immich library (APFS volumes share space dynamically — no fixed partitions needed).

**The one risk you accept:** both drives are in the same room. Fire or theft would lose both. For a personal photo library that's a reasonable tradeoff. If you ever want a cloud copy, Backblaze can be added later.

---

## Before You Touch the Drives

You said you have photos on both drives. **Do not format anything yet.**

Get all photos onto the 1TB first, verify they're there, then format the 500GB.

### Step 1 — See what's on each drive

```bash
ls /Volumes/
```

This shows all connected drives by name.

### Step 2 — Check how much space each drive is using

```bash
df -h /Volumes/<drive-name>
# Run for each drive
```

### Step 3 — Copy everything from the 500GB to the 1TB

```bash
rsync -av --progress /Volumes/<500gb-drive-name>/ /Volumes/<1tb-drive-name>/
```

This copies every file. The `--progress` flag shows you what's happening. Wait until it finishes completely.

### Step 4 — Verify the copy

```bash
# Count files on 500GB
find /Volumes/<500gb-drive-name> -type f | wc -l

# Count files on 1TB
find /Volumes/<1tb-drive-name> -type f | wc -l
```

The 1TB count should be equal to or higher than the 500GB count. Also open Finder and browse both drives to spot-check that folders look right.

### Step 5 — Only now format the 500GB

Once you're confident everything is safely on the 1TB, you can format the 500GB.

---

## Setup — Step by Step

Run these in order. The whole thing takes about an hour.

Replace `youruser` with your macOS username throughout (check it with `whoami`).

---

### Step 1 — Prepare the drives

**T7 (1TB) — add a TimeMachine volume without touching existing files**

T7 already has your photos. With APFS you can add a new volume to the same drive without erasing anything — volumes share the pool of space dynamically.

Open **Disk Utility** (Spotlight → Disk Utility):
- Select **T7** in the left sidebar (the container, not the volume)
- Click **+** (Add Volume) in the toolbar — do NOT click Erase
- Name: `TimeMachine`, Format: `APFS`
- Leave size limits blank (APFS shares space dynamically)
- Click **Add**

Your existing files on T7 are untouched. You now have two APFS volumes on T7: the original (with your photos) and the new `TimeMachine`.

Create the Immich folder on T7 (use the existing volume name):
```bash
ls /Volumes/   # check what T7's existing volume is named
mkdir -p /Volumes/<T7-volume-name>/immich
mkdir -p ~/services/immich
mkdir -p ~/logs
```

**T5 (500GB) — format as ImmichBackup**

T5 is empty, so format it cleanly:
- Select **T5** in the left sidebar
- Click **Erase**
- Name: `ImmichBackup`, Format: `APFS`
- Click **Erase**

---

### Step 2 — Prevent sleep (recommended)

If you want Immich to sync phone photos overnight and backups to run at 3am, the Mac mini needs to stay awake.

```bash
sudo pmset -a sleep 0 disksleep 0 displaysleep 10
```

What each part does:
- `sleep 0` — machine never goes to sleep
- `disksleep 0` — drives never spin down
- `displaysleep 10` — screen turns off after 10 minutes (saves power, nothing else is affected)

The Mac mini still uses very little power in this mode. It's not the same as your MacBook with the screen on — it's sitting there doing nothing with the screen off, using maybe 6-10W.

To revert to normal sleep behaviour later:
```bash
sudo pmset -a sleep 1
```

**Auto-restart after a power cut** (so it comes back on by itself):
```bash
sudo systemsetup -setrestartpowerfailure on
```

---

### Step 3 — Tailscale

Tailscale creates a private encrypted network between all your devices — Mac mini, MacBook, and phone — that works anywhere in the world. No router configuration, no exposed ports.

Without Tailscale, your phone can only reach Immich when you're home on the same WiFi. With Tailscale, it works from anywhere.

**On the Mac mini:**
```bash
brew install --cask tailscale
open /Applications/Tailscale.app
```

Sign in with Google or GitHub. This creates your private network (called a tailnet).

**On your MacBook:** go to [tailscale.com/download](https://tailscale.com/download), install, sign in with the same account.

**On your phone:** install Tailscale from the App Store, sign in with the same account.

All three devices are now on the same private network. Get the Mac mini's private IP — you'll use this everywhere:

```bash
tailscale ip -4
# e.g. 100.64.0.12 — write this down
```

Verify it works from your MacBook (can be on any network, including mobile hotspot):
```bash
ping <tailscale-ip>
# Should get responses
```

---

### Step 4 — SSH

SSH lets you open a terminal on the Mac mini from anywhere. Useful when something needs fixing or you want to check on services.

**Enable on Mac mini:**
`System Settings → General → Sharing → Remote Login` → turn On

**Add a shortcut on your MacBook** so you can type `ssh macmini` instead of the full IP. Edit `~/.ssh/config` on your MacBook:

```
Host macmini
  HostName <tailscale-ip>
  User youruser
```

**Copy your SSH key** so you never need a password:
```bash
ssh-copy-id macmini
```

**Test it:**
```bash
ssh macmini
# Should connect without asking for a password
exit
```

---

### Step 5 — Docker

Immich runs inside Docker containers. Docker is already installed by the dotfiles installer.

Open **Docker Desktop** (it installs as a cask via Homebrew) and let it start. Verify:
```bash
docker --version
docker compose version
```

Docker starts automatically when you log in and restarts containers after a reboot.

**Important — network pool config:** The dotfiles installer copies `config/docker/daemon.json` to `~/.docker/daemon.json`. This sets Docker to allocate `/24` subnets instead of the default `/16`. Without this, Docker exhausts the `172.16.0.0/12` range after ~15 networks, and new containers get `192.168.x.x` subnets that Docker Desktop can't proxy correctly (ports appear open but HTTP traffic doesn't flow). If you hit this issue on an existing install, restart Docker Desktop after the config is in place, then recreate affected services with `docker compose down && docker compose up -d`.

---

### Step 6 — Immich

Immich is your self-hosted Google Photos. It runs in Docker on the Mac mini and stores photos on the 1TB SSD.

**Create the service files:**

```bash
mkdir -p ~/services/immich
cd ~/services/immich
```

Create `~/services/immich/docker-compose.yml`:

```yaml
name: immich

services:
  immich-server:
    container_name: immich_server
    image: ghcr.io/immich-app/immich-server:release
    volumes:
      - /Volumes/<T7-volume-name>/immich/upload:/usr/src/app/upload
      - /etc/localtime:/etc/localtime:ro
    env_file:
      - .env
    ports:
      - 2283:2283
    depends_on:
      - redis
      - database
    restart: always

  immich-machine-learning:
    container_name: immich_machine_learning
    image: ghcr.io/immich-app/immich-machine-learning:release
    volumes:
      - /Volumes/<T7-volume-name>/immich/model-cache:/cache
    env_file:
      - .env
    restart: always

  redis:
    container_name: immich_redis
    image: docker.io/redis:6.2-alpine
    restart: always

  database:
    container_name: immich_postgres
    image: docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0
    env_file:
      - .env
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_USER: ${DB_USERNAME}
      POSTGRES_DB: ${DB_DATABASE_NAME}
    volumes:
      - /Volumes/<T7-volume-name>/immich/postgres:/var/lib/postgresql/data
    restart: always
```

Create `~/services/immich/.env`:

```env
DB_PASSWORD=changeme
DB_USERNAME=postgres
DB_DATABASE_NAME=immich
REDIS_HOSTNAME=redis
```

**Start Immich:**
```bash
cd ~/services/immich
docker compose up -d
```

Wait about 30 seconds for everything to start. Check it's running:
```bash
docker ps
# Should show 4 containers: immich_server, immich_machine_learning, immich_redis, immich_postgres
```

**Open the web interface:**

Go to `http://<tailscale-ip>:2283` in your browser and create your admin account.

---

### Step 7 — Set up phone backup

This is the main value of Immich. Once set up, you never think about photo backup again.

1. Install **Immich** from the App Store on your iPhone
2. Open it → tap **Login**
3. Server URL: `http://<tailscale-ip>:2283`
4. Sign in with the account you created
5. Tap your profile picture → **App Settings** → **Background Backup** → enable it

**What happens after this:**
- Phone on home WiFi → Immich silently uploads new photos in the background
- Phone anywhere else → syncs over Tailscale when you open the app
- No cables, no manual export, no iCloud needed
- Open `http://<tailscale-ip>:2283` on any device and all photos are there

**Import your existing photo library:**

Your existing photos are already on the 1TB SSD (from the migration earlier). Import them into Immich:

Option A — drag and drop in the web UI:
Go to `http://<tailscale-ip>:2283` → click the upload icon → drag your photo folders in

Option B — CLI for large imports (faster for thousands of photos):
```bash
npm install -g @immich/cli
immich login http://<tailscale-ip>:2283 <your-email>
immich upload --recursive /Volumes/Storage/
```

---

### Step 8 — Nightly photo backup

This copies your Immich photos from the 1TB to the 500GB every night at 3am. If the 1TB ever fails, you have last night's photos on the 500GB.

Test the backup script manually first:
```bash
~/.dotfiles/scripts/backup/backup-immich.sh
```

If it runs without errors, schedule it:
```bash
crontab -e
```

Add this line (this is standard cron syntax — `0 3 * * *` means "at 3:00am every day"):
```
0 3 * * * ~/.dotfiles/scripts/backup/backup-immich.sh >> ~/logs/immich-backup.log 2>&1
```

Save and close. Check it ran the next morning:
```bash
cat ~/logs/immich-backup.log
```

---

### Step 9 — Time Machine (MacBook + Mac mini)

The `TimeMachine` APFS volume on T7 backs up both machines. One volume, two sources — macOS handles it.

**Mac mini Time Machine (backs up the Mac mini itself):**
1. `System Settings → General → Time Machine`
2. Click **Add Backup Disk**
3. Select the `TimeMachine` volume on T7
4. Done — Mac mini backs up its own system data to T7

**MacBook Time Machine (backs up over the network):**

On the Mac mini first:
1. `System Settings → General → Sharing → File Sharing` → turn On
2. Click `+` under Shared Folders → navigate to the `TimeMachine` volume on T7 → add it
3. Click **Options** → check **Share as Time Machine backup destination**

On your MacBook:
1. `System Settings → General → Time Machine`
2. Click **Add Backup Disk**
3. Select the Mac mini's `TimeMachine` share
4. Done — MacBook backs up automatically whenever it's on the same network (home WiFi or Tailscale)

---

### Step 10 — Verify everything

```bash
# Docker containers running
docker ps
# Should show 4 Immich containers

# Tailscale connected
tailscale status
# Should show all your devices

# SSH works
ssh macmini echo "connected"

# Immich web UI
open http://<tailscale-ip>:2283

# Backup script works
~/.dotfiles/scripts/backup/backup-immich.sh
```

---

### Step 11 — Deploy remaining services

With Immich running, deploy everything else. See [SERVICES.md](SERVICES.md) for what each service does (24 services total).

```bash
cd ~/.dotfiles

# Stage all services to ~/services/
./services/setup-services.sh

# Deploy core services:
for svc in watchtower portainer ollama uptime-kuma syncthing vaultwarden nextcloud freshrss homarr paperless-ngx calibre-web; do
  cd ~/services/$svc
  nano .env          # fill in passwords/settings (generate secrets with: openssl rand -base64 32)
  docker compose up -d
  cd -
done

# Deploy utility services:
for svc in pihole stirling-pdf it-tools audiobookshelf linkwarden mealie; do
  cd ~/services/$svc
  nano .env
  docker compose up -d
  cd -
done

# Deploy media stack:
mkdir -p /Volumes/T7/media/{movies,tv,downloads}
for svc in transmission sonarr-radarr jellyfin; do
  cd ~/services/$svc
  nano .env
  docker compose up -d
  cd -
done
```

For Ollama specifically — models on T7, Open WebUI on port 3030:
```bash
mkdir -p /Volumes/T7/ollama-models
cd ~/services/ollama
# Set OLLAMA_MODELS_PATH=/Volumes/T7/ollama-models in .env
# Set WEBUI_SECRET_KEY=$(openssl rand -hex 32) in .env
docker compose up -d
docker exec ollama ollama pull llama3.2:3b
```

For Calibre-Web — books on T7:
```bash
mkdir -p /Volumes/T7/calibre-books
cd ~/services/calibre-web
# Set BOOKS_DIR=/Volumes/T7/calibre-books in .env
docker compose up -d
```

Deploy everything, stop containers later if not needed:
```bash
docker stop <container_name>  # stop a service
docker start <container_name> # start it again
```

### Step 11b — Pi-hole DNS setup

Pi-hole provides ad blocking + local DNS. Local DNS means `*.peciulevicius.com` resolves directly to the Mac mini when you're on home WiFi (instead of going through Cloudflare).

```bash
cd ~/services/pihole
nano .env          # set PIHOLE_PASSWORD, LOCAL_IP
docker compose up -d
```

**Add local DNS records** (Pi-hole admin → Settings → Local DNS → DNS Records):

Add an entry for each subdomain pointing to the Mac mini's local IP:
```
home.peciulevicius.com       → 192.168.1.100
vault.peciulevicius.com      → 192.168.1.100
photos.peciulevicius.com     → 192.168.1.100
cloud.peciulevicius.com      → 192.168.1.100
... (all subdomains — see .env.example for full list)
```

**Router configuration:**
1. Log into your router admin panel
2. Set DNS servers to:
   - Primary: Mac mini local IP (e.g. 192.168.1.100)
   - Secondary: 1.1.1.1 (fallback if Mac mini is down)
3. All devices on the network now use Pi-hole for DNS

---

### Step 12 — Cloudflare Tunnel (HTTPS for all services)

This gives every service a real HTTPS URL like `https://vault.peciulevicius.com`. Required for the Bitwarden app (which rejects HTTP).

```bash
~/.dotfiles/scripts/setup/setup-cloudflare-tunnel.sh
```

The script will:
1. Open your browser to authenticate with Cloudflare
2. Create a tunnel named "macmini"
3. Create DNS records for all service subdomains
4. Start the tunnel as a background service (auto-starts on boot)

After it finishes, all services are live at:

| Service | URL |
|---------|-----|
| Dashboard | https://home.peciulevicius.com |
| Vaultwarden | https://vault.peciulevicius.com |
| Immich | https://photos.peciulevicius.com |
| Nextcloud | https://cloud.peciulevicius.com |
| Open WebUI | https://ai.peciulevicius.com |
| Paperless | https://papers.peciulevicius.com |
| FreshRSS | https://rss.peciulevicius.com |
| Uptime Kuma | https://status.peciulevicius.com |
| Syncthing | https://sync.peciulevicius.com |
| Calibre-Web | https://books.peciulevicius.com |
| Portainer | https://portainer.peciulevicius.com |

**Bitwarden app:** set server URL to `https://vault.peciulevicius.com` — works on all devices with no certificate warnings.

---

## If Something Breaks

### Immich not loading

```bash
cd ~/services/immich
docker compose ps          # check container status
docker compose logs -f     # see what's wrong
docker compose restart     # restart everything
```

### T7 fails — photo recovery

Immich goes offline. Photos are on the T5 `ImmichBackup` volume from last night.

```bash
# Edit the docker-compose.yml to point at the backup
nano ~/services/immich/docker-compose.yml
```

Find these lines and update them to point at ImmichBackup:
```
/Volumes/<T7-volume-name>/immich/upload:/usr/src/app/upload
/Volumes/<T7-volume-name>/immich/postgres:/var/lib/postgresql/data
/Volumes/<T7-volume-name>/immich/model-cache:/cache
```

Change each to `/Volumes/ImmichBackup/immich/...`, then:
```bash
cd ~/services/immich
docker compose down
docker compose up -d
```

Immich is back with yesterday's photos. Buy a replacement drive, copy data back, repoint Immich.

Note: Time Machine also lives on T7, so MacBook and Mac mini backups stop too. Replace T7 first priority.

### T5 fails

Photos on T7 are completely unaffected. Immich keeps running. Nightly backup stops. Buy a replacement, format it as `ImmichBackup`, re-add the cron job.

### Immich app on phone can't connect

- Check Tailscale is running on phone and Mac mini
- Try opening `http://<tailscale-ip>:2283` in mobile Safari — if that works, the issue is the app config
- On Mac mini: `docker ps` to confirm containers are running

---

## Day-to-Day Maintenance

### Update Immich (do this occasionally)

```bash
cd ~/services/immich
docker compose pull
docker compose up -d
```

Immich updates frequently and improvements are worth having.

### Update everything else

```bash
scripts/update.sh
```

### Check what's running

```bash
docker ps
```

---

## New Machine Setup — TL;DR

Complete checklist for setting up a new Mac mini from scratch:

```bash
# 1. Clone dotfiles and run installer
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh

# 2. Prepare drives (see steps 1-2 above for details)
# - T7: add TimeMachine APFS volume, create /Volumes/T7/immich
# - T5: format as ImmichBackup
# - Prevent sleep: sudo pmset -a sleep 0 disksleep 0 displaysleep 10

# 3. Set up networking
# - Install Tailscale, sign in
# - Enable SSH: System Settings → General → Sharing → Remote Login

# 4. Deploy all services
./services/setup-services.sh                            # stage configs to ~/services/
mkdir -p /Volumes/T7/media/{movies,tv,downloads}
for svc in immich watchtower portainer ollama uptime-kuma syncthing \
           vaultwarden nextcloud freshrss homarr paperless-ngx calibre-web \
           pihole stirling-pdf it-tools audiobookshelf linkwarden mealie \
           transmission sonarr-radarr jellyfin; do
  cd ~/services/$svc
  nano .env          # fill in secrets (openssl rand -base64 32)
  docker compose up -d
  cd -
done

# 5. Set up Cloudflare Tunnel (HTTPS for all services)
~/.dotfiles/scripts/setup/setup-cloudflare-tunnel.sh

# 6. Set up backups
crontab -e
# Add:
# 0 3 * * * ~/.dotfiles/scripts/backup/backup-immich.sh >> ~/logs/immich-backup.log 2>&1
# 0 4 * * 0 ~/.dotfiles/scripts/backup/backup-databases.sh >> ~/logs/db-backup.log 2>&1

# 7. Set up Time Machine (see step 9 above)

# 8. Verify
docker ps                    # all containers running
tailscale status             # devices connected
curl https://vault.peciulevicius.com  # tunnel working
```

## Quick Reference

```bash
# SSH into Mac mini from anywhere
ssh macmini

# Check all containers
docker ps

# Restart a service
cd ~/services/<service> && docker compose restart

# Update a service
cd ~/services/<service> && docker compose pull && docker compose up -d

# Run photo backup manually
~/.dotfiles/scripts/backup/backup-immich.sh

# Dump databases
~/.dotfiles/scripts/backup/backup-databases.sh

# Check Tailscale status
tailscale status

# Service URLs (24 total — see SERVICES.md for full list)
# https://home.peciulevicius.com      (dashboard)
# https://photos.peciulevicius.com    (Immich)
# https://vault.peciulevicius.com     (Vaultwarden)
# https://cloud.peciulevicius.com     (Nextcloud)
# https://ai.peciulevicius.com        (Open WebUI)
# https://watch.peciulevicius.com     (Jellyfin)
# https://recipes.peciulevicius.com   (Mealie)
# https://pihole.peciulevicius.com    (Pi-hole)
# ... and more — see SERVICES.md
```
