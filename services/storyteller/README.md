# Storyteller — self-hosted Whispersync

Takes an **ebook** and its **audiobook**, transcribes the audio, force-aligns it
sentence-by-sentence against the text, and outputs a single **EPUB 3 with Media
Overlays** — a book that highlights each word as the narrator speaks it and
follows along across devices.

**Port:** 8087 (8001 is Vaultwarden) · **Source:**
<https://gitlab.com/storyteller-platform/storyteller> · MIT

## Why it exists here

KOReader's `audiobook.koplugin` can play audiobooks from Audiobookshelf, but it
**cannot highlight text during real narration** — an audio file carries no map
between seconds and words. Only a book with Media Overlays can do that, and
Storyteller is what produces one.

Amazon's Whispersync solves the same problem with Audible's alignment data, on
books you bought from them. This does it for books you already own.

## ⚠️ Run it as a batch job, not a service

`restart: "no"` is deliberate. Alignment wants **~4GB of RAM**, which is most of
the Mac mini's remaining Docker headroom, on a host already swapping. It is also
transcription-heavy, so it will use the CPU hard while working.

```bash
cd ~/services/storyteller
docker compose up -d        # align a book at http://localhost:8087
docker compose down         # as soon as you're done
```

Leaving it running competes directly with Odysseus for the same headroom — see
[SELF_HOSTED_AI.md](../../docs/guides/SELF_HOSTED_AI.md).

## Setup

```bash
~/.dotfiles/services/setup-services.sh storyteller
cd ~/services/storyteller

openssl rand -hex 32        # paste into STORYTELLER_SECRET_KEY
nano .env

docker compose up -d
open http://localhost:8087
```

## Importing from disk, not the browser

`./import` is bind-mounted to **`/import`** in the container, and Storyteller
can import from a server path — so a 744MB audiobook never has to go through a
browser upload.

Three rules that decide whether it works:

1. **Every book needs its own folder.** `/import/Can't Hurt Me/` holding both
   the EPUB and the M4B. Loose files at the top level are not picked up.
2. **Originals are neither copied nor moved.** Storyteller reads them where they
   are, so `./import` is the canonical location for anything queued — deleting a
   folder there removes the source.
3. **Don't overlap folders.** A top-level auto-import folder *and* a
   per-collection one covering the same path gives you duplicate books.

Configure it at **Settings → auto-import folder → `/import`**, or per-collection
if you'd rather books land in a collection than in *Uncollected*.

⚠️ This folder lives on the **internal SSD** and audiobooks are large. Clear out
books once aligned; the SSD had ~30GB free when this was written.

## Worked example — *Can't Hurt Me*

Both halves were already on the server, so this is the shape of every future
alignment.

**1. Start it and drop the files into the import folder** (done 2026-09-20):

```bash
cd ~/services/storyteller && docker compose up -d
ls "import/Can't Hurt Me/"
#   cant-hurt-me.epub   9.0M   (from Calibre, /Volumes/books)
#   cant-hurt-me.m4b    744M   (from Audiobookshelf, /Volumes/audiobooks)
```

**2. In the browser** at <http://localhost:8087>:

- Create an account on first run — it is local-only, but set a real password
- **Settings → auto-import folder → `/import`** (or set it per-collection, so
  books land in a collection instead of *Uncollected*)
- The book appears with cover, author, narrator and blurb already filled in
- ⚠️ The add-book wizard still makes you **select the EPUB** before *Next*
  becomes active. That is a picker, not an upload — the file stays in
  `/import`, and the page afterwards shows both paths plus an *Asset folder*.
- Hit **Create readaloud** to start transcription and alignment

**3. Wait — properly.** It transcribes the entire audiobook first, then aligns.

⚠️ **Docker on macOS has no GPU passthrough**, so transcription is CPU-only.
For *Can't Hurt Me* that is **13 hr 38 min of audio**, and CPU transcription
tends to run at roughly real-time or slower. Plan for this to take **many
hours** — start it before bed rather than expecting it over coffee. This is also
the step that wants ~4GB.

Worth knowing before committing to a long book: a short one proves the pipeline
end to end in a fraction of the time.

**4. Download the `readaloud` format.** Three are offered:

| Format | What it is |
|---|---|
| **`readaloud`** ⭐ | The aligned EPUB 3 with Media Overlays — **this is the output** |
| `ebook` | Your original EPUB, unchanged |
| `audiobook` | The audio, unchanged |

⚠️ **It is ~750MB.** The EPUB is assembled *on demand* and embeds the transcoded
audio — Media Overlays reference audio inside the package, so it cannot be
small. Nothing sits on disk as a finished `.epub` until you request it.

**5. Get it into Calibre — upload, don't copy.**

Dropping the file into `/Volumes/books/<Author>/` does **not** add it: Calibre
tracks books in `metadata.db`, and a file the database doesn't know about is
invisible.

Use **Calibre-Web → Upload**, which writes through the running app — the safe
way to touch a library that Calibre-Web and the Calibre content server both have
open. ⚠️ Avoid `calibredb add` against a live library for that reason.

⚠️ **Do not upload through `books.peciulevicius.com`.** Cloudflare's free plan
caps request bodies at **100MB**, so a 750MB upload fails with
*"Error: File size may be too big"* — which reads like a Calibre-Web limit but
is the tunnel rejecting it.

