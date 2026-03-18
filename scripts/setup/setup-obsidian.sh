#!/bin/bash
# Set up Obsidian vault with folder structure and template files
# Usage: ./scripts/setup/setup-obsidian.sh [--vault-path /custom/path]

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

VAULT_PATH="${VAULT_PATH:-$HOME/obsidian-vault}"

log_ok()   { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_info() { echo -e "${CYAN}→${NC} $1"; }

for arg in "$@"; do
  case "$arg" in
    --vault-path) shift; VAULT_PATH="$1" ;;
    *) ;;
  esac
done

echo -e "${CYAN}Obsidian Vault Setup${NC}"
echo "Vault path: $VAULT_PATH"
echo ""

if [[ -d "$VAULT_PATH" ]] && [[ -n "$(ls -A "$VAULT_PATH" 2>/dev/null)" ]]; then
  # Check if vault already has our structure
  if [[ -f "$VAULT_PATH/HOME.md" ]]; then
    log_warn "Obsidian vault already set up at $VAULT_PATH"
    exit 0
  fi
fi

mkdir -p "$VAULT_PATH"

# Folder structure
FOLDERS=(
  "⚡ Capture"
  "🏢 Visma"
  "🚀 Build"
  "📚 Books & Learning/Book Notes"
  "🏊 Training & Health"
  "💰 Finance"
  "✈️ Travel"
  "🙋 Personal"
  "📥 Imports"
  "📦 Archive"
)

for folder in "${FOLDERS[@]}"; do
  mkdir -p "$VAULT_PATH/$folder"
  log_ok "Created $folder/"
done

# HOME.md — root dashboard
cat > "$VAULT_PATH/HOME.md" <<'EOF'
# My Vault

## Where does everything go?

| I want to... | Go to |
|---|---|
| Dump a thought fast | ⚡ Capture/Quick Capture.md |
| Log a training session | 🏊 Training & Health/Training Log.md |
| Write down a business idea | 🚀 Build/Ideas & Brainstorm.md |
| Develop an idea seriously | 🚀 Build/Ventures & Business Models.md |
| Note something from a book | 📚 Books & Learning/Currently Reading.md |
| Save a great quote | 📚 Books & Learning/Quotes & Principles.md |
| Log a work meeting / task | 🏢 Visma/[relevant file] |
| Plan a race | 🏊 Training & Health/Race Planning.md |
| Track budget / spending | 💰 Finance/Budget & Overview.md |
| Plan a trip | ✈️ Travel/[Trip name].md |
| Reflect / set goals | 🙋 Personal/Goals & Priorities.md |
| Paste a Kindle TXT export | 📥 Imports/ → then move content to right note |
| Dead idea / old note | 📦 Archive/ |

## Weekly routine (10 min every Sunday)
1. Clear ⚡ Quick Capture — move items to their home, delete noise
2. Process 📥 Imports — paste TXT content into correct notes, delete raw files
3. Add one entry to 🙋 Personal/Weekly Reflection.md
EOF

# ⚡ Capture
cat > "$VAULT_PATH/⚡ Capture/Quick Capture.md" <<'EOF'
# Quick Capture

**This is your inbox. Dump everything here first, sort it later.**
Comes from: Kindle Scribe / phone / voice memo / PC random thought.
Clear every Sunday — move what matters, delete the rest.

---

<!-- paste anything below this line, don't organise while capturing -->
EOF

# 🏢 Visma
for file in VFS Gweb VCDM; do
cat > "$VAULT_PATH/🏢 Visma/$file.md" <<EOF
# $file

## Notes
-

## Action items
- [ ]

## Archive
-
EOF
done

cat > "$VAULT_PATH/🏢 Visma/1on1 Justas D.md" <<'EOF'
# 1:1 Justas D.

## Running notes

### YYYY-MM-DD
**Topics:**
-
**Actions:**
- [ ]
EOF

cat > "$VAULT_PATH/🏢 Visma/Young Professionals Program 25-26.md" <<'EOF'
# Young Professionals Program 25/26

