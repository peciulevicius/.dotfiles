# Mac mini Setup

Mac mini M4 as a second desk computer and photo hub. With a KVM you switch between MacBook and Mac mini using the same keyboard, mouse, and monitor.

---

## What It Actually Does

| Thing | Value |
|-------|-------|
| **Immich** | Phone photos auto-backup wirelessly — your own Google Photos |
| **Time Machine target** | MacBook backs up to the Mac mini's 500GB SSD automatically |
| **Photo backup** | Nightly copy of photos from 1TB → 500GB in case 1TB fails |
| **Tailscale** | So your phone can reach Immich when you're not home |
| **SSH** | Optional — there when you need to check something remotely |

**The Mac mini does not need Time Machine itself.** Time Machine is for your MacBook — it backs up TO the Mac mini. The Mac mini's own data (photos) is protected by the nightly rsync copy to the 500GB.

---

## Storage

| Drive | Role |
|-------|------|
| 1TB SSD | Immich photo library (primary) |
| 500GB SSD | 200GB Time Machine (MacBook) + 300GB photo backup (rsync) |

Both stay connected permanently.

---

## Before You Start — Migrate Existing Photos

You have photos on both drives. Get everything onto the 1TB before touching anything.

**1. See what drives are connected:**
```bash
ls /Volumes/
```

**2. Copy everything from 500GB to 1TB:**
```bash
rsync -av --progress /Volumes/<500gb-name>/ /Volumes/<1tb-name>/
```

Wait for it to finish. Then verify the file count matches:
```bash
find /Volumes/<500gb-name> -type f | wc -l
find /Volumes/<1tb-name> -type f | wc -l
```

**3. Only format the 500GB once you're sure everything is on the 1TB.**

---

## Setup

### 1. Format the drives

**1TB → Disk Utility → Erase:**
- Format: APFS
- Name: `Storage`

**500GB → Disk Utility → Partition → two partitions:**
- `TimeMachine` — 200GB
- `ImmichBackup` — 300GB

Create folders on the 1TB:
```bash
mkdir -p /Volumes/Storage/immich
mkdir -p ~/services/immich
mkdir -p ~/logs
```

---

### 2. Tailscale

Lets your phone reach Immich when you're away from home. Also lets you SSH in if you ever need to.

```bash
brew install --cask tailscale
open /Applications/Tailscale.app
# Sign in with Google or GitHub
```

Install on your phone too (App Store, same account). Get the Mac mini's IP:
```bash
tailscale ip -4
# e.g. 100.64.0.12 — save this
```

---

### 3. SSH (optional but quick to set up)

Only useful if you ever need to check or fix something remotely. Takes 2 minutes so worth having.

`System Settings → General → Sharing → Remote Login` → On

On your MacBook, add a shortcut (`~/.ssh/config`):
```
Host macmini
  HostName <tailscale-ip>
  User youruser
```

Copy your key so no password needed:
```bash
ssh-copy-id macmini
```

---

### 4. OrbStack (Docker)

Immich runs in Docker. OrbStack is lighter than Docker Desktop.

```bash
brew install --cask orbstack
# Open it and let it start
```

---

### 5. Immich

Self-hosted Google Photos. Your phone backs up to it automatically over WiFi.

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

---

### 6. Phone backup

Install **Immich** from the App Store. Open it → enter server URL: `http://<tailscale-ip>:2283` → sign in → go to Profile → enable **Automatic Backup**.

That's it. From now on:
- Phone on home WiFi → Immich syncs automatically in the background
- Phone anywhere → syncs over Tailscale when you open the app
- No cables, no manual export, no iCloud needed

**Import existing photos:** drag folders into the Immich web UI at `http://<tailscale-ip>:2283`, or use the CLI for large imports:
```bash
npm install -g @immich/cli
immich upload --recursive /Volumes/Storage/your-photos-folder
```

---

### 7. Photo backup (nightly rsync)

Copies photos from 1TB → 500GB every night so a drive failure doesn't lose everything.

Test it:
```bash
~/.dotfiles/scripts/backup-immich.sh
```

Schedule it (open crontab editor):
```bash
crontab -e
```

Add this line:
```
0 3 * * * ~/.dotfiles/scripts/backup-immich.sh >> ~/logs/immich-backup.log 2>&1
```

---

### 8. Time Machine (MacBook backup)

**On Mac mini:**
1. `System Settings → General → Sharing → File Sharing` → On
2. Add the `TimeMachine` partition
3. Options → check **Share as Time Machine backup destination**

**On MacBook:**
1. `System Settings → General → Time Machine → Add Backup Disk`
2. Select the Mac mini's `TimeMachine` share

MacBook backs up automatically when on the same network. Done.

---

## If a Drive Fails

**1TB fails** — Immich goes offline, photos are on 500GB from last night.

Recovery: edit `~/services/immich/docker-compose.yml`, change the upload volume path from `/Volumes/Storage/immich/upload` to `/Volumes/ImmichBackup/immich/upload`, then `docker compose down && docker compose up -d`. Photos are back. Buy a new 1TB, copy data back, repoint Immich.

**500GB fails** — MacBook Time Machine stops, nightly backup stops. Photos on 1TB unaffected. Buy a replacement, reformat, re-point Time Machine and cron job.

---

## Should It Sleep?

Up to you.

- **Let it sleep** — fine if you're always home when you need it. Immich won't sync phone photos while it sleeps. Time Machine won't run. SSH won't connect.
- **Prevent sleep** — if you want phone photos to sync automatically overnight, or want to SSH from outside the house.

To prevent sleep:
```bash
sudo pmset -a sleep 0 disksleep 0 displaysleep 10
```

To revert to normal:
```bash
sudo pmset -a sleep 1
```

---

## Quick Reference

```bash
# SSH in
ssh macmini

# Check services
docker ps

# Restart Immich
cd ~/services/immich && docker compose restart

# Update Immich
cd ~/services/immich && docker compose pull && docker compose up -d

# Run backup manually
~/.dotfiles/scripts/backup-immich.sh

# Check backup log
cat ~/logs/immich-backup.log
```
