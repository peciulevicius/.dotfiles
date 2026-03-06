# Mac Mini Setup — Step by Step

Condensed checklist for setting up the Mac mini. Full details and troubleshooting: [HOME_SERVER.md](HOME_SERVER.md).

**Drives:**
- T7 (1TB, has existing photos) → Immich library + `TimeMachine` APFS volume
- T5 (500GB, empty) → `ImmichBackup` (nightly rsync of Immich photos)

---

## Phase 1 — First boot: disable sleep

On the Mac mini, open Terminal:

```bash
~/.dotfiles/scripts/mac-mini.sh sleep off
```

This disables sleep so Immich syncs and backups run overnight. To toggle later:

```bash
~/.dotfiles/scripts/mac-mini.sh sleep on    # normal sleep (if you ever need it)
~/.dotfiles/scripts/mac-mini.sh sleep off   # back to server mode
```

---

## Phase 2 — Prepare the drives

**T7 — add a TimeMachine APFS volume (no data loss)**

T7 already has your photos. APFS lets you add a new volume without touching existing files.

Open **Disk Utility**:
1. Select **T7** in the left sidebar — the disk/container row, not a volume row
2. Click **+** (Add Volume) in the toolbar — do NOT click Erase
3. Name: `TimeMachine`, Format: `APFS`, leave size limits blank
4. Click **Add**

Done. Existing photos untouched. T7 now has two APFS volumes sharing its space dynamically.

**T5 — format as ImmichBackup**

T5 is empty, clean format:
1. Select **T5** in the left sidebar
2. Click **Erase**
3. Name: `ImmichBackup`, Format: `APFS`
4. Click **Erase**

---

## Phase 3 — Tailscale

Tailscale connects Mac mini, MacBook, and phone on a private network. Required for Immich access from anywhere outside home WiFi.

**Mac mini:**
```bash
brew install --cask tailscale
open /Applications/Tailscale.app
# Sign in with Google/GitHub
```

**MacBook + iPhone:** install Tailscale, sign in with the same account.

Get the Mac mini's Tailscale IP — used everywhere from here on:
```bash
tailscale ip -4
# e.g. 100.64.0.12 — write this down
```

---

## Phase 4 — SSH

Lets you control the Mac mini from MacBook terminal remotely.

**On Mac mini:**
`System Settings → General → Sharing → Remote Login` → turn **On**

**On MacBook:**
```bash
cat >> ~/.ssh/config << 'EOF'
Host macmini
  HostName <tailscale-ip>
  User <your-mac-mini-username>
EOF

ssh-copy-id macmini   # copy key — no password prompt after this
ssh macmini           # test
```

---

## Phase 5 — Immich setup

Now that the drives are ready and connected, run the setup command:

```bash
~/.dotfiles/scripts/mac-mini.sh immich-setup
```

It will show connected volumes, ask for your T7 volume name (whatever macOS calls it — e.g. `Samsung T7`, `T7 Touch`), then:
- Create the Immich folders on T7
- Write `~/services/immich/docker-compose.yml` with your volume name already in it
- Copy `.env` template to `~/services/immich/.env`

---

## Phase 6 — Start Immich

Open Docker Desktop (or OrbStack) and let it start, then:

```bash
nano ~/services/immich/.env        # set DB_PASSWORD to something strong
cd ~/services/immich
docker compose up -d
docker ps                          # should show 4 containers after ~30s
```

Open `http://<tailscale-ip>:2283` → create your admin account.

---

## Phase 7 — Import existing photos

Your existing photos/videos are already on T7. Import them into Immich:

```bash
npm install -g @immich/cli
immich login http://<tailscale-ip>:2283 <your-email>
immich upload --recursive /Volumes/<T7-volume-name>/
```

Large libraries take a while. Let it run.

---

## Phase 8 — Nightly photo backup (T7 → T5)

```bash
# Test it manually first
~/.dotfiles/scripts/backup-immich.sh

# Schedule it at 3am daily
crontab -e
```

Add:
```
0 3 * * * ~/.dotfiles/scripts/backup-immich.sh >> ~/logs/immich-backup.log 2>&1
```

---

## Phase 9 — Time Machine (Mac mini + MacBook)

The `TimeMachine` APFS volume on T7 backs up both machines.

**Mac mini (local):**
1. `System Settings → General → Time Machine`
2. Add Backup Disk → select `TimeMachine` on T7
3. Done

**MacBook (over network) — on Mac mini first:**
1. `System Settings → General → Sharing → File Sharing` → On
2. Add `TimeMachine` volume as a shared folder
3. Options → check **Share as Time Machine backup destination**

**On MacBook:**
1. `System Settings → General → Time Machine`
2. Add Backup Disk → select Mac mini's `TimeMachine` share
3. Done — backs up automatically on the same network

---

## Phase 10 — Phone

1. App Store → **Immich**
2. Server URL: `http://<tailscale-ip>:2283`
3. Sign in
4. Profile → **App Settings** → **Background Backup** → enable

Home WiFi = silent background sync. Anywhere else = syncs over Tailscale when you open the app.

---

## Final verify

```bash
docker ps                              # 4 Immich containers running
tailscale status                       # all devices connected
ssh macmini echo "connected"           # SSH works
~/.dotfiles/scripts/backup-immich.sh   # backup runs without errors
```

Open `http://<tailscale-ip>:2283` in browser — Immich loads.
