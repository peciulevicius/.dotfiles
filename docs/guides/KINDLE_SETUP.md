# Kindle setup (jailbroken)

Configuration of a jailbroken Kindle Scribe as a reader for a self-hosted
Calibre-Web library, with the stock handwriting features kept intact.

Written for a **Kindle Scribe on firmware 5.19.6, jailbroken with Vera on
2026-09-20**. Most steps apply to any Kindle jailbroken with an `hdnext`-based
jailbreak; device-specific caveats are noted.

Related: [BOOKS.md](BOOKS.md) (library and acquisition pipeline, design
decisions) · [NOTES.md](NOTES.md) (handwritten notes into Obsidian).

---

## Principles

1. **The jailbreak is additive.** KOReader handles reading; the stock software
   keeps handling handwriting. KOReader's Scribe stylus support was merged in
   March 2026 and reverted as unstable, and the notes pipeline
   (`pkm/kindle_sync.py`) depends on the stock *Share → Searchable PDF* export.
2. **Wi-Fi stays on.** The Searchable PDF export goes through Amazon to email.
   Updates are blocked by the jailbreak instead of by airplane mode.
3. **Check firmware compatibility before installing anything.** Several
   projects do not support 5.19.x and fail silently rather than refusing to
   start.

---

## After jailbreaking

### Confirm OTA updates are blocked

A firmware update removes the jailbreak. Vera blocks OTA updates itself (the
legacy "Universal Hotfix" / HotfixUpdater is not needed); confirm it with the
**Check OTA Status** scriptlet.

### Stray `.bin` files

The KindleModding wiki recommends removing leftover firmware images (`*.bin`)
from the root of the Kindle's USB storage, since the device may try to install
them. Check with kTerm:

```sh
ls /mnt/us/*.bin
```

KOReader's own `bin` folder is unrelated and must be left alone.

---

## How software is installed

| Mechanism | How | Used for |
|---|---|---|
| **KPM** | `;kpm install <name>` in the search bar, or `kpm -S <name>` in kTerm | Packages in the KPM repositories — try this first |
| **KOReader plugin** | Extract a `*.koplugin` folder into `koreader/plugins/`, then restart KOReader | Anything named `*.koplugin` |
| **Scriptlet** | Extract under `/mnt/us`; a `.sh` file in `documents/` appears in the library and runs when tapped | Most other tools |

### KPM

```
;kpm update                     # refresh package lists
;kpm install <package>
;kpm uninstall <package>
;kpm add-repo <url>             # add a third-party repository
;kpm list-repo
```

| Path | Contents |
|---|---|
| `/mnt/us/kpm/packages/` | Installed packages |
| `/mnt/us/kpm/packages/bin/` | Executables (on `PATH` via `/etc/profile`) |
| `/usr/local/bin/kpm` | KPM |
| `/etc/kpm` | Configuration |

