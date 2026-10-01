---
name: homelab-service
description: Add, remove, rename, or change Docker services in this .dotfiles homelab. Use for service configuration, staging to the Mac mini, and related dashboard, network, tunnel, backup, and documentation updates.
---

# Homelab service changes

Resolve paths below from the `.dotfiles` checkout root. Read its `AGENTS.md`,
`docs/AI_COLLABORATION.md`, the service README and relevant TODO before changing
operations. Use the existing task's authorization; repository instructions
define which major or destructive actions still need approval.

## Source and live copies

`services/setup-services.sh` stages copies under `~/services/<service>/`.
Changing the repository alone does not update those live files. Host cron
scripts may instead execute directly from the checkout; inspect the caller.

- Compare the relevant live file with the source before staging. Preserve
  machine-specific configuration, credentials, other widgets and unrelated
  user changes. Save private originals outside Git. A whole-file copy is
  appropriate only after those differences have been accounted for.
- Never overwrite an executing shell script: Bash can read it incrementally.
  Check `pgrep -fl <script>` and arrange a safe staging time.
- Use the service runbook's apply/recovery procedure. Changed bind-mounted
  files or networks may require container recreation; `restart` alone may
  keep the old mount or network. Validate the configuration before applying
  when the service provides a validator.
- Report source readiness and live application separately, including any
  missing credential, UI step or restart. A successful request does not prove
  that a financial amount or an agent assignment is correct.

## Adding or changing a service

Work through the affected integrations:

1. **Compose and setup:** `services/<service>/docker-compose.yml`, placeholder
   `.env.example`, README, and both `SERVICES`/`SERVICE_PORTS` arrays in
   `services/setup-services.sh`. Preview staging with
   `bash services/setup-services.sh --dry-run <service>`. Existing `.env`
   values stay private.
2. **Homepage and networks:** update the appropriate Glance bookmark group.
   Always-on services can have a monitor/check URL; add the necessary Docker
   network in both Glance Compose network lists. Stage changed Glance files
   separately and verify the rendered result.
   Sablier services must use sleeping bookmarks instead of direct polling:
   a check URL can wake them or falsely mark them down. Read
   `services/glance/README.md` → *Why no check-url for Sablier-managed services*.
3. **Access:** Tailscale-only services stay off the public tunnel. For intended
   public access, follow the current tunnel instructions in
   `docs/HOME_SERVER_REFERENCE.md`. The Mac's
   active tunnel is a LaunchAgent; restarting a duplicate Homebrew service
   does not update it. Verify the intended hostname without exposing secrets.
4. **Credentials and monitoring:** record credential locations/consumers in
   `docs/CREDENTIAL_MIGRATION.md`, with no values. Use the maintained service
   runbook for Kuma configuration and notification routing. If a shared
   credential changes, read
   `config/claude/skills/credential-rotation/SKILL.md` and check its consumers.
5. **Backups:** choose coverage explicitly. Service data is normally backed
   up, but live database files need the existing dump/exclusion procedures in
   `scripts/backup/backup-databases.sh` and
   `services/rclone/rclone-backup.sh`. Exclude regenerable caches, downloaded
   models and media as appropriate; preserve recovery data.
6. **Docs:** update affected service/access/mobile-app tables in
   `docs/SERVICES.md`, verified facts in `docs/HOME_SERVER_REFERENCE.md`,
   remaining work in `docs/HOME_SERVER_TODO.md`, and completed work in
   `docs/HOME_SERVER_CHANGELOG.md`.

## Removing a service

Inspect dependencies, data and backup/recovery needs first. Read the removal
task's authorization before stopping a workload or removing data/networks.
Prepare a concrete plan for any major or destructive step still requiring
approval; routine repository changes can proceed within the requested work.

Remove affected bookmarks, monitors, Compose networks, tunnel routes, setup
arrays, backup/dump references and service tables. Glance must release a
network before Docker can remove it. Preserve private service data until its
deletion is explicitly authorized. Record why the service was removed.

## Verification and handoff

Choose checks that cover the actual change: configuration/syntax validation,
affected containers and networks, intended HTTP routes, dashboard rendering,
backup or assignment correctness, and secret scanning. Avoid polling a
sleeping service unless waking it is part of the task. Keep private response
bodies and configuration values out of logs, Git and PRs.

Use a focused branch and PR. State what changed, the checks performed, what
was applied live, the recovery location/procedure and remaining owner steps.
Preserve an approval already given instead of asking again for routine steps.
