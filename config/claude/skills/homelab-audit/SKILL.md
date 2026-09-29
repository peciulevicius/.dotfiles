---
name: homelab-audit
description: Health and security audit of the Mac mini homelab and this public dotfiles repo — drift, container health, backups, disk, secrets, stale credentials, outdated images, and docs that contradict reality. Use when asked for an audit, health check, "is everything ok", or after a big batch of changes. Fixes what it finds.
---

# Homelab audit

Two layers: the script does the mechanical checks (it also runs weekly from
cron and alerts Discord), then you do the checks that need judgment. **Fix
what you find, then commit and push** — don't just list problems.

## 1. Run the script

```bash
~/.dotfiles/scripts/utils/homelab-audit.sh
```

Covers: repo-vs-live drift, containers down/unhealthy, R2 backup completed
in the last day, DB dump freshness, disk usage, gitleaks on the last 8 days
of commits, pre-commit hook enabled. Fix every ✗ before moving on.

## 2. Judgment checks

**Secrets in the whole repo** (the script only scans recent commits):
```bash
cd ~/.dotfiles && gitleaks git --redact -v --config .gitleaks.toml
```
A known historical finding stays until the underlying secret is **rotated**
(see `credential-rotation`), then its fingerprint goes in `.gitleaksignore`.
Also look for things gitleaks can't recognise — personal passwords, tokens
embedded in URLs — and add a rule to `.gitleaks.toml` when you find a new
pattern.

**Outdated images.** Pinned tags never move, so Watchtower being on proves
nothing. WUD checks daily; refresh its report of pinned images:
```bash
~/.dotfiles/scripts/utils/update-report.sh
```
Read Glance's Updates card or the report in `~/logs/update-report.log` for
safe/major/held entries. The older `check-image-updates.py --outdated` remains
an optional direct-registry check; its quarterly cron was replaced 2026-09-28.
These checks only report — bump one service at a time after reading the
release notes and the WUD holds table. Use `upgrade-service.sh` for approved
upgrades and preserve the data-migration safeguards.
Pi-hole (publicly exposed, controls DNS) and Vaultwarden come first. A client
failing against a server that logs 200s is often a version mismatch.

**Stale credential copies.** After any rotation, grep `~/services/` for the
old value and test each consumer (Radarr/Sonarr/LazyLibrarian download
clients, Calibre-Web and Uptime Kuma SMTP) — see `credential-rotation`.

**Download pipeline** — Radarr/Sonarr queue shouldn't show
`downloadClientUnavailable`; nothing in Transmission should be a bare
`.exe`/`.scr`; the release profiles rejecting those still exist:
`curl -s localhost:7878/api/v3/releaseprofile -H "X-Api-Key: …"`.

**Offsite + monitoring gaps** — is the Healthchecks.io dead-man's switch in
place and fresh? Is documented power-loss restart enabled
(`pmset -g custom` → `autorestart 1`, see `man pmset`)? Do not treat this as
proof of physical recovery or change an undocumented flag. FileVault cold
boots still need a person; an outage test needs a maintenance window.

**Docs vs reality.** Spot-check claims in `.claude/CLAUDE.md`,
`docs/START_HERE.md` and `docs/HOME_SERVER_TODO.md` against live state —
container count, "not started"/"done" markers, disk figures, ticked boxes for
work that's actually finished. Stale docs have been wrong several times.

## 3. Report and record

Summarise: fixed / needs the user (anything requiring sudo, a UI login, or a
purchase) / fine. Add a dated entry to `docs/HOME_SERVER_CHANGELOG.md`, update
`docs/HOME_SERVER_TODO.md`, commit, push.
