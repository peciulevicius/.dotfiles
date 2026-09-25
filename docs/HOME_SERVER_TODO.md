# Home Server — TODO

Outstanding work only. Finished items live in
[HOME_SERVER_CHANGELOG.md](HOME_SERVER_CHANGELOG.md).

Grouped by "what happens if I ignore this", not by number.

---

## ▶ Start here — do these in this order

Last worked: **2026-09-21**. Finished work is in
[HOME_SERVER_CHANGELOG.md](HOME_SERVER_CHANGELOG.md).

**The order matters** — each step unblocks or de-risks the next. The reasoning
is written out so it survives being read cold in a year.

| # | Step | Why it is here and not later |
|---|---|---|
| **1** | ✅ ~~Delete the plaintext vault exports~~ | Done 2026-09-21 |
| **2** | 🔴 Move TOTP off Google Authenticator | Seeds sync to the account being left — lockout risk |
| **3** | 🔴 Rotate the Vaultwarden admin token | Leaked into a container config on 2026-09-21 |
| **4** | 📮 Buy Purelymail + DNS | Everything below depends on the mailbox existing |
| **5** | 🔁 Repoint the 3 Gmail consumers, then revoke | Two of them fail **silently** |
| **6** | 🔑 One pass: password + email per service | Same ~14 logins — separating them doubles the work |
| **7** | 🧩 Vaultwarden Chrome extension | Blocked on the work laptop, not on us |
| **8** | 🤖 Odysseus model defaults + RAG | Pure upside, nothing depends on it |
| **8a** | 🔐 Regenerate the leaked Kuma push token, enable the hook on the MacBook | Token was public since May |
| **9** | 🧹 Pinned images, SMB, wallpapers | Maintenance backlog |

---

### ✅ 1. Delete the plaintext vault exports — done

Made during the 2026-09-21 Vaultwarden scare (212 cleartext passwords,
`encrypted: false`), cleaned up same day — verified 2026-09-21, no
`bitwarden_export*` files remain anywhere in `~/Downloads`.

> The vault itself was never damaged; the real fix was upgrading Vaultwarden
> 1.35.4 → 1.37.3. These exports were leftover blast radius from the
> debugging, not a backup anyone needed.

### ⚡ Batch 2026-09-24 — one-day push (subagents in parallel)

👤 = needs you. Everything else runs in parallel.

- [ ] 👤 **Reset Odysseus 2FA** (TOTP + backup codes) — exposed in a session
      transcript 2026-09-23 while auditing `data/auth.json`
- [ ] 👤 Reset the Uptime Kuma backup push token → `~/services/rclone/.env`
- [x] ~~**Odysseus repair**~~ — done: 131 memories (12 pinned), dup-skill bug
      removed, dev skills pruned, task/utility model = Sonnet
- [ ] **Email cutover** — 👤 Purelymail domain + `dziugas@` mailbox + Cloudflare
      API token; then DNS switch (replace SPF, MX, DKIM×3, DMARC, ownership),
      catch-all, tests, repoint kindle_sync / Calibre-Web / Kuma SMTP, 👤 revoke
      Gmail app password, 👤 iPhone Apple Mail + Sieve filters, 👤 Gmail forward
- [ ] **AI coach** — ✅ built 2026-09-25 (skill in Claude Code + Odysseus,
      `trainingpeaks-mcp` :8092, `strava-mcp` :8093, `~/.training` → R2).
      Remaining: 👤 Garmin→TP Daily Health Stats toggle; 👤 TP cookie into
      `~/services/trainingpeaks-mcp/.env` (Terminal, per its README); 👤 Strava
      API app + `strava-mcp auth`; then Odysseus restart (bind mount +
      `tool_path_extra_roots`), add both MCP servers in Odysseus, `claude mcp
      add` for TrainingPeaks, first coaching session
- [x] ~~**Claude config**~~ — done (setup-claude.sh fixed, 3 new skills)
- [x] ~~HOME_SERVER.md rewrite~~ — done
- [ ] Local models: no bigger model (RAM ceiling ~8B); optional later — OpenCode
      + `qwen2.5-coder:7b` for offline snippets only

### 📋 Open user steps — as of 2026-09-25

- [ ] 👤 **T7 external backup** — plug in the T7, run
      `~/.dotfiles/scripts/backup/backup-external.sh /Volumes/T7`, unplug.
      The weekly audit fails until the first run is stamped
      (`~/logs/external-backup-T7.last`), then again whenever it's >30 days
      old — that's the reminder. Same for T5 before it goes offsite.
- [ ] 👤 **Healthchecks.io heartbeat** — check created 2026-09-25 (5-min period,
      10-min grace). Remaining: save the ping URL from Terminal (not chat) into
      `~/.config/homelab/heartbeat.env` as `HEARTBEAT_PING_URL=`, then
      `scripts/utils/heartbeat.sh --test` → "sent: ok".
- [ ] 👤 **Uptime Kuma "Rclone Backup" push token** — Edit monitor → Reset
      Token → Save → put the new base URL in `~/services/rclone/.env`.
- [ ] 👤 **Email** — Purelymail "Add New Domain" page is open with the
      ownership value visible; waiting on the Cloudflare API token so the DNS
      records go in first, then Check DNS → Save → create `dziugas@` user →
      catch-all routing.

### 2. 🔴 Move TOTP off Google Authenticator — before any password change

**The single highest-risk item in the whole de-Googling effort.** Google
Authenticator syncs its TOTP seeds to the Google account being abandoned. Every
service whose 2FA lives there is one account-loss away from being unreachable.

- [ ] Export from Google Authenticator (its built-in transfer QR)
- [ ] Import into **Ente Auth** or **Vaultwarden** — see
      [guides/DEGOOGLE.md](guides/DEGOOGLE.md)
