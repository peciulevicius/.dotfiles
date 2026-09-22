# Books & Audio Automation

Automated ebook and audiobook acquisition: search in LazyLibrarian → click "Wanted" → downloads automatically → EPUBs land in Calibre, audiobooks land in Audiobookshelf.

## Stack

| Tool | Role |
|------|------|
| LazyLibrarian | Book/audiobook automation (search, snatch, post-process) |
| Prowlarr | Indexer manager — provides Torznab endpoints to LazyLibrarian |
| Transmission | BitTorrent download client |
| Calibre | Library manager (runs as content server on port 8081) |
| Calibre-Web | Self-hosted library server (books.peciulevicius.com) |
| Audiobookshelf | Audiobook server (listen.peciulevicius.com) |

## How It Works

```
LazyLibrarian → search Prowlarr Torznab indexers
             → snatch torrent → Transmission downloads
             → PostProcessor runs every 10 min
             → EPUB → /books/ (Calibre auto-imports via content server)
             → MP3/M4B → ~/services/audiobookshelf/data/audiobooks/ (Audiobookshelf watches this)
```

## Indexers (via Prowlarr)

LazyLibrarian connects to Prowlarr's Torznab proxy. Prowlarr must be running with these indexers:

| Prowlarr ID | Indexer | Torznab URL |
|-------------|---------|-------------|
| 2 | The Pirate Bay | `http://prowlarr:9696/2` |
| 4 | Knaben | `http://prowlarr:9696/4` |
| 5 | EBookBay | `http://prowlarr:9696/5` |
| 6 | TorrentDownload | `http://prowlarr:9696/6` |

LazyLibrarian appends `/api` to these URLs automatically.

## LazyLibrarian Config (critical settings)

**Torznab providers** — in LazyLibrarian config, each `[Torznab_N]` section needs:
```ini
[Torznab_0]
dispname = EBookBay
enabled = True          ← CRITICAL: defaults to False, must be explicit
host = http://prowlarr:9696/5
api = <prowlarr_api_key>
generalsearch = search
bookcat = 7020,8000,8010
dltypes = A,E
```

**Ebook content filter** — `reject_words` defaults to `audiobook, mp3`. This causes ebook torrents containing spam files (e.g. `free audiobook version.txt`) to be rejected. Fix:
```ini
[GENERAL]
reject_words = mp3
```

**Transmission** — configured under `[TRANSMISSION]`:
```ini
[TRANSMISSION]
transmission_host = transmission
transmission_base = /transmission/
transmission_port = 9091
transmission_user = admin
transmission_pass = <password>
```

**Calibre content server** — books are imported via the running Calibre container:
```ini
[CALIBRE]
calibre_use_server = True
calibre_server = http://calibre:8081
```

## Setting Up from Scratch

### 1. Start containers

```bash
cd ~/services/lazylibrarian && docker compose up -d
```

LazyLibrarian is on port 5299 (Tailscale-only: `http://100.81.171.49:5299`).

### 2. Add Torznab providers via web UI

Go to **Config → Providers → Torznab** and add each indexer:
- Display Name: `EBookBay` / Host: `http://prowlarr:9696/5` / API: `<prowlarr_api_key>`
- Display Name: `The Pirate Bay` / Host: `http://prowlarr:9696/2` / API: `<prowlarr_api_key>`
- Display Name: `Knaben` / Host: `http://prowlarr:9696/4` / API: `<prowlarr_api_key>`
- Display Name: `TorrentDownload` / Host: `http://prowlarr:9696/6` / API: `<prowlarr_api_key>`

Check **Enabled** on each one. Set **Download Types** to `A,E`.

Get the Prowlarr API key from `http://100.81.171.49:9696` → Settings → General → API Key.

### 3. Add Transmission

**Config → Download → Transmission:**
- Host: `transmission`
- Port: `9091`
- Base URL: `/transmission/`
- Username/Password: from `~/services/transmission/.env`

Enable **"Use for Torrents"** checkbox.

