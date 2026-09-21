# Home Server — TODO

Outstanding work only. Finished items live in
[HOME_SERVER_CHANGELOG.md](HOME_SERVER_CHANGELOG.md).

Grouped by "what happens if I ignore this", not by number.

---

## ▶ Start here — do these in this order

Last worked: **2026-09-19**. Finished work is in
[HOME_SERVER_CHANGELOG.md](HOME_SERVER_CHANGELOG.md) (see the 2026-09-19 entry).
The order below matters — each step unblocks the next.

### ✅ Done 2026-09-19 — Gmail app password, and the custom email address

Both cleared. Kindle sync is alive after ~73 days; Uptime Kuma SMTP and
Calibre-Web Send-to-Kindle were re-pointed at the new app password and tested
working. Cloudflare Email Routing is live on `peciulevicius.com` with
`contact@`, `hello@`, `dziugas@` and a **catch-all** — verified by delivering to
an address that was never created.

⚠️ Still true: Email Routing **receives only**. Replying goes out as Gmail until
there is a real mailbox, so this is the argument for doing Purelymail sooner
rather than later — see [guides/DEGOOGLE.md](guides/DEGOOGLE.md).

### 0. 📌 Quick wins left over from 2026-09-20

- [ ] **Sync the Kindle wallpapers.** Six are ready in `wallpapers/kindle/`
      (two rejects dropped, all renamed descriptively). Run
      `~/.dotfiles/scripts/kindle/sync.sh`, then the one line it prints in
      kTerm. It mirrors, so it also clears the ten stale `lockscreen-*.png`
      left from the earlier numbered attempt.
- [x] ~~Storyteller alignment~~ — **done 2026-09-20/21.** 23 chapters aligned,
      6 unaligned (all front/back matter). The 733MB read-along EPUB is in
      Calibre as book 41; working files cleared and the container powered down.
- [x] ~~Confirm KOReader highlights the aligned book~~ — **works, 2026-09-21.**
      Self-hosted Whispersync is running end to end: Storyteller alignment →
      Calibre-Web → OPDS → KOReader, with word highlighting during real
      narration.
- [ ] ⚠️ **Playback speed does nothing on Kindle** — upstream limitation, the
      Kindle audio backends implement no speed control and the call fails
      silently. Workaround if it matters: `ffmpeg -filter:a atempo=1.5` the M4B
      *before* aligning, so the read-along is natively faster. Needs
      `brew install ffmpeg` and a re-align per speed.
- [ ] **Clear stuck duplicate files in the Calibre library from the NAS side.**
      Two failed Calibre-Web renames left a 733MB `.smbdelete` orphan plus a
      733MB duplicate EPUB in
      `/Volumes/books/David Goggins/Can't Hurt Me_ ... (41)/`, and ~1.5GB of
      `.smbdelete` files at the library root. Stopping every container that
      touches the share **and** unmounting/remounting it did **not** release
      them — the lock is held by the NAS's SMB server, so they have to go via
      the **UGOS file manager** (or an SSH session on the NAS).
      ~2.3GB. Not urgent: all excluded from the R2 backup.
- [ ] **Tag the aligned book** `read-along` in Calibre-Web so it is
      distinguishable over OPDS. ⚠️ Tag it — do **not** rename it; see the
      rename warning in [HOME_SERVER_REFERENCE.md](HOME_SERVER_REFERENCE.md).
- [ ] Verify Kindle OTA is blocked ("Check OTA Status" scriptlet)
- [ ] Stock app → **Share → Searchable PDF** → confirm the mail arrives. This
      is the Obsidian pipeline, and it is the thing most likely to have broken
      quietly during all the Kindle work.

### 1. 🔑 Credentials into Bitwarden — **start here tomorrow**

Full checklist, no secrets: **[CREDENTIAL_MIGRATION.md](CREDENTIAL_MIGRATION.md)**.
4 of ~18 services done.

- [ ] Transcribe the three pending passwords from `~/credentials-import.md`
      (CouchDB, Transmission, Pi-hole) plus the Gmail app password, then
      `rm` that file
- [ ] Work down the checklist: generate in Bitwarden → set in the app → save,
      with the **URL** on each entry so autofill matches
