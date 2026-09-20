# Jailbroken Kindle — setup guide

Turning a jailbroken Kindle Scribe into a reader for **your own** self-hosted
library, with Amazon out of the loop for reading while keeping its handwriting
stack intact.

Written for a **Kindle Scribe on firmware 5.19.6, jailbroken with Vera
(2026-09-20)**, paired with a self-hosted [Calibre-Web](../SERVICES.md) library.
Most of it applies to any jailbroken Kindle; device-specific caveats are called
out.

> **Companion docs:** [BOOKS.md](BOOKS.md) for *why* this setup exists and how
> the acquisition pipeline works · [NOTES.md](NOTES.md) for the Scribe →
> Obsidian handwriting sync.

---

## The one rule that matters

**The jailbreak is additive. Do not replace the stock reader for handwriting.**

KOReader's Scribe stylus support was merged in March 2026 and then reverted as
unstable. So:

| Task | Use |
|---|---|
| Reading EPUBs from your own library | **KOReader** |
| Handwritten notes + OCR export | **Stock Kindle software** |

The notes pipeline (`pkm/kindle_sync.py`) depends on *Share → Searchable PDF*,
which is stock-only. Breaking that breaks the vault sync.

---

## Housekeeping right after jailbreaking

### Verify OTA updates are blocked

A firmware update removes the jailbreak. Modern `hdnext`-stack jailbreaks block
updates automatically, but **verify rather than assume** — run the
**"Check OTA Status"** scriptlet.

Once confirmed, normal Wi-Fi use is fine. Wi-Fi is in fact *required* here: the
Searchable PDF export routes through Amazon to email, which is what feeds the
Obsidian vault. Permanent airplane mode is not an option for this setup.

### About `.bin` files — probably nothing to do

The KindleModding wiki advises removing stray `.bin` update files from the
**Kindle's USB storage root** — the drive that appears when you plug it into a
computer. These would be firmware images left behind by the jailbreak process;
if one is present, the device may try to install it.

Two clarifications, because this is easy to misread:

- ⚠️ **KOReader's `bin` folder is unrelated.** That holds KOReader's own
  binaries. Leave it alone.
- **With no computer to hand, there is nothing to browse** — the Kindle has no
  built-in file manager. Either check next time you connect over USB, or install
  `kterm` and run `ls /mnt/us/*.bin`.

If the jailbreak completed and OTA is blocked, this is housekeeping, not urgent.

---

## KPM — the package manager

Packages are installed with **KPM**, which came with the jailbreak. Two ways to
invoke it, and which one your build accepts varies:

```
;kpm install <package>          # typed into the Kindle's SEARCH BAR
kpm -S <package>                # inside kterm, or where the wiki documents it
```

Both appear in current documentation. Try the search-bar form first; if the
scriptlet doesn't respond, install `kterm` and use the `-S` form there.

Useful commands:

```
;kpm update                     # refresh package lists
;kpm add-repo <url>             # add a third-party repository
;kpm list-repo                  # show configured repositories
```

