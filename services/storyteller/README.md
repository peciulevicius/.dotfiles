# Storyteller

Aligns an **ebook** with its **audiobook** and produces an **EPUB 3 with Media
Overlays**: a book that highlights text as the narration plays. It is the
self-hosted equivalent of Amazon's Whispersync / Immersion Reading.

| | |
|---|---|
| Port | 8087 |
| Source | <https://gitlab.com/storyteller-platform/storyteller> (MIT) |
| Access | `http://localhost:8087` on the Mac mini, or over Tailscale while running |
| Runs | On demand (`restart: "no"`) |

## Purpose

KOReader's `audiobook.koplugin` can play Audiobookshelf audiobooks but cannot
highlight text during recorded narration: an audio file carries no mapping
between time and words. A Media Overlay EPUB contains that mapping, and
Storyteller generates it by transcription and forced alignment.

## Operating model

`restart: "no"` is deliberate. Alignment needs about **4GB of memory** (most of
the remaining Docker headroom) and saturates the CPU during transcription.
Start it for a batch and stop it afterwards; left running it competes with
Odysseus for the same memory.

```bash
cd ~/services/storyteller
docker compose up -d
# … align at http://localhost:8087 …
docker compose down
```

## Setup

```bash
~/.dotfiles/services/setup-services.sh storyteller
cd ~/services/storyteller
openssl rand -hex 32        # value for STORYTELLER_SECRET_KEY in .env
nano .env
docker compose up -d
```

On first visit, create the (local) account with a real password.

## Importing from disk

`./import` is mounted at `/import` in the container, so large audiobooks never
go through a browser upload.

1. **Each book needs its own folder** containing both the EPUB and the audio,
   for example `import/<Title>/book.epub` and `import/<Title>/book.m4b`. Loose
   files at the top level are ignored.
2. **Files are read in place**, not copied. Deleting a folder in `./import`
   removes the source Storyteller uses.
3. **Do not overlap import folders.** A global auto-import folder and a
   per-collection folder on the same path produce duplicate books.

Set the folder under **Settings → auto-import folder → `/import`**, or per
collection so books land in that collection.

`./import` is on the internal SSD; clear books out once they are aligned.

## Procedure

1. **Stage the files** in `import/<Title>/`: the EPUB from Calibre and the
   M4B from Audiobookshelf.
2. **Create the read-along** in the web UI. The book appears with its metadata
   filled in. The add-book wizard still requires selecting the EPUB before
   *Next* is enabled; this is a file picker, not an upload. Click **Create
   readaloud**.
3. **Wait.** Storyteller transcribes the whole audiobook, then aligns. Docker on
   macOS has no GPU passthrough, so transcription runs on the CPU at roughly
   real time or slower: a 13.6-hour audiobook takes many hours. Align a short
   book first to verify the pipeline.
4. **Check the report** at `data/assets/<book>/.storyteller/report.json` before
   keeping the result.
5. **Download the `readaloud` format.**

   | Format | Content |
   |---|---|
   | `readaloud` | The aligned EPUB 3 with Media Overlays (the output) |
   | `ebook` | The original EPUB |
   | `audiobook` | The original audio |

   The read-along embeds the transcoded audio, so it is large (about 750MB for
   a 13.6-hour book). It is assembled when requested.
6. **Add it to Calibre through Calibre-Web → Upload.** Copying a file into the
   library folder does not register it in `metadata.db`, and `calibredb add`
   against a library that Calibre-Web and the content server hold open is
   unsafe.
7. **Clean up** (see below) and stop the container.

### Uploading large files

Upload through the direct address, not `books.peciulevicius.com`: Cloudflare's
free plan limits request bodies to 100MB, and the failure appears as
*"File size may be too big"* from Calibre-Web.

| From | Address |
|---|---|
| The Mac mini | `http://localhost:8083` |
| The tailnet | `http://100.81.171.49:8083` |

The same limit applies to Immich, Nextcloud and Paperless uploads over the
public hostnames.

### Naming in Calibre

Calibre stores one EPUB per record, so the original and the read-along are two
entries. Keep both: the small original for reading and the read-along for
listening.

Do not rename the read-along in Calibre-Web while the library is on SMB (see
[HOME_SERVER_REFERENCE.md](../../docs/HOME_SERVER_REFERENCE.md)). Instead:

- add a tag such as `read-along` (metadata only; shown as a category in OPDS), or
- set the title before uploading:
  `ebook-meta "book (readaloud).epub" --title "<Title> (read-along)"`

The book is then available over OPDS, and KOReader downloads it over Wi-Fi.

### Cleanup

A finished book leaves about 1.5GB on the internal SSD:

```bash
du -sh ~/services/storyteller/data/assets ~/services/storyteller/import
#   ~770M  assets   (transcoded audio and transcriptions)
#   ~750M  import   (source EPUB and M4B)
```

Confirm the read-along is in Calibre first; regenerating it takes another long
run. Then delete the book in Storyteller's UI and remove its import folder:

```bash
rm -rf ~/services/storyteller/import/"<Title>"
cd ~/services/storyteller && docker compose down
```

The sources remain in Calibre and Audiobookshelf.

## Alignment quality

Forced alignment can only match audio to text that exists in the book. Narrator
asides, ad-libbed commentary and publisher intros have nothing to align to, so
the highlight pauses there and resumes when the narration returns to the text.
Books read close to the manuscript align well.

First run (2026-09-20, a 13.6-hour narrated non-fiction book with frequent
narrator asides):

- 23 chapters aligned.
- 6 sections unaligned, all front or back matter (copyright, dedication,
  contents, acknowledgements, about the author, one empty file).
- 4 audio files unaligned: the publisher intro and closing credits.

Every chapter of the book's content aligned; the asides were concentrated
outside the chapters.

## Storage and backup

- `./data` holds the SQLite database and working files on the **internal SSD**
  (SQLite must not live on SMB).
- Process one book at a time and clear finished books; disk space on the SSD
  is limited.
- `./data` is **excluded from the R2 backup**: it contains regenerable working
  files. The output lives in Calibre, which is backed up (a 750MB read-along
  noticeably increases the size of the Calibre backup; re-running alignment
  would cost far more).

## Homepage

The Glance homepage has a **bookmark** for Storyteller under System ("off by
default"), not a monitor: a monitor on a service that is stopped most of the
time would always be red. There is no public tunnel hostname.