- [ ] Use the same pass to move email-based logins onto per-service aliases
      (`immich@`, `linkwarden@`, …) — the catch-all means none need creating
      first, and a spammed alias tells you exactly who leaked it

### 2. 🔗 Finish Obsidian LiveSync — the server side is done

CouchDB is up at `https://couchdb.peciulevicius.com`, `obsidian` database
created, anonymous requests 401 on every path except `/_up`.

- [ ] Install **Self-hosted LiveSync** on each device, E2E encryption on, same
      passphrase everywhere
- [ ] ⚠️ **Start on the Mac mini** — it holds the real vault. Let it finish
      uploading before connecting the iPhone. LiveSync asks which side wins and
      answering with an empty device wipes the vault. Snapshot:
      `~/backups/vault-snapshots/`.

### 3. 🛡️ Two-minute jobs that prevent real loss

- [ ] Tailscale key expiry (it silently dropped the tailnet once already)
- [ ] ⚠️ T5 offsite — iCloud is cancelled, so there is no cloud copy of the
      photos, only the NAS and two drives in the same room

### 4. 🤖 Odysseus

[guides/SELF_HOSTED_AI.md](guides/SELF_HOSTED_AI.md). Needs an Anthropic or
OpenRouter API key and a Cloudflare Access policy. ⚠️ **Port 7000 is taken** by
macOS AirPlay Receiver — map it elsewhere or turn AirPlay Receiver off.

### Not Mac mini work — on the phone, whenever

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

### Get every credential into Vaultwarden, one per service

**The rule: one unique generated password per service, master copy in
Vaultwarden.** The working checklist, with a row per service, is
`~/credentials-import.md` (outside this repo — this one is public).

⚠️ This matters more than it looks: `rclone-backup.sh` **excludes every `.env`**
from the R2 backup. A restore from R2 gives you configs with no secrets.
**Vaultwarden is the only copy.**

**Decision 2026-09-19 — username `peciulevicius` everywhere, and two kinds of
password:** one memorised passphrase for the Vaultwarden master, generated
random for every service.

✅ Already done: **Vaultwarden master password**, **CouchDB**, **Transmission**
and **Pi-hole** — the only services whose password is a runtime env var. All
32/28-char random, verified working, old credentials rejected.

🔴 **Pi-hole's old password was 5 characters and contained a common word, on a
publicly exposed panel that controls network DNS.** Rotated 2026-09-19; treat
the old one as exposed.

⚠️ **Everything else cannot be changed from a file.** Init-only env vars are
inert once the account exists, and app accounts are salted hashes. Four services
have CLI resets (Nextcloud, Paperless, FreshRSS, Grafana); the rest are UI only.
Commands and the full explanation are in `~/credentials-import.md`.

📋 **Worksheet with the real values: `~/credentials-import.md`** — deliberately
outside this repo, which is public.

⚠️ **`ADMIN_USER` / `GRAFANA_USER` in the other `.env` files are inert** — they
only apply at first init, so those renames must happen in each app's own UI.

- [ ] ⚠️ **Retire the old reused personal password.** It was in use across many
      services; treat any account still on it as compromised-by-reuse until
      rotated. The string is deliberately not recorded in this repo.
- [ ] Work down the inventory in `~/credentials-import.md`, one service at a
      time: generate in Vaultwarden **first** (with the URL set so autofill
      works), then change it in the app, then confirm the app still works
- [ ] ⚠️ Several services use **the Gmail address as the login itself** —
      Vaultwarden, Immich, Linkwarden, Mealie. Those logins have to change at
      the email migration, not just the forwarding.
- [ ] Gmail app password → Vaultwarden. Used in **three** places, not one —
      rotating it breaks all three
- [ ] Bitwarden Vault Health report → clear the remaining reused-password flags

⚠️ Leave internal database roles alone (`DB_USERNAME=postgres` and friends).
Change the app's *login*, not the database role.

This is a walk, not a single sitting.

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

### Move Calibre's metadata.db off the SMB share