## Notes
-

## Key dates
-

## Actions
- [ ]
EOF

# 🚀 Build
cat > "$VAULT_PATH/🚀 Build/Ideas & Brainstorm.md" <<'EOF'
# Ideas & Brainstorm

Raw, unfiltered. No idea is too stupid here.
Dump fast — evaluate in Ventures & Business Models.

---

## [Date] — [quick label]
-
EOF

cat > "$VAULT_PATH/🚀 Build/SaaS Stack & Research.md" <<'EOF'
# SaaS Stack & Research

Tools, competitors, tech, pricing models, market research.

---

## Tools I'm evaluating

| Tool | What it does | Cost | Verdict |
|---|---|---|---|
| | | | |

## Competitors & market

-

## Tech & architecture notes

-
EOF

cat > "$VAULT_PATH/🚀 Build/Ventures & Business Models.md" <<'EOF'
# Ventures & Business Models

One section per idea worth developing. Copy the template below.

---

## Template — copy for each idea

### [Idea Name]
**Status:** Exploring / Active / Paused / Killed
**Date:** YYYY-MM-DD

**Problem:** Who has it, how painful, how do you know?

**Who pays:** Specific customer type. Why would they pay?

**Revenue model:** Subscription / one-time / marketplace / other

**Unfair advantage:** Why you, why now?

**First 10 customers:** How exactly would you find and close them?

**Validated so far:**
-

**Kill criteria:** What would make you stop?

**Raw notes:**
-
EOF

cat > "$VAULT_PATH/🚀 Build/Writing & Content.md" <<'EOF'
# Writing & Content

Drafts, essays, LinkedIn posts, blog articles — anything to publish.
Rule: write ugly first, edit later, publish something.

---

## Draft queue
-

## In progress
-

## Published / done
-
EOF

# 📚 Books & Learning
cat > "$VAULT_PATH/📚 Books & Learning/Currently Reading.md" <<'EOF'
# Currently Reading

Live notes per reading session. One section per book, newest first.

---

## Project Hail Mary — Andy Weir
**Started:** 2026-03
**Format:** Kindle

### Notes
-
EOF

cat > "$VAULT_PATH/📚 Books & Learning/Quotes & Principles.md" <<'EOF'
# Quotes & Principles

The best lines from everything you read, hear, or think.
Always source it.

---

> "Quote here."
> — Book or source, Author
EOF

cat > "$VAULT_PATH/📚 Books & Learning/Book Notes/_Book Template.md" <<'EOF'
---
title:
author:
status: Reading / Finished / Abandoned
format: Kindle / Physical / Audio
started:
finished:
goodreads:
---

# Title — Author

## One-sentence takeaway

## Highlights
<!-- paste Kindle TXT export here -->

## My notes
<!-- your thinking — this is more valuable than the highlights -->

## Best quotes
<!-- move the top ones to Quotes & Principles.md -->

## Actions
<!-- concrete things to apply from this book -->
EOF

# 🏊 Training & Health
cat > "$VAULT_PATH/🏊 Training & Health/Training Log.md" <<'EOF'
# Training Log

One entry per session. Newest at top.

---

## Template — copy per session

### YYYY-MM-DD — [Swim / Bike / Run / Brick / Rest]
**Distance / duration:**
**How it felt (1–10):**
**Notes:**
-
EOF

cat > "$VAULT_PATH/🏊 Training & Health/Race Planning.md" <<'EOF'
# Race Planning

One section per race. Include A/B/C priority.

---

## Race Template

### [Race Name] — [Date] — [Location]
**Priority:** A / B / C
**Distance:** Sprint / Olympic / 70.3 / Full
**Goal:** Finish / Time target / Podium

**Preparation checklist:**
- [ ] Register
- [ ] Book accommodation
- [ ] Plan travel
- [ ] Peak week plan
- [ ] Race kit ready
- [ ] Nutrition plan

**Notes:**
-

**Result:**
-

---

## Upcoming races

-

## Past races

-
EOF

