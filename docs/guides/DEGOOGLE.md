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
- [ ] Switch to Vaultwarden as Bitwarden server (see [SERVICES.md](../SERVICES.md))
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

  **Decision: ProtonMail vs Fastmail**

  | | ProtonMail | Fastmail |
  |---|---|---|
  | Privacy | E2E encrypted, Swiss jurisdiction | Not E2E, Australian |
  | Custom domain | Yes (Mail Plus, ~$4/mo) | Yes (Standard, ~$5/mo) |
  | IMAP/SMTP | Via Proton Bridge app only | Native IMAP/SMTP |
  | CalDAV/CardDAV | Yes (Bridge or native apps) | Yes (native, excellent) |
  | Ecosystem | Mail + Calendar + Drive + VPN + Pass | Mail + Calendar + Contacts |
  | Catch-all / aliases | Yes | Yes |

  ProtonMail = privacy-first. Fastmail = "just works" with better standards support.

  **Step 0 — Use your own domain (most important step)**
  - Set up email on `peciulevicius.com` (or another domain you own)
  - Both Proton and Fastmail support custom domains on paid plans
  - This means you're never locked into any provider — switch by changing MX records
  - If you ever move providers, your email address stays the same

  **Step 1 — Set up new email**
  - Create account on chosen provider (Proton or Fastmail)
  - Add custom domain, configure MX + SPF + DKIM + DMARC records
  - Verify domain ownership
  - Create your address: `dziugas@peciulevicius.com` (or preferred format)

  **Step 2 — Forward Gmail**
  - Gmail → Settings → Forwarding → Add forwarding address → new email
  - Keep a copy in Gmail (for safety during transition)
  - This ensures you don't miss anything during migration

  **Step 3 — Import Gmail archive**
  - Google Takeout → select Gmail → download .mbox
  - ProtonMail: Import/Export app (desktop) or Easy Switch (web)
  - Fastmail: Settings → Import & Export → Import from Gmail directly

  **Step 4 — Update critical accounts (do these first)**
  - [ ] Apple ID
  - [ ] Bank / financial institutions
  - [ ] GitHub
  - [ ] Domain registrar (Cloudflare)
  - [ ] Stripe / payment processors
  - [ ] Cloud providers (Vercel, Supabase, Cloudflare)
  - [ ] Password manager (Vaultwarden) — update vault email

  **Step 5 — Update remaining accounts**
  - Use Vaultwarden to find all accounts with the old Gmail
  - Update 5-10 per day — don't try to do all at once
  - For unimportant accounts: just leave them, they'll forward

  **Step 6 — Update contacts**
  - Send a short "new email" message to frequent contacts
  - Update email signature everywhere
  - Update any public profiles (GitHub, LinkedIn, etc.)

  **Step 7 — Wind down Gmail (after 6 months)**
  - Check Gmail forwarding is still catching stragglers
  - After 6 months with no important mail going only to Gmail:
    - Stop forwarding
    - Set Gmail vacation responder with new address
    - Keep the Google account (don't delete — prevents someone else registering it)
    - Download final Takeout backup, store on B2

- [ ] **Google Calendar → Nextcloud Calendar**
  - Export: Google Calendar → Settings → Export
  - Import .ics files into Nextcloud Calendar
  - Subscribe mobile calendar to Nextcloud via CalDAV
  - Share calendar URL with contacts who need it

- [ ] **Google Contacts → Nextcloud Contacts**
  - Export: contacts.google.com → Export → vCard
  - Import .vcf into Nextcloud Contacts
  - Set up CardDAV sync on iPhone (Settings → Contacts → Accounts → Add)

### Phase 3 — Messaging & Communication

- [ ] **WhatsApp/Messenger → Signal**
  - Download Signal on phone and desktop
  - Start with close friends/family — ask them to install Signal
  - Use Signal as default for new conversations
  - Keep Messenger for people who won't switch (can't fully escape Meta for social)
  - Don't delete WhatsApp/Messenger — just reduce usage over time

### Phase 4 — Microsoft Cleanup

- [ ] **Audit Microsoft accounts**
  - Check for any personal Microsoft accounts (Outlook, OneDrive, Xbox, etc.)
  - Close/delete unused personal accounts
  - Note: work C#/.NET usage is separate, no action needed there

### Phase 5 — Deepen Privacy

- [ ] Remove Google Analytics from personal sites → use PostHog or Plausible
- [ ] Replace Google Fonts with self-hosted fonts or bunny.net/fonts
- [ ] Switch to a privacy-respecting DNS (Cloudflare 1.1.1.1 or NextDNS)
- [ ] Audit app permissions — revoke Google sign-in from apps where possible
- [ ] Set up NextDNS or Pi-hole to block tracking at DNS level
- [ ] Review remaining Google accounts — delete unused ones
- [ ] Enable Google Account activity controls to minimise data collection
- [ ] Remove Google as Cloudflare Access identity provider (after email migration is done)

### Phase 6 — ProtonMail + Custom Domain Setup

- [ ] **Set up ProtonMail with `peciulevicius.com`**
  - Sign up for ProtonMail Plus (~$4/mo)
  - Add custom domain in ProtonMail settings
  - Configure DNS records in Cloudflare:
    - MX records (ProtonMail provides these)
    - SPF: TXT record `v=spf1 include:_spf.protonmail.ch ~all`
    - DKIM: CNAME records (ProtonMail provides 3 of these)
    - DMARC: TXT record `v=DMARC1; p=quarantine`
  - Verify domain ownership
  - Create address: `dziugas@peciulevicius.com`
  - All existing Gmail history can be imported via ProtonMail Easy Switch

## Services We're Not Escaping (and that's fine)

| Service | Why |
|---------|-----|
| **Meta/Messenger** | Social connections — keep for people who won't use Signal |
| **Apple** | Privacy-respecting enough, deeply integrated with macOS/iPhone |
| **Amazon** | Shopping — no practical alternative |
| **YouTube** | No real alternative, use FreeTube client for privacy |
| **GitHub** | Developer ecosystem, owned by Microsoft but irreplaceable |

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
- Use your own domain for email — never locked into any provider
- Keep a migration log to track progress

## Resources

- `/r/degoogle` — community resources
- privacyguides.org — vetted alternatives
- alternativeto.net — find alternatives for any service
