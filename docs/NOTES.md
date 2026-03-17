# Notes System

Personal knowledge management with Obsidian, synced across devices with Syncthing.

## Stack

| Tool | Role |
|------|------|
| Obsidian | PKM app (desktop + mobile) |
| Syncthing | Vault sync (Mac ↔ Mac mini ↔ iPhone) |
| Git | Version control + GitHub backup |
| Kindle highlights | Via Readwise or manual export |

## Vault Structure (PARA)

```
~/obsidian-vault/
├── 000 Inbox/          # Quick capture, process weekly
├── 100 Projects/       # Active projects (with deadlines)
├── 200 Areas/          # Ongoing responsibilities
├── 300 Resources/      # Reference by topic
├── 400 Archive/        # Completed / inactive
├── 500 Templates/      # Note templates
├── 600 Daily Notes/    # Daily journal
├── 700 Books/          # Book notes
└── 800 Kindle Highlights/  # Imported highlights
```

## Setup

```bash
# Create vault structure
./scripts/setup-obsidian.sh

# Or with custom path
VAULT_PATH=/Volumes/SSD/obsidian-vault ./scripts/setup-obsidian.sh
```

Then open Obsidian → **Open folder as vault** → select `~/obsidian-vault`.

## Syncthing Setup

Syncthing syncs the vault peer-to-peer (no cloud needed).

**Mac mini (host):**
```bash
cd ~/docker/syncthing
docker compose up -d
# Open http://localhost:8384
# Add device: your MacBook's device ID
# Share folder: ~/obsidian-vault → ~/docker/syncthing/data/sync/obsidian-vault
```

**MacBook:**
```bash
brew install syncthing
syncthing  # opens at http://127.0.0.1:8384
# Add Mac mini as device
# Accept shared folder → ~/obsidian-vault
```

**iPhone:**
Install Möbius Sync (iOS) or Syncthing (Android), add the Mac mini as a device.

## Git Backup

```bash
cd ~/obsidian-vault
git init
git remote add origin git@github.com:yourusername/obsidian-vault.git
git add -A && git commit -m "init"
git push -u origin main
```

The `scripts/update.sh` will auto-commit and push daily when run.

## Recommended Plugins

| Plugin | Purpose |
|--------|---------|
| Dataview | Query notes as a database |
| Calendar | Visual daily note navigation |
| Templater | Advanced templates |
| Git | Backup from within Obsidian |
| Kindle Highlights | Import Kindle highlights |
| Omnisearch | Full-text search |

## Capture Workflow

1. **Quick thought** → `000 Inbox/` (Ctrl+N, add to inbox)
2. **Meeting notes** → `100 Projects/<project>/` or `200 Areas/`
3. **Article/book** → `300 Resources/<topic>/`
4. **Daily review** → `600 Daily Notes/YYYY-MM-DD`

Process inbox weekly: every note either moves to Projects/Areas/Resources/Archive or gets deleted.

## Scribe Workflow (Voice → Note)

Using Wispr Flow (installed via the macOS installer):

1. Hold Fn (or your hotkey) to dictate
2. Dictate into an Obsidian note
3. Use Claude to clean up and categorise

## Ollama Integration

With Ollama running locally, use the Obsidian plugin **Smart Connections** or **BMO Chatbot** to chat with your vault using a local model. No data leaves your machine.

```bash
# Start Ollama
cd ~/docker/ollama
docker compose up -d

# In Obsidian: install Smart Connections → set model to Ollama → llama3.2:3b
```
