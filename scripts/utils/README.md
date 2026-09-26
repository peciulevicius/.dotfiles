# Utility Scripts

Standalone utility scripts for one-off tasks. Not part of the main install flow.

---

## arw-to-jpeg.sh

Converts Sony ARW (RAW) files to JPEG for uploading to Immich or general use.
Uses macOS built-in `sips` — no dependencies needed.

```bash
# Preview what will be converted (no changes made)
./arw-to-jpeg.sh /path/to/photos --dry-run

# Convert all ARW files to JPEG alongside originals (90% quality)
./arw-to-jpeg.sh /path/to/photos

# Convert to a separate output folder
./arw-to-jpeg.sh /path/to/photos --out ~/Desktop/converted

# Convert at lower quality to save more space
./arw-to-jpeg.sh /path/to/photos --quality 80

# Convert and delete originals (saves space — make sure you have a backup first)
./arw-to-jpeg.sh /path/to/photos --delete-originals

# Full example: separate output folder + lower quality + delete originals
./arw-to-jpeg.sh ~/Pictures/Sony --out ~/Pictures/Immich --quality 85 --delete-originals
```

**Notes:**
- EXIF metadata (date, GPS, camera model) is preserved — Immich will sort photos by the correct date
- ARW files are typically 25-50MB each; JPEG at 90% quality will be ~8-15MB
- Skips files where a JPEG already exists (safe to re-run)
- Always run `--dry-run` first to verify it finds the right files

---

## heartbeat.sh

Dead-man's switch. Pings a Healthchecks.io check every five minutes (cron);
Healthchecks alerts from outside the network when the pings stop — the only
alert that survives the whole house losing power. Sends a `/fail` ping when
Docker is unresponsive, since Uptime Kuma is down with it.

```bash
~/.dotfiles/scripts/utils/heartbeat.sh --test   # one ping, prints "sent: ok" or the failure
```

Reads `HEARTBEAT_PING_URL` from `~/.config/homelab/heartbeat.env` (never commit
it). Setup: `scripts/cron/README.md`, "Setting up the heartbeat".

---

## utils.sh

Shared print/formatting helper functions (coloured output, section banners).
Not meant to be run directly — sourced by the Linux and Windows installer scripts.

```bash
source ./utils.sh
print_success "Done"
print_warning "Check this"
print_error "Something failed"
```

---

## gdpr-export.mjs

Export or delete one person's data in a Supabase project (GDPR access/erasure
requests). Canonical copy; projects vendor it. Full docs:
[docs/UTILITY_SCRIPTS.md](../../docs/UTILITY_SCRIPTS.md#gdpr-exportmjs).

```bash
node gdpr-export.mjs --config gdpr.config.json export someone@example.com
node gdpr-export.mjs --config gdpr.config.json delete someone@example.com [--yes]
```
