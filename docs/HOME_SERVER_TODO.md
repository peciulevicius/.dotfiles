# Home Server — TODO

Outstanding work only. Finished items live in
[HOME_SERVER_CHANGELOG.md](HOME_SERVER_CHANGELOG.md).

👤 = needs you (a UI, a device, a password or a decision). Unmarked = Claude
can do it in a session. Last truth pass: **2026-09-25** — every open item was
checked against the live system; done items moved to the changelog.

---

## 🔝 Next up (2026-09-25) — switch mail consumers off Gmail

1. [ ] 👤 Save the `dziugas@` password (Terminal.app, not chat):
   ```bash
   mkdir -p ~/.config/homelab && read -rs "P?dziugas@ password: " && printf 'PM_USER=dziugas@peciulevicius.com\nPM_PASS=%s\n' "$P" > ~/.config/homelab/purelymail.env && chmod 600 ~/.config/homelab/purelymail.env && unset P && echo saved
   ```
   (Checked 2026-09-25: `~/.config/homelab/purelymail.env` does not exist yet.)
2. [ ] Run `~/.dotfiles/scripts/utils/mail-switch-purelymail.sh` — tests IMAP
   login, repoints `pkm/config.py` (kindle_sync) and Kuma's SMTP notification
   (~10 s Kuma downtime), backs up both, never prints the password. Then Kuma →
   "Uptime Kuma" notification → **Test**. (Claude, after step 1. Checked
   2026-09-25: kindle_sync still logs `imap.gmail.com`; Kuma's "Uptime Kuma"
   notification still points at Gmail.)
3. [ ] 👤 Calibre-Web (password is encrypted in `app.db`, so UI only): Admin →
   Edit E-mail Server Settings → `smtp.purelymail.com`, 465, SSL/TLS, login +
   from `dziugas@peciulevicius.com` → Save → Test. (Still `smtp.gmail.com:587`
   on 2026-09-25.)
4. [ ] 👤 Revoke the Gmail app password (Google Account → Security → App
   passwords). ⚠️ It was printed in a Claude session on 2026-09-25 (and to a
   terminal on 2026-09-21) — don't postpone this.
5. [ ] 👤 Kindle exports keep going to **Gmail** (the Amazon account email) until
   the account-email pass below. So kindle_sync still sees them after step 2,
   add a **Gmail filter**: `from:do-not-reply@amazon.com subject:"from your
   Kindle"` → Forward to `dziugas@peciulevicius.com` (Gmail asks you to confirm
   the forwarding address — the code lands in `dziugas@`). Or pick the saved
   `kindle@peciulevicius.com` address on the Scribe share screen each time.
   Export format: *Convert to text (TXT)* + *✓ Attach searchable PDF*.

---

## 🧭 Who does what — index of every open item

Section names in *italics* are headings below.

### 👤 Needs you (UI / device / credentials / decision)

- Purelymail password file, Calibre-Web SMTP, revoke Gmail app password, Gmail→Kindle filter — *🔝 Next up* 1, 3, 4, 5
- Coach: upload skill zip, add the `tp-mcp` custom connector in claude.ai, "Coach" Project — *🏃 Coach in the Claude app*
- Website: `supabase login` + DB password, `checkOrigin` decision, Pages → Worker move; janioniu: commit your local TODO edits, confirm placeholder facts with Dad, Purelymail domain — *🌐 Other repo backlogs* and below
- Gravatar, branded signature, Google account photo — *✉️ Email identity*
- T7 external backup run — *📋 Open user steps*
- Email: catch-all, inbound test, iPhone Mail, deliverability / mail-tester — *📋 Open user steps*
- Reset Odysseus 2FA; first coaching session in Odysseus — *⚡ Batch 2026-09-24*
- Move TOTP off Google Authenticator — *2. Move TOTP off Google Authenticator*
- Rotate the Vaultwarden admin token (Claude can do the hash + `.env`; you save it) — *3. Rotate the Vaultwarden admin token*
- Credential + email pass per service, NAS account passwords, `~/credentials-import.md` — *6. One pass per service*
- Vaultwarden Chrome extension on the work laptop — *7. Vaultwarden Chrome extension*
- Odysseus: chat-history exports, ChatGPT memories by hand, API balance/top-up check, save admin password to Vaultwarden — *8. Odysseus*
- MacBook: gitleaks hook + `sync.sh`, re-auth Tailscale (key expired 2026-09-02) — *8a. Public-repo hygiene*
- R2 token scope, Cloudflare account 2FA — *8b. Cloudflare/R2 security check*
- `pmset autorestartatconnect`, UPS decision, NAS auto power-on — *8c. Power outage recovery*
- notebook.koplugin, Supernote, Jellyfin music + API keys, Nextcloud/Paperless keep-or-remove — *9. Maintenance backlog*
- Kindle wallpapers, KOReader speed workaround, `.smbdelete` cleanup, `read-along` tag, OTA check, Searchable PDF test — *Quick wins left over from 2026-09-20*
- LiveSync plugin on each device — *🔗 Obsidian LiveSync*
- DB-dump retention — *💾 Disk*
- T5 offsite trip — *Get one copy of the photos out of the building*
- Immich missing thumbnails job — *Regenerate missing Immich thumbnails*
- KOReader OPDS + Calibre-Web shelf check — *Move the Calibre library off SMB onto the SSD*
- What T5 is for — *External backups are manual now*
- Router DHCP reservation — *Router DHCP reservation for the NAS*
- Pi-hole: Caddy decision, router DNS — *Pi-hole — finish the deployment*
- Old photo archives into Immich (needs T7 + judgement) — *Import old photo archives into Immich*
- Paperless tags/types — *Paperless-NGX — organise documents*
- Brave Shields for Linkwarden — *Linkwarden*
- VPN provider pick — *VPN for torrents*
- Capture Shortcut, Web Clipper, 30-day habit, Kindle/KOReader items — *Notes*
- "Sign in with Google" audit, Gmail redirect decision, Takeout — *De-Google*
- Calendar + Contacts to Nextcloud — *Calendar + Contacts*
- Phone: battery, ADP, search/browser, Pixel checks — *Phone* and *Quick wins* (De-Google)
- NAS UI settings, stale NAS folders, drive sleep — *NAS — remaining follow-ups*

