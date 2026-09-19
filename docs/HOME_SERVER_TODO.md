# Home Server — TODO

Outstanding work only. Finished items live in
[HOME_SERVER_CHANGELOG.md](HOME_SERVER_CHANGELOG.md).

Grouped by "what happens if I ignore this", not by number.

---

## ▶ Start here — what's next

Last worked: **2026-09-19** on the Mac mini. What got done that day is in
[HOME_SERVER_CHANGELOG.md](HOME_SERVER_CHANGELOG.md#2026-09-19--verification-backups-couchdb).
Only outstanding work is listed here.

**1. 🔴 Regenerate the Gmail app password — nothing else can fix this**

The Kindle sync has been failing every hour since early July: the app password
in `pkm/config.py` is no longer valid. The Scribe → Obsidian pipeline is dead
until this is done, and the whole notes plan sits on it.

- [ ] Google Account → Security → App passwords → generate a new one
- [ ] Put it in `pkm/config.py` as `EMAIL_PASSWORD`
- [ ] Test: `~/.dotfiles/pkm/.venv/bin/python3 ~/.dotfiles/pkm/kindle_sync.py`

It will now shout on Discord if it breaks again — but only once the webhook is
configured, which is step 2.

**2. Configure the Discord webhook for job alerts (~2 min)**

The cron jobs now notify on failure and recovery, but the webhook file doesn't
exist yet, so they are currently silent no-ops.

- [ ] Uptime Kuma → Settings → Notifications → the Discord entry → copy the URL
- [ ] `mkdir -p ~/.config/homelab && chmod 600` a `notify.env` there containing
      `DISCORD_WEBHOOK_URL=...` — see [scripts/cron/README.md](../scripts/cron/README.md)

**3. Finish Obsidian LiveSync — the server side is done**

CouchDB is up at `https://couchdb.peciulevicius.com` with the `obsidian`
database created. Only the plugin is left.

- [ ] Install **Self-hosted LiveSync** on each device, turn on E2E encryption,
      same passphrase everywhere
- [ ] ⚠️ **Start on the Mac mini** — it holds the real vault. Let it finish
      uploading before connecting the iPhone. LiveSync asks which side wins and
      answering with an empty device wipes the vault. Snapshot is in
      `~/backups/vault-snapshots/` if it goes wrong.

**4. Two-minute jobs that prevent real loss** — see the section below

- Tailscale key expiry (it silently dropped the tailnet once already)
- ⚠️ T5 offsite: iCloud is cancelled, so there is no cloud copy of the photos —
  only the NAS and two drives in the same room

**5. Odysseus** — [guides/SELF_HOSTED_AI.md](guides/SELF_HOSTED_AI.md).
Needs an Anthropic or OpenRouter API key from you, and a Cloudflare Access
policy. ⚠️ **Port 7000 is taken** by macOS AirPlay Receiver — map it elsewhere
or turn AirPlay Receiver off.

**Not Mac mini work — do on the phone when convenient:**
⚠️ **Google Authenticator → Ente Auth.** Highest-risk item in the whole
de-Google effort: its TOTP seeds sync to the account being left.

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
- [x] ~~Consider dropping iCloud~~ — already cancelled (early 2026). This makes
      getting T5 offsite *more* urgent, not less: there is no cloud copy of the
      photos any more, only the NAS and two drives in the same room.

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

### Linkwarden — it's set up; the friction is Brave Shields

**Linkwarden is the keeper, not the thing being scrapped.** Karakeep was the
experiment, it was tried as a replacement and reverted — and its containers are
now stopped. Linkwarden stays on port 3005 / `links.peciulevicius.com`.

The changelog says the extension is installed and **621 bookmarks are imported**,
so the old "install the extension / import bookmarks" items here were stale.

What's actually wrong: save-a-tab-and-it-syncs *is* what the extension does, but
**Brave needs Shields disabled for the site** or it silently fails — which makes
it feel like it doesn't work. That's the thing to fix.

- [ ] Brave → `links.peciulevicius.com` → Shields **down** for this site, then
      save a tab and confirm it appears on the phone PWA
- [ ] If it still feels like friction after that, the honest comparison is
      against browser-native sync, not against another self-hosted tool

Linkwarden archives links; the **Obsidian Web Clipper** captures page *content*.
They are complements, not competitors — see the Notes section.

### Octopus Deploy — researched, ruled out for now

Wanted as a day-job-mirroring .NET practice rig. **Not building it on the Mac
mini**: its SQL Server dependency needs ~3-4GB and the host is already swapping
3GB of 4GB with ~4.1GiB of Docker VM headroom left. Full research, including the
licence check, compose sketch and the unrecoverable master-key step, is in
[guides/OCTOPUS_DEPLOY.md](guides/OCTOPUS_DEPLOY.md) so it doesn't get
re-researched. Revisit only if it gets its own machine.

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

- [ ] **Stand up CouchDB + Self-hosted LiveSync** — self-hosted Obsidian sync,
      works on iOS/Android/desktop, real-time, E2E, no subscription, no Apple
      dependency. `services/couchdb/`, data on the **internal SSD** (database —
      never SMB), exposed at `couchdb.peciulevicius.com` via the existing tunnel
      (**mobile Obsidian requires HTTPS**), behind Cloudflare Access.
      ⚠️ Back up the vault first — LiveSync's initial sync picks a source of
      truth and can overwrite. Fallback if CouchDB is unwanted: Remotely Save →
      Nextcloud WebDAV or R2.
      ❌ Not iCloud (Apple dependency, and breaks on a Pixel), ❌ not Obsidian
      Sync (~€4/mo subscription).
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
- [ ] **Kindle is a target device too, not just phone + PC.** Full plan in
      [guides/BOOKS.md](guides/BOOKS.md). Goal: read your own Calibre-Web EPUBs
      on the Scribe **without Amazon in the middle**. Stock Kindle can't read
      EPUB — Send to Kindle converts server-side, so every LazyLibrarian
      download would round-trip through Amazon. KOReader reads EPUB natively via
      Calibre-Web's OPDS feed.
- [ ] **Jailbreak decision: yes.** Blocker is **software, not warranty** —
      Vera's Scribe support reads as pending, no fixed date. (Warranty is
      **2 years in the EU**, to ~Oct 2027, not 1 — and the jailbreak is
      reversible via `renametobin` Restore → factory reset → update, so a
      warranty claim stays possible.)
