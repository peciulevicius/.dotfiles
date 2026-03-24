# Actual Budget — personal finance manager

Zero-based budgeting app. Local-first, works offline, supports CSV/OFX bank import.

## Setup

1. `docker compose up -d`
2. Open http://localhost:5006
3. Create a new budget or import an existing one

## Features

- Zero-based budgeting
- Bank CSV/OFX import
- Reports and graphs
- Works completely offline
- Data stored locally in `./data/`

## Backup

The `./data/` directory contains all budget files.
Add it to your rclone backup if you want cloud backup.