- janioniuvynuogynas.lt is live (404 fix + `www` redirect in PR #6, see
  changelog). Open there (add to that repo's TODO when its uncommitted edits
  are sorted):
  - 👤 placeholder phone `+370 600 00 000` and other facts are now on the real
    domain — confirm with Dad
  - 👤 your local checkout has uncommitted `docs/TODO.md` + `environments.md`
    edits and is now behind `main` (PR #5 touched TODO.md) — commit/stash, then
    `git pull`

- 👤 janioniuvynuogynas.lt email: **add the domain to the existing Purelymail
  account** (no extra cost) instead of Cloudflare Email Routing → Gmail; create
  `info@janioniuvynuogynas.lt` (or route it to whoever answers). Claude adds the
  Purelymail DNS records afterwards (zone and token are in place). Resend
  keeps using `send.janioniuvynuogynas.lt`, so no MX clash. Supersedes the
  "Email Routing → your Gmail" line in that repo's TODO step 3.

- 👤 **Phone apps** — connect Reeder (set FreshRSS API password first),
  Swift Paperless, Linkwarden, Pi-hole Remote (create an app password) —
  step-by-step table in `SERVICES.md` → *Connecting each app*. Finamp waits for
  the music library; Nextcloud app waits for the keep-or-remove decision;
  Amperfy dropped (Subsonic-only). Also install: Bitwarden, Ente Auth,
  Obsidian + LiveSync, ntfy, Swiftfin/Infuse, Odysseus home-screen web app.

- 👤 Ad blocking anywhere: Tailscale DNS → Pi-hole (`100.81.171.49`, override local DNS); Brave iOS/AdGuard for YouTube — *Pi-hole → Ad blocking everywhere*

- 👤 janioniu: Cloudflare → Workers & Pages → `janioniu-vynuogynas` → Settings →
  **Build** → turn off production deploys from Workers Builds (keep PR
  previews). Right now every merge deploys twice and the Workers Builds copy
  has no build vars — a race. Then submit one real contact form to confirm
  Resend/Loops keys work (secrets now sync on each GitHub Actions deploy).

### 🤖 Claude can do next

- Run `mail-switch-purelymail.sh` once the password file exists — *🔝 Next up* 2
- Website: apply `v1.5.0` via `supabase db push` (after your login), merge PR #46 (after the Worker move) — *🌐 Other repo backlogs*
- Optional: OpenCode + `qwen2.5-coder:7b` for offline snippets — *⚡ Batch 2026-09-24*
- Odysseus: chat-export import, CalDAV after Nextcloud, RAG over Paperless + Linkwarden — *8. Odysseus*
- Rotate Immich's DB password (restarts Immich — say go) — *9. Maintenance backlog*
- `rm -rf ~/services/mealie ~/services/grafana` (say go) — *9. Maintenance backlog*
- Pi-hole local DNS records, only after a Caddy decision — *Pi-hole — finish the deployment*
- Optional `scp` push to the Scribe — *Notes*
- Gluetun compose once a VPN provider is picked — *VPN for torrents*
- Major-version image upgrades, one per sitting — *21 pinned images*
- Calibre follow-ups: backup log check (2026-09-26), NAS copy removal
  (~2026-10-02) — *Move the Calibre library off SMB onto the SSD*

---

## 🌐 Other repo backlogs

- `~/dev/peciulevicius.com/docs/TODO.md` — open there: 👤 Supabase CLI login +
  DB password → Claude applies `v1.5.0` via `supabase db push`; 👤 decide
  `checkOrigin` (one-click unsubscribe); 👤 Pages → Worker move, then Claude
  merges **PR #46** (Astro 7 + Tailwind 4); newsletter end-to-end test.
- `~/dev/janioniu-vynuogynas/docs/TODO.md` — live at
  https://janioniuvynuogynas.lt since 2026-09-25 (PRs #5 + #6 merged). Still
  open: Astro 7 (critical audit advisory), placeholder phone, Resend setup.
  Your uncommitted edits in `docs/TODO.md` + `docs/environments.md` there
  still need committing.

## 🏃 Coach in the Claude app / phone — walkthrough with Claude

- [ ] 👤 Upload `config/claude/skills/adaptive-endurance-coach/` (zip) in
      claude.ai → Settings → Capabilities → Skills.
- [ ] 👤 claude.ai → Connectors → Add custom connector →
      `https://tp-mcp.peciulevicius.com/mcp`; confirm `tp_auth_status` from the
      phone. Check the official Strava connector is enabled. (Fallback OAuth
      client id is in your chat with Claude, not in this repo.)
- [ ] 👤 Claude Project "Coach" with the skill + pinned summary (the app can't read
      `~/.training`).

## ✉️ Email identity

- [ ] 👤 Gravatar: logo on `hello@peciulevicius.com`, own photo on
      `dziugas@peciulevicius.com`.
- [ ] 👤 Install the branded signature (from `peciulevicius.com/email/signature`
      once deployed) in Odysseus, iPhone Mail, Purelymail webmail. Keep it a
      light HTML *signature*, not a heavy template — image-heavy mail scores
      worse with spam filters.
- [ ] 👤 Decide on a Google account photo for Gmail recipients (conflicts with
      de-Googling — default: no).

---

## ▶ The ordered path

**The order matters** — each step unblocks or de-risks the next. The reasoning
is written out so it survives being read cold in a year.

| # | Step | Why it is here and not later |
|---|---|---|
| **2** | 🔴 Move TOTP off Google Authenticator | Seeds sync to the account being left — lockout risk |
| **3** | 🔴 Rotate the Vaultwarden admin token | Leaked into a container config on 2026-09-21 |
| **5** | 🔁 Repoint the 3 Gmail consumers, then revoke | Two of them fail **silently** — now tracked in 🔝 Next up |
| **6** | 🔑 One pass: password + email per service | Same ~14 logins — separating them doubles the work |
| **7** | 🧩 Vaultwarden Chrome extension | Blocked on the work laptop, not on us |
| **8** | 🤖 Odysseus history import | Pure upside, nothing depends on it |
| **8a** | 🔐 MacBook hook + Tailscale re-auth | Kuma token rotated, fingerprint ignored 2026-09-25 |
| **9** | 🧹 Pinned images, SMB, wallpapers | Maintenance backlog |

---

### ⚡ Batch 2026-09-24 — one-day push (subagents in parallel)

Finished parts (Odysseus repair, Claude config, HOME_SERVER.md rewrite, Kuma
token, email DNS cutover, coach build) are in the changelog.

- [ ] 👤 **Reset Odysseus 2FA** (TOTP + backup codes) — exposed in a session
      transcript 2026-09-23 while auditing `data/auth.json`. Not verifiable
      from outside without reading the secret; tick it yourself when done.
- [ ] 👤 **AI coach — first coaching session in Odysseus.** Everything else is
      built and connected (TrainingPeaks 85 tools, Strava 11 tools,
      `~/.training` mounted). Not in the claude.ai app/phone until the
      *Coach in the Claude app* steps are done — use Odysseus over Tailscale on
      the phone meanwhile.
- [ ] Optional, local models: no bigger model (RAM ceiling ~8B). OpenCode +
      `qwen2.5-coder:7b` for offline snippets only; point Odysseus's **Agent
      (OpenCode)** at Ollama for private or throwaway coding; keep Claude Code
      for real work.

### 📋 Open user steps — as of 2026-09-25

- [ ] 👤 **T7 external backup** — plug in the T7, run
      `~/.dotfiles/scripts/backup/backup-external.sh /Volumes/T7`, unplug.
      The weekly audit fails until the first run is stamped
      (`~/logs/external-backup-T7.last`), then again whenever it's >30 days
      old — that's the reminder. Same for T5 before it goes offsite.
      (No stamp yet on 2026-09-25.)
- [ ] 👤 **Email** — DNS + MX live on Purelymail 2026-09-25, Email Routing
      disabled, domain saved, `dziugas@` user created. Remaining:
      1. Purelymail → Routing → catch-all `*@peciulevicius.com` → `dziugas@`.
      2. Test: mail `inbox@peciulevicius.com` from Gmail, check webmail.
      3. Repoint kindle_sync / Calibre-Web / Kuma SMTP (EMAIL.md §7), revoke
         the Gmail app password, iPhone Mail, Gmail forward. → consumers and
         revoke are tracked in 🔝 Next up; 👤 iPhone Apple Mail + Sieve filters
         and the Gmail redirect decision (*De-Google → Email*) stay here.
      4. Deliverability: first mails to Gmail landed in Spam (new domain, no
         reputation; SPF/DKIM/DMARC all pass). Mark *Not spam*, add
         `dziugas@` to contacts, keep sending real mail; check once with
         mail-tester.com (aim ≥ 9/10).
      ⚠️ `peciulevicius@purelymail.com` (admin) and `dziugas@peciulevicius.com`
      are **separate mailboxes** — log clients in as `dziugas@`, not the admin.

### 2. 🔴 Move TOTP off Google Authenticator — before any password change

**The single highest-risk item in the whole de-Googling effort.** Google
Authenticator syncs its TOTP seeds to the Google account being abandoned. Every
service whose 2FA lives there is one account-loss away from being unreachable.
It's phone work — no Mac mini needed.

- [ ] 👤 Google Authenticator → ⋯ → Transfer accounts → **Export accounts**
      (its built-in transfer QR)
- [ ] 👤 Import into **Ente Auth** (open source, E2E, cross-platform) — or
      **Vaultwarden**, which unlocks Bitwarden premium TOTP free when
      self-hosted, at the cost of keeping both factors in one vault. See
      [guides/DEGOOGLE.md](guides/DEGOOGLE.md)
- [ ] 👤 Verify several logins end-to-end with the new app **before** deleting
      anything
- [ ] 👤 Keep Google Authenticator installed for a month, until every seed is
      confirmed working

> ⚠️ Do this **before** step 6. Changing passwords across 14 services while 2FA
> still depends on Google means a single lockout takes all of them at once.

### 3. 🔴 Rotate the Vaultwarden admin token

On 2026-09-21 a throwaway container (`relaxed_ritchie`, vaultwarden 1.35.4) was
created to run `vaultwarden hash`. **The pre-hash admin token stayed visible in
its container config for ~4 hours**, readable by anything that could run
`docker inspect`. The container has been removed, but the token should be
treated as disclosed.

- [ ] 👤+Claude Generate a new `ADMIN_TOKEN`, hash it, update `~/services/vaultwarden/.env`
- [ ] `docker compose up -d` and confirm `/admin` accepts only the new one
- [ ] 👤 Save it in Vaultwarden itself

> 💡 Lesson: `docker inspect` exposes the full command line of every container,
> including secrets passed as arguments. Pipe secrets via stdin to a container
> started with `--rm`, and verify it actually exited.

### 5. 🔁 Repoint the three Gmail consumers — then revoke

**Tracked as 🔝 Next up** at the top. Background kept here because it's the
part that's easy to get wrong: **three things use Gmail, and two hide their
config in SQLite** rather than environment variables, so an `env`-based audit
reports "nothing uses email" and is wrong (the 2026-09-21 audit made exactly
that mistake). Full detail in [guides/EMAIL.md](guides/EMAIL.md) §2.

- `pkm/kindle_sync.py` — `IMAP_SERVER`, `EMAIL_ADDRESS`, `EMAIL_PASSWORD` in
  `pkm/config.py` (gitignored, Mac mini only).
- **Calibre-Web** — 🔴 **fails silently** and has no fallback; use its *Send
  test email* button after the change.
- **Uptime Kuma** — the `smtp` notification. Its Discord notification is
  unaffected, so alerting stays audible throughout.
- **Only then** revoke the Gmail app password at
  <https://myaccount.google.com/apppasswords>.

### 6. 🔑 One pass per service — password AND email together

Both changes need the same ~14 logins. **Doing them separately means 28.**
Checklist, no secrets: [CREDENTIAL_MIGRATION.md](CREDENTIAL_MIGRATION.md) —
4 of ~18 services done. Worksheet with real values: `~/credentials-import.md`
(deliberately outside this public repo; still present 2026-09-25).

**The rule: one unique generated password per service, master copy in
Vaultwarden** (decided 2026-09-19: one non-default username everywhere; one
memorised passphrase for the Vaultwarden master, generated random for every
service). ⚠️ `rclone-backup.sh` **excludes every `.env`** from R2 — a restore
gives configs with no secrets. **Vaultwarden is the only copy.**

Per service, one visit: log in → Bitwarden-generated password saved **with the
autofill URL** → change address to `<service>@peciulevicius.com` → confirm the
verification mail arrives (this also proves catch-all works) → tick it off.
Critical accounts first: Apple ID, banks, GitHub, Cloudflare, Stripe.

- [ ] 👤 Transcribe the three pending passwords from `~/credentials-import.md`
      (CouchDB, Transmission, Pi-hole) plus the Gmail app password, then `rm`
      that file when the list is exhausted
- [ ] 👤 Work down the checklist
- [ ] 👤 ⚠️ **Retire the old reused personal password.** It was in use across
      many services; treat any account still on it as compromised-by-reuse
      until rotated. The string is deliberately not recorded in this repo.
- [ ] 👤 Several services use **the Gmail address as the login itself** —
      Vaultwarden, Immich, Linkwarden. Those logins change in this pass.
- [ ] 👤 ⚠️ **Change Vaultwarden's own address LAST** — it is what recovers all
      the others; do not move it while still depending on it
- [ ] 👤 Both NAS accounts still share a password with elsewhere:
      - [ ] personal admin (web UI) — generate in Bitwarden, update entry
      - [ ] `macmini` (SMB) — after changing on the NAS, update the saved
            credential in macOS Keychain on the Mac mini (Finder prompts on next
            mount; remount the four shares)
- [ ] 👤 Bitwarden **Vault Health** report → clear the remaining reused-password
      flags

⚠️ **Only Vaultwarden's master, CouchDB, Transmission and Pi-hole could be
changed from a file (all done — changelog); everything else cannot.** Init-only env vars are
inert once the account exists (`ADMIN_USER` / `GRAFANA_USER` included — renames
happen in each app's UI), and app accounts are salted hashes. Nextcloud,
Paperless and FreshRSS have CLI resets; the rest are UI only. Commands are in
`~/credentials-import.md`. Leave internal database roles alone
(`DB_USERNAME=postgres` and friends) — change the app's *login*, not the role.

⚠️ **After rotating any password, check every OTHER service that stores its own
copy of that login.** Real example, 2026-09-22: Transmission's password was
rotated 2026-09-19, but Radarr, Sonarr *and* LazyLibrarian each keep their own
copy of Transmission's login. All three silently failed authentication for
three days. `grep -rl "<old value>" ~/services/` after any rotation is cheap
insurance. The `credential-rotation` skill encodes this.

### 7. 🧩 Vaultwarden Chrome extension on the work laptop

Still broken after the 1.37.3 upgrade fixed iOS. **The extension has never once
registered with the server** — no device type 2 in the database — which points
at the corporate network, not at Vaultwarden.

- [ ] 👤 Open `https://vault.peciulevicius.com` in a plain tab on that laptop
      first. If the page does not load, it is network policy and the extension
      was never going to work
- [ ] 👤 If the page loads, re-check the extension's self-hosted URL field

### 8. 🤖 Odysseus — configuration, not deployment

Running on **7001** (7000 is AirPlay Receiver), Tailscale-only at
`http://100.81.171.49:7001` — **no public hostname, deliberately** (it holds
health/finance history and its agent executes code). Cloud models: default
`claude-opus-5-5`, task/utility `claude-haiku-4-5-20251001`, Anthropic
endpoint; native Ollama kept for short, tool-free chats. Why cloud:
[services/odysseus/README.md](https://github.com/peciulevicius/.dotfiles/blob/main/services/odysseus/README.md)
"Which model for which job". Full plan: [guides/SELF_HOSTED_AI.md](guides/SELF_HOSTED_AI.md).

- [ ] Later: point RAG at Paperless + Linkwarden too (the vault is indexed):
      a small model over *your* documents beats a big model that has never
      seen them.
- [ ] 👤 **Bring Claude + ChatGPT history home.** Memories were imported
      2026-09-24 (131, 12 pinned); chat *history* was not.
      - [ ] 👤 Export both (ChatGPT: Data Controls → Export; Claude: Privacy → Export)
      - [ ] 👤 Copy ChatGPT *memories* by hand — they are **not** in the export
      - [ ] Check whether Odysseus already ships a ChatGPT importer before
            writing `scripts/ai/import-chat-history.py`
      - [ ] Keep raw exports at `/Volumes/unsorted/ai-exports/`, add to
            `rclone-backup.sh`, point RAG at the archive
- [ ] 👤 Anthropic console: confirm a **low balance and auto-top-up off**, so a
      leaked key or runaway agent loop can't drain it (API billing is separate
      from Claude Pro).
- [ ] 👤 Save the Odysseus admin password + API key to Vaultwarden
- [ ] Wire Odysseus's **CalDAV** sync to Nextcloud Calendar — after
      *Calendar + Contacts* is done
- [ ] 👤 🔒 Habit: health, finances and journal go to the local model where
      possible. Cloud gives sovereignty over the record, not privacy from the
      provider. (The coach is the deliberate exception — it needs cloud tool
      use.)

Notes, not tasks: Gemini/OpenAI keys only if a concrete gap appears. No model
above ~8B (16GB shared with ~40 containers). **Decided against OpenRouter** —
5.5% top-up fee, 1-year credit expiry, 24-hour refund window, Discord-only
support, some providers serving quantized models, and its Series B was led by
**CapitalG, Alphabet's investment arm**. Phase 3 hardware (M4 Pro 48–64GB
~€1,600–2,200, or a used 3090 ~€700–1,000) only if local inference itself
becomes the goal — a €2,000 box is eight years of Claude and still loses at
coding.

### 8a. 🔐 Public-repo hygiene — added 2026-09-23

Full secret audit done (gitleaks over all 492 commits): only one leak ever —
the Uptime Kuma backup push token, public since **2026-05-09**. Rotated
2026-09-25; the pre-commit hook, CI and the weekly audit guard against a
repeat.

- [ ] 👤 **Enable the hook on the MacBook's clone too** — run
      `~/.dotfiles/scripts/sync.sh` there once (it sets `core.hooksPath`), then
      `brew install gitleaks`. (The statusline commit on 2026-09-23 came from a
      clone without it.) Can't be checked from the Mac mini.
- [ ] 👤 **MacBook Air's Tailscale key expired 2026-09-02** (`tailscale status`,
      2026-09-25). Log in again and **Disable key expiry** for it in the admin
      console. Also identify the node named `localhost` (expires 2027-03-04)
      and disable its expiry if it's a device you keep.