The [KPM wiki package list](https://kpmwiki.vercel.app/packages) is incomplete:
`kterm` and `koreader` install through KPM without appearing on it.
Third-party repositories are the least reliable part of KPM; if an install from
one fails, use the project's zip release instead.

### No KUAL

KUAL is the launcher for pre-`hdnext` jailbreaks and does not work with Vera.
Instructions that say "open KUAL" or refer to `extensions/` as a launcher
location predate Vera. Use scriptlets instead.

Any command can be made tappable from the library with a scriptlet:

```sh
cat > /mnt/us/documents/KindleFetch.sh <<'EOF'
#!/bin/sh
kindlefetch
EOF
chmod +x /mnt/us/documents/KindleFetch.sh
```

The library only rescans on boot; restart the device if the entry does not
appear.

### Transferring files to the device

- **On-device HTTPS downloads fail.** The Kindle's `wget` is a busybox applet
  whose TLS support cannot negotiate with GitHub's download CDN; the typical
  error is `wget: error getting response: Connection reset by peer`. KPM is
  unaffected because it handles its own transport.
- **USB does not mount on macOS.** Kindles from about 2022 onward, the Scribe
  included, use MTP rather than USB mass storage, and macOS has no native MTP
  support. (OpenMTP is an open-source client if needed.)
- **Plain HTTP over the LAN works.** Serve files from the Mac mini and fetch
  them with `wget` in kTerm.

On the Mac mini:

```sh
~/.dotfiles/scripts/kindle/sync.sh --dir ~/Downloads/kindle-plugins
```

This serves the folder and prints the exact `wget` commands, with the LAN IP
filled in. Both devices must be on the same network. Stop the server with
Ctrl-C afterwards.

On the Kindle, in kTerm:

```sh
cd /mnt/us
wget -O plugin.zip http://<mac-mini-ip>:8765/<file>.zip
cd /mnt/us/koreader/plugins && unzip /mnt/us/plugin.zip && rm /mnt/us/plugin.zip
```

---

## KOReader and the OPDS library

### Install

```
;kpm install koreader
```

### Add the Calibre-Web catalogue

In KOReader: tap the top of the screen → search icon → **OPDS catalog** → **+**.

| Field | Value |
|---|---|
| Catalog name | `Calibre-Web` |
| Catalog URL | `https://books.peciulevicius.com/opds` |
| Username / Password | Calibre-Web login |

Open the catalogue, select a book, choose **EPUB**; it downloads and opens in
KOReader.

The endpoint uses HTTP Basic authentication, which KOReader supports. It must
not be placed behind Cloudflare Access: KOReader cannot complete Access's
interactive login.

| | Send to Kindle | KOReader + OPDS |
|---|---|---|
| Amazon sees the library | Yes | No |
| EPUB | Converted server-side | Read natively |
| Page numbers | Usually unavailable (no APNX) | Native pagination |
| Covers | Often a placeholder | The EPUB's own cover |

OPDS is pull-based; nothing syncs in the background.

### File browser

KOReader opens on the storage root (`/mnt/us/`), which also contains firmware,
fonts, the jailbreak's files (`libkh/`, `privesc_marker`) and KOReader itself.
Only `documents/` (books) and `screenshots/` are relevant.

1. Long-press `documents/` (or a dedicated `books/` folder) → **Set as HOME
   directory**.
2. File browser ☰ → **Settings** → turn off *Show unsupported files* (and leave
   *Show hidden files* off).
3. On the first OPDS download, choose the home folder as the destination.
4. Use **History** and **Favorites** (long-press a book → *Add to favorites*)
   rather than folder browsing.

Screenshots: tap two diagonally opposite corners at the same time.

---

## Read-aloud: audiobook.koplugin

[audiobook.koplugin](https://github.com/stradichenko/audiobook.koplugin)
provides text-to-speech with synchronised word highlighting, automatic page
turns and Bluetooth audio. It is offline; voice models are downloaded once.

| Mode | Audio source | Highlighting and page turns |
|---|---|---|
| Text-to-speech | Synthesised on device (espeak-ng, **Piper**, sanoTTS) | Yes |
| Audiobook playback | An Audiobookshelf server | No — plays audio only |
| Media Overlay EPUB | Narration embedded in the book (e.g. from Storyteller) | Yes (upstream support marked as work in progress) |

Text-to-speech always highlights because the speech is generated from the text
being highlighted. A plain audiobook file carries no mapping from audio to
words, so it plays without highlighting.

**Install:** the release unpacks to about 232MB (Piper 123MB, espeak-ng 71MB),
so transfer it over the LAN rather than on-device. Extract into
`koreader/plugins/`, restart KOReader fully, then **Tools → Audiobook
Read-Along → Voice settings → Piper**.

### Playback speed

The speed control has no effect on recorded narration on the Kindle. The
plugin's `mediaengine.lua` implements `setSpeed` for mpv, MPlayer, ffmpeg and
generic GStreamer, but not for the Kindle backends (`KINDLE_GST_PLAY`,
`KINDLE_LIPC`), and the call fails silently. Speed does work in text-to-speech
mode, where it is a synthesis parameter.

Workaround for Media Overlay books: speed up the audio before alignment, so the
aligned book plays at that speed natively.

```sh
# 1.5x with pitch preserved (atempo is limited to 2.0 per pass; chain for more)
ffmpeg -i "book.m4b" -filter:a "atempo=1.5" -vn "book-1.5x.m4b"
ffmpeg -i "book.m4b" -filter:a "atempo=2.0,atempo=1.25" -vn "book-2.5x.m4b"   # 2.5x
```

Each speed needs its own alignment run and about 750MB per resulting EPUB.
Requires `brew install ffmpeg`.

---

## Read-along with recorded narration

EPUB 3 **Media Overlays** pair text fragments with audio timestamps through an
embedded SMIL map; Amazon's Whispersync is a proprietary equivalent limited to
matched Kindle and Audible editions.

[Storyteller](https://storyteller-platform.dev/) produces Media Overlay EPUBs
from an ebook and its audiobook by transcription and forced alignment. It runs
here as `services/storyteller/` (port 8087, `restart: "no"`), and the result is
added to Calibre-Web and read over OPDS. End-to-end read-along with word
highlighting was confirmed on 2026-09-21.

- Storyteller needs about 4GB of memory. Start it for a batch, then stop it.
- Forced alignment can only match audio to text that is in the book. Narrator
  asides and ad-libbed passages have nothing to align to, so highlighting
  stalls there and resumes when the narration returns to the text.

Setup and usage: [services/storyteller/README.md](https://github.com/peciulevicius/.dotfiles/blob/main/services/storyteller/README.md).

---

## Custom lockscreens

### Install

The KPM route (`;kpm add-repo https://kpm.andrecheng.com/kpm.json`, then
`;kpm install custom-screensaver`) frequently fails with *failed to install
packages*. Install from the zip release instead; it ships a Vera-compatible
scriptlet:

```
documents/Custom Screensaver.sh          # launcher (scriptlet)
extensions/custom-screensaver/...        # code
```

Serve `custom-screensaver-0.3.0-kindlehf.zip` with `scripts/kindle/sync.sh`,
then in kTerm:

```sh
cd /mnt/us
wget -O ss.zip http://<mac-mini-ip>:8765/custom-screensaver-0.3.0-kindlehf.zip
unzip ss.zip && rm ss.zip
mkdir -p /mnt/us/screensavers
```

Unzipping at `/mnt/us` merges into the existing `documents/` and `extensions/`
folders, which is expected.

### Usage

The **Custom Screensaver** library entry is a toggle, not an app: tapping it
turns the custom sleep screen on or off and returns to the library. Add images
before enabling it. PNG files in `/mnt/us/screensavers/` are used in
alphabetical order and scaled automatically.

### Images

Lockscreen sources live in `wallpapers/kindle/` in this repository.

```sh
~/.dotfiles/scripts/kindle/sync.sh
```

The script converts each image to 1860 × 2480 greyscale (letterboxed, not
cropped), warns about sources under ~1200px, serves the files, and prints the
single kTerm command to run. **The device is mirrored to the folder**: deleting
an image from `wallpapers/kindle/` and syncing removes it from the Kindle.

Manual conversion for the Scribe's 1860 × 2480 (300 ppi) panel:

```sh
magick input.jpg -colorspace Gray -resize 1860x2480^ \
  -gravity center -extent 1860x2480 -quality 92 lockscreen-01.png
```

High-contrast images work best on e-ink.

The package was tested by its author on Kindle 12th gen and Paperwhite 5/6, not
on the Scribe. If it misbehaves, KOReader's sleep screen is the fallback
(settings → **Screen** → **Sleep screen** → **Wallpaper**), which applies only
while KOReader is running.

---

## Package reference

### KPM official repository (as of 2026-09)

| Package | Description | Recommendation |
|---|---|---|
| `kterm` | E-ink terminal | Installed; needed to install most other tools |
| `koreader` | Reader | Installed |
| `kindlefetch` | On-device book search and download (CLI) | Superseded by the KOReader plugin; uninstall |
| `blockamazon` | Blocks Amazon domains via `/etc/hosts` | Use with care — see below |
| `hyprpad` | E-ink text editor | Optional |
| `kanki` | Flashcards | Optional; RAnki syncs with Anki, KAnki does not |
| `gnomegames`, `kwordle` | Games | Optional |
| `hello` | KPM test package | Not needed |
| `make`, `musl` | Build tool and C library | Dependencies only |

### Other tools

| Tool | Assessment |
|---|---|
| [KindleFetch.koplugin](https://github.com/william-spongberg/KindleFetch.koplugin) | On-device search and download inside KOReader. Search is currently broken upstream because the source site rate-limits scraping ([issue #24](https://github.com/william-spongberg/KindleFetch.koplugin/issues/24), v0.3). A convenience only; the library remains LazyLibrarian → Calibre-Web. |
| [UsbNetLite](https://github.com/notmarek/kindle-usbnetlite) | SSH over USB; would enable a bulk `scp` push from the Mac mini. Optional. |
| [ScreenControl](https://kindlemodshelf.me/screencontrol.html) | Screen mirroring with input over the network; useful for debugging. |
| [Kreate](https://github.com/Foskya/Kreate) | Drawing app suited to the Scribe's stylus. Does not replace stock handwriting for the notes pipeline. |
| [Textadept](https://github.com/kbarni/textadept-kindle) | Text editor with Bluetooth keyboard support. |
| [RAnki](https://github.com/crazy-electron/ranki) / [KAnki](https://github.com/crizmo/KAnki) | Flashcards; RAnki syncs with Anki. |
| [Alpine](https://github.com/schuhumi/alpine_kindle) | Full Linux userland on the Kindle; a project in itself. |
| [LARK](https://github.com/kbarni/LARKPlayer) | Not compatible (see below). |
| KinAMP, SOX Media Player | Bluetooth audio players; likely the same firmware limitation as LARK. |
| Disable ADs | Not applicable; the Scribe has no ad-supported variant. |
| Android on Kindles | Not applicable; would remove the handwriting stack. |
| KindleForge | Targets other jailbreaks and is in maintenance mode pending a KPM rewrite. |

Games are listed in [Awesome-Kindle](https://github.com/KindleTweaks/Awesome-Kindle).

### `blockamazon` and the notes pipeline

`blockamazon` blocks Amazon domains in `/etc/hosts` and does not document which
ones. The *Share → Searchable PDF* export depends on Amazon's servers.

1. Back up the hosts file first: `cp /etc/hosts /etc/hosts.bak`.
2. After installing, immediately test a Searchable PDF export and confirm the
   email arrives.
3. If it does not, restore `/etc/hosts.bak`. The upstream unblock option is
   exposed through KUAL, which Vera does not have.

### LARK (audiobook player)

Evaluated 2026-09-20 and not used:

1. Supports firmware below 5.19 only; the Scribe runs 5.19.6.
2. No text/audio synchronisation or highlighting.
3. Local files only; it would not replace Audiobookshelf's streaming and
   cross-device progress.

Revisit if it gains 5.19 support. [BARKPlayer](https://github.com/Teknoist/BARKPlayer)
is an updated fork worth checking.

---

## Troubleshooting

**A command prints nothing.** The binary is usually missing. Check with
`which curl wget unzip`. `wget` and `unzip` are busybox applets; if a bare name
is not found, `busybox wget …` reaches the same binary. `curl` is often absent.

**`wget: error getting response: Connection reset by peer`.** TLS failure; see
[Transferring files to the device](#transferring-files-to-the-device).

**A KPM install reports success but nothing runs.** Check what was installed:

```sh
ls /mnt/us/kpm/packages/ /mnt/us/kpm/packages/bin/
find /mnt/us -maxdepth 2 -iname '*<name>*' 2>/dev/null
```

Some packages are libraries (`make`, `musl`), and some expect a KUAL launcher;
wrap the command in a scriptlet.

**A scriptlet does not appear in the library.** Check `chmod +x` and restart the
device.

**Downloads fail while on Wi-Fi.** The Kindle's Wi-Fi sleeps aggressively. Wake
the screen, load a page in the stock browser, and retry immediately.

**Repeated on-device download failures.** After two failed attempts, transfer
the files over the LAN (or USB from a machine with MTP support). Every plugin
install is an extraction into `koreader/plugins/`.

---

## Recovery

The jailbreak is reversible: `renametobin` → *Restore* (re-enables updates) →
factory reset → install current firmware. Restore to stock before any warranty
claim; the EU statutory two-year guarantee applies alongside Amazon's one-year
warranty.

Never install a firmware update while jailbroken unless the jailbreak is meant
to be removed.

---

## Setup status

| Item | Status |
|---|---|
| Jailbreak (Vera, 5.19.6) | Done, 2026-09-20 |
| KOReader + OPDS catalogue | Done |
| kTerm | Done |
| audiobook.koplugin (Audiobookshelf connected) | Done |
| KindleFetch.koplugin | Installed; search broken upstream |
| KOReader home directory, hide unsupported files | To do |
| OTA block confirmed (*Check OTA Status*) | To do |
| Uninstall the `kindlefetch` CLI | To do |
| Custom screensavers + images | To do |
| UsbNetLite | Optional |
| Check for stray `.bin` files | To do |
| Stock handwriting + Searchable PDF export still working | Re-check after every round of installs |
