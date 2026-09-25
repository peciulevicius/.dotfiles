# Strava MCP

Strava activities, athlete profile and training analysis for the AI coach
inside **Odysseus**. Claude Code doesn't need this — it already has the
official claude.ai Strava connector, which Odysseus can't use.

**Port:** `127.0.0.1:8093` (Streamable HTTP at `/mcp`, SSE at `/sse`, health at
`/status`) · **Upstream:** [eddmann/strava-mcp](https://github.com/eddmann/strava-mcp)
(MIT), pinned to commit `2c6fa69` · Not public: localhost only.

## Why eddmann over r-huijts

Neither matches the claude.ai connector's tool names, so the coach skill maps
names per client (see its "This setup" section). eddmann's tools are
higher-level and suit coaching better — `query_activities` (filters, one
activity by id, streams), `analyze_training`, `compare_activities`,
`find_similar_activities`, `get_athlete_profile` — and its single-user stdio
mode rewrites rotated refresh tokens to a file by itself. r-huijts
(`get-recent-activities`, `get-activity-details`, …) is lower-level and
segment/route-heavy.

eddmann's own HTTP mode is a multi-user OAuth server built for AWS Lambda —
overkill here — so the container runs its **stdio** mode behind `mcp-proxy`,
like the TrainingPeaks service.

## One-time setup (you)

1. **Create a Strava API app:** <https://www.strava.com/settings/api> →
   Application Name anything (e.g. "homelab coach"), Category "Training",
   Website `http://localhost`, **Authorization Callback Domain `localhost`**.
   Note the **Client ID** and **Client Secret**.
2. **Run the auth wizard** in Terminal.app on the Mac mini:
   ```bash
   cd ~/services/strava-mcp && docker compose run --rm -it strava-mcp /opt/strava/bin/strava-mcp auth
   ```
   - Choose **stdio** when asked for the transport.
   - Paste Client ID, then Client Secret (typed silently).
   - Open the printed URL, click **Authorize**. The browser then fails to load
     `http://localhost/?state=&code=…` — **that's expected**. Copy the whole
     address-bar URL and paste it back into the wizard.
   - It exchanges the code and writes everything to
     `~/services/strava-mcp/data/.strava-mcp.env`.
3. Start it: `docker compose up -d`, then `curl -s http://127.0.0.1:8093/status`.

Scopes requested: `profile:read_all, activity:read_all, activity:read,
profile:write` (upstream defaults — `profile:write` is only used for starring
segments).

## Where secrets live

`~/services/strava-mcp/data/.strava-mcp.env` — client secret + access/refresh
tokens. Not in `.env` (which holds only the port) because the server
**rewrites the refresh token there on every refresh** — Strava rotates them —
so it must be a writable, persistent file. `chmod 600` it after the wizard.
Excluded from the R2 backup (regenerable by re-running the wizard).

If Strava ever returns 401s that don't recover: revoke the app at
<https://www.strava.com/settings/apps> and re-run step 2.

## Risks

- Official Strava API, so the lowest-risk connector here. Strava's API
  agreement restricts feeding API data to AI, aimed at third-party apps; using
  your own data for your own coaching is a grey area, not clearly allowed.
- Rate limits: 100 requests / 15 min, 1000 / day per app — plenty for one
  athlete.
