# Books and audiobooks

Acquisition, storage and reading of ebooks and audiobooks, including the Kindle
Scribe. LazyLibrarian acquires; Calibre-Web and Audiobookshelf serve; KOReader
reads on the Kindle without Amazon in the path.

Device setup, step by step: [KINDLE_SETUP.md](KINDLE_SETUP.md).

## Components

| Component | Role | Access |
|---|---|---|
| LazyLibrarian | Ebook and audiobook automation (search, download, post-process) | Tailscale, port 5299 |
| Prowlarr | Indexer manager; provides Torznab endpoints to LazyLibrarian | Tailscale, port 9696 |
| Transmission | Download client | Tailscale, port 9091 |
| Calibre | Library manager; content server on port 8081 used for imports | Tailscale, port 8888 (GUI) |
| Calibre-Web | Library web UI and OPDS feed | `https://books.peciulevicius.com` |
| Audiobookshelf | Audiobook server | `https://listen.peciulevicius.com` |
| Storyteller | Aligns audiobooks with ebooks into read-along EPUBs (on demand) | Port 8087 |
| KOReader | Reader on the jailbroken Kindle; reads EPUB natively over OPDS | On device |

Readarr was removed on 2026-09-19: it had no authors, books or download
history, and the project is archived upstream.

## Data flow

```
LazyLibrarian → searches Prowlarr (Torznab)
             → sends the download to Transmission
             → post-processor (every 10 min)
                 ├─ EPUB     → /books       → imported via the Calibre content server
                 └─ MP3/M4B  → /audiobooks  → picked up by Audiobookshelf
```

## Paths