- [ ] Verify a login end-to-end with the new app **before** deleting anything
- [ ] Keep Google Authenticator installed until every seed is confirmed working

> ⚠️ Do this **before** step 6. Changing passwords across 14 services while 2FA
> still depends on Google means a single lockout takes all of them at once.

### 3. 🔴 Rotate the Vaultwarden admin token

On 2026-09-21 a throwaway container (`relaxed_ritchie`, vaultwarden 1.35.4) was
created to run `vaultwarden hash`. **The pre-hash admin token stayed visible in
its container config for ~4 hours**, readable by anything that could run
`docker inspect`. The container has been removed, but the token should be
treated as disclosed.

- [ ] Generate a new `ADMIN_TOKEN`, hash it, update `~/services/vaultwarden/.env`
- [ ] `docker compose up -d` and confirm `/admin` accepts only the new one
- [ ] Save it in Vaultwarden itself

> 💡 Lesson: `docker inspect` exposes the full command line of every container,
> including secrets passed as arguments. Pipe secrets via stdin to a container
> started with `--rm`, and verify it actually exited.

### 4. 📮 Buy Purelymail and cut DNS over

📘 **Full runbook: [guides/EMAIL.md](guides/EMAIL.md).** Do not improvise this
from memory — the ordering traps are documented.

- [ ] Sign up ($10/yr). ⚠️ The signup dropdown is the **account admin user's**
      address, not your mail domain — pick any, use a **long** username
- [ ] Add `peciulevicius.com`; create `peciulevicius@peciulevicius.com`
- [ ] ⚠️ **Disable Cloudflare Email Routing first** — two providers claiming the
      MX makes delivery non-deterministic
- [ ] Add all seven DNS records, **grey cloud** (proxying breaks mail)
- [ ] Enable catch-all — this is what makes step 6 cheap
- [ ] Test both directions; check <https://www.mail-tester.com> for 9+/10

### 5. 🔁 Repoint the three Gmail consumers — then revoke

⚠️ **Three things use Gmail, and two hide their config in SQLite** rather than
environment variables. An `env`-based audit reports "nothing uses email" and is
wrong. Full detail in [guides/EMAIL.md](guides/EMAIL.md) §2.

- [ ] **`pkm/kindle_sync.py`** — `IMAP_SERVER`, `EMAIL_ADDRESS`,
      `EMAIL_PASSWORD` in `pkm/config.py` (gitignored, Mac mini only). Point the
      Kindle's *Share → Searchable PDF* at `kindle@peciulevicius.com`
- [ ] **Calibre-Web** — Admin → Edit E-mail Server Settings. 🔴 **Fails silently**
      and has no fallback. Use its *Send test email* button
- [ ] **Uptime Kuma** — Settings → Notifications → the `smtp` entry. Its Discord
      notification is unaffected, so alerting stays audible throughout
- [ ] **Only then** revoke the Gmail app password at
      <https://myaccount.google.com/apppasswords>
- [ ] ⚠️ Also revoke it because it was printed to a terminal on 2026-09-21

### 6. 🔑 One pass per service — password AND email together

Both changes need the same ~14 logins. **Doing them separately means 28.**
Checklist: [CREDENTIAL_MIGRATION.md](CREDENTIAL_MIGRATION.md).

Per service, one visit: log in → Bitwarden-generated password saved **with the
autofill URL** → change address to `<service>@peciulevicius.com` → confirm the
verification mail arrives (this also proves catch-all works) → tick it off.

- [ ] Work down the checklist
- [ ] ⚠️ **Change Vaultwarden's own address LAST** — it is what recovers all the
      others; do not move it while still depending on it
- [ ] Delete `~/credentials-import.md` when the list is exhausted

⚠️ **After rotating any password, check every OTHER service that stores its own
copy of that login** — not just the service whose password you changed. Real
example, 2026-09-22: Transmission's password was rotated 2026-09-19, but
Radarr, Sonarr *and* LazyLibrarian each keep their own separate stored copy of
Transmission's login to talk to it. All three silently failed authentication
for three days — nothing in Transmission itself looked wrong. `grep -rl
"<old value>" ~/services/` across every service's config after any rotation
is cheap insurance against this exact class of miss.

### 7. 🧩 Vaultwarden Chrome extension on the work laptop

Still broken after the 1.37.3 upgrade fixed iOS. **The extension has never once
registered with the server** — no device type 2 in the database — which points
at the corporate network, not at Vaultwarden.

- [ ] Open `https://vault.peciulevicius.com` in a plain tab on that laptop
      first. If the page does not load, it is network policy and the extension
      was never going to work
- [ ] If the page loads, re-check the extension's self-hosted URL field

### 8. 🤖 Odysseus — configuration, not deployment