### 8b. 🔒 Cloudflare/R2 security check — added 2026-09-21

Nothing is known-broken; both are just unverified.

- [ ] 👤 **Check the R2 API token's scope** (R2 → Manage R2 API tokens). If
      account-wide, create a new token scoped to `peciulevicius-backups`
      only, update `~/services/rclone/.env`, confirm `rclone lsd r2:` still
      works, then revoke the old token.
- [ ] 👤 **Confirm 2FA is enabled on the Cloudflare account itself** — it
      controls DNS, the Tunnel and R2; arguably the single highest-value
      account in the setup.

### 8c. 🔌 Power outage recovery — added 2026-09-22

A real outage left the Mac mini fully off; needed a physical power-button
press. **FileVault stays on** (decided 2026-09-22 — pre-boot unlock has no
unattended path, so someone types the password once per outage, but 30+
services' `.env` files stay encrypted at rest). That also rules out Mac mini
auto-login. The external dead-man's switch is live since 2026-09-25, so a
whole-house outage now alerts.

- [ ] 👤 `sudo pmset -a autorestartatconnect 1` — needs an interactive
      password. Still not set on 2026-09-25 (`pmset -g custom` shows only
      `autorestart 1`, which is restart-after-panic, not power-on-at-AC).
- [ ] 👤 Decide on a **UPS** for the Mac mini + NAS (~€100–150) — brief
      outages then never cut power at all, and FileVault stays.
- [ ] 👤 Confirm the NAS's own **"Auto power-on when power is supplied"** (+
      WOL) is enabled (NAS UI → Hardware & Power). A self-recovering Mac mini
      is useless if the NAS stays off.

