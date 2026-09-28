#!/bin/bash
# Upgrade one pinned container image, with backup, health check and
# automatic rollback.
#
#   upgrade-service.sh <service> [new-tag] [--image <substring>] [--commit]
#
#   upgrade-service.sh bazarr 1.6.2
#   upgrade-service.sh bazarr                  # tag taken from WUD's report
#   upgrade-service.sh paperless-ngx 3.2.1 --image paperless-ngx/paperless-ngx
#   upgrade-service.sh bazarr 1.6.2 --commit   # also git commit + push
#
# <service> is the directory under services/. If its compose file has more
# than one pinned image, --image picks which one (any unique substring of the
# image name). Without a tag, the "available" tag for that service from
# ~/services/glance/assets/updates.json (scripts/utils/update-report.sh) is
# used; held items (services/wud/holds.tsv) are refused.
#
# Steps:
#   1. Refuse floating tags (${VAR}, latest) — Watchtower handles those.
#   2. Back up the repo + live compose to ~/backups/upgrades/<svc>-<ts>/.
#      If the stack has a Postgres/MariaDB container, run
#      scripts/backup/backup-databases.sh first (all dumps, ~1 min).
#   3. Bump the tag in services/<svc>/docker-compose.yml, copy it to
#      ~/services/<svc>/ (the live copy), diff must be silent.
#   4. docker compose pull + up -d for that compose service only.
#   5. Wait up to TIMEOUT seconds (default 300): healthy if the container has
#      a healthcheck, otherwise running with no restarts for 45 s.
#   6. Unhealthy → restore both compose files, recreate on the old tag,
#      exit 1. The repo is left exactly as it was.
#   7. Scale-to-zero (Sablier) containers that were stopped before the
#      upgrade are stopped again afterwards — nothing is left awake.
#   8. Print a changelog-ready line. The repo change is yours to commit
#      (or pass --commit).
#
# Never touches .env.

set -uo pipefail

REPO="$HOME/.dotfiles"
LIVE="$HOME/services"
TIMEOUT="${TIMEOUT:-300}"
STABLE_SECS=45

die() { echo "✗ $*" >&2; exit 1; }
info() { echo "→ $*"; }
ok() { echo "✓ $*"; }

svc="" tag="" image_sub="" commit=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --image) image_sub="${2:-}"; shift 2 ;;
    --commit) commit=true; shift ;;
    -h|--help) sed -n '2,36p' "$0"; exit 0 ;;
    *) if [[ -z "$svc" ]]; then svc="$1"; elif [[ -z "$tag" ]]; then tag="$1"; else die "unexpected argument: $1"; fi; shift ;;
  esac
done
[[ -n "$svc" ]] || die "usage: upgrade-service.sh <service> [new-tag] [--image <substring>] [--commit]"

repo_compose="$REPO/services/$svc/docker-compose.yml"
live_dir="$LIVE/$svc"
live_compose="$live_dir/docker-compose.yml"
[[ -f "$repo_compose" ]] || die "no $repo_compose"
[[ -f "$live_compose" ]] || die "no live copy at $live_compose (run services/setup-services.sh $svc)"
diff -q "$repo_compose" "$live_compose" >/dev/null || die "repo and live compose differ — stage or commit that first"

# ── Which image line? ───────────────────────────────────────────────────────
# (bash 3.2 on macOS: no mapfile — plain loops)
images=$(grep -E '^[[:space:]]*image:[[:space:]]*' "$repo_compose" | sed -E 's/^[[:space:]]*image:[[:space:]]*//; s/[[:space:]]*(#.*)?$//')
[[ -n "$image_sub" ]] && images=$(printf '%s\n' "$images" | grep -F -- "$image_sub")
pinned=""
count=0
while IFS= read -r i; do
  [[ -z "$i" || "$i" == *'${'* || "$i" != *:* || "$i" == *:latest ]] && continue
  pinned="$i"; count=$((count + 1))
done <<< "$images"
[[ $count -eq 1 ]] || { printf '%s\n' "$images" | sed 's/^/  /' >&2; die "need exactly one pinned image — use --image <substring> (floating tags are Watchtower's job)"; }
old_image="$pinned"
repo_name="${old_image%:*}"
old_tag="${old_image##*:}"

# ── Target tag (argument or WUD report) ─────────────────────────────────────
if [[ -z "$tag" ]]; then
  tag=$(python3 - "$HOME/services/glance/assets/updates.json" "$svc" "$repo_name" <<'PY'
import json, sys
path, svc, repo = sys.argv[1:4]
try:
    d = json.load(open(path))
except Exception:
    sys.exit()
for r in d.get("held", []):
    if r["service"] == svc:
        print("HELD:" + r.get("reason", "")); sys.exit()
hits = [r for b in ("safe", "major") for r in d.get(b, []) if r["service"] == svc]
if len(hits) == 1:
    print(hits[0]["available"])
PY
)
  [[ "$tag" == HELD:* ]] && die "held in services/wud/holds.tsv: ${tag#HELD:}"
  [[ -n "$tag" ]] || die "no single update for '$svc' in updates.json — pass the tag explicitly"
fi
[[ "$tag" != "$old_tag" ]] || die "already on $old_tag"
new_image="$repo_name:$tag"