### 4. Fix reject_words

**Config → Processing → Reject Words** — remove `audiobook` from the list, keep `mp3` only.

This prevents spam files inside ebook torrents (e.g. `free audiobook version.txt`) from causing the whole download to be rejected.

### 5. Set Calibre content server

**Config → Calibre:**
- Enable **Use Calibre Content Server**
- Server URL: `http://calibre:8081`

### 6. Verify directory paths

**Config → General:**
- Ebook dir: `/books`
- Audio dir: `/audiobooks`
- Download dir: `/downloads`

These map to:
| Container path | Mac mini path |
|----------------|--------------|
| `/books` | `/Volumes/books` (shared with Calibre) |
| `/audiobooks` | `~/services/audiobookshelf/data/audiobooks/` |
| `/downloads` | `/Volumes/media/downloads` |

### 7. Add an author and search

1. Search for an author → Add to library
2. LazyLibrarian imports all their books/audio as "Skipped"
3. Click **Wanted** on a book (ebook) or audiobook → it searches and downloads automatically
4. PostProcessor runs every 10 min and moves completed files to the right place

## Day-to-Day Usage

1. Go to `http://100.81.171.49:5299`
2. Search for author → Add → find books
3. Click **Wanted** button next to any book or audiobook
4. Wait ~15 min for download + processing
5. Ebook appears in Calibre-Web / Audiobookshelf automatically

## Reading sideloaded books on the Kindle

### Page numbers vs "Location"

Tap the progress indicator at the bottom of the screen to cycle through
**Location → Page in book → Time left in chapter → Time left in book**.

But "Page in book" only appears when the file carries page-number data. Amazon
supplies that as a separate **APNX** file, generated per-title by matching a
print edition — store purchases get one, personal documents almost never do. So
for anything sideloaded, the option is usually simply absent, and no setting
brings it back.

Two ways around it:

- **Transfer over USB with Calibre instead of email.** Calibre's Kindle driver
  generates an APNX alongside the book (Preferences → Devices → your Kindle →
  page-number options: *fast*, *accurate*, or *pagebreak*). Send-to-Kindle email
  transfers no APNX, so this only works over the cable.
- **KOReader after the jailbreak** — it paginates natively and shows real page
  numbers for EPUB without needing anything from Amazon. This is already the
  plan; see the jailbreak section.

### Covers not showing for Send-to-Kindle books

Expected, and not something wrong with the library — 35 of 37 books have covers
in Calibre. Books that arrive as **personal documents** frequently render with a
generic placeholder instead of their cover art, because Amazon's conversion
pipeline treats them differently from store purchases.

Worth trying, in order:

1. **Send AZW3 rather than EPUB.** AZW3 carries the cover in a form the Kindle
   reads directly, with no conversion step to lose it. Much of the library
   already has AZW3/AZW8 alongside EPUB from the DeDRM work.
2. **Embed the cover into the file first** — in Calibre, select the book →
   *Polish books* → **Update metadata in book files**. EPUBs that merely have a
   cover in Calibre's database, rather than inside the file, lose it in transit.
3. **USB transfer**, which skips Amazon's conversion entirely.

Again, the durable answer is KOReader over the OPDS feed: it reads the EPUB as
it exists in Calibre-Web, covers and all, with Amazon out of the loop.

## Known Gotchas

### Torznab `enabled` defaults to False
**Symptom:** All searches return empty. Searches complete with "0 results" for every provider.
**Cause:** `configdefs.py` sets `ConfigBool('', "ENABLED", False)` — every Torznab section defaults to disabled.
**Fix:** Must explicitly set `enabled = True` in each `[Torznab_N]` section, or tick **Enabled** in the web UI.
**After restart:** If LazyLibrarian rewrites config and drops the `enabled` field, use the web UI to re-enable providers and save. Alternatively, run `config_update` POST via script (see `scripts/lazylibrarian-config-fix.sh` if it exists).

