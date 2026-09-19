# Notes System

Personal knowledge management with Obsidian, synced across devices with Syncthing.

## Stack

| Tool | Role |
|------|------|
| Obsidian | PKM app (desktop + mobile) |
| Syncthing | Live vault sync (Mac ↔ Mac mini ↔ iPhone) |
| Rclone → B2 | Offsite backup (nightly, via rclone-backup.sh) |
| Kindle highlights | Via Readwise or manual export |

## Vault Structure

```
~/obsidian-vault/
├── HOME.md                          ← root dashboard, open on startup
├── ⚡ Capture/
│   └── Quick Capture.md
├── 🏢 Visma/
│   ├── VFS.md
│   ├── Gweb.md
│   ├── 1on1 Justas D.md
│   ├── Young Professionals Program 25-26.md
│   └── VCDM.md
├── 🚀 Build/
│   ├── Ideas & Brainstorm.md
│   ├── SaaS Stack & Research.md
│   ├── Ventures & Business Models.md
│   └── Writing & Content.md
├── 📚 Books & Learning/
│   ├── Currently Reading.md
│   ├── Quotes & Principles.md
│   └── Book Notes/
│       └── _Book Template.md
├── 🏊 Training & Health/
│   ├── Training Log.md
│   ├── Race Planning.md
│   ├── Gear & Nutrition.md
│   └── Health & Recovery.md
├── 💰 Finance/
│   ├── Budget & Overview.md
│   └── Notes.md
├── ✈️ Travel/
│   ├── _Trip Template.md
│   └── Ideas & Wishlist.md
├── 🙋 Personal/
│   ├── Goals & Priorities.md
│   └── Weekly Reflection.md
├── 📥 Imports/
│   └── README.md
└── 📦 Archive/
    └── README.md
```

## Setup

```bash
# Create vault structure
./scripts/setup/setup-obsidian.sh

# Or with custom path
VAULT_PATH=/Volumes/SSD/obsidian-vault ./scripts/setup/setup-obsidian.sh
```

Then open Obsidian → **Open folder as vault** → select `~/obsidian-vault`.
Set HOME.md as the startup note (Settings → Files & Links → Default note).

## Syncthing Setup

Syncthing syncs the vault peer-to-peer (no cloud needed).

**Mac mini (host):**
```bash
cd ~/services/syncthing
docker compose up -d
# Open http://localhost:8384
# Add device: your MacBook's device ID
# Add folder: ~/obsidian-vault
```

**MacBook:**
```bash
brew install syncthing
syncthing  # opens at http://127.0.0.1:8384
# Add Mac mini as device
# Accept shared folder → ~/obsidian-vault
```

**iPhone:**
Install Möbius Sync (iOS), add the Mac mini as a device, accept the shared folder.

## Backup

Obsidian vault is backed up to Backblaze B2 nightly via the rclone backup script (alongside Docker configs). No git needed — Syncthing handles live sync, rclone handles offsite backup.

Excluded from backup: `.obsidian/workspace*`, `.obsidian/plugins/`, `.DS_Store`, `.stfolder`.

## Weekly Routine (10 min every Sunday)

1. Clear ⚡ Quick Capture — move items to their home, delete noise
2. Process 📥 Imports — paste TXT content into correct notes, delete raw files
3. Add one entry to 🙋 Personal/Weekly Reflection.md

## Kindle Scribe → Obsidian Routing

| Notebook name contains | Paste into |
|---|---|
| VFS / Gweb / Justas / VCDM / Young Prof | 🏢 Visma/[matching file] |
| Ideas / SaaS / Ventures / Writing | 🚀 Build/[matching file] |
| Book / Reading / Quotes | 📚 Books & Learning/[matching file] |
| Training / Swim / Bike / Run / Race | 🏊 Training & Health/[matching file] |
| Health / Recovery / Physio | 🏊 Training & Health/Health & Recovery.md |
| Budget / Finance / Money | 💰 Finance/[matching file] |
| Travel / Trip | ✈️ Travel/[trip name].md |
| Goals / Reflection / Journal | 🙋 Personal/[matching file] |
| Anything unclear / mixed | 📥 Imports/ — review manually |

## Scribe Workflow (Voice → Note)

Using Wispr Flow (installed via the macOS installer):

1. Hold Fn (or your hotkey) to dictate
2. Dictate into an Obsidian note
3. Use Claude to clean up and categorise

---

## "I don't actually use this" — fixing capture before changing tools

The vault exists, the routing rules exist, the Kindle sync exists — and it still
isn't used. Worth naming the actual problem before reaching for a different app.

**It is almost never the tool. It is capture friction.** A note system dies at
the moment capturing a thought takes more effort than not capturing it. Swapping
Obsidian for Logseq/Notion/Notesnook resets the novelty and reproduces the same
failure a month later.

### Should you just use Obsidian more? Yes — here's why it's the right base

- **Plain markdown files you own.** No export needed, no lock-in, greppable from
  the terminal, feedable to Odysseus's RAG later.
- Works offline, free for personal use, best plugin ecosystem.
- You're a developer — a folder of `.md` files is the format you'd have chosen.

The weakness is real though: **mobile capture friction and iOS sync.** Fix those
two and the tool stops being the problem.

### The architecture: one vault, one inbox, many capture routes

