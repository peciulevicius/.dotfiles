# Mac Mini Setup — Step by Step

Condensed checklist for setting up the Mac mini from scratch. Full details and troubleshooting in [HOME_SERVER.md](HOME_SERVER.md).

**Drives:**
- T7 (1TB, has existing photos) → Immich library + TimeMachine volume (both machines)
- T5 (500GB, empty) → ImmichBackup only (nightly rsync of Immich photos from T7)

---

## Phase 1 — Mac mini first boot prep

Run the setup script — it handles sleep config, folder creation, and Immich file setup in one go:

```bash
~/.dotfiles/scripts/mac-mini-setup.sh
```

It will ask for your T7 volume name, then set everything up. To toggle sleep mode later:

```bash
~/.dotfiles/scripts/mac-mini-setup.sh --sleep       # re-enable normal sleep
~/.dotfiles/scripts/mac-mini-setup.sh --sleep-only  # server mode sleep settings only
```

---

## Phase 2 — Prepare the drives

**T7 — add a TimeMachine volume (no data loss)**

T7 already has photos. APFS lets you add a new volume to the same drive without erasing anything.

Open **Disk Utility**:
1. Select **T7** in the left sidebar (the container/disk, not a volume)
2. Click **+** (Add Volume) in the toolbar — do NOT click Erase
3. Name: `TimeMachine`, Format: `APFS`, leave size limits blank
4. Click **Add**

Existing files are untouched. T7 now has two APFS volumes sharing its space.

**T5 — format as ImmichBackup**

T5 is empty, so a clean format:
1. Select **T5** in the left sidebar
2. Click **Erase**
3. Name: `ImmichBackup`, Format: `APFS`
4. Click **Erase**

---

## Phase 3 — Tailscale

Tailscale creates a private network connecting Mac mini, MacBook, and phone. Required for Immich from anywhere (not just home WiFi).

**Mac mini:**
```bash
brew install --cask tailscale
open /Applications/Tailscale.app
# Sign in with Google/GitHub
```

**MacBook + iPhone:** install Tailscale, sign in with the same account.

Get the Mac mini's Tailscale IP — you'll use it everywhere:
```bash
tailscale ip -4
# e.g. 100.64.0.12 — write this down
```

Test from MacBook (works from any network):
```bash
ping <tailscale-ip>
```

---

## Phase 4 — SSH

Lets you control the Mac mini from MacBook terminal from anywhere.

**On Mac mini:**
`System Settings → General → Sharing → Remote Login` → turn **On**

**On MacBook:**
```bash
cat >> ~/.ssh/config << 'EOF'
Host macmini
  HostName <tailscale-ip>
  User <your-mac-mini-username>
EOF

ssh-copy-id macmini   # copy key, no password needed after this
ssh macmini           # test
```

---

## Phase 5 — Docker + Immich

Docker is installed by the dotfiles installer. Open **Docker Desktop** and let it start (or **OrbStack** if you installed that instead — same commands, lighter).

```bash
docker --version       # verify Docker is running
docker compose version
```

The setup script from Phase 1 already created `~/services/immich/docker-compose.yml` and `~/services/immich/.env`. Edit the `.env` and set a real password:

```bash
nano ~/services/immich/.env
# Change DB_PASSWORD to something strong
```

Start Immich:

```bash
cd ~/services/immich
docker compose up -d
docker ps   # should show 4 containers after ~30 seconds
```

Open `http://<tailscale-ip>:2283` → create your admin account.

The template files live in `~/.dotfiles/config/immich/` if you ever need to reference them.

---

## Phase 6 — Import existing photos

```bash
npm install -g @immich/cli
immich login http://<tailscale-ip>:2283 <your-email>
immich upload --recursive /Volumes/<T7-volume-name>/
```

Large libraries take a while. Let it run.

---

## Phase 7 — Nightly photo backup (T7 → T5)

```bash
# Test manually first
~/.dotfiles/scripts/backup-immich.sh

# Schedule at 3am daily
crontab -e
```

Add:
```
0 3 * * * ~/.dotfiles/scripts/backup-immich.sh >> ~/logs/immich-backup.log 2>&1
```

---

## Phase 8 — Time Machine (Mac mini + MacBook)

The `TimeMachine` volume on T7 serves both machines.

**Mac mini (local backup):**
1. `System Settings → General → Time Machine`
2. Add Backup Disk → select `TimeMachine` on T7
3. Done

**MacBook (network backup) — on Mac mini first:**
1. `System Settings → General → Sharing → File Sharing` → On
2. Add the `TimeMachine` volume as a shared folder
3. Options → check **Share as Time Machine backup destination**

**On MacBook:**
1. `System Settings → General → Time Machine`
2. Add Backup Disk → select Mac mini's `TimeMachine` share
3. Done — backs up automatically on the same network

---

## Phase 9 — Phone setup

1. App Store → **Immich**
2. Server URL: `http://<tailscale-ip>:2283`
3. Sign in
4. Profile → **App Settings** → **Background Backup** → enable

Home WiFi = silent background sync. Anywhere else = syncs over Tailscale.

---

## Final verify

```bash
docker ps                              # 4 Immich containers running
tailscale status                       # all devices connected
ssh macmini echo "connected"           # SSH works
open http://<tailscale-ip>:2283        # Immich UI loads
~/.dotfiles/scripts/backup-immich.sh   # backup runs without errors
```
