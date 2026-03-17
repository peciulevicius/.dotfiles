# Watchtower

Automatically updates Docker containers to latest image versions on a schedule.

## Quick Start

```bash
cp .env.example .env
docker compose up -d
```

## Notes

- Immich containers have `com.centurylinklabs.watchtower.enable: "false"` — they are excluded
- Set `WATCHTOWER_LABEL_ENABLE=true` to update only opted-in containers
- Check logs: `docker logs watchtower`
