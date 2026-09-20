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
- The book appears without any uploading

**3. Wait.** It transcribes the whole audiobook, then aligns. On this hardware
expect **a long while** for a 13-hour book — leave it running and check back.
This is the step that wants ~4GB.

**4. Download the aligned EPUB 3**, then put it where the Kindle can reach it:

```bash
cp ~/Downloads/<aligned>.epub "/Volumes/books/David Goggins/"
# then in Calibre-Web, or via Calibre, refresh the library
```

It then appears in the OPDS catalog like any other book, and KOReader downloads
it over Wi-Fi — no cable, no MTP.

**5. Stop it.**

```bash
cd ~/services/storyteller && docker compose down
```

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