cat > "$VAULT_PATH/🏊 Training & Health/Gear & Nutrition.md" <<'EOF'
# Gear & Nutrition

## Gear

### Current kit
| Item | Brand/Model | Notes |
|---|---|---|
| Wetsuit | | |
| Bike | | |
| Helmet | | |
| Shoes (run) | | |
| Shoes (bike) | | |
| Watch | | |

### Wishlist / research
-

## Nutrition

### Race day protocol
-

### Training nutrition
-

### Products I use / testing
-
EOF

cat > "$VAULT_PATH/🏊 Training & Health/Health & Recovery.md" <<'EOF'
# Health & Recovery

Sleep, injury, physio notes, HRV, general body tracking.

---

## Ongoing notes
-

## Injuries / niggles

### [Date] — [Area]
**What happened:**
**Treatment:**
**Status:**

## Recovery protocols
-
EOF

# 💰 Finance
cat > "$VAULT_PATH/💰 Finance/Budget & Overview.md" <<'EOF'
# Budget & Overview

## Monthly snapshot

| Category | Budget | Actual | Delta |
|---|---|---|---|
| Housing | | | |
| Food | | | |
| Transport | | | |
| Training / gear | | | |
| Subscriptions | | | |
| Savings | | | |
| Other | | | |

## Financial goals

-

## Notes
-
EOF

cat > "$VAULT_PATH/💰 Finance/Notes.md" <<'EOF'
# Finance Notes

Random financial thoughts, research, things to look into.

---

-
EOF

# ✈️ Travel
cat > "$VAULT_PATH/✈️ Travel/_Trip Template.md" <<'EOF'
# [Destination] — [Month Year]

**Dates:**
**With:**
**Purpose:** Holiday / Work / Race / Other

---

## Planning

- [ ] Flights
- [ ] Accommodation
- [ ] Transport
- [ ] Things to do
- [ ] Packing list

## Places to visit
-

## Restaurants / food
-

## Notes
-
EOF

cat > "$VAULT_PATH/✈️ Travel/Ideas & Wishlist.md" <<'EOF'
# Travel Ideas & Wishlist

Places I want to go, roughly organised.

---

## Next 12 months
-

## Someday
-

## Race travel
-
EOF

# 🙋 Personal
cat > "$VAULT_PATH/🙋 Personal/Goals & Priorities.md" <<'EOF'
# Goals & Priorities

---

## 2026

### Top 3 priorities
1.
2.
3.

### By area

**Build / business:**
-

**Training / triathlon:**
-

**Reading:**
-

**Finance:**
-

**Personal growth:**
-

## Someday / maybe
-
EOF

cat > "$VAULT_PATH/🙋 Personal/Weekly Reflection.md" <<'EOF'
# Weekly Reflection

10 minutes every Sunday. One entry per week, newest at top.

---

## Template

### Week of YYYY-MM-DD

**What went well:**

**What didn't:**

**Training this week:**

**One thing to do differently:**

**Focus for next week:**
EOF

# 📥 Imports
cat > "$VAULT_PATH/📥 Imports/README.md" <<'EOF'
# Imports

Kindle TXT exports land here. Process weekly:
1. Open the TXT file
2. Copy content
3. Paste into the correct note body (never attach as a file)
4. Delete the raw TXT from this folder
5. Keep PDFs here only if they have sketches/diagrams worth keeping visually

Nothing should live here longer than one week.
EOF

# 📦 Archive
cat > "$VAULT_PATH/📦 Archive/README.md" <<'EOF'
# Archive

Nothing gets deleted — just moved here.
Dead business ideas, old Visma notes, past courses, outdated research.
EOF

log_ok "Vault structure created at $VAULT_PATH"
echo ""
echo "Next steps:"
echo "  1) Open Obsidian → 'Open folder as vault' → $VAULT_PATH"
echo "  2) Set HOME.md as startup note (Settings → Files & Links → Default note)"
echo "  3) Syncthing handles sync to other devices"
echo "  4) Rclone handles B2 offsite backup (runs nightly)"
