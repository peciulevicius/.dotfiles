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

## Storage Layout

Two external SSDs, used like this:

| Drive | Size | Role |
|-------|------|------|
| 1TB SSD | Primary | Immich photos + Docker volumes + large files |
| 500GB SSD | Split | 200GB Time Machine (MacBook) + 300GB Immich backup |

Both stay permanently connected.

### Partition the 500GB

Open Disk Utility → select 500GB → Partition → add two partitions:

| Partition name | Size |
|---------------|------|
| `TimeMachine` | 200GB |
| `ImmichBackup` | 300GB |

### Format the 1TB

Open Disk Utility → select 1TB → Erase:
- Format: **APFS**
- Scheme: **GUID Partition Map**
- Name: `Storage`

### Directory layout on 1TB

```
/Volumes/Storage/
├── immich/       ← photo library
└── docker/       ← Docker volume data (databases, etc.)
```

---

## Backup Strategy

**The 1TB is primary storage, not a backup.** If it fails without a copy, photos are gone.

Nightly rsync copies photos from the 1TB to the 500GB `ImmichBackup` partition automatically.

Set it up:

```bash
# Test it manually first
~/.dotfiles/scripts/backup-immich.sh

# Schedule nightly at 3am
crontab -e
# add this line:
# 0 3 * * * ~/.dotfiles/scripts/backup-immich.sh >> ~/logs/immich-backup.log 2>&1
```

**After setup:**

| Data | Primary | Backup |
|------|---------|--------|
| Photos (Immich) | 1TB SSD | 500GB partition (nightly rsync) |
| MacBook files | MacBook internal | 500GB partition (Time Machine) |
| Docker volumes | 1TB SSD | Not backed up — dev data, easy to recreate |

**Risk accepted:** both drives are in the same room. Fire or theft loses both. That's the self-hosting tradeoff. Acceptable for most people.

---

## Step 1: Tailscale (do this first)

Tailscale gives you secure remote access from anywhere — no port forwarding needed.

```bash
brew install --cask tailscale
open /Applications/Tailscale.app
# Sign in — creates your tailnet
```

Install on your MacBook and phone too. All devices see each other on a private network.

Find your Mac mini's Tailscale IP:

```bash
tailscale ip -4
# Something like 100.x.x.x
```

Use this IP for everything remote.

---

## Step 2: Enable SSH

`System Settings → General → Sharing → Remote Login` → On

From your laptop:

```bash
ssh youruser@<tailscale-ip>
```

Add your SSH key so you don't need a password every time:

```bash
ssh-copy-id youruser@<tailscale-ip>
```

Use tmux for persistent sessions that survive disconnects:

```bash
tmux new -s dev
# detach: Ctrl+B D
# reattach: tmux attach -t dev
```

VS Code Remote SSH also works — connect and edit files directly on the Mac mini.

---

## Step 3: OrbStack (Docker)

Lighter and faster than Docker Desktop on Mac. Same `docker` CLI.

```bash
brew install --cask orbstack
```

Verify:

```bash
docker --version
docker compose version
```

---

## Step 4: Local Dev Databases

Run Postgres and Redis locally instead of hitting cloud databases during development. Faster, free, no network latency, safe to wipe.

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

Connect from your laptop (over Tailscale or SSH tunnel):

```bash
# SSH tunnel for Postgres
ssh -N -L 5432:localhost:5432 youruser@<tailscale-ip>

# Then connect locally
psql -h localhost -U dev -d dev
```

---

## Step 5: Immich (Photo Library)

Self-hosted Google Photos. Mobile app, face recognition, albums, auto-backup.

```bash
mkdir -p /Volumes/Storage/immich
mkdir -p ~/services/immich
cd ~/services/immich
```

Create `docker-compose.yml`:

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

Create `.env`:

```env
DB_PASSWORD=changeme
DB_USERNAME=postgres
DB_DATABASE_NAME=immich
REDIS_HOSTNAME=redis
```

Start:

```bash
docker compose up -d
```

Open `http://<tailscale-ip>:2283` → create admin account.

**Mobile:** install Immich from App Store → point at `http://<tailscale-ip>:2283` → enable auto-backup.

**Import existing photos:** export from Apple Photos → drag into Immich web UI, or use the Immich CLI for bulk import.

---

## Step 6: Time Machine from MacBook

Share the `TimeMachine` partition over the network.

On Mac mini:
1. `System Settings → General → Sharing → File Sharing` → On
2. Add the `TimeMachine` partition as a shared folder
3. Options → enable SMB

On MacBook:
1. `System Settings → General → Time Machine → Add Disk`
2. Select the shared `TimeMachine` drive

Backs up automatically when on the same network (or over Tailscale).

---

## Optional: Self-hosted GitHub Actions Runner

Free CI for your private repos. Runs jobs on the Mac mini instead of GitHub's servers.

```bash
# On GitHub: repo → Settings → Actions → Runners → New self-hosted runner
# Follow the setup instructions GitHub gives you (takes ~5 minutes)
```

Good for: long-running builds, jobs that need local network access, avoiding GitHub Actions minutes limits.

---

## Keeping Everything Running

OrbStack auto-starts containers with `restart: always/unless-stopped` on boot.

```bash
# Check status
docker ps
brew services list

# Update everything
scripts/update.sh
cd ~/services/immich && docker compose pull && docker compose up -d
cd ~/services/dev-db && docker compose pull && docker compose up -d
```

---

## Full Setup Order

1. Format 1TB as APFS in Disk Utility (name: `Storage`)
2. Partition 500GB: 200GB `TimeMachine` + 300GB `ImmichBackup`
3. Tailscale — install + sign in on Mac mini, MacBook, phone
4. Enable SSH — System Settings → Sharing → Remote Login
5. OrbStack
6. Dev databases — `~/services/dev-db/docker-compose.yml`
7. Immich — `~/services/immich/docker-compose.yml`
8. Backup cron — `crontab -e`, schedule `backup-immich.sh` nightly
9. Time Machine — share `TimeMachine` partition, point MacBook at it

---

## Quick Reference

```bash
# SSH into Mac mini from anywhere
ssh youruser@<tailscale-ip>

# Persistent terminal session
tmux attach -t dev   # or: tmux new -s dev

# Tunnel dev database to laptop
ssh -N -L 5432:localhost:5432 youruser@<tailscale-ip>

# Immich
open http://<tailscale-ip>:2283

# Check services
docker ps
brew services list

# Update services
cd ~/services/immich && docker compose pull && docker compose up -d
```