**Rule: capture must never require a decision.** Everything lands in one inbox
folder unsorted. Sorting happens later, or never.

| Device | Capture route | Setup |
|---|---|---|
| **iPhone** | Obsidian mobile + **Share Sheet** + a home-screen Shortcut that appends to today's daily note | ⚠️ must be ≤2 taps or it won't happen |
| **Mac** | Obsidian desktop + a global hotkey via Raycast/Alfred that appends to the inbox | |
| **Web** | ⭐ **Obsidian Web Clipper** — official browser extension, clips any page to markdown straight into the vault | Pairs with Linkwarden ✅: Linkwarden archives the *link*, the clipper captures the *content you care about* |
| **Kindle Scribe** | `pkm/kindle_sync.py` ✅ already built — hourly cron | See below |

### Sync — the part that actually breaks

| Option | Verdict |
|---|---|
| **iCloud** | ⭐ **Use this now.** Obsidian supports it natively on iOS + Mac, it's free, and you already pay for iCloud. Reliable in a way Syncthing on iOS is not. |
| **Obsidian Sync** (~€4/mo) | The thing that "just works" everywhere including Android. ⭐ **Switch to this if a Pixel happens.** |
| **Syncthing** ✅ | Free and excellent Mac↔Mac↔Android — but **iOS is the weak point**: needs Möbius Sync (paid) and iOS background limits make it unreliable. Fine for the Mac mini leg. |

> **"Doesn't iCloud sync contradict de-Googling?"** No. The files are plain
> markdown — sync is *transport*, not ownership. You can move the vault to any
> other method in an afternoon. Don't let purity block the thing that makes the
> system usable.

### Search

Obsidian's built-in search covers most of it. For everything else:

```bash
rg -i "search term" ~/obsidian-vault        # terminal search across all notes
```

Later: point Odysseus's RAG at the vault — see [SELF_HOSTED_AI.md](SELF_HOSTED_AI.md).
A small local model over your own notes beats a large model that has never seen them.

### Do this, in order

- [ ] Pick **iCloud** as the sync method, get the vault on the iPhone
- [ ] Set up **one** quick-capture Shortcut on the iPhone home screen
- [ ] Install the **Obsidian Web Clipper** in Brave
- [ ] Verify the Kindle sync is still alive (below)
- [ ] **Use it for 30 days with zero organising** — capture only, into the inbox
- [ ] Only after that, revisit folder structure

If it still hasn't stuck after 30 days of frictionless capture, that's real data:
**you may not need a PKM.** Apple Notes for fleeting thoughts plus Obsidian for
durable project notes is a legitimate end state, not a failure. Splitting by
purpose beats a "do it all" tool nobody opens.

---

## Is the Kindle sync still running?

`pkm/config.py` is gitignored and lives on the **Mac mini**, which is where the
cron runs — so it can't be checked from the MacBook. To verify:

```bash
ssh macmini
crontab -l | grep kindle          # is the hourly job still scheduled?
tail -20 ~/logs/kindle-sync.log   # when did it last run, and did it error?
ls -la ~/.dotfiles/pkm/.processed_ids
```

**It runs hourly, not daily** — deliberately, because **Amazon's share links
expire after 7 days**, so a slow poll risks losing exports.

### Scribe export routes in 2026

- **Email** ⭐ — *Share → Quick send* to your registered address. This is what
  `kindle_sync.py` consumes, and it's the only route that stays provider-neutral.
  **Update `EMAIL_ADDRESS` / `IMAP_SERVER` in `pkm/config.py` when email moves.**
- **Google Drive / OneDrive / OneNote** — only on **2025-or-later Scribe
  models**, and all three are exactly the services being left. Ignore.

So yes: **email remains the only sensible route**, and that's a feature here, not
a limitation — it's why the script is provider-agnostic.

### Note-taking on the Scribe, honestly

It's a good *handwriting* device — excellent screen, pleasant pen feel, great for
longform thinking and marking up PDFs. It is **not** a good quick-capture device:
no search inside handwriting worth relying on, slow to wake, and every export is
a manual Share action.

Treat it as the place for **deliberate, longform notes** that get exported in
batches — not for catching fleeting thoughts. The phone is for that.

### Jailbreaking the Scribe

Kindle jailbreaks are active in 2026 — **Vera** (firmware 5.17.1–5.19.6) and
**Sanctuary** (5.16.4–5.18.3, runs in the Kindle browser, no PC or cable). Once
jailbroken, `;kpm install koreader` installs KOReader.

⚠️ **Scribe-specific compatibility is not confirmed** in either project's
published range — check [kindlemodding.org](https://kindlemodding.org) against
your exact model and firmware before attempting anything.

**But it probably wouldn't help you.** Jailbreaking improves *reading* — more
formats, no Amazon lock-in, KOReader's superior typography. It does **not**
improve note-taking: the pen and notebook features are Amazon's software, and
KOReader doesn't replace them. If the goal is better notes, jailbreaking is the
wrong lever.

### Storyteller doesn't need a jailbreak

Worth correcting: **Storyteller has native iOS and Android apps** — it is not
KOReader-only. You'd read/listen on your phone, not the Scribe. The Scribe
couldn't do synced narration anyway (no audio hardware, and immersion reading is
app-only even on Amazon's own stack).
