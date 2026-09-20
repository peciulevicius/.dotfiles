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

## Using it

1. Upload the **EPUB** and the **audiobook** (M4B or MP3) for the same title
2. Start the alignment job — it transcribes, then aligns. **Slow**: expect the
   better part of an hour for a long book on this hardware.
3. Download the produced EPUB 3
4. Put it in Calibre-Web so it reaches the Kindle over OPDS like anything else
5. `docker compose down`

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

## Not exposed publicly

No tunnel hostname, no Glance monitor — it is off almost all the time, so a
monitor would only generate false alarms. Reach it at `localhost:8087` on the
Mac mini, or over Tailscale at `100.81.171.49:8087` while it happens to be up.

## Backup

Excluded from the R2 backup: it holds regenerable working files, and the audio
is bulky. The **outputs** belong in Calibre-Web, which is backed up.
