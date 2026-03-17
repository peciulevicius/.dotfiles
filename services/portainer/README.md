# Portainer CE

Docker management UI — view containers, logs, images, and volumes.

## Ports

| Port | Service |
|------|---------|
| 9000 | Web UI |

## Quick Start

```bash
docker compose up -d
```

Open `http://localhost:9000` and create your admin account on first visit.

## Notes

- Portainer has access to the Docker socket — keep it on the private network
- Use Tailscale to access remotely rather than exposing to the internet
