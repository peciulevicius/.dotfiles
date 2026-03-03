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

**What it's not great for:** local AI. If you already use Claude, small local models (7B/8B) are a step down in quality and add maintenance overhead. Skip it. If curiosity ever strikes, `brew install ollama` takes two minutes.

---

## Storage

Two SSDs. **Both stay connected permanently** — pulling one breaks services.

| Drive | Size | Role |
|-------|------|------|
| 1TB SSD | Primary | Immich photos + Docker volumes + large files |
| 500GB SSD | Split | 200GB Time Machine (MacBook) + 300GB Immich backup |

---

## Complete Setup

Follow this in order. Takes about an hour. Replace `youruser` with your macOS username throughout.

### 0. Format and partition the drives

**1TB → primary storage**

Disk Utility → select 1TB → Erase:
- Format: **APFS**
- Scheme: **GUID Partition Map**
- Name: `Storage`

**500GB → split in two**

Disk Utility → select 500GB → Partition → add two partitions:
- `TimeMachine` — 200GB
- `ImmichBackup` — 300GB

Create the directories you'll use:

```bash
mkdir -p /Volumes/Storage/immich
mkdir -p /Volumes/Storage/docker
mkdir -p ~/services/immich
mkdir -p ~/services/dev-db
mkdir -p ~/logs
```

---

### 1. Mac mini server settings

These prevent the Mac mini sleeping when idle — essential for a headless server.

**Prevent sleep:**
`System Settings → Energy → Options → Enable "Prevent automatic sleeping when display is off"` → On

Or via terminal:
```bash
sudo pmset -a sleep 0 disksleep 0 displaysleep 10
```

**Auto-restart after power failure:**
```bash
sudo systemsetup -setrestartpowerfailure on
```

**Auto-login (optional, for headless use):**
`System Settings → Users & Groups → Automatic Login` → select your user

---

### 2. Tailscale (remote access)

Tailscale connects all your devices on a private network. No port forwarding, no exposed ports.

**On the Mac mini:**
```bash
brew install --cask tailscale
open /Applications/Tailscale.app
# Sign in with Google or GitHub
```

