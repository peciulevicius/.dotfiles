#!/bin/bash
# Weekly homelab health audit — the checks that kept failing silently.
#
#   homelab-audit.sh          # run all checks, exit 1 if anything needs attention
#
# Cron (weekly, via run-with-notify so a failure reaches Discord):
#   0 9 * * 0 ~/.dotfiles/scripts/utils/run-with-notify.sh "Homelab audit" \
#             ~/.dotfiles/scripts/utils/homelab-audit.sh >> ~/logs/homelab-audit.log 2>&1
#
# Every check here maps to a real miss from 2026-09-21/22:
#   drift     — repo edits to services/ sat inert because ~/services is a copy
#   containers— a stopped container nobody noticed
#   backups   — backups "succeeding" while skipping data, stale dumps
#   disk      — SSD reached 92% before anyone looked
#   secrets   — a token committed from a machine without the pre-commit hook
#   external  — T5 drifted seven weeks stale before anyone noticed (2026-09-05)
#   cron      — the repo crontab fell behind the live one; reinstalling it
#               would have silently undone the 2026-09-23 backup fix
#
# The judgment calls (pinned image versions, stale credential copies after a
# rotation, docs contradicting reality) live in the homelab-audit skill.

set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIVE="$HOME/services"
PROBLEMS=0

ok()   { echo "  ✓ $1"; }
bad()  { echo "  ✗ $1"; PROBLEMS=$((PROBLEMS + 1)); }
head_() { echo ""; echo "== $1"; }

days_ago() {  # YYYYMMDD for N days ago, macOS or GNU date
  date -v-"$1"d +%Y%m%d 2>/dev/null || date -d "$1 days ago" +%Y%m%d
}

# ── 1. Repo vs live drift ────────────────────────────────────────────────────
head_ "Drift: repo services/ vs live ~/services (copies, not symlinks)"
drift=0
while IFS= read -r f; do
  rel="${f#"$DOTFILES"/services/}"
  live="$LIVE/$rel"
  if [[ -f "$live" ]] && ! diff -q "$f" "$live" >/dev/null 2>&1; then
    bad "$rel differs — re-copy it, then recreate the container"
    drift=1
  fi
done < <(find "$DOTFILES/services" -mindepth 2 -maxdepth 2 \( -name '*.sh' -o -name 'docker-compose.yml' -o -name 'glance.yml' \))
[[ $drift -eq 0 ]] && ok "no drift"

# ── 2. Containers meant to be up that aren't ─────────────────────────────────
head_ "Containers"
if command -v docker >/dev/null 2>&1; then
  down=0
  while IFS='|' read -r name status policy; do
    # restart=no marks on-demand services (e.g. storyteller) — stopped is normal
    [[ "$policy" == "no" ]] && continue
    if [[ "$status" != running ]]; then
      bad "$name is $status (restart policy: $policy)"; down=1
    fi
  done < <(docker ps -aq | xargs -r docker inspect --format '{{.Name}}|{{.State.Status}}|{{.HostConfig.RestartPolicy.Name}}' 2>/dev/null | sed 's#^/##')
  unhealthy=$(docker ps --filter health=unhealthy --format '{{.Names}}')
  [[ -n "$unhealthy" ]] && { bad "unhealthy: $unhealthy"; down=1; }
  [[ $down -eq 0 ]] && ok "$(docker ps -q | wc -l | tr -d ' ') running, none down or unhealthy"
else
  bad "docker not available"
fi

# ── 3. Backups actually completed recently ───────────────────────────────────
head_ "Backups"
found=0
for d in 0 1; do
  log="$HOME/logs/rclone-$(days_ago "$d").log"
  if [[ -f "$log" ]] && grep -q "All backups complete" "$log"; then found=1; break; fi
done
[[ $found -eq 1 ]] && ok "R2 backup completed within the last day" \
                   || bad "no successful R2 backup in the last day — check ~/logs/rclone-*.log"

# "All backups complete" also prints when an opt-in step is silently skipped.
# Caught 2026-09-23: cron ran a copy of the script whose .env lacked
# BACKUP_IMMICH_PHOTOS, so photos went un-backed-up while every run looked green.
if grep -q '^BACKUP_IMMICH_PHOTOS=true' "$LIVE/rclone/.env" 2>/dev/null; then
  immich_ok=0
  for d in 0 1; do
    log="$HOME/logs/rclone-$(days_ago "$d").log"
    [[ -f "$log" ]] && grep -q "Immich photos backup complete" "$log" && { immich_ok=1; break; }
  done
  [[ $immich_ok -eq 1 ]] && ok "Immich photos included in the last day's backup" \
                         || bad "Immich photo backup is enabled but didn't run in the last day"