Running on 7001. Benchmarks in
[services/odysseus/README.md](https://github.com/peciulevicius/.dotfiles/blob/main/services/odysseus/README.md).

- [ ] Set **`qwen2.5:7b`** as the chat model, **`llama3.2:3b`** for background
      calls (titles, tagging)
- [ ] Point **RAG at `~/obsidian-vault`**
- [ ] Import Claude and ChatGPT history (⚠️ ChatGPT *memories* are not in the
      export — copy by hand)
- [ ] Point its IMAP client at Purelymail once step 4 is done
- [ ] Decide on the Anthropic API key — currently leaning **skip**, since
      claude.ai on Pro covers general reasoning and local covers the private topics

### 8a. 🔐 Public-repo hygiene — added 2026-09-23

Full secret audit done (gitleaks over all 492 commits + a targeted search for
every known credential): only one leak ever — the Uptime Kuma backup push
token, public since **2026-05-09**. Removed from the tree; the pre-commit hook
and weekly audit now guard against a repeat.

- [ ] 🔴 **Regenerate the Kuma backup push token** — Uptime Kuma → the backup
      push monitor → reset token → put the new URL in
      `~/services/rclone/.env` as `HEARTBEAT_URL=`. Until then the leaked
      token (still in git history) can mark the nightly backup healthy. Then
      add its gitleaks fingerprint to `.gitleaksignore` so full-history scans
      stop flagging a dead token.
- [ ] **Enable the hook on the MacBook's clone too** — since 2026-09-24
      `scripts/sync.sh` sets `core.hooksPath` on every run, so just run
      `~/.dotfiles/scripts/sync.sh` there once, then `brew install gitleaks`
      (sync warns if it is missing). (The statusline commit on 2026-09-23
      came from a clone without it.)
- [x] ~~Pre-commit secret hook~~ — `.githooks/pre-commit` + `.gitleaks.toml`
      (adds a Kuma push-token rule the defaults lacked), tested blocking a
      fake token. `install.sh` enables it; installers install gitleaks.
- [x] ~~Weekly automated audit~~ — `scripts/utils/homelab-audit.sh`, Sundays
      9AM via `run-with-notify.sh` → Discord on failure.
- [x] ~~Project skills~~ — `homelab-service`, `credential-rotation`,
      `homelab-audit` in `config/claude/skills/` (moved from `.claude/skills/` 2026-09-25).
- [ ] Optional: **import the homelab skills into Odysseus** — it reads the
      same `SKILL.md` format natively and can import from a public GitHub
      URL (this repo). Useful mainly as reference inside Odysseus chats; its
      local 7B model won't execute multi-step shell checklists the way Claude
      Code does.

### 8b. 🔒 Cloudflare/R2 security check — added 2026-09-21

Surfaced while reviewing the new Immich backup. Nothing is known-broken, both
are just unverified.

- [ ] **Check the R2 API token's scope** in the Cloudflare dashboard (R2 →
      Manage R2 API tokens). The setup docs never directed scoping it to one
      bucket, so it may currently be account-wide. If so, create a new token
      scoped to `peciulevicius-backups` only, update
      `~/services/rclone/.env`, confirm `rclone lsd r2:` still works, then
      revoke the old token.
- [ ] **Confirm 2FA is enabled on the Cloudflare account itself** and add it to
      [CREDENTIAL_MIGRATION.md](CREDENTIAL_MIGRATION.md) explicitly — it
      wasn't tracked there at all despite controlling DNS, the Tunnel, Email
      Routing, and now R2. This is arguably the single highest-value account
      in the whole setup.

### 8c. 🔌 Power outage recovery — added 2026-09-22

A real outage left the Mac mini fully off; needed a physical power-button
press to bring it back. Two separate gaps found.

- [ ] Run `sudo pmset -a autorestartatconnect 1` — needs an interactive
      password, so this is one for you, not something run in a session.
      `autorestart` (restart after a kernel panic) was already on; this is the
      *actual* "power on when AC returns" flag, and it was never set at all.
- [x] ~~Decide: keep FileVault on, or trade it for full unattended
      recovery?~~ — decided 2026-09-22: **keep it on.** Even with the setting
      above, FileVault's pre-boot disk password has no unattended-unlock path,
      so a person is still needed once per outage — but every one of 30+
      services' `.env` files stays encrypted at rest if the machine is ever
      stolen. Right trade for a box holding that many live secrets.
- [ ] 🔴 **Add an external (off this network) dead-man's-switch monitor.**
      ⏳ **Still open — code done 2026-09-24, account setup pending.** `scripts/utils/heartbeat.sh` + a 5-minute
      cron line + an audit check. Left for you (~5 min): Healthchecks.io
      account, a check with period 5 min / grace 10 min, then the ping URL in
      `~/.config/homelab/heartbeat.env` — steps in `scripts/cron/README.md`
      "Setting up the heartbeat". Original note:
      Confirmed 2026-09-22: Uptime Kuma and its Discord alerts run on the same
      machine that just lost power — when the whole house goes down, nothing
      can alert about it, because the alerter is also without power. Needs a
      service like [Healthchecks.io](https://healthchecks.io) (free tier)
      that expects a periodic ping *from* the Mac mini and alerts when the
      ping stops arriving — the inverse of how Kuma works today. A simple cron
      line hitting a Healthchecks.io ping URL every few minutes is the whole
      implementation; the alert fires on its servers, not this network.

### 9. 🧹 Maintenance backlog — no deadline, real value

- [x] ~~Try `pencil-handwriting.koplugin`~~ — researched 2026-09-22, **skip
      it, it's not what it sounds like.** It only draws ink *on top of an
      already-open PDF/EPUB* — there's no blank canvas, so it can't replace
      the stock notebook for freeform notes at all. It also has **no sync of
      any kind** — export is a manual screenshot or a drag-and-drop script,
      nothing automatic.
- [ ] **Try `notebook.koplugin` (by pierspad) for on-device writing —
      checked 2026-09-22, genuinely good, still doesn't replace the pipeline.**
      Real blank-canvas notebook, vector ink with clean erase/undo, multiple
      page backgrounds, actively developed and specifically optimized for the
      Scribe (a September 2026 audit measured up to 261× faster input
      handling on this exact hardware). But: **fixed pages, not infinite
      canvas** (same as every alternative researched), **no server sync** —
      only an optional local-Wi-Fi send-to-phone via `localsend.koplugin`,
      one notebook at a time — and **no search**. Doesn't produce anything
      `kindle_sync.py` can pick up, so it can't replace Amazon's *Share →
      Searchable PDF* OCR pipeline into Obsidian — worth using *alongside*
      the stock notebook for writing you don't need synced, not instead of
      it. Install: latest release zip → `koreader/plugins/` →
      `notebook.koplugin` folder → restart KOReader → Menu → Tools → More
      tools → Notebook. Full writeup: `guides/BOOKS.md`.
- [ ] **Decide: buy a Supernote Manta?** Not urgent, not blocking anything —
      the current Kindle+Calibre-Web+KOReader reading pipeline is untouched
      either way. Confirmed 2026-09-22: none of the alternatives (Supernote,
      Boox, reMarkable) give you everything at once — see the three-way
      trade-off table in `guides/BOOKS.md`. If bought, it can sync to the
      **already-running Nextcloud** via WebDAV, no new infrastructure needed.
- [ ] **Add a music library to Jellyfin.** No new service needed — Jellyfin
      already natively supports music as a library type, same app, same
      login. Create `/Volumes/media/music`, drop files in, add it as a
      library in Jellyfin's admin. Stream-only (no manual download step,
      works like Spotify) with **Finamp** (free, iOS/Android) or **Amperfy**
      (iOS, has a paid tier for extras but core streaming is free). Both
      point at the same Jellyfin server already running.
      Added 2026-09-22 as a stopgap: `scripts/utils/smb-watcher-rescan.sh`
      restarts Jellyfin + Audiobookshelf every 30 min because neither's file
      watcher reliably sees new files over SMB. Each real fix needs one
      30-second thing only you can do:
      - [ ] **Jellyfin** — dashboard → Admin → **API Keys → +** → send me the
            key, I'll wire it into Radarr's and Sonarr's Settings → Connect.
            Instant refresh, no restart, no playback interruption.
      - [ ] **Audiobookshelf** — same idea (Settings → API Keys), but check
            whether LazyLibrarian even supports a "notify on import" hook for
            it first — unconfirmed as of 2026-09-22, unlike Jellyfin's
            well-documented Connect integration.