**On your MacBook:** download from [tailscale.com](https://tailscale.com/download) and sign into the same account.

**On your phone:** install Tailscale from the App Store, same account.

Get the Mac mini's Tailscale IP — you'll use this for everything:
```bash
tailscale ip -4
# e.g. 100.64.0.12 — note this down
```

Verify from your MacBook (on any network):
```bash
ping <mac-mini-tailscale-ip>
```

---

### 3. SSH

Enable on Mac mini:
`System Settings → General → Sharing → Remote Login` → On

From your MacBook, connect:
```bash
ssh youruser@<tailscale-ip>
```

Copy your MacBook's SSH key to the Mac mini so you never need a password:
```bash
ssh-copy-id youruser@<tailscale-ip>
```

Test it — should connect without asking for a password:
```bash
ssh youruser@<tailscale-ip>
```

---

### 4. tmux (persistent sessions)

tmux keeps your terminal sessions alive even when you disconnect. Essential for remote work.

Install (if not already):
```bash
brew install tmux
```

**Basic usage:**

```bash
# Create a new named session
tmux new -s dev

# Detach from session (session keeps running)
Ctrl+B  then  D

# Reattach later
tmux attach -t dev

# List running sessions
tmux ls

# Create multiple windows inside a session
Ctrl+B  then  C   # new window
Ctrl+B  then  N   # next window
Ctrl+B  then  P   # previous window

# Split panes
Ctrl+B  then  %   # vertical split
Ctrl+B  then  "   # horizontal split
Ctrl+B  then arrow key   # move between panes
```

**Typical remote workflow:**
```bash
ssh youruser@<tailscale-ip>     # connect to Mac mini
tmux attach -t dev              # reattach to existing session
# everything you left is still there
```

---

### 5. VS Code Remote SSH (optional)

Edit files on the Mac mini directly from VS Code on your laptop — full IntelliSense, extensions, terminal.

1. Install the **Remote - SSH** extension in VS Code on your MacBook
2. `Cmd+Shift+P` → `Remote-SSH: Connect to Host` → `youruser@<tailscale-ip>`
3. VS Code connects and you edit files that live on the Mac mini

Add it to your SSH config for convenience (`~/.ssh/config` on MacBook):
```
Host macmini
  HostName <tailscale-ip>
  User youruser
```

Then: `Remote-SSH: Connect to Host` → `macmini`

---

### 6. OrbStack (Docker)

Lighter and faster than Docker Desktop on Mac. Same `docker` and `docker compose` CLI.

```bash
brew install --cask orbstack
# Open it and let it start
```

Verify:
```bash
docker --version
docker compose version
```

OrbStack auto-starts on login and restarts containers marked `restart: always` on boot.

---

### 7. Dev databases

Local Postgres and Redis — stop hitting Supabase prod during development.

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

**From your MacBook**, tunnel the ports over SSH:
```bash
ssh -N -L 5432:localhost:5432 -L 6379:localhost:6379 youruser@<tailscale-ip>
```

Now `localhost:5432` and `localhost:6379` on your MacBook route to the Mac mini. Your `.env` files don't need to change.

---

### 8. Immich (photo library)

Self-hosted Google Photos. Mobile app with auto-backup, face recognition, albums.

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

**Mobile app:** install Immich from App Store → server URL: `http://<tailscale-ip>:2283` → enable backup.

**Import existing photos:** export from Apple Photos app → drag into Immich web UI, or use Immich CLI for bulk import.

---

### 9. Backup (nightly rsync)

Nightly copy of your Immich photo library from the 1TB to the `ImmichBackup` partition on the 500GB.

Test manually:
```bash
~/.dotfiles/scripts/backup-immich.sh
```

Schedule it (runs at 3am every night):
```bash
crontab -e
```

Add this line:
```
0 3 * * * ~/.dotfiles/scripts/backup-immich.sh >> ~/logs/immich-backup.log 2>&1
```

---

### 10. Time Machine (MacBook backups)

The `TimeMachine` partition on the 500GB backs up your MacBook automatically.

**On Mac mini:**
1. `System Settings → General → Sharing → File Sharing` → On
2. Click the `+` and add the `TimeMachine` partition
3. Click `Options` → enable **SMB**

**On MacBook:**
1. `System Settings → General → Time Machine`
2. `Add Backup Disk` → select the Mac mini's `TimeMachine` share
3. Backs up automatically on the same network (and over Tailscale when remote)

---

### 11. Final checks

```bash
# Verify everything is running
docker ps
brew services list
tailscale status

# SSH from MacBook without password
ssh youruser@<tailscale-ip>

# Immich accessible
open http://<tailscale-ip>:2283

# Backup works
~/.dotfiles/scripts/backup-immich.sh
```

---

## Optional: Self-hosted GitHub Actions Runner

Free CI for private repos. Runs builds on the Mac mini.

GitHub: repo → Settings → Actions → Runners → New self-hosted runner → follow the instructions (takes ~5 min).

---

## Keeping Everything Running

```bash
# Check status
docker ps
brew services list

# Update Homebrew tools
scripts/update.sh

# Update Docker services
cd ~/services/immich && docker compose pull && docker compose up -d
cd ~/services/dev-db && docker compose pull && docker compose up -d
```

---

## Quick Reference

```bash
# Connect to Mac mini
ssh youruser@<tailscale-ip>

# Reattach persistent session
tmux attach -t dev

# Tunnel dev database to MacBook
ssh -N -L 5432:localhost:5432 -L 6379:localhost:6379 youruser@<tailscale-ip>

# Immich web UI
open http://<tailscale-ip>:2283

# Run backup manually
~/.dotfiles/scripts/backup-immich.sh

# Check what's running
docker ps && brew services list && tailscale status
```