### 9. 🧹 Maintenance backlog — no deadline, real value

- [ ] 👤 **Try `notebook.koplugin` (by pierspad) for on-device writing —
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
- [ ] 👤 **Decide: buy a Supernote Manta?** Not urgent, not blocking anything —
      the current Kindle+Calibre-Web+KOReader reading pipeline is untouched
      either way. Confirmed 2026-09-22: none of the alternatives (Supernote,
      Boox, reMarkable) give you everything at once — see the three-way
      trade-off table in `guides/BOOKS.md`. If bought, it can sync to the
      **already-running Nextcloud** via WebDAV, no new infrastructure needed.
- [ ] 👤 **Add a music library to Jellyfin.** No new service needed — Jellyfin
      already natively supports music as a library type, same app, same
      login. Create `/Volumes/media/music`, drop files in, add it as a
      library in Jellyfin's admin. Stream-only with **Finamp** (free,
      iOS/Android) or **Amperfy** (iOS). Both point at the same Jellyfin.
      Related stopgap (2026-09-22, still cron'd every 30 min):
      `scripts/utils/smb-watcher-rescan.sh` restarts Jellyfin + Audiobookshelf
      because neither's file watcher reliably sees new files over SMB. Each
      real fix needs one 30-second thing only you can do:
      - [ ] 👤 **Jellyfin** — dashboard → Admin → **API Keys → +** → send me the
            key, I'll wire it into Radarr's and Sonarr's Settings → Connect.
            Instant refresh, no restart, no playback interruption.
      - [ ] 👤 **Audiobookshelf** — same idea (Settings → API Keys), but check
            whether LazyLibrarian even supports a "notify on import" hook for
            it first — unconfirmed as of 2026-09-22.
- [ ] 🔴 **Rotate Immich's database password** (Claude, with a go-ahead — it
      restarts Immich). Found 2026-09-22: `~/services/immich/.env`'s
      `DB_PASSWORD` is still the old, reused personal password. Internal-only
      (Postgres isn't exposed outside the Docker network), so not an active
      exposure, but it's the one password in this stack never replaced with a
      random one.
      ⚠️ **Changing `.env` alone will NOT work**: Immich's Postgres already has
      the OLD password set on the database user, so a mismatched `.env` breaks
      Immich's DB connection entirely (photos safe on disk, app inaccessible).
      Correct sequence:
      ```bash
      NEW_PASS="$(openssl rand -base64 32)"
      docker exec immich_postgres psql -U postgres -c "ALTER USER postgres WITH PASSWORD '$NEW_PASS';"
      # then update DB_PASSWORD in ~/services/immich/.env to match $NEW_PASS
      docker compose -f ~/services/immich/docker-compose.yml up -d
      # verify: docker logs immich_server --tail 20 (no auth errors), open the app
      ```
- [ ] Clear the leftover data directories from the removals:
      `rm -rf ~/services/mealie ~/services/grafana` (both confirmed
      empty/unused before removal; both still present 2026-09-25).
      `rclone-backup.sh` already excludes both.
- [ ] 👤 **Decide: Nextcloud — keep or remove?** Only 83MB of real user files in
      it (the rest is app code + DB engine). Its non-redundant features:
      **Calendar/Contacts sync** (CalDAV/CardDAV — nothing else here does
      that; contacts and calendar currently live **only on the iPhone**, see
      *Calendar + Contacts*) and **the confirmed WebDAV target for a
      Supernote's own-server note sync** (see `guides/BOOKS.md`), so it gains
      a second real use only if a Supernote is ever bought. ⚠️ Don't use
      Nextcloud's own Notes app if you keep it — genuinely bad app (2.3★,
      constant disconnects, doesn't stay logged in); Obsidian is already the
      right notes tool.
- [ ] 👤 **Decide: Paperless-ngx — keep or remove?** Not empty like Mealie was —
      **14 real scanned documents** exist. Low activity, but not zero. Its job
      (OCR + searchable archive of scanned paperwork) is different from just
      uploading a file into an Odysseus chat — Odysseus's upload is ephemeral
      per-conversation context, not a tagged, dated, full-text-searchable
      archive across years. Keep if you expect to scan real paperwork
      (tax/medical/receipts) later; remove if not.

⚠️ **Pi-hole is the one that matters here:** pinned at `pihole/pihole:2024.07.0`,
publicly exposed, and it controls DNS for the whole network. A pinned tag never
moves, so Watchtower being enabled is not evidence anything is current.

- [ ] Delete ~2.3 GB of locked `.smbdelete` duplicates (needs NAS-side access)

#### Quick wins left over from 2026-09-20

- [ ] 👤 **Sync the Kindle wallpapers.** Six are ready in `wallpapers/kindle/`
      (two rejects dropped, all renamed descriptively). Run
      `~/.dotfiles/scripts/kindle/sync.sh`, then the one line it prints in
      kTerm. It mirrors, so it also clears the ten stale `lockscreen-*.png`
      left from the earlier numbered attempt. (Custom lockscreens need the
      screensaver zip first — see *Notes*.)
- [ ] 👤 ⚠️ **Playback speed does nothing on Kindle** — upstream limitation, the
      Kindle audio backends implement no speed control and the call fails
      silently. Workaround if it matters: `ffmpeg -filter:a atempo=1.5` the M4B
      *before* aligning, so the read-along is natively faster. Needs
      `brew install ffmpeg` and a re-align per speed.
- [ ] 👤 **Clear stuck duplicate files in the Calibre library from the NAS side.**
      Two failed Calibre-Web renames left a 733MB `.smbdelete` orphan plus a
      733MB duplicate EPUB in
      `/Volumes/books/David Goggins/Can't Hurt Me_ ... (41)/`, and ~1.5GB of
      `.smbdelete` files at the library root. Stopping every container that
      touches the share **and** unmounting/remounting it did **not** release
      them — the lock is held by the NAS's SMB server, so they have to go via
      the **UGOS file manager** (or an SSH session on the NAS — SSH is enabled
      now). ~2.3GB. Not urgent: all excluded from the R2 backup.
- [ ] 👤 **Tag the aligned book** `read-along` in Calibre-Web so it is
      distinguishable over OPDS. ⚠️ Tag it — do **not** rename it; see the
      rename warning in [HOME_SERVER_REFERENCE.md](HOME_SERVER_REFERENCE.md).
- [ ] 👤 **Verify Kindle OTA is blocked** ("Check OTA Status" scriptlet).
      Vera blocks updates itself — verify, don't assume.
- [ ] 👤 Stock app → **Share → Searchable PDF** → confirm the mail arrives. This
      is the Obsidian pipeline, and it is the thing most likely to have broken
      quietly during all the Kindle work (and the mail switch). kindle_sync
      itself runs hourly — last run 2026-09-25 13:00, "No new Kindle export
      emails".

---

## Detail and standing items

Background for the steps above, plus items outside the sequence.

### 💾 Disk — 32GiB free of 228GB (84%) on 2026-09-25

Was **15 GiB free (92%)** before the 2026-09-21 cleanup (Docker build cache
6.05GB, Homebrew 477MB, applied Squirrel/ShipIt update staging ~2.1GB); Trash
(2.7GB) and `~/Downloads` (1.1GB) were emptied afterwards. It fills faster than
expected — re-check with `du -sh ~/Library/Caches/* | sort -rh | head` when it
gets tight (update staging recurs as apps update).

| What | Size (2026-09-21) |
|---|---|
| Docker (`Docker.raw`) | **48GB allocated** — TRIMs back after a prune; judge by `df -h /System/Volumes/Data`, not file size |
| `~/services` (service data) | 6.9GB |
| `~/.ollama/models` | 6.2GB |
| `~/Library/Caches` | 4.4GB — mostly live browser cache, leave it |
| `~/dev` | 4.9GB |

- [ ] 👤 Consider whether old DB dumps in `~/backups` need 30 days of retention
- The `.smbdelete` duplicates: see *9. Maintenance backlog*.

⚠️ **Never `docker image prune -a` or `docker system prune -a`.** They delete
every image not backing a *running* container — including the 2.77GB
Storyteller image, stopped by design. Dangling-only (`docker image prune -f`)
reclaims 0B. The safe reclaim is `docker builder prune -af`; remove specific
images after checking `docker ps -a --format '{{.Names}}\t{{.Image}}'`. The 7
dangling volumes hold 55KB total — not worth the risk.

⚠️ **Do not move service data to the NAS to save space.** Databases must not
live on SMB — that rule is why Immich's Postgres is on the SSD, and the Calibre
library breaking repeatedly on 2026-09-21 is what happens when it is ignored.
Media belongs on the NAS; databases and app state belong on the SSD.

### 🔗 Obsidian LiveSync — the server side is done

CouchDB is up at `https://couchdb.peciulevicius.com` (data on the internal SSD,
behind Cloudflare Access), `obsidian` database created, anonymous requests 401
on every path except `/_up`. Self-hosted, E2E, no subscription, no Apple
dependency. ❌ Not iCloud, ❌ not Obsidian Sync. Fallback if CouchDB is
unwanted: Remotely Save → Nextcloud WebDAV or R2.

- [ ] 👤 Install **Self-hosted LiveSync** on each device, E2E encryption on, same
      passphrase everywhere
- [ ] 👤 ⚠️ **Start on the Mac mini** — it holds the real vault. Let it finish
      uploading before connecting the iPhone. LiveSync asks which side wins and
      answering with an empty device wipes the vault. Snapshot:
      `~/backups/vault-snapshots/`.

---

## Do these first — you lose data or access without them

### Get one copy of the photos out of the building

Photos live on the NAS (RAID 5) plus T7 and T5 — all three in the same room.
The R2 cloud copy (Plan B) is done and verified; see the changelog and
`services/rclone/README.md` "Immich photo/video backup".

- [ ] 👤 **Plan A:** reload T5 with the full photo/video collection and take it
      to the parents' house as the offsite family copy (last verified 1:1
      against the NAS on 2026-09-05 — re-run `backup-external.sh` to it first).