### EBookBay rate limiting (429)
**Symptom:** EBookBay returns `429 Too Many Requests`, gets blocked for 30 seconds.
**Impact:** Minor — other 3 indexers still search fine. EBookBay just times out.
**Fix:** No fix needed — LazyLibrarian continues with other providers.

### "audiobook" in banword list rejects ebook torrents
**Symptom:** PostProcessor log shows: `free audiobook version.txt contains audiobook. Rejecting download`.
**Cause:** Some ebook torrents (especially from TPB) contain spam files named `*audiobook*.txt`. Default `reject_words = audiobook, mp3` matches them.
**Fix:** Set `reject_words = mp3` (remove "audiobook"). Done in Config → Processing.

### Author status "Paused" blocks searching
**Symptom:** Clicking "Wanted" does nothing. No search triggered.
**Cause:** Authors can be set to "Paused" status — this blocks all processing.
**Fix:** In LazyLibrarian → Authors → find author → set Status to "Active". Or via SQLite:
```bash
sqlite3 ~/services/lazylibrarian/data/lazylibrarian.db \
  "UPDATE authors SET Status='Active' WHERE AuthorName='Author Name';"
```

### Calibre content server must be running for import
**Symptom:** PostProcessor completes but book doesn't appear in Calibre.
**Cause:** LazyLibrarian imports via `calibredb --with-library=http://calibre:8081` — needs the Calibre container running.
**Fix:** Ensure `calibre` container is up: `docker compose up -d` in `~/services/calibre/`.

### Manual Calibre import (if PostProcessor fails)
Copy file to the shared `/books` volume then import via Calibre container:
```bash
# Copy EPUB to /books volume (accessible as /Volumes/books/)
cp book.epub /Volumes/books/

# Import via calibredb inside the calibre container
docker exec calibre calibredb add /books/book.epub --with-library="http://localhost:8081"
```

## Volume Paths

| What | Container | Mac mini |
|------|-----------|---------|
| Ebooks | `/books` | `/Volumes/books` |
| Audiobooks | `/audiobooks` | `~/services/audiobookshelf/data/audiobooks` |
| Downloads | `/downloads` | `/Volumes/media/downloads` |
| LazyLibrarian config | `/config` | `~/services/lazylibrarian/data` |
| SQLite database | `/config/lazylibrarian.db` | `~/services/lazylibrarian/data/lazylibrarian.db` |

## Audiobook File Structure

Audiobookshelf expects books organised by author:
```
audiobooks/
  Pierce Brown/
    Red Rising/
      Red Rising (Unabridged) Part 1 Pierce Brown.mp3
      Red Rising (Unabridged) Part 2 Pierce Brown.mp3
```

LazyLibrarian PostProcessor creates this structure automatically using the `$Author/$Title` template.

## Device Access

| App | Platform | URL |
|-----|----------|-----|
| Audiobookshelf | iOS/Android/Web | https://listen.peciulevicius.com |
| Calibre-Web | Browser | https://books.peciulevicius.com |
| Calibre-Web OPDS | Kobo/KyBook | https://books.peciulevicius.com/opds |
| Kindle | iOS/Hardware | Send via Calibre-Web → Send to Device |

---

## Which service does what

You already have the whole chain — worth restating since it's easy to lose track:

| Need | Service | Where |
|---|---|---|
| **Find + download audiobooks** | **LazyLibrarian** | Tailscale only, :5299 |
| **Store + listen to audiobooks** | **Audiobookshelf** | listen.peciulevicius.com |
| **Find + download ebooks** | **LazyLibrarian** (same tool, both media) | :5299 |
| **Store + read ebooks** | **Calibre** → **Calibre-Web** | books.peciulevicius.com |
| Indexers / torrents | Prowlarr → Transmission | |

So: **LazyLibrarian acquires, Audiobookshelf and Calibre-Web serve.** One tool
handles both books and audiobooks — click "Wanted" and the PostProcessor routes
EPUBs into Calibre and MP3/M4B into Audiobookshelf automatically.

