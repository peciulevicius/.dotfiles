# FreshRSS

Self-hosted RSS reader. Replaces Feedly/Google Reader.

## Ports

| Port | Service |
|------|---------|
| 8082 | Web UI |

## Quick Start

```bash
cp .env.example .env
nano .env  # set timezone

docker compose up -d
```

Open `http://localhost:8082` to set up your account.

## Mobile Apps

FreshRSS exposes a Google Reader API. Compatible apps:
- **iOS**: Reeder, NetNewsWire
- **Android**: FeedMe, Readrops