- [ ] 🔴 **Rotate Immich's database password.** Found 2026-09-22 while
      checking whether other services shared the Transmission credential bug:
      `~/services/immich/.env`'s `DB_PASSWORD` is still your old, reused
      personal password (the same one flagged earlier in the credential
      migration). Internal-only (Postgres isn't exposed outside the Docker
      network), so not an active exposure, but it's the one password in this
      whole stack that was never actually replaced with a random one.
      ⚠️ **Do this carefully, not as a quick edit** — changing `.env` alone
      will NOT work: Immich's Postgres container already has the OLD password
      set on the database user, so a mismatched `.env` breaks Immich's DB
      connection entirely (photos safe on disk, app inaccessible). Correct
      sequence:
      ```bash
      NEW_PASS="$(openssl rand -base64 32)"
      docker exec immich_postgres psql -U postgres -c "ALTER USER postgres WITH PASSWORD '$NEW_PASS';"
      # then update DB_PASSWORD in ~/services/immich/.env to match $NEW_PASS
      docker compose -f ~/services/immich/docker-compose.yml up -d
      # verify: docker logs immich_server --tail 20 (no auth errors), open the app
      ```
- [x] ~~Rewrite `HOME_SERVER.md` against the NAS architecture~~ — done 2026-09-24
      (773 → 353 lines, every path re-based on the NAS; old version in git history)
- [ ] Clear the leftover data directories from tonight's removals:
      `rm -rf ~/services/mealie ~/services/grafana` (both confirmed
      empty/unused before removal, nothing to lose). Until then
      `rclone-backup.sh` excludes both (2026-09-24), so they stop being
      uploaded to R2 once the script is re-staged
- [x] ~~Remove Mealie~~ — done 2026-09-21/22. **0 real recipes** despite the
      folder existing — confirmed empty, not just "unused." Container, tunnel
      route (`recipes.peciulevicius.com`), homepage entry and network all
      removed.
- [x] ~~Remove Grafana + Prometheus + node-exporter~~ — done 2026-09-21/22.
      Tailscale-only (never in the tunnel config, so no public exposure to
      begin with), no script in this repo ever read its data, and the login
      itself was long forgotten. Reclaimed **~1.78 GiB RAM**. Container, homepage
      entry and network all removed.