> **Readarr was removed on 2026-09-19.** It had 0 authors, 0 books and 0 grab
> history, and is archived upstream. LazyLibrarian is the pipeline.
>
> ⚠️ LazyLibrarian has **not actually downloaded anything either** (47 books
> known, 1 author, 0 with status Open). Prove it can fetch a book before
> assuming the acquisition half of this guide works.

---

## Getting books onto the Kindle

**They do not sync automatically today.** Two routes, and the difference matters
for this project:

### Route A — Send to Kindle (works now, no jailbreak)

Calibre-Web has a **"Send to Kindle"** button that emails a book to your
`@kindle.com` address.

- ✅ Works today, no modification to the device
- ❌ **Every book passes through Amazon**, gets converted server-side, and lands
  in your Amazon library
- ❌ Manual, one click per book — not real sync
- ❌ Requires the sending address be whitelisted in your Amazon account

### Route B — KOReader + OPDS (needs jailbreak) ⭐

Calibre-Web exposes an **OPDS feed**. KOReader can browse and download from it
directly over Wi-Fi.

- ✅ **Zero Amazon involvement** — straight from `books.peciulevicius.com`
- ✅ **Native EPUB**, no conversion
- ✅ Browse your whole library from the device
- ❌ Requires jailbreaking

**Given the goal is owning your own things, Route B is the one that matches the
project.** Route A works fine in the meantime.

### Does the Kindle support EPUB? No — and this is the crux

| | Native formats |
|---|---|
| **Stock Kindle** | AZW3, KFX, MOBI (legacy), PDF, TXT — **no EPUB** |
| **KOReader** | EPUB, PDF, DjVu, FB2, CBZ, MOBI, and more |

Send to Kindle *accepts* EPUB, but **Amazon converts it** on their servers.
Since LazyLibrarian delivers EPUBs into Calibre, a stock Kindle means every book
you download gets round-tripped through Amazon before you can read it.
**KOReader reads them as-is.** That is the single strongest argument for the
jailbreak.

---

## Will books transfer automatically? No — OPDS is *pull*

Worth being precise, because "automatic" is doing a lot of work in that question.

**KOReader + OPDS is pull, not push.** You open KOReader → OPDS catalogue →
tap a book → it downloads. About ten seconds, and you browse your whole library
from the device — but **nothing arrives on its own** when LazyLibrarian finishes
a download.

| Route | Automatic? |
|---|---|
| KOReader + OPDS | ❌ Pull — you tap to download, but the whole library is browsable |
| Calibre-Web "Send to Kindle" | ⚠️ Push, but **one manual click per book** and Amazon converts it |
| Custom SSH push script | ✅ Possible — see below |

### If you want it genuinely automatic

A jailbroken Kindle is a Linux box, and **SSH can be enabled over Wi-Fi**. So a
script on the Mac mini could push new EPUBs to the device whenever it's on the
network — a cron job watching the Calibre library and `scp`-ing anything new to
KOReader's books folder.

That's a real option for this setup, but it's a **custom build**, not something
that ships. Honestly: opening KOReader and tapping a book takes ten seconds, and
you rarely start more than one book at a time. **Start with OPDS.** Build the
push script later only if the friction actually bothers you.

- [ ] Use OPDS first and see whether automation is even wanted
- [ ] Optional later: `scripts/kindle/push-books.sh` — watch Calibre, `scp`
      new EPUBs when the Scribe is reachable

---

## Jailbreak plan

**Yes, do it.** It's what connects your self-hosted library to the device
without Amazon in the middle.

### Warranty: it's 2 years in the EU, not 1 — and the jailbreak is reversible

Correcting the earlier note. Amazon's **1-year manufacturer warranty is a
*commercial* guarantee**, and under EU law it runs **alongside**, not instead
of, the mandatory **2-year statutory guarantee** from the seller. Bought in
Lithuania and registered 2025-10-08, statutory cover runs to roughly
**October 2027**.

But that matters less than it sounds, for two reasons:

