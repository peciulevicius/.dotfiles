# Octopus Deploy in the homelab — researched, not building it

**Verdict (2026-09-19): no, not on the Mac mini.** Not because the idea is bad —
because the RAM isn't there, and the measurement below says so plainly. This file
exists so the research isn't lost and the idea doesn't get re-proposed from
scratch in six months.

Moved here from a scratchpad in `~/dev/janioniu-vynuogynas`, where it didn't
belong: that repo is a single Cloudflare Worker. `.dotfiles` is the homelab repo.

---

## What was wanted

A mirror of the day-job setup — Octopus deploying .NET apps to self-managed
targets — for practice and for personal .NET projects. Intended hostname
`deploy.peciulevicius.com`.

Explicitly **not** the deploy path for `janioniu-vynuogynas`. That site is one
Worker; `wrangler versions upload` / `versions deploy` / `rollback` already gives
promote-and-rollback, and can split traffic, which is more than Octopus gives
for free. See that repo's `docs/environments.md`.

## Why it doesn't fit here — measured, not guessed

Octopus's real cost is not Octopus, it's **SQL Server**. `mcr.microsoft.com/mssql/server`
has a hard 2 GB RAM floor and will use it. Plus the Octopus Server container,
call it ~3–4 GB for the pair.

Measured on the Mac mini, 2026-09-19, *after* stopping karakeep ×3 and
actual-budget:

| | |
|---|---|
| Host RAM | 16 GB total, ~7.4 GB in the compressor |
| Host swap | **3.0 GB of 4 GB used** |
| Docker VM allocation | 9.7 GiB |
| Used by the 38 running containers | 5.55 GiB |
| Headroom inside the Docker VM | ~4.1 GiB |

So Octopus + SQL Server would consume essentially *all* remaining Docker
headroom, on a host already swapping 3 GB. And the RAM freed by stopping
karakeep was earmarked for Odysseus, which is the higher-priority want.

**This would not be tight. It would not fit.**

## What would change the answer

- Octopus moves to its own machine or VM — it was always the honest answer for
  a SQL-Server-backed service
- The Mac mini's container load drops substantially (it is going up, not down)
- Octopus ships a SQLite or Postgres backend (no sign of this)

## If it's revisited, start here — don't re-research

### 1. Licence, before anything else

Octopus is commercial. The free tier has historically been **Community Edition**
with small target/project caps, and the terms have moved more than once. Confirm
the current free-tier limits and whether self-hosted Community still exists at
octopus.com/pricing. If it now needs a paid licence, the alternatives below win
outright.

### 2. Decide what the goal actually is

This changes the answer completely:

- **Day-job skill transfer** → Octopus is correct, and the SQL Server cost is
  simply the price of it
- **"Deploy my .NET side projects"** → a **self-hosted GitHub Actions runner**
  beats it on every axis: free, no server to maintain, no database, and closest
  to what already works for the vineyard site

Other options that avoid the SQL Server tax: Woodpecker CI or Drone (SQLite),
Argo CD if targets ever become Kubernetes. None of them teach you Octopus, which
is the whole point if it's skill transfer.

### 3. Compose sketch — untested starting point

Pin real versions and re-read Octopus's docs for current env var names; they have
changed between majors.

```yaml
services:
  octopus_db:
    image: mcr.microsoft.com/mssql/server:2022-latest
    environment:
      ACCEPT_EULA: "Y"
      MSSQL_SA_PASSWORD: ${MSSQL_SA_PASSWORD}   # from .env, never inline
      MSSQL_PID: Express                        # check Express's 10 GB DB cap is enough
    volumes:
      - octopus_db_data:/var/opt/mssql
    restart: unless-stopped

  octopus:
    image: octopusdeploy/octopusdeploy:latest    # pin a real tag
    depends_on: [octopus_db]
    environment:
      ACCEPT_EULA: "Y"
      DB_CONNECTION_STRING: "Server=octopus_db,1433;Database=Octopus;User Id=sa;Password=${MSSQL_SA_PASSWORD};TrustServerCertificate=true"
      ADMIN_USERNAME: ${OCTOPUS_ADMIN_USERNAME}
      ADMIN_PASSWORD: ${OCTOPUS_ADMIN_PASSWORD}
      MASTER_KEY: ${OCTOPUS_MASTER_KEY}          # generate once, BACK IT UP
    ports:
      - "8090:8080"                              # 8080 is taken on this host
    volumes:
      - octopus_repo:/repository
      - octopus_artifacts:/artifacts
      - octopus_logs:/tasklogs
    restart: unless-stopped

volumes:
  octopus_db_data:
  octopus_repo:
  octopus_artifacts:
  octopus_logs:
```

Ports already bound on this host: `8080`, `8000`, `8001`, `8053`, `8082`–`8085`,
`8096`, `5055`, and now `5984` (CouchDB). `8090` was free as of 2026-09-19 —
re-check with `lsof -nP -iTCP:8090 -sTCP:LISTEN`.

### 4. Exposure

**Never behind a plain reverse proxy.** Octopus holds deployment credentials for
every target it touches; an exposed instance with a weak admin password is a full
compromise of all of them.

**Prefer Tailscale-only.** The tunnel + Cloudflare Access path
(`deploy.peciulevicius.com`, allow-list your own email, no inbound port forward)
is available since the tunnel already runs — but it is a public surface for no
gain unless you genuinely need access from a device that can't run Tailscale.

### 5. Back up the master key on first run — this one is unrecoverable

Octopus encrypts sensitive variables with the master key. Lose it and the
database cannot be recovered even from a complete SQL backup.

- Save the master key to Vaultwarden (already running here)
- Back up the SQL database **and** the master key together
- Verify a restore into a throwaway instance before trusting it

This is the step people skip and regret.
