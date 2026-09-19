# De-Google Alternatives — Reference

Community-sourced alternatives (r/degoogle, PrivacyGuides), **annotated for this
setup**. The plain lists tell you what exists; this one tells you what to
actually pick given what's already running here.

Plan and migration order: **[DEGOOGLE.md](DEGOOGLE.md)**.

**Legend:** ✅ already running · ⭐ recommended pick · ⚠️ caveat · ❌ ruled out

---

## Why this list differs from r/degoogle's

The subreddit optimises for **FOSS purity and privacy ideology**. This setup has
two additional hard constraints that change several answers:

1. **Native IMAP is mandatory** — `pkm/kindle_sync.py` and Odysseus's mail
   integration both connect over plain IMAP, headless, on a Mac mini.
2. **~€1/month budget** for email.

Where a popular recommendation fails one of those, it's marked ❌ with the
reason. The subreddit isn't wrong — it's answering a different question.

---

## Email — where the lists and this setup disagree most

| Option | Verdict |
|---|---|
| **Purelymail** | ⭐ **$10/yr (~€0.77/mo).** Native IMAP/SMTP, custom domains, no hard limits. The only real mailbox that fits both constraints. |
| Migadu Micro | Backup pick. $19/yr, native IMAP, but hard **20 outgoing msgs/day cap**. |
| Cloudflare Email Routing | ⭐ **Free**, and the right *first* step — but **receive only**, cannot send. |
| **Proton Mail** | ❌ ~$48/yr (over budget) **and** IMAP only via **Bridge**, a desktop GUI app. Fights a headless Mac mini. |
| **Tuta Mail** | ❌ ~$36/yr (over budget) **and** **no IMAP at all** — `kindle_sync.py` and Odysseus literally cannot connect. |
| mailbox.org | ❌ The €1 Light tier has IMAP but **no custom domain** — that needs Standard at €3/mo. |
| **Posteo** | ❌ **Never supports custom domains, by design.** Doing so would force them to store customer identity data, which breaks their whole privacy model. Principled, but incompatible with owning your address. |
| Disroot | ⚠️ Free/donation, but no custom domains. |
| Zoho free | ❌ Webmail only, no IMAP. |
| Fastmail | ❌ ~$60/yr — 6× budget. Excellent otherwise; its CalDAV/CardDAV is best-in-class. |
| iCloud+ | ⚠️ ~€12/yr, works via app-specific password, but send-as is fiddly and it deepens Apple lock-in. |

> **On Proton and Tuta specifically:** they're genuinely good, and if you only
> ever used their own apps they'd be fine. The blocker is automation — the
> moment something headless needs IMAP, Bridge-only or no-IMAP becomes fatal.
> Also note **email to/from Gmail users is not E2E regardless of provider** —
> Proton's encryption only applies between Proton accounts.

---

## Does Nextcloud cover email too? No — and this is the common mistake

**Nextcloud Mail is an IMAP *client*, not a mail *server*.** It displays mail
from an account you already have somewhere else. It does not give you an email
address, does not receive mail from the internet, and cannot send on its own.

So Nextcloud replaces most of Google — but **email still needs a provider**.

**PewDiePie hit exactly this.** He used Nextcloud for "PDFs, Google Docs,
calendar, contacts — all baked in one", but for mail: *"I decided to get my own
email. I paid a small fee. It was fiddly as hell."* Even in the video that
inspired this project, **email was the one thing he paid someone else to host.**

### What Nextcloud does replace (✅ already running here)

| Google | Nextcloud app |
|---|---|
| Drive | Files ✅ |
| Calendar | Calendar (CalDAV) — *enable this, Gap 3* |
| Contacts | Contacts (CardDAV) — *enable this, Gap 3* |
| Docs / Sheets / Slides | Office (Collabora / OnlyOffice) |
| Keep | Notes |
| Meet | Talk |
| Tasks | Tasks / Deck |
| Photos | Files — but **Immich ✅ is far better**, keep using it |

---

## Search