1. **The jailbreak is reversible.** The documented un-jailbreak is: `renametobin`
   → *Restore* (re-enables updates) → factory reset → install current firmware.
   The device is stock again. If you ever needed a warranty claim, you'd restore
   first.
2. After the first year, the burden of proof shifts to the consumer in most
   member states, so claims get harder regardless — and the statutory guarantee
   only covers **defects present at delivery**, never damage you cause.

**So warranty is not the real blocker. Software availability is.**
Vera's Scribe support still reads as *pending* — that's what you're actually
waiting for, and it has no fixed date.

### ✅ Jailbroken 2026-09-20 with Vera

Scribe support landed sooner than this guide predicted — it was written while
Vera's Scribe port read as *pending*. The device is jailbroken and `;kpm` is
available. Everything below is now live work, not a waiting game.

**Housekeeping first** (from the KindleModding wiki's post-jailbreak page):

- [ ] Delete any leftover `.bin` update files from the Kindle's root, plus the
      jailbreak's filler files — a stray `.bin` can undo the jailbreak
- [ ] Confirm OTA is blocked with the **"Check OTA Status"** scriptlet. Modern
      `hdnext`-stack jailbreaks block updates automatically, but verify rather
      than assume — then normal Wi-Fi use is fine, and Wi-Fi is *required* for
      the notes pipeline.

---

## What to install after the jailbreak

📘 **Step-by-step setup with screenshots-level detail:
[KINDLE_SETUP.md](KINDLE_SETUP.md)** — written to be followable by anyone, not
just on this hardware. The summary below is the *what and why*; that guide is
the *how*.

`;kpm` is the package manager. Directory of what exists:
[KindleTweaks/Awesome-Kindle](https://github.com/KindleTweaks/Awesome-Kindle).

### 1. KOReader — the entire point of doing this

```
;kpm install koreader
```

Then point it at Calibre-Web's OPDS feed:
`https://books.peciulevicius.com/opds`

Verified 2026-09-20: that endpoint answers with **HTTP Basic auth**
(`WWW-Authenticate: Basic`), which KOReader's OPDS client speaks natively, and it
is deliberately **not** behind Cloudflare Access — an Access challenge would
block the reader exactly as it blocks the Obsidian LiveSync plugin. Use the
Calibre-Web login.

This is what removes Amazon from the loop: KOReader reads the EPUB as it exists
in Calibre-Web, and it paginates natively so real page numbers work — see the
sideloading section above.

### 2. UsbNetLite — SSH over USB

```
;kpm install usbnetlite
```

Worth it because it unblocks the push script this guide has listed as
"possible later" all along: with SSH on the device, new EPUBs can be `scp`'d
straight across instead of pulled one at a time through OPDS. OPDS first, since
it needs nothing; this is the upgrade path.

### 3. Custom screensavers / lockscreens

```
;kpm add-repo https://kpm.andrecheng.com/kpm.json
;kpm list-repo
;kpm update
;kpm install custom-screensaver
```

Drop **PNG** files into `/screensavers/` on the Kindle's storage; any filename
works, images are scaled automatically, and they rotate alphabetically. It needs
neither KOReader nor KUAL.

⚠️ **Tested by its author on Kindle 12th gen, Paperwhite 5 and Paperwhite 6
(firmware 5.18.6–5.19.6) — not the Scribe.** The firmware matches, but the
Scribe's panel is 10.2" rather than ~6–7", so scaling is the thing to watch. If
it misbehaves, KOReader's own sleep screen is the fallback: **gear → Screen →
Sleep screen → Wallpaper**, pointed at a folder of images.

### 4. HotfixUpdater

Keeps the OTA-blocking hotfixes current as Amazon ships new firmware. Cheap
insurance for a device that stays on Wi-Fi.

### Also available, with an opinion

| Tool | Verdict |
|---|---|
| **kTerm** | An e-ink terminal. Genuinely useful when something breaks on-device. |
| **LARK** | 🔴 **Blocked** — the project supports *firmware <5.19* and the Scribe is on 5.19.6. Also no read-along/Whispersync and no streaming, so it would not replace Audiobookshelf. See [KINDLE_SETUP.md](KINDLE_SETUP.md#audiobooks-lark-doesnt-fit-this-device-yet). |
| **KindleFetch** | ⭐ Worth having — grabs a book from Anna's Archive with no computer nearby. A shortcut alongside the LazyLibrarian → Calibre-Web library, not a replacement for it. |
| **Disable ADs** | Not applicable — the Scribe has no ad-supported variant. |
| **Android on Kindles** | Not for the Scribe, and it would destroy the handwriting stack. No. |
| Games, KAnki, Kreate, Textadept | Fun, unrelated to this project. |

⚠️ **Do not replace the stock reader for handwriting.** KOReader's Scribe stylus
support was merged and then reverted as unstable. The jailbreak is *additive*:
KOReader for reading EPUBs, stock Kindle software for notes and the Searchable
PDF export that feeds `kindle_sync.py`.

## Can you keep Wi-Fi on afterwards? Yes

This is the question that trips people up, and the answer is reassuring.

**Firmware updates do remove the jailbreak** — so an unguarded Kindle on Wi-Fi
will eventually undo itself. But **the jailbreak toolchain includes an update
blocker**: `renametobin` disables automatic updates (its *Restore* option is
what re-enables them). With that in place, **normal Wi-Fi use is fine.**

- [ ] After jailbreaking, confirm updates are blocked using the
      **"Check OTA Status"** scriptlet from Marek's collection
- [ ] Only then resume normal Wi-Fi use

> The "forget all networks, enable Airplane mode" advice you'll see applies
> **before and during** jailbreaking — it stops the device updating itself out
> of a supported firmware while you're preparing. It is not the permanent state.

**And yes, you need Wi-Fi for notes.** The *Share → Searchable PDF* export goes
through Amazon's servers to reach your email, which is what feeds
`kindle_sync.py`. A permanently offline Scribe would kill the Obsidian pipeline —
so update blocking, not airplane mode, is the right answer.

---

## Anything else worth knowing

- ✅ **Stock features are unaffected.** The KindleModding FAQ confirms
  jailbreaking doesn't interfere with **Send to Kindle**, Libby, Readwise or
  GoodReads. Your notebooks, handwriting OCR and export pipeline all keep working.
- ⚠️ **A factory reset removes the jailbreak.** It survives reboots, not resets.
- 📦 **Keep a copy of the jailbreak files and your KOReader config** — on the NAS,
  so a re-flash is quick.
- 🔋 KOReader can use more battery than stock depending on refresh settings.
- 🔁 **Reversible** — restore, factory reset, update, and it's stock again.

---

## Note-taking after the jailbreak — keep using Amazon's

This is the part to get right, because the answer is counterintuitive.

**KOReader's stylus support is not ready.** A pull request adding Kindle Scribe
stylus events was merged in **March 2026**, proved unstable, and was **reverted**.

A third-party plugin — **`pencil-handwriting.koplugin`** — targets the
Scribe's EMR pen, and it was tried and ruled out 2026-09-22: **it isn't a
notebook app.** It only draws ink *on top of an already-open PDF or EPUB* —
there's no blank canvas, so it can't take freeform notes at all. It also has
**no sync of any kind**: getting a note out means a manual KOReader
screenshot, a drag-and-drop script, or a self-run export server — nothing
automatic. Other real limits: no per-stroke edit or recolor (erase removes
the whole stroke), no pressure sensitivity, and EPUB annotations drift out of
position after the text reflows (PDF-only is the reliable case). Install, if
you want to see it for yourself: copy the plugin folder into
`koreader/plugins/`, fully restart KOReader (plugins only load at startup),
enable per-document via the Typeset menu.

**`notebook.koplugin` (by pierspad) — checked 2026-09-22, genuinely better,
still doesn't solve sync or search.** Unlike `pencil-handwriting`, this one
*is* a real notebook: an actual blank canvas, vector strokes (clean per-stroke
erase and undo, unlike Amazon's own eraser), multiple pages with a choice of
backgrounds (blank/lined/narrow-lined/grid/dot-grid/checklist), and a gallery
of thumbnails to browse notebooks. It's also under active, Scribe-specific
development — a September 2026 performance audit rewrote its input handling
for this exact hardware and measured **up to 261× faster** input processing
and ~92–94% less redraw time. This is a serious, maintained plugin, not an
abandoned experiment.

But it still doesn't get you what you actually asked for:

- ❌ **Not infinite canvas** — fixed-size pages, same as everything else
  researched here (see the [device comparison table](#no-you-cant-wipe-the-scribe-and-put-a-different-os-on-it--settled-2026-09-22) above — only reMarkable has true infinite scroll)
- ❌ **No server sync** — the only transfer option is an optional companion
  plugin ([`localsend.koplugin`](https://github.com/kaikozlov/localsend.koplugin))
  that sends a notebook to a phone over local Wi-Fi, by hand, one at a time.
  Nothing pushes to Obsidian or anywhere automatically.
- ❌ **No search** — not mentioned anywhere in its docs; nothing indicates
  full-text or handwriting search exists.
- ⚠️ Known rough edges from its own audit: dragging still re-rasterizes the
  whole stroke per frame (can lag on complex drawings), saving very large
  notebooks is synchronous (brief hang possible), and the notebook gallery
  recomputes thumbnails on every paint rather than caching them.

**Verdict: worth trying as a nicer on-device writing experience** — vector
ink, real erase/undo, and it's specifically tuned for the Scribe's hardware —
**but it does not replace `kindle_sync.py`'s pipeline.** That pipeline
depends on Amazon's own *Share → Searchable PDF* OCR export, which this
plugin has no equivalent of. Using it means either running it *alongside*
the stock notebook (two note-taking surfaces, more to remember) or losing
the automatic OCR-into-Obsidian path entirely. Install: download the latest
release zip, extract into `koreader/plugins/` so you end up with a
`notebook.koplugin` folder, restart KOReader, find it at
**Menu → Tools → More tools → Notebook**.

Sources: [pierspad/notebook.koplugin](https://github.com/pierspad/notebook.koplugin) ·
[2026-09-14 performance audit](https://github.com/pierspad/notebook.koplugin/blob/main/docs/audits/2026-09-14-notebook.md)

**Amazon's stock note-taking is materially better:** notebooks, templates,
sticky notes in books, and — critically — **handwriting OCR** via
*Share → Searchable PDF*, which is what makes your meeting notes greppable once
`kindle_sync.py` files them into Obsidian.

### The division of labour

**Jailbreaking is additive — the stock Kindle software stays.** So run both:

| Task | Use |
|---|---|
| **Reading** your own EPUBs from Calibre-Web | **KOReader** (via OPDS) |
| **Handwriting**, meeting notes, PDF markup, OCR export | **Amazon's stock software** |

You lose nothing. The notebook pipeline into Obsidian keeps working exactly as
it does now, and you gain an Amazon-free path for everything you read.

> Revisit KOReader's stylus support in a year — if `pencil-handwriting` matures
> or the native support lands stably, the last Amazon dependency here goes away.

## No, you can't wipe the Scribe and put a different OS on it — settled 2026-09-22

Researched after watching an e-ink tablet comparison video that made the
Kindle Scribe's own note-taking look genuinely bad next to Supernote and Boox.
**No custom Linux distro or Android ROM exists for Kindle Scribe hardware.**
Boox tablets run stock Android because they use commodity Android SoCs;
Amazon's e-ink silicon and bootloader are locked down with no alternative OS
path — this isn't an open project waiting for contributors, MobileRead and XDA
both treat it as settled. The Vera jailbreak + KOReader-on-top is the ceiling
for this specific device. **Don't re-research this** — the answer won't
change without new hardware shipping.

The one real "different OS" device is different hardware entirely: the
**PocketBook InkPad One** ships Linux natively. That's a purchase, not a
software change to the Scribe.

**The honest trade-off, if note-taking quality genuinely matters more than
this project's original goal:** the video's frustration matches what's
already documented above — Amazon's notebook is fixed-page, no zoom, no
infinite canvas, and KOReader can't write on the Scribe at all. But **none of
the obvious replacements actually give you infinite canvas either** — checked
2026-09-22, don't re-research:

| Device | Canvas | Writing feel | Own-server sync |
|---|---|---|---|
| **reMarkable** | ✅ genuine infinite scroll — the only one that has it | Good | Subscription paywall for search/organize (the exact thing that started this whole comparison) |
| **Supernote Manta** | ❌ page-by-page, fixed — best writing feel of the three | Best | ✅ **WebDAV**, confirmed working against **self-hosted Nextcloud** — which is already deployed here, so this needs zero new infrastructure if bought |
| **Boox** (Note Max, Go) | 🟡 *extendable* — a larger fixed canvas, off-screen panning, not truly infinite | Weaker (runs full Android, more battery drain) | Runs Android — anything, since it's just an app |

So it's a real three-way trade, not a clear winner: true infinite canvas
means accepting reMarkable's subscription wall (the problem this whole
research started from); the best pure writing feel (Supernote) means giving
up infinite canvas entirely; Boox splits the difference with a bigger-but-
still-finite canvas and full Android flexibility at the cost of pen feel and
battery.

**A Supernote Manta is a materially better *writing* device by every account,
this repo's findings included** — but it doesn't replace what the Kindle
setup already does well — Calibre-Web + OPDS + KOReader for EPUBs,
`kindle_sync.py`'s IMAP pipeline into Obsidian — those would need re-solving
on different hardware. This is a **buy a second device** decision, not a fix
to the current one — worth making deliberately, not as a side effect of
note-taking friction on a device bought for reading.

**Not Lithuanian** — PocketBook (maker of the InkPad One) was founded in Kyiv,
Ukraine in 2007, HQ'd in Lugano, Switzerland since 2012. Swiss company with
Ukrainian roots.

---

## Kindle Scribe + Audible "Read & Listen" — what actually works

**Short answer: the Scribe cannot do true immersion reading.**

Two different features get confused:

| Feature | What it does | Works on Scribe? |
|---|---|---|
| **Read & Listen** (formerly Whispersync for Voice) | Syncs your *position* between the Kindle ebook and the Audible audiobook, so you can switch between reading and listening without losing your place | ✅ Yes (audio over Bluetooth) |
| **Immersion Reading** | Highlights each word/sentence **as the narrator reads it** | ❌ **No — app only.** Available in the Audible/Kindle apps on phone and tablet, not on e-ink devices. |

So the thing you're picturing — text highlighting along with the narration —
only happens in the phone app, never on the Scribe.

**Why it's not available on all books:** it requires Amazon to have a
Whispersync-paired ebook *and* audiobook for that title, and **you must own
both formats**. Most catalogue titles don't have the pairing, and for those that
do you're buying the book twice (the audiobook is usually discounted after
buying the ebook).

### What this means for the self-hosted stack

You're right that it won't survive the move to Calibre + Audiobookshelf — it's
an Amazon-account-tied feature that requires Amazon-purchased pairs. But it
already doesn't work well: app-only, limited catalogue, two purchases per title.
**Little is actually being given up.**

**Worth investigating: [Storyteller](https://smoores.dev/storyteller)** — an
open-source, self-hostable tool that uses forced alignment (Whisper) to sync an
audiobook to its ebook and outputs a synced EPUB3 with media overlays. That is
genuinely *immersion reading, self-hosted* — the thing the Scribe can't do —
and it would sit naturally alongside Calibre and Audiobookshelf.

- [ ] Evaluate Storyteller against a book you own in both formats
- [ ] Note it needs CPU for the alignment pass — that's a Mac mini job, and a
      candidate for the native-Whisper setup in
      [SELF_HOSTED_AI.md](SELF_HOSTED_AI.md)