Directory of everything available:
[KindleTweaks/Awesome-Kindle](https://github.com/KindleTweaks/Awesome-Kindle) ·
[KPM wiki](https://kpmwiki.vercel.app)

---

## 1. KOReader + your own library over OPDS

This is the payoff: reading your Calibre-Web EPUBs on the Kindle with no
Send-to-Kindle round trip through Amazon.

### Install

```
;kpm install koreader
```

A new scriptlet appears once it finishes.

### Point it at Calibre-Web

In KOReader:

1. Tap the **top of the screen** to open the menu
2. Go to the **magnifying glass / search icon** → **OPDS catalog**
3. Tap **+** (add catalog) — usually top-left, or via the ☰ menu
4. Fill in:

| Field | Value |
|---|---|
| **Catalog name** | `Calibre-Web` (anything you like) |
| **Catalog URL** | `https://books.peciulevicius.com/opds` |
| **Username** | your Calibre-Web login |
| **Password** | your Calibre-Web password |

5. Save, then tap the catalog to browse. Tap a book → choose **EPUB** → it
   downloads to the device and opens in KOReader.

### Why this works

Verified 2026-09-20: that endpoint answers with **HTTP Basic auth**
(`WWW-Authenticate: Basic`), which KOReader's OPDS client speaks natively.

⚠️ It is deliberately **not** behind Cloudflare Access. An Access policy that
challenges the browser also blocks KOReader, which cannot complete an
interactive login — the same constraint that applies to the Obsidian LiveSync
plugin. If you ever put Access in front of Calibre-Web, OPDS breaks.

### What you gain over Send-to-Kindle

| | Send to Kindle | KOReader + OPDS |
|---|---|---|
| Amazon sees your library | ✅ yes | ❌ no |
| Reads EPUB | converts server-side | natively |
| Page numbers | usually unavailable (no APNX) | real pagination |
| Covers | often a generic placeholder | the EPUB's own cover |

### Finding your books — and taming the file browser

KOReader's file browser opens on the Kindle's **storage root** (`/mnt/us/`), so
the first thing you see is the device's own plumbing:

```
audible/  documents/  fonts/  kmc/  koreader/  libkh/
lost+found/  screenshots/  system/  voice/  privesc_marker
```

Only two of those matter to you:

| Folder | What's in it |
|---|---|
| **`documents/`** | **Your books.** Where the stock Kindle keeps them, and where Send-to-Kindle deposits them. |
| `screenshots/` | Yes — screenshots. Tap two **diagonally opposite corners** at the same time. KOReader can also bind it to a gesture. |

The rest is firmware, fonts, the jailbreak's own files (`libkh/`,
`privesc_marker`) and KOReader itself. **Leave them alone.**

#### Make it usable, once

1. **Set a home directory.** Long-press `documents/` (or a dedicated `books/`
   folder you create) → **Set as HOME directory**. The home button then always
   lands there instead of the root.
2. **Hide the noise.** In the file browser, open the **☰ menu → Settings** and
   turn **off** *Show unsupported files*. Firmware clutter stops appearing.
   Leave *Show hidden files* off too.
3. **Send OPDS downloads to the same place.** The first time you download from
   the catalog, KOReader asks where to save — choose your home folder so
   everything lands together rather than scattering.
4. **Use History and Favorites** rather than browsing. The ☰ menu has both;
   long-press any book → *Add to favorites*. For a real library, collections
   beat folder navigation.

A dedicated `books/` folder at the root is worth it if you want your own library
kept clearly apart from whatever Amazon has put in `documents/`.

### Books do not sync automatically

OPDS is **pull**: open KOReader, browse, tap to download. There is no background
sync. To push instead, see *SSH over USB* below.

---

## 2. Custom lockscreens

```
;kpm add-repo https://kpm.andrecheng.com/kpm.json
;kpm list-repo
;kpm update
;kpm install custom-screensaver
```

Then drop **PNG** files into `/screensavers/` on the Kindle's storage. Any
filename works, images are scaled automatically, and they rotate alphabetically.
It needs neither KOReader nor KUAL.

⚠️ **Untested on the Scribe.** Its author lists Kindle 12th gen, Paperwhite 5 and
Paperwhite 6 on firmware 5.18.6–5.19.6. The firmware range matches the Scribe,
but the panel is 10.2" instead of ~6–7", so scaling is what to watch.

**Fallback if it misbehaves** — KOReader's own sleep screen, which only covers
sleep *from within KOReader*:

> gear icon → **Screen** → **Sleep screen** → **Wallpaper** → point at a folder
> of images

Source: [chengandre/kindle-custom-screensaver](https://github.com/chengandre/kindle-custom-screensaver)

---

## 3. KindleFetch — grabbing a book with no computer

Searches **Anna's Archive** and downloads straight to the device. Genuinely
useful when you want a book immediately and aren't near a computer.

Two versions — **prefer the KOReader plugin**, since you already have KOReader
and it keeps everything in one app:

| Version | Install | Notes |
|---|---|---|
| **KOReader plugin** ⭐ | [william-spongberg/KindleFetch.koplugin](https://github.com/william-spongberg/KindleFetch.koplugin) | Search and download without leaving KOReader. Also covers Library Genesis. |
| CLI | `;kpm install kindlefetch` (or `kpm -S kindlefetch`) | Runs in kterm / KUAL. [justrals/KindleFetch](https://github.com/justrals/KindleFetch) |

**How it fits with the self-hosted stack:** it doesn't replace it. LazyLibrarian
→ Calibre-Web remains the library — everything catalogued, backed up to R2, and
readable on every device. KindleFetch is the quick path when you're away from a
computer. Books grabbed this way live only on the Kindle unless you add them to
Calibre-Web later, so treat it as a shortcut rather than the front door.

Anna's Archive indexes copyrighted material; what you download is your call.

---

## 4. SSH over USB — push books instead of pulling

```
;kpm install usbnetlite
```

Gives the Kindle an SSH server over the USB cable. That unblocks a push script
(`scripts/books/push-to-kindle.sh`, not yet written) to `scp` new EPUBs across in
bulk rather than tapping through OPDS one at a time.

Do OPDS first — it needs nothing and works over Wi-Fi from anywhere. This is the
upgrade once the library is big enough for one-at-a-time to annoy.

---

## 5. HotfixUpdater

Keeps the OTA-blocking hotfixes current as Amazon ships new firmware. Cheap
insurance on a device that stays on Wi-Fi permanently.

---

## Audiobooks: LARK doesn't fit this device (yet)

**LARK** is a Libre Audiobook Player for Kindle — MP3 and M4B over Bluetooth,
which is appealing given the Scribe has Bluetooth and you already run
Audiobookshelf.

Three findings, checked 2026-09-20, and together they rule it out for now:

1. 🔴 **Firmware.** The project states *"Only Firmware <5.19 supported right
   now"*. The Scribe here is on **5.19.6**, so it is outside the supported
   range. Upstream is "working on a solution for newer devices".
2. 🔴 **No read-along.** It has **no text/audio synchronisation, no word
   highlighting** — listening history, chapters, bookmarks and metadata only.
   What you may be thinking of is Amazon's **Immersion Reading / Whispersync for
   Voice**, which highlights narrated words in a matched Kindle+Audible edition.
   That is an Amazon feature requiring both editions of the same title; no
   third-party Kindle player reproduces it.
3. 🟠 **No streaming.** LARK plays **local files only**, so it would not replace
   Audiobookshelf — you would copy M4B files onto the Kindle's limited storage
   by hand, losing Audiobookshelf's progress sync across devices.

**Recommendation:** keep using Audiobookshelf on the phone for audiobooks. Revisit
LARK if it gains 5.19+ support and you specifically want one device for both.

Sources: [kbarni/LARKPlayer](https://github.com/kbarni/LARKPlayer) ·
[Teknoist/BARKPlayer](https://github.com/Teknoist/BARKPlayer) (an updated fork —
worth checking whether it has moved past the 5.19 limit)

---

## Worth installing

| Tool | Why |
|---|---|
| **kterm** | E-ink terminal. The thing you need when something breaks on-device, and the fallback for `kpm -S` syntax. |
| **KOPlugins** | KOReader plugin ecosystem — dictionaries, statistics, custom gestures. |

## Skip these

| Tool | Why not |
|---|---|
| **Android on Kindles** | Would destroy the handwriting stack the notes pipeline depends on. |
| **Disable ADs** | No ad-supported Scribe variant exists. |
| Games, KAnki, Kreate, Textadept | Fun; unrelated to this setup. |

---

## Recovery

The jailbreak is **reversible**: `renametobin` *Restore* → factory reset →
allow the firmware update. Worth knowing for a warranty claim — EU statutory
warranty is **2 years**, to roughly October 2027.

⚠️ Never take a firmware update while jailbroken unless you intend to lose it.

---

## Setup checklist

- [ ] Verify OTA blocked ("Check OTA Status" scriptlet)
- [ ] Check for stray `.bin` files in the USB root, next time you connect
- [ ] `;kpm install koreader`
- [ ] Add the OPDS catalog, download one book, confirm it opens
- [ ] `;kpm install custom-screensaver` + PNGs in `/screensavers/`
- [ ] KindleFetch KOReader plugin
- [ ] `;kpm install usbnetlite` (optional, enables the push script)
- [ ] HotfixUpdater
- [ ] Confirm stock handwriting + *Share → Searchable PDF* still works