---

## Worth doing soon

### ⚠️ 21 pinned images that Watchtower can never update

Watchtower is enabled, which creates a false sense of currency: **a pinned tag
never moves**, so Watchtower silently does nothing for most of the stack. This
cost four hours on 2026-09-21 — the Bitwarden iOS app was broken by a bug fixed
three Vaultwarden releases earlier, and the pin hid it.

Every request logged **200 OK** while the app failed, because the fault was a
malformed response body, not an error status. **When a client misbehaves against
a healthy-looking server, compare versions first.**

Oldest and most exposed first:

- [ ] **Majors NOT taken — each has a one-way data migration.** Plan per item;
      do one per sitting, never two at once:
  - **Jellyfin 10.10 → 10.11**: 10.11 moves the library DB to EF Core,
    one-way, and can take 10–30+ min on first start (don't restart it
    mid-migration). Backup: stop, tar `~/services/jellyfin/data/config`
    (~200MB, cache excluded). Rollback: restore the tar + `10.10.7` tag — a
    10.11 DB will not open on 10.10. Check client app versions first.
  - **Uptime Kuma 1.23 → 2.x**: 2.0 migrates SQLite in place (heartbeat table
    rewrite; minutes on a 1.3GB `kuma.db` — trim heartbeat retention first)
    and can optionally move to MariaDB. Backup: stop, copy `data/`. Rollback:
    restore `data/` + `1.23.17`. Watch the Discord notifier and the
    `status.` page after.
  - **Syncthing 1 → 2**: v2 replaces the LevelDB index with SQLite (migrated
    on first start, one-way) and drops some legacy options. Backup
    `data/config`; rollback = restore it + `1.30.0` (index rescans). Upgrade
    the phone/desktop peers soon after — v2 still talks to v1 peers.
  - **Radarr 5 → 6**, **Prowlarr 1 → 2**: DB schema migrations on start
    (forward-only); each app writes its own `Backups/` zip — take one via
    System → Backup first, plus a tar of its data dir. Rollback = restore
    zip into the old tag. Do Prowlarr first; re-run Sonarr/Radarr app tests.
  - **Paperless-ngx 2 → 3**: Django migrations + possible OCR/config renames.
    `pg_dump` + `document_exporter` to `data/export` first; rollback = restore
    the dump into the 2.20.15 tag. Only if Paperless survives the
    keep/remove decision.
  - **Stirling PDF 0.46 → 1.x+**: image renamed (`stirlingtools/stirling-pdf`),
    settings.yml layout changed; stateless otherwise (no login enabled) —
    low risk, just re-check `settings.yml` after.
  - **Nextcloud 30 → 31 → 32 …**: 30 is end-of-life. Must step one major at
    a time (`occ upgrade` each), maintenance mode, MariaDB dump first
    (`backup-databases.sh`), check apps compatibility per step. Biggest job
    here — schedule an evening.
  - **Postgres 16 → 17/18, MariaDB 11.4 → 12/13, Redis 7 → 8**: data-dir
    format changes; Postgres needs dump/restore into a fresh volume. Stay on
    16 / 11.4 LTS / 7.4 until a reason appears — all floating tags were
    verified current on 2026-09-25.