fi

newest_dump=$(ls -t "$HOME"/backups/*.sql 2>/dev/null | head -1)
if [[ -z "$newest_dump" ]]; then
  bad "no DB dumps in ~/backups"
elif [[ -n "$(find "$newest_dump" -mtime +8 2>/dev/null)" ]]; then
  bad "newest DB dump is older than 8 days: $(basename "$newest_dump")"
else
  ok "DB dumps fresh ($(basename "$newest_dump"))"
fi

# External drives aren't plugged in permanently, so the nightly cron for them
# was removed (2026-09-05) and nothing noticed T5 going seven weeks stale.
# backup-external.sh stamps ~/logs/external-backup-<drive>.last on success;
# this is the reminder that replaced the cron.
EXTERNAL_MAX_DAYS=30
stamps=("$HOME"/logs/external-backup-*.last)
if [[ ! -e "${stamps[0]}" ]]; then
  bad "no external-drive backup recorded — plug in T7 and run scripts/backup/backup-external.sh /Volumes/T7"
else
  now=$(date +%s)
  for stamp in "${stamps[@]}"; do
    drive="${stamp##*/external-backup-}"; drive="${drive%.last}"
    age=$(( (now - $(cat "$stamp" 2>/dev/null || echo 0)) / 86400 ))
    if (( age > EXTERNAL_MAX_DAYS )); then
      bad "external backup to $drive is $age days old (limit $EXTERNAL_MAX_DAYS)"
    else
      ok "external backup to $drive is $age days old"
    fi
  done
fi

# ── 4. Disk ──────────────────────────────────────────────────────────────────
head_ "Disk"
target="/System/Volumes/Data"; [[ -d "$target" ]] || target="/"
used=$(df -P "$target" | awk 'NR==2 {gsub("%","",$5); print $5}')
if (( used >= 90 )); then bad "internal disk ${used}% full — see HOME_SERVER_REFERENCE.md SSD section"
else ok "internal disk ${used}% used"; fi

# ── 5. Secrets committed in the last week (e.g. from a hook-less machine) ────
head_ "Secrets (commits from the last 8 days)"
if command -v gitleaks >/dev/null 2>&1; then
  if gitleaks git "$DOTFILES" --no-banner --redact --log-opts="--since=8.days" \
       --config "$DOTFILES/.gitleaks.toml" >/dev/null 2>&1; then
    ok "no secrets in recent commits"
  else
    bad "gitleaks flagged recent commits — run: gitleaks git --redact -v --log-opts='--since=8.days'"
  fi
else
  bad "gitleaks not installed (brew install gitleaks)"
fi

[[ "$(git -C "$DOTFILES" config core.hooksPath)" == ".githooks" ]] \
  && ok "pre-commit secret hook enabled" \
  || bad "pre-commit hook NOT enabled — git config core.hooksPath .githooks"

# ── 6. Live crontab vs the repo copy ─────────────────────────────────────────
# scripts/cron/crontab is meant to be authoritative. If it falls behind, the
# next `crontab < scripts/cron/crontab` silently reverts whatever was fixed
# live — which is exactly what nearly happened to the 2026-09-23 rclone path.
head_ "Cron"
if command -v crontab >/dev/null 2>&1; then
  jobs_only() { grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' | sort; }
  cron_diff=$(diff <(crontab -l 2>/dev/null | jobs_only) <(jobs_only < "$DOTFILES/scripts/cron/crontab"))
  if [[ -z "$cron_diff" ]]; then
    ok "live crontab matches scripts/cron/crontab"
  else
    bad "live crontab differs from scripts/cron/crontab (< live, > repo):"
    echo "$cron_diff" | grep '^[<>]' | sed 's/^/      /'
  fi
else
  bad "crontab not available — cannot check the schedule"
fi

echo ""
if (( PROBLEMS > 0 )); then
  echo "✗ $PROBLEMS problem(s) need attention"
  exit 1
fi
echo "✓ All checks passed"
