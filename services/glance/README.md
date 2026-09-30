# Glance

Dashboard/start page (`glanceapp/glance`), served at `home.peciulevicius.com`
and `http://100.81.171.49:7575` / `http://localhost:7575`. Config is
version-controlled here; the live copy is a **copy**, not a symlink — see
`~/.dotfiles/.claude/CLAUDE.md` and the `homelab-service` skill for the
copy → diff → recreate workflow.

## Layout (redesigned 2026-09-27)

**Home page** (three columns since 2026-09-28): a `small` **left** column for
the homelab, a `full`-width middle column for services, and a `small`
**right** column for the athlete team.

Left, top to bottom: `clock` (24h), **Server** (the former Homelab health
widget plus CPU, containers and uptime), **Sleeping apps**, **Updates**
(image updates from WUD via `scripts/utils/update-report.sh` →
`assets/updates.json`, see `services/wud/README.md`), `dns-stats` (Pi-hole). Right: **Today** (Radicale events + tasks, added 2026-09-28), **Training**,
**Coach team**, `repository` (this repo), `calendar`. `weather` was removed and Glance's built-in `server-stats` was
dropped 2026-09-28: inside Docker Desktop it reports the Linux VM, not the Mac,
so its numbers disagreed with the Server widget. The **Media** page was
removed the same day (two subreddits and app release notes — not used). The standalone ntfy was removed entirely (2026-09-28); the Coach team posts
to Discord.

Main column:
1. **`monitor` — "Always-On Services"**: a compact status grid, `check-url`
   against every service that is *not* Sablier-managed. 19 sites.
2. **`bookmarks`**: every service on the homelab, exactly once, grouped by
   purpose — **Media**, **Files & Docs**, **Security & Network**, **AI &
   Agents**, **Ops**. Scale-to-zero apps carry no marker any more (the 💤
   prefix and its legend were removed 2026-09-28); their live state is the
   **Sleeping apps** widget.
3. **`docker-containers` — "Live Status"**: `running-only: true`, which
   containers are up right now.

## Today widget (added 2026-09-28)

Top of the right column. Today's and tomorrow's events and up to 8 open tasks
(overdue in red) from Radicale, read from `./assets/calendar.json`, which
`scripts/utils/calendar-status.sh` writes every 5 min over CalDAV. Glance
never talks to Radicale for this widget; the separate monitor entry checks
`http://radicale:5232/.web/` on the `radicale` network.

## Server widget (added 2026-09-27 as "Homelab health")

A `custom-api` widget in the left column. It shows:
- CPU (1-min load average ÷ cores), containers running / total, Mac uptime
- Docker VM memory, macOS swap, and disk usage (Mac data volume and NAS)
- how long ago the R2 backup, the DB dumps and the T5/T7 drive backups ran
(the 💤 count, Paperclip queue, check-in age and Dietitian line moved to
their own widgets on 2026-09-28, see below)

Each value is coloured green, amber or red.

**How it works.** Glance can't see any of that from inside its container:
macOS swap, the APFS *data* volume (`df /` only shows the sealed system
volume, ~38%, while the real disk is ~90%), backup stamps in `~/logs`, the
Paperclip board and `~/ai-memory/training/`. So `scripts/utils/homelab-status.sh` runs on
the host every 5 minutes (cron) and writes
`~/services/glance/assets/status.json`.

Glance serves that directory at `/assets/` (`server.assets-path: /app/assets`,
mounted `./assets:/app/assets:ro`). The widget fetches
`http://localhost:8080/assets/status.json`, which is Glance talking to itself,
so it never touches another service and can't wake a sleeper.

The script computes a level (`ok` / `warn` / `bad`) for every value.
`assets/health.css` (loaded through `theme.custom-css-file`) colours the
`lvl-*` classes, because the stock palette has no amber. `setup-services.sh`
copies the files in `assets/` individually, so `status.json` is never
overwritten by staging.

Thresholds are in the script:

| Value | Amber | Red |
|---|---|---|
| Docker memory | 80% | 92% |
| macOS swap | 75% | 90% |
| Mac disk | 85% | 93% |
| NAS disk | 80% | 90% |
| R2 backup | 26 h | 50 h, or the last run didn't finish |
| DB dumps | 8 d | 15 d |
| T5 / T7 | 35 d | 60 d |
| Coach check-in | 26 h | 50 h |

