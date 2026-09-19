# Home Server — TODO

Outstanding work only. Finished items live in
[HOME_SERVER_CHANGELOG.md](HOME_SERVER_CHANGELOG.md).

Grouped by "what happens if I ignore this", not by number.

---

## Do these first — you lose data or access without them

### Disable Tailscale key expiry

Key expires **2027-03-04**. When it does, the Mac mini silently drops off the
tailnet: no `ssh macmini` from away, and every Tailscale-only service
(Sonarr, Radarr, Prowlarr, Transmission, Syncthing, Jellyseerr, Bazarr, Grafana,
Prometheus, LazyLibrarian, Karakeep) becomes unreachable. This already happened
once and was only noticed on 2026-09-05, during an outage, from home.

- [ ] Tailscale admin console → Machines → `macmini` → ⋯ → **Disable key expiry**
- [ ] Same for `ugreen-nas`

Logging back in only resets the same six-month timer — disabling expiry is the
actual fix.

### Get one copy of the photos out of the building

Photos live on the NAS (RAID 5) plus T7 and T5 — but all three sit in the same
room. RAID survives a dead drive; it does not survive fire, flood, or theft.
R2 deliberately excludes photos (too large).

- [ ] Take T5 to the parents' house once it is loaded (it was verified 1:1 on
      2026-09-05 — see the backup section below)
- [ ] Only after that, consider dropping iCloud

### Power-outage recovery is still manual

`pmset autorestart` is on, so the Mac mini *tries* to boot after a cut — but
**FileVault is enabled with no auto-login**, so it stops at the unlock screen.
Until someone types the password: no Docker, no NAS mounts, no cloudflared, no
watchdogs. This is exactly what happened on 2026-08-16.

- [ ] Pick one:
  1. **UPS** on the Mac mini + NAS — brief outages never cut power, so none of
     the recovery chain is exercised. Keeps FileVault. ~€100–150.
  2. Disable FileVault, enable auto-login — full unattended recovery, but the
     internal SSD is no longer encrypted at rest.
- [ ] Confirm the NAS's own "Auto power-on when power is supplied" is enabled
      (NAS UI → Hardware & Power). Even a self-recovering Mac mini is useless if
      the NAS stays off.

### Rotate the reused NAS passwords

Both NAS accounts (`Džiugas` admin + `macmini` SMB service account) currently
use the same password as elsewhere. Rotate to unique generated passwords:
- [ ] `Džiugas` (web UI admin) — generate in Bitwarden, update entry
- [ ] `macmini` (SMB) — generate in Bitwarden; after changing on NAS, update
  the saved credential in macOS Keychain on the Mac mini (Finder will prompt
  on next mount; also remount the four shares)
- [ ] While at it: audit other reused passwords flagged by Bitwarden's
  Vault Health report

---

## Worth doing soon

### Regenerate missing Immich thumbnails

87 assets show "error loading image" — all videos, thumbnails lost while Immich
was crash-looping in early September. Originals are intact (verified on disk;
0 assets flagged offline).

- [ ] photos.peciulevicius.com → Administration → Jobs → **Generate Thumbnails →
      Missing**

### Reconcile services marked removed that are still running

The changelog records both as removed; all four containers are up as of
2026-09-05. Either stop them or correct the record.