# ── Compose service key for that image ──────────────────────────────────────
key=$(cd "$live_dir" && docker compose config --format json 2>/dev/null | python3 -c '
import json, sys
img = sys.argv[1]
for k, v in json.load(sys.stdin)["services"].items():
    if v.get("image") == img:
        print(k); break' "$old_image")
[[ -n "$key" ]] || die "couldn't map $old_image to a compose service"
container=$(cd "$live_dir" && docker compose config --format json | python3 -c '
import json, sys
v = json.load(sys.stdin)["services"][sys.argv[1]]
print(v.get("container_name") or "")' "$key")
[[ -n "$container" ]] || container=$(cd "$live_dir" && docker compose ps -a -q "$key" | head -1)

info "$svc: $old_image → $new_image (compose service '$key', container '$container')"

# ── Pull first: a typo'd tag fails here, before anything changes ────────────
docker pull -q "$new_image" >/dev/null || die "can't pull $new_image — check the tag"

# ── Backups ─────────────────────────────────────────────────────────────────
ts=$(date +%Y%m%d-%H%M%S)
bk="$HOME/backups/upgrades/$svc-$ts"
mkdir -p "$bk"
cp "$repo_compose" "$bk/docker-compose.repo.yml"
cp "$live_compose" "$bk/docker-compose.live.yml"
old_digest=$(docker inspect --format '{{.Image}}' "$container" 2>/dev/null || echo "?")
echo "$old_image $old_digest" > "$bk/previous-image.txt"
ok "backed up compose files to $bk"
if grep -qE 'image:[[:space:]]*(postgres|mariadb|mysql|ghcr.io/immich-app/postgres)' "$repo_compose"; then
  info "stack has a database — running backup-databases.sh first"
  "$REPO/scripts/backup/backup-databases.sh" || die "database backup failed — not upgrading"
fi

# Which containers of this stack were running before (Sablier sleepers)?
was_running=$(cd "$live_dir" && docker compose ps --status running --format '{{.Name}}')
sleeper=$(docker inspect --format '{{index .Config.Labels "sablier.enable"}}' "$container" 2>/dev/null || true)

restore() {
  echo "✗ $1 — rolling back to $old_image" >&2
  cp "$bk/docker-compose.repo.yml" "$repo_compose"
  cp "$bk/docker-compose.live.yml" "$live_compose"
  (cd "$live_dir" && docker compose up -d "$key") >/dev/null 2>&1
  docker logs --tail 20 "$container" >&2 2>/dev/null || true
  echo "  rolled back; logs of the failed attempt are above. Backup: $bk" >&2
  exit 1
}

# ── Bump + stage ────────────────────────────────────────────────────────────
python3 - "$repo_compose" "$old_image" "$new_image" <<'PY'
import sys
p, old, new = sys.argv[1:4]
s = open(p).read()
assert s.count(old) == 1, "image string not unique"
open(p, "w").write(s.replace(old, new))
PY
cp "$repo_compose" "$live_compose"
diff -q "$repo_compose" "$live_compose" >/dev/null || restore "staging failed"

# ── Recreate + wait ─────────────────────────────────────────────────────────
(cd "$live_dir" && docker compose up -d "$key") || restore "docker compose up failed"
has_hc=$(docker inspect --format '{{if .State.Health}}yes{{end}}' "$container" 2>/dev/null)
start=$(date +%s)
restarts0=$(docker inspect --format '{{.RestartCount}}' "$container" 2>/dev/null || echo 0)
while :; do
  now=$(date +%s); el=$((now - start))
  (( el > TIMEOUT )) && restore "not healthy after ${TIMEOUT}s"
  state=$(docker inspect --format '{{.State.Status}}' "$container" 2>/dev/null)
  if [[ "$has_hc" == yes ]]; then
    h=$(docker inspect --format '{{.State.Health.Status}}' "$container" 2>/dev/null)
    [[ "$h" == healthy ]] && break
    [[ "$h" == unhealthy ]] && restore "healthcheck reports unhealthy"
  else
    r=$(docker inspect --format '{{.RestartCount}}' "$container" 2>/dev/null || echo 0)
    [[ "$state" == running && "$r" == "$restarts0" && $el -ge $STABLE_SECS ]] && break
    [[ "$r" != "$restarts0" ]] && restore "container restarted (crash loop)"
  fi
  [[ "$state" == exited || "$state" == dead ]] && restore "container $state"
  sleep 5
done
ok "$container healthy on $tag after $(( $(date +%s) - start ))s"

# ── Put sleepers back to sleep ──────────────────────────────────────────────
if [[ "$sleeper" == true ]]; then
  now_running=$(cd "$live_dir" && docker compose ps --status running --format '{{.Name}}')
  while IFS= read -r c; do
    [[ -z "$c" ]] && continue
    printf '%s\n' "$was_running" | grep -qx "$c" || { docker stop "$c" >/dev/null && info "stopped $c again (scale-to-zero)"; }
  done <<< "$now_running"
fi

line="- $(date +%F): \`$svc\` $repo_name \`$old_tag\` → \`$tag\` (upgrade-service.sh, health-checked; backup $bk)"
echo
echo "Changelog line:"
echo "$line"

if $commit; then
  cd "$REPO" || exit 1
  git add "services/$svc/docker-compose.yml"
  git commit -qm "chore($svc): upgrade ${repo_name##*/} to $tag" && git push -q && ok "committed and pushed"
else
  echo
  echo "Repo changed: services/$svc/docker-compose.yml — commit it (or re-run with --commit next time)."
fi
