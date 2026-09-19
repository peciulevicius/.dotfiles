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

### Sync — self-hosted, no subscriptions, no Apple dependency

**Constraint: no monthly subscriptions, and nothing that ties the vault to the
Apple ecosystem** — the NAS and Mac mini exist precisely to avoid both, and a
future GrapheneOS phone must work too. That rules out iCloud *and* Obsidian Sync.

| Option | Verdict |
|---|---|
| **Self-hosted LiveSync + CouchDB** | ⭐ **The answer.** Community plugin, works on **iOS, Android, macOS, Windows**, real-time, E2E encrypted, free. CouchDB runs in Docker on the Mac mini. |
| Remotely Save → Nextcloud WebDAV or R2 | Simpler fallback. Periodic rather than real-time, but no new database to run — points at Nextcloud ✅ or R2 ✅, both already yours. |
| Syncthing ✅ | Keep for the Mac mini leg. Excellent on Android — **but iOS is the weak point** (Möbius Sync, background limits). Not the mobile answer while on iPhone. |
| ❌ iCloud | Rejected — Apple ecosystem dependency, and breaks entirely if a Pixel happens. |
| ❌ Obsidian Sync | Rejected — ~€4/mo subscription. |

**Self-hosted LiveSync is the right fit here** because the hard part — exposing
the database over HTTPS so mobile Obsidian can reach it — is already solved:
**the cloudflared tunnel is running.** It's one more container plus one more
subdomain.

- [ ] `services/couchdb/docker-compose.yml` + `.env.example`, per repo convention
- [ ] Data dir on the **internal SSD**, not the NAS — it's a database, and
      databases must not live on an SMB mount (same rule as Immich Postgres)
- [ ] Expose at `couchdb.peciulevicius.com` via the existing tunnel —
      **mobile Obsidian requires HTTPS**, plain HTTP will not work
- [ ] Put it behind Cloudflare Access, or keep it Tailscale-only
- [ ] Install the **Self-hosted LiveSync** community plugin on every device;
      enable E2E encryption and set a passphrase
- [ ] Add the CouchDB data dir to `rclone-backup.sh`
- [ ] Add a Glance tile + Uptime Kuma check

⚠️ **Do a one-way first sync.** LiveSync's initial setup asks which device is
the source of truth — get this wrong and it can overwrite a vault. Back the
vault up before the first connection.

### Search

Obsidian's built-in search covers most of it. For everything else:

```bash
rg -i "search term" ~/obsidian-vault        # terminal search across all notes
```

Later: point Odysseus's RAG at the vault — see [SELF_HOSTED_AI.md](SELF_HOSTED_AI.md).
A small local model over your own notes beats a large model that has never seen them.

### Do this, in order

- [ ] Stand up **CouchDB + Self-hosted LiveSync** (above), get the vault on the iPhone
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

### ⚠️ Gmail app passwords may not be available

`kindle_sync.py` authenticates with plain IMAP `login()`, which Gmail only
accepts with a **16-character app password** — never the account password, and
the script has no OAuth2 path.

The app-passwords page is hidden from the Security menu; go direct to
<https://myaccount.google.com/apppasswords>. If it reports the setting is
unavailable, the usual cause is **2-Step Verification being off** (app passwords
require it); Advanced Protection blocks them outright.

If they stay unavailable, the fix is to bring the email migration forward:
**Purelymail** gives a real IMAP mailbox that accepts a normal password.
Cloudflare Email Routing does **not** work for this — it forwards only, with no
mailbox to poll. Amazon sends exports to the address registered on the Amazon
account, so either change that address or forward `do-not-reply@amazon.com`
from Gmail into the new mailbox.

### Scribe export routes in 2026

- **Email** ⭐ — *Share → Quick send* to your registered address. This is what
  `kindle_sync.py` consumes, and it's the only route that stays provider-neutral.
  **Update `EMAIL_ADDRESS` / `IMAP_SERVER` in `pkm/config.py` when email moves.**
- **Google Drive / OneDrive / OneNote** — only on **2025-or-later Scribe
  models**, and all three are exactly the services being left. Ignore.

