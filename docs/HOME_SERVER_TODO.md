# Home Server — TODO

Outstanding work only. Finished items live in
[HOME_SERVER_CHANGELOG.md](HOME_SERVER_CHANGELOG.md).

👤 = needs owner input (a UI, device, credential, decision or approval).
Unmarked = no owner-only step is recorded; every agent must still follow
repository/service rules and get approval for consequential actions. Last
truth pass: **2026-09-26** — every open item was checked against the live
system; done items moved to the changelog. Partial
truth pass **2026-09-29** corrected power settings, the removed rescan schedule,
obsolete ntfy advice, and duplicate VPN/device steps; it was not a full audit.

---

## 🔝 Next up — finish the mail switch

- [ ] 👤 **Discord notification migration:** grant the bridge bot's server
  role Manage Channels and Manage Webhooks, then run
  `python3 scripts/utils/configure-discord-notifications.py --apply`.
  Preview verified 2026-09-29; currently blocked by those missing permissions.
  Destinations: `#uptime-alerts`, `#homelab-jobs`, `#ai-agents`,
  `#homelab-reminders`. Kuma repeats are already disabled. See the cron README.

kindle_sync, Kuma SMTP and Calibre-Web SMTP all run on Purelymail since
2026-09-26 (changelog). Remaining:
- [ ] 👤 Kuma → "Uptime Kuma" notification → **Test**; Calibre-Web → Admin →
      *Send test email* → Tasks shows *Finished* (the profile email is already
      `dziugas@`, checked 2026-09-26)
- [ ] 👤 Amazon → Manage Content & Devices → Preferences → Personal Document
      Settings → **approve `dziugas@peciulevicius.com`** as a sender, or
      Calibre-Web "Send to Kindle" silently stops working
- [ ] 👤 Kindle exports keep going to **Gmail** (the Amazon account email) until
   the account-email pass below, but kindle_sync now reads Purelymail. So it
   still sees them, add a **Gmail filter**: `from:do-not-reply@amazon.com
   subject:"from your Kindle"` → Forward to `dziugas@peciulevicius.com` (Gmail
   asks you to confirm the forwarding address — the code lands in `dziugas@`).
   Or pick the saved `kindle@peciulevicius.com` address on the Scribe share
   screen each time. Export format: *Convert to text (TXT)* + *✓ Attach
   searchable PDF*.

---

## 🧭 Who does what — index of every open item

Section names in *italics* are headings below.

### 👤 Needs you (UI / device / credentials / decision)

- [x] ~~⚡ Paperclip usage-limit watchdog~~ — detects and notifies about Claude limits; OpenRouter connections are provisioned in all three companies. `AUTO_SWITCH` is **off** after the restore incident. Recovery applied 2026-09-29: skills and three open issue assignments restored, three reporting links repaired.
- [x] ~~Paperclip unchanged-binding validation defect~~ — deployed the guarded local patch from the recovery PR after approval; Web Engineer and Homelab Security Engineer's reporting updates now succeed. All five reporting links, three issue assignments and three routine assignments are repaired; fallback state is cleared.
- [ ] **Paperclip retired-record cleanup:** the 11 obsolete Coach/Studio records pass reference checks; termination awaits explicit approval. The old Homelab Lead is now unreferenced but excluded from that 11-record plan. The ten active unbound Claude roles were temporarily switched on their existing IDs to Codex on 2026-09-30 after a fresh container login. Their originals are saved; a staged cron check starts recovery after 2026-10-01 11:00 Vilnius and requires a real Claude probe. Automatic routing and managed-binding recovery remain pending. Keep `AUTO_SWITCH=0`. Details: `services/paperclip/README.md` → *Usage-limit fallback*.
- **🧠 Shared AI memory (2026-09-29):**
  - [x] ~~First portable Claude/Codex repository skill~~ — `homelab-service` now has one source under `.agents/skills/`, Claude project discovery and a compatibility link for the existing installer/global path. Skill guidance preserves staged live differences and separates source readiness from deployment. Paperclip/Odysseus skill imports remain separate from host discovery.
  - [x] ~~NAS: create the `backups` share and mount it at `/Volumes/backups`~~ — done 2026-09-29; first `~/ai-memory` copy verified on the NAS. See `docs/HOME_SERVER_CHANGELOG.md`.
  - [x] ~~Consistent memory instructions across Paperclip agents~~ — appended and verified on all 31 current agents (including paused departments), 2026-09-29. Claude/Codex repository guidance points to the same private tree. New hires: `paperclip-memory-guidance.py` preview then `--apply`; role instructions preserved, private originals backed up.
  - [ ] 👤 Odysseus: save the current admin password to Vaultwarden and put it in `~/services/odysseus/.env` (`ODYSSEUS_ADMIN_PASSWORD`) — the `.env` one no longer matches, so API automation can't log in.
  - [ ] 👤 When the Anthropic API credit is used up: Odysseus → Admin → Models → disable the "Anthropic" endpoint and set task/utility models to an OpenRouter one.

- 👤 Save the **WUD** login to Vaultwarden (entry *WUD*, URL `http://100.81.171.49:3070`) — values in `~/services/wud/.env`
- **🛡️ Tailscale / VPN (2026-09-28):**
  - [x] ~~Approve the Mac mini as an exit node~~ — approved 2026-09-28, visible on the iPhone
  - [x] ~~Disable key expiry on `transmission-ts`~~ — 2026-09-28
  - [x] ~~iPhone: Mullvad exit node + Connect On Demand~~ — 2026-09-28
  - [ ] 👤 MacBook: menu bar Tailscale → Exit Node → Mullvad → same country
  - [x] ~~Passkey admin user~~ — created 2026-09-28; log in with it on each device
  - [ ] 📅 **2026-10-26 (calendar event set): cancel the Tailscale Mullvad add-on before it renews (~28 Oct)** — first decide the route: (a) fresh Tailscale tailnet on our domain → re-buy the add-on there, or (b) fully self-hosted **Headscale** → the add-on doesn't exist there, so buy Mullvad directly (account number, no email; ~€5/mo) and rewire `transmission-ts` + its kill switch to plain WireGuard.
  - [ ] 📅 **2026-10-28 (calendar event set): fresh tailnet on `peciulevicius.com`** (custom OIDC + WebFinger) — re-add all devices, move the Mullvad add-on, re-apply DNS/exit nodes/key-expiry policy, update 100.x IPs everywhere. Can't switch the current tailnet: it's a gmail.com tailnet, and GitHub/Apple can't be switch targets.