## Training, Coach team and Sleeping apps widgets (added 2026-09-28)

Three more `custom-api` widgets read the **same** `status.json`:

- **Training:** days to IRONMAN 70.3 Luxembourg (11 Jul 2027), with
  fitness · fatigue · form (CTL · ATL · TSB). Also weight and body fat now, each
  with its change against 7 days earlier, and last night's HRV, resting HR and
  sleep. Then this week's done/planned sessions, TSS and hours, and today's
  planned session. Source: the TrainingPeaks MCP (`127.0.0.1:8092`), read-only
  tools only (`tp_auth_status`, `tp_get_fitness`, `tp_get_weekly_summary`,
  `tp_get_metrics`). The script caches the result for **30 min** in
  `~/.cache/homelab-status/tp.json`, so TrainingPeaks sees at most ~48 calls
  a day. If the TP cookie has expired, the widget says "TP login expired" and
  links nothing else (refresh steps: `services/trainingpeaks-mcp/README.md`).
  Form turns amber below −10 and red below −25.
- **Coach team:** the first 4 lines of the Coach's latest *Daily check-in*
  comment (markdown headers dropped), the Dietitian's `today.md` line, what
  Paperclip is waiting on you for, and links to the two Discord channels and
  Paperclip.
- **Sleeping apps:** all 11 Sablier groups with 🟢 awake / 💤 asleep and a
  link to each (clicking wakes it). Awake apps sort first. State comes from
  `docker ps`, never from requesting the app.

Personal numbers (weight, HRV, check-in text) exist only in the generated
files under `~/services/glance/assets/` and `~/.cache/`, which are outside
the repo. Nothing personal is committed.

**Refresh:** the script runs every 5 min (cron). The widgets re-read the file
every minute, and each footer shows "updated HH:MM · refreshes every 5 min".
TrainingPeaks data can be up to 30 min old on top of that.

**If it looks stale:** the "updated HH:MM" line at the bottom is the
script's last run. Run `~/.dotfiles/scripts/utils/homelab-status.sh --print`
(the output contains no secrets) and check `~/logs/homelab-status.log`. The
Paperclip board password is read from `~/.config/homelab/paperclip-admin.env`
and only ever sent to the local API. "Paperclip unreachable" means the login
failed or the container is down.

**Feed / Media / Finance pages** are unchanged except the **Media** page's
own `bookmarks` widget was removed — those tiles now live once, on Home, in
the Media group. Feed/Media/Finance keep their reddit/release/market feeds.

## Finance page (rebuilt 2026-09-28)

Three columns, native widgets only:
- **Left:** **Portfolio** (`custom-api`, reads `/assets/finance.json`) and
  **Watchlist** (`markets`, Yahoo symbols).
- **Middle:** **Personal Finance** (reddit).
- **Right:** **Learn & markets** RSS (Babypips + WSJ Markets, 8 items, 4
  shown).

TradingView embeds (chart, ticker tape, technical gauge, news, economic
calendar) were tried the same day and removed. They frame fine (no
`X-Frame-Options`/`frame-ancestors`), but they render as light boxes that
clash with the dark theme.

### Portfolio: direct IBKR and Trading 212 feeds

Wallet was removed on 2026-09-30 at the user's request: a successful Wallet
API request did not establish that its manually maintained balances were
accurate. The collector no longer reads its token, account balances or budgets.

`scripts/utils/finance-status.sh` calls `finance-data.py` daily at 07:00 and
writes `~/services/glance/assets/finance.json`. Each broker has a separate
status, native-currency value, source and date. **Connected investments** is
only the sum of connected broker accounts, not total personal net worth.
IBKR uses its reported end-of-day NAV. Trading 212 uses the reported live
account total; its cash and investments are not added to that total again.
Trading 212 currently supplies account totals and unrealised P&L; individual
holdings on this card come from IBKR only.

The combined total defaults to EUR (`FINANCE_REPORT_CURRENCY` can override
it). Cross-currency totals use Frankfurter daily reference rates, whose date
is retained in the snapshot. Native balances remain visible if FX fails; that
provider is excluded from the combined total with a warning. Missing amounts
are not silently treated as zero. A malformed/multi-account IBKR report is
rejected rather than partly counted. Daily P&L and unrealised percentages
were removed: the old cash-adjusted NAV change was not pure trading P&L, and
the percentage used cash in its denominator.

