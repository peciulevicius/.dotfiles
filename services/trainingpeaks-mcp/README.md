# TrainingPeaks MCP

Gives the AI coach (`adaptive-endurance-coach` skill, in Claude Code and
Odysseus) read **and write** access to TrainingPeaks: workouts, fitness
(CTL/ATL/TSB), weekly summaries, peaks/PRs, ATP, events, nutrition, zones — and
**metrics**, which is where the Garmin data lands.

**Port:** `127.0.0.1:8092` (Streamable HTTP at `/mcp`, SSE at `/sse`, health at
`/status`) · **Upstream:** [JamsusMaximus/trainingpeaks-mcp](https://github.com/JamsusMaximus/trainingpeaks-mcp)
(MIT), pinned to commit `a412a84` (v3.2.0, 85 tools) · Not public: no tunnel,
localhost only.

## Why TrainingPeaks and not a Garmin connector

Garmin Connect pushes **Daily Health Stats** (sleep + stages, HRV, resting HR,
Body Battery, stress) and **body composition** (weight, muscle mass, BMI…) into
TrainingPeaks by itself. So one TrainingPeaks connection covers workouts *and*
recovery/body data, and the fragile unofficial Garmin login is avoided.

Metrics come back through `tp_get_metrics(start_date, end_date)`, which returns
TrainingPeaks' consolidated timed metrics for the range **as-is**: whatever
TrainingPeaks displays for a day (weight, sleep, HRV, RHR, Body Battery, stress,
muscle mass, BMI…) is in the response. `tp_log_metrics` can *write* weight,
pulse, HRV and sleep hours. The upstream doesn't document every Garmin field by
name — the first real call (after auth) is the check; see "Verify" below.

**One-time Garmin setting (required):** Garmin Connect app → More → Settings →
Connected Apps → TrainingPeaks → enable **Daily Health Stats** (and body
composition). Without it, only workouts reach TrainingPeaks.

## How it runs

Upstream is stdio-only, so the container runs `mcp-proxy` (0.12, pinned) in
front of `tp-mcp serve`. They live in separate venvs inside the image:
mcp-proxy 0.12 breaks on `mcp` 2.x, which `tp-mcp` requires. The image is
built locally (`docker compose build`) — Watchtower is told to skip it
(there's no registry image to pull); to update, bump `TP_MCP_REF` in the
compose file and rebuild.

| Client | Connects to |
|---|---|
| Claude Code | `http://127.0.0.1:8092/mcp` |
| Odysseus | `http://host.docker.internal:8092/mcp` (verified reachable from the Odysseus container) |
| Glance | `http://trainingpeaks-mcp:8000/status` over the compose network |

## Auth — ⚠️ read this

TrainingPeaks' official API is partner-only, so this uses your **browser login
cookie** (`Production_tpAuth`). It is **unofficial**, gives **full account
access** (read and write), and **expires every few weeks**. Treat it like a
password: it lives only in `~/services/trainingpeaks-mcp/.env` (gitignored,
`chmod 600`), never in chat, never in this repo.

**Set or refresh it** (Terminal.app on the Mac mini — the value is read
silently, never echoed or stored in shell history):

1. Log in at <https://app.trainingpeaks.com> in your browser.
2. Open DevTools → **Application** (Chrome) / **Storage** (Safari/Firefox) →
   Cookies → `https://app.trainingpeaks.com` → copy the **value** of
   `Production_tpAuth`.
3. With the value still on the clipboard, run:
   ```bash
   sed -i '' '/^TP_AUTH_COOKIE=/d' ~/services/trainingpeaks-mcp/.env && \
     printf 'TP_AUTH_COOKIE=%s\n' "$(pbpaste | tr -d '[:space:]')" >> ~/services/trainingpeaks-mcp/.env && \
     chmod 600 ~/services/trainingpeaks-mcp/.env && pbcopy </dev/null && \
     awk -F= '/^TP_AUTH_COOKIE=/{print "saved, length", length($2)}' ~/services/trainingpeaks-mcp/.env
   cd ~/services/trainingpeaks-mcp && docker compose up -d --force-recreate
   ```
   It reads the clipboard instead of a typed paste: macOS Terminal caps
   a typed line at 1024 bytes (`MAX_CANON`), the cookie is longer, so a
   `read -s` paste silently hangs on Enter. The clipboard is cleared
   afterwards. Expect a length in the hundreds; `0` means nothing was copied.

When the cookie expires, the coach will report `tp_auth_status` invalid —
repeat the same three steps.

## Verify

```bash
curl -s http://127.0.0.1:8092/status          # proxy up
```
Then, from Claude Code or Odysseus, ask for `tp_auth_status` (should report a
valid athlete id) and `tp_get_metrics` for the last 7 days — confirm weight,
sleep, HRV and Body Battery appear. If the Garmin fields are missing, the
Daily Health Stats toggle above is off (or Garmin hasn't synced yet).

## Risks

- Unofficial: TrainingPeaks can change its internal API and break this, or
  object to cookie use under its ToS.
- Full-account cookie: a leak means someone can read and edit your training
  calendar. It stays on this machine, localhost-bound.
- The coach **writes** to your calendar (workouts, notes, nutrition targets) —
  that's the point, but review what it changes.