- [ ] Watch kindlemodding.org → when Scribe lands, run the Jailbreaking Wizard
      → `;kpm install koreader` → point KOReader at `books.peciulevicius.com` OPDS
- [ ] **Wi-Fi stays on afterwards** — `renametobin` blocks OTA updates; verify
      with the "Check OTA Status" scriptlet. Airplane mode is only for *before*
      jailbreaking. Wi-Fi is required for notes: *Share → Searchable PDF* routes
      through Amazon to email, which is what feeds `kindle_sync.py`.
- [ ] **Books do not auto-transfer** — OPDS is pull (open KOReader, tap to
      download). Optional later: `scripts/books/push-to-kindle.sh` to `scp` new
      EPUBs over SSH when the Scribe is reachable. Try OPDS first.
- [ ] **Keep Amazon's stock software for handwriting.** KOReader's Scribe stylus
      PR was merged March 2026 then reverted as unstable;
      `pencil-handwriting.koplugin` is early-stage. Jailbreak is additive, so
      run both: KOReader for reading, stock for notes + OCR export.
- [ ] Check whether `readarr` is still running — the pipeline uses
      LazyLibrarian, and Readarr was archived upstream (same reconciliation
      issue as karakeep/actual-budget)
- [ ] **Freeze the Kindle Scribe firmware at 5.19.6** — fill its storage or keep
      Wi-Fi off. Vera's Scribe port targets `<=5.19.6`; updating past it may
      strand the device. Confirm actual support via the Jailbreaking Wizard —
      Scribe support reads as pending, not shipped.
- [ ] Habit: **Share → Searchable PDF** after each meeting. Amazon's handwriting
      OCR is what makes the notes greppable once they land in the vault.
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
- [ ] **Now (free):** enable **Advanced Data Protection** on iCloud — works on
      the free tier, no iCloud+ needed — delete
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

**Hardware and migration history** — arrival, RAID build, SMB shares, the T7 →
NAS copy and the switch of every service to NAS paths — is in
[HOME_SERVER_CHANGELOG.md](HOME_SERVER_CHANGELOG.md#nas--arrival-and-migration-jul-aug-2026).
Layout and paths are in [HOME_SERVER_REFERENCE.md](HOME_SERVER_REFERENCE.md).

**Still to do (pre-drives config that never got finished):**
- [ ] Enable SSH (Control Panel → Terminal; set "Shut down automatically" to never)
- [ ] Enable "Auto power-on when power is supplied" + WOL (Hardware & Power → Power)
- [ ] Set up 2FA on admin account (Security → Account security)
- [ ] Enable DoS protection (Security → Security)
- [ ] Change custom domain name from "localhost" to "nas" (Device Connection → LAN)

**Remaining follow-ups:**
- [ ] Delete stale `immich/postgres` folder on NAS share (460MB dead copy — via Files app)
- [ ] Verify a NAS-sourced external backup by hand — the nightly T5/T7 cron was
      removed 2026-09-05 (the drives aren't always plugged in, so it failed every
      night). rclone → R2 at 5am is the only automated leg now.
- [ ] Decide: delete stale `/Volumes/T7/docker/` (53G old Docker VM copy)
- [ ] T5 future plan: reload with full photo/video collection, store at parents' home as offsite family copy
- [ ] Verify drive sleep works (configured: 20 min idle)
- [ ] Optional: Bonjour + Time Machine target, NAS rsync service
- [ ] Mac mini auto-login (System Settings → Users & Groups) — without it, after a power outage neither Docker, cloudflared, nor NAS mounts come up
- [ ] Watch streaming: 4K high-bitrate files may exceed the extender's ~100Mbps ceiling — if Jellyfin buffers, wire the NAS/Mac path properly

**Hardware reference:** 4-bay, RK3588C ARM 8-core, 8GB RAM (keep NAS storage-only — no heavy Docker workloads; compute stays on Mac mini), 2.5GbE port. Purchase total ~€1,060 (NAS €340 + drives €690 + switch/cables €30).

---
