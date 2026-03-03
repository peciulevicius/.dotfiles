# Mac mini Home Server Setup

Mac mini M4 (16GB / 256GB) as an always-on home server: dev machine, photo hub, remote access.

---

## What It's Good For

| Use case | Why |
|----------|-----|
| Always-on dev environment | Run long jobs, leave terminals open, never close your laptop |
| Remote access from anywhere | SSH + Tailscale — laptop, phone, wherever |
| Immich photo library | Self-hosted Google Photos replacement |
| Local dev databases | Postgres + Redis in Docker — stop hitting Supabase prod during dev |
| Self-hosted GitHub Actions | Free CI/CD for private repos |
| Time Machine target | Automatic MacBook backups when you're home |

---

## Concepts to Understand First

Before you start, read this. It'll save you a lot of confusion.

### Sleep vs Locked

These are completely different:

| State | Machine | SSH | Services |
|-------|---------|-----|---------|
| **Sleeping** | Processor off | ❌ Can't connect | ❌ Nothing runs |
| **Locked** | Fully running, screen off | ✅ Works | ✅ Everything runs |

**When you lock your Mac mini or walk away, it's still running.** SSH works, Docker containers keep serving, backups run at 3am. The only thing that stops everything is sleep.

**Should you prevent sleep?** Only if you want any of these:
- SSH in from outside your house (phone, hotel, office)
- Background tasks to run while you're not home (nightly backup, Immich syncing phone photos)
- Services to stay available 24/7

If you only use the Mac mini when you're sitting in front of it, sleep is fine. But as a home server the whole point is it keeps running when you're not there.

### Why Docker?

Docker runs services (like Postgres, Immich) in isolated containers instead of installing them directly on macOS.

**Without Docker:** install Postgres directly → it writes files all over the system → updating it is risky → removing it is messy → it can conflict with other things.

**With Docker:** Postgres runs in a self-contained box → start it with one command → stop it with one command → wipe and reinstall in seconds → completely isolated from your system.

It's not magic — it's just a clean way to run server software on a Mac without making a mess of it.

### How the backup actually works

The nightly rsync is a **copy**, not a live mirror. Here's what that means:

- Every night at 3am: photos from 1TB are copied to 500GB
- If the 1TB fails: you have yesterday's photos on 500GB — but Immich is down
- Recovery: manually point Immich at the 500GB backup, restart it, photos are back
- **Not automatic** — you have to do the recovery steps yourself

This is not RAID (which would mirror in real time). It's a daily snapshot backup. Your photos are safe, but you'd spend 20 minutes recovering, not 0 minutes.

---

## Before You Touch the Drives

**You said you have photos on both drives. Do this before formatting anything.**

### 1. See what's on each drive

```bash
ls /Volumes/
# Shows all mounted drives
```

```bash
# See how much space is used on each
df -h /Volumes/<drive-name>
```

### 2. Copy everything to the 1TB

The 1TB is your primary drive. Get all photos onto it first.

```bash
# Replace drive names with what you actually see in /Volumes/
rsync -av --progress /Volumes/<500gb-drive-name>/ /Volumes/<1tb-drive-name>/
```

This copies everything from the 500GB to the 1TB. Wait for it to finish.

### 3. Verify the copy

```bash
# Count files on source
find /Volumes/<500gb-drive-name> -type f | wc -l

# Count files on destination
find /Volumes/<1tb-drive-name> -type f | wc -l
```

Numbers should match (or destination should be higher if 1TB already had files).

Open Finder, browse both drives, spot-check that folders and files look right.

### 4. Only then format the 500GB

Once you're confident everything is on the 1TB, format and partition the 500GB (instructions below).

---

## Storage Layout

| Drive | Size | Role |
|-------|------|------|
| 1TB SSD | Primary | Immich photos + Docker volumes + large files |
| 500GB SSD | Split | 200GB Time Machine (MacBook) + 300GB Immich backup |

**Both stay connected permanently.** If a drive disconnects, services that depend on it stop working — Immich goes offline, backups fail. Treat them like internal drives.

---

## Complete Setup

Follow this in order. Replace `youruser` with your macOS username throughout.

---

### Step 0 — Format and partition drives

**Only do this after you've verified all photos are safe on the 1TB (see "Before You Touch the Drives" above).**

**1TB → primary storage**

Disk Utility → select 1TB → Erase:
- Format: **APFS**
- Scheme: **GUID Partition Map**
- Name: `Storage`

**500GB → split in two**

Disk Utility → select 500GB → Partition → click `+` twice to add two partitions:
- Name: `TimeMachine`, Size: 200GB
- Name: `ImmichBackup`, Size: 300GB

Create the directory structure on the 1TB:

```bash
mkdir -p /Volumes/Storage/immich
mkdir -p /Volumes/Storage/docker
mkdir -p ~/services/immich
mkdir -p ~/services/dev-db
mkdir -p ~/logs
```