`/Volumes/books/metadata.db` is SQLite on an SMB mount — the thing this setup's
own rule says never to do (same reason Immich's Postgres lives on the internal
SSD). It has not corrupted yet; the 2026-09-19 "malformed" error turned out to
be a stale bind mount, not the file. But SQLite's locking is not reliable over
SMB and Calibre *writes* this database.

- [ ] Decide the layout: book files can stay on the NAS, but the library
      metadata should live on the internal SSD
- [ ] Calibre and Calibre-Web both open the same library, so they have to agree
      on the new path — check whether Calibre-Web's `--dbpath`-style split works
      before moving anything
- [ ] Back up `metadata.db` first; a copy is already at
      `~/backups/calibre-repair/`

### Internal SSD is filling — 29GB free of 228GB

Docker dominates and nothing here is on the NAS by mistake; it is simply a lot
of containers. Measured 2026-09-21:

| What | Size |
|---|---|
| Docker (`~/Library/Containers/com.docker.docker`) | **40GB** |
| `~/services` (service data) | 6.8GB |
| `~/.Trash` | 2.7GB |
| `~/Downloads` | 1.1GB |
| `~/backups` (DB dumps) | 601MB |

Cheap wins first, in order:

- [ ] **Empty the Trash** — 2.7GB, mostly the Storyteller working files and the
      removed karakeep/readarr data
- [ ] **`docker system prune -a`** — 3.7GB of reclaimable images. ⚠️ Removes
      images not backing a running container, so anything stopped (Storyteller)
      re-pulls on next start.
- [ ] Clear `~/Downloads` (1.1GB) — the Kindle plugin zips are re-downloadable
- [ ] Consider whether old DB dumps in `~/backups` need 30 days of retention

⚠️ **Do not move service data to the NAS to save space.** Databases must not
live on SMB — that rule is why Immich's Postgres is on the SSD, and the Calibre
library breaking repeatedly on 2026-09-21 is what happens when it is ignored.
Media belongs on the NAS; databases and app state belong on the SSD.

### ⚠️ Move the Calibre library off SMB onto the SSD

The root cause of a whole day of failures: `metadata.db` is **SQLite on an SMB
share**, which this setup's own rule forbids. Every symptom traced back to it —
`disk I/O error` opening a shelf, `Device or resource busy` renaming a book,
`.smbdelete` duplicate files, and `database disk image is malformed` from a
stale mount.

**It is affordable now:** the whole library is **1.1GB** and the SSD has 29GB
free.

- [ ] Stop `calibre`, `calibre-web`, `lazylibrarian`
- [ ] Copy `/Volumes/books` → `~/services/calibre/library` (internal SSD)
- [ ] Repoint the `BOOKS_DIR` bind mount in all three compose files
- [ ] Update `rclone-backup.sh`, which currently syncs `/Volumes/books` to R2
- [ ] Decide where the large read-along EPUBs live — they are the only big
      files, and they could stay on the NAS as a separate Calibre library
- [ ] Verify OPDS still serves to KOReader afterwards

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
- [x] ~~**Jailbreak the Scribe**~~ — **done 2026-09-20 with Vera.** Support
      landed earlier than expected; `;kpm` is available on the device.
- [ ] **Post-jailbreak housekeeping** — delete leftover `.bin` update files from
      the Kindle's root plus the jailbreak's filler files; a stray `.bin` can
      undo the jailbreak
- [ ] **Verify OTA is blocked** with the "Check OTA Status" scriptlet. Modern
      `hdnext`-stack jailbreaks block updates automatically — verify, don't
      assume. Then normal Wi-Fi is fine, and Wi-Fi is *required* for notes:
      *Share → Searchable PDF* routes through Amazon to email, which feeds
      `kindle_sync.py`.
- [x] ~~**`;kpm install koreader`** + OPDS catalog pointed at
      `https://books.peciulevicius.com/opds`~~ — **done 2026-09-20.** The whole
      point of the jailbreak is now working: own library, no Amazon round trip.
- [ ] In KOReader, set a **HOME directory** (long-press `documents/` or a new
      `books/` folder) and turn off *Show unsupported files* — the browser opens
      on the storage root and shows firmware internals otherwise
