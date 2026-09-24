# Octopus Deploy (evaluated, not deployed)

**Decision (2026-09-19): not deployed on the Mac mini, because of available
memory.** This page records the evaluation so it does not need repeating.

## Goal

A self-hosted Octopus Deploy instance for practising .NET deployments to
self-managed targets and for deploying personal .NET projects.

It was not intended as the deploy path for Cloudflare Worker or static-site
projects. For those, `wrangler versions upload` / `versions deploy` /
`rollback` already provide promotion, rollback and traffic splitting.

## Why it does not fit

Octopus Server requires **SQL Server**, and `mcr.microsoft.com/mssql/server`
has a 2GB memory floor. Octopus Server plus SQL Server needs roughly 3–4GB.

Measured on the Mac mini on 2026-09-19, after removing unused containers:

| Metric | Value |
|---|---|
| Host RAM | 16GB total, ~7.4GB compressed |
| Host swap | 3.0GB of 4GB in use |
| Docker VM allocation | 9.7GiB |
| Used by 38 running containers | 5.55GiB |
| Headroom inside the Docker VM | ~4.1GiB |

The pair would consume all remaining Docker headroom on a host that is already
swapping, and the freed memory was allocated to the AI workspace, which had
higher priority.

## Conditions for revisiting

- Octopus gets its own machine or VM.
- The Mac mini's container load drops substantially.
- Octopus supports a lighter database backend (SQLite or PostgreSQL).

---

## Notes for a future deployment

### 1. Licensing

Octopus is commercial software. Its free tier has historically been a
Community Edition with limits on targets and projects, and the terms have
changed more than once. Check the current limits at octopus.com/pricing before
anything else.

### 2. Choose based on the goal

- **Learning Octopus itself:** Octopus is the right tool; SQL Server is the
  cost.
- **Deploying personal .NET projects:** a self-hosted GitHub Actions runner is
  simpler — free, no database, no server to maintain. Woodpecker CI or Drone
  (SQLite-backed) also avoid SQL Server; Argo CD fits if targets become
  Kubernetes.

### 3. Compose starting point

Untested. Pin real image tags and confirm environment variable names against
the current Octopus documentation; they have changed between major versions.

```yaml
services:
  octopus_db:
    image: mcr.microsoft.com/mssql/server:2022-latest
    environment:
      ACCEPT_EULA: "Y"
      MSSQL_SA_PASSWORD: ${MSSQL_SA_PASSWORD}   # from .env
      MSSQL_PID: Express                        # Express has a 10GB database cap
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
      MASTER_KEY: ${OCTOPUS_MASTER_KEY}          # generate once and back up
    ports:
      - "8090:8080"                              # 8080 is in use on this host
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

Ports in use on the host as of 2026-09-19 include `8080`, `8000`, `8001`,
`8053`, `8082`–`8085`, `8096`, `5055` and `5984`. Check `8090` before use:

```bash
lsof -nP -iTCP:8090 -sTCP:LISTEN
```

### 4. Exposure

Octopus holds deployment credentials for every target it manages, so a
compromised instance compromises all of them.

- Keep it **Tailscale-only**.
- If access from a device without Tailscale is ever required, publish it through
  the Cloudflare tunnel behind Cloudflare Access (for example
  `deploy.peciulevicius.com`), never through a plain reverse proxy.

### 5. Master key

Octopus encrypts sensitive variables with a master key. **Without the key, the
database cannot be recovered, even from a complete SQL backup.**

1. Store the master key in Vaultwarden when the instance is first created.
2. Back up the SQL database and the master key together.
3. Test a restore into a throwaway instance before relying on the backup.
