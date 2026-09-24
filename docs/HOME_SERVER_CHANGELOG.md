# Home Server — Completed Work

Archive of finished items, moved out of `HOME_SERVER_TODO.md` on 2026-09-08 so
that file holds only outstanding work. Kept because the *why* behind a past fix
is often what you need when something similar breaks again.

Newest first-ish; dates are when the work was finished.

---

## 2026-09-24 — Pinned images get a quarterly review

`scripts/utils/check-image-updates.py` reads each pinned tag from
`services/*/docker-compose.yml`, lists the registry's tags (Docker Hub, GHCR —
`lscr.io` resolves there — and GitLab) and reports the newest release of the
same shape (`16-alpine` only against `NN-alpine`; date-style versions only
against date-style), classed patch/minor/major, with database majors flagged
as data migrations. Legacy tags that merely look newer (LinuxServer's
Calibre-Web once carried Calibre's 5.x versions) are excluded per image.
Report-only; a quarterly cron job posts the list to Discord. Kept out of the
weekly audit on purpose: with most pins behind at any given time it would be
permanently red, and a check that is always red gets ignored.

## 2026-09-24 — cleanup.sh no longer prunes the homelab's stopped services

`scripts/cleanup.sh` ran `docker container prune`, `image prune -a` and
`volume prune` on every host. On the Mac mini that deletes Storyteller (stopped
by design, `restart: "no"`) and its 2.77GB image, and any volume not attached
to a running container — the exact commands HOME_SERVER_TODO.md says never to run
there. It now detects the homelab host (compose files in `~/services`) and
only removes the build cache and dangling images; `DOCKER_FULL_PRUNE=1`
restores the full prune.

## 2026-09-24 — Cloud PRs triaged: #34/#35 merged, #36/#40 closed with cherry-picks

A cloud Claude session opened six PRs. Each was reviewed against the live
system before anything landed.

- **#35 (CI: gitleaks, shellcheck, strict docs build)** — merged as-is after a
  rebase.
- **#34 (backup reliability)** — merged after two fixes: the cron label
  (`"SMB rescan"` vs live `"SMB library rescan"`, which would have failed the
  new crontab-diff audit weekly) and the restore/verify fallback bucket (the
  non-existent `peciulevicius-services-backup`, only used when `.env` is
  missing — i.e. exactly a disaster rebuild). Live crontab reinstalled from the
  repo (now identical, 7 jobs). First `r2-verify.sh` run: all five sets
  restored a byte-identical file.
- **#36 / #40 (docs "professional rewrite")** — closed. Their tone rewrites
  halved BOOKS/KINDLE_SETUP/DEGOOGLE and deleted settled decisions ("can't
  wipe the Scribe", the capture-friction diagnosis, "don't re-research",
  the why/caught lines), and #40's SERVICES.md rewrite dropped post-deploy
  wiring, access rationale and the Mobile Apps section. **Kept by
  cherry-pick:** the privacy scrub (NAS serial, router MAC, remote-access URL,
  Send-to-Kindle address, employer/colleague/bank/family names, DRM tooling;
  `settings.local.json` untracked everywhere), the changelog redaction, and the
  UTILITY_SCRIPTS refresh.
- **Hand-applied** the other real fixes from those PRs: Mealie hostname out of
  `setup-cloudflare-tunnel.sh`, `guides/EMAIL.md` into the docs nav, stale
  `/pr`/`/docs`/`/deploy` and command counts out of CLAUDE_CODE_GUIDE. Also
  scrubbed what the PRs missed: the NAS admin *login* name (half a credential)
  and piracy indexer / release names (generic labels now; Prowlarr IDs and
  every gotcha kept). Your name as a public author identity stays.

## 2026-09-24 — Repo crontab had fallen behind; audit now checks it

`scripts/cron/crontab` is documented as the authoritative schedule, but it
still ran the backup from the **repo** copy (`~/.dotfiles/services/rclone/…`)
— the exact path the 2026-09-23 fix moved away from — and was missing the
`smb-watcher-rescan.sh` and `homelab-audit.sh` jobs. The next
`crontab < scripts/cron/crontab` would have silently re-broken the Immich
photo backup and dropped two jobs. File brought in line with
`scripts/cron/README.md`. ⚠️ The two added lines were reconstructed from the
docs, not copied from the live crontab — the first audit run shows any
difference.

Three gaps closed in the same pass, all "nothing notices" failures:

- **`homelab-audit.sh` diffs `crontab -l` against the repo file**, so the two
  can't drift apart unnoticed again.
- **External-drive staleness.** `backup-external.sh` writes
  `~/logs/external-backup-<drive>.last` on success and reports the previous
  run's age at start; the audit fails past 30 days. Replaces the nightly cron
  removed 2026-09-05 (drives aren't always connected), after which T5 went
  seven weeks stale unnoticed.
- **`scripts/sync.sh` enables the gitleaks pre-commit hook** on every run and
  warns if gitleaks is missing. `core.hooksPath` is per-clone and `install.sh`
  runs once per machine, so older clones (the MacBook) never got it.

### `restore.sh` can now restore everything that is backed up

It could only restore the service-config set. The vault, DB dumps, Calibre
library and Immich originals, which are the irreplaceable parts, had no restore
path, so a disaster would have meant writing rclone commands from memory.
Added `restore.sh set <vault|dumps|books|photos>`. `db` now detects MariaDB
dumps (Nextcloud's) instead of piping them into `psql`, and connects to the
`postgres` maintenance database for `pg_dumpall` output. `all` uses
`rclone copy` rather than `sync`, so it can't delete sets already restored
next to it. Defaults now say R2, not B2.

### Calibre-off-SMB migration scripted (not yet run)

`scripts/utils/migrate-calibre-to-ssd.sh` moves the whole library (1.1GB) to
`~/services/calibre/library`: SQLite over SMB is behind every Calibre-Web
failure so far. Whole library rather than a metadata-only split, because a
split needs three services to agree on two paths and the book folders are
what Calibre-Web renames. The backup scripts no longer hardcode
`/Volumes/books`: they read `BOOKS_DIR` from `~/services/calibre/.env`, so the
backups move with the library.

### Monthly R2 restore check

New `scripts/backup/r2-verify.sh`, cron'd for the 1st of each month: one
random file per backup set is downloaded and byte-compared with the original,
and bucket sizes go to `~/logs/r2-size-history.tsv`, failing on a >5% shrink.
"All backups complete" only proves an upload ran — this proves a restore
works. Tested here against a local stand-in for R2 (a corrupted file and a
shrunk set both fail it). Not yet run against the real bucket.

## 2026-09-24 — External dead-man's switch (code; account setup pending)

Every alert here ran on the Mac mini, so the 2026-09-22 power cut went
unreported. `scripts/utils/heartbeat.sh` now pings Healthchecks.io every five
minutes from cron; Healthchecks alerts from its own servers when the pings
stop. It pings `/fail` when Docker does not answer within 20s, because Uptime
Kuma is a container and is blind at the same moment. The ping URL is a
credential and lives only in `~/.config/homelab/heartbeat.env`; a new gitleaks
rule (`healthchecks-ping-url`) blocks it from being committed, and the weekly
audit fails while it is missing or the last successful ping is over an hour
old. Not wrapped in `run-with-notify.sh` — it would nag every five minutes
while unconfigured; the audit reports that weekly instead.

## 2026-09-24 — Odysseus memories and skills repaired

- **Memory re-import.** The 2026-09-23 import ran on qwen2.5:7b with a 4k
  context — it saw part of the export, merged ~40 facts into one blob (later
  deleted), saved skill descriptions as memories; **none of the export
  survived**. Rewritten as 130 atomic facts directly through `MemoryManager`
  inside the container (no model involved), 12 pinned; vector index rebuilt
  (startup only rebuilds an *empty* index). 3 → 131 memories; 15-fact
  spot-check matched the export.
- **Skills.** Removed 32 nested ownerless `SKILL.md` copies that `app.py`
  would have adopted into `general/` on every restart; pruned the 29 dev
  skills plus one extractor draft — only the homelab skills remain (coding
  stays in Claude Code).
- **Background model.** Task + utility models were empty (fell back to the
  4k local model); now `claude-sonnet-5` (API-billed). Default chat stays
  `claude-opus-5-5`.
- Backups: `data/{memory,settings}.json.bak-2026-09-24`. Scratch files holding
  personal facts removed from container and host `/tmp`.

## 2026-09-24 — CI on every push: secrets, shellcheck, docs

`.github/workflows/checks.yml` runs on every push to every branch:

- **gitleaks** over the pushed commits — the server-side backstop for the
  pre-commit hook, which is per-clone and silently skips when gitleaks isn't
  installed (how the 2026-09-23 commit got in from the MacBook). Pushed
  commits only, so the one dead token still in history doesn't fail every run.
- **`shellcheck -S error`** on every tracked script. Errors only: the warning
  level flags ~40 intentional patterns, and an always-red check gets ignored.
  The one existing error (`scripts/utils/utils.sh` had no shell directive — it
  is sourced, never run) is fixed.
- **`mkdocs build --strict`** — `docs-pages.yml` only built after a push to
  `main`, so a docs break surfaced after it had landed.

## 2026-09-24 — Claude config: setup-claude.sh was silently linking nothing

- **`setup-claude.sh` had linked nothing since the scripts reorg (31dbaa2)** —
  `DOTFILES_DIR` resolved to `scripts/`, so it looked for a nonexistent
  `scripts/config/claude`. That's why dead command symlinks piled up and
  `/dotfiles` never got linked. Fixed the depth; it now also prunes dead
  symlinks pointing into `config/claude` (removed 7).
- Removed duplicate `check`/`debug`/`review`/`standup` commands — the skills
  remain and are invoked the same way (the deletions landed in the
  HOME_SERVER.md commit by accident; same intent). `check` now uses gitleaks;
  `debug` reports root cause / fix / prevention and commits only if asked.
- Devops agent: dropped the removed Grafana/Prometheus stack and the
  ineffective `brew services restart cloudflared` (→ `launchctl kickstart`).
- New global skills: `personal-finance` (IBKR connector, read-only by
  default), `pkm-notes`, `testing` (Vitest/Playwright + Angular + xUnit). No
  personal data in them — details come from Odysseus memory at runtime.

## 2026-09-24 — HOME_SERVER.md rewritten for the NAS architecture

The linked "set up from scratch" guide still described the pre-2026-08-04
T7-primary setup. Rewritten (773 → 353 lines) against the current facts in
`HOME_SERVER_REFERENCE.md`, `SERVICES.md`, `NAS.md` and the live compose files:
architecture, prerequisites (incl. getting into Vaultwarden when it's what
you're rebuilding), step-by-step rebuild with the pmset/FileVault, copy-not-
symlink staging and real-cloudflared-agent caveats, R2/DB-dump/Immich restores,
cron, and an if-something-breaks table. The old narrative stays in git history.
Unverified spots are marked "check" rather than guessed (whether a Time Machine
target is still active; whether the tunnel setup script reuses a tunnel).

## 2026-09-23 (later still) — Nightly backup had silently dropped the Immich photos

**Note:** **Corrects the 2026-09-21 entry that said "let the nightly cron pick it up,
no further change needed" — that was wrong.** Cron ran
`~/.dotfiles/services/rclone/rclone-backup.sh` (the repo copy), and the script
loads `.env` from its own directory — a second, stale `.env` that never got
`BACKUP_IMMICH_PHOTOS=true`. The flag had been set in `~/services/rclone/.env`,
which only the manual runs read. So after the one manual 72GB upload, every
nightly run backed up everything *except* new photos while reporting "All
backups complete". Same trap would have hit today's `HEARTBEAT_URL` move.

Fix: cron now runs the staged copy (`~/services/rclone/rclone-backup.sh`),
matching every other service; the stale repo-side `.env` (a strict subset,
gitignored, never committed) was moved out to
`~/services/rclone/.env.retired-repo-copy`. Dry-run of the exact cron command
confirms the Immich step and heartbeat are active. No photos lost — rclone is
incremental, so the next run uploads the gap.

`homelab-audit.sh` now also fails if Immich backup is enabled but didn't run
in the last day, since "All backups complete" alone can't tell.

## 2026-09-23 (later) — Automation: pre-commit secret hook, weekly audit, project skills

Built so the recurring misses from this week stop depending on anyone
remembering them.

- **`.githooks/pre-commit`** runs gitleaks on staged changes and blocks the
  commit on a hit. `.gitleaks.toml` extends the default rules with an Uptime
  Kuma push-token rule — the defaults missed the real leak; the new rule
  finds it in history (committed 2026-05-09). Tested by staging a fake token:
  blocked, nothing committed. `install.sh` sets `core.hooksPath` on every
  clone; all three installers now install gitleaks. The hook warns and
  allows if gitleaks is missing, rather than bricking commits on a fresh
  machine.
- **`scripts/utils/homelab-audit.sh`** — repo-vs-live drift, containers down
  or unhealthy (skipping `restart: no` on-demand services), R2 backup success
  in the last day, DB dump age, disk usage, gitleaks on the last 8 days of
  commits, hook enabled. Cron'd Sundays 9AM through `run-with-notify.sh`, so
  a failure reaches Discord. First run: all green.
- **Project skills in `.claude/skills/`** (load only in this repo, not in
  other projects): `homelab-service` (add/remove checklist — staging, Glance,
  tunnel, backups, credentials, docs), `credential-rotation` (find and test
  every consumer; stop→edit→start for apps like LazyLibrarian; ALTER USER
  before `.env` for Postgres), `homelab-audit` (runs the script, then the
  judgment checks: full-history secrets, pinned images, stale credentials,
  docs vs reality).
- **Odysseus reads the same `SKILL.md` format natively** (`data/skills/<category>/<name>/SKILL.md`,
  plus a GitHub-URL importer), so these can be imported there. Claude Code
  agents have no direct Odysseus equivalent.

## 2026-09-23 — Public-repo secret audit

Ran `gitleaks` over all 492 commits (no leaks) and separately searched full
history for every specific secret value seen during recent sessions —
Transmission, Gmail app password, Vaultwarden admin token, the old reused
personal password, all *arr API keys, the R2 access key, the Discord webhook.
**None have ever been committed.**

One real find: the **Uptime Kuma push token** was hardcoded in
`rclone-backup.sh` (`HEARTBEAT_URL`). Anyone holding it can report the nightly
backup as healthy, which would hide a real failure. Moved to
`~/services/rclone/.env` (gitignored), placeholder in `.env.example`, script
now skips the ping with a warning if unset. Note: The old token is still in git
history — **regenerate it in Uptime Kuma** (the backup push monitor → reset
token) and update `.env`; that makes the leaked one worthless without
rewriting history.

## 2026-09-22 (power outage) — Auto-restart gap found, monitoring gap found, two research questions settled

**Power outage — Mac mini never came back on its own.** `pmset -g` showed
`autorestart 1` (restart-after-kernel-panic) but **`autorestartatconnect` was
never set at all** — the actual "power on when AC returns" setting is a
separate, easy-to-miss flag. Needs `sudo pmset -a autorestartatconnect 1`
(interactive password, so this is a command for the user, not something run
in-session).

**Warning:** This alone doesn't give full unattended recovery — FileVault is on.
Every cold power-on hits FileVault's pre-boot disk-password screen, which has
no unattended-unlock path in macOS. **Decided 2026-09-22: keep FileVault on.**
The trade-off was made deliberately — recovering from an outage still needs a
person physically present once, but every one of 30+ services' `.env`
credentials stays encrypted at rest if the machine is ever stolen. The
alternative (turn off FileVault for full auto-recovery) was rejected as the
wrong trade for a box holding that many live secrets.

**Important:** **Real gap found: Uptime Kuma and Discord alerting run on the same machine
that lost power.** Confirmed no external (off this network) monitor exists at
all. When the whole house loses power, nothing can alert about it, because the
alerter is also without power. Needs a genuinely external heartbeat service
(e.g. Healthchecks.io free tier) that expects a periodic ping *from* the Mac
mini and alerts when the ping stops arriving — the inverse of how Kuma
currently works. Tracked in `HOME_SERVER_TODO.md`.

**Settled, don't re-research: no custom OS exists for Kindle Scribe hardware.**
Asked after watching an e-ink tablet comparison video. Unlike Boox (commodity
Android SoC), Amazon's Scribe silicon has no alternative-OS path — the Vera
jailbreak + KOReader is the ceiling for this device. Full writeup in
`guides/BOOKS.md`. The honest trade-off if note-taking quality matters more
than this project's reading goal: a Supernote Manta is a genuinely better
writing device, but that's a second-device purchase, not a Scribe fix.

**Settled, don't re-research: stay on Paperless-ngx over Papra.** Papra is
lighter (1 container vs 2, ~524MB vs ~1.5GB) with a nicer UI, but **has no OCR
at all** — a hard blocker for a document-archive use case. Paperless-ngx also
has ~8x the community size. Revisit only if Papra ships OCR.

**Self-hosted music: no new service needed.** Checked — Jellyfin has no music
library configured yet and there's no music folder on the NAS, but Jellyfin
already natively supports music as a library type. Adding a `/Volumes/media/music`
folder and pointing Jellyfin at it as a new library is the whole task; no
Navidrome/Airsonic deployment needed unless a more music-specific UI is
wanted later.


## 2026-09-21 (later) — Email audit corrected, TODO resequenced

**Correction: the earlier email audit was wrong.** It checked container *environment
variables* and concluded only `kindle_sync.py` used email. Two more consumers
store their SMTP settings in **SQLite**, where an env check cannot see them:

- **Calibre-Web** — `smtp.gmail.com:587` in `/config/app.db`, for Send-to-Kindle
- **Uptime Kuma** — an active `smtp` notification in `/app/data/kuma.db`,
  alongside the Discord one

So revoking the Gmail app password breaks both. Calibre-Web has no fallback and
**fails silently**. `guides/EMAIL.md` now documents all three consumers, carries
a two-part audit command (env *and* database), and orders the runbook so both
are repointed and tested before the app password is revoked.

**Removed a stray container.** `relaxed_ritchie` (vaultwarden 1.35.4) was left
running from the `vaultwarden hash` debugging. Note: **Its pre-hash `ADMIN_TOKEN`
remained visible in the container config for ~4 hours**, readable by anything
that could run `docker inspect`. Container and its anonymous volume removed;
rotating the token is now step 3 of the TODO. Lesson recorded: `docker inspect`
exposes every container's full command line, so secrets must arrive on stdin to
a `--rm` container — and you must verify it actually exited.

**Found 212 cleartext passwords in `~/Downloads`** — unencrypted Bitwarden
exports from the Vaultwarden scare, never cleaned up. Now step 1.

**Resequenced `HOME_SERVER_TODO.md`** into an explicit 1–9 path with a table
saying *why* each step sits where it does, rather than competing numbered
sections. Older detail moved under "Detail and standing items". Refreshed the
SSD section (it had hit 15GiB/92%, not the 29GB recorded) and added the
warning that `docker image prune -a` would delete Storyteller.

## 2026-09-22 (later still) — Same credential bug hit a third service, plus a real find

Asked "will this hit other services too" after the Radarr/Sonarr fix — checked
rather than assumed:

- **LazyLibrarian had the identical bug**, and worse: its stored Transmission
  password was still the user's actual old, reused personal password (the
  same one flagged earlier in the credential migration project), sitting in a
  live config file rather than just a doc. Fixed — but the fix didn't stick on
  the first try: `docker restart` let LazyLibrarian flush its own in-memory
  config back to disk on shutdown, silently reverting the edit. Second attempt
  used `docker stop` → edit while fully dead → `docker start`, which held.
  Also deleted `config.ini.bak`/`.bak2`, which carried the same old password.
- **Bazarr, Jellyseerr, Prowlarr are unaffected** — confirmed each only stores
  API keys for Radarr/Sonarr/Jellyfin, never a Transmission login, so nothing
  in the credential rotation touches them.
- **Hardened LazyLibrarian's release filter** (`reject_words`) with the same
  `.exe/.scr/.msi/.bat/.cmd/.vbs/.jar/installer` terms added to Radarr/Sonarr
  earlier tonight — the malware-disguised-as-media risk applies to ebook/
  audiobook indexers exactly the same way.
- **Found a real, separate issue while checking:** `~/services/immich/.env`'s
  `DB_PASSWORD` is also the same old reused personal password — never rotated
  during the credential migration. Internal-only (not exposed outside the
  Docker network), so not fixed tonight at midnight without testing — the
  correct sequence (ALTER the Postgres user first, then update `.env`, or
  Immich's DB connection breaks entirely) is written out in
  `HOME_SERVER_TODO.md`.
- **Renamed `jellyfin-rescan.sh` → `smb-watcher-rescan.sh`** and extended it to
  also restart Audiobookshelf, which runs an identical watcher on an
  identically SMB-mounted library (`/Volumes/audiobooks`) — no confirmed
  failure yet, added preventively since the root cause is architectural.
- Added a standing warning to TODO step 6 (the credential migration pass):
  after rotating any password, grep every service's config for the old value,
  not just assume the one service you changed is the only consumer.

## 2026-09-22 (later still) — Finished download didn't appear in Jellyfin

Two separate gaps, not "just needed to wait":

1. **Radarr had the file on disk but hadn't registered it** (`hasFile: false`
   despite the `.mp4` already sitting in `/media/movies/`). Forced with
   `POST /api/v3/command {"name":"DownloadedMoviesScan"}` — resolved in
   seconds, so this one likely would have cleared on its own next scheduled
   check, just not instantly.
2. **Jellyfin never noticed the new file at all** — confirmed real, not a
   timing issue: `/Library/Refresh` needs auth (401, no key configured), and
   even after Radarr's import completed, zero scan/refresh activity appeared
   in Jellyfin's logs. This is the same class of limitation already
   documented for other services on this NAS — Jellyfin's real-time file
   watcher does not reliably see changes on an SMB-mounted share. Restarting
   the container (forces a full scan on startup) picked it up immediately,
   confirmed via `ffprobe` running against the exact file in the fresh logs.

**Added `scripts/utils/jellyfin-rescan.sh`**, cron'd every 30 minutes via the
existing `run-with-notify.sh` wrapper — restarts Jellyfin so this stops being
a manual step for every future download. This is the blunt fix (a few
seconds of playback interruption for anyone actively streaming, every 30
min); the surgical one is a native Radarr/Sonarr → Jellyfin "Connect"
integration that refreshes just the new item with no restart, gated on one
thing only a person can do — generate a Jellyfin API key in its dashboard.
Tracked in `HOME_SERVER_TODO.md`.

## 2026-09-22 (later) — Download pipeline was silently broken, then served malware

**Root cause of "requested movies never appear in Transmission":** Radarr and
Sonarr were both still authenticating to Transmission as `admin` with the old
password. The 2026-09-19 credential migration rotated Transmission to
the standard username + a new generated password, but never updated the *other
side* of that connection — each app stores its own separate copy of the
download client's login. Every release either app grabbed was silently
failing at the handoff with `Authentication Failure` / `downloadClientUnavailable`,
invisible unless you specifically checked Radarr's queue detail. Fixed both
via the API, verified each connection test passes clean.

**Important:** **While confirming the fix, one of the two retried releases turned out to
be malware.** A movie release from one of the Prowlarr indexers was a single
1.15GB `.exe` file — no
video container, no subtitles, nothing else in the torrent. Already 19%
downloaded (223MB) by the time it was caught. Real releases are never a bare
executable.

- Deleted the torrent and its data from Transmission
- Cleared a `.smbdelete*` remnant it left behind on the NAS (same SMB-can't-
  delete-an-open-handle issue documented elsewhere in this file)
- Blocklisted the release in Radarr via `DELETE /api/v3/queue/{id}?blocklist=true`
  (a raw `POST /api/v3/blocklist` call silently did nothing — the queue
  endpoint's blocklist flag is the one that actually works)
- Triggered a fresh search; a legitimate release should replace it

**Added a release profile to both Radarr and Sonarr** rejecting
`.exe .scr .lnk .msi .bat .cmd .vbs .jar`, `password.txt`, `setup.exe`,
`installer` in a release name — this class of fake release gets auto-rejected
before ever reaching a download client, not just cleaned up after the fact.

## 2026-09-22 — Removed Mealie and Grafana/Prometheus, verified the RAM claim

**Mealie:** confirmed 0 real recipes in the data directory despite the folder
existing — genuinely never used, not just forgotten about. **Grafana +
Prometheus + node-exporter:** confirmed Tailscale-only (never in
`~/.cloudflared/config.yml`, so no public exposure existed), zero scripts in
this repo read its data, and the login itself was already forgotten. Both
removed: containers stopped, `~/services/{mealie,grafana}` deleted, repo
entries removed, Glance homepage monitors/bookmarks/networks removed, the
`recipes.peciulevicius.com` tunnel ingress rule removed and verified (now
404s instead of hanging on a dead port), the dead `grafana/data/**` rclone
exclude removed. 42 → 38 containers.

**Found while restarting the tunnel: two competing cloudflared LaunchAgents.**
`brew services restart cloudflared` reported success but the real
traffic-serving process — started outside Homebrew, a separate
`com.cloudflare.cloudflared.plist` — never noticed the config change. Fixed
with `launchctl kickstart -k gui/$(id -u)/com.cloudflare.cloudflared`,
verified via PID/start-time change and a live curl to both a working and the
now-removed hostname. Documented in `HOME_SERVER_REFERENCE.md` so the next
tunnel edit doesn't lose 20 minutes to the same trap.

**Tested, did not just assume, whether this frees headroom for bigger Odysseus
models.** Loaded `qwen2.5:7b` before and after: swap still grew to 8.19GB
total (7.31GB used) post-removal, memory free still 22% — statistically the
same as the 23%/7.1GB swap measured earlier the same night. **The ~1.78GiB
reclaimed is a real, permanent baseline improvement, but it does not unlock a
larger model tier** — something else reabsorbed it. The ~8B ceiling in
`.claude/CLAUDE.md` stands unchanged.

## 2026-09-21 (actually final) — Immich offsite backup ran clean

**Flipped `BACKUP_IMMICH_PHOTOS=true` and ran it.** Verified R2 pricing live
against Cloudflare's own pricing page first ($0.015/GB-month, 10GB free, free
egress — matched what was already documented). Dry run predicted 72.4 GiB /
6,696 files; the real run landed exactly that, zero errors.

**First attempt crashed — self-inflicted.** Fixed the portainer.db/celerybeat
BadDigest bug (see above) by `cp`-ing the corrected script over the *live*
file while the backup was still running against it. Bash reads a script
incrementally; changing its length under a running interpreter corrupts its
read position, and it hit a syntax error a few steps later and died mid-run.
No data was lost — services/Obsidian/DB-dumps had already completed before
the crash, and Immich's own object count in R2 was confirmed at 0 before the
retry, so nothing was left half-written. **Lesson: never overwrite a script
file while it may still be executing** — wait for the run to finish, or write
to a temp file and `mv` it in atomically instead of `cp` in place. Restarted
clean; the second run went start to finish with no intervention.

Checked but did not yet act on: R2 API token scope (the setup docs never
directed scoping it to one bucket — should be verified/tightened in the
Cloudflare dashboard), Cloudflare account 2FA (not tracked in the credential
checklist at all despite controlling DNS/Tunnel/Email/R2), Nextcloud's actual
user files (83MB, currently fully excluded from any backup), and audiobooks
(18GB, would add ~$0.28/month to enable the same way as photos).

## 2026-09-21 (final) — Fixed live drift instead of just flagging it, caught a stale setup guide

**Went back and actually fixed what the drift sweep found**, rather than
leaving it as a footnote. `jellyfin`, `transmission` and `sonarr-radarr`'s live
`docker-compose.yml` still defaulted `MEDIA_DIR` to `/Volumes/T7/media` (dead —
`.env` already overrides it to the NAS on all three, confirmed before touching
anything) — re-staged from the repo, which already had the right default.
**Immich's live config used a hardcoded `TZ: Europe/Vilnius` env var** where
the repo bind-mounts `/etc/localtime:ro` (portable, follows the host
automatically). Applied the repo version, recreated `immich_server`, and
verified the container's clock still matches the host exactly post-recreate.

**Found `HOME_SERVER.md` describes an architecture that stopped existing on
2026-08-04.** It's the linked "set up a new Mac mini from scratch" guide, and
it still tells a reader to `mkdir -p /Volumes/T7/media`, point Immich's
Postgres/upload/model-cache at a T7 volume, and put Calibre books on T7 — the
pre-NAS-migration setup, when T7 was primary storage instead of a decoupled
manual backup target. Three other docs (`SERVICES.md` ×2, `UTILITY_SCRIPTS.md`)
linked to it as "the backup strategy," which meant the actually-current backup
facts in `HOME_SERVER_REFERENCE.md` weren't where a reader would land. Added a
banner to the top of `HOME_SERVER.md` making the historical status explicit and
pointing at current docs, repointed all three stale links, and updated
`START_HERE.md`'s index row and `.claude/CLAUDE.md`'s file list to match. A full
rewrite of the ~750-line body against the NAS architecture is tracked as its
own item in `HOME_SERVER_TODO.md` — too large to do as a drive-by fix.

## 2026-09-21 (later still) — Offsite photo backup plan, fastembed cache leak fixed

**Added an opt-in cloud offsite copy of Immich originals.** `rclone-backup.sh`
gets a new Backup 5, guarded by `BACKUP_IMMICH_PHOTOS` (default `false`):
`/Volumes/immich/upload/upload` (~73GB) → R2 `peciulevicius-backups/immich-photos`.
Excludes `encoded-video/` and `thumbs/` (regenerable by Immich) and `backups/`
(Immich's own DB snapshot, already redundant with the `pg_dump` of
`immich_postgres` that Backup 3 ships separately). Left off by default on
purpose — turning it on hands the next cron run a multi-hour first upload and
moves the R2 bill from $0 to ~$1/month; the TODO now has the exact commands to
enable it deliberately, by hand, before it ever reaches a cron run. This is a
second, complementary offsite layer alongside the existing T5-to-parents'-house
plan, not a replacement for it.

**Found and fixed a real leak while testing the above.** A `--dry-run` of the
existing Backup 1 (services configs) showed `.incomplete` partial model blobs
from `odysseus/data/fastembed_cache/` being swept into the backup — a cache
directory the existing huggingface/local excludes didn't cover. Added the
exclude; same regenerable-cache class as the other two, ~97MB.

## 2026-09-21 — Local model benchmarks, disk cleanup, email runbook

**Models.** Benchmarked all three local models on the same real training
question, 100% GPU via native Ollama. `qwen2.5:7b` (20.1 tok/s, 4.8 GB) is the
only one that engaged with the numbers in the question — it becomes the chat
default. `llama3.2:3b` (42.9 tok/s, 2.5 GB) is twice as fast but shallow, so it
takes Odysseus's background calls (titles, tagging). **Removed `qwen3:4b`** —
dominated on both axes: 2445 tokens and 80s to answer what the 7B answered in
479 and 30s. Ollama's `"think": false` does not suppress reasoning cleanly.

**Cookbook ruled out permanently.** Docker on macOS has no GPU passthrough, so
Cookbook scans the *container*, not the M4 — it reports `No GPU`, rates 1.5B
models "PERFECT" and offers 70 GB downloads. Verified no stray download ever
landed: `data/huggingface/` is 72 KB and the writable layer 74.8 MB.

**Disk was at 92%** (15 GiB free), not the ~29 GB previously recorded. Freed
6.05 GB of Docker build cache and 477 MB of Homebrew cache → **22 GiB**.
**Note:** Learned: the 2.77 GB "unused" image is **Storyteller**, merely stopped —
`docker image prune -a` would have deleted it. Dangling-only reclaimed 0 B.

**Email audit.** Checked all 43 containers and every script: `pkm/kindle_sync.py`
is the **only** consumer of email (IMAP). Uptime Kuma and `notify.sh` use
Discord webhooks; **no container has SMTP configured**. So the Purelymail
migration breaks nothing — it is a 3-line change in one gitignored file.

**Wrote [guides/EMAIL.md](./guides/EMAIL.md)** — a from-cold runbook: the four
moving parts, provider comparison with the IMAP requirement that eliminates
Proton/Tuta/Zoho, the signup dropdown gotcha (it is the *admin user's* address,
not your domain), all seven DNS records, rollback via re-enabling Email Routing,
verification commands, and the permanent Gmail funnel for contacts who have the
old address. Fixed stale status rows in `START_HERE.md` (Odysseus listed as
"not started") and `DEGOOGLE.md` (email listed as "not started").

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

**Warning:** Cookbook caveat worth remembering: upstream's compose says *"Inside
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

**Note:** Playback **speed** does nothing on Kindle — upstream implements `setSpeed`
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

**Note:** The ~4GB figure is for alignment, not idle, and that is the same headroom
Odysseus is earmarked for on a host already swapping 4.1GB. Batch use only.

**Note:** Media Overlay support in `audiobook.koplugin` is still *work in progress*, so
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

**Note:** Learned the hard way: **`crontab <file>` silently installs an empty crontab**
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

**Note:** Worth knowing: LazyLibrarian has **0 books downloaded** too (47 known, 1
author). The pipeline is configured, not proven.

Data directories for karakeep (238MB), actual-budget (80KB) and readarr (49MB)
were moved out of `~/services/` to `~/.Trash/homelab-removed-20260919/`.

### Credential policy set, first two services rotated

Username standardised on **one non-default name** (not `admin` — the first username
every automated attack tries). Passwords split into two kinds: one memorised
passphrase for the Vaultwarden master, generated random for everything else,
with a six-word passphrase reserved for the one password actually typed by hand
on a phone (CouchDB in the LiveSync plugin).

Rotated and verified: **Vaultwarden master password** (by hand), **CouchDB**
(standard username + 32-char random — old credentials rejected, `obsidian`
database intact, anonymous requests 401 on every path including `/`) and
**Transmission** (standard username + 28-char random).

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

**Note:** Discovered while planning it: `ADMIN_USER` / `GRAFANA_USER` in the other
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

**Note:** Worth noting the underlying rule this bumps into: `metadata.db` is SQLite
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

Also found **two Nextcloud accounts**: the standard one, and a second `admin`
whose display name is confusingly the same as the standard username.

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

**Note:** Do not bind-mount `local.ini` into `/opt/couchdb/etc/local.d/`. The stock
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

**Status (Jul 2026):** NAS arrived (UGREEN DH4300 Plus, warranty until 2028-07). Drives ordered — 3× IronWolf Pro 6TB recert (ST6000NE000) €230 each from [datablocks.dev](https://datablocks.dev), preorder arriving **~Jul 27–31**.

**Done (pre-drives, Jul 22):**
- [x] NAS on network at 192.168.1.73 via WiFi extender ethernet port (100Mbps — extender is the bottleneck, acceptable for now)
- [x] `nas.peciulevicius.com` → UGOS Pro web UI, via existing cloudflared tunnel on Mac mini (ingress: `http://192.168.1.73:9999`). No Docker needed on NAS.
- [x] UGREENlink remote access active (fallback access path; link kept in Vaultwarden)

**Still to do (pre-drives):** moved to `HOME_SERVER_TODO.md` → "NAS — remaining
follow-ups" (the NAS UI settings) and "Router DHCP reservation for the NAS"
(MAC in the router's client list). Tracked there, not here — this file is finished
work only. The reservation is no longer load-bearing: everything addresses the
NAS by mDNS (`DH4300PLUS-DP.local`) since 2026-09-05.

**Migration done (2026-08-04)**
- [x] RAID 5 pool created (3× 6TB IronWolf Pro = ~11TiB usable), Btrfs
- [x] SMB on; shares: `media`, `immich`, `audiobooks`, `books`, `unsorted`; service account `macmini` (ASCII name — a non-ASCII character in the personal admin account name breaks SMB auth)
- [x] Tailscale via Docker container on NAS (`ugreen-nas`, 100.95.228.35) — remote SMB/Finder
- [x] Full copy T7 → NAS (~680GB incl. 142G photo archives → `unsorted`), zero errors
- [x] All services switched to NAS paths (`/Volumes/media` etc.); Immich Postgres moved to internal SSD (`~/services/immich/data/postgres`) — DBs must not live on SMB
- [x] Reboot-proof mounts: `scripts/utils/mount-nas.sh` + `com.peciulevicius.mount-nas` LaunchAgent
- [x] Glance tile for NAS

---

### ~~1. Calibre-Web — finish setup~~ — done (2026-05-09)

Bookshelves skipped (not needed). Send to Kindle configured via Gmail SMTP — the device's `@kindle.com` address approved and working.


### ~~2. Uptime Kuma notifications~~ — done (2026-05-09)

Gmail SMTP configured (smtp.gmail.com:465, app password). Email alerts working.


### ~~5. Set up Obsidian vault sync via Syncthing~~ — done (2026-05-08)

`obsidian-vault` folder shared in Syncthing across Mac mini, MacBook, and iPhone. Real-time sync working.



### ~~8. Bazarr — subtitle provider~~ — done (2026-05-09)

OpenSubtitles.com configured, Default language profile set with English. Applied to all series and movies. 71 Wanted items queued — downloading automatically.


### ~~13. Show Mac host stats in monitoring~~ — done (2026-05-07)

Homebrew node_exporter running at port 9100, scraped by Prometheus (`job="mac-host"`). Custom Grafana dashboard (`mac-host.json`) provisioned — shows real 16GB RAM, swap, CPU, disk, network. Glance `server-stats` widget updated to show actual host figures.


### ~~14. Uptime Kuma — rclone backup heartbeat~~ — done (2026-05-09)

Push monitor added in Uptime Kuma. Heartbeat URL wired into `rclone-backup.sh` — pings up on success, down on failure. R2 backup verified working across all 4 targets.


### 15. ~~Migrate backups from B2 to Cloudflare R2~~ — done (2026-04-22)

Migrated to Cloudflare R2. Nightly rclone backup running at 5am. R2 at ~1.3GB (critical-only: vaultwarden, paperless docs, obsidian vault, db dumps, calibre books). B2 bucket purged and can be deleted from Backblaze dashboard.


### ~~16. Docker VM resource limits~~ — done (2026-07-23)

Docker Desktop VM bumped from 7.8GB → 10GB RAM, swap 1GB → 2GB (via
`settings-store.json`). Also enabled AutoStart so Docker launches on login
after a reboot/power cut. All 40 containers verified back up, key services
responding (photos/vault/home/watch/nas all 200).

---


### ~~17. Kindle Scribe → Obsidian automation~~ — done (2026-05-08)

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


### ~~19. T7 → T5 full backup~~ — done (2026-07-09)

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
| NAS fails | T7 + T5 | T7 + T5 | T7 + T5 + R2 | R2 |
| A drive fails | re-run `backup-external.sh` | same | same | R2 |
| Fire/theft | nothing offsite (all in one room) | nothing offsite | R2 | R2 |

**The real remaining gap:** both external drives sit next to the NAS, so nothing survives
fire, flood or theft. Moving T5 offsite is what makes this genuinely 3-2-1.


---

## Done

- [x] ~~Books & audio automation (Jul 2026)~~ — LazyLibrarian fully configured: 4 Torznab indexers via Prowlarr, Transmission download client, PostProcessor auto-moves EPUBs to Calibre and MP3s to Audiobookshelf. Click "Wanted" → fully hands-off. See `docs/guides/BOOKS.md` for setup notes and gotchas.

- [x] ~~Kindle library → Calibre-Web (Apr 2026)~~ — ~30 purchased books converted to EPUB and imported into Calibre-Web
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
- [x] ~~Kindle library → Calibre-Web (Apr 2026)~~ — ~30 purchased books converted to EPUB in Calibre and synced to the Mac mini Calibre-Web
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
- [x] ~~Linkwarden~~ — setup complete, browser extensions installed (Chrome; Brave needs Shields disabled for the site), phone PWA added
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