- [ ] **Decide: Nextcloud — keep or remove?** Only 83MB of real user files in
      it (the rest is app code + DB engine). Its non-redundant features:
      **Calendar/Contacts sync** (CalDAV/CardDAV — nothing else here does
      that; depends on where your phone's contacts/calendar actually live
      today — if Google, this is the designated de-Google replacement already
      on the gap list in `guides/DEGOOGLE.md`; if Apple and happy there,
      redundant) and — new consideration, 2026-09-22 — **it's the confirmed
      WebDAV target for a Supernote's own-server note sync** (see
      `guides/BOOKS.md`), so it gains a second real use only if a Supernote is
      ever bought. ⚠️ Don't use Nextcloud's own Notes app if you do keep it —
      per a second creator's own de-Google attempt, it's a genuinely bad app
      (2.3★, constant disconnects, doesn't stay logged in); Obsidian is
      already the right notes tool here regardless.
- [ ] **Decide: Paperless-ngx — keep or remove?** Not empty like Mealie was —
      **14 real scanned documents** exist. Low activity, but not zero. Its job
      (OCR + searchable archive of scanned paperwork) is different from just
      uploading a file into an Odysseus chat — Odysseus's upload is ephemeral
      per-conversation context, not a tagged, dated, full-text-searchable
      archive across years. Keep if you expect to scan real paperwork
      (tax/medical/receipts) later; remove if not.

⚠️ **Pi-hole is the one that matters here:** pinned at `pihole/pihole:2024.07.0`,
publicly exposed, and it controls DNS for the whole network. A pinned tag never
moves, so Watchtower being enabled is not evidence anything is current.

- [ ] Bump **Pi-hole** first, then work through the other pinned images
- [ ] Move the **Calibre library off SMB** onto the internal SSD — SQLite over
      SMB is the root cause of every Calibre-Web failure so far. Scripted —
      see "Move the Calibre library off SMB onto the SSD" below
- [ ] Delete ~2.3 GB of locked `.smbdelete` duplicates (needs NAS-side access)

#### Quick wins left over from 2026-09-20

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

---

## Detail and standing items

Everything above is the ordered path. What follows is background for those
steps, plus items that sit outside the sequence entirely.

### 🔑 Credentials — detail for step 6

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

> **Do email next, ahead of the remaining Odysseus polish** (decided
> 2026-09-21). Odysseus is functionally done; what is left there is optional.
> Email *blocks* three things: `kindle_sync.py` still authenticates with a
> **Gmail app password**, Odysseus's IMAP client has nothing to connect to, and
> Cloudflare Email Routing **receives only** — every reply still goes out as
> `@gmail.com`.
>
> ⚠️ **Do it in the same pass as the credential migration.** Both require
> logging into each of the ~14 remaining services. Set the Bitwarden password
> *and* change the address in one visit, or you do 28 logins instead of 14.

### 💾 Disk — cleaned 2026-09-21, watch it

Was **15 GiB free (92% full)**, now **24 GiB (88%)**. Freed by `docker builder
prune -af` (6.05 GB), `brew cleanup --prune=all` (477 MB) and deleting applied
Squirrel/ShipIt update staging (~2.1 GB). `~/Library/Caches` went 6.8 → 4.4 GB.

- [x] ~~Reclaim applied-update staging~~ — done 2026-09-21. Recurs as the apps
      update, so it is worth re-checking when disk gets tight:
      `du -sh ~/Library/Caches/* | sort -rh | head`
- [ ] Move the Calibre library off SMB onto the internal SSD (1.1 GB)
- [ ] ~2.3 GB of locked `.smbdelete` duplicates — needs NAS-side deletion

⚠️ **Do not run `docker image prune -a`.** The 2.77 GB "unused" image is
**Storyteller**, which is simply stopped most of the time. `-a` would delete it
and anything else not currently running. Dangling-only (`docker image prune -f`)
reclaimed 0 B — there is nothing dangling to collect.

💡 `Docker.raw` is 48 GB and does not shrink on delete; it TRIMs back after a
prune. Judge free space with `df -h /System/Volumes/Data`, not the file size.

### 🔗 Obsidian LiveSync — the server side is done

CouchDB is up at `https://couchdb.peciulevicius.com`, `obsidian` database
created, anonymous requests 401 on every path except `/_up`.

- [ ] Install **Self-hosted LiveSync** on each device, E2E encryption on, same
      passphrase everywhere
- [ ] ⚠️ **Start on the Mac mini** — it holds the real vault. Let it finish
      uploading before connecting the iPhone. LiveSync asks which side wins and
      answering with an empty device wipes the vault. Snapshot:
      `~/backups/vault-snapshots/`.

### 🛡️ Standing risks — not in the sequence, but real

Two items sit outside the ordered path and are easy to forget precisely because
nothing is currently broken. Both are written up in full under
"Do these first — you lose data or access without them" below:

- 🔴 **Tailscale key expiry — 2027-03-04.** Odysseus, Vaultwarden and all
  phone access are Tailscale-only. When the key expires, remote access to
  everything stops at once, and it stops *quietly*. It has happened once already.
- ✅ **Cloud offsite copy of photos — done 2026-09-21.** 72.4GB, all originals,
  in R2. iCloud is cancelled, so this + the still-pending T5-to-parents' plan
  (below) is what makes photos 3-2-1. RAID survives a dead drive, R2 survives
  a fire in this room.

### ✅ Odysseus — detail for step 8

**Deployed 2026-09-21** on **port 7001** (7000 is AirPlay Receiver). Four
containers, Tailscale-only at `http://100.81.171.49:7001`, local model working
through native Ollama. Full notes:
[services/odysseus/README.md](https://github.com/peciulevicius/.dotfiles/blob/main/services/odysseus/README.md).

- [ ] **Add an Anthropic API key** — `console.anthropic.com`. ⚠️ Billed
      separately from Claude Pro; a subscription is **not** an API key. Keep a
      low balance and **auto-top-up off**, so a leaked key or a runaway agent
      loop cannot drain it.
- [ ] Save the Odysseus admin password + API key to Vaultwarden
- [ ] 🔒 **Habit to set: health, finances and journal go to the local model.**
      Cloud gives sovereignty over the record, not privacy from the provider.
- [ ] Import **Claude and ChatGPT history** exports. ⚠️ ChatGPT *memories* are
      not included in the export — copy them by hand.
- [ ] Point **RAG at `~/obsidian-vault`**
- [ ] Point the **IMAP client at Purelymail** after the email migration
- [x] ~~Try **Cookbook**~~ — ❌ **unusable on this host, settled 2026-09-21.**
      Docker on macOS has no GPU passthrough, so Cookbook scans the *container*,
      not the M4: it reports `No GPU`, rates 1.5B models "PERFECT" and offers
      70GB downloads. Anything it serves is CPU-only. Verified no stray
      download landed (`data/huggingface/` is 72KB). Use native Ollama.
- [ ] Set Odysseus's model defaults: **`qwen2.5:7b` for chats**, **`llama3.2:3b`
      for background calls** (titles, summaries, tagging). Benchmarks in
      `services/odysseus/README.md`
- [x] ~~`ollama rm qwen3:4b`~~ — done 2026-09-21. Dominated on both axes:
      slower end to end than the 7B *and* less useful (2445 tokens to answer
      one question)
- [ ] Point Odysseus's **Agent (OpenCode)** at Ollama for private or throwaway
      coding; keep Claude Code for real work
- [ ] Only if a concrete gap appears: Gemini or OpenAI keys
- [ ] Try `qwen3:8b` if RAM allows — ⚠️ headroom is now **2.11 GiB**; drop
      SearXNG first if it bites
- [ ] `ai.peciulevicius.com` only if a non-Tailscale device ever needs it

**Decided against OpenRouter**, despite being the obvious pick: 5.5% top-up fee,
1-year credit expiry, 24-hour refund window, Discord-only support, some
providers serving quantized models — and its Series B was led by **CapitalG,
Alphabet's investment arm**, a poor fit mid-de-Googling.

### Not Mac mini work — on the phone, whenever

⚠️ **Google Authenticator → Ente Auth.** Highest-risk item in the whole
de-Google effort: its TOTP seeds sync to the account being left.

---

## Do these first — you lose data or access without them

### Disable Tailscale key expiry

Key expires **2027-03-04**. When it does, the Mac mini silently drops off the
tailnet: no `ssh macmini` from away, and every Tailscale-only service
(Sonarr, Radarr, Prowlarr, Transmission, Syncthing, Jellyseerr, Bazarr,
LazyLibrarian, Odysseus) becomes unreachable. This already happened
once and was only noticed on 2026-09-05, during an outage, from home.

- [ ] Tailscale admin console → Machines → `macmini` → ⋯ → **Disable key expiry**
- [ ] Same for `ugreen-nas`

Logging back in only resets the same six-month timer — disabling expiry is the
actual fix.

### Get one copy of the photos out of the building

Photos live on the NAS (RAID 5) plus T7 and T5 — but all three sit in the same
room. RAID survives a dead drive; it does not survive fire, flood, or theft.
Two complementary plans, not either/or — the drive is already loaded and just
needs a trip, the cloud copy needs nothing but a decision.

**Plan A — physical drive, already loaded, needs a trip**

- [ ] Take T5 to the parents' house once possible (it was verified 1:1 against
      the NAS on 2026-09-05 — see the backup section below)
- [x] ~~Consider dropping iCloud~~ — already cancelled (early 2026). This makes
      getting T5 offsite *more* urgent, not less: there is no cloud copy of the
      photos any more, only the NAS and two drives in the same room.

**Plan B — cloud copy of originals via the existing R2 backup, added 2026-09-21**

Measured: Immich's library is **90GB total**, but only **73GB (`upload/`) is
irreplaceable**. `encoded-video/` (15GB) and `thumbs/` (1.5GB) are transcodes
and thumbnails Immich regenerates from the originals; `backups/` (878MB) is
Immich's own DB snapshot, already redundant with the weekly `pg_dump` of
`immich_postgres` that Backup 3 already ships to R2. So the cloud copy only
needs the 73GB, not the full 90GB.

`rclone-backup.sh` now has this wired up as **Backup 5**, guarded behind
`BACKUP_IMMICH_PHOTOS` — **off by default**, deliberately: flipping it silently
would hand the next 5am cron run a ~73GB first upload (hours, depending on
upload speed) and move the R2 bill from $0/month (everything else combined is
~2.9GB, under the 10GB free tier) to **~$1/month**. Every run after the first
is incremental — rclone only transfers new or changed files — so the cost and
time only spike once, on the first run.

- [x] ~~Decide and run it~~ — done 2026-09-21. **72.396 GiB, 6,696 files,
      zero errors**, matches the dry-run prediction exactly. First run hit a
      bash gotcha (a live re-`cp` of the script mid-execution corrupted the
      running interpreter's read position — never overwrite a script file
      while it's still executing) and separately caught two live-SQLite files
      that fail every run (`portainer.db`, Celery's schedule) — both fixed,
      both now excluded. Second attempt ran clean end to end.
- [ ] Spot-check restore integrity — **automated 2026-09-24**:
      `scripts/backup/r2-verify.sh` pulls one random photo (and one file from
      every other set) back and byte-compares it. Still to do: reinstall the
      crontab (`crontab < ~/.dotfiles/scripts/cron/crontab`, then
      `crontab -l`), run the script once by hand and tick this off when it
      passes
- [x] ~~Let the nightly cron pick it up~~ — ⚠️ it didn't at first: cron ran
      the repo copy, which read a different `.env` without the flag. Fixed
      2026-09-23 (cron now runs `~/services/rclone/`); first confirmed nightly
      run is the next 05:00. See changelog.
- [x] ~~Re-check yearly that it's still running~~ — `r2-verify.sh` logs
      `rclone size` monthly to `~/logs/r2-size-history.tsv` and fails on a
      >5% shrink; a flat line shows as "unchanged since the last check"

Full detail: `services/rclone/README.md` "Immich photo/video backup", and the
updated backup facts table in
[HOME_SERVER_REFERENCE.md](HOME_SERVER_REFERENCE.md).

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

**Decision 2026-09-19 — one non-default username everywhere, and two kinds of
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

Both NAS accounts (personal admin + `macmini` SMB service account) currently
use the same password as elsewhere. Rotate to unique generated passwords:
- [ ] personal admin (web UI) — generate in Bitwarden, update entry
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

- [x] ~~Decide the layout~~ — decided 2026-09-24: **move the whole library**,
      not a metadata-only split. It is 1.1GB, a split would need Calibre,
      Calibre-Web *and* LazyLibrarian to agree on two paths, and the book
      folders are exactly what Calibre-Web renames (the `.smbdelete` source).
      Steps and script in the next section.

### ⚠️ 21 pinned images that Watchtower can never update

Watchtower is enabled, which creates a false sense of currency: **a pinned tag
never moves**, so Watchtower silently does nothing for most of the stack. This
cost four hours on 2026-09-21 — the Bitwarden iOS app was broken by a bug fixed
three Vaultwarden releases earlier, and the pin hid it.

Every request logged **200 OK** while the app failed, because the fault was a
malformed response body, not an error status. **When a client misbehaves against
a healthy-looking server, compare versions first.**

Oldest and most exposed first:

- [ ] **Pi-hole `2024.07.0`** — over a year old and **publicly reachable** at
      `pihole.peciulevicius.com`, controlling DNS for the whole network.
      Highest priority.
- [ ] **it-tools `2023.11.2`** — public, and the oldest pin here
- [ ] **Jellyfin `10.10.6`**, **Uptime Kuma `1.23.16`** (Grafana was removed
      2026-09-22)
- [ ] The rest: audiobookshelf, bazarr, calibre-web, couchdb, freshrss,
      jellyseerr, linkwarden, mariadb, redis, sonarr/radarr,
      stirling-pdf, syncthing, transmission
- [x] ~~vaultwarden~~ — 1.35.4 → **1.37.3** on 2026-09-21

**Process, not a one-off:** bump deliberately, one service at a time, reading
release notes and backing up data first — that is why they are pinned, and
pinning is still the right call. But schedule it; quarterly is enough.
`docker compose pull` will not help while the tag is fixed.

**Scheduled since 2026-09-24:** `scripts/utils/check-image-updates.py`
compares every pinned tag with the registry (patch/minor/major, database
majors flagged as needing a data migration) and runs quarterly from cron,
posting the list to Discord. Run it any time with `--outdated`. First run,
2026-09-24: 25 of 26 pins behind — patch-level and safe to take first:
couchdb 3.5.2, sonarr 4.0.20, calibre-web 0.6.27; the big ones are Pi-hole
(2024.07 → 2026.09, v6 config migration), Uptime Kuma 1 → 2, Syncthing 1 → 2,
Radarr 5 → 6, Prowlarr 1 → 2, Paperless 2 → 3, Stirling PDF 0.36 → 2.x.

### Internal SSD — 24GiB free of 228GB (88%), after the 2026-09-21 cleanup

⚠️ It had reached **15GiB / 92%** before cleanup, not the 29GB recorded earlier
— it fills faster than expected. Freed 6.05GB (Docker build cache), 477MB
(Homebrew) and ~2.1GB (applied Squirrel/ShipIt update staging).

| What | Size |
|---|---|
| Docker (`Docker.raw`) | **48GB allocated** — TRIMs back after a prune; judge by `df`, not file size |
| `~/services` (service data) | 6.9GB |
| `~/.ollama/models` | 6.2GB (2 models) |
| `~/Library/Caches` | 4.4GB — mostly live browser cache, leave it |
| `~/dev` | 4.9GB |

⚠️ **Never `docker image prune -a`.** The 2.77GB image it reports as unused is
**Storyteller**, which is simply stopped most of the time. Dangling-only
(`docker image prune -f`) reclaims 0B — there is nothing dangling to collect.
The safe reclaim is `docker builder prune -af`.

Cheap wins first, in order:

- [ ] **Empty the Trash** — 2.7GB, mostly the Storyteller working files and the
      removed karakeep/readarr data
- [x] ~~Prune Docker~~ — done 2026-09-21, **945MB** reclaimed by removing an
      orphaned `tensorchord/pgvecto-rs` image left from an older Immich.
      ⚠️ **Do not run `docker system prune -a`**: it deletes every image not
      backing a *running* container, which on this host means the 2.77GB
      Storyteller image that is stopped by design. Remove specific images
      instead, after checking `docker ps -a --format '{{.Names}}\t{{.Image}}'`.
      The 7 dangling volumes hold 55KB total — not worth the risk of touching.
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

**It is affordable now:** the whole library is **1.1GB** and the SSD has 24GB
free.

📜 **Scripted 2026-09-24: `scripts/utils/migrate-calibre-to-ssd.sh`.** Dry
run by default; `--apply` stops all three containers, rsyncs, verifies by
checksum + `PRAGMA integrity_check`, sets `BOOKS_DIR` in each `.env` (old one
kept as `.env.pre-ssd-migration`), recreates the containers and checks their
`/books` mount. Any failure before the switch restarts them on the old path.
Rollback is in the script header. Tested against a stand-in library and a
stubbed `docker`, not yet on the Mac mini.

- [ ] Re-stage the changed backup script first — `cp
      ~/.dotfiles/services/rclone/rclone-backup.sh ~/services/rclone/` (it now
      reads the library path from `~/services/calibre/.env`)
- [ ] `~/.dotfiles/scripts/utils/migrate-calibre-to-ssd.sh` (dry run), then
      `--apply`
- [x] ~~Repoint the `BOOKS_DIR` bind mount~~ — compose files already read
      `${BOOKS_DIR}`; the script edits the three `.env` files
- [x] ~~Update `rclone-backup.sh`~~ — it, `backup-external.sh` and
      `r2-verify.sh` all read `BOOKS_DIR` from `~/services/calibre/.env` now;
      backup 1 excludes `calibre/library/**` so it isn't uploaded twice
- [x] ~~Decide where the large read-along EPUBs live~~ — with them, on the
      SSD. One 733MB book fits; revisit only if read-alongs become a shelf
- [ ] Verify OPDS still serves to KOReader afterwards, and that Calibre-Web
      opens a shelf (the old `disk I/O error` path)
- [ ] After a week: delete `/Volumes/books` from the NAS via UGOS, then update
      the Calibre rows in `HOME_SERVER_REFERENCE.md` and `NAS.md`

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

- [x] ~~Set a recurring reminder~~ — done 2026-09-24: `backup-external.sh`
      stamps `~/logs/external-backup-<drive>.last`, and the weekly
      `homelab-audit.sh` fails (→ Discord) once a stamp passes 30 days. The
      first audit after this lands will flag "no external-drive backup
      recorded" until a run to T7 writes the first stamp — that is intended
- [ ] Decide what T5 is *for* — once it lives offsite it can never be the
      routine local target

Run a backup with:
`~/.dotfiles/scripts/backup/backup-external.sh /Volumes/T7 --dry-run` then without `--dry-run`.

### Router DHCP reservation for the NAS

No longer load-bearing — everything addresses the NAS as `DH4300PLUS-DP.local`
(mDNS) since 2026-09-05, which absorbs IP drift. Still worth pinning.

- [ ] OpenWrt (`192.168.1.1`) → static lease for the NAS (MAC from the router's client list)

---

## Projects (no deadline)

### Pi-hole — finish the deployment

**Note:** PIHOLE_API_KEY is now configured in `~/services/glance/.env` — DNS stats widget is working.

**Goal:** Access `*.peciulevicius.com` on local WiFi without going through Cloudflare.

⚠️ **Checked 2026-09-24 — do NOT add the local DNS records on their own; it
breaks every service on the LAN.** Nothing on the Mac mini listens on 443:
TLS and the subdomain → port mapping (`photos` → 2283, `books` → 8083, …) both
happen *inside* the Cloudflare tunnel. Point `photos.peciulevicius.com` at
`192.168.1.x` and the browser opens `https://192.168.1.x:443` — connection
refused, on every device using Pi-hole. The records only work together with a
local reverse proxy that holds real certificates:

- **Caddy** with the `caddy-dns/cloudflare` module — DNS-01 challenge, so it
  gets valid `*.peciulevicius.com` certs without exposing a port, and one
  `Caddyfile` line per subdomain → `localhost:<port>`. The tunnel keeps
  serving everything from outside; Caddy serves the same names at home.
- Needs a Cloudflare API token scoped to *Zone → DNS → Edit* for this zone
  only (not the R2 token), kept in `~/services/caddy/.env`.

What it buys: LAN traffic stays on the LAN (faster Immich/Jellyfin at home,
works when the internet is down). What it costs: another service, and two
paths to every app that can drift apart. **Today the tunnel already works from
inside the house**, so this is an optimisation, not a fix. Decide before doing
any of it.

- [ ] Decide: Caddy for local HTTPS, or leave everything on the tunnel
- [ ] Independent of that, and worth doing on its own: set router DNS to the
      Mac mini IP (primary) + `1.1.1.1` (fallback), so every device gets
      ad-blocking, not just the manually configured ones (see below)
- [ ] Only with Caddy running: Pi-hole → Local DNS → DNS Records, each
      subdomain → Mac mini LAN IP; test `curl -I https://home.peciulevicius.com`
      from a LAN device returns 200 with a valid cert

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
- Notable: `/Volumes/T7/2024` (99GB) holds trip folders with both iPhone and camera shots

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

- [ ] **Stand up CouchDB + Self-hosted LiveSync** — ✅ CouchDB side done
      2026-09-19; what remains is the plugin on each device (see "Obsidian
      LiveSync" above). Self-hosted Obsidian sync,
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

> 📘 **Full runbook: [guides/EMAIL.md](./guides/EMAIL.md)** — DNS records,
> signup gotcha, rollback, verification and the Gmail funnel. Written
> 2026-09-21 so this can be rebuilt from cold.
>
> ✅ **Audited 2026-09-21: nothing in the stack breaks.** `pkm/kindle_sync.py`
> is the *only* thing using email (IMAP). Uptime Kuma and `notify.sh` use
> Discord webhooks; **no container has SMTP configured at all.**
>
> ⚠️ **Signup gotcha:** the domain dropdown on Purelymail's signup form
> (`purelymail.com`, `cheapermail.com`, …) is the **account admin user's**
> address, *not* your mail domain. Pick any, use a **long** username (short
> ones on shared domains carry a $0–$1.20/yr anti-squat fee), then add
> `peciulevicius.com` separately — users on your own domain are free.

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

#### Calendar + Contacts — unblocked, ~1 hour, more urgent than it looked

Nextcloud is already running. Nothing is stopping this.

⚠️ **Corrected 2026-09-22 — this isn't a de-Google migration, it's fixing an
actual single point of failure.** Contacts and calendar live **only on the
iPhone itself** — not backed up to Google, and (until this is done) not
backed up anywhere. A lost, stolen, or bricked phone loses both completely.
There's no Google `.ics`/`.vcf` export to pull from; the import source is the
phone's own local data.

- [ ] Enable Nextcloud Calendar + Contacts apps
- [ ] On iPhone: Settings → Contacts / Calendar → **export first** (Contacts
      app → select all → Share → vCard; or use the Nextcloud/CardDAV import
      flow directly) before touching sync settings — don't let a sync error
      be the first time a two-way merge runs against your only copy
- [ ] Add CalDAV + CardDAV accounts on the iPhone, verify two-way sync
- [ ] Confirm a re-fetch on a second device (or after a fresh CalDAV
      re-add) actually shows everything — this is the real backup test, not
      just "the accounts screen shows green"

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
      do your banking apps survive hardware attestation; is HeliBoard's
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