Go direct instead, bypassing Cloudflare entirely:

| From | URL |
|---|---|
| On the Mac mini | `http://localhost:8083` |
| Anywhere on the tailnet | `http://100.81.171.49:8083` |

Downloading the file from Storyteller is unaffected — `100.81.171.49:8087` is
also off-tunnel.

This applies to anything large: **Immich, Nextcloud and Paperless uploads over
the public hostnames hit the same 100MB ceiling.** Use the Tailscale address for
big files.

⚠️ **Do not rename it in Calibre-Web afterwards.** Renaming over SMB corrupts
the library entry — see
[HOME_SERVER_REFERENCE.md](../../docs/HOME_SERVER_REFERENCE.md). Instead:

- **Add a tag** like `read-along` (metadata only, touches no files, and shows up
  as a browsable category in KOReader's OPDS view), **or**
- **Set the title before uploading**:
  `ebook-meta "book (readaloud).epub" --title "Can't Hurt Me (read-along)"`

**You will have two entries, and that's intended:** Calibre cannot hold two
EPUBs on one record. Keep the 8.6MB original for ordinary reading and the 750MB
read-along for listening — you rarely want to pull 750MB onto the Kindle just to
read a chapter.

It then appears in the OPDS catalog like any other book, and KOReader downloads
it over Wi-Fi — no cable, no MTP.

**6. Reclaim the space, then stop it.**

A finished book leaves roughly **1.5GB** behind on the internal SSD:

```bash
du -sh ~/services/storyteller/data/assets ~/services/storyteller/import
#   772M  assets   (transcoded audio + transcriptions)
#   753M  import   (the source EPUB + M4B)
```

⚠️ **Confirm the read-along EPUB is safely in Calibre first.** Deleting the
assets means regenerating it costs another overnight run.

Delete the book in Storyteller's UI, then clear the import folder:

```bash
rm -rf ~/services/storyteller/import/"Can't Hurt Me"
cd ~/services/storyteller && docker compose down
```

The sources are still in their real homes — the EPUB in Calibre, the M4B in
Audiobookshelf on the NAS — so nothing is lost.

### Backup implication

`/Volumes/books` is synced to R2 by `rclone-backup.sh`, so a 750MB read-along
EPUB roughly **doubles** the current ~1.3GB cloud backup. That is the right
trade: R2 is cheap, and the alternative is re-running a night of CPU
transcription to get it back.

### How it actually aligned (2026-09-20)

Better than expected. From `data/assets/<book>/.storyteller/report.json`:

- **23 chapters aligned**
- **6 unaligned — all front/back matter**: the copyright page, dedication,
  table of contents, acknowledgments, about-the-author, and one empty file
- 4 audio files unaligned: the first two and last two, i.e. the publisher's
  intro and the closing credits

So **every chapter of actual book content aligned**. The warning below was more
pessimistic than reality — narrated prose tracks well even from a narrator who
ad-libs, because the ad-libs cluster in the intro/outro rather than mid-chapter.

Reading `report.json` after each book is the quickest way to judge quality
before committing the output to the library.

### ⚠️ Expect this particular book to align imperfectly

*Can't Hurt Me* is close to the worst case: Goggins talks **between** chapters,
and those "challenge" segments are not in the manuscript. Forced alignment has
no text to attach them to, so the highlight will stall or drift through them and
recover when he returns to the written text.

The chapters themselves should track well. If you want a clean first test of
whether the whole pipeline works, align a **straight-read novel** first and try
this one second — otherwise a poor result won't tell you whether the tooling is
broken or the book is simply hard.

## Storage

`./data` holds the SQLite database plus uploaded and generated files, on the
**internal SSD** — never the NAS, because SQLite over SMB corrupts.

⚠️ Audiobooks are large and the SSD had **~34GB free** when this was written.
Process one book at a time and clear finished uploads out of the web UI. If this
becomes routine, moving the *finished* EPUBs to the NAS and keeping only the
working set locally is the way to go.

## ⚠️ Narrator asides break alignment

Forced alignment matches audio to **text that exists in the book**. When a
narrator ad-libs or talks between chapters — David Goggins is the standard
example — there is no text for those words to attach to, so the highlight stalls
or drifts until the narration returns to the manuscript.

Books narrated close to the text align well. Heavily ad-libbed audiobooks are
the worst case for this technique, in Storyteller and Whispersync alike.

## On the homepage, as a link only

`home.peciulevicius.com` carries a **bookmark** for it under System, labelled
*"Storyteller (off by default)"*, pointing at `http://100.81.171.49:8087`.

Deliberately **not a monitor with a `check-url`**: the service is stopped almost
all the time, so a monitor would sit permanently red and train you to ignore
the dashboard. The repo rule is that a service missing from the homepage
effectively doesn't exist — a link satisfies that without the false alarms.

No public tunnel hostname either. Reach it on the Mac mini at `localhost:8087`,
or over Tailscale while it is up.

## Backup

Excluded from the R2 backup: it holds regenerable working files, and the audio
is bulky. The **outputs** belong in Calibre-Web, which is backed up.
