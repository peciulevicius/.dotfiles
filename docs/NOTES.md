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

## Ollama Integration

With Ollama running locally, use the Obsidian plugin **Smart Connections** or **BMO Chatbot** to chat with your vault using a local model. No data leaves your machine.

```bash
# Start Ollama
cd ~/services/ollama
docker compose up -d

# In Obsidian: install Smart Connections → set model to Ollama → llama3.2:3b
```