- [ ] `actual-budget` — replaced by Wallet by Budget Bakers, still running
- [ ] `karakeep` + `karakeep-chrome` + `karakeep-meilisearch` — reverted to
      Linkwarden, still running (three containers' worth of RAM)

### External backups are manual now — nothing warns when they go stale

The nightly cron was removed on 2026-09-05 (the drives are not permanently
connected, so it failed every night). T5 had silently drifted seven weeks out of
date before anyone noticed.

- [ ] Set a recurring reminder, or check the drive's newest file against the NAS
      before trusting it
- [ ] Decide what T5 is *for* — once it lives offsite it can never be the
      routine local target

Run a backup with:
`~/.dotfiles/scripts/backup/backup-external.sh /Volumes/T7 --dry-run` then without `--dry-run`.

### Weekly database dumps have gaps

`~/backups/` holds Aug 2, Aug 9, Aug 30 — **Aug 16 and Aug 23 are missing**.
The Sunday 4am cron should have produced them; the Mac was likely asleep or the
runs failed silently.

- [ ] Check whether next Sunday's dump lands; if not, add a heartbeat

### Router DHCP reservation for the NAS

No longer load-bearing — everything addresses the NAS as `DH4300PLUS-DP.local`
(mDNS) since 2026-09-05, which absorbs IP drift. Still worth pinning.

- [ ] OpenWrt (`192.168.1.1`) → static lease, MAC `6c:1f:f7:a9:39:e9`

---

## Projects (no deadline)

### Pi-hole — finish the deployment

**Note:** PIHOLE_API_KEY is now configured in `~/services/glance/.env` — DNS stats widget is working.

**Goal:** Access `*.peciulevicius.com` on local WiFi without going through Cloudflare.

- [ ] In Pi-hole admin (http://localhost:8053/admin) → Local DNS → DNS Records
- [ ] Add for each subdomain → Mac mini local IP
- [ ] Set router DNS to Mac mini IP (primary) + `1.1.1.1` (fallback)
- [ ] Test: `nslookup home.peciulevicius.com` should return Mac mini local IP

**Reality check on what Pi-hole can do:** it blocks by domain, so it stops
trackers, telemetry and most web/banner ads — but **not YouTube or Spotify ads**,
which are served from the same domains as the content itself. See the ad-blocking
notes in `docs/SERVICES.md`.

Currently only ~3.6% of queries are blocked (12,812 queries / 459 blocked), which
is low because the router still does not point at Pi-hole — only manually
configured devices use it.

### Import old photo archives into Immich

~140GB of personal photos sitting on T7 outside of Immich, organised by year/trip:

- `/Volumes/T7/2002` → `/Volumes/T7/2024` — ~130GB of photos going back years
- `/Volumes/T7/from iphone (reikia surušiuoti)` — 9.2GB unsorted iPhone photos
- Notable: `/Volumes/T7/2024` (99GB) contains Barcelona F1 + Zakopane trips with both iPhone and camera shots

- [ ] Check if any of these are already in Immich (avoid duplicates)
- [ ] Import via Immich CLI or bulk upload through the web UI
- [ ] Sort/tag the unsorted iPhone folder before importing
- [ ] Delete originals from T7 after confirming import (frees ~140GB)

### Paperless-NGX — organise documents

Paperless-NGX doesn't support traditional folders — it uses **tags**, **document types**, and **correspondents** instead.

- [ ] Create document types: e.g. "Invoice", "Contract", "Receipt", "Statement"
- [ ] Create correspondents: e.g. "Bank", "Employer", "Government"
- [ ] Create tags: e.g. "Tax 2024", "Important", "Archive"
- [ ] Assign types/correspondents/tags to uploaded documents
- [ ] Use **Saved Views** (left sidebar) to create folder-like filtered views

### Linkwarden — browser extension + import

- [ ] Install Linkwarden browser extension
- [ ] Import bookmarks from Chrome/Brave

### VPN for torrents

**Goal:** Route Transmission traffic through a VPN so ISP can't see torrent activity. Not urgent — no downloads planned for ~1 month.

**Provider options (pick one):**
- [ ] **Mullvad** — €5/mo, best privacy, no email needed, cancel anytime
- [ ] **Proton VPN** — free tier works but slower, no port forwarding

**Setup (after choosing provider):**
- [ ] Create `services/gluetun/docker-compose.yml` with VPN credentials
- [ ] Update Transmission compose to use `network_mode: service:gluetun`
- [ ] Test: `docker exec transmission curl ifconfig.me` should show VPN IP, not home IP

### Notes — make capture frictionless before changing tools

**Full plan: [guides/NOTES.md](guides/NOTES.md).** The vault, routing rules and
Kindle sync all exist and go unused. The problem is capture friction, not the
tool — swapping Obsidian for something else reproduces the same failure later.

- [ ] Sync the vault via **iCloud** (native in Obsidian, free, reliable on
      iOS/Mac). Syncthing stays for the Mac mini leg; switch to Obsidian Sync
      (~€4/mo) only if a Pixel happens — iOS Syncthing is the weak point.
- [ ] **One** quick-capture Shortcut on the iPhone home screen, ≤2 taps,
      appending to the daily note
- [ ] Install the **Obsidian Web Clipper** in Brave (complements Linkwarden:
      it archives links, the clipper captures content)
- [ ] Verify the Kindle sync still runs — it's on the **Mac mini**, not here:
      `ssh macmini` then `crontab -l | grep kindle` and
      `tail -20 ~/logs/kindle-sync.log`
- [ ] **30 days of capture only, zero organising.** Then reassess.
      If it still hasn't stuck, Apple Notes for fleeting + Obsidian for durable
      is a legitimate end state, not a failure.
- [ ] Later: point Odysseus's RAG at the vault

### De-Google — migrate off all Google services

**Full plan: [guides/DEGOOGLE.md](guides/DEGOOGLE.md).** Annotated replacement
list for every Google service: **[guides/DEGOOGLE_ALTERNATIVES.md](guides/DEGOOGLE_ALTERNATIVES.md)**
— check it before swapping any individual service. Only the live decisions and
next actions live here.

**Where you actually are:** Vaultwarden, Nextcloud, Immich, Tailscale, own domain
with per-service subdomains — all done. That is PewDiePie's entire 22-minute
video, finished months ago. **Four gaps remain: email, phone, calendar/contacts,
AI.** Don't restart from step one.

#### ⚠️ Do this before anything else — Google Authenticator

It holds your 2FA codes and syncs to the Google account you're trying to leave.
Lose that account or phone before migrating and you're locked out of everything
it protects. **Highest-priority item in the whole de-Google effort.**

- [ ] Google Authenticator → ⋯ → Transfer accounts → **Export accounts**
- [ ] Import into **Ente Auth** (open source, E2E, cross-platform) — or
      Vaultwarden, which unlocks Bitwarden premium TOTP free when self-hosted,
      at the cost of keeping both factors in one vault
- [ ] Verify several logins work before deleting anything; keep the old app a month

#### Accounts and "Sign in with Google"

- [ ] List dependencies: Google Account → Security → *Your connections to
      third-party apps & services*
- [ ] For each that matters: set a real password, then change the email —
      converts OAuth into a login you control
- [ ] **Never delete the Google account.** It breaks remaining OAuth logins and
      frees the address for someone else to register and attempt resets with.
      Goal is to stop *using* Google, not to delete it.

#### Email — the only real gap

Decision is still open. `guides/DEGOOGLE.md` has the full comparison and an
explanation of how MX/SPF/DKIM actually work.

**Do not self-host the mail server** — residential IP, blocklists, blocked
port 25, no reverse DNS. Mail silently lands in spam and you never find out.

Free first step, no provider decision needed, ~15 minutes:

- [ ] Cloudflare → `peciulevicius.com` → Email → **enable Email Routing** (free)
- [ ] `dziugas@peciulevicius.com` + catch-all → forwards to current Gmail
- [ ] Start handing out the new address everywhere immediately

That alone means every future switch is a DNS edit. Then, when ready to leave
Gmail properly:

- [ ] **Budget is ~€1/month. Pick Purelymail — $10/yr (~€0.77/mo).** Native
      IMAP/SMTP, no hard limits on domains/addresses/storage. Verify the price
      at signup: their 2026 roadmap says the pricing model is being redesigned.
  - Backup: **Migadu Micro ($19/yr)** — plain IMAP but a hard **20 outgoing
    msgs/day cap**
  - ❌ **Fastmail is out** at ~$60/yr — 6× budget. Nextcloud covers the
    CalDAV/CardDAV it would have given us.
  - ❌ **Not Proton** (Bridge-only IMAP fights the headless Mac mini),
    ❌ **not Tuta** (no IMAP at all — Odysseus and `kindle_sync.py` can't connect),
    ❌ **not Zoho free** (webmail only, no IMAP)
- [ ] **Redirecting existing mail:** Phase A = new address forwards *to* Gmail
      (free, zero risk). Phase B = flip it — Gmail → Settings → Forwarding →
      forward all to the new address, and set it as default "Send mail as".
      Everything then lands in one inbox regardless of which address senders use.
- [ ] Repoint MX, add SPF/DKIM/DMARC, import the Gmail Takeout `.mbox`
- [ ] Update `IMAP_SERVER` in `pkm/config.py`
- [ ] Critical accounts first: Apple ID, banks, GitHub, Cloudflare, Stripe

#### Calendar + Contacts — unblocked, ~1 hour

Nextcloud is already running. Nothing is stopping this.

- [ ] Enable Nextcloud Calendar + Contacts apps
- [ ] Import Google `.ics` and `.vcf` exports
- [ ] Add CalDAV + CardDAV accounts on the iPhone, verify two-way sync

#### Phone — decision: don't buy a Pixel right now

**You already captured ~90% of the win by self-hosting.** A de-Googled iPhone
gets you to the stated goal; what's left is *Apple* telemetry, a smaller and
different problem. Against that: €403, losing Apple Wallet's cards+coupons (no
GrapheneOS equivalent — Google Wallet refuses to run), a bigger phone than the
mini you chose, and you'd carry the iPhone anyway for React Native iOS testing.

**Revisit when the 13 mini actually ages out (~2028–2030).** Buy a €233 Pixel 8a
now only if the tinkering itself is the point — in which case it's a test device,
not a replacement. Don't buy the €403 10a today either way.

**The iPhone 13 mini cannot run a custom OS.** Bootloader can't be unlocked;
checkm8 only covers A11 and earlier (yours is A15). It's harden-iOS or buy an
Android — there is no third option.

GrapheneOS *is* the most complete privacy OS, and it is Pixel-only because
Pixels are effectively the only phones that let you relock the bootloader with
your own key.

- [ ] **Keep the 13 mini regardless.** On iOS 26.5, gets iOS 27, major updates to
      ~2027–2028, security to ~2029–2030. You also **need a physical iPhone to test
      Expo/React Native iOS builds** — so it stays either way. The realistic end
      state is Pixel as daily driver, iPhone as dev device + tap-to-pay fallback.
- [ ] **Now (~€90):** replace the 13 mini battery — buys years of runway
- [ ] **Now (free):** enable **Advanced Data Protection** on iCloud, delete
      Google apps, default search → DuckDuckGo
- [ ] **Before committing to any Pixel:** check your banking apps survive
      hardware attestation on a custom OS, and that HeliBoard does Lithuanian
      swipe typing well enough
- [ ] **Pick by purpose.** GrapheneOS supports Pixel 6 → **Pixel 10a** (no Pixel 11 yet).
  - **Daily driver → Pixel 10a, €403 new at Telia.** Supported to **March 2033**
    — furthest of any device. New battery, local warranty, no carrier-lock risk.
  - **Just testing → Pixel 8a, €233 refurbed.** Supported to ~2031.
  - ❌ **Not the Pixel 6 Pro at €205** — Google support ends **October 2026**,
    this month. GrapheneOS drops devices when firmware updates stop.
- [ ] **Check first, in this order:** does Google Wallet still refuse to run on
      GrapheneOS (tap-to-pay would stop working — the biggest daily friction);
      do your banks and Revolut survive hardware attestation; is HeliBoard's
      Lithuanian swipe typing good enough.
- [ ] Note the 10a is ~6.3" — **no modern Pixel is small**. You chose a *mini*.
- [x] ~~Does Mullvad work on GrapheneOS?~~ Yes — GrapheneOS's FAQ recommends it,
      installs from F-Droid, no Play Store. Caveat: Android allows always-on VPN
      in only one profile at a time. Separate from the Transmission/gluetun plan.
- [ ] If buying refurbished: confirm carrier-unlocked, not a US carrier model —
      those bootloaders cannot be unlocked, making GrapheneOS impossible.
- [x] ~~Non-Pixel options?~~ Yes — CalyxOS runs on **Fairphone 5** and some
      Motorola while still relocking the bootloader. **User prefers to stick with
      Pixel**, so Fairphone is noted but not planned.
- [ ] Minimal Phone 2 (€599/€699, 12GB) is **2.5–3× the 8a and cannot run
      GrapheneOS** — not a Pixel, no Titan M2, ships with Play Services. It solves
      *attention*, not *privacy*. GrapheneOS user profiles give the focus benefit
      for €233 — which is what PewDiePie chose over a dumbphone.

#### Quick wins

- [ ] Confirm default search is DuckDuckGo/Kagi in every browser **and** on the phone
- [ ] Confirm Brave (already installed) is the default browser
- [ ] Audit "Sign in with Google" — each one breaks if you ever delete the account
- [ ] Remove Google as a Cloudflare Access identity provider — **after** email moves
- [ ] Maps: accept the loss. Apple Maps is the pragmatic swap; Organic Maps for offline.

### Self-hosted AI — own the history, rent the compute

**Full plan: [guides/SELF_HOSTED_AI.md](guides/SELF_HOSTED_AI.md).**

Ollama + Open WebUI were removed once already for lack of RAM (see
[HOME_SERVER_CHANGELOG.md](HOME_SERVER_CHANGELOG.md)). The likely real cause: **Ollama was running in Docker, which on macOS
has no GPU passthrough** — so it ran on CPU at a fraction of Metal speed. Rule
going forward: models run natively via Homebrew, only the web UI goes in Docker.

**What you get from Phase 1 without any new hardware:** the chat history,
memories, RAG corpus and agent configs live on your disk instead of inside
Anthropic's and OpenAI's accounts. The prompts themselves still go to the
provider — that is data *sovereignty*, not data *privacy*. A local model is the
only way to get both, and that's Phase 2.

#### Phase 1 — workspace with cloud backends

- [ ] Free RAM by finishing the reconciliation above — stop `karakeep` ×3 and
      `actual-budget` (~400MB, already on the list)
- [x] ~~Check Odysseus macOS support~~ — confirmed: repo ships `build-macos-app.sh`
      and `start-macos.sh`. <https://github.com/odysseus-dev/odysseus>, AGPL-3.0.
      Docker Compose is still the right path here for consistency.
- [ ] `services/odysseus/` — compose + `.env.example`; app listens on **port 7000**
- [ ] Keep **`AUTH_ENABLED=true`** (the README insists on it for networked deploys)
- [ ] Data dir on the **internal SSD**, never the NAS — it's database-backed
- [ ] Anthropic or OpenRouter API key as the first backend
- [ ] Expose at `ai.peciulevicius.com`, **behind Cloudflare Access** — this holds
      your email, documents and memories, and the agent can execute code
- [ ] Wire its **IMAP/SMTP email** integration to the new mailbox once chosen, and
      its **CalDAV** sync to Nextcloud Calendar. It also speaks **MCP**.
- [ ] Add data dir to `rclone-backup.sh`; add Glance tile + Uptime Kuma check

#### Phase 2 — local models, natively

- [ ] `brew install ollama` — **native, not Docker**; workspace points at
      `http://host.docker.internal:11434`
- [ ] Use Odysseus's **Cookbook** if available — it scans the hardware and scores
      what this machine can actually run, which settles the "do I need more RAM"
      question with data instead of guesswork
- [ ] Start at Qwen3 4B (~2.5GB). Ceiling here is ~8B. Nothing 30B+ fits in 16GB.
- [ ] Route by sensitivity: Claude for coding and hard reasoning, local for
      journal/health/finances/Paperless documents and bulk drudgery
- [ ] RAG over Paperless + Obsidian + Linkwarden — a small model over *your*
      documents beats a big model that has never seen them

#### Phase 3 — hardware (only after Phase 2 proves the need)

- [ ] Don't buy anything until you know what you're actually missing.
      M4 Pro 48–64GB ~€1,600–2,200, or a used 3090 ~€700–1,000. Claude is ~€20/mo,
      so a €2,000 box is eight years of subscription and still loses at coding.
      Buy it because local inference is the goal, not to save money.

#### Bring Claude + ChatGPT history home

- [ ] Export both (ChatGPT: Data Controls → Export; Claude: Privacy → Export)
- [ ] Copy ChatGPT memories by hand — they are **not** in the export
- [ ] Check whether the workspace already ships a ChatGPT importer before writing one
- [ ] `scripts/ai/import-chat-history.py` — normalise both exports to the
      workspace's import format
- [ ] Keep raw exports at `/Volumes/unsorted/ai-exports/`, add to `rclone-backup.sh`
- [ ] Point RAG at the archive — years of your own context, searchable

### NAS — remaining follow-ups

**Status (Jul 2026):** NAS arrived ✅ (UGREEN DH4300 Plus, SN H43001J61J30FAD0, warranty until 2028-07-23). Drives ordered — 3× IronWolf Pro 6TB recert (ST6000NE000) €230 each from [datablocks.dev](https://datablocks.dev), preorder arriving **~Jul 27–31**.

**Done (pre-drives, Jul 22):**
- [x] NAS on network at 192.168.1.73 via WiFi extender ethernet port (100Mbps — extender is the bottleneck, acceptable for now)
- [x] `nas.peciulevicius.com` → UGOS Pro web UI, via existing cloudflared tunnel on Mac mini (ingress: `http://192.168.1.73:9999`). No Docker needed on NAS.
- [x] UGREENlink remote access active (backup access: https://ug.link/dh4300plus-dp)

**Still to do (pre-drives):**
- [ ] **NEXT SESSION:** Reserve 192.168.1.73 for NAS in router DHCP settings — if IP changes, nas.peciulevicius.com breaks. Steps:
  1. Open http://192.168.1.1 in browser, log in (admin password often on router sticker)
  2. Find the DHCP section — usually under *LAN*, *Network*, or *Advanced → DHCP Server*. The feature is called **"Address Reservation"**, **"Static Lease"**, **"DHCP Binding"**, or **"Reserved IP"** depending on brand
  3. Add entry: MAC `6c:1f:f7:a9:39:e9` → IP `192.168.1.73` (device may appear in a connected-clients list as DH4300PLUS-DP — can often click it and hit "reserve")
  4. Save/apply. No NAS reboot needed — reservation kicks in at next DHCP renewal
  5. Verify: NAS Control Panel → Network still shows 192.168.1.73
- [ ] Enable SSH (Control Panel → Terminal; set "Shut down automatically" to never)
- [ ] Enable "Auto power-on when power is supplied" + WOL (Hardware & Power → Power)
- [ ] Set up 2FA on admin account (Security → Account security)
- [ ] Enable DoS protection (Security → Security)
- [ ] Change custom domain name from "localhost" to "nas" (Device Connection → LAN)

**Migration done (2026-08-04)** ✅
- [x] RAID 5 pool created (3× 6TB IronWolf Pro = ~11TiB usable), Btrfs
- [x] SMB on; shares: `media`, `immich`, `audiobooks`, `books`, `unsorted`; service account `macmini` (ASCII name — `ž` in `Džiugas` breaks SMB auth)
- [x] Tailscale via Docker container on NAS (`ugreen-nas`, 100.95.228.35) — remote SMB/Finder
- [x] Full copy T7 → NAS (~680GB incl. 142G photo archives → `unsorted`), zero errors
- [x] All services switched to NAS paths (`/Volumes/media` etc.); Immich Postgres moved to internal SSD (`~/services/immich/data/postgres`) — DBs must not live on SMB
- [x] Reboot-proof mounts: `scripts/utils/mount-nas.sh` + `com.peciulevicius.mount-nas` LaunchAgent
- [x] Glance tile for NAS

**Remaining follow-ups:**
- [x] ~~Update rclone/T5 backup scripts to NAS paths~~ (2026-08-04 — backup-t5.sh, backup-immich.sh, rclone-backup.sh all read from NAS mounts; T7 fully decoupled, safe to disconnect. Keep T7 data intact on the shelf ~2 weeks before wiping/repurposing)
- [ ] Delete stale `immich/postgres` folder on NAS share (460MB dead copy — via Files app)
- [ ] Verify first NAS-sourced backups: T5 cron (3am, needs T5 plugged) + rclone (5am)
- [ ] Decide: delete stale `/Volumes/T7/docker/` (53G old Docker VM copy)
- [ ] T5 future plan: reload with full photo/video collection, store at parents' home as offsite family copy
- [ ] Verify drive sleep works (configured: 20 min idle)
- [ ] Optional: Bonjour + Time Machine target, NAS rsync service
- [ ] Mac mini auto-login (System Settings → Users & Groups) — without it, after a power outage neither Docker, cloudflared, nor NAS mounts come up
- [ ] Watch streaming: 4K high-bitrate files may exceed the extender's ~100Mbps ceiling — if Jellyfin buffers, wire the NAS/Mac path properly

**Hardware reference:** 4-bay, RK3588C ARM 8-core, 8GB RAM (keep NAS storage-only — no heavy Docker workloads; compute stays on Mac mini), 2.5GbE port. Purchase total ~€1,060 (NAS €340 + drives €690 + switch/cables €30).

---

## Reference

### RAM baseline

Mac mini M4, **16GB unified memory**. Docker VM ceiling is now **10GB** (raised
from 7.8GB on 2026-07-23), but that is a *ceiling*, not a reservation — the VM
allocates lazily.

Measured 2026-09-08 with all 42 containers running:

| Metric | Value | Reading |
|---|---|---|
| Containers, total | 5.2 GiB of the VM's 9.7 GiB | comfortable |
| Docker VM, host-resident | **2.06 GB** | the 10GB ceiling is not actually taken |
| macOS memory free | 43% | healthy |
| Swap used | ~2.5 GB of 3 GB, **slowly shrinking** | historical, not active pressure |
| Compressor occupied | ~7.5 GB | macOS working, but coping |

**How to read swap on macOS:** "Pages free" is always near zero by design — macOS
uses spare RAM as cache, so a low free-page count is not a warning. Judge by
*memory pressure percentage* and whether swap is **growing**. Stable or shrinking
swap is fine, even at 2.5GB. Growing swap plus pressure under ~20% is the real
alarm.

Biggest single consumers: `immich_server` (~775MB), `paperless` (~374MB),
`mealie` (~354MB), `calibre` (~315MB), `karakeep` (~273MB).

**Containers safe to stop while traveling:**
`nextcloud`, `nextcloud_db`, `pihole`, `bazarr`, `sonarr`, `radarr`, `prowlarr`, `transmission`, `jellyseerr`, `immich_machine_learning`, `mealie`

---

## Drive Layout (reference)

Since the 2026-08-04 migration the **NAS is primary**. The two Samsung SSDs are
backup targets only, plugged in occasionally and synced by hand.

| Device | Size | Role | Mount path |
|--------|------|------|-----------|
| **UGREEN NAS** | ~11TiB usable (RAID 5) | Primary storage | `/Volumes/<share>` |
| **T7** | 1TB | Manual backup | `/Volumes/T7/` |
| **T5** | 500GB | Manual backup, destined offsite | `/Volumes/Backup/` |

**What lives where:**

| Data | Where | Path |
|------|-------|------|
| Immich photos | NAS | `/Volumes/immich/upload` |
| Immich database | Internal SSD | `~/services/immich/data/postgres` (never on SMB — DBs corrupt over network mounts) |
| Immich thumbnails | Internal SSD | `~/services/immich/data/thumbs` (SSD for fast scrolling; regenerable) |
| Media (movies, TV, downloads) | NAS | `/Volumes/media/` |
| Audiobooks | NAS | `/Volumes/audiobooks/` |
| Calibre books | NAS | `/Volumes/books/` |
| Docker data | Internal SSD | `~/Library/Containers/com.docker.docker` |

**Still on T7 and not yet in Immich:** the year folders (`2002`–`2024`, `Močiutė`,
`from iphone`) — ~140GB of archives, see TODO #20. T5 holds copies of the same
folders, so they are not single-copy, but **do not wipe T7 until they are imported**.

**Cloud backup (rclone → Cloudflare R2), nightly 5am:**
- Docker service configs, obsidian vault, Calibre books, DB dumps → R2 `peciulevicius-backups`
- Script: `~/.dotfiles/services/rclone/rclone-backup.sh`
- ~1.3GB total (critical-only; photos/audiobooks excluded from R2)

**Local backup (rsync NAS → external drive), MANUAL — no cron:**
- `~/.dotfiles/scripts/backup/backup-external.sh /Volumes/T7` (or `/Volumes/Backup` for T5)
- Covers: Immich originals + transcoded video, **database dumps**, audiobooks, Calibre books
- Skips: media (movies/TV — too large, re-downloadable), Immich thumbnails (regenerable)
- Both drives verified 1:1 against the NAS on 2026-09-05

**If the NAS dies:** photos + books + audiobooks + DB dumps on T7 and T5. Configs on R2.
Re-download media.
**If a drive dies:** re-run the script against a replacement.
**If the Mac mini dies:** all data safe on the NAS. Reinstall macOS, clone dotfiles,
restore configs from R2.

**The gap:** T7 and T5 currently sit in the same room as the NAS, so nothing survives
fire/flood/theft. Moving T5 offsite (the parents' house plan) is what makes this 3-2-1.

---

## Quick reference

| Service | Container path | Mac mini path |
|---|---|---|
| Radarr/Sonarr media | `/media` | `/Volumes/media` |
| Radarr movies | `/media/movies` | `/Volumes/media/movies` |
| Sonarr TV | `/media/tv` | `/Volumes/media/tv` |
| Transmission downloads | `/downloads` | `/Volumes/media/downloads` |
| Audiobookshelf | `/audiobooks` | `/Volumes/audiobooks` |
| Calibre library | `/books` | `/Volumes/books` |
| Immich photos | `/usr/src/app/upload` | `/Volumes/immich/upload` |
| Immich thumbnails | `/usr/src/app/upload/thumbs` | `~/services/immich/data/thumbs` (internal SSD) |
| Immich DB | `/var/lib/postgresql/data` | `~/services/immich/data/postgres` (internal SSD) |

All `/Volumes/<share>` paths are NAS SMB mounts — see `docs/NAS.md`.