**Process, not a one-off:** bump deliberately, one service at a time, reading
release notes and backing up data first — that is why they are pinned, and
pinning is still the right call. But schedule it; quarterly is enough.
`docker compose pull` will not help while the tag is fixed.

**Scheduled since 2026-09-24:** `scripts/utils/check-image-updates.py` runs
quarterly from cron and posts outdated pins to Discord (`--outdated` to run
it by hand). All same-major bumps were taken 2026-09-25 (changelog); only the
majors above remain.

### ⚠️ Move the Calibre library off SMB onto the SSD

Done 2026-09-25 with `scripts/utils/migrate-calibre-to-ssd.sh` — library now
at `~/services/calibre/library` (why and how: changelog). Follow-ups left:

- [ ] Verify OPDS still serves to KOReader afterwards, and that Calibre-Web
      opens a shelf (the old `disk I/O error` path) — server side checked
      2026-09-25 (login 200, OPDS answers 401 Basic, no DB errors); the
      logged-in KOReader + shelf check needs you
- [ ] Next morning (2026-09-26): `~/logs/rclone-backup.log` shows the Calibre
      books backup reading from `~/services/calibre/library`
- [ ] After a week (~2026-10-02): delete `/Volumes/books` from the NAS via
      UGOS, then update `NAS.md` (`HOME_SERVER_REFERENCE.md` rows already
      point at the SSD and call the NAS copy a frozen rollback)

### Regenerate missing Immich thumbnails

87 assets show "error loading image" — all videos, thumbnails lost while Immich
was crash-looping in early September. Originals are intact (verified on disk;
0 assets flagged offline).

- [ ] 👤 photos.peciulevicius.com → Administration → Jobs → **Generate Thumbnails →
      Missing**

### External backups are manual now — nothing warns when they go stale

The nightly cron was removed on 2026-09-05 (the drives are not permanently
connected, so it failed every night). T5 had silently drifted seven weeks out of
date before anyone noticed. Since 2026-09-24 `backup-external.sh` stamps
`~/logs/external-backup-<drive>.last` and the weekly audit fails past 30 days —
first T7 run is in *📋 Open user steps*.

- [ ] 👤 Decide what T5 is *for* — once it lives offsite it can never be the
      routine local target

Run a backup with:
`~/.dotfiles/scripts/backup/backup-external.sh /Volumes/T7 --dry-run` then without `--dry-run`.

### Router DHCP reservation for the NAS

No longer load-bearing — everything addresses the NAS as `DH4300PLUS-DP.local`
(mDNS) since 2026-09-05, which absorbs IP drift. Still worth pinning.

- [ ] 👤 OpenWrt (`192.168.1.1`) → static lease for the NAS (MAC from the router's client list)

---

## Projects (no deadline)

### Pi-hole — finish the deployment

#### Ad blocking everywhere — layered (added 2026-09-25)

Pi-hole blocks by **domain**, so it stops ads/trackers that come from ad
domains — in apps, smart TVs, everything on the network — but **not** ads
served from the site's own domain (YouTube, Amazon sponsored listings,
Instagram/Facebook, "AdChoices" served first-party). Those need an in-browser
blocker. So: Pi-hole for the network + a content blocker in the browser.

