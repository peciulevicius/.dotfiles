# Home Server — Completed Work

Archive of finished items, moved out of `HOME_SERVER_TODO.md` on 2026-09-08 so
that file holds only outstanding work. Kept because the *why* behind a past fix
is often what you need when something similar breaks again.

Newest first-ish; dates are when the work was finished.

---

## 2026-09-21 — Odysseus deployed, read-along verified, Calibre repaired

### Odysseus running on 7001

Four containers — odysseus, chromadb, searxng, ntfy — with the local model
served by **native Homebrew Ollama**, not a container. Verified from inside the
container: it sees `qwen3:4b` over `host.docker.internal:11434`.

Three things this setup needed that upstream's defaults don't give you:

- **Port 7001, not 7000** — macOS AirPlay Receiver owns 7000, which upstream's
  own `.env.example` warns about.
- **`OLLAMA_HOST=0.0.0.0:11434`** — Ollama binds loopback by default, so the
  container cannot reach it. This is the sort of thing that reads as "the model
  isn't working" rather than a networking setting.
- **A compose override dropping SearXNG's host port** — upstream publishes
  `127.0.0.1:8080`, which collides with Nextcloud. Odysseus talks to it over
  the compose network, so the mapping was never needed. Kept in
  `docker-compose.override.yml` so `git pull` cannot clobber it.

**Tailscale-only, deliberately.** It holds health and finance history and its
agent executes code; the iPhone is already on the tailnet, so a public hostname
would add exposure and buy nothing.

Measured: ~960MB for the four containers, 686MB image, host headroom down to
**2.11 GiB**. SearXNG is the first to drop if that bites.

⚠️ **Cookbook caveat worth remembering:** upstream's compose says *"Inside
Docker, 'Local' means the Odysseus container."* Docker on macOS has no GPU
passthrough, so anything Cookbook serves "locally" is CPU-only and its hardware
scan measures the container. That is almost certainly the real cause of the
2026 entry below recorded as *"Ollama + Open WebUI — removed, not enough RAM."*

### Decided against OpenRouter

The obvious choice for multi-model access, rejected on research: 5.5% top-up
fee, **1-year credit expiry**, 24-hour refund window buried in fine print,
Discord-only support, a reported account compromise with ten card charges in 30
minutes, some providers silently serving quantized models — and its $113M
Series B was led by **CapitalG, Alphabet's investment arm**, which is a poor
fit in the middle of a de-Googling project. One direct Anthropic key covers the
need; Odysseus supports multiple backends natively if that changes.

### Read-along confirmed working

The whole books chain works end to end: Storyteller alignment → Calibre-Web →
OPDS → KOReader, highlighting words during real narration. Self-hosted
Whispersync, with Amazon nowhere in it.

⚠️ Playback **speed** does nothing on Kindle — upstream implements `setSpeed`
for mpv, MPlayer, ffmpeg-pipe and generic GStreamer but not the Kindle
backends, and the call sits in a `pcall` so it fails silently. Workaround is
`ffmpeg -filter:a atempo=` on the M4B *before* aligning.

### Calibre library repaired twice, and the cause named

Renaming a book in Calibre-Web corrupted the library entry two separate times:
it renames the folder, copies the 769MB EPUB, fails to delete the original
because SMB reports it busy, then rolls back the database without undoing the
folder rename. Repaired by renaming the folder back to the path `metadata.db`
expected.

Root cause is `metadata.db` being **SQLite on an SMB share** — the same rule
that keeps Immich's Postgres on the internal SSD. `disk I/O error` opening a
shelf, `Device or resource busy` on renames, and `.smbdelete` duplicates are all
the same problem. Moving the 1.1GB library to the SSD is now a TODO.

## 2026-09-20 — Kindle Scribe jailbroken, KOReader + read-along

Done with **Vera** on firmware 5.19.6. Earlier than `guides/BOOKS.md` predicted —
that guide was written while Vera's Scribe port still read as *pending*, and the
plan had been to wait and watch kindlemodding.org.

