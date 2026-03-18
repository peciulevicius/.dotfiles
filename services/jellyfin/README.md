# Jellyfin

Self-hosted media server. Stream movies and TV shows from any device. No subscriptions, no tracking.

Reads from the shared `/media/movies/` and `/media/tv/` directories managed by Radarr and Sonarr.

## Setup

```bash
# Create media directories on T7
mkdir -p /Volumes/T7/media/{movies,tv,downloads}

cd ~/services/jellyfin
nano .env
docker compose up -d
# Open: http://localhost:8096
```

## Port

| Port | Purpose |
|------|---------|
| 8096 | Web UI |
