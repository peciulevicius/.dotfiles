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

## How installs actually work

Three different mechanisms, and knowing which one a tool uses saves most of the
confusion — **`;kpm install` does not work for most things on the list.**

| Method | How | Which tools |
|---|---|---|
| **KPM** | `;kpm install <name>` in the search bar, or `kpm -S <name>` in kterm | Only a handful of official packages, plus whatever third-party repos you add |
| **KOReader plugin** | Unzip a `*.koplugin` folder into `koreader/plugins/` | Anything ending `.koplugin` |
| **Manual scriptlet / extension** | Unzip into `documents/` or `extensions/` at the Kindle's root, then run from the search bar or KUAL | Most of the rest |

KPM's official package list is small — as of 2026-09: `blockamazon`,
`gnomegames`, `hello`, `hyprpad`, `kanki`, `kindlefetch`, `kwordle`, `make`,
`musl`. Check the current list at the [KPM wiki](https://kpmwiki.vercel.app/packages).

> **KindleForge** is a GUI app store for Kindles and sounds like the obvious
> shortcut, but skip it here: it targets AdBreak/WinterBreak/LanguageBreak
> jailbreaks (not Vera), and its author has it in **maintenance mode pending a
> rewrite on top of KPM**. Use KPM directly.

---

## What each KPM package is

The official repo is small. As of 2026-09:

| Package | What it is | Verdict here |
|---|---|---|
| `kindlefetch` | Download books from Anna's Archive on-device | ⭐ **Install** |
| `blockamazon` | Blocks Amazon domains via `/etc/hosts` to disable the Kindle store | ⚠️ **Careful** — see below |
| `hyprpad` | Simple on-device text editor, e-ink optimised | Optional |
| `kanki` | Anki-style flashcards | Optional — [RAnki](https://github.com/crazy-electron/ranki) syncs with real Anki, this doesn't |
| `gnomegames` | Chess (decent AI) + Minesweeper | Fun |
| `kwordle` | Wordle | Fun |
| `hello` | A hello-world test package | Skip — it exists to verify KPM works |
| `make` | The `make` build tool | **Dependency**, pulled in when something needs it |
| `musl` | The musl C library | **Dependency**, same |

`make` and `musl` are libraries other packages depend on — install them only when
something asks, not on their own.

### ⚠️ `blockamazon` could break the notes pipeline

It works by blocking Amazon domains in `/etc/hosts` to kill the store. The
project does **not** document which domains, and this device depends on Amazon
for one thing that matters: *Share → Searchable PDF* routes the handwriting OCR
**through Amazon to email**, which is what feeds `kindle_sync.py` into the
Obsidian vault.

If you want it:

1. Install it, then **immediately test a Searchable PDF export** and confirm the
   mail arrives
2. If it doesn't, unblock — the extension ships an **unblock** function in KUAL,
   so it is reversible

Don't install it and discover three weeks later that notes stopped syncing.

---

## Going through Awesome-Kindle, annotated

Every entry from [the list](https://github.com/KindleTweaks/Awesome-Kindle),
with a verdict for **this** setup — a Scribe used for reading a self-hosted
library and taking handwritten notes.

### Install these

| Tool | What it does | How |
|---|---|---|
| [KOReader](https://koreader.rocks/) ✅ | The reason for jailbreaking. EPUB natively, real pagination, OPDS. | `;kpm install koreader` — **done** |
| [KindleFetch](https://github.com/justrals/KindleFetch) | Download books from Anna's Archive on-device, no computer. | `;kpm install kindlefetch`, or better the [KOReader plugin](https://github.com/william-spongberg/KindleFetch.koplugin) |
| [HotfixUpdater](https://github.com/KindleTweaks/HotfixUpdater) | Keeps the universal hotfix current, which is what keeps OTA blocked. | Manual — grab the release |
| [kTerm](https://github.com/bfabiszewski/kterm) | E-ink terminal. What you need when something breaks on-device, and the fallback for `kpm -S`. | Manual — unzip to `extensions/` |
| [UsbNetLite](https://github.com/notmarek/kindle-usbnetlite) | SSH over USB. Unblocks the `scp` push script instead of pulling one book at a time. | Manual |

### Worth considering

| Tool | Verdict |
|---|---|
| [Kreate](https://github.com/Foskya/Kreate) | Drawing app. The Scribe has the best stylus of any Kindle, so this is the one "fun" tool that actually suits the hardware. ⚠️ Won't replace stock handwriting for the notes pipeline. |
| [Textadept](https://github.com/kbarni/textadept-kindle) | Real text editor, Bluetooth keyboard support. Interesting as a distraction-free writing device — though notes belong in the Obsidian vault, not stranded on the Kindle. |
| [RAnki](https://github.com/crazy-electron/ranki) / [KAnki](https://github.com/crizmo/KAnki) | Flashcards. RAnki uses the real Anki backend and **syncs**, so it's the one to pick if you want this at all. KAnki is `;kpm install kanki`. |
| [ScreenControl](https://kindlemodshelf.me/screencontrol.html) | Mirrors the screen over the network with input. Genuinely useful for demoing or debugging without hovering over the device. |
| [Alpine](https://github.com/schuhumi/alpine_kindle) | Full Linux on the Kindle. A project in itself, not a tool. |

### Blocked or not applicable here

| Tool | Why not |
|---|---|
| [LARK](https://github.com/kbarni/LARKPlayer) 🔴 | Firmware **<5.19** only; this Scribe is 5.19.6. Also no read-along and no streaming — see the audiobooks section below. |
| [KinAMP](https://github.com/kbarni/KinAMP) | Bluetooth music player by the same author, so expect the same firmware ceiling. You carry a phone. |
| [SOX Media Player](https://www.mobileread.com/forums/showthread.php?t=368945) | Bluetooth audio + internet radio. Same reasoning. |
| [Disable ADs](https://scriptlets.notmarek.com/scriptlets/disable_ads.sh) | No ad-supported Scribe variant exists. |
| [Android on Kindles](https://github.com/Ooonana/Guide-to-installing-android-on-kindle) | ❌ Would destroy the stock handwriting stack the notes pipeline depends on. Not on this device. |
| [KindleForge](https://github.com/KindleTweaks/KindleForge) | Targets other jailbreaks, and in maintenance mode pending a KPM rewrite. |

### Games — harmless, unrelated

[KWordle](https://github.com/crizmo/KWordle) ·
[IllusionChess](https://github.com/penguins184/IllusionChess) ·
[Gnome Chess & Minesweeper](https://github.com/crazy-electron/GnomeGames4Kindle)
(`;kpm install gnomegames`) ·
[Gambatte-K2](https://github.com/crazy-electron/gambatte-k2) (Game Boy emulator) ·
[Crossword](https://github.com/roygbyte/crossword.koplugin) (a KOReader plugin) ·
[Tetris](https://kindlemodshelf.me/tetris.html) ·
[KindleKraft](https://github.com/penguins184/KindleKraft) /
[KindleCraft](https://github.com/gingrspacecadet/bareiron) (Minecraft servers) ·
[KShips](https://github.com/LOT-Projects/KShips) ·
[KPomo](https://github.com/crizmo/KPomo) (Pomodoro timer)

A 10.2" e-ink Game Boy emulator is a funny thing to own. None of it affects the
reading or notes setup.

### Where to look when this list goes stale

- [KindleModding Wiki](https://kindlemodding.org/) — the authoritative guide
- [KindleModShelf](https://kindlemodshelf.me/) — catalog with per-project pages
- [Penguins' Mesquite Wiki](https://github.com/penguins184/Penguins-Kindle-Wiki)
- [KindleModding Discord](https://discord.kindlemodding.org)

⚠️ **Check firmware compatibility before installing anything.** This Scribe is on
**5.19.6**, which is newer than several projects support — LARK is the worked
example. A tool that assumes an older firmware can fail quietly or misbehave
rather than refusing to start.

---

## Read-aloud with word highlighting — this exists, and it isn't LARK

**LARK cannot do this.** It plays pre-recorded MP3/M4B audiobook *files*. It has
no connection to whatever book is open, no text synchronisation and no
highlighting — and it is blocked on 5.19.6 anyway.

What does do it: **[audiobook.koplugin](https://github.com/stradichenko/audiobook.koplugin)**,
a KOReader plugin providing *"text-to-speech with synchronized word
highlighting, automatic page turns, and Bluetooth audio support."*

Open a book in KOReader, start it, and it reads aloud while highlighting each
word and turning pages by itself — the experience you were describing.

- **TTS engines:** espeak-ng (light), **Piper** (neural, far more natural),
  sanoTTS
- **Fully offline** — no network needed for synthesis; Piper voice models are
  downloaded once from HuggingFace
- **Bluetooth**: device scanning and pairing, plus headset media-button control
- **Install:** download the release zip, copy the `audiobook.koplugin` folder
  into `koreader/plugins/`

### How it differs from Whispersync

| | Amazon Immersion Reading | audiobook.koplugin |
|---|---|---|
| Voice | Human narrator (Audible) | Synthesised (Piper is good, not human) |
| Needs | Matched Kindle + Audible editions, bought | Any book you can open |
| Highlighting | ✅ | ✅ |
| Works with your own EPUBs | ❌ | ✅ |

Amazon's **VoiceView** screen reader is also on the device and reads aloud over
Bluetooth, but it is an accessibility tool narrating the whole interface rather
than a reading companion. The plugin is the better fit.

---

## Install walkthrough, in order

### Step 1 — KPM packages

Search bar, one at a time. If a scriptlet doesn't respond, do Step 2 first and
use `kpm -S <name>` in the terminal instead.

```
;kpm update
;kpm install kindlefetch
```

Optional extras: `;kpm install hyprpad`, `;kpm install gnomegames`,
`;kpm install kwordle`. Skip `hello`. Leave `make` and `musl` for when a package
asks for them. Hold off on `blockamazon` until you've read the warning above.

### Step 2 — kTerm

Not a KPM package. [Grab the release](https://github.com/bfabiszewski/kterm),
unzip, and copy the extension folder into `extensions/` at the Kindle's storage
root. Launch it from KUAL or its scriptlet.

Worth doing early: it is how you diagnose anything that goes wrong on-device,
and it's the fallback whenever the `;kpm` search-bar form misbehaves.

### Step 3 — KindleFetch, the good version

The KPM package installs the CLI. The **KOReader plugin** is nicer, because
search and download happen inside the reader you already live in:

1. Download the release from
   [william-spongberg/KindleFetch.koplugin](https://github.com/william-spongberg/KindleFetch.koplugin)
2. Copy the `KindleFetch.koplugin` folder into `koreader/plugins/`
3. Restart KOReader — it appears in the ☰ menu

Also covers Library Genesis.

### Step 4 — Read-aloud plugin

Same pattern: copy `audiobook.koplugin` into `koreader/plugins/`, restart
KOReader. Pick **Piper** for voice quality; it downloads a voice model once.

### Step 5 — Custom screensavers

See the lockscreens section above — `;kpm add-repo …` then
`;kpm install custom-screensaver`, PNGs into `/screensavers/`.

### Step 6 — HotfixUpdater

[Release](https://github.com/KindleTweaks/HotfixUpdater) → unzip → copy to the
Kindle root as its README directs. Keeps OTA blocking current.

### Step 7 — UsbNetLite, when you want it

[notmarek/kindle-usbnetlite](https://github.com/notmarek/kindle-usbnetlite).
SSH over USB, for the bulk push script. OPDS already covers day-to-day.

### Copying files with no computer

Steps 2–4 need files placed into folders. Options without plugging in:

- **KindleFetch's own downloader** once it's running
- **kTerm + `curl`** — `cd /mnt/us/koreader/plugins && curl -LO <release-url>`
  then `unzip`. This is the main reason to install kTerm early.
- Otherwise, plug into a computer once and do Steps 2–4 together

---

## Recovery

The jailbreak is **reversible**: `renametobin` *Restore* → factory reset →
allow the firmware update. Worth knowing for a warranty claim — EU statutory
warranty is **2 years**, to roughly October 2027.

⚠️ Never take a firmware update while jailbroken unless you intend to lose it.

---

## Setup checklist

- [x] ~~Jailbreak (Vera, firmware 5.19.6)~~ — 2026-09-20
- [x] ~~`;kpm install koreader`~~
- [x] ~~Add the OPDS catalog pointing at Calibre-Web~~
- [ ] Set a HOME directory in KOReader + hide unsupported files
- [ ] Verify OTA blocked ("Check OTA Status" scriptlet)
- [ ] kTerm — do this early, it's how you fix things on-device
- [ ] KindleFetch — the KOReader plugin version
- [ ] `audiobook.koplugin` — read-aloud with word highlighting
- [ ] Custom screensavers + PNGs in `/screensavers/`
- [ ] HotfixUpdater
- [ ] UsbNetLite (optional — enables the push script)
- [ ] Check for stray `.bin` files in the USB root, next time you connect
- [ ] Confirm stock handwriting + *Share → Searchable PDF* still works