---

### Step 1 — Mac mini server settings

**Prevent sleep** (so SSH works and background tasks run when you're not home):

```bash
sudo pmset -a sleep 0 disksleep 0 displaysleep 10
```

This means:
- `sleep 0` — machine never sleeps
- `disksleep 0` — drives never spin down
- `displaysleep 10` — screen turns off after 10 minutes (saves power, doesn't affect anything)

**Auto-restart after power outage** (so it comes back on its own if power cuts out):

```bash
sudo systemsetup -setrestartpowerfailure on
```

**Optional — auto-login on startup** (so services start immediately after a reboot without someone typing a password at the keyboard):

`System Settings → Users & Groups → Automatic Login` → select your user

---

### Step 2 — Tailscale

Tailscale creates a private network between all your devices. Your Mac mini, MacBook, and phone all get a private IP that works from anywhere — no port forwarding, no exposed ports, encrypted.

**On Mac mini:**
```bash
brew install --cask tailscale
open /Applications/Tailscale.app
# Sign in with Google or GitHub
```

**On MacBook:** download from [tailscale.com](https://tailscale.com/download), sign in with the same account.

**On phone:** install from App Store, same account.

Get your Mac mini's Tailscale IP:
```bash
tailscale ip -4
# e.g. 100.64.0.12
```

Write this down. You'll use it for everything. Verify from MacBook (from any network, including mobile):
```bash
ping <tailscale-ip>
```

---

### Step 3 — SSH

SSH lets you open a terminal on the Mac mini from anywhere.

Enable on Mac mini:
`System Settings → General → Sharing → Remote Login` → On

Connect from MacBook:
```bash
ssh youruser@<tailscale-ip>
# It'll ask for your password the first time
```

Copy your SSH key so you never need a password again:
```bash
ssh-copy-id youruser@<tailscale-ip>
```

Add a shortcut to `~/.ssh/config` on your MacBook:
```
Host macmini
  HostName <tailscale-ip>
  User youruser
```

Now you just type:
```bash
ssh macmini
```

---

### Step 4 — tmux (persistent sessions)

When you SSH into the Mac mini and close your laptop, the SSH connection drops and anything running in that terminal stops. tmux keeps sessions alive — you reconnect and everything is exactly where you left it.

Install on Mac mini:
```bash
brew install tmux
```

**The workflow:**
```bash
ssh macmini               # connect
tmux new -s work          # start a named session called "work"
# ... do stuff ...
# close laptop / lose connection
ssh macmini               # reconnect later
tmux attach -t work       # everything is still there
```

**Essential shortcuts** (all start with `Ctrl+B`, then a key):

| Shortcut | What it does |
|----------|-------------|
| `Ctrl+B D` | Detach from session (leave it running) |
| `Ctrl+B C` | New window |
| `Ctrl+B N` | Next window |
| `Ctrl+B P` | Previous window |
| `Ctrl+B %` | Split pane vertically |
| `Ctrl+B "` | Split pane horizontally |
| `Ctrl+B →` | Move to pane on the right |
| `Ctrl+B [` | Scroll mode (use arrow keys, `Q` to exit) |

List all sessions:
```bash
tmux ls
```

---

### Step 5 — VS Code Remote SSH

Edit files on the Mac mini from VS Code on your MacBook — full autocomplete, extensions, integrated terminal, everything.

1. In VS Code on MacBook: install the **Remote - SSH** extension
2. `Cmd+Shift+P` → type `Remote-SSH: Connect to Host` → select `macmini` (from your SSH config)
3. VS Code opens a window connected to the Mac mini — files, terminal, everything runs there

You can run `pnpm dev` in the terminal and the server runs on the Mac mini, accessible from `localhost` on your MacBook via port forwarding that VS Code does automatically.

---

### Step 6 — OrbStack (Docker)

OrbStack is a lighter, faster replacement for Docker Desktop on Mac. The `docker` and `docker compose` commands work identically.

```bash
brew install --cask orbstack
# Open OrbStack and let it start
```

Verify:
```bash
docker --version
docker compose version
```

OrbStack starts automatically on login and restarts containers marked `restart: always` after a reboot.

---

### Step 7 — Dev databases

Run Postgres and Redis on the Mac mini instead of hitting Supabase or cloud databases during development. Faster, free, isolated, safe to wipe.

Create `~/services/dev-db/docker-compose.yml`:

```yaml
services:
  postgres:
    image: postgres:16
    container_name: dev-postgres
    environment:
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev
      POSTGRES_DB: dev
    ports:
      - 5432:5432
    volumes:
      - /Volumes/Storage/docker/postgres:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    container_name: dev-redis
    ports:
      - 6379:6379
    volumes:
      - /Volumes/Storage/docker/redis:/data
    restart: unless-stopped
```

Start:
```bash
cd ~/services/dev-db
docker compose up -d
```

**Use from MacBook** — tunnel both ports over SSH in one command:
```bash
ssh -N -L 5432:localhost:5432 -L 6379:localhost:6379 macmini
```

Leave this running in a terminal tab. Your MacBook's `localhost:5432` now routes to Postgres on the Mac mini. No `.env` changes needed.

---

### Step 8 — Immich (photo library)

Immich is a self-hosted Google Photos replacement. It runs in Docker on the Mac mini and stores photos on the 1TB SSD.

Create `~/services/immich/docker-compose.yml`:

```yaml
name: immich

services:
  immich-server:
    container_name: immich_server
    image: ghcr.io/immich-app/immich-server:release
    volumes:
      - /Volumes/Storage/immich/upload:/usr/src/app/upload
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
      - /Volumes/Storage/immich/model-cache:/cache
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
      - /Volumes/Storage/immich/postgres:/var/lib/postgresql/data
    restart: always
```

Create `~/services/immich/.env`:
```env
DB_PASSWORD=changeme
DB_USERNAME=postgres
DB_DATABASE_NAME=immich
REDIS_HOSTNAME=redis
```

Start:
```bash
cd ~/services/immich
docker compose up -d
```

Open `http://<tailscale-ip>:2283` → create your admin account.

**Phone setup:** install Immich from App Store → server URL: `http://<tailscale-ip>:2283` → sign in → enable automatic backup. Your phone photos now back up to your Mac mini automatically.

**Import existing photos from 1TB:** in Immich web UI → top right menu → Upload → drag your photo folders in. Or use the Immich CLI for large imports:
```bash
# Install Immich CLI
npm install -g @immich/cli

# Upload a folder
immich upload --recursive /Volumes/Storage/your-photos-folder
```

---

### Step 9 — Backup (nightly rsync)

Copies your Immich photo library from 1TB to 500GB every night at 3am.

Test it manually first:
```bash
~/.dotfiles/scripts/backup-immich.sh
```

Schedule it:
```bash
crontab -e
```

Add this line:
```
0 3 * * * ~/.dotfiles/scripts/backup-immich.sh >> ~/logs/immich-backup.log 2>&1
```

Check it ran in the morning:
```bash
cat ~/logs/immich-backup.log
```

---

### Step 10 — Time Machine (MacBook backups)

**On Mac mini:**
1. `System Settings → General → Sharing → File Sharing` → On
2. Click `+` → add the `TimeMachine` partition
3. Click `Options` → check **Share as Time Machine backup destination**

**On MacBook:**
1. `System Settings → General → Time Machine`
2. `Add Backup Disk` → select the Mac mini's `TimeMachine` share
3. Backs up automatically when on the same network or over Tailscale

---

### Step 11 — Verify everything works

```bash
# All Docker containers running
docker ps

# Tailscale connected
tailscale status

# SSH works without password
ssh macmini echo "connected"

# Immich accessible
open http://<tailscale-ip>:2283

# Backup runs without errors
~/.dotfiles/scripts/backup-immich.sh
```

---

## If a Drive Fails

### 1TB fails (photo library)

Immich goes offline. Photos are on the 500GB `ImmichBackup` partition from last night.

Recovery:
```bash
# Update Immich to point at backup partition
# Edit ~/services/immich/docker-compose.yml
# Change this line in immich-server volumes:
#   /Volumes/Storage/immich/upload:/usr/src/app/upload
# To:
#   /Volumes/ImmichBackup/immich/upload:/usr/src/app/upload

# Also update the postgres volume path similarly, then:
cd ~/services/immich
docker compose down
docker compose up -d
```

Buy a replacement drive, copy data back, repoint Immich to the new 1TB.

### 500GB fails

- MacBook Time Machine stops (buy new drive, re-point Time Machine)
- Nightly backup stops (backup-immich.sh will error and log it)
- Photos on 1TB are unaffected

---

## Keeping Everything Running

Services start automatically on boot (OrbStack handles Docker, brew services handles native tools).

```bash
# Check everything
docker ps
brew services list
tailscale status

# Update
scripts/update.sh                                              # Homebrew tools
cd ~/services/immich && docker compose pull && docker compose up -d   # Immich
cd ~/services/dev-db && docker compose pull && docker compose up -d   # databases
```

---

## Optional: Self-hosted GitHub Actions Runner

Free CI for private repos. GitHub: repo → Settings → Actions → Runners → New self-hosted runner → follow instructions (~5 min).

---

## Quick Reference

```bash
# Connect
ssh macmini

# Reattach terminal session
tmux attach -t work

# Tunnel dev databases to MacBook
ssh -N -L 5432:localhost:5432 -L 6379:localhost:6379 macmini

# Immich web UI
open http://<tailscale-ip>:2283

# Run backup now
~/.dotfiles/scripts/backup-immich.sh

# Check everything
docker ps && tailscale status
```