- [ ] **`;kpm install usbnetlite`** — SSH over USB, which is what unblocks the
      `scp` push script below. Do OPDS first; this is the upgrade.
- [x] ~~HotfixUpdater~~ — **not needed on Vera**, which blocks OTA itself. The
      universal hotfix belongs to the legacy jailbreak chain.
- [x] ~~Storyteller for true read-along~~ — **deployed 2026-09-20** as
      `services/storyteller/` on port 8087, `restart: "no"` so it stays off.
      Audiobookshelf playback in KOReader does **not** highlight; real narration
      needs EPUB 3 Media Overlays, which Storyteller produces by forced
      alignment.
- [ ] **Align a first book and confirm the Kindle highlights it.** Upload an
      EPUB + its audiobook at `localhost:8087`, drop the output into
      Calibre-Web, open it over OPDS. ⚠️ `docker compose down` afterwards — it
      wants ~4GB, the same headroom as Odysseus, on a host already swapping.
      ⚠️ Media Overlay support in `audiobook.koplugin` is still *work in
      progress*, so verify before aligning a shelf full of books.
- [ ] **Custom lockscreens** — ⚠️ the KPM route fails with *"failed to install
      packages"*; use the zip instead. It ships `documents/Custom Screensaver.sh`,
      which is a Vera scriptlet, so it needs no KUAL. Serve
      `custom-screensaver-0.3.0-kindlehf.zip` (already in
      `~/Downloads/kindle-plugins`) with `scripts/kindle/sync.sh`,
      `wget` + `unzip` it at `/mnt/us`, then PNGs at **1860 × 2480** into
      `/mnt/us/screensavers/`.
- [ ] **KindleFetch** (KOReader plugin version) — grab a book from Anna's
      Archive with no computer nearby. A shortcut beside the LazyLibrarian →
      Calibre-Web library, not a replacement.
- [x] ~~Consider LARK for audiobooks~~ — **ruled out 2026-09-20**: supports
      firmware <5.19 and the Scribe is on 5.19.6, has no read-along/Whispersync,
      and plays local files only so it cannot replace Audiobookshelf's streaming
      and cross-device progress. Revisit if it gains 5.19+ support.
- [ ] **Read-aloud with word highlighting** — what LARK was wanted for actually
      exists as [audiobook.koplugin](https://github.com/stradichenko/audiobook.koplugin):
      TTS, synchronised highlighting, auto page turns, Bluetooth, fully offline.
      Copy into `koreader/plugins/`. Use the Piper voice.
- [ ] ⚠️ **If installing `blockamazon`, test the Searchable PDF export straight
      after.** It blocks Amazon domains via `/etc/hosts` and does not document
      which — and the handwriting OCR export routes through Amazon to email,
      which is what feeds `kindle_sync.py`. Reversible via KUAL's unblock.

📘 Full step-by-step: **[guides/KINDLE_SETUP.md](guides/KINDLE_SETUP.md)**
- [ ] **Books do not auto-transfer** — OPDS is pull (open KOReader, tap to
      download). Optional later: `scripts/kindle/sync.sh --dir` to `scp` new
      EPUBs over SSH when the Scribe is reachable. Try OPDS first.
- [ ] **Keep Amazon's stock software for handwriting.** KOReader's Scribe stylus
      PR was merged March 2026 then reverted as unstable;
      `pencil-handwriting.koplugin` is early-stage. Jailbreak is additive, so
      run both: KOReader for reading, stock for notes + OCR export.
- [x] ~~Check whether `readarr` is still running~~ — checked 2026-09-19 and
      **removed**: 0 authors, 0 books, 0 grab history. It had never acquired
      anything. ⚠️ But LazyLibrarian shows **0 books downloaded** too (47 known,
      1 author), so the book pipeline is configured, not proven. Confirm it can
      actually fetch something before relying on it.
- [x] ~~**Freeze firmware at 5.19.6**~~ — moot now that the jailbreak is in and
      blocking OTA. Keep it that way: never let the device take a firmware
      update, or the jailbreak goes with it.
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
[HOME_SERVER_CHANGELOG.md](HOME_SERVER_CHANGELOG.md) (see the NAS arrival/migration entry).
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
