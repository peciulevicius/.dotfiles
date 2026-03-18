# Transmission

Lightweight BitTorrent client with web UI. Downloads to the shared `/media/downloads/` directory where Sonarr and Radarr pick up completed files.

## Setup

```bash
cd ~/services/transmission
nano .env              # set username/password
docker compose up -d
# Open: http://localhost:9091
```

## Port

| Port | Purpose |
|------|---------|
| 9091 | Web UI |
| 51413 | BitTorrent peer connections |

## Integration

Sonarr and Radarr connect to Transmission at `http://transmission:9091` (same Docker network `media`).
