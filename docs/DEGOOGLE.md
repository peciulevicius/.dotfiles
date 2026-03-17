# Degoogle Guide

Replace Google services with self-hosted or privacy-respecting alternatives.

## Replacement Map

| Google Service | Self-Hosted | Hosted Alternative |
|---------------|------------|-------------------|
| Google Photos | Immich | None needed |
| Google Drive | Nextcloud | ProtonDrive |
| Google Docs | Nextcloud + Collabora | Notion, Coda |
| Gmail | — | ProtonMail, Fastmail |
| Google Calendar | Nextcloud Calendar | ProtonCalendar |
| Google Contacts | Nextcloud Contacts | — |
| Chrome Sync | — | Firefox Sync |
| Google Password Manager | Vaultwarden | Bitwarden Cloud |
| YouTube | — | PeerTube (niche), FreeTube (client) |
| Google Maps | — | Apple Maps, OsmAnd |
| Google Analytics | PostHog (self-hosted) | Plausible Cloud |
| Google Search | — | DuckDuckGo, Kagi |
| Google Fonts | — | bunny.net/fonts, self-host |
| Google News | FreshRSS | — |
| Google Home | — | Home Assistant |

## Migration Checklist

### Phase 1 — Quick Wins (no data migration)

- [ ] Switch default search to DuckDuckGo or Kagi
- [ ] Switch browser to Firefox or Brave
- [ ] Enable Firefox Sync instead of Chrome Sync
- [ ] Install Bitwarden extension, import passwords from Google Password Manager
- [ ] Switch to Vaultwarden as Bitwarden server (see [SERVICES.md](SERVICES.md))
- [ ] Switch Maps to Apple Maps (iPhone) or OsmAnd (Android)
- [ ] Remove Google from 2FA — move TOTP codes to Bitwarden or Raivo

### Phase 2 — Data Migrations

- [ ] **Google Photos → Immich**
  - Set up Immich: `cd ~/docker/immich && docker compose up -d`
  - Download Google Photos: Google Takeout → select Photos
  - Import: Immich web UI → Import → select Takeout folder
  - Install Immich app on phone → backup enabled
  - After 30 days with no issues: delete Google Photos backup

- [ ] **Google Drive → Nextcloud**
  - Set up Nextcloud: `cd ~/docker/nextcloud && docker compose up -d`
  - Download Google Drive: Google Takeout → select Drive
  - Upload to Nextcloud via web UI or CLI
  - Install Nextcloud desktop sync client
  - Update shared links (send new Nextcloud links to collaborators)

- [ ] **Gmail → ProtonMail or Fastmail**
  - Create new email account
  - Set Gmail to forward to new address for 6 months
  - Update email on important accounts (bank, Apple, GitHub, etc.)
  - Export Gmail via Google Takeout
  - Update contacts with new address
  - After 6 months: stop Gmail forwarding

- [ ] **Google Calendar → Nextcloud Calendar**
  - Export: Google Calendar → Settings → Export
  - Import .ics files into Nextcloud Calendar
  - Subscribe mobile calendar to Nextcloud via CalDAV
  - Share calendar URL with contacts who need it

- [ ] **Google Contacts → Nextcloud Contacts**
  - Export: contacts.google.com → Export → vCard
  - Import .vcf into Nextcloud Contacts
  - Set up CardDAV sync on iPhone (Settings → Contacts → Accounts → Add)

### Phase 3 — Deepen Privacy

- [ ] Remove Google Analytics from personal sites → use PostHog or Plausible
- [ ] Replace Google Fonts with self-hosted fonts or bunny.net/fonts
- [ ] Switch to a privacy-respecting DNS (Cloudflare 1.1.1.1 or NextDNS)
- [ ] Audit app permissions — revoke Google sign-in from apps where possible
- [ ] Set up NextDNS or Pi-hole to block tracking at DNS level
- [ ] Review remaining Google accounts — delete unused ones
- [ ] Enable Google Account activity controls to minimise data collection

## Google Takeout

Export all your Google data:

1. Go to takeout.google.com
2. Select the services you want (Photos, Drive, Mail, Calendar, Contacts)
3. Choose export format and frequency
4. Download and store the archive securely (backup to B2)

## Notes

- The goal is not zero Google overnight — migrate at your own pace
- Some Google services are genuinely hard to replace (YouTube, Maps)
- Prioritise based on privacy impact: Photos and Passwords first
- Keep a migration log to track progress

## Resources

- `/r/degoogle` — community resources
- privacyguides.org — vetted alternatives
- alternativeto.net — find alternatives for any service
