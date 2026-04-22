"""
Kindle Scribe → Obsidian sync configuration.
Fill in VAULT_PATH and IMAP credentials before first run.
"""

# Absolute path to your Obsidian vault folder
VAULT_PATH = ""  # e.g. "/Users/yourname/obsidian-vault"

# IMAP credentials — use an app password if your provider requires it
IMAP_SERVER = "imap.gmail.com"   # change to imap.fastmail.com etc. when switching
IMAP_PORT = 993
EMAIL_ADDRESS = "dziugaspeciulevicius@gmail.com"
EMAIL_PASSWORD = ""  # app password (not your main account password)

# Optional features
GIT_AUTOPUSH = False   # set True to git commit + push after every sync

# Routing: keyword (lowercase) → path relative to VAULT_PATH
# If keyword matches notebook name, notes go to that path.
# Paths ending in "/" are folders — file will be named YYYY-MM-DD_NotebookName.md inside.
# Paths ending in ".md" are appended to that specific file.
ROUTING_RULES: dict[str, str] = {
    # Work — Visma
    "vfs":          "🏢 Visma/VFS.md",
    "gweb":         "🏢 Visma/Gweb.md",
    "justas":       "🏢 Visma/1on1 Justas D.md",
    "vcdm":         "🏢 Visma/VCDM.md",
    "young prof":   "🏢 Visma/Young Professionals Program 25-26.md",
    "visma":        "🏢 Visma/",
    # Build
    "ideas":        "🚀 Build/Ideas & Brainstorm.md",
    "saas":         "🚀 Build/SaaS Stack & Research.md",
    "ventures":     "🚀 Build/Ventures & Business Models.md",
    "writing":      "🚀 Build/Writing & Content.md",
    "content":      "🚀 Build/Writing & Content.md",
    "build":        "🚀 Build/Ideas & Brainstorm.md",
    # Books & Learning
    "book":         "📚 Books & Learning/Book Notes/",
    "reading":      "📚 Books & Learning/Currently Reading.md",
    "quotes":       "📚 Books & Learning/Quotes & Principles.md",
    "principles":   "📚 Books & Learning/Quotes & Principles.md",
    # Training & Health
    "training":     "🏊 Training & Health/Training Log.md",
    "swim":         "🏊 Training & Health/Training Log.md",
    "bike":         "🏊 Training & Health/Training Log.md",
    "run":          "🏊 Training & Health/Training Log.md",
    "race":         "🏊 Training & Health/Race Planning.md",
    "triathlon":    "🏊 Training & Health/Race Planning.md",
    "health":       "🏊 Training & Health/Health & Recovery.md",
    "recovery":     "🏊 Training & Health/Health & Recovery.md",
    "physio":       "🏊 Training & Health/Health & Recovery.md",
    # Finance
    "finance":      "💰 Finance/Budget & Overview.md",
    "budget":       "💰 Finance/Budget & Overview.md",
    "money":        "💰 Finance/Notes.md",
    # Travel
    "travel":       "✈️ Travel/Ideas & Wishlist.md",
    "trip":         "✈️ Travel/",
    # Personal
    "goals":        "🙋 Personal/Goals & Priorities.md",
    "priorities":   "🙋 Personal/Goals & Priorities.md",
    "reflection":   "🙋 Personal/Weekly Reflection.md",
    "journal":      "🙋 Personal/Weekly Reflection.md",
    "personal":     "🙋 Personal/Goals & Priorities.md",
    "weekly":       "🙋 Personal/Weekly Reflection.md",
    # Catch-all
    "capture":      "⚡ Capture/Quick Capture.md",
}

# If no routing rule matches, notes go here
FALLBACK_FOLDER = "📥 Imports/"
