# Sonarr + Radarr + Prowlarr

Media automation stack. Prowlarr manages indexers, Sonarr handles TV shows, Radarr handles movies. All three share a `/media` volume on the NAS.

> ⏸ **FlareSolverr is on-demand** (since 2026-09-26) — stopped by default;
> no Prowlarr indexer carries the `flaresolverr` tag, so nothing uses it.
> If an indexer starts failing on a Cloudflare challenge: `ondemand start
> flaresolverr`, tag that indexer `flaresolverr` in Prowlarr, and take it off
> the on-demand list in `scripts/utils/ondemand.sh`. ⚠️ `docker compose up -d`
> in this dir starts it again — run `ondemand stop flaresolverr` after.

## Setup

```bash
# Create media directories
mkdir -p /Volumes/media/{movies,tv,downloads}

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
/Volumes/media/
  downloads/    ← Transmission downloads here
  movies/       ← Radarr moves completed movies here
  tv/           ← Sonarr moves completed TV here
```