Caches are private (`~/.config/homelab/finance-cache/`, directory 700/files
600), keyed to the current credentials, and contain native amounts. IBKR's
cache lasts 30 minutes; Trading 212's lasts two minutes. Fetch failures retain
that account's last valid cache and mark it stale. Rotating credentials does
not reuse the previous account's cache. The served snapshot contains private
balances; retain Glance's existing access protection and never commit it.

#### IBKR setup

1. Client Portal → **Reporting → Flex Queries** → create an Activity Flex
   Query named `glance`. Choose **one account**, **Last Business Day**, XML,
   date format `yyyyMMdd`. Include **Account Information** (base currency),
   **Open Positions** (Summary; symbol, position value, currency,
   FX rate to base, FIFO unrealised P&L), **Cash Report**, and **NAV in Base /
   Change in NAV** (ending value and currency). Save the Query ID.
2. On the Flex Queries page, open **Flex Web Service Configuration**, enable
   it and create a token. Its maximum validity is one year; renew before
   expiry. See the official [token setup](https://www.interactivebrokers.com/docs/web-api/flex-web-service/client-portal-configuration/enable-and-create-access-token).
3. Save locally with hidden prompts (works in zsh). Do not paste credentials
   into chat or print the environment file:

   ```bash
   mkdir -p ~/.config/homelab
   printf 'Flex token: '; read -rs FINANCE_IBKR_TOKEN; printf '\n'
   printf 'Query ID: '; read -r FINANCE_IBKR_QUERY
   umask 077
   printf 'IBKR_FLEX_TOKEN=%s\nIBKR_FLEX_QUERY_ID=%s\n' "$FINANCE_IBKR_TOKEN" "$FINANCE_IBKR_QUERY" > ~/.config/homelab/ibkr-flex.env
   chmod 600 ~/.config/homelab/ibkr-flex.env
   unset FINANCE_IBKR_TOKEN FINANCE_IBKR_QUERY
   ```

#### Trading 212 setup

The official API supports **Invest and Stocks ISA**, not CFD accounts, and
uses an **API Key + API Secret** pair with HTTP Basic authentication. Create
an account-specific key with **account data read permission only**; do not
enable orders or other write permissions. This collector only makes one GET
request to `/api/v0/equity/account/summary` (limit: one request per five
seconds). See [key creation](https://helpcentre.trading212.com/hc/en-us/articles/14584770928157-Trading-212-API-key)
and the [account summary schema](https://docs.trading212.com/api/accounts/getaccountsummary).

```bash
mkdir -p ~/.config/homelab
printf 'Trading 212 API key: '; read -rs FINANCE_T212_KEY; printf '\n'
printf 'Trading 212 API secret: '; read -rs FINANCE_T212_SECRET; printf '\n'
umask 077
printf 'TRADING212_API_KEY=%s\nTRADING212_API_SECRET=%s\n' "$FINANCE_T212_KEY" "$FINANCE_T212_SECRET" > ~/.config/homelab/trading212.env
chmod 600 ~/.config/homelab/trading212.env
unset FINANCE_T212_KEY FINANCE_T212_SECRET
```

#### Check and reconcile

```bash
bash scripts/utils/finance-status.sh
bash scripts/utils/finance-status.sh --health
```

`--health` makes no API calls and prints no balances, tokens or account IDs.
`ok` means parsed data is available, possibly from the last valid cache; check
`stale` too. It does **not** confirm numerical accuracy. In Glance, compare
each native account total with its broker app, using the same account and
date (IBKR is end-of-day, Trading 212 is live). Check the combined total only
after each provider reconciles. `--print` includes private financial data and
is for local use only.

For a saved IBKR report, isolate the output and cache locations; other broker
calls and live provider cache data writes are disabled in this mode:

```bash
OUT_DIR=/private/tmp/finance-preview FINANCE_CACHE_DIR=/private/tmp/finance-preview-cache bash scripts/utils/finance-status.sh --from-file /path/to/report.xml
```

At 07:05, `finance-memory-snapshot.sh` writes a private summary under
`~/ai-memory/finance/`. It records source coverage and freshness, excludes
Wallet budgets, and compares prior-month values only with the same schema,
providers and currency. Legacy Wallet summaries remain historical records
and are not used for the new portfolio's change calculation.

#### Further accounts

- **Kraken**: planned read-only exchange balance integration; not implemented.
- **Capital.com**: planned account integration; not implemented.
- **Ledger**: public addresses and price lookup; no seed or private keys.
- **Swedbank / Revolut**: choose a personal open-banking connection or CSV import.

Credentials and initial broker reconciliation still require the account
owner. New connectors should report their own coverage and account types,
not silently expand this number into total personal net worth.

## Why no `check-url` for Sablier-managed (💤) services

`services/caddy/` fronts ~11 services with scale-to-zero. Hitting one of
those containers directly with a `check-url`:

- **times out** while it's asleep (the container isn't running to answer), or
- **wakes it** on every poll interval, if pointed at the public hostname
  instead — defeating the point of scale-to-zero.

**Evaluated and rejected**, 2026-09-27:

- **Sablier's own API** (`http://sablier:10000`, reachable from Glance if it
  joined the `caddy_default` network) — checked the docs
  (`sablierapp.dev/reference`, `/how-to-guides/readiness/`) and the source.
  There is **no read-only status endpoint**. The only HTTP routes are
  `/api/strategies/{blocking,dynamic}`, which are the routes the *reverse
  proxy* calls to start a session — hitting them from Glance would start the
  group, the exact thing to avoid.
- **`docker-containers` widget filtered by `glance.category` label** — Glance
  supports this via a Docker label on each container, but that means adding
  `labels: glance.category: sleepers` to all ~11 Sablier-managed services'
  `docker-compose.yml` files and recreating each one — out of scope for a
  homepage change, and each recreate is a small availability blip for no
  real gain over what's below.

**What's actually in place instead**: the existing `running-only: true`
`docker-containers` widget already does the right thing for free — a
stopped/asleep container simply doesn't appear in it (no false "down"), and
a container Sablier just started appears the moment it's up, all without
Glance issuing a single request to the app itself. Combined with the 💤
bookmark, that's "state without waking" without touching 11 other services.

## UGREEN NAS check-url

`http://DH4300PLUS-DP.local:9999/` (mDNS `.local`) — kept as documented in
`docs/NAS.md` ("never an IP — its IP drifted three times"), **not** switched
to a raw IP. Verified 2026-09-27: `docker exec glance getent hosts
DH4300PLUS-DP.local` resolves correctly (Docker Desktop on macOS relays
`.local`/mDNS queries from containers to the host resolver), and the monitor
shows `200 OK`. Added `timeout: 5s` (up from Glance's 3s default) as a
cushion against the occasional slow resolve, since the NAS isn't on a DHCP
reservation yet (see `HOME_SERVER_TODO.md`).

## GitHub Repository widget

Shows `peciulevicius/.dotfiles`. The repo is **public**, so the widget needs
**no token** — leave `GITHUB_TOKEN` empty in `~/services/glance/.env`
(unauthenticated API: 60 requests/hour, plenty for a homepage).

History (2026-09-27): the widget showed `404` because the repo had briefly
been made private. A `gh auth token` (the user's full-scope GitHub login
token) was put into Glance's `.env` as a quick fix — **removed the same day**:
a container env var is the wrong place for a token that can push to every
repo. If a private repo ever needs showing, use a fine-grained token scoped
to that one repo with read-only *Metadata* + *Contents*.

## Networks

Glance joins one Docker network per service it needs to reach by container
name for a `check-url` (see `docker-compose.yml`). Added 2026-09-27:
`calibre` (the linuxserver/calibre GUI, `services/calibre/`) and `syncthing`
— both were missing, so those two services could only ever be bookmarks, not
monitored.

## Adding a new service to this page

See the `homelab-service` skill's "Adding a service" step 5 — amended
2026-09-27: a Sablier-managed (scale-to-zero) service gets a 💤-prefixed
bookmark in the right purpose group, **not** a `monitor` entry with
`check-url` (see "Why no check-url" above). Everything else still gets a
`monitor` entry + bookmark + a network join if its `check-url` needs one.