- [ ] 👤 **Pi-hole on every device, anywhere, via Tailscale:** admin console →
      **DNS** → Nameservers → *Add nameserver* → Custom → `100.81.171.49`
      (Pi-hole's **Tailscale** IP, not the LAN IP) → enable **Override local
      DNS**. Verified 2026-09-25 that Pi-hole already answers on that IP
      (`dig @100.81.171.49 example.com`, listening mode ALL). Test on cellular
      with Tailscale on; watch the Pi-hole query log for the phone.
      ⚠️ If the Mac mini is off, Tailscale devices lose DNS entirely while
      the override is on — toggle Tailscale off in that case, or accept it.
- [x] Curated blocklists added 2026-09-25: **HaGeZi Multi Pro** + **HaGeZi TIF
      medium** alongside StevenBlack → 1.18M domains in gravity. Spot-checked:
      YouTube, Amazon, GitHub, Apple, Claude, Strava, TrainingPeaks, Purelymail,
      Tailscale resolve; doubleclick → 0.0.0.0. If a site breaks, check the
      Pi-hole query log and allowlist the domain.
- [ ] 👤 **Router DNS → Pi-hole** (existing item below) so non-Tailscale
      devices at home (TV, guests) are covered too.
- [ ] 👤 Browser side: **Brave** Shields on (blocks YouTube ads on desktop);
      on the **iPhone**, the YouTube *app* can't be fixed by DNS — watch in
      **Brave for iOS** (blocks YouTube ads, background play) or add **AdGuard**
      (Safari content blocker). If ever on Zen/Firefox: **uBlock Origin**.

**Note:** since the v6 upgrade (2026-09-25) Glance's DNS widget logs in with `PIHOLE_PASSWORD` in `~/services/glance/.env` (the v5 `PIHOLE_API_KEY` is gone).

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

- [ ] 👤 Decide: Caddy for local HTTPS, or leave everything on the tunnel
- [ ] 👤 Independent of that, and worth doing on its own: set router DNS to the
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

~140GB of personal photos sitting on T7 outside of Immich, organised by year/trip
(a copy also sits in the NAS `unsorted` share since the T7 → NAS migration):

- `/Volumes/T7/2002` → `/Volumes/T7/2024` — ~130GB of photos going back years
- `/Volumes/T7/from iphone (reikia surušiuoti)` — 9.2GB unsorted iPhone photos
- Notable: `/Volumes/T7/2024` (99GB) holds trip folders with both iPhone and camera shots

- [ ] 👤 Check if any of these are already in Immich (avoid duplicates)
- [ ] 👤 Import via Immich CLI or bulk upload through the web UI
- [ ] 👤 Sort/tag the unsorted iPhone folder before importing
- [ ] 👤 Delete originals from T7 after confirming import (frees ~140GB); also
      decide on the stale `/Volumes/T7/docker/` (53G old Docker VM copy)

### Paperless-NGX — organise documents

Only if Paperless is kept — see the keep-or-remove decision in *9. Maintenance
backlog*. Paperless-NGX doesn't support traditional folders — it uses **tags**,
**document types**, and **correspondents** instead.

- [ ] 👤 Create document types: e.g. "Invoice", "Contract", "Receipt", "Statement"
- [ ] 👤 Create correspondents: e.g. "Bank", "Employer", "Government"
- [ ] 👤 Create tags: e.g. "Tax 2024", "Important", "Archive"
- [ ] 👤 Assign types/correspondents/tags to uploaded documents
- [ ] 👤 Use **Saved Views** (left sidebar) to create folder-like filtered views

### Linkwarden — it's set up; the friction is Brave Shields

**Linkwarden is the keeper, not the thing being scrapped.** Karakeep was the
experiment, tried as a replacement and reverted; its containers are gone.
Linkwarden stays on port 3005 / `links.peciulevicius.com`, extension installed,
**621 bookmarks imported**.

What's actually wrong: **Brave needs Shields disabled for the site** or the
extension silently fails — which makes it feel like it doesn't work.

- [ ] 👤 Brave → `links.peciulevicius.com` → Shields **down** for this site, then
      save a tab and confirm it appears on the phone PWA
- [ ] 👤 If it still feels like friction after that, the honest comparison is
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

**Goal:** Route Transmission traffic through a VPN so ISP can't see torrent activity. Not urgent.

- [ ] 👤 Pick a provider: **Mullvad** (€5/mo, best privacy, no email needed,
      cancel anytime) or **Proton VPN** (free tier works but slower, no port
      forwarding)
- [ ] Create `services/gluetun/docker-compose.yml` with VPN credentials
- [ ] Update Transmission compose to use `network_mode: service:gluetun`
- [ ] Test: `docker exec transmission curl ifconfig.me` should show VPN IP, not home IP

### Notes — make capture frictionless before changing tools

**Full plan: [guides/NOTES.md](guides/NOTES.md).** The vault, routing rules and
Kindle sync all exist and go unused. The problem is capture friction, not the
tool — swapping Obsidian for something else reproduces the same failure later.
Sync: see *🔗 Obsidian LiveSync* (server done, devices pending). Kindle sync is
verified running hourly on the Mac mini (2026-09-25).

- [ ] 👤 **One** quick-capture Shortcut on the iPhone home screen, ≤2 taps,
      appending to the daily note
- [ ] 👤 Install the **Obsidian Web Clipper** in Brave (complements Linkwarden:
      it archives links, the clipper captures content)
- [ ] 👤 **30 days of capture only, zero organising.** Then reassess.
      If it still hasn't stuck, Apple Notes for fleeting + Obsidian for durable
      is a legitimate end state, not a failure.
- [ ] 👤 Habit: **Share → Searchable PDF** after each meeting. Amazon's
      handwriting OCR is what makes the notes greppable once they land in the
      vault.

**Kindle Scribe** — a target device too, not just phone + PC. Full plan in
[guides/BOOKS.md](guides/BOOKS.md), step-by-step in
**[guides/KINDLE_SETUP.md](guides/KINDLE_SETUP.md)**. Jailbroken (Vera,
2026-09-20), KOReader reads Calibre-Web over OPDS, read-along verified.
Standing decision: **keep Amazon's stock software for handwriting** (KOReader's
Scribe stylus PR was merged March 2026 then reverted as unstable) — KOReader
for reading, stock for notes + OCR export.

- [ ] 👤 **Post-jailbreak housekeeping** — delete leftover `.bin` update files from
      the Kindle's root plus the jailbreak's filler files; a stray `.bin` can
      undo the jailbreak
- [ ] 👤 In KOReader, set a **HOME directory** (long-press `documents/` or a new
      `books/` folder) and turn off *Show unsupported files* — the browser opens
      on the storage root and shows firmware internals otherwise
- [ ] 👤 **`;kpm install usbnetlite`** — SSH over USB, which is what unblocks the
      `scp` push script below.
- [ ] Optional later: **books do not auto-transfer** — OPDS is pull.
      `scripts/kindle/sync.sh --dir` to `scp` new EPUBs over SSH when the
      Scribe is reachable (needs usbnetlite).
- [ ] 👤 **Custom lockscreens** — ⚠️ the KPM route fails with *"failed to install
      packages"*; use the zip instead. It ships `documents/Custom Screensaver.sh`,
      which is a Vera scriptlet, so it needs no KUAL. Serve
      `custom-screensaver-0.3.0-kindlehf.zip` with `scripts/kindle/sync.sh`
      (⚠️ it was in `~/Downloads/kindle-plugins`, which has since been emptied —
      re-download it), `wget` + `unzip` it at `/mnt/us`, then PNGs at
      **1860 × 2480** into `/mnt/us/screensavers/`.
- [ ] 👤 **KindleFetch** (KOReader plugin version) — grab a book from Anna's
      Archive with no computer nearby. A shortcut beside the LazyLibrarian →
      Calibre-Web library, not a replacement.
