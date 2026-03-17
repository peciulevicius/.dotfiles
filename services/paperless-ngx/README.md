# Paperless-ngx

Document scanner, OCR, and organiser. Scan receipts, bills, and documents once — find them forever.

## Ports

| Port | Service |
|------|---------|
| 8000 | Web UI |

## Quick Start

```bash
# Generate a secret key
python3 -c "import secrets; print(secrets.token_hex(32))"

cp .env.example .env
nano .env  # fill in DB_PASSWORD, SECRET_KEY, ADMIN_PASSWORD

docker compose up -d
```

## Workflow

1. Drop files in `./data/consume/` — Paperless picks them up automatically
2. Or email documents to Paperless (configure in Settings)
3. Or use the mobile app to photograph and upload

## Scanner Setup

Configure your scanner/printer to save to the consume directory (map the network path).
