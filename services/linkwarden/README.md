# Linkwarden

Bookmark manager that archives web pages. Save links, organize with collections and tags, and never lose a page to link rot.

## Setup

```bash
cd ~/services/linkwarden
nano .env              # set passwords and secrets
docker compose up -d
# Open: http://localhost:3005
```

Generate secrets:
```bash
openssl rand -hex 32   # for NEXTAUTH_SECRET
openssl rand -base64 32 # for POSTGRES_PASSWORD
```

## Port

| Port | Purpose |
|------|---------|
| 3005 | Web UI |

## Scale-to-zero start race (fixed 2026-10-14)

Sablier starts `linkwarden` and `linkwarden_db` together, so the app's
`prisma migrate deploy` could run before Postgres accepted connections, exit
with `P1001` in under 10 s, and never be restarted. The compose `command:` now
waits for `linkwarden-db:5432` (a node one-liner — the image has no `nc`) and
then runs the image's own CMD. **On a Linkwarden image upgrade, compare the
new image's CMD** (`docker inspect <image> --format '{{json .Config.Cmd}}'`)
with the one copied into `command:`, or the upgrade's start-up changes are
silently skipped.

## Importing bookmarks again

Diff the browser's bookmarks against `select url from "Link"` and post only
the missing ones through `/api/v1/links` (that's how the 73 newer Brave
bookmarks went in, 2026-10-14). Linkwarden's own HTML import does not skip
duplicates.
