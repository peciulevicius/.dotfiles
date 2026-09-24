# Notes

Personal knowledge management with Obsidian. The vault is a folder of plain
Markdown files on the Mac mini, synced to other devices and backed up nightly.

## Components

| Component | Role |
|---|---|
| Obsidian | Editor, desktop and mobile |
| Syncthing | Vault sync between the Macs |
| CouchDB + Self-hosted LiveSync | Vault sync to mobile (server running; per-device setup pending) |
| `pkm/kindle_sync.py` | Imports Kindle Scribe notebook exports from email, hourly |
| rclone → Cloudflare R2 | Nightly offsite backup of the vault |

## Design principles

- **Capture must not require a decision.** Everything lands unsorted in one
  inbox; sorting happens later or not at all. A notes system stops being used
  when capturing a thought costs more effort than skipping it, and changing
  tools does not fix that.
- **Plain Markdown, owned locally.** Greppable from the terminal, usable as a
  retrieval corpus for the local AI workspace, no export step.
- **No subscriptions and no Apple-ecosystem dependency.** This rules out iCloud
  and Obsidian Sync; the setup must also work with a future Android phone.

---

## Vault structure

```
~/obsidian-vault/
├── HOME.md                          ← dashboard, opened on startup
├── ⚡ Capture/
│   └── Quick Capture.md
├── 🏢 Work/
│   ├── Projects.md
│   └── 1on1 Notes.md
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

Create it with:

```bash
./scripts/setup/setup-obsidian.sh
# or with a custom location
VAULT_PATH=/path/to/obsidian-vault ./scripts/setup/setup-obsidian.sh
```

Then open Obsidian → **Open folder as vault**, and set `HOME.md` as the default
note (Settings → Files & Links).

### Weekly review (about 10 minutes)

1. Empty `⚡ Capture/Quick Capture.md` into the right notes; delete noise.
2. Process `📥 Imports/`: move content into the right notes, delete raw files.
3. Add an entry to `🙋 Personal/Weekly Reflection.md`.

---

## Capture routes

| Device | Route |
|---|---|
| iPhone | Obsidian mobile and the Share Sheet, plus a home-screen Shortcut that appends to the daily note. It must take two taps or fewer. |
| Mac | Obsidian desktop, plus a global hotkey (Raycast or Alfred) that appends to the inbox. Wispr Flow for dictation. |
| Browser | **Obsidian Web Clipper** — saves page content as Markdown into the vault. Complements Linkwarden, which archives the link itself. |
| Kindle Scribe | Share → Searchable PDF by email, imported by `kindle_sync.py` (see below). |

---

## Sync

| Option | Assessment |
|---|---|
| **Self-hosted LiveSync + CouchDB** | Chosen. Real-time, end-to-end encrypted, works on iOS, Android, macOS and Windows. |
| Syncthing | Used between the Macs. Weak on iOS (background limits), so not the mobile solution. |
| Remotely Save → Nextcloud WebDAV or R2 | Fallback. Periodic rather than real-time; no extra database. |
| iCloud | Rejected: Apple dependency. |
| Obsidian Sync | Rejected: subscription. |

### CouchDB server

Running since 2026-09-19 at `https://couchdb.peciulevicius.com`; details in
[services/couchdb/README.md](https://github.com/peciulevicius/.dotfiles/blob/main/services/couchdb/README.md).

- Data on the internal SSD (databases never live on SMB).
- Exposed through the Cloudflare tunnel because mobile Obsidian requires HTTPS
  and the phone needs access outside the tailnet.
- Not behind Cloudflare Access: Access's interactive login blocks the plugin.
  CouchDB's own authentication protects it, and anonymous requests return 401.
- Excluded from the R2 backup. CouchDB is a sync transport; the vault is the
  source of truth and is backed up directly.

### Connecting devices

1. Back up the vault before the first connection (snapshots are kept in
   `~/backups/vault-snapshots/`).
2. **Start on the Mac mini**, which holds the real vault, and let the initial
   upload finish.
3. Install the **Self-hosted LiveSync** community plugin on each other device,
   with end-to-end encryption enabled and the same passphrase everywhere.

> **Warning:** LiveSync asks which side is the source of truth during setup.
> Answering with an empty device can overwrite the vault.

---

## Backup

The vault is included in the nightly R2 backup (`services/rclone/rclone-backup.sh`,
backup set 2). Excluded: `.obsidian/workspace*`, `.obsidian/plugins/`,
`.DS_Store`, `.stfolder`. The monthly restore check
(`scripts/backup/r2-verify.sh`) restores a random note to confirm the backup is
readable.

---

## Search

Obsidian's built-in search covers most needs. From a terminal:

```bash
rg -i "search term" ~/obsidian-vault
```

The vault can also be used as a retrieval corpus in the AI workspace
([SELF_HOSTED_AI.md](SELF_HOSTED_AI.md)).

---

## Kindle Scribe import

`pkm/kindle_sync.py` runs hourly on the Mac mini. It polls a mailbox over IMAP
for Kindle Scribe exports, downloads the `.txt` and `.pdf` from Amazon's share
link, and files each notebook into the vault.

1. On the Scribe: **Share → Searchable PDF**. Amazon runs handwriting OCR and
   emails a link to the registered address.
2. The hourly job downloads both the text and the PDF.
3. The note is written to `📥 Imports/YYYY-MM-DD_HH-MM_name.md`, or routed by
   notebook name (below).

The job runs hourly because **Amazon's share links expire after seven days**;
if the Mac mini is down longer than that, exports are lost.

Configuration lives in `pkm/config.py` (gitignored; template in
`pkm/config.example.py`).

### Routing by notebook name

| Notebook name contains | Destination |
|---|---|
| 1on1 / project / work | `🏢 Work/` |
| Ideas / SaaS / Ventures / Writing | `🚀 Build/` |
| Book / Reading / Quotes | `📚 Books & Learning/` |
| Training / Swim / Bike / Run / Race | `🏊 Training & Health/` |
| Health / Recovery / Physio | `🏊 Training & Health/Health & Recovery.md` |
| Budget / Finance / Money | `💰 Finance/` |
| Travel / Trip | `✈️ Travel/` |
| Goals / Reflection / Journal | `🙋 Personal/` |
| No match | `📥 Imports/` |

### Mailbox requirements

The script uses plain IMAP `login()` with no OAuth support:

- **Gmail** accepts only a 16-character app password
  (<https://myaccount.google.com/apppasswords>), which requires 2-Step
  Verification and is unavailable under Advanced Protection.
- **Purelymail** accepts the mailbox password directly.
- **Cloudflare Email Routing** does not work: it forwards only and has no
  mailbox to poll.

Amazon sends exports to the address registered on the Amazon account. After an
email migration, update `EMAIL_ADDRESS`, `EMAIL_PASSWORD` and `IMAP_SERVER` in
`pkm/config.py`, and either change the Amazon account address or forward
Amazon's mail to the new mailbox. The full cutover procedure is in
[EMAIL.md](EMAIL.md).

### Export routes

Email is the only export route that does not depend on Google or Microsoft.
Direct export to Google Drive, OneDrive and OneNote exists only on 2025 and
later Scribe models.

### Checking the job

```bash
ssh macmini
crontab -l | grep kindle          # scheduled?
tail -20 ~/logs/kindle-sync.log   # last run and errors
ls -la ~/.dotfiles/pkm/.processed_ids
```

Failures are also reported to Discord through `scripts/utils/run-with-notify.sh`.

### Handwriting OCR

Amazon's handwriting OCR is free and accurate. Self-hosted options are not yet
comparable (Tesseract handles cursive poorly); a local vision model is a
possible future replacement. The output lands in the vault as Markdown either
way.

The Scribe suits deliberate, longer notes exported in batches. It is a poor
quick-capture device: slow to wake, with a manual share step for every export.
The phone covers quick capture.

---

## Kindle reading setup

Jailbreaking, KOReader and the self-hosted reading pipeline are covered in
[BOOKS.md](BOOKS.md) and [KINDLE_SETUP.md](KINDLE_SETUP.md). The jailbreak is
additive: the stock notebook and the Searchable PDF export keep working, so
this import pipeline is unaffected.