- [ ] 👤 **Read-aloud with word highlighting** —
      [audiobook.koplugin](https://github.com/stradichenko/audiobook.koplugin):
      TTS, synchronised highlighting, auto page turns, Bluetooth, fully offline.
      Copy into `koreader/plugins/`. Use the Piper voice.
- [ ] 👤 ⚠️ **If installing `blockamazon`, test the Searchable PDF export straight
      after.** It blocks Amazon domains via `/etc/hosts` and does not document
      which — and the handwriting OCR export routes through Amazon to email,
      which is what feeds `kindle_sync.py`. Reversible via KUAL's unblock.
- [ ] 👤 LazyLibrarian shows **0 books downloaded** (47 known, 1 author) — the
      book pipeline is configured, not proven. Confirm it can actually fetch
      something before relying on it.

### De-Google — migrate off all Google services

**Full plan: [guides/DEGOOGLE.md](guides/DEGOOGLE.md).** Annotated replacement
list for every Google service: **[guides/DEGOOGLE_ALTERNATIVES.md](guides/DEGOOGLE_ALTERNATIVES.md)**
— check it before swapping any individual service. Only the live decisions and
next actions live here.

**Where you actually are:** Vaultwarden, Nextcloud, Immich, Tailscale, own domain
with per-service subdomains — all done, and **email is now on Purelymail**
(2026-09-25). Remaining gaps: **moving the mail consumers + accounts over,
phone, calendar/contacts, AI.** Don't restart from step one.

Google Authenticator → see **2. Move TOTP off Google Authenticator** — do it
before anything else here.

#### Accounts and "Sign in with Google"

- [ ] 👤 List dependencies: Google Account → Security → *Your connections to
      third-party apps & services*
- [ ] 👤 For each that matters: set a real password, then change the email —
      converts OAuth into a login you control (same pass as step 6)
- [ ] 👤 **Never delete the Google account.** It breaks remaining OAuth logins and
      frees the address for someone else to register and attempt resets with.
      Goal is to stop *using* Google, not to delete it.

#### Email — Purelymail is live; what's left

Provider, DNS and mailbox are done (changelog 2026-09-25). Runbook:
**[guides/EMAIL.md](./guides/EMAIL.md)**. Standing decision: **never self-host
the mail server** (residential IP, blocklists, blocked port 25, no reverse DNS).
Consumers → *🔝 Next up*; catch-all/tests/deliverability → *📋 Open user steps*.

- [ ] 👤 **Decide the Gmail redirect**: full forward (Gmail → Settings →
      Forwarding → all mail to `dziugas@`, and `dziugas@` as default "Send mail
      as") so everything lands in one inbox, or the Kindle-only filter from
      *🔝 Next up* #5 and let Gmail wither.
- [ ] 👤 Import the Gmail Takeout `.mbox` into Purelymail (optional — only if
      you want the history in one place).
- [ ] 👤 Remove Google as a Cloudflare Access identity provider — **after** the
      logins have moved.

#### Calendar + Contacts — unblocked, ~1 hour, more urgent than it looked

Nextcloud is already running. Nothing is stopping this.

⚠️ **Corrected 2026-09-22 — this isn't a de-Google migration, it's fixing an
actual single point of failure.** Contacts and calendar live **only on the
iPhone itself** — not backed up to Google, and (until this is done) not
backed up anywhere. A lost, stolen, or bricked phone loses both completely.
There's no Google `.ics`/`.vcf` export to pull from; the import source is the
phone's own local data.

- [ ] 👤 Enable Nextcloud Calendar + Contacts apps
- [ ] 👤 On iPhone: Settings → Contacts / Calendar → **export first** (Contacts
      app → select all → Share → vCard; or use the Nextcloud/CardDAV import
      flow directly) before touching sync settings — don't let a sync error
      be the first time a two-way merge runs against your only copy
- [ ] 👤 Add CalDAV + CardDAV accounts on the iPhone, verify two-way sync
- [ ] 👤 Confirm a re-fetch on a second device (or after a fresh CalDAV
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

**Keep the 13 mini regardless.** On iOS 26.5, gets iOS 27, major updates to
~2027–2028, security to ~2029–2030. You also **need a physical iPhone to test
Expo/React Native iOS builds** — so it stays either way. The realistic end
state is Pixel as daily driver, iPhone as dev device + tap-to-pay fallback.

- [ ] 👤 **Now (~€90):** replace the 13 mini battery — buys years of runway
- [ ] 👤 **Now (free):** enable **Advanced Data Protection** on iCloud — works on
      the free tier, no iCloud+ needed — delete Google apps, default search →
      DuckDuckGo
- [ ] 👤 **Before committing to any Pixel, check in this order:** does Google
      Wallet still refuse to run on GrapheneOS (tap-to-pay would stop working —
      the biggest daily friction); do your banking apps survive hardware
      attestation on a custom OS; is HeliBoard's Lithuanian swipe typing good
      enough.
- [ ] 👤 If buying refurbished: confirm carrier-unlocked, not a US carrier model —
      those bootloaders cannot be unlocked, making GrapheneOS impossible.

Reference for when the time comes — **pick by purpose.** GrapheneOS supports
Pixel 6 → **Pixel 10a** (no Pixel 11 yet).

- **Daily driver → Pixel 10a, €403 new at Telia.** Supported to **March 2033**
  — furthest of any device. New battery, local warranty, no carrier-lock risk.
  Note it's ~6.3" — **no modern Pixel is small**.
- **Just testing → Pixel 8a, €233 refurbed.** Supported to ~2031.
- ❌ **Not the Pixel 6 Pro at €205** — Google support ends **October 2026**.
  GrapheneOS drops devices when firmware updates stop.
- Mullvad works on GrapheneOS (F-Droid, no Play Store; always-on VPN in one
  profile at a time). CalyxOS runs on **Fairphone 5** — noted, but you prefer
  Pixel. Minimal Phone 2 (€599/€699) is **2.5–3× the 8a and cannot run
  GrapheneOS** — it solves *attention*, not *privacy*; GrapheneOS user profiles
  give the focus benefit for €233.

#### Quick wins

- [ ] 👤 Confirm default search is DuckDuckGo/Kagi in every browser **and** on the phone
- [ ] 👤 Confirm Brave (already installed) is the default browser
- [ ] 👤 Maps: accept the loss. Apple Maps is the pragmatic swap; Organic Maps for offline.

### NAS — remaining follow-ups

**Hardware and migration history** — arrival, RAID build, SMB shares, the T7 →
NAS copy and the switch of every service to NAS paths — is in
[HOME_SERVER_CHANGELOG.md](HOME_SERVER_CHANGELOG.md) (see the NAS arrival/migration entry).
Layout and paths are in [HOME_SERVER_REFERENCE.md](HOME_SERVER_REFERENCE.md).
SSH is enabled (port 22 answers, 2026-09-25); auto power-on is under *8c*.

- [ ] 👤 Terminal settings: set "Shut down automatically" to never (Control Panel → Terminal)
- [ ] 👤 Set up 2FA on admin account (Security → Account security)
- [ ] 👤 Enable DoS protection (Security → Security)
- [ ] 👤 Change custom domain name from "localhost" to "nas" (Device Connection → LAN)
- [ ] 👤 Delete stale `immich/postgres` folder on NAS share (460MB dead copy — via Files app)
- [ ] 👤 Verify drive sleep works (configured: 20 min idle)
- [ ] 👤 Optional: Bonjour + Time Machine target, NAS rsync service
- Watch streaming: 4K high-bitrate files may exceed the extender's ~100Mbps
  ceiling — if Jellyfin buffers, wire the NAS/Mac path properly.

**Hardware reference:** 4-bay, RK3588C ARM 8-core, 8GB RAM (keep NAS storage-only — no heavy Docker workloads; compute stays on Mac mini), 2.5GbE port. Purchase total ~€1,060 (NAS €340 + drives €690 + switch/cables €30).

---