So yes: **email remains the only sensible route**, and that's a feature here, not
a limitation — it's why the script is provider-agnostic.

### Making meeting notes searchable — the pipeline already does this

This is the actual requirement: handwrite in a meeting, **find it later**.

**That is exactly what `kindle_sync.py` was built for, and it already works:**

1. Scribe → **Share → Searchable PDF**. Amazon runs **handwriting OCR** and
   produces a real text layer alongside the PDF.
2. The email lands, the hourly cron picks it up, the script pulls **both** the
   `.txt` and the `.pdf`.
3. Both are filed into `📥 Imports/YYYY-MM-DD_HH-MM_name.md` in the vault.

From there the handwriting is **plain searchable text**:

```bash
rg -i "that thing from the meeting" ~/obsidian-vault
```

…plus Obsidian's own search, and later Odysseus's RAG over the whole vault.

**So the searchability problem is already solved — it's the last mile that
isn't.** Nothing is searchable while the notes sit on the Scribe. The export
has to actually happen, and the vault has to be somewhere you look.

- [ ] Verify the cron still runs (see above) — it's untested for months
- [ ] Get into the habit of **Share → Searchable PDF** at the end of each meeting
- [ ] Remember Amazon's share links expire after **7 days** — if the Mac mini is
      down for a week, those exports are lost

> Amazon's handwriting OCR is genuinely good and costs nothing. There is no
> comparable self-hosted handwriting OCR today — Tesseract is poor at cursive.
> A local vision model (Qwen-VL via Odysseus) is the plausible future
> replacement, but Amazon's is better right now. This is a reasonable place to
> keep using their processing, since the *output* lands in your vault as plain
> markdown you own.

### Note-taking on the Scribe, honestly

It's a good *handwriting* device — excellent screen, pleasant pen feel, great for
longform thinking and marking up PDFs. It is **not** a good quick-capture device:
no search inside handwriting worth relying on, slow to wake, and every export is
a manual Share action.

Treat it as the place for **deliberate, longform notes** that get exported in
batches — not for catching fleeting thoughts. The phone is for that.

### Jailbreaking the Scribe — check the Wizard, and freeze firmware now

**Device here:** Kindle Scribe 1st gen (2024), serial `GO93…`, firmware **5.19.6**.

⚠️ **Scribe support appears to be pending, not shipped.** Vera's own page says
it *"will be ported to `KS3(NFL)` and `KSC` firmwares <=5.19.6 **in the
future**"* — which reads as Scribe targets not yet being supported, with 5.19.6
as the intended ceiling.

- [ ] **Confirm with the [Jailbreaking Wizard](https://kindlemodding.org)**
      against the exact model + firmware before attempting anything. Don't infer
      support from a version range in prose — the Wizard is authoritative.

#### Whatever you decide, do this now: stop firmware updates

You are on **5.19.6**, which is the ceiling mentioned. If the Scribe auto-updates
past it, a future jailbreak may never apply to this device. Freezing costs
nothing and is reversible.

- [ ] **Fill the device's storage** — the documented trick to block auto-updates,
      and listed as a Vera prerequisite
- [ ] Or keep Wi-Fi off except when deliberately syncing
- [ ] Optionally block Amazon's update endpoints at **Pi-hole** ✅ — but note the
      router still doesn't point at Pi-hole, so this only works for devices
      configured to use it manually

#### It still won't improve note-taking

Worth repeating, because it's the actual goal here: jailbreaking gets you
**KOReader** — better reading, more formats, no Amazon lock-in. The pen,
notebooks and handwriting OCR are **Amazon's software**, and KOReader does not
replace them. Jailbreaking is a *reading* upgrade, not a *notes* upgrade.

The good news: it's additive. A jailbroken Scribe keeps the stock notebook
features, so the existing export pipeline keeps working.

### Storyteller doesn't need a jailbreak

Worth correcting: **Storyteller has native iOS and Android apps** — it is not
KOReader-only. You'd read/listen on your phone, not the Scribe. The Scribe
couldn't do synced narration anyway (no audio hardware, and immersion reading is
app-only even on Amazon's own stack).
