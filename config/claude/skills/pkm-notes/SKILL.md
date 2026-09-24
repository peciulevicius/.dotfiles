---
name: pkm-notes
description: Personal knowledge management — the Obsidian vault, Kindle Scribe handwritten notes flowing in via kindle_sync.py, book highlights, and the reading list. Use for capturing, triaging or finding notes, processing Kindle exports, or "what should I read next".
---

# Notes & reading (PKM)

Full decisions and history: `~/.dotfiles/docs/guides/NOTES.md` and
`~/.dotfiles/docs/guides/BOOKS.md` — read them before proposing changes.

## Standing decisions — don't relitigate

- **Obsidian stays.** The problem was diagnosed as *capture friction*, not the
  tool. Never suggest replacing Obsidian.
- **No subscriptions, no Apple lock-in.** Never propose iCloud or Obsidian
  Sync. Sync is **CouchDB + Self-hosted LiveSync** on the Mac mini (plus
  Syncthing).
- **Kindle Scribe handwriting stays on Amazon's stock notebook.** KOReader
  can't write on the Scribe reliably; `notebook.koplugin` works but has no
  sync or search, so it can't feed the pipeline. Settled 2026-09-22/24.

## The pipeline

```
Kindle Scribe notebook ──Share → Searchable PDF (OCR)──► email
      ──IMAP, hourly──► pkm/kindle_sync.py ──► ~/obsidian-vault/  ──► R2 backup
```

- `kindle_sync.py` runs hourly on the Mac mini (Amazon's share links expire
  after 7 days). Config in `pkm/config.py` — gitignored, never print it.
- It tracks messages by **Message-ID**, not IMAP sequence numbers (sequence
  numbers renumber and caused silent data loss once).
- Nothing arriving? Check in order: the cron log `~/logs/kindle-sync.log`,
  whether the export email reached the inbox, IMAP credentials (after the
  Purelymail move it points at `imap.purelymail.com`).

## Capture-first rules (the actual fix)

1. Capture must take ≤ 2 taps (iPhone Shortcut → vault inbox; Web Clipper on
   desktop). If capture is slower, fix that before anything else.
2. **30 days of capture-only** — no folders, no tags, no reorganising. An
   `Inbox/` and dated notes are enough.
3. Triage weekly, not daily.

## Weekly triage (~20 min)

1. List new notes in `Inbox/` and new Kindle exports since last week.
2. For each: keep (move to a topic note, add 1–3 links), act (turn into a TODO
   in the right place), or delete. Most things are "delete" — that's fine.
3. Kindle OCR text is imperfect — fix names/numbers only where they matter.
4. Report counts: captured / kept / actioned / deleted.

## Reading

- The system is **finish owned books before acquiring more**; a fixed
  "read next" sequence; track format per book (audio / ebook / physical).
- Books are added faster than read (often from social media recommendations)
  — acknowledge that neutrally if relevant, **never lecture** about it.
- Ebooks: Calibre-Web → OPDS → KOReader on the Scribe. Audiobooks:
  Audiobookshelf. Read-along (Whispersync-style): Storyteller, started on demand.
- "What next?" → take the next item in the fixed sequence (from memory/the
  vault's reading note), not a fresh recommendation.
