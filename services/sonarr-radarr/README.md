# Sonarr + Radarr + Prowlarr

Media automation stack. Prowlarr manages indexers, Sonarr handles TV shows, Radarr handles movies. All three share a `/media` volume on T7.

## Setup

```bash
# Create media directories
mkdir -p /Volumes/T7/media/{movies,tv,downloads}

cd ~/services/sonarr-radarr
nano .env
docker compose up -d
```

## Ports

| Service | Port | Purpose |
|---------|------|---------|
| Sonarr | 8989 | TV show management |
| Radarr | 7878 | Movie management |
| Prowlarr | 9696 | Indexer manager |

## Configuration Order

1. **Prowlarr** first — add indexers (trackers/usenet)
2. **Sonarr** — add Prowlarr as indexer manager, add Transmission as download client, set root folder to `/media/tv`
3. **Radarr** — add Prowlarr as indexer manager, add Transmission as download client, set root folder to `/media/movies`

## Volume Structure

```
/Volumes/T7/media/
  downloads/    ← Transmission downloads here
  movies/       ← Radarr moves completed movies here
  tv/           ← Sonarr moves completed TV here
```