- [x] ~~Discord two-way chat with Coach + Dietitian~~ — bridge live 2026-09-27
- **Delete the Claude.ai export** once the Coach team and Studio brief look right: `~/Downloads/claude_export/`, `claude_export_full.json`, `export_from_claude.md` (they hold every chat, not just training)
- Mail wrap-up: Kuma + Calibre-Web test mails, approve `dziugas@` as an Amazon sender, Gmail→Kindle filter — *🔝 Next up*
- Coach: upload skill zip, add the `tp-mcp` custom connector in claude.ai, "Coach" Project — *🏃 Coach in the Claude app*
- Website: `checkOrigin` decision, `IP_HASH_SALT` secret, Resend domain check; janioniu: sort your local TODO edits, confirm placeholder facts with Dad, Purelymail domain, Workers Builds toggle — *🌐 Other repo backlogs* and below
- 👤 Install signature v2 on Mac Mail (select your account in the left column → + → paste, or `config/email/install-mac-signature.sh` for the dark-mode logo) + iPhone (`signature.txt`). Avatar: **decided 2026-09-28 — skip** (Gravatar isn't shown by Gmail/Apple Mail; BIMI logo needs a $650+/yr certificate; Google-account photo conflicts with de-Google) — *✉️ Email identity*
- Email: inbound test, more folders/filters (catch-all, iPhone Mail, signature built, mail-tester **10/10** — done 2026-09-28/29) — *📋 Open user steps*
- Reset Odysseus 2FA; first coaching session in Odysseus — *⚡ Batch 2026-09-24*
- Rotate the Vaultwarden admin token (Claude can do the hash + `.env`; you save it) — *3. Rotate the Vaultwarden admin token*
- Credential + email pass per service, NAS account passwords, `~/credentials-import.md` — *6. One pass per service*
- Vaultwarden Chrome extension on the work laptop — *7. Vaultwarden Chrome extension*
- Odysseus: chat-history exports, ChatGPT memories by hand, API balance/top-up check, save admin password to Vaultwarden — *8. Odysseus*
- MacBook: gitleaks hook + `sync.sh` (Tailscale re-auth done 2026-09-28) — *8a. Public-repo hygiene*
- R2 token scope, Cloudflare account 2FA — *8b. Cloudflare/R2 security check*
- **🔋 Buy a UPS** (decided 2026-09-28; FileVault stays on, so a reboot needs you at the machine — the UPS makes short outages not reboot at all). ~€80–130, shoebox size, draws 2–5 W itself, battery swap every 3–5 y. Pick one with **USB (HID)** so macOS/NUT can shut down cleanly: e.g. **APC Back-UPS BX750MI / BX950MI** or **Eaton 5E 850i USB**. Compare prices on kaina24.lt; LT shops: Varle.lt, Pigu.lt, 1a.lt, Senukai; or Amazon.de. Mac mini + NAS ≈ 30 W → ~20–40 min runtime. Claude: after it arrives, wire up clean shutdown (macOS Energy settings + NAS). `autorestart` is already on (checked 2026-09-28); NAS auto power-on still to check — *8c. Power outage recovery*
- notebook.koplugin, Supernote, cancel YouTube Music/Premium, music-folder cleanup, Jellyfin/ABS API keys, Nextcloud/Paperless (on-demand; decide later) — *9. Maintenance backlog*
- Kindle wallpapers, KOReader speed workaround, `.smbdelete` cleanup, `read-along` tag, OTA check, Searchable PDF test — *Quick wins left over from 2026-09-20*
- LiveSync plugin on each device — *🔗 Obsidian LiveSync*
- T5 offsite trip — *Get one copy of the photos out of the building*
- Immich missing thumbnails job — *Regenerate missing Immich thumbnails*
- KOReader OPDS + Calibre-Web shelf check — *Move the Calibre library off SMB onto the SSD*
- What T5 is for — *External backups are manual now*
- Router DHCP reservation — *Router DHCP reservation for the NAS*
- **Paperclip** (deployed 2026-09-26, `http://100.81.171.49:3100`): move the
  admin email/password from `~/services/paperclip/.env` into Vaultwarden and
  delete those two lines (no reset email exists — Vaultwarden is the only
  recovery). Claude Code + Codex are logged in and both companies are
  configured (2026-09-26, `services/paperclip/README.md` → *Companies*). Left
  for you:
  - **Studio:** open task **STU-2** (backlog, Planning mode) and move it to
    **Todo** when you want the CEO to start the 20-ideas plan.
  - **Studio:** *Routines → Daily standup* is **paused** on purpose (~25–35
    agent runs/week when on) — toggle it on only while the pipeline is moving.
  - **Homelab:** optionally *Routines → Homelab weekly report → Run now* once
    to see a first report before Sunday 10:00.
  - 👤 **Second GitHub token for the Web Engineer** (Homelab): fine-grained
    PAT for `peciulevicius/peciulevicius.com` only, *Contents* + *Pull
    requests* read/write → Paperclip secret in the Homelab company → bind as
    `GH_TOKEN` on the Web Engineer. Until then it can only hand over patches.
    Steps: README → *GitHub token for the Web Engineer*.
  - 👤 **GitHub connector for Homelab** (2026-09-29, separate from the
    Web Engineer PAT above): connect GitHub in Homelab's Connectors page so
    agents there can read/open PRs against `peciulevicius/.dotfiles` itself,
    not just the peciulevicius.com repo. Fine-grained PAT, that repo only,
    Contents + Pull requests read/write, no admin, never direct push to main.
  - **Move `GITHUB_TOKEN_HOMELAB` out of `.env`** into Vaultwarden *before
    the next* `docker compose up -d` — Paperclip now holds it as a secret, and
    `env_file` would otherwise expose it to every agent.
  - 👤 **Un-pause per phase**: README → *Un-pausing a department*. Studio was
    resumed wholesale by the board on 2026-09-26 — pause what isn't in the
    current phase (planning → build → launch/Marketing) so a fan-out can't
    wake many agents at once. Homelab: all new agents paused; resume per
    department (PRs → Infrastructure/Knowledge → Web after its token).
  - (Only if the Codex login ever expires:
    `docker exec -it paperclip codex login --device-auth`.)
  Watch `sysctl vm.swapusage` during the first agent runs.
  - [x] ~~Coach company (drafted, not created)~~ — **done 2026-09-27**: company,
    agent, MCP connections (TrainingPeaks + Strava), Discord push secret and
    the Daily check-in routine are all live. Detail:
    `services/paperclip/README.md` → *Coach — adaptive triathlon coaching*.
  - [x] ~~Approve Coach's connection cards~~ — TrainingPeaks reads work
    (COA-6 pulled body composition 2026-09-27).
  - [x] ~~ntfy iOS app / Kuma monitor for ntfy~~ — standalone ntfy removed
    2026-09-28 (unused; Coach team uses Discord). Delete the ntfy app from the
    phone if it was installed.
  - 👤 **Refresh the TrainingPeaks cookie when `tp_auth_status` fails** — it
    expires every few weeks. Steps: `services/trainingpeaks-mcp/README.md`.
- Pi-hole: Caddy decision, router DNS — *Pi-hole — finish the deployment*
- Old photo archives into Immich (needs T7 + judgement) — *Import old photo archives into Immich*
- Paperless tags/types — *Paperless-NGX — organise documents*
- Brave Shields for Linkwarden — *Linkwarden*
- Capture Shortcut, Web Clipper, 30-day habit, Kindle/KOReader items — *Notes*
- "Sign in with Google" audit, Gmail redirect decision, Takeout — *De-Google*
- Calendar + Contacts → **Radicale** is up; export from the iPhone + import + phone setup — *Calendar + Contacts*
- Phone: battery, ADP, search/browser, Pixel checks — *Phone* and *Quick wins* (De-Google)
- NAS UI settings, stale NAS folders, drive sleep — *NAS — remaining follow-ups*

- janioniuvynuogynas.lt (live; its own backlog is that repo's `docs/TODO.md`):
  - 👤 placeholder phone `+370 600 00 000` is still on the live site
    (2026-09-26), with the other unconfirmed facts — confirm with Dad
  - 👤 your local checkout has uncommitted `docs/TODO.md` + `environments.md`
    edits and is 26+ commits behind `main`; the 2026-09-26 TODO truth pass
    rewrote `docs/TODO.md` on `main`, so stash, `git pull`, then re-apply by
    hand (it will conflict)

- 👤 janioniuvynuogynas.lt email: **add the domain to the existing Purelymail
  account** (no extra cost) instead of Cloudflare Email Routing → Gmail; create
  `info@janioniuvynuogynas.lt` (or route it to whoever answers). Claude adds the
  Purelymail DNS records afterwards (zone and token are in place; no MX exists
  yet, 2026-09-26). Resend keeps using `send.janioniuvynuogynas.lt`, so no MX
  clash.

- 👤 **Phone apps** — connect Reeder (set FreshRSS API password first),
  Swift Paperless, Linkwarden, Pi-hole Remote (create an app password) —
  step-by-step table in `SERVICES.md` → *Connecting each app*. Nextcloud app
  waits for the keep-or-remove decision (Nextcloud is on-demand for now); Finamp/Amperfy not used (self-hosted
  music dropped 2026-09-26, Spotify kept). Also install: Bitwarden, Ente Auth,
  Obsidian + LiveSync, Swiftfin/Infuse, Odysseus home-screen web app. Standalone
  ntfy was removed 2026-09-28; agent chat/notifications use Discord.

- 👤 Ad blocking: Brave iOS / AdGuard for YouTube (Tailscale → Pi-hole done 2026-09-26) — *Pi-hole → Ad blocking everywhere*

- 👤 janioniu: Cloudflare → Workers & Pages → `janioniu-vynuogynas` → Settings →
  **Build** → turn off production deploys from Workers Builds (keep PR
  previews). Right now every merge deploys twice and the Workers Builds copy
  has no build vars — a race. Then submit one real contact form to confirm
  Resend/Loops keys work (secrets now sync on each GitHub Actions deploy).



- 👤 **~2026-10-03:** `rm ~/services/uptime-kuma/data/kuma.db.bak-2026-09-26-*` (and other pre-change backups) — the weekly audit now flags any `*.bak-*` / `*.pre-*` file under `~/services` older than 7 days, so this reminds itself via Discord

- **💰 Finance dashboard — direct accounts** (read-only credentials, local hidden prompts; setup in `services/glance/README.md` → Finance). Pipeline: `finance-status.sh` (07:00) → `finance-memory-snapshot.sh` (07:05) → Glance. IBKR, Trading 212 and Kraken collectors are implemented; account credentials and reconciliation remain owner steps.
  - [x] ~~BudgetBakers Wallet HTTP 400~~ — transport repair completed 2026-09-29. The 2026-09-30 successful fetch did not establish balance accuracy. Wallet was removed from the collector, card and future private summaries at the user's request; old historical records are excluded from new portfolio comparisons.
  - [x] ~~Direct IBKR / Trading 212 account collection~~ — implemented 2026-09-30. Each provider exposes native value, date and connection status. The EUR total covers connected investments only; stale/partial data is labelled. Trading 212 uses its reported account total without adding investments or pie cash again.
  - [ ] 👤 **IBKR:** create a one-account Activity Flex query (Account Information, Open Positions Summary, Cash Report, NAV / Change in NAV; XML, Last Business Day, `yyyyMMdd`) and a Flex Web Service token. Save with the hidden prompts in the Glance runbook. Compare the native NAV against the broker's same-date statement.
  - [ ] 👤 **Trading 212:** create an Invest/Stocks ISA key + secret with account-data read permission only. Save with the runbook's hidden prompts, refresh, and compare its native total with the app. No order permission is needed.
  - [x] ~~Trading 212 holdings detail~~ — implemented 2026-09-30. Read-only positions use broker wallet amounts in account currency, include pie shares once and retain reported account totals. Missing/malformed detail is explicit without hiding a valid summary. Credentials and comparison against the app remain the owner step above.
  - [x] ~~Kraken read-only collector~~ — implemented 2026-09-30. Default-wallet quantities and indicative EUR midpoint valuation; unsupported/unpriced balances fail the account rather than disappear. Private persisted nonces, credential-specific caches and stale recovery are implemented. No orders or withdrawals.
  - [ ] 👤 **Kraken:** connect a dedicated key with Query Funds only using the runbook's hidden prompts, then compare quantities against the app. No trading, transfers or withdrawal permissions. Other wallets/Futures and cost basis are outside current coverage.
  - [ ] **Capital.com / Ledger:** confirm which accounts to include; Ledger uses public addresses/xpubs only, never seeds or private keys.
  - [ ] **Swedbank / Revolut:** choose a personal open-banking connection or CSV import.
  - [ ] Decide whether to grow this into **Monifo as a personal self-hosted app** (P&L calendar, trade journal, dividends). Glance keeps a summary and link.

- 👤 Optional: Uptime Kuma **DNS** monitor for the resolver chain (Kuma has no monitor API — UI step): + Add New Monitor → DNS → hostname `example.com`, resolver `host.docker.internal` port 53 → alerts if Pi-hole *or* unbound stops answering.

### 🤖 An AI agent can do next

- Paperclip: recovery and reference repairs were applied and verified
  2026-09-29. A temporary unbound Claude → Codex takeover was applied on
  2026-09-30 with saved original models and a scheduled guarded return.
  PR #53's default-deny syscall policy is applied live; actual command tools
  and filesystem restrictions passed as server UID 1000, including a real
  model tool call. Coach/Dietitian secret references are repaired live and
  preserved in saved Claude configs. Runtime injection and Discord endpoint
  GET checks pass; actual normal post delivery still needs verification.
  STU-13's hold was cleared through supported recovery after proving its
  held admission was cancelled before provider execution. The issue is now In
  review after two resumed runs failed with `provider_quota`; a human-only
  vendor-access question is pending. Open STU-13 in Paperclip and answer it.
  No earlier outcomes were certified and no repeat approval was requested.
  Automatic quota routing is disabled; Paperclip's built-in monitor can retry
  a classified quota failure on the same task agent at reset/default backoff but
  does not change providers. The owner prefers Claude Max and asked
  for no further Codex-specific development.
  Channel migration separately needs the
  bot's Manage Channels and Manage Webhooks permissions.
  Recovery now isolates busy/changed/unavailable roles and failed probes,
  requires a real hello result, and preserves unresolved originals. This
  subscription helper excludes selected execution environments; host-login
  proof is insufficient for their separate credentials. Automatic routing
  across subscriptions and managed connections is deferred per the owner's
  Claude Max preference. Host-login tests do not prove managed credentials
  work; restoring a null binding currently retains OpenRouter. Keep
  auto-switch off. The guarded manual switch requires an existing active
  monthly hard-stop policy of $3 or less; `--switch --dry-run` previews it.

- [x] ~~Rotate the **Radarr + Sonarr API keys**~~ — **done 2026-09-27**
  (Prowlarr, Jellyseerr, Bazarr updated + tested; see changelog).

- Optional: OpenCode + `qwen2.5-coder:7b` for offline snippets — *⚡ Batch 2026-09-24*
- Odysseus: chat-export import, CalDAV after Nextcloud, RAG over Paperless + Linkwarden — *8. Odysseus*
- 👤 Rotate Immich's DB password (restarts Immich — say go) — *9. Maintenance backlog*
- 👤 `rm -rf ~/services/mealie ~/services/grafana` (say go) — *9. Maintenance backlog*
- Pi-hole local DNS records, only after a Caddy decision — *Pi-hole — finish the deployment*
- Optional `scp` push to the Scribe — *Notes*
- Major-version image upgrades, one per sitting, with `upgrade-service.sh` — *Pinned images*
- Calibre follow-up: NAS copy removal
  (~2026-10-02) — *Move the Calibre library off SMB onto the SSD*

---

## 🌐 Other repo backlogs

- `~/dev/peciulevicius.com/docs/TODO.md` — on the Worker, migrations v1.5.0 +
  v1.6.0 applied (2026-09-26). Open there: 👤 decide `checkOrigin` (one-click
  unsubscribe still 403s); 👤 `IP_HASH_SALT` secret; 👤 confirm the Resend
  domain; Claude runs the newsletter end-to-end test; optional 👤 delete the
  paused Pages project.
- `~/dev/janioniu-vynuogynas/docs/TODO.md` — live at
  https://janioniuvynuogynas.lt, Astro 7 + v1.0.0 done. Open there: 👤 Resend
  sending domain (no DNS records yet), Purelymail for `info@`, Workers Builds
  toggle, placeholder phone/facts, real contact-form test, PostHog/Loops/Web
  Analytics/Search Console. Your uncommitted local edits there will conflict
  on pull (see above).

## 🏃 Coach in the Claude app / phone — walkthrough with Claude

- [ ] 👤 Upload `config/claude/skills/adaptive-endurance-coach/` (zip) in
      claude.ai → Settings → Capabilities → Skills.
- [ ] 👤 claude.ai → Connectors → Add custom connector →
      `https://tp-mcp.peciulevicius.com/mcp`; confirm `tp_auth_status` from the
      phone. Check the official Strava connector is enabled. (Fallback OAuth
      client id is in your chat with Claude, not in this repo.)
- [ ] 👤 Claude Project "Coach" with the skill + pinned summary (the app can't read
      `~/ai-memory/training`).

## ✉️ Email identity

Details and the option table: `config/email/README.md`.

- [ ] 👤 **Gravatar** (recommended, free): gravatar.com → sign up with
      `dziugas@peciulevicius.com` → upload photo or logo. Optionally the logo
      on `hello@peciulevicius.com`. Shows in apps/some clients, not in Gmail
      or Apple Mail.
- [ ] 👤 **Install the signature** (v2, `config/email/`, no title line):
      Mac Mail — select the account in the **left column** (not "All
      Signatures") → + → paste from Safari → untick "Always match my default
      message font" → *Choose Signature*; or `install-mac-signature.sh` for
      the full light/dark logo swap. iPhone Mail — paste `signature.txt`
      (Settings → Apps → Mail → Signature → Per Account). Webmail optional.
- [ ] 👤 **Sender avatar in Gmail** — decide: accept the letter (default),
      Google-account photo (free, conflicts with de-Googling), or BIMI CMC
      (~$650+/yr — over budget). Deliverability itself is fine: mail-tester
      10/10 on 2026-09-29.

---

## ▶ The ordered path

**The order matters** — each step unblocks or de-risks the next. The reasoning
is written out so it survives being read cold in a year.

| # | Step | Why it is here and not later |
|---|---|---|
| **2** | ✅ ~~Move TOTP off Google Authenticator~~ | Done 2026-09-26 — codes in Bitwarden Authenticator |
| **3** | 🔴 Rotate the Vaultwarden admin token | Leaked into a container config on 2026-09-21 |
| **5** | ✅ ~~Revoke the Gmail app password~~ | Done 2026-09-26 |
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
      `~/ai-memory/training` mounted). Not in the claude.ai app/phone until the
      *Coach in the Claude app* steps are done — use Odysseus over Tailscale on
      the phone meanwhile.
- [ ] Optional, local models: no bigger model (RAM ceiling ~8B). OpenCode +
      `qwen2.5-coder:7b` for offline snippets only; point Odysseus's **Agent
      (OpenCode)** at Ollama for private or throwaway coding; keep Claude Code
      for real work.

### 📋 Open user steps — as of 2026-09-25

- [ ] 👤 **Email** — DNS + MX live on Purelymail 2026-09-25, Email Routing
      disabled, domain saved, `dziugas@` user created. Remaining:
      1. ~~Purelymail → Routing → catch-all `*@peciulevicius.com` → `dziugas@`~~ — done 2026-09-28
      2. Test: mail `inbox@peciulevicius.com` from Gmail, check webmail.
      3. ~~iPhone Apple Mail~~ — done 2026-09-28 (first folder created; more folders + Sieve filters later). Consumers
         were repointed 2026-09-26; revoke is in 🔝 Next up; the Gmail
         redirect decision is under *De-Google → Email*.
      4. Deliverability: first mails to Gmail landed in Spam (new domain, no
         reputation; SPF/DKIM/DMARC all pass). Mark *Not spam*, add
         `dziugas@` to contacts, keep sending real mail; check once with
         mail-tester.com (aim ≥ 9/10).
      ⚠️ `peciulevicius@purelymail.com` (admin) and `dziugas@peciulevicius.com`
      are **separate mailboxes** — log clients in as `dziugas@`, not the admin.

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

### 5. 🔁 Gmail consumers repointed — revoke left

All three were moved to Purelymail on 2026-09-26 (changelog); the test mails
and the revoke are in 🔝 Next up. Lesson kept here: **two of the three hid
their config in SQLite** (Calibre-Web, Uptime Kuma) rather than environment
variables, so an `env`-based audit reports "nothing uses email" and is wrong
(the 2026-09-21 audit made exactly that mistake). Calibre-Web fails
**silently** with no fallback. Full detail in [guides/EMAIL.md](guides/EMAIL.md) §2.
Revoke at <https://myaccount.google.com/apppasswords>.

### 6. 🔑 One pass per service — password AND email together

Both changes need the same ~14 logins. **Doing them separately means 28.**
Checklist, no secrets: [CREDENTIAL_MIGRATION.md](CREDENTIAL_MIGRATION.md) —
5 of ~18 services done. Worksheet with real values: `~/credentials-import.md`
(deliberately outside this public repo; still present 2026-09-26).

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

- [ ] 👤 **Automatic PR reviews:** connect `.dotfiles` in Codex's hosted code
  review settings and enable automatic review. Generate a Claude Code
  subscription token locally, save it as the repository secret
  `CLAUDE_CODE_OAUTH_TOKEN`, set `CLAUDE_PR_REVIEW_ENABLED=true`, and merge the
  review workflow PR. Both providers need account setup; no paid API key is
  configured. See [PR reviews](guides/PR_REVIEWS.md).

Full secret audit done (gitleaks over all 492 commits): only one leak ever —
the Uptime Kuma backup push token, public since **2026-05-09**. Rotated
2026-09-25; the pre-commit hook, CI and the weekly audit guard against a
repeat.

- [ ] 👤 **Enable the hook on the MacBook's clone too** — run
      `~/.dotfiles/scripts/sync.sh` there once (it sets `core.hooksPath`), then
      `brew install gitleaks`. (The statusline commit on 2026-09-23 came from a
      clone without it.) Can't be checked from the Mac mini.
- [ ] 👤 **Verify key-expiry policy for the MacBook and iPhone** in the
      Tailscale admin console. MacBook re-auth was recorded as complete on
      2026-09-28; do not ask to log in again based only on the older expired-key
      snapshot. The iPhone may appear as `localhost` (`iphone13mini`).

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

- [ ] 👤 **Verify physical power-loss recovery when you are present**, after
      choosing a maintenance window. `pmset -g custom` shows `autorestart 1`
      (checked 2026-09-29); Apple's installed `man pmset` defines it as restart
      on power loss. The earlier claim that it only handles kernel panics was
      wrong. Do not change an undocumented extra flag based on that claim.
      FileVault still requires a person to unlock the disk on cold boot.
- [ ] 👤 **Buy the UPS** already decided on 2026-09-28 — brief outages then
      never cut power at all, and FileVault stays. USB/HID required for the
      planned clean-shutdown setup; see the index above.
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
- [ ] 👤 **Cancel YouTube Music / YouTube Premium** (de-Google). Self-hosted
      music was dropped 2026-09-26 — Spotify stays (see changelog *Music setup
      removed*). The liked-songs list is kept privately in the Obsidian vault.
- [ ] 👤 **Delete the leftover NAS folder `/Volumes/media/music/`** — only the
      beets test leftovers remain (`Library/Zzbeetstest Artist/`, `.smbdelete*`
      ghosts, 116K). Claude's `rm -rf` was blocked by permissions 2026-09-26.
      The ghosts are held open by Docker Desktop's VM, so do it after the next
      Docker Desktop restart: `rm -rf /Volumes/media/music`.
- [ ] 👤 **Delete the old staged dirs** `rm -rf ~/services/beets ~/services/lidarr`
      (containers and images already removed 2026-09-26), and after a week of
      Uptime Kuma running fine, `rm ~/services/uptime-kuma/data/kuma.db.bak-2026-09-26-music`.
- [ ] **Optional immediate library refresh while a media server is awake.**
      The 30-minute restart cron was removed 2026-09-28 (verified absent in
      the installed crontab 2026-09-29); it woke Sablier sleepers and interrupted
      playback. Sleeping apps scan when they next start. The remaining API
      integrations could refresh new items during a long-running session:
      - [ ] 👤 **Jellyfin** — dashboard → Admin → **API Keys → +** → send me the
            key, I'll wire it into Radarr's and Sonarr's Settings → Connect.
            Instant refresh, no restart, no playback interruption.
      - [ ] 👤 **Audiobookshelf** — same idea (Settings → API Keys), but check
            whether LazyLibrarian even supports a "notify on import" hook for
            it first — unconfirmed as of 2026-09-22.
- [ ] 👤 🔴 **Rotate Immich's database password** (with a go-ahead — it
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
- [ ] 👤 Clear the leftover data directories from the removals:
      `rm -rf ~/services/mealie ~/services/grafana` (both confirmed
      empty/unused before removal; both still present 2026-09-25).
      `rclone-backup.sh` already excludes both.
- [x] **Scale-to-zero rollout (Caddy + Sablier, `services/caddy/README.md`)
      — all 3 phases done 2026-09-27.** Phase 1: Stirling PDF, IT-Tools.
      Phase 2: Paperless, Nextcloud, Odysseus, Linkwarden, Jellyseerr, Bazarr.
      Phase 3: Calibre-Web, Audiobookshelf, Jellyfin (2h idle instead of 30m
      for the media two; each also reachable directly on the Tailscale IP
      now, same as the phase 2 three, since LAN/TV clients were bypassing
      Caddy). All 11 services tested cold-start through the real public
      hostname and/or Tailscale port and idle-stop with a 2m test duration
      before setting the real one. Bazarr's, Jellyseerr's, Nextcloud's,
      Calibre-Web's and Audiobookshelf's missing Docker healthchecks each
      caused (or would have caused) a 502 race — fixed on all five (see the
      README "Gotchas"). Known accepted gap: Jellyseerr calls Jellyfin
      directly over the Docker network for its background sync, which can't
      wake a sleeping Jellyfin — not fixed, documented.
      - [ ] 👤 Uptime Kuma has no config-file/API for creating or pausing
        monitors — pause the monitors for every Sablier-managed service that
        has one (Stirling PDF, IT-Tools, Paperless-ngx, Nextcloud,
        Linkwarden, Jellyseerr, Bazarr, Calibre-Web, Audiobookshelf, Jellyfin
        — Odysseus wasn't monitored) and add one active monitor each for
        Caddy (`127.0.0.1:8880`, e.g. via the tunnel) and Sablier, so the
        proxy itself being down is still caught even though the apps behind
        it are expected to look stopped.
      - [ ] 👤 Test Jellyfin on the TV app, Audiobookshelf on the phone app,
        and KOReader's OPDS feed (Calibre-Web) each after they've gone to
        sleep — confirm all three reconnect within the timeout instead of
        just showing an error, and that Audiobookshelf progress sync survives
        a stop/start cycle. (Automated `curl` testing already confirmed the
        OPDS cold-start returns `401` within timeout and that the tunnel
        hostnames work — this item is specifically about the real apps on
        real devices, which a terminal can't stand in for.)
- [ ] 👤 **Nextcloud + Paperless-ngx keep-or-remove — decide later, no rush.**
      Both scale to zero automatically now (2026-09-27, see above) instead of
      needing a manual `ondemand start`, but the keep-or-remove question
      itself is unrelated to that and still parked, not answered. What each
      would be kept for:
      - *Nextcloud* — 83MB of real files; its only non-redundant features are
        CalDAV/CardDAV (see *Calendar + Contacts* — that plan needs it
        reachable, which scale-to-zero still allows, just with a cold-start
        delay on the first request) and the WebDAV target for a Supernote, if
        one is ever bought. ⚠️ Don't use Nextcloud's Notes app (2.3★,
        disconnects); Obsidian is the notes tool.
      - *Paperless-ngx* — 14 real scanned documents; OCR + a tagged,
        searchable archive, which an Odysseus chat upload is not. While
        asleep it doesn't consume or OCR anything, so scan in batches with
        it open.

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
      itself runs hourly — since 2026-09-26 10:00 against
      `imap.purelymail.com`, "No new Kindle export emails".

---

## Detail and standing items

Background for the steps above, plus items outside the sequence.

### 💾 Disk — 23GiB free of 228GB (89%) on 2026-09-28, ~38GiB once the Trash is emptied

**2026-09-28 cleanup** (from 17GiB / 92%): Docker unused images + build cache
pruned (~3.8GB), brew/npm/pnpm/pip caches cleaned; moved to
`~/.Trash/cleanup-2026-09-28` (15GB, recoverable until the Trash is emptied):
Claude desktop `vm_bundles` (10GB), Brave caches, the Google cache folder,
Bitwarden update staging. Chrome's *profile* and app were left alone
(claude-in-chrome runs there). DB dumps in `~/backups` (2.2GB) are pruned by
`backup-databases.sh` after 30 days — left as is.

- [ ] 👤 Empty the Trash — that's what actually frees the 15GB.


Evening cleanup took it from **18GiB free (92%)** to **23GiB (89%)** — see the
changelog. Measure with `df -h /System/Volumes/Data`: plain `df -h /` shows the
sealed system volume (11GiB used) and hides the real usage. Earlier history:
15GiB (92%) before the 2026-09-21 cleanup, 27GiB (87%) on the morning of
2026-09-26. It fills fast — Paperclip alone is 6.7GB and app update staging
recurs.

| What | Size (2026-09-26 evening) |
|---|---|
| Docker (`Docker.raw`) | **47GB** allocated (50GB before prunes); ~46GB used inside the VM |
| `~/Library/Application Support/Claude/vm_bundles` | 10GB — Claude desktop's VM image |
| Google Chrome (profile 6.0GB, cache 1.2GB, updater 773MB, app 1.4GB) | ~9.4GB |
| `~/services` (service data) | 13GB — live, leave it |
| `~/dev` | 7.0GB (≈1.75GB of it `node_modules`) |
| `~/.ollama/models` | 6.2GB — qwen2.5:7b + llama3.2:3b, in use |
| Squirrel/ShipIt + updater staging | 2.6GB — updates waiting to install |
| iMovie + GarageBand | 4.8GB |

👤 Your call. Each item frees the space shown and none of them is service data:

- [ ] **App update staging (2.6GB).** Quit and reopen Bitwarden, Notion and VS
      Code so the staged updates install, then:
      `rm -rf ~/Library/Caches/{com.microsoft.VSCode.ShipIt,com.bitwarden.desktop.ShipIt,bitwarden-updater,notion.id.ShipIt,notion-updater}`
- [x] ~~**Claude desktop VM bundle (10GB)**~~ — moved to Trash 2026-09-28
- [ ] **Chrome (~9.4GB).** De-Googling, but the claude-in-chrome extension
      runs in it, so only if you move that to another browser: drag Chrome to
      the Trash, then `rm -rf ~/Library/Application\ Support/Google ~/Library/Caches/Google`
- [ ] **iMovie + GarageBand (4.8GB)**, if unused:
      `rm -rf /Applications/iMovie.app /Applications/GarageBand.app` (both can be reinstalled from the App Store)
- [ ] **Temp dirs left by earlier agents (~840MB):**
      `rm -rf /tmp/paperclip.VADn /tmp/truthpass /tmp/mkdocs-venv-music /tmp/mk /tmp/mkv /tmp/mk-site /tmp/mkd /tmp/mk.log /tmp/astro7-shots /tmp/pw /tmp/gdprtest`
      (leave `/tmp/claude-501`: Claude Code is using it)
- [ ] **DB dumps older than 7 days (352MB):** immich + paperless from 08-30,
      09-06 and 09-13. This also settles 30-day retention:
      `find ~/backups -maxdepth 1 -name '*.sql' -mtime +7 -delete`
- [ ] **Small pre-change backups older than 7 days (4.7MB):**
      `rm -rf ~/backups/{calibre-repair,vault-snapshots,vaultwarden-preupgrade}`
- [ ] **`node_modules` in `~/dev` (1.75GB).** They come back with `pnpm install`:
      `find ~/dev -maxdepth 2 -name node_modules -type d -prune -exec rm -rf {} +`
- [ ] **Playwright browsers (557MB).** Reinstall with `pnpm exec playwright install chromium`:
      `rm -rf ~/Library/Caches/ms-playwright`
- [ ] **Homebrew download cache (230MB):** `rm -rf "$(brew --cache)"`
- [ ] **Leftover `~/services/{mealie,grafana}`** (already listed in *9. Maintenance backlog*):
      `rm -rf ~/services/mealie ~/services/grafana`

Checked on 2026-09-26 and nothing to do: Trash 616KB, `~/Downloads` 1.4MB
(Takeout is 236KB), `~/services/*/*.bak*` 24KB, no Time Machine local
snapshots.
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

### ⚠️ Pinned images — what WUD says is available

Watchtower only refreshes a container's *current* tag, so pinned images never
move on their own. Since 2026-09-28 **WUD** (`services/wud`) checks every
container daily; the Glance **Updates** widget and a Monday Discord summary
show what's available, and **`scripts/utils/upgrade-service.sh <service>
[tag]`** applies one upgrade with backup, health check and automatic rollback
(details: `services/wud/README.md`). This replaced the quarterly
`check-image-updates.py` cron (the script still works by hand).

Why pins stay: this cost four hours on 2026-09-21 — the Bitwarden iOS app was
broken by a bug fixed three Vaultwarden releases earlier, and the pin hid it.
Every request logged **200 OK** while the app failed. **When a client
misbehaves against a healthy-looking server, compare versions first.**

**Available on 2026-09-28** (`update-report.sh --markdown`; Bazarr
1.6.1 → 1.6.2 was applied the same day as the first real `upgrade-service.sh`
run):

| Container | Service | Current | Available | Kind | Note |
|---|---|---|---|---|---|
| odysseus-searxng-1 | odysseus | `2026.5.31-7159b8aed` | `2026.9.25-d8ae3abd5` | minor | upgrade-service.sh |
| jellyfin | jellyfin | `10.10.7` | `12.1.20260915-010956` | major | read release notes |
| nextcloud | nextcloud | `30-apache` | `35-apache` | major | read release notes |
| paperless | paperless-ngx | `2.20.15` | `3.2.1` | major | read release notes |
| stirling_pdf | stirling-pdf | `2.14.3` | `3.0.0` | major | read release notes |
| syncthing | syncthing | `1.30.0` | `2.1.5` | major | read release notes |
| uptime_kuma | uptime-kuma | `1.23.17` | `2.5.5` | major | read release notes |
| calibre_web | calibre-web | `0.6.27` | `5.33.2` | major | False positive (linuxserver -lsNNN tags) until the wud.tag.include label applies on next recreate |
| immich_postgres | immich | `14-vectorchord0.3.0-pgvectors0.2.0` | `18-vectorchord1.1.1-pgvector0.8.5` | major | Immich pins its own Postgres image; upgrade only with an Immich release that asks for it |
| immich_redis | immich | `7.4-alpine` | `8.10-alpine3.23` | major | Immich pins Redis; follow Immich's compose |
| linkwarden_db | linkwarden | `16-alpine` | `18-alpine3.24` | major | Postgres major = dump/restore migration, not a tag bump |
| nextcloud_db | nextcloud | `11.4` | `13.0` | major | MariaDB major = migration; follow Nextcloud's supported versions |
| paperless_broker | paperless-ngx | `7.4-alpine` | `8.10-alpine3.23` | major | Redis major; no need unless Paperless requires it |
| paperless_db | paperless-ngx | `16-alpine` | `18-alpine3.24` | major | Postgres major = dump/restore migration, not a tag bump |

Notes on the list:
- **Safe:** `odysseus-searxng-1` (minor) — `upgrade-service.sh odysseus
  --image searxng` whenever convenient.
- **Jellyfin:** WUD proposed a dated build (`12.1.2026…`); the
  `wud.tag.include` label (plain `X.Y.Z` only) applies on the next recreate and
  will show the real stable target — 10.11.x and 12.x both exist, both are
  one-way DB migrations (notes below).
- **Held** rows are in `services/wud/holds.tsv` and are never offered.

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
  - **Paperless-ngx 2 → 3**: Django migrations + possible OCR/config renames.
    `pg_dump` + `document_exporter` to `data/export` first; rollback = restore
    the dump into the 2.20.15 tag. Only if Paperless survives the
    keep/remove decision.
  - **Stirling PDF 2.14 → 3.x**: 2.14.3 taken 2026-09-26 (changelog). WUD
    still reports 3.0.0 as newest (2026-09-28) — wait for a 3.0.x point
    release, re-read its notes, check `SECURITY_ENABLELOGIN=false` still applies.
  - **Nextcloud 30 → 31 → 32 …**: 30 is end-of-life. Must step one major at
    a time (`occ upgrade` each), maintenance mode, MariaDB dump first
    (`backup-databases.sh`), check apps compatibility per step. Biggest job
    here — schedule an evening.
  - 👤 **After ~2026-10-03, if Stirling/Prowlarr/Radarr are still fine:**
    `rm -rf ~/backups/{stirling-pdf,prowlarr,radarr}-2026-09-26` (pre-upgrade
    tars + old image digests; rollback = old tag from `old-image.txt` +
    untar over `data/`).
  - **Postgres 16 → 17/18, MariaDB 11.4 → 12/13, Redis 7 → 8**: data-dir
    format changes; Postgres needs dump/restore into a fresh volume. Stay on
    16 / 11.4 LTS / 7.4 until a reason appears — all floating tags were
    verified current on 2026-09-25.

**Process, not a one-off:** bump deliberately, one service at a time, reading
release notes and backing up data first — that is why they are pinned, and
pinning is still the right call. But schedule it; quarterly is enough.
`docker compose pull` will not help while the tag is fixed.

**Tracking:** WUD + `update-report.sh` (daily Glance widget, weekly Discord)
since 2026-09-28 — see the top of this section. Do majors with
`upgrade-service.sh`, one per sitting, after the backup each note above asks
for (the script's own compose backup and DB dump don't cover app data dirs).

### ⚠️ Move the Calibre library off SMB onto the SSD

Done 2026-09-25 by a one-off script (removed 2026-09-26, see git history:
`git log --all -- scripts/utils/migrate-calibre-to-ssd.sh`) — library now at
`~/services/calibre/library` (why and how: changelog). Rollback until the NAS
copy is deleted — each service kept its old `.env` as `.env.pre-ssd-migration`:

```bash
for s in calibre calibre-web lazylibrarian; do
  mv ~/services/$s/.env.pre-ssd-migration ~/services/$s/.env
  docker compose -f ~/services/$s/docker-compose.yml up -d
done
```

Follow-ups left:

- [ ] 👤 Verify OPDS still serves to KOReader afterwards, and that Calibre-Web
      opens a shelf (the old `disk I/O error` path) — server side checked
      2026-09-25 (login 200, OPDS answers 401 Basic, no DB errors); the
      logged-in KOReader + shelf check needs you
- [ ] After a week (~2026-10-02): delete `/Volumes/books` from the NAS via
      UGOS, then drop the "frozen rollback copy" note from the `BOOKS_DIR`
      row in `NAS.md` and `HOME_SERVER_REFERENCE.md`, and the `.env.pre-ssd-migration`
      files in `~/services/{calibre,calibre-web,lazylibrarian}/`

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

- [x] Pi-hole on every device via Tailscale — nameserver `100.81.171.49` + Override local DNS set by the user 2026-09-26.
- Curated blocklists (HaGeZi Multi Pro + TIF medium, 2026-09-25, changelog):
  if a site breaks, check the Pi-hole query log and allowlist the domain.
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

Last measured before the v6 upgrade and HaGeZi lists: ~3.6% of queries blocked
(12,812 queries / 459 blocked) — low because the router still does not point at
Pi-hole, so only manually configured devices use it.

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

Only if Paperless is kept — it is on-demand for now (`ondemand start
paperless-ngx`), see *9. Maintenance backlog*. Paperless-NGX doesn't support traditional folders — it uses **tags**,
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

**Goal:** Route Transmission traffic through Mullvad so the ISP can't see torrent
activity and peers/trackers don't see the home IP. Not urgent.

Built 2026-09-26: Transmission now sits behind a Tailscale sidecar
(`transmission-ts`), ready for a Mullvad exit node via the Tailscale add-on —
replaces the old Gluetun plan. Details and the switch-on steps:
`services/transmission/README.md` → *Tailscale sidecar*.

- [x] ~~👤 Buy the Tailscale Mullvad add-on and allow `transmission-ts` + the phone~~ — 2026-09-28
- [x] ~~Disable key expiry on `transmission-ts`~~ — recorded complete
      2026-09-28 in the VPN index above; no repeat action needed.
- [x] ~~Claude: exit node~~ — `se-sto-wg-201` (Stockholm), web UI + Sonarr/Radarr tests pass (2026-09-28)
- [x] ~~Claude: leak test~~ — Transmission's user egresses as a Mullvad IP (2026-09-28)
- [x] ~~Claude: kill-switch test~~ — it **did** leak on restart; fixed with
      `killswitch.sh` (policy routing, fail-closed), all scenarios re-tested
      (2026-09-28). Details: `services/transmission/README.md` → *Kill switch*.
- [ ] Optional: torrent-IP checker magnet (ipleak.net) next time a download runs.
- Rollback, if ever needed: `~/backups/transmission-2026-09-26/` holds the
  pre-sidecar compose + config + image digest (steps in the README).

### Notes — make capture frictionless before changing tools

**Full plan: [guides/NOTES.md](guides/NOTES.md).** The vault, routing rules and
Kindle sync all exist and go unused. The problem is capture friction, not the
tool — swapping Obsidian for something else reproduces the same failure later.
Sync: see *🔗 Obsidian LiveSync* (server done, devices pending). Kindle sync is
verified running hourly on the Mac mini, over Purelymail IMAP (2026-09-26).

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
(2026-09-25), with the three mail consumers moved over (2026-09-26). Remaining
gaps: **moving accounts over, phone, calendar/contacts, AI.** Don't restart
from step one.

Google Authenticator → ✅ moved to Bitwarden Authenticator 2026-09-26 — do it
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
Revoke + Kindle filter → *🔝 Next up*; catch-all/tests/deliverability → *📋 Open user steps*.

- [ ] 👤 **Decide the Gmail redirect**: full forward (Gmail → Settings →
      Forwarding → all mail to `dziugas@`, and `dziugas@` as default "Send mail
      as") so everything lands in one inbox, or the Kindle-only filter from
      *🔝 Next up* and let Gmail wither.
- [ ] 👤 Import the Gmail Takeout `.mbox` into Purelymail (optional — only if
      you want the history in one place).
- [ ] 👤 Remove Google as a Cloudflare Access identity provider — **after** the
      logins have moved.

#### Calendar + Contacts — Radicale is up (2026-09-28), your import is next

**Superseded the Nextcloud plan:** calendar, contacts and to-dos now go to
**Radicale** (`services/radicale/`, `http://100.81.171.49:5232/`, Tailscale
only). Nextcloud's keep-or-remove decision is separate. Still urgent: the
iPhone holds the **only copy** of contacts and calendar (checked 2026-09-22).
Steps: `services/radicale/README.md`.

- [ ] 👤 Save the Radicale password to Vaultwarden (`~/.config/homelab/radicale.env`)
- [ ] 👤 **Export first:** contacts → vCard, calendar → via Finder sync + Mac Calendar export
- [ ] 👤 Add the CalDAV + CardDAV accounts on the Mac and iPhone; import the vCard + `.ics` into Radicale; set Radicale as default calendar / contacts / Reminders list
- [ ] 👤 Backup test: re-add the account on one device and confirm everything re-downloads

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