`;kpm` is available on the device, so the rest of the books plan is now live
work rather than a waiting game: KOReader over Calibre-Web's OPDS feed, custom
screensavers, and UsbNetLite for the SSH push script.

Verified while planning it: `https://books.peciulevicius.com/opds` answers with
**HTTP Basic auth**, which KOReader's OPDS client speaks natively, and it is not
behind Cloudflare Access — an Access challenge would block the reader the same
way it blocks the Obsidian LiveSync plugin. So the intended setup works as
designed.

The recommendations, with reasoning about what to skip, are in
[guides/BOOKS.md](guides/BOOKS.md#what-to-install-after-the-jailbreak).

---

### Storyteller deployed for read-along books

`services/storyteller/` on port 8087 (8001 is Vaultwarden). Verified running —
HTTP 200, **340 MB idle** — then stopped again, which is how it is meant to
live: `restart: "no"`, brought up only to align a book.

It exists because KOReader's audiobook plugin plays Audiobookshelf audiobooks
but **cannot highlight text during real narration** — an audio file has no map
from seconds to words. Storyteller transcribes the audio, force-aligns it
against the ebook, and emits an EPUB 3 with Media Overlays, which does.

⚠️ The ~4GB figure is for alignment, not idle, and that is the same headroom
Odysseus is earmarked for on a host already swapping 4.1GB. Batch use only.

⚠️ Media Overlay support in `audiobook.koplugin` is still *work in progress*, so
align one book and confirm the Kindle highlights it before doing a shelf.

Data on the internal SSD (SQLite), excluded from R2 — the audio is bulky and
regenerable; the aligned EPUBs belong in Calibre-Web, which is backed up.

## 2026-09-19 — Verification, backups, CouchDB

A "just verify what's running" session that turned up two silent failures.

### Fixed: two of four database dumps had never worked

`linkwarden_db` was dumped as role `linkwarden` (it is `postgres`), and
`nextcloud_db`'s `mariadb-dump` ran with no password while `MYSQL_ROOT_PASSWORD`
is set. Only immich and paperless had ever landed in `~/backups/`. The script
also exited 0 regardless, so nothing ever reported it.

Fixed, and `backup-databases.sh` now counts errors and exits non-zero. All four
verified: immich 129M, paperless 432K, linkwarden 1.7M, nextcloud 3.5M. The
MariaDB password is read from the container's own env, so it stays out of the repo.

The earlier Aug 16 + 23 gap did **not** recur — Aug 30, Sep 6, Sep 13 all landed.

### Found, not fixed: the Kindle sync has been dead since early July

~1,763 consecutive hourly failures with `[AUTHENTICATIONFAILED] Invalid
credentials` — the Gmail app password in `pkm/config.py` is no longer valid.
Needs a new app password generated by hand; still outstanding.

### Added: Discord alerts for cron jobs

`scripts/utils/run-with-notify.sh` wraps each job and posts to the same Discord
webhook Uptime Kuma uses, on **transitions** (ok→fail, fail→ok) rather than
every run, re-nagging daily while still broken. `scripts/cron/crontab` is now
the authoritative copy of the schedule, which previously lived only in the live
crontab.

⚠️ Learned the hard way: **`crontab <file>` silently installs an empty crontab**
on macOS when the file is outside home — exits 0, wipes everything. Pipe via
stdin and always `crontab -l` to verify.

### Cleaned up: karakeep and actual-budget removed for real

Containers stopped, images deleted (karakeep 2.1GB, alpine-chrome 958MB,
meilisearch 234MB, actual-budget 548MB), `services/karakeep/` and
`services/actual-budget/` deleted from the repo, and both dropped from
`setup-services.sh` and `services/README.md`. Docker went from 44.78GB to
35.47GB of images. Data directories under `~/services/` are still there.

Also unmounted a duplicate SMB mount: `/Volumes/media-1` was the same NAS share
mounted a second time by IP (`192.168.1.73`) alongside the mDNS mount at
`/Volumes/media`. Nothing referenced it.

### Fixed: the tunnel setup script pointed `links` at the wrong port

`setup-cloudflare-tunnel.sh` mapped `links.peciulevicius.com` to **3006
(Karakeep)**, but Linkwarden is on **3005** — so re-running it on a fresh
machine would have broken the bookmark manager's URL. Corrected, and
`couchdb` → 5984 added so a rebuild recreates the LiveSync hostname too.

### Added: Discord webhook configured, alerts verified live

`~/.config/homelab/notify.env` created with the same webhook Uptime Kuma uses.
Test post returned HTTP 204. Cron job failures now actually reach Discord.

### Tried and failed: the Gmail account password does not work for IMAP

Filling `EMAIL_PASSWORD` with the Google **account** password was rejected with
`AUTHENTICATIONFAILED`. Gmail IMAP requires a **16-character app password** when
2FA is on. The field was cleared rather than left holding an account password in
plaintext. The three places that password is used were mapped — `pkm/config.py`, Uptime Kuma SMTP, Calibre-Web Send-to-Kindle
— because a revoked one breaks all three and only the first one is noisy.

### Removed: Readarr

Checked before removing rather than assuming: **0 authors, 0 books, 0 grab
history** in `readarr.db`. It had never acquired anything, and it is archived
upstream. Container, image (300MB), repo directory and every reference in
`dev-check.sh`, `nas-watchdog.sh`, `NAS.md` and the Calibre compose comments
are gone. LazyLibrarian is the book pipeline.

⚠️ Worth knowing: LazyLibrarian has **0 books downloaded** too (47 known, 1
author). The pipeline is configured, not proven.

Data directories for karakeep (238MB), actual-budget (80KB) and readarr (49MB)
were moved out of `~/services/` to `~/.Trash/homelab-removed-20260919/`.

### Credential policy set, first two services rotated

Username standardised on **`peciulevicius`** (not `admin` — the first username
every automated attack tries). Passwords split into two kinds: one memorised
passphrase for the Vaultwarden master, generated random for everything else,
with a six-word passphrase reserved for the one password actually typed by hand
on a phone (CouchDB in the LiveSync plugin).

Rotated and verified: **Vaultwarden master password** (by hand), **CouchDB**
(`peciulevicius` + 32-char random — old credentials rejected, `obsidian`
database intact, anonymous requests 401 on every path including `/`) and
**Transmission** (`peciulevicius` + 28-char random).

The passphrase idea was dropped the same day: since every password is copied
out of Bitwarden anyway — on the phone too — nothing but the vault master is
ever typed, so there is no reason for a service password to be memorable.
Random everywhere.

Every service was inventoried with the URL to store in the Bitwarden entry, so
autofill matches (this lived in `docs/CREDENTIALS.md`, later folded into the
out-of-repo worksheet `~/credentials-import.md` — see the note below). It also flags that
several logins *are* the Gmail address (Vaultwarden, Immich, Linkwarden,
Mealie), which the email migration has to change inside each app — not just
forward.

⚠️ Discovered while planning it: `ADMIN_USER` / `GRAFANA_USER` in the other
`.env` files are **inert** — they are read only at first initialisation, so the
account already exists in each app's database and editing `.env` changes
nothing. Those renames are UI work; the checklist is in `~/credentials-import.md`.

### Kindle sync restored after ~73 days, and a silent data-loss bug fixed

A new Gmail app password brought it back, set via a throwaway helper that
prompted without echoing so the secret never touched shell history or a
transcript (removed after use; recoverable with
`git show 50c21f9:scripts/setup/set-kindle-password.sh`). Google's
app-passwords page listed **none**, confirming the old one was deleted rather
than expired, so Uptime Kuma's SMTP alerts and Calibre-Web's Send-to-Kindle
broke at the same moment and stayed broken silently.

**Nothing was lost in the outage:** the inbox holds zero Amazon export emails,
so no notebooks were sent during those 73 days. Consistent with the capture
friction the notes guide describes — the Scribe was not being used.

While verifying that, found a real bug. `.processed_ids` stored IMAP **sequence
numbers** (51, 52, 61, 64-68), which are positional and renumber whenever mail
leaves the mailbox. A stored number can therefore match a different email later:
either a new export is silently skipped and its Amazon link expires after 7
days, or an already-imported note is written to the vault twice. Both silent.

Fixed: searches and fetches by UID, and dedupes on the RFC822 **Message-ID**
header. Message-ID is globally unique and travels with the mail, so it survives
the planned move to Purelymail — UIDs would not, as they reset on a UIDVALIDITY
change or provider move. Falls back to a sha256 of `Subject|Date|From` when a
message carries no Message-ID. The 8 stale sequence numbers were dropped, safe
because the inbox contains no Amazon mail to re-import.

### Calibre-Web "database disk image is malformed" — stale bind mounts

Not corruption. `metadata.db` passed `PRAGMA integrity_check` on the host the
whole time. `/books` **inside the container** was returning EBADF: the host had
remounted the SMB share while the container kept running, so its bind mount
still pointed at the dead mount instance, and SQLite reading through that fd
reports the file as malformed.

A scan found **five more containers in the same state** — Jellyfin (movies and
TV), Sonarr, Radarr and Bazarr were all blind to `/media` and had said nothing.
`docker compose restart` re-resolves the bind mount; all twelve NAS-backed
mounts verified healthy afterwards.

The existing `nas-watchdog.sh` could not catch this: it checks that shares are
mounted **on the host** and that containers are **running**, and both were true.
It now also probes from inside each container and restarts any stack whose bind
mount has gone stale, reporting it to Discord.

⚠️ Worth noting the underlying rule this bumps into: `metadata.db` is SQLite
living on an SMB share, which the repo's own guidance says never to do. It
survived this time because the file was only being *read* through a dead fd
rather than written. Moving the Calibre library metadata onto the internal SSD
is the real fix and is now an open TODO.

### Cloudflare Email Routing live, catch-all verified

`peciulevicius.com` now receives mail: `contact@`, `hello@`, `dziugas@` and a
catch-all, all forwarding to Gmail. Verified by delivering to an address that
was never created, which confirms the catch-all is active and that every local
part at the domain reaches the inbox.

Receive-only, though — Cloudflare provides no SMTP, so Gmail's "Send mail as"
cannot send from the custom address. Fine for signups, weak for correspondence,
and the concrete reason to stop deferring Purelymail.

### Docs site build fixed

`mkdocs build --strict` was failing on main. The cause was a link added earlier
that day from `START_HERE.md` to `../scripts/cron/README.md` — outside the docs
tree, so mkdocs cannot resolve it and strict mode turns that warning into a
failure. Now an absolute GitHub URL.

Also removed two brittle anchors into the changelog (em dashes slugify
unpredictably) and fixed three genuinely wrong in-page anchors that had been
broken for readers: `#sonarr--radarr--prowlarr`, `#grafana--prometheus` and
`#setup--update` all use single hyphens once slugified. Verified by running the
exact CI command locally — exit 0, no warnings.

### Security: Pi-hole had a 5-character password, publicly exposed

Auditing the `.env` files turned it up: `PIHOLE_PASSWORD` was 5 characters and
contained a common word, on `pihole.peciulevicius.com` — a public admin panel
that controls DNS for the whole network. Anyone into it could silently redirect
any domain. Rotated to 32-char random and verified DNS still resolves. Treat the
old password as exposed.

Same audit found **Immich's Postgres role still uses the old reused personal
password**. Internal-only, so lower risk, but changing it needs `ALTER USER`
inside the database and the `.env` updated together — left for a deliberate
session. Nextcloud, Paperless, Linkwarden and the Vaultwarden admin token all
checked out as 32–64 char random.

Also found **two Nextcloud accounts**: `peciulevicius`, and a second `admin`
whose display name is confusingly also "peciulevicius".

### Credentials documentation moved out of the repo entirely

`docs/CREDENTIALS.md` was created and then deleted the same day. The reasoning:
a secret-free "map" in the public repo and a separate worksheet holding the real
values meant two files to keep in sync, and the map is not what you reach for
while actually moving passwords into Bitwarden.

Everything — the per-service table with URLs and usernames, the CLI reset
commands, the Gmail app-password procedure, and the known issues — now lives in
**`~/credentials-import.md`**, outside the repo, chmod 600, to be deleted once
the vault is populated.

What stays in the repo is the *rule*, in `.claude/CLAUDE.md`: this repo is
public, so no password, token or webhook URL may ever land in it — not even in
documentation.

### Added: CouchDB for Obsidian LiveSync

`services/couchdb/` — single-node, CORS for `app://obsidian.md`, `obsidian`
database created, data on the internal SSD. Live at
`https://couchdb.peciulevicius.com` (tunnel) and on the tailnet. Anonymous
requests 401. Deliberately **not** behind Cloudflare Access: an interactive
Access policy blocks the plugin, which cannot do a browser login.

⚠️ Do not bind-mount `local.ini` into `/opt/couchdb/etc/local.d/`. The stock
entrypoint chowns everything under `/opt/couchdb` under `set -e`, a macOS bind
mount cannot be chowned, and the container dies **with empty `docker logs`**.
The compose file mounts at `/config` and copies it in.

### Reconciled: karakeep and actual-budget

Both were recorded as removed while still running. Now genuinely stopped and
removed, and karakeep is out of `setup-services.sh`. Data kept in `~/services/`;
`docker compose up -d` restores either. Host went to 39% free.

### Fixed: `~/docker` vs `~/services`

`setup-services.sh` moved staging to `~/services` long ago; `update.sh` and
`dev-check.sh` still looked in `~/docker`. So update.sh had been silently
pulling **zero** images, and dev-check reported services unstaged on a machine
with all of them.

### Decided: Octopus Deploy is not happening here

Ruled out on measured RAM, not principle — its SQL Server dependency wants
~3–4GB against ~4.1GiB of Docker headroom on a host already swapping 3GB.
Research preserved in [guides/OCTOPUS_DEPLOY.md](guides/OCTOPUS_DEPLOY.md) so it
does not get re-proposed.

### Reorganised the docs

Reference material (RAM baseline, drive layout, path mappings) moved out of the
TODO into [HOME_SERVER_REFERENCE.md](HOME_SERVER_REFERENCE.md). The TODO holds
only outstanding work again.

---

## NAS — arrival and migration (Jul–Aug 2026)

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

---

### ~~1. Calibre-Web — finish setup~~ ✅ Done (2026-05-09)

Bookshelves skipped (not needed). Send to Kindle configured via Gmail SMTP — `peciulevicius-scribe@kindle.com` approved and working.


### ~~2. Uptime Kuma notifications~~ ✅ Done (2026-05-09)

Gmail SMTP configured (smtp.gmail.com:465, app password). Email alerts working.


### ~~5. Set up Obsidian vault sync via Syncthing~~ ✅ Done (2026-05-08)

`obsidian-vault` folder shared in Syncthing across Mac mini, MacBook, and iPhone. Real-time sync working.



### ~~8. Bazarr — subtitle provider~~ ✅ Done (2026-05-09)

OpenSubtitles.com configured, Default language profile set with English. Applied to all series and movies. 71 Wanted items queued — downloading automatically.


### ~~13. Show Mac host stats in monitoring~~ ✅ Done (2026-05-07)

Homebrew node_exporter running at port 9100, scraped by Prometheus (`job="mac-host"`). Custom Grafana dashboard (`mac-host.json`) provisioned — shows real 16GB RAM, swap, CPU, disk, network. Glance `server-stats` widget updated to show actual host figures.


### ~~14. Uptime Kuma — rclone backup heartbeat~~ ✅ Done (2026-05-09)

Push monitor added in Uptime Kuma. Heartbeat URL wired into `rclone-backup.sh` — pings up on success, down on failure. R2 backup verified working across all 4 targets.


### 15. ~~Migrate backups from B2 to Cloudflare R2~~ ✅ Done (2026-04-22)

Migrated to Cloudflare R2. Nightly rclone backup running at 5am. R2 at ~1.3GB (critical-only: vaultwarden, paperless docs, obsidian vault, db dumps, calibre books). B2 bucket purged and can be deleted from Backblaze dashboard.


### ~~16. Docker VM resource limits~~ ✅ Done (2026-07-23)

Docker Desktop VM bumped from 7.8GB → 10GB RAM, swap 1GB → 2GB (via
`settings-store.json`). Also enabled AutoStart so Docker launches on login
after a reboot/power cut. All 40 containers verified back up, key services
responding (photos/vault/home/watch/nas all 200).

---


### ~~17. Kindle Scribe → Obsidian automation~~ ✅ Done (2026-05-08)

**Goal:** Automatically sync Kindle Scribe handwritten/typed notes to the Obsidian vault so notes taken on the Scribe appear on all synced devices (MacBook, Mac mini, iPhone, eventually Windows work laptop).

**How it works:** Scribe exports a notebook as TXT via email (Share → Send to email). A script fetches those emails, extracts the text, and routes it to the correct vault folder based on the notebook name.

**Existing infrastructure:**
- Vault structure + templates: `scripts/setup/setup-obsidian.sh`
- Routing rules documented: `docs/guides/NOTES.md` (Kindle Scribe → Obsidian Routing table)
- Syncthing sync: TODO #7

**To build — `pkm/kindle_sync.py` (IMAP-based, provider-agnostic):**

1. Connect to email via IMAP (works with any provider — Gmail now, easy to switch later)
2. Search for unread emails from `do-not-reply@amazon.com` with subject containing "from your Kindle"
3. Parse email subject to extract notebook name
4. Download TXT content from the download link in the email body
5. Route to correct vault folder using keyword matching (same rules as `docs/guides/NOTES.md`)
6. Save as `.md` with frontmatter:
   ```yaml
   ---
   source: Kindle Scribe
   exported: YYYY-MM-DD
   notebook: [original notebook name]
   ---
   ```
7. Filename: `YYYY-MM-DD_NotebookName.md` (append `_v2`, `_v3` if exists — never overwrite)
8. Mark email as read after processing
9. Optional: git commit + push to `obsidian-vault` private repo

**Directory structure:**
```
pkm/
├── kindle_sync.py       # main script
├── config.py            # IMAP creds, vault path, routing rules, toggles
└── requirements.txt     # imaplib is stdlib, requests for download link
```

~~Steps completed (2026-05-08):~~
- Script at `pkm/kindle_sync.py` — IMAP-based, provider-agnostic
- Exports as **Searchable PDF** from Scribe → email → script grabs `.txt` + `.pdf`
- Saves to `📥 Imports/YYYY-MM-DD_HH-MM_name.md` + `.pdf` attachment
- Hourly cron job running, logs to `~/logs/kindle-sync.log`
- Gmail app password configured in `pkm/config.py` (gitignored)


### ~~19. T7 → T5 full backup~~ ✅ Done (2026-07-09)

**What was done:**
- Renamed T5 volume from `ImmichBackup` → `Backup` (`diskutil rename`)
- Created `scripts/backup/backup-t5.sh` — rsync T7 → T5 covering:
  - `/Volumes/T7/immich/upload` → `/Volumes/Backup/immich/upload` (photos)
  - `/Volumes/T7/audiobooks` → `/Volumes/Backup/audiobooks`
  - `/Volumes/T7/calibre-books` → `/Volumes/Backup/calibre-books`
  - Skips `/Volumes/T7/media/` — movies/TV too large for 500GB T5
- Updated cron: 3am daily now runs `backup-t5.sh` (replaces `backup-immich.sh`)
- Fixed `backup-immich.sh` path references from `/Volumes/ImmichBackup` → `/Volumes/Backup`

**Recovery posture as of 2026-09-05** (superseded by the NAS migration — kept for history;
current posture is in the Drive Layout section below):
| If... | Photos | Audiobooks | Books | Services config |
|-------|--------|------------|-------|----------------|
| NAS fails | T7 ✅ + T5 ✅ | T7 ✅ + T5 ✅ | T7 ✅ + T5 ✅ + R2 ✅ | R2 ✅ |
| A drive fails | re-run `backup-external.sh` | same | same | R2 ✅ |
| Fire/theft | ❌ everything is in one room | ❌ | R2 ✅ | R2 ✅ |

**The real remaining gap:** both external drives sit next to the NAS, so nothing survives
fire, flood or theft. Moving T5 offsite is what makes this genuinely 3-2-1.


---

## Done

- [x] ~~Books & audio automation (Jul 2026)~~ — LazyLibrarian fully configured: 4 Torznab indexers via Prowlarr (EBookBay, TPB, Knaben, TorrentDownload), Transmission download client, PostProcessor auto-moves EPUBs to Calibre and MP3s to Audiobookshelf. Click "Wanted" → fully hands-off. See `docs/guides/BOOKS.md` for setup notes and gotchas.

- [x] ~~DeDRM Kindle books → Calibre-Web (Apr 2026)~~ — ~30 books DRM-removed via Windows VM (UTM) + Kindle for PC 2.8.2 + KFXArchiver283, converted to EPUB, uploaded to Calibre-Web
- [x] ~~Calibre-Web — organising books (Apr 2026)~~ — year-end books processed and organised
- [x] ~~Media stack setup~~ — Sonarr/Radarr/Prowlarr/Transmission/Jellyfin fully connected, remote path mapping fixed, Narcos S1-S3 downloaded and playing
- [x] ~~Cloudflare DNS cleanup~~ — deleted stale CNAMEs: `sync`, `portainer`, `ai`, `sonarr`, `radarr`, `prowlarr`, `downloads`
- [x] ~~Cloudflare Access (wildcard)~~ — removed `*.peciulevicius.com` Zero Trust gate; was breaking all native apps (Bitwarden, Immich, etc.). Each service has its own login screen — Access wasn't needed.
- [x] ~~Cloudflare Access (Glance only)~~ — added Access policy on `home.peciulevicius.com` only. GitHub SSO (primary) + email OTP (fallback). 1-month session. Other services unaffected.
- [x] ~~Homarr → Glance migration~~ — replaced Homarr with Glance (YAML config, responsive). Four pages: Home, Feed, Media, Finance.
- [x] ~~Glance internal links~~ — fixed `host.docker.internal` → Tailscale IP (`100.81.171.49`) so all links work from any device (phone, laptop, etc.)
- [~] Actual Budget — was marked removed in favour of Wallet by Budget Bakers, but the `actual-budget` container is **still running** as of 2026-09-05. Either finish removing it or drop the strikethrough; right now the notes and reality disagree.
- [x] ~~Passkey migration~~ — all 5 services (Amazon, Binance, GitHub, Google, PSN) re-registered with Bitwarden
- [~] Karakeep — tried as a Linkwarden replacement and reverted, but `karakeep`, `karakeep-chrome` and `karakeep-meilisearch` are **still running** as of 2026-09-05 (three containers' worth of RAM). Either stop them or drop the strikethrough.
- [x] ~~Linkwarden~~ — restored as primary bookmark manager on port 3005, `links.peciulevicius.com`
- [x] ~~Grafana + Prometheus configured~~ — datasource connected, dashboards imported, password set
- [x] ~~Bazarr connected~~ — Sonarr/Radarr API keys configured, subtitle provider still needed
- [x] ~~Kindle DeDRM → Calibre-Web (Apr 2026)~~ — decrypted 30 Kindle books via KFXArchiver283 (work laptop + Kindle for PC 2.8.2), converted to EPUB in Calibre, synced to Mac mini Calibre-Web. BOOKS folder cleaned (~22GB freed).
- [x] ~~Audible AAX → Audiobookshelf (Apr 2026)~~ — converted 28 AAX audiobooks to M4B via `scripts/convert-audiobooks.sh` (ffmpeg stream copy, chapters preserved). Synced to Mac mini Audiobookshelf.
- [x] ~~B2 backup cleanup (Apr 2026)~~ — deleted Immich photos (7GB), Linkwarden (644MB), Audiobookshelf (890MB) from B2. Down from 9.7GB to 1.2GB. Immich backup disabled (using T5 local). Script fixed: `pipefail` + error counter.
- [x] ~~Cloudflared plist fix~~ — brew service was missing `tunnel run` args, created proper `com.cloudflare.cloudflared.plist` launch agent
- [x] ~~Docker Desktop watchdog~~ — `scripts/utils/docker-watchdog.sh` + launchd agent runs every 5min; restarts Docker Desktop if containers lose internet (Docker proxy dies intermittently)
- [x] ~~NordPass cancelled~~ — subscription ended, passwords in Vaultwarden
- [x] ~~Jellyseerr~~ — media request/discovery UI for Jellyfin (Tailscale-only, port 5055)
- [x] ~~Bazarr~~ — automated subtitle management for Sonarr/Radarr (Tailscale-only, port 6767)
- [x] ~~Grafana + Prometheus~~ — monitoring stack with Node Exporter (Tailscale-only, ports 3000/9090/9100)
- [x] ~~Restart stopped services~~ — all 33 containers confirmed running (all have `restart: unless-stopped`)
- [x] ~~Homarr cleanup~~ — removed containers, images, Docker network, updated setup script
- [x] ~~Tunnel security split~~ — moved Sonarr/Radarr/Prowlarr/Transmission to Tailscale-only, added Portainer to public tunnel
- [x] ~~Mealie~~ — setup complete
- [x] ~~Linkwarden~~ — setup complete, browser extensions installed (Chrome ✅, Brave ⚠️ disable Shields), phone PWA added
- [x] ~~Calibre-Web `metadata_dirtied` bug~~ — fixed: ran `CREATE TABLE` SQL
- [x] ~~Radarr Docker volumes~~ — compose already has `/media` mount
- [x] ~~Pi-hole 403 on root~~ — fixed: lighttpd redirect config mounted
- [x] ~~Transmission credentials~~ — changed from defaults (see .env on Mac Mini)
- [x] ~~Homarr dashboard~~ — configured with all services, organized into categories (Main, Media, Utilities, System, Direct Access)
- [x] ~~Linkwarden bookmarks~~ — 621 bookmarks imported (services + browser bookmarks)
- [x] ~~Uptime Kuma monitors~~ — all services monitored
- [x] ~~Ollama + Open WebUI~~ — removed (not enough RAM, using Claude instead)
- [x] ~~NordPass → Vaultwarden~~ — passwords migrated, subscription cancelled (Apr 2026)
- [x] ~~Radarr/Sonarr auto-cleanup~~ — `removeCompletedDownloads` + `removeFailedDownloads` enabled via API
- [x] ~~Ollama/Open WebUI containers~~ — stopped, removed from setup-services.sh
- [x] ~~Audiobookshelf subdomain~~ — fixed: books → listen
- [x] ~~B2 cloud backup~~ — nightly cron at 5am, services + obsidian-vault + Immich photos all backed up
- [x] ~~Immich photos B2 backup~~ — added `/Volumes/T7/immich/upload` to rclone-backup.sh
- [x] ~~Disk full (Apr 2026)~~ — T7 at 100% (17MB free). Cleared 480GB duplicate downloads from `downloads/complete/`, deleted 156GB old photo copies from APFS `TimeMachine` volume, removed 2.5GB ollama-models. Now at 140GB free.
- [x] ~~SSH enabled~~ — Remote Login turned on via System Settings, `ssh macmini` works via Tailscale
- [x] ~~Jellyfin delete fix~~ — removed `:ro` from media volume mounts so Jellyfin can delete files
- [x] ~~mac-mini.sh expanded~~ — added `services up/down/restart/status`, `cleanup`, `disk`, `ssh on/off` commands
- [x] ~~Ollama containers still running~~ — `ollama` and `open_webui` still in `~/services/ollama/`, should remove when home

---

