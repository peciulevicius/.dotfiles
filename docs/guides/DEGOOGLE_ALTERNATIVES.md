# De-Google alternatives

Per-service replacements for Google products, annotated for this setup: what
is already running, what to pick, and what was ruled out. Migration order and
decisions are in [DEGOOGLE.md](DEGOOGLE.md).

Status values: **Running** (deployed here), **Recommended**, **Ruled out**.

## Constraints that shape the picks

General privacy lists optimise for open source and privacy in the abstract.
Two additional constraints apply here and change several answers:

1. **Native IMAP is required.** `pkm/kindle_sync.py` and Odysseus's mail
   integration connect headlessly over plain IMAP from the Mac mini.
2. **Email budget is about €1/month.**

---

## Email

| Option | Status | Notes |
|---|---|---|
| Purelymail | **Recommended (chosen)** | $10/yr. Native IMAP/SMTP, custom domains, no hard limits. |
| Cloudflare Email Routing | Running | Free, receive-only. The first step; cannot send. |
| Migadu Micro | Fallback | $19/yr, native IMAP, hard cap of 20 outgoing messages/day. |
| Fastmail | Ruled out | ~$60/yr. Excellent, including best-in-class CalDAV/CardDAV, but over budget. |
| Proton Mail | Ruled out | ~$48/yr, and IMAP only through Bridge, a desktop app unsuited to a headless server. |
| Tuta Mail | Ruled out | ~$36/yr and no IMAP. |
| mailbox.org | Ruled out | The €1 tier has no custom domain. |
| Posteo | Ruled out | No custom domains by design. |
| Disroot | Ruled out | No custom domains. |
| Zoho (free) | Ruled out | Webmail only. |
| iCloud+ | Ruled out | Subscription and Apple lock-in; send-as is awkward. |

Proton and Tuta work well inside their own apps. The problem is automation:
anything headless that needs IMAP cannot use them. Their end-to-end encryption
also only applies between their own users; mail to and from other providers is
not end-to-end encrypted with any provider.

## What Nextcloud covers

Nextcloud Mail is an IMAP **client**. It displays mail from an existing
account; it does not provide an address, receive mail from the internet, or
send on its own. Email needs a provider regardless.

| Google | Nextcloud app | Status |
|---|---|---|
| Drive | Files | Running |
| Calendar | Calendar (CalDAV) | To enable |
| Contacts | Contacts (CardDAV) | To enable |
| Docs / Sheets / Slides | Office (Collabora / OnlyOffice) | Available |
| Keep | Notes | Not used — Obsidian is the notes tool |
| Meet | Talk | Available |
| Tasks | Tasks / Deck | Available |
| Photos | Files | Not used — Immich is better suited |

---

## Search

Recommended: **DuckDuckGo**. Alternatives: Kagi (paid), Startpage, Brave
Search, Mojeek, Marginalia, SearXNG (self-hostable).

## Browser

Recommended: **Brave** (installed by `os/mac/install.sh`). Firefox hardened
with arkenfox is the main alternative. Others: LibreWolf, Waterfox, Ungoogled
Chromium, Cromite. On Android: IronFox, Fennec F-Droid.

## Photos

Running: **Immich**. Ente Photos is the hosted alternative.

## Passwords

Running: **Vaultwarden**. Self-hosting includes Bitwarden's premium features,
TOTP among them. Alternatives: KeePassXC / KeePassDX, Proton Pass.

## 2FA

Highest-priority migration — Google Authenticator syncs its seeds to the
Google account. See [DEGOOGLE.md](DEGOOGLE.md#move-2fa-off-google-authenticator).

Recommended: **Ente Auth** (open source, end-to-end encrypted, cross-platform,
keeps 2FA separate from passwords). Alternatives: Vaultwarden (both factors in
one vault), Aegis (Android only), Proton Authenticator, Bitwarden
Authenticator.

## Notes

Running: **Obsidian**, synced with Syncthing. Alternatives: Joplin, Notesnook,
Standard Notes, Nextcloud Notes.

## Maps

No alternative matches Google's live traffic prediction.

Recommended: **Apple Maps** for daily use; **Organic Maps / CoMaps** for fully
offline OpenStreetMap. Others: Magic Earth, Mapy.com, OsmAnd, HERE WeGo.

## YouTube

No replacement platform exists. Privacy-respecting clients:

- Desktop and Android: **Grayjay**, **FreeTube**
- Android: NewPipe, PipePipe, LibreTube
- TV: SmartTube
- Web: Invidious

## DNS

Running: **Pi-hole**. The router does not yet point at it, so only manually
configured devices are filtered — see the Pi-hole section in
[HOME_SERVER_TODO.md](../HOME_SERVER_TODO.md). Upstream options: Quad9,
NextDNS, AdGuard DNS, Control D.

## Analytics

Recommended: **PostHog** (self-hostable) or **Plausible**. Others: Matomo,
Fathom, Ackee.

## Android apps

Relevant only if the phone moves to Android.

- **Keyboard:** HeliBoard, FUTO Keyboard, FlorisBoard. Verify swipe typing in
  the languages you use before switching.
- **App stores:** Aurora Store, F-Droid, Droid-ify, Obtainium, Accrescent.
- **Phone / SMS:** Fossify Phone, Fossify Messages, QUIK SMS.
- **VPN:** Mullvad (recommended in the GrapheneOS FAQ, available on F-Droid).
  Android allows an always-on VPN in only one profile at a time.

## Home automation

Home Assistant or openHAB, if smart-home devices are added.

## Desktop OS

Not applicable; the Macs stay on macOS.

---

## Sources

- [Privacy Guides](https://www.privacyguides.org)
- [GrapheneOS](https://grapheneos.org)
