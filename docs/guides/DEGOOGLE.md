# De-Googling

Plan for moving personal data and daily services off Google. The aim is to stop
*using* Google services, not to delete the Google account.

Related documents:

- [DEGOOGLE_ALTERNATIVES.md](DEGOOGLE_ALTERNATIVES.md) — per-service
  replacement list with the reasoning for each pick. Check it before replacing
  any individual service.
- [EMAIL.md](EMAIL.md) — the email migration runbook.
- [SELF_HOSTED_AI.md](SELF_HOSTED_AI.md) — the AI workspace.

---

## Status

Most of the migration is complete. The self-hosted stack already covers photos,
files, passwords, notes and bookmarks.

| Area | Replacement | Status |
|---|---|---|
| Passwords | Vaultwarden | Done |
| Files / Drive | Nextcloud, Syncthing, NAS | Done |
| Notes | Obsidian + Syncthing (LiveSync in progress) | Done |
| Photos | Immich | Done |
| Domain and remote access | `*.peciulevicius.com` via Cloudflare Tunnel, Tailscale, Cloudflare Access | Done |
| News / RSS | FreshRSS | Done |
| AI | Odysseus (cloud and local models) | Done (see [SELF_HOSTED_AI.md](SELF_HOSTED_AI.md)) |
| 2FA codes | Ente Auth or Vaultwarden | **Not started — highest priority** |
| Email | Purelymail on the own domain | In progress — see [EMAIL.md](EMAIL.md) |
| Calendar and contacts | Nextcloud (CalDAV/CardDAV) | Not started |
| Search and browser defaults | DuckDuckGo / Kagi, Brave | Verify on every device |
| Phone OS | Hardened iOS for now | Decided — see [Phone](#phone) |
| Maps | Apple Maps / Organic Maps | Partial — see [Maps](#maps) |

Remaining work: 2FA, email, calendar/contacts, and the defaults on each device.

---

## Replacement map

| Google service | Self-hosted | Hosted alternative |
|---|---|---|
| Google Photos | Immich (running) | — |
| Google Drive | Nextcloud (running) | Proton Drive |
| Google Docs | Nextcloud + Collabora | Notion, Coda |
| Gmail | Not self-hosted — see [Email](#email) | Purelymail (chosen), Migadu, Fastmail |
| Google Calendar | Nextcloud Calendar | Fastmail |
| Google Contacts | Nextcloud Contacts | Fastmail |
| Chrome sync | — | Firefox Sync |
| Google Password Manager | Vaultwarden (running) | Bitwarden Cloud |
| YouTube | — | FreeTube / Grayjay (clients only) |
| Google Maps | — | Apple Maps, Organic Maps, OsmAnd |
| Google Analytics | PostHog | Plausible |
| Google Search | — | DuckDuckGo, Kagi |
| Google Fonts | Self-host | bunny.net/fonts |
| Google News | FreshRSS (running) | — |
| Google Home | Home Assistant | — |
| Gemini / ChatGPT | Odysseus + local models | — |

---

## Accounts, logins and 2FA

Complete this section before changing any email address.

### Move 2FA off Google Authenticator

Google Authenticator syncs its TOTP seeds to the Google account. While the
seeds live there, the second factor for every other account depends on the
account being retired. Losing that account or the phone before migrating locks
out every service whose codes it holds.

1. Google Authenticator → ⋯ → **Transfer accounts → Export accounts**. This
   produces QR codes containing the TOTP seeds.
2. Import them into the replacement.
3. Log in to several services with the new app before removing anything.
4. Keep Google Authenticator installed, unused, for a month as a fallback.

| Option | Assessment |
|---|---|
| **Ente Auth** | Recommended. Open source, end-to-end encrypted, free, iOS/Android/desktop, works on GrapheneOS. Keeps 2FA separate from passwords. |
| Vaultwarden | Works; self-hosting unlocks Bitwarden's premium TOTP feature for free. Storing codes next to passwords means one compromised vault exposes both factors. |
| Aegis | Android only. An option if the phone changes platform. |

### "Sign in with Google" accounts

There are two kinds of Google-linked logins:

1. **Accounts that use the Gmail address as a username**, with their own
   password. These keep working indefinitely; change the address at each
   service over time.
2. **Accounts that use "Sign in with Google" (OAuth).** These have no password
   of their own. If the Google account disappears, so do they, often with no
   recovery path.

To remove the OAuth dependency:

1. List the dependencies: Google Account → **Security** → *Your connections to
   third-party apps & services*.
2. For each account that matters, log in, **set a password**, then change the
   email to the new address.
3. Leave unimportant ones as they are.

### Keep the Google account

Do not delete the Google account:

- Deleting it breaks every remaining "Sign in with Google" login, often
  permanently.
- It frees the old `@gmail.com` address for someone else to register, who could
  then request password resets on accounts that were never migrated.
- A dormant account costs nothing.

The end state is an empty account that forwards mail and anchors legacy OAuth
logins.

### Redirecting mail during the transition

Existing services keep the Gmail address on file until it is changed at each
one. Forwarding keeps everything in one inbox while that happens.

| Phase | What happens |
|---|---|
| A | The new address forwards *to* Gmail (Cloudflare Email Routing). Hand out the new address; keep reading Gmail. |
| B | Once the real mailbox exists, Gmail forwards *to* the new address (Settings → Forwarding and POP/IMAP, keep Gmail's copy) and the new address becomes the default *Send mail as*. |
| C | Update accounts gradually, 5–10 a day. Banks, Apple ID, GitHub, Cloudflare and Stripe first. |
| D | After about six months with nothing important arriving only at Gmail: stop forwarding, set an auto-reply pointing to the new address, leave the account dormant. |

### Phone apps

| Google app | Replacement | Notes |
|---|---|---|
| Authenticator | Ente Auth | Do first — lockout risk |
| Gmail | Apple Mail over IMAP | After the email cutover |
| Calendar | Nextcloud Calendar (CalDAV) | See [Calendar and contacts](#calendar-and-contacts) |
| Drive | Nextcloud | Running |
| Chrome | Brave or Safari | — |
| Maps | Apple Maps / Organic Maps | See [Maps](#maps) |
| Translate | Apple Translate or DeepL | — |
| Sheets / Slides | Nextcloud Office, or Numbers/Keynote | — |
| Meet | Jitsi | Keep Meet where others require it |
| Home | Home Assistant | Only with smart-home devices |

Only Authenticator carries real risk; the rest can be removed in any order.

---

## Email

The full procedure — DNS records, ordering constraints, rollback and
verification — is in **[EMAIL.md](EMAIL.md)**. This section records the
decisions.

### How the pieces fit

- **The address belongs to the domain owner.** `@peciulevicius.com` stays the
  same whichever provider sits behind it.
- **MX records** tell senders which server accepts mail for the domain.
  Changing provider means changing MX records.
- **SPF, DKIM and DMARC** records prove outbound mail is authorised. Without
  them, major providers file it as spam.
- A hosted provider needs no `mail.` hostname; that only matters when running
  the mail server yourself.

### Decision: do not self-host the mail server

- Residential IP ranges are on Spamhaus PBL by default, so outbound mail lands
  in spam without any error.
- Most ISPs block outbound port 25.
- Residential connections cannot set reverse DNS, which receivers check.
- Every other service here degrades gracefully when the Mac mini is down; a
  mail server that is down loses mail silently.

### Decision: Purelymail

Requirements:

1. **Native IMAP/SMTP.** `pkm/kindle_sync.py` and Odysseus's mail integration
   connect headlessly over plain IMAP.
2. **Budget of about €1/month.**

| Provider | Cost/yr | IMAP/SMTP | Result |
|---|---|---|---|
| **Purelymail** | ~$10 | Native | **Chosen.** No hard limits on domains, addresses or storage. Small operator; pricing model under review in 2026, so confirm at signup. |
| Migadu Micro | $19 | Native | Fallback. Hard cap of 20 outgoing messages/day. |
| Fastmail | ~$60 | Native + JMAP | Excellent, but six times the budget. Its CalDAV/CardDAV advantage is covered by Nextcloud. |
| MXroute | $59 | Native | Over budget. |
| Proton Mail Plus | ~$48 | Bridge only | Over budget. Bridge is a desktop app, which does not suit a headless server. Its end-to-end encryption only applies between Proton users. |
| Tuta | ~$36 | None | No IMAP; cannot work with the Kindle pipeline or Odysseus. |
| mailbox.org | €12+ | Native | €1 tier has no custom domain. |
| Posteo | €12 | Native | No custom domains by design. |
| Zoho (free) | €0 | None | Webmail only. |
| iCloud+ | ~€12 | Native | Rejected: subscription (cancelled in 2026) and Apple lock-in. |

**Forwarding-only services receive but cannot send.** Cloudflare Email
Routing, ImprovMX and Forward Email's free tier all forward inbound mail;
replying from the domain needs a real mailbox with SMTP.

### Email Routing and the catch-all

Cloudflare Email Routing was the first step: free, receive-only, and it moved
the domain's inbound mail off Google without choosing a provider.

Explicit routing rules match first; anything unmatched falls through to the
catch-all. With a catch-all enabled, every local part at the domain is
delivered (verified 2026-09-19).

- **Benefit:** per-service aliases (`bank@`, `github@`, …) need no setup, and
  an alias that starts receiving spam identifies who leaked it.
- **Cost:** a catch-all accepts mail for addresses that were never issued. If
  the domain is dictionary-attacked, replace the catch-all with explicit rules
  for the aliases in use.

### Mail clients

Clients are free and independent of the provider.

| Platform | Client |
|---|---|
| iPhone and Mac | Apple Mail (built in, IMAP) |
| Desktop, advanced filtering | Thunderbird |
| Android | Thunderbird for Android (formerly K-9 Mail) |

### Kindle pipeline dependency

`pkm/kindle_sync.py` reads Kindle Scribe exports from a mailbox over IMAP every
hour and files them into the Obsidian vault. Any provider without plain IMAP
breaks it. Its mailbox settings live in `pkm/config.py` (gitignored); see
[NOTES.md](NOTES.md).

---

## Phone

### Current device

The iPhone cannot run another operating system:

- The bootloader cannot be unlocked, and iPhones cannot dual-boot.
- The checkm8 bootrom exploit covers A11 and earlier; the current phone is A15.
- Projects such as Project Sandcastle only booted limited Linux on old hardware.

The choice is therefore between hardening iOS and moving to Android.

### Decision: keep the iPhone for now

**Harden iOS now; revisit the phone when the current one reaches end of support
(~2028–2030).**

Rationale:

- With photos, files, passwords, notes and documents self-hosted, the data
  ownership goal is largely met. With the Google apps removed, Google is no
  longer on the phone; what remains is Apple telemetry, a separate and smaller
  concern.
- A physical iPhone is required for Expo / React Native iOS testing, so a new
  Android phone would be a second device rather than a replacement.
- Switching costs fall on daily conveniences: Apple Wallet (cards and loyalty
  cards), tap-to-pay, and a larger form factor — no current Pixel is compact.
- The current phone receives security updates until roughly 2029–2030. A
  battery replacement (~€90) extends its useful life.

A refurbished Pixel 8a (~€233) is a reasonable purchase only as a test device
for evaluating GrapheneOS.

### Hardening iOS

1. Enable **Advanced Data Protection** (Settings → Apple Account → iCloud).
   It makes iCloud data end-to-end encrypted and is available without a paid
   iCloud+ plan.
2. Delete the Google apps: Gmail, Maps, Drive, Photos, Chrome.
3. Set the default search engine to DuckDuckGo or Kagi.
4. Settings → Privacy & Security → Tracking → disable *Allow Apps to Request to
   Track*.
5. Install the Immich, Nextcloud and Bitwarden apps pointed at the self-hosted
   services.
6. Add CalDAV and CardDAV accounts (see below).
7. Settings → Face ID & Passcode → disable Control Center and Siri on the lock
   screen.

### Apple and privacy

Apple is meaningfully better than Google on privacy — its core business is
hardware, it processes more on-device, and Advanced Data Protection encrypts
iCloud end to end. It is still a closed, commercial platform: it runs an ads
business, ties analytics to the Apple ID, and without Advanced Data Protection
holds the keys to iCloud backups. GrapheneOS is the only option where the user
controls what reaches the network.

### Android options (for the future decision)

A custom OS is only as trustworthy as the device's ability to **relock the
bootloader** with the OS's own signing key. Without that, verified boot is lost
permanently, which makes a custom ROM less secure than stock.

| OS | Devices | Notes |
|---|---|---|
| **GrapheneOS** | Pixel only | Strongest. Storage Scopes, per-app network permission, user profiles. A Motorola partnership is announced for 2027 devices. |
| CalyxOS | Pixel, Fairphone 5, some Motorola | Relocks the bootloader; best non-Pixel option. Uses microG. |
| iodéOS | Fairphone 6 and others | LineageOS-based, built-in ad blocker. |
| /e/OS | Fairphone 6, wide range | Friendliest; sold preinstalled on Murena phones. |
| LineageOS | Widest | Usually cannot relock the bootloader. |

GrapheneOS drops a device when Google stops shipping its firmware, so the
support end date matters most. Prices as of September 2026:

| Model | Price | Support ends | Assessment |
|---|---|---|---|
| Pixel 10a (new) | €403 | March 2033 | Best as a daily driver: new battery, local warranty, longest support. |
| Pixel 8a (refurbished) | €233 | ~May 2031 | Best as a test device. |
| Pixel 8 (refurbished) | €249 | ~Oct 2030 | No advantage over the 8a. |
| Pixel 10 (refurbished) | €545 | ~2032 | Overpriced relative to the 10a. |
| Pixel 6 Pro (refurbished) | €205 | October 2026 | Do not buy — support ends this month. |

Before buying:

- **Refurbished units must be carrier-unlocked and not a US carrier model.**
  Carrier-locked Pixels (Verizon in particular) have bootloaders that cannot be
  unlocked, which makes GrapheneOS impossible.
- Check the battery grade and the seller rating; refurbished marketplaces vary
  by seller.
- **Google Wallet does not run on GrapheneOS**, so tap-to-pay stops working.
  Confirm the current status first.
- Banking apps that use hardware attestation may refuse to run. Test each one.
- Confirm HeliBoard (the open-source keyboard) handles swipe typing in the
  languages you use.

Daily-use differences on GrapheneOS with sandboxed Google Play:

| Area | Effect |
|---|---|
| Contactless payment | Lost (Google Wallet refuses to run). |
| iMessage, FaceTime, AirDrop, Handoff, Find My | Lost. Syncthing and Nextcloud cover file transfer. |
| Push notifications, most Play Store apps | Work normally via sandboxed Play Services. |
| Gains | Per-app network permission, Storage Scopes, apps fully stop when closed, isolated user profiles. |
| Self-hosted apps | Immich, Nextcloud, Bitwarden, Jellyfin and Syncthing all have Android clients. |

Mullvad is supported on GrapheneOS (installable from F-Droid). Android allows
an always-on VPN in only one user profile at a time.

The Minimal Phone 2 (€599–699) cannot run GrapheneOS and ships with Google Play
Services. It addresses attention rather than privacy; GrapheneOS user profiles
provide a similar focus benefit.

---

## Calendar and contacts

Contacts and calendar currently exist **only on the iPhone**, with no backup.
This is a single point of failure as much as a de-Googling task: a lost or
broken phone loses both.

Nextcloud is already running; this takes about an hour.

1. Nextcloud → Apps → enable **Calendar** and **Contacts**.
2. **Export from the phone first**, before changing any sync setting — for
   example Contacts → select all → Share → vCard. Do not let the first two-way
   merge run against the only copy.
3. Import the export into Nextcloud.
4. iPhone → Settings → Calendar → Accounts → Add Account → Other → **Add CalDAV
   Account**, server `cloud.peciulevicius.com`. Repeat for **CardDAV** under
   Contacts.
5. Verify two-way sync, then confirm a fresh device (or a re-added account)
   shows everything. That is the real backup test.

> **Note:** Nextcloud Mail is an IMAP client, not a mail server. Nextcloud
> covers Drive, Calendar, Contacts, Docs, Notes and Meet; email still needs a
> provider.

---

## Maps

Google Maps' traffic prediction depends on the location data this effort
avoids, and no alternative matches it.

1. **Apple Maps** — good coverage, far better privacy, no setup.
2. **Organic Maps / OsmAnd** — fully offline OpenStreetMap; good for hiking and
   travel, weak on live traffic.
3. Google Maps in a signed-out browser tab when live traffic matters.

---

## Checklist of remaining defaults

- Default search engine is DuckDuckGo or Kagi in every browser and on the phone.
- Default browser is Brave (installed by `os/mac/install.sh`) or Firefox.
- Personal sites use self-hosted fonts or bunny.net/fonts, not Google Fonts.
- Personal sites use PostHog or Plausible, not Google Analytics.
- The router points at Pi-hole (see the Pi-hole section in
  [HOME_SERVER_TODO.md](../HOME_SERVER_TODO.md)).
- Google is removed as a Cloudflare Access identity provider — only after the
  email migration.

---

## Services kept

| Service | Reason |
|---|---|
| YouTube | No equivalent exists. FreeTube or Grayjay reduce tracking as clients. |
| Messenger / WhatsApp | Where contacts are. Signal where possible. |
| Apple | Better than Google on privacy; the Macs depend on it. |
| GitHub | Central to development work. |
| Amazon | Shopping; the Kindle export pipeline also routes through it. |

---

## Google Takeout

1. Go to takeout.google.com.
2. Select Photos, Drive, Mail, Calendar and Contacts.
3. Store the archive on the NAS; it is included in the R2 backup via
   `services/rclone/rclone-backup.sh`.

## References

- [Privacy Guides](https://www.privacyguides.org) — vetted alternatives
- [GrapheneOS](https://grapheneos.org) — installation guide and supported devices
