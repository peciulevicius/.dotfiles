# Audiobookshelf

Self-hosted audiobook and podcast server. Stream audiobooks from any device, track listening progress, download for offline.

## Setup

```bash
cd ~/services/audiobookshelf
nano .env              # set library paths
docker compose up -d
# Open: http://localhost:13378
```

## Port

| Port | Purpose |
|------|---------|
| 13378 | Web UI |
