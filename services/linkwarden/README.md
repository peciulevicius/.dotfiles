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
