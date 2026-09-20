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
| CLI | `;kpm install kindlefetch` | Launch via kTerm or a scriptlet — **not KUAL**, which Vera does not support. [justrals/KindleFetch](https://github.com/justrals/KindleFetch) |

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

## 5. HotfixUpdater — ⚠️ not needed on Vera

Skip it. The "Universal Hotfix" belongs to the **legacy** jailbreak chain
(WinterBreak, SpringBreak, LanguageBreak, Sanctuary), where blocking OTA updates
was a separate manual step. **Vera blocks OTA by itself**, so there is no hotfix
to keep current and `HotfixUpdater` has nothing to act on.

Verify the block once with the **"Check OTA Status"** scriptlet and move on.

---

## Read-along: which books actually highlight, and which don't

`audiobook.koplugin` does two quite different things, and the difference decides
whether you get highlighting and page turns.

| Mode | Where the audio comes from | Highlights + turns pages? |
|---|---|---|
| **TTS** | Synthesised on-device from the text | ✅ **Always** |
| **Audiobook playback** | An [Audiobookshelf](https://www.audiobookshelf.org/) server | ❌ **No** — it's a player |
| **Media Overlay EPUB** | Narration embedded in the book, pre-aligned | ✅ (support is *work in progress*) |

**Why TTS always works:** the plugin generates the speech from the very words it
is highlighting, so it knows the position exactly. Nothing to align.

**Why real narration doesn't:** an Audiobookshelf audiobook is just an audio
file. Nothing in it says "this second corresponds to that word", so the plugin
plays it and the page sits still. You get a good audiobook player with your
library synced — but not read-along.

### Getting real narration to highlight: EPUB 3 Media Overlays

The standard for read-along is **EPUB 3 Media Overlays** — a SMIL map embedded
in the book pairing text fragments with audio timestamps. Amazon's Whispersync
is their proprietary equivalent, built from Audible's alignment data, which is
why it only works on matched Kindle+Audible editions you bought from them.

The plugin's README lists *"Storyteller compatibility; EPUB 3 Media Overlays
support (work in progress)"* — so this path exists but is not finished. Check
the release notes before relying on it.

### Storyteller — self-hosted Whispersync

[Storyteller](https://storyteller-platform.dev/) takes an ebook **and** its
audiobook, transcribes the audio, uses **forced alignment** to match it
sentence-by-sentence against the text, and outputs a single **EPUB 3 with Media
Overlays**. Self-hosted, Docker, and the resulting file works in any reader that
supports Media Overlays.

It fits this stack unusually well — the audiobooks are already in Audiobookshelf
and the ebooks already in Calibre-Web.

**Deployed here as `services/storyteller/`, port 8087** (8001 is Vaultwarden),
with `restart: "no"` so it never comes back on its own. Setup and usage:
[services/storyteller/README.md](https://github.com/peciulevicius/.dotfiles/blob/main/services/storyteller/README.md).

⚠️ **RAM.** Storyteller wants **~4GB**, which is roughly the entire Docker
headroom left on the Mac mini and the same budget earmarked for Odysseus — the
constraint that ruled out [Octopus Deploy](OCTOPUS_DEPLOY.md). Alignment is a
**batch job**, not a permanent service, so the realistic pattern is: bring it up,
process a book, take it down. Don't leave it running.

### ⚠️ What happens with narrator asides

This is the honest limitation of any alignment tool, including Storyteller and
Whispersync.

Forced alignment maps **audio to text that exists in the book**. When a narrator
ad-libs, chats between chapters, or adds commentary that isn't in the manuscript
— David Goggins being the obvious example — there is no text for those words to
align to. Expect the highlight to **stall or drift** during those passages and
pick up again when the narration returns to the written text.

Books where the narration follows the manuscript closely align well. Heavily
ad-libbed audiobooks are the worst case for this technology, not a bug in the
tool.

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
| **KPM** | `;kpm install <name>` in the search bar, or `kpm -S <name>` in kterm | More than the wiki's package page lists — `kterm` installs this way even though it isn't on it. **Always try KPM first.** |
| **KOReader plugin** | Unzip a `*.koplugin` folder into `koreader/plugins/` | Anything ending `.koplugin` |
| **Manual scriptlet** | Unzip somewhere under `/mnt/us`, then drop a `.sh` into `documents/` — it appears in the library as a tappable "book". ⚠️ Not `extensions/`: that is the old KUAL layout and doesn't exist on Vera. | Most of the rest |

The [KPM wiki](https://kpmwiki.vercel.app/packages) lists `blockamazon`,
`gnomegames`, `hello`, `hyprpad`, `kanki`, `kindlefetch`, `kwordle`, `make` and
`musl` — but that page is **incomplete**: `kterm` and `koreader` both install
through KPM without appearing on it. Try `;kpm install <name>` before assuming
a manual install is needed.

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
2. If it doesn't, unblock it. The upstream extension exposes unblock **through
   KUAL**, which Vera does not have — so before installing, confirm the KPM
   package offers an unblock path of its own. Worst case it is an `/etc/hosts`
   edit you can undo in kTerm:
   `cp /etc/hosts /etc/hosts.bak` first, and restore that file to reverse it.

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
| [kTerm](https://github.com/bfabiszewski/kterm) | E-ink terminal. How you install everything else without a computer. | `;kpm install kterm` — **done** |
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

Everything below is done **on the Kindle, with no computer**, using kTerm.

### Step 1 — KPM packages ✅

```
;kpm update
;kpm install kterm
;kpm install kindlefetch
```

More is in KPM than the wiki's package page lists — **kterm installs via KPM
too.** When in doubt, just try `;kpm install <name>`; if it isn't there, fall
back to a manual install.

### Step 2 — Using KindleFetch (the CLI you installed) ✅

#### ⚠️ There is no KUAL, and you should not install one

**KUAL is obsolete and does not work with Vera.** It was the old launcher for
pre-`hdnext` jailbreaks. Vera replaces it with **scriptlets** — so any
instruction that says "open KUAL" (including KindleFetch's own docs, and the KPM
wiki) predates this jailbreak. Ignore it.

A **scriptlet** is just a `.sh` file in `documents/`. It shows up in the Kindle
library looking like a book; tapping it runs the script. That is the whole
mechanism.

#### Where KPM actually puts things

Not `extensions/` — that is the **old KUAL layout** and does not exist on a Vera
install. KPM uses:

| Path | Contents |
|---|---|
| `/mnt/us/kpm/packages/` | installed packages |
| `/mnt/us/kpm/packages/bin/` | their executables |
| `/usr/local/bin/kpm` | KPM itself |
| `/etc/kpm` | configuration |

`/mnt/us/kpm/packages/bin` is added to `PATH` via `/etc/profile`, so in kTerm the
package name alone should work.

#### Launching KindleFetch

**Try this first** in kTerm:

```sh
kindlefetch
```

If the shell can't find it, look rather than guess:

```sh
ls /mnt/us/kpm/packages/
ls /mnt/us/kpm/packages/bin/
```

And if it's somewhere else entirely, search for it:

```sh
find /mnt/us -iname '*kindlefetch*' 2>/dev/null
```

Then run whatever that turns up — e.g.
`sh /mnt/us/kpm/packages/kindlefetch/run.sh`.

#### Make it tappable instead of terminal-only

Once you know the working command, wrap it in a **scriptlet** so it opens from
the library:

```sh
cat > /mnt/us/documents/KindleFetch.sh <<'EOF'
#!/bin/sh
kindlefetch
EOF
chmod +x /mnt/us/documents/KindleFetch.sh
```

Replace `kindlefetch` with the full path if the bare name didn't work.
**KindleFetch** then appears in your library next to your books — tap to launch.
Restart the device if it doesn't show up.

The same wrapper gives any KPM package a launcher.

#### Using it

Type a title, author or keyword → browse results → tap to download. Books land
in `documents/`, so they appear in both the stock library and KOReader.

**CLI vs the KOReader plugin — you can run both**, they don't conflict. The CLI
is standalone; the plugin puts the same search inside KOReader so you never
leave the reader. You have the CLI; add the plugin later only if switching apps
starts to annoy.

### Finding anything on the device

Two commands worth remembering, because upstream docs frequently describe paths
from older jailbreaks that don't exist here:

```sh
find /mnt/us -maxdepth 2 -iname '*<name>*' 2>/dev/null   # where did it install?
ls /mnt/us/kpm/packages/bin/                             # what can I run?
```

`/mnt/us/kpm/packages/bin` is on `PATH`, so anything listed there runs by name.

### Step 3 — Why on-device downloading fails, and when to stop

The Kindle's `wget` is a busybox applet with limited TLS. Against GitHub it
typically dies with:

```
wget: error getting response: Connection reset by peer
```

That is a **TLS handshake failure**, not a network or path problem, and no
amount of retrying fixes it. GitHub redirects release downloads to a CDN whose
modern TLS the applet cannot negotiate.

⚠️ There is a second reason not to fight this: **the read-aloud plugin is 232 MB
unpacked** — it bundles the Piper (123 MB) and espeak-ng (71 MB) speech engines.
That is not a comfortable download over a sleepy Kindle Wi-Fi connection even if
TLS worked.

**Use a computer for the plugins.** KPM packages still install fine on-device;
it is only direct downloads that break.

### ⚠️ Why USB does not work on macOS either

Plug a modern Kindle into a Mac and it shows:

> *"If your Kindle is not listed on your computer or you're using macOS, go to
> amazon.com/connectmykindle for additional help and macOS software support."*

Kindles from roughly 2022 onward — the **Scribe included** — present themselves
over **MTP** rather than as a USB mass-storage drive, and **macOS has no native
MTP support**. The volume never mounts, so there is nothing to drag files into.

You could install an MTP client (OpenMTP is the open-source one; Android File
Transfer is Google's and unmaintained), but there is a better route that needs
no software at all.

### Step 4 — Serve the files over the LAN instead

The Kindle can't do **HTTPS**, but plain **HTTP** is fine. So serve the files
from the Mac mini over the local network and `wget` them on the device.

#### On the Mac mini

```sh
~/.dotfiles/scripts/books/serve-to-kindle.sh
```

It serves `~/Downloads/kindle-plugins` and prints the exact `wget` line for each
file it finds, with the right LAN IP already filled in. Leave it running.

Pass a different folder or port as arguments:
`serve-to-kindle.sh ~/some/dir 9000`

#### On the Kindle, in kTerm

Type the commands it printed — roughly:

```sh
cd /mnt/us
wget -O ab.zip http://<mac-mini-ip>:8765/audiobook-koplugin-v0.2.2.zip
wget -O kf.zip http://<mac-mini-ip>:8765/kindlefetch.koplugin.zip
```

Both devices must be on the **same Wi-Fi**. Then unpack into place:

```sh
cd /mnt/us/koreader/plugins
unzip /mnt/us/ab.zip
unzip /mnt/us/kf.zip

rm /mnt/us/ab.zip /mnt/us/kf.zip
ls /mnt/us/koreader/plugins/     # expect audiobook.koplugin + kindlefetch.koplugin
```

Stop the server on the Mac with Ctrl-C when you're done.

⚠️ The read-aloud plugin is **232 MB**, so that one takes a while even over LAN.

#### Then, on the Kindle

- **Fully quit and relaunch KOReader** — not a page refresh
- **Tools → Audiobook Read-Along → Voice settings** → choose **Piper**
- KindleFetch is in the ☰ book menu

### Step 5 — Drop the broken CLI

```
;kpm uninstall kindlefetch
```

The KOReader plugin replaces it, and needs no launcher — which is what made the
CLI awkward without KUAL.

### Step 6 — Custom lockscreens

#### ⚠️ The KPM route often fails

`;kpm add-repo …` followed by `;kpm install custom-screensaver` frequently ends
in **"failed to install packages"**. Third-party repos are the least reliable
part of KPM. Don't fight it — the manual install is straightforward and needs no
KUAL, because the package ships a **scriptlet**.

Inside the zip:

```
documents/Custom Screensaver.sh          <- the launcher (a Vera scriptlet)
extensions/custom-screensaver/...        <- the code
```

That `.sh` in `documents/` is exactly Vera's launcher mechanism, so the package
works on this jailbreak even though its docs predate it.

#### Install it over the LAN

**On the Mac mini** — the file is already in `~/Downloads/kindle-plugins`:

```sh
~/.dotfiles/scripts/books/serve-to-kindle.sh
```

**On the Kindle, in kTerm:**

```sh
cd /mnt/us
wget -O ss.zip http://<mac-mini-ip>:8765/custom-screensaver-0.3.0-kindlehf.zip
unzip ss.zip
rm ss.zip
```

Unzipping at `/mnt/us` merges `documents/` and `extensions/` into the existing
folders — expected, not a mistake.

**"Custom Screensaver"** then appears in your library as a tappable entry. Open
it to toggle the screensaver on.

> There is also a `.kpkg` in the release, which KPM may be able to install from
> a local file. The zip is the route verified to contain a working scriptlet, so
> prefer it.

#### What happens when you tap it

The library entry is a **toggle**, not an app. Tapping it runs
`extensions/custom-screensaver/toggle.sh`, which switches the custom screensaver
**on or off** and then returns you to the library. There is no interface and no
picker — it either takes over the sleep screen or hands it back to Amazon.

So the sequence is: **add images first, then tap to enable.** With an empty
`/mnt/us/screensavers/` there is nothing to show, and you'll see either Amazon's
default or a blank screen. Tap it again any time to turn it off.

#### Add your images


```sh
mkdir -p /mnt/us/screensavers
```

PNGs go there — any filename, rotating alphabetically, scaled automatically.

**Where the images come from is up to you** — the package ships none. You pick
them on the Mac, where you can see them properly, and push only the ones you
want. Good sources:

| Source | Why |
|---|---|
| **Your own photos, via Immich** | `photos.peciulevicius.com` — already yours, and a favourite shot in high-contrast greyscale looks superb on e-ink |
| [Unsplash](https://unsplash.com) / [Pexels](https://pexels.com) | Free, high resolution. Search "black and white" or "minimal". |
| Book covers, maps, typography | Line art and strong shapes suit e-ink far better than busy photos |

Preview and cull in Finder first — the Kindle is the worst place to discover an
image looks wrong.

**The easy way** — one command does convert *and* serve:

```sh
~/.dotfiles/scripts/books/kindle-lockscreens.sh ~/Downloads
```

It greyscales and resizes everything it finds to 1860 × 2480, letterboxing
rather than cropping, writes them to `~/Pictures/kindle-lockscreens/` as
`lockscreen-01.png`…, then prints the `wget` lines for kTerm. Uses `sips`, built
into macOS, and handles AVIF and HEIC as well as JPEG and PNG.

⚠️ Small sources get upscaled and look soft on a 300 ppi panel — anything under
about 1200 px on its long edge is worth swapping out.

**The manual way**, if you prefer ImageMagick:

```sh
mkdir -p ~/Pictures/kindle-lockscreens
cd ~/Pictures/kindle-lockscreens
# drop your chosen JPGs/PNGs here, then:
i=1; for f in *.jpg *.jpeg *.png; do
  [ -e "$f" ] || continue
  magick "$f" -colorspace Gray -resize 1860x2480^     -gravity center -extent 1860x2480 -quality 92     "$(printf 'lockscreen-%02d.png' $i)"
  i=$((i+1))
done
rm -f *.jpg *.jpeg          # keep only the converted PNGs

~/.dotfiles/scripts/books/serve-to-kindle.sh ~/Pictures/kindle-lockscreens
```

The script detects images and prints `wget` lines pointing straight at
`/mnt/us/screensavers/`. Run those in kTerm, then tap the library entry to
enable.

**Sizing** — the Scribe's panel is **1860 × 2480 px** (10.2", 300 ppi):

```sh
magick input.jpg -colorspace Gray -resize 1860x2480^ \
  -gravity center -extent 1860x2480 -quality 92 lockscreen-01.png
```

Greyscale and high contrast: it is e-ink, and low-contrast images look muddy.

#### If it misbehaves on the Scribe

⚠️ The author tested Paperwhite 5/6 and 12th-gen, **not** the Scribe's larger
panel. Fallback is KOReader's own sleep screen, which only applies while
KOReader is running:

> gear icon → **Screen** → **Sleep screen** → **Wallpaper** → point at a folder

### Step 7 — UsbNetLite (optional)

Only worth it when tapping through OPDS one book at a time starts to grate;
it enables a bulk `scp` push from the Mac mini.
[notmarek/kindle-usbnetlite](https://github.com/notmarek/kindle-usbnetlite)

### Verify nothing broke

- [ ] Open a book from the OPDS catalog — still works
- [ ] **Stock app: write a note → Share → Searchable PDF** → confirm the email
      arrives. This is what feeds `kindle_sync.py`; check it after *every* round
      of installs.

---

## KindleFetch: "no books found"

Not your setup — it's upstream. **Anna's Archive throttles scraping behind
Cloudflare**, which breaks the plugin's search. Tracked as
[issue #24](https://github.com/william-spongberg/KindleFetch.koplugin/issues/24)
against v0.3.

Worth trying:

- Check for a release newer than v0.3
- Delete the plugin folder, reinstall, and clear KOReader's cache
- The alternative plugin [fischer-hub/annas.koplugin](https://github.com/fischer-hub/annas.koplugin)
  has the same upstream problem but is worth a look

Meanwhile the self-hosted pipeline is unaffected: **LazyLibrarian → Calibre-Web
→ OPDS** doesn't touch Anna's Archive, and the OPDS catalog in KOReader keeps
working regardless. KindleFetch was always the convenience shortcut, not the
library.

---

## Troubleshooting

### A command prints nothing at all

Usually the binary is missing rather than the command succeeding quietly —
`curl` in particular is often absent. See what you actually have:

```sh
which curl wget unzip
```

`wget` and `unzip` normally exist as part of busybox, the toolset the Kindle's
userland is already built from — **not something you install**. If a bare name
isn't found, `busybox wget …` reaches the same binary.

### `wget: error getting response: Connection reset by peer`

A **TLS failure**, not a network fault. Busybox's `wget` cannot negotiate the
TLS that GitHub's download CDN requires, so release downloads fail on-device
however many times you retry.

Use a computer for anything that has to be downloaded as a file. KPM packages
are unaffected — `;kpm install …` keeps working, because KPM handles its own
transport.

### `;kpm install X` says it worked but nothing runs

KPM installs to `/mnt/us/kpm/packages/`, with executables in
`/mnt/us/kpm/packages/bin/` (on `PATH` via `/etc/profile`). Check what actually
landed:

```sh
ls /mnt/us/kpm/packages/ /mnt/us/kpm/packages/bin/
find /mnt/us -iname '*<name>*' 2>/dev/null
```

Not every package ships something runnable by name — some are libraries
(`make`, `musl`), and some expect a launcher that only KUAL provided.

### Nothing appears in the library after adding a scriptlet

A `.sh` in `documents/` should show as a "book". If it doesn't: check
`chmod +x`, then restart the device — the library index only rescans on boot.

### Downloads fail but the device is on Wi-Fi

Kindle Wi-Fi sleeps aggressively. Wake the screen, load any page in the stock
browser to bring the radio up, then retry immediately.

### When to stop debugging and use the cable

If two attempts at an on-device download fail, plug into a computer. Every
remaining install is "unzip a folder into `koreader/plugins/`", which takes
minutes over USB and needs no working `curl`, no typed URLs and no guessing at
paths. ⚠️ Eject before unplugging.

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
- [x] ~~kTerm~~ — `;kpm install kterm`
- [x] ~~KOReader + OPDS catalog~~
- [x] ~~`audiobook.koplugin`~~ — Tools → Audiobook Read-Along, Audiobookshelf connected
- [x] ~~`kindlefetch.koplugin`~~ — installed (search broken upstream, not your setup)
- [ ] **Over the LAN** (`scripts/books/serve-to-kindle.sh` on the Mac mini, then
      `wget` in kTerm): `audiobook.koplugin` + `kindlefetch.koplugin` into
      `koreader/plugins/`. ⚠️ USB doesn't work — the
      Scribe is MTP and macOS can't mount it. HTTPS doesn't work either.
- [ ] `;kpm uninstall kindlefetch` — the CLI, superseded by the plugin
- [ ] Custom screensavers (`;kpm`, no download needed) + PNGs in `/screensavers/`
- [ ] UsbNetLite (optional — enables the push script)
- [ ] Check for stray `.bin` files in the USB root, next time you connect
- [ ] Confirm stock handwriting + *Share → Searchable PDF* still works