⭐ **DuckDuckGo** — the pragmatic default, what PewDiePie switched to.
Also: StartPage, Brave Search, Mojeek, Marginalia, SearXNG (self-hostable — a
reasonable future addition to this stack), Kagi (paid, excellent).

## Browser

⭐ **Brave** ✅ already installed via `os/mac/install.sh`.
Firefox is the other solid pick — PewDiePie's choice, *"B tier, but you can lock
it down to S tier"* with arkenfox. Also: LibreWolf, Waterfox, Cromite,
Ungoogled Chromium. On Android: IronFox, Fennec F-Droid.

## Photos

⭐ **Immich** ✅ already running. Ente Photos is the hosted alternative if you
ever want someone else to run it.

## Passwords

⭐ **Vaultwarden** ✅ already running. Self-hosting unlocks Bitwarden's premium
features — including TOTP — **for free**.
Also: KeePassXC / KeePassDX, Proton Pass.

## 2FA / Authenticator

⚠️ **Highest-priority migration — see Gap 0 in [DEGOOGLE.md](DEGOOGLE.md).**
Google Authenticator's seeds sync to the account being left.

⭐ **Ente Auth** — open source, E2E, free, cross-platform. Keeps 2FA separate
from passwords.
Also: Vaultwarden ✅ (convenient, but both factors in one vault), Aegis
(Android-only), Proton Authenticator, Bitwarden Authenticator.

## Notes

⭐ **Obsidian** ✅ already running, synced via Syncthing ✅.
Also: Joplin (PewDiePie's pick), Notesnook, Standard Notes, Nextcloud Notes.

## Maps

⚠️ No clean win — PewDiePie was **30 minutes late in Tokyo** using an
open-source alternative and fell back to his car's GPS.

⭐ **Apple Maps** — good in Lithuania, far better privacy than Google, zero effort.
⭐ **Organic Maps / CoMaps** — fully offline OSM, excellent for hiking and travel.
Also: Magic Earth, Mapy.com, OsmAnd, HERE WeGo.

## YouTube

No real replacement exists — PewDiePie is *on* YouTube and said so outright.
Use a privacy-respecting **client** instead:

⭐ **Grayjay** (macOS/Windows/Linux/Android) or **FreeTube**.
Android: NewPipe, PipePipe, LibreTube. TV: SmartTube. Web: Invidious.
Alternative platforms (niche): PeerTube, Odysee.

## DNS

⭐ **Pi-hole** ✅ already running — *but the router still doesn't point at it*,
so only ~3.6% of queries are filtered. See the Pi-hole section in
`HOME_SERVER_TODO.md`.
Upstream/alternatives: Quad9, NextDNS, AdGuard DNS, Control D.

## Analytics

⭐ **PostHog** (self-hostable) or **Plausible** for peciulevicius.com.
Also: Matomo, Fathom, Ackee.

## Android apps (only relevant if a Pixel happens)

- **Keyboard:** HeliBoard, FUTO Keyboard, FlorisBoard — ⚠️ **verify Lithuanian
  swipe typing before committing.** PewDiePie couldn't find a FOSS keyboard for
  his languages and fell back to Google's internet-connected one.
- **App stores:** Aurora Store (Play without an account), F-Droid, Droid-ify,
  Obtainium, Accrescent
- **Phone/SMS:** Fossify Phone, Fossify Messages, QUIK SMS
- **VPN:** ⭐ **Mullvad** — recommended in GrapheneOS's own FAQ, installs from
  F-Droid. ⚠️ Android allows always-on VPN in only one profile at a time.

## Home automation

**Home Assistant** or openHAB — only worth it if smart devices actually exist here.

## Desktop / laptop OS

Not relevant — this is a macOS shop, and the Macs are staying. Listed for
completeness: Linux Mint, Zorin, Manjaro, Framework/System76/Tuxedo hardware.

---

## Sources

- [r/degoogle alternatives wiki](https://www.reddit.com/r/degoogle/)
- [privacyguides.org](https://www.privacyguides.org)
- [grapheneos.org](https://grapheneos.org)
