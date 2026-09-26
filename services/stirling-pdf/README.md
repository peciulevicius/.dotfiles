# Stirling PDF

All-in-one PDF manipulation tool. Merge, split, compress, convert, rotate, add watermarks, and more — all locally.

> ⏸ **On-demand** (since 2026-09-26) — stopped by default to save RAM.
> `ondemand start stirling-pdf` (alias for `scripts/utils/ondemand.sh`) prints the
> URL; `ondemand stop stirling-pdf` when done. It's the single biggest saving (~850MB idle, a JVM).

## Setup

```bash
cd ~/services/stirling-pdf
docker compose up -d
# Open: http://localhost:8084
```

## Port

| Port | Purpose |
|------|---------|
| 8084 | Web UI |
