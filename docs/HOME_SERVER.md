# Mac mini Home Server Setup

Mac mini M4 (16GB / 256GB) as a home server: always-on dev machine, photo hub, local AI.

---

## Storage Layout

You have two external SSDs. Use them like this:

| Drive | Size | Role |
|-------|------|------|
| 1TB SSD | Primary | Ollama models + Immich photos + Docker volumes |
| 500GB SSD | Secondary | Time Machine backups from MacBook |

Both stay connected permanently.

### Format the 1TB (if not already APFS)

Open Disk Utility → select the 1TB drive → Erase:
- Format: **APFS**
- Scheme: **GUID Partition Map**
- Name: `Storage` (or whatever you want)

APFS is the right choice for a Mac-only setup. Do not use exFAT unless you need Windows/Linux access.

### Mount point

After formatting, it mounts at `/Volumes/Storage`. All service data goes under:

```
/Volumes/Storage/
├── immich/       ← photo library
├── ollama/       ← AI model cache
└── docker/       ← Docker volume data (optional)
```

---

## Step 1: Tailscale (do this first)

Tailscale gives you secure remote access to the Mac mini from anywhere — laptop, phone, wherever. No port forwarding needed.

Install:
```bash
brew install --cask tailscale
```

Start and authenticate:
```bash
open /Applications/Tailscale.app
# Sign in with Google/GitHub — creates your tailnet
```

Enable on your MacBook and phone too. They'll all see each other on a private network.

Find your Mac mini's Tailscale IP:
```bash
tailscale ip -4
# Something like 100.x.x.x
```

From now on, access the Mac mini from anywhere with that IP.

---

## Step 2: Enable SSH

`System Settings → General → Sharing → Remote Login` → On

Test from your laptop:
```bash
ssh youruser@<tailscale-ip>
```

Add your laptop's SSH key so you don't need a password:
```bash
ssh-copy-id youruser@<tailscale-ip>
```

---

## Step 3: OrbStack (Docker)

OrbStack is a lighter, faster Docker Desktop replacement for Mac. Same `docker` CLI, same Compose — just better.

```bash
brew install --cask orbstack
```

Open it, let it start. Verify:
```bash
docker --version
docker compose version
```

That's it. Use `docker` and `docker compose` exactly as you would with Docker Desktop.

---

## Step 4: Immich (Photo Library)

Immich is a self-hosted Google Photos replacement. Fast, mobile app, face recognition, albums, shared libraries.

### Create storage directory

```bash
mkdir -p /Volumes/Storage/immich
```

### Create Compose file

```bash
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

### Start it

```bash
docker compose up -d
```

Open: `http://<tailscale-ip>:2283`

Create your admin account on first open.

### Mobile app

Install **Immich** from the App Store. Point it at `http://<tailscale-ip>:2283`. Enable auto-backup. Done — Google Photos replacement running on your hardware.

### Initial photo import

If you have photos in Apple Photos or on disk:
- Export from Photos.app → drag into Immich web UI
- Or use the Immich CLI for bulk import

---

## Step 5: Ollama (Local AI)

Run natively — not in Docker. Native Ollama uses Apple Silicon GPU (Metal). Docker adds overhead with no benefit here.

### Install

```bash
brew install ollama
```

### Move model cache to 1TB

Models are 4-8GB each and fill up the internal SSD fast. Move the cache:

```bash
mkdir -p /Volumes/Storage/ollama
```

Add to your `~/.zshrc`:

```bash
export OLLAMA_MODELS=/Volumes/Storage/ollama
```

Reload:
```bash
source ~/.zshrc
```

### Run as background service

```bash
brew services start ollama
```

### Pull starter models

```bash
ollama pull qwen2.5-coder:7b   # coding tasks
ollama pull llama3.1:8b        # general purpose
```

### Test

```bash
ollama run qwen2.5-coder:7b "What is a closure in JavaScript?"
```

### Access from laptop

Tunnel the API over SSH so your laptop can use the Mac mini's models:

```bash
ssh -N -L 11434:localhost:11434 youruser@<tailscale-ip>
```

Now `http://localhost:11434` on your laptop routes to the Mac mini. Any tool that supports Ollama endpoints (LM Studio, Continue, etc.) will work.

---

## Step 6: Time Machine from MacBook

Plug the 500GB SSD into the Mac mini. Share it over the network so your MacBook backs up to it.

On Mac mini:
1. `System Settings → General → Sharing → File Sharing` → On
2. Add the 500GB drive as a shared folder
3. Options → enable SMB

On MacBook:
1. `System Settings → General → Time Machine`
2. Add disk → select the shared drive on your Mac mini

Backups happen automatically when on the same network (or over Tailscale).

---

## Keeping Everything Running

### Start services on boot

OrbStack auto-starts Docker containers marked `restart: always` on system boot.

Ollama runs as a brew service (starts on login):
```bash
brew services list  # verify it's running
```

### Update everything

```bash
scripts/update.sh                    # updates Homebrew, Ollama, CLI tools
docker compose pull && docker compose up -d  # update Docker services
```

### Check what's running

```bash
brew services list          # native services (Ollama)
docker ps                   # Docker containers
ollama list                 # loaded models
```

---

## Services Not Worth Setting Up (Yet)

| Service | Why skip |
|---------|----------|
| Plex / Jellyfin | Only useful if you have a large media library |
| Uptime Kuma | Overkill for 2-3 personal services |
| Home Assistant | Only if you have smart home devices |
| Gitea | GitHub works fine for private repos |
| n8n | Add later if you need automation pipelines |

Add these when you actually have a use case, not preemptively.

---

## Quick Reference

```bash
# SSH into Mac mini from anywhere
ssh youruser@<tailscale-ip>

# Immich
cd ~/services/immich && docker compose up -d
open http://<tailscale-ip>:2283

# Ollama
brew services start ollama
ollama list
ollama pull <model>

# Tunnel Ollama to laptop
ssh -N -L 11434:localhost:11434 youruser@<tailscale-ip>

# Update Immich
cd ~/services/immich && docker compose pull && docker compose up -d

# Check everything
brew services list
docker ps
```