| Data | Container path | Host path |
|---|---|---|
| Ebook library | `/books` | `BOOKS_DIR` in `~/services/calibre/.env` (`/Volumes/books` today; see [Library location](#library-location)) |
| Audiobooks | `/audiobooks` | `~/services/audiobookshelf/data/audiobooks` |
| Downloads | `/downloads` | `/Volumes/media/downloads` |
| LazyLibrarian config | `/config` | `~/services/lazylibrarian/data` |
| LazyLibrarian database | `/config/lazylibrarian.db` | `~/services/lazylibrarian/data/lazylibrarian.db` |

Audiobookshelf expects `Author/Title/` folders. LazyLibrarian's post-processor
creates them with the `$Author/$Title` template.

---

## LazyLibrarian setup

1. Start the container: `cd ~/services/lazylibrarian && docker compose up -d`.
2. **Config → Providers → Torznab:** add one entry per Prowlarr indexer, with
   host `http://prowlarr:9696/<indexer id>` and the Prowlarr API key
   (Prowlarr → Settings → General). Tick **Enabled** and set **Download Types**
   to `A,E`. LazyLibrarian appends `/api` itself.
3. **Config → Download → Transmission:** host `transmission`, port `9091`, base
   URL `/transmission/`, credentials from `~/services/transmission/.env`. Enable
   **Use for Torrents**.
4. **Config → Processing → Reject Words:** set to `mp3` only (see
   [Known issues](#known-issues)).
5. **Config → Calibre:** enable **Use Calibre Content Server**, URL
   `http://calibre:8081`.
6. **Config → General:** ebook dir `/books`, audio dir `/audiobooks`, download
   dir `/downloads`.

Equivalent `config.ini` sections:

```ini
[Torznab_0]
dispname = <indexer name>
enabled = True          ; defaults to False — must be set explicitly
host = http://prowlarr:9696/<indexer id>
api = <prowlarr_api_key>
generalsearch = search
bookcat = 7020,8000,8010
dltypes = A,E

[GENERAL]
reject_words = mp3

[TRANSMISSION]
transmission_host = transmission
transmission_base = /transmission/
transmission_port = 9091
transmission_user = <username>
transmission_pass = <password>

[CALIBRE]
calibre_use_server = True
calibre_server = http://calibre:8081
```

### Usage

1. Open LazyLibrarian and search for an author; add them to the library. Their
   books are imported with status *Skipped*.
2. Click **Wanted** on an ebook or audiobook. LazyLibrarian searches and starts
   the download.
3. Within about 15 minutes the post-processor imports the result into
   Calibre-Web or Audiobookshelf.

> **Note:** As of 2026-09-19 the acquisition path had not yet completed a real
> download end to end. Confirm it with one book before relying on it.

### Known issues

**Torznab providers are disabled by default.** Every search returns zero
results because `ENABLED` defaults to `False` for each `[Torznab_N]` section.
Set `enabled = True` or tick **Enabled** in the UI. If a restart rewrites the
config without the field, re-enable the providers in the UI and save.

**`reject_words` rejects valid ebooks.** The default `audiobook, mp3` matches
filler files such as `free audiobook version.txt` inside ebook downloads, and
the whole download is rejected. Set `reject_words = mp3`.

**Paused authors block searching.** Clicking **Wanted** does nothing when the
author's status is *Paused*. Set it to *Active* in the UI, or:

```bash
sqlite3 ~/services/lazylibrarian/data/lazylibrarian.db \
  "UPDATE authors SET Status='Active' WHERE AuthorName='Author Name';"
```

**Imports need the Calibre container.** LazyLibrarian imports with
`calibredb --with-library=http://calibre:8081`; if the `calibre` container is
down, processed books never appear.

**Rate-limited indexers.** An indexer returning `429 Too Many Requests` is
skipped for 30 seconds; the others continue.

**Manual import** when post-processing fails:

```bash
cp book.epub "$BOOKS_DIR/"
docker exec calibre calibredb add /books/book.epub --with-library="http://localhost:8081"
```

---

## Library location

`metadata.db` is SQLite, and SQLite locking is unreliable over SMB. Every
Calibre-Web failure so far traced back to the library being on the NAS share:
`disk I/O error` on shelves, `Device or resource busy` on renames, `.smbdelete`
duplicates, and a `database disk image is malformed` error from a stale mount.

`scripts/utils/migrate-calibre-to-ssd.sh` moves the library (about 1.1GB) to
`~/services/calibre/library` on the internal SSD and repoints `BOOKS_DIR` for
Calibre, Calibre-Web and LazyLibrarian. The backup scripts read `BOOKS_DIR`
from `~/services/calibre/.env`, so they follow the library.

> **Warning:** Do not rename books in Calibre-Web while the library is on SMB.
> See [HOME_SERVER_REFERENCE.md](../HOME_SERVER_REFERENCE.md).

---

## Getting books onto the Kindle

The stock Kindle does not read EPUB. Send-to-Kindle accepts EPUB but converts it
on Amazon's servers, and every book then lands in the Amazon library. KOReader,
installed through the jailbreak, reads EPUB directly.

| Format support | Formats |
|---|---|
| Stock Kindle | AZW3, KFX, MOBI (legacy), PDF, TXT |
| KOReader | EPUB, PDF, DjVu, FB2, CBZ, MOBI and others |

| Route | Amazon involved | Automatic |
|---|---|---|
| **KOReader + OPDS** (primary) | No | Pull: browse the library on the device and tap to download |
| Calibre-Web *Send to Kindle* | Yes (conversion, sender allow-list) | One click per book |
| SSH push script | No | Possible; not built |

### KOReader and OPDS

The OPDS feed is `https://books.peciulevicius.com/opds`. It uses HTTP Basic
authentication, which KOReader supports, with the Calibre-Web login. It is
deliberately **not** behind Cloudflare Access, whose interactive challenge would
block the reader (the same reason CouchDB is not behind it).

OPDS is pull-based: nothing arrives on the device when LazyLibrarian finishes a
download. A push script (`scp` new EPUBs over SSH when the Kindle is reachable,
enabled by UsbNetLite) is possible but not built; downloading from the OPDS
catalogue takes seconds.

### Page numbers

On the stock reader, *Page in book* only appears when the book has an APNX file
with page data. Store purchases have one; sideloaded books usually do not.

- Transferring over USB with Calibre generates an APNX (Preferences → Devices →
  Kindle → page-number options). Send-to-Kindle email does not.
- KOReader paginates EPUB natively and shows page numbers without APNX data.

### Missing covers on Send-to-Kindle books

Personal documents often show a placeholder instead of the cover.

1. Send AZW3 instead of EPUB where available; AZW3 carries the cover in a form
   the Kindle reads directly.
2. Embed the cover in the file first: Calibre → *Polish books* → **Update
   metadata in book files**.
3. Transfer over USB, which skips Amazon's conversion.

KOReader over OPDS avoids the issue entirely.

---

## Kindle jailbreak

The Kindle Scribe (firmware 5.19.6) was **jailbroken on 2026-09-20 with Vera**.
`;kpm` is the on-device package manager. Installation and configuration steps
are in [KINDLE_SETUP.md](KINDLE_SETUP.md).

- **Updates:** firmware updates remove the jailbreak. `renametobin` blocks
  automatic updates (its *Restore* option re-enables them); Vera blocks OTA
  itself, so HotfixUpdater is not required. Confirm with the *Check OTA Status*
  scriptlet.
- **Wi-Fi stays on.** The *Share → Searchable PDF* export goes through Amazon to
  email, which feeds `kindle_sync.py`. Airplane mode is only needed before and
  during the jailbreak.
- **Stock features are unaffected**: Send to Kindle, notebooks, handwriting OCR
  and the export pipeline keep working.
- **A factory reset removes the jailbreak**; reboots do not.
- **Reversible:** `renametobin` → *Restore*, factory reset, install current
  firmware.
- **Warranty:** the EU statutory two-year guarantee runs alongside Amazon's
  one-year commercial warranty. Because the jailbreak is reversible, restore the
  device to stock before any warranty claim.
- Keep copies of the jailbreak files and the KOReader configuration on the NAS.

### Packages

| Package | Purpose | Status |
|---|---|---|
| KOReader | EPUB reading over OPDS | Installed |
| UsbNetLite | SSH over USB; enables a push script | Optional |
| Custom screensaver | PNG lockscreens from `/screensavers/` | Use the zip release; the `;kpm` install fails |
| kTerm | On-device terminal | Useful for troubleshooting |
| KindleFetch (KOReader plugin) | On-device book search and download without a computer | Optional |
| audiobook.koplugin | Offline text-to-speech with word highlighting | Optional |
| LARK | Audiobook player | Not compatible — supports firmware below 5.19 only |
| Android ports | — | Not applicable; would remove the handwriting stack |

Custom screensavers were tested by their author on Kindle 12th gen and
Paperwhite 5/6 (firmware 5.18.6–5.19.6), not on the Scribe's larger panel. If
scaling is wrong, KOReader's own sleep screen (Screen → Sleep screen →
Wallpaper) is the fallback. Lockscreen images for this device are in
`wallpapers/kindle/`, synced with `scripts/kindle/sync.sh`.

### Handwriting

**Handwritten notes stay on Amazon's stock software.** KOReader's Scribe stylus
support was merged in March 2026 and reverted as unstable.

| Task | Software |
|---|---|
| Reading EPUBs from Calibre-Web | KOReader over OPDS |
| Notes, PDF markup, OCR export | Stock Kindle software |

Evaluated plugins (2026-09-22):

| Plugin | Assessment |
|---|---|
| `pencil-handwriting.koplugin` | Not a notebook: draws only over an open PDF/EPUB, no blank canvas, no sync, no pressure sensitivity; EPUB annotations drift after reflow. Not used. |
| [`notebook.koplugin`](https://github.com/pierspad/notebook.koplugin) | A real notebook: blank canvas, vector strokes with per-stroke erase and undo, page backgrounds, thumbnail gallery, and active Scribe-specific optimisation. Fixed-size pages, no server sync (only `localsend.koplugin` to a phone on the local network), no search. Suitable alongside the stock notebook, not as a replacement for the OCR export into Obsidian. |

Install either by extracting the release into `koreader/plugins/` and restarting
KOReader. `notebook.koplugin` appears under Menu → Tools → More tools →
Notebook.

### Alternative devices

**No alternative OS exists for the Kindle Scribe.** Amazon's bootloader and
e-ink platform are locked down; the Vera jailbreak with KOReader is the ceiling
for this hardware.

For better handwriting, a separate device would be needed:

| Device | Canvas | Writing feel | Sync to own server |
|---|---|---|---|
| reMarkable | Infinite scroll (the only one) | Good | Search and organisation behind a subscription |
| Supernote Manta | Fixed pages | Best | WebDAV to self-hosted Nextcloud (already running) |
| Boox Note Max / Go | Larger fixed canvas with panning | Weaker; full Android, more battery drain | Any Android app |
| PocketBook InkPad One | — | — | Ships with Linux |

A second device would not replace the reading pipeline (Calibre-Web, OPDS,
KOReader) or the `kindle_sync.py` import, which would need solving again. The
purchase decision is tracked in [HOME_SERVER_TODO.md](../HOME_SERVER_TODO.md).

---

## Read-along (self-hosted immersion reading)

Amazon offers two related features:

| Feature | Behaviour | On Kindle e-ink devices |
|---|---|---|
| Read & Listen (Whispersync for Voice) | Syncs position between ebook and audiobook | Yes, with Bluetooth audio |
| Immersion Reading | Highlights text as the narrator reads | No — phone and tablet apps only |

Both require an Amazon-paired ebook and audiobook, bought separately.

The self-hosted equivalent is running:

1. **Storyteller** (`services/storyteller/`, port 8087, started on demand)
   aligns an audiobook with its EPUB using Whisper and produces an EPUB 3 with
   Media Overlays.
2. The result is added to Calibre (for example, book 41) and served over OPDS.
3. KOReader plays the narration with word highlighting (confirmed 2026-09-21).

Known limitations:

- Playback speed control does nothing on the Kindle; the Kindle audio backends
  do not implement it. Re-encode the audiobook first
  (`ffmpeg -filter:a atempo=1.5`) and align that file.
- Storyteller needs about 4GB of memory while aligning. Stop it afterwards
  (`docker compose down`).
- Tag aligned books (for example `read-along`) in Calibre-Web rather than
  renaming them.

Details: [services/storyteller/README.md](https://github.com/peciulevicius/.dotfiles/blob/main/services/storyteller/README.md).

---

## Access

| Client | Platform | Address |
|---|---|---|
| Audiobookshelf | iOS, Android, web | `https://listen.peciulevicius.com` |
| Calibre-Web | Browser | `https://books.peciulevicius.com` |
| OPDS | KOReader and other OPDS readers | `https://books.peciulevicius.com/opds` |
| Send to Kindle | Stock Kindle | Calibre-Web → Send to Device |
