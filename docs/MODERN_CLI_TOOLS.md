# Modern CLI Tools Guide

This dotfiles repository includes modern, improved CLI tools that significantly enhance your terminal experience. These tools are faster, more user-friendly, and provide better output than their traditional counterparts.

## 🚀 Overview

All of these tools are installed automatically when you run the installation scripts. They're available on macOS, Arch Linux, and Ubuntu/Debian.

## 📦 Installed Tools

### bat - Better `cat`

**Better than:** `cat`
**What it does:** Display file contents with syntax highlighting and Git integration

```bash
# Traditional
cat file.js

# Modern
bat file.js
```

**Features:**
- Syntax highlighting for 200+ languages
- Git integration shows modifications
- Line numbers
- Paging support (like less)
- Non-printable character highlighting

**Usage:**
```bash
bat README.md                    # View with syntax highlighting
bat src/**/*.js                  # View multiple files
bat -n file.py                   # Show line numbers only
bat --style=plain file.txt       # Plain output (no line numbers)
```

**Aliases in .zshrc:**
```bash
alias cat='bat'
```

---

### eza - Better `ls`

**Better than:** `ls` / `exa`
**What it does:** List directory contents with colors, icons, and Git status

```bash
# Traditional
ls -la

# Modern
eza -la
```

**Features:**
- Colorful output
- File icons (requires Nerd Font)
- Git status integration
- Tree view
- Human-readable sizes

**Usage:**
```bash
eza -la                          # Long format with hidden files
eza --icons                      # Show file icons
eza --tree --level=2             # Tree view (2 levels deep)
eza --git                        # Show git status
eza --sort=modified              # Sort by modification time
```

**Aliases in .zshrc:**
```bash
alias ls='eza'
alias ll='eza -la'
alias la='eza -a'
alias lt='eza --tree --level=2'
```

---

### ripgrep (rg) - Better `grep`

**Better than:** `grep` / `ag` / `ack`
**What it does:** Search file contents lightning-fast

```bash
# Traditional
grep -r "pattern" .

# Modern
rg "pattern"
```

**Features:**
- Incredibly fast (written in Rust)
- Respects .gitignore by default
- Supports regex
- Multiline matching
- Automatic file type detection

**Usage:**
```bash
rg "TODO"                        # Find all TODOs
rg "function.*user" --type js    # Search in JS files only
rg -i "error"                    # Case-insensitive search
rg -l "import.*react"            # List files containing pattern
rg --hidden "api_key"            # Search hidden files too
```

**Useful flags:**
```bash
-i                               # Ignore case
-l                               # List files only
-c                               # Count matches
-A 3                             # Show 3 lines after match
-B 3                             # Show 3 lines before match
-C 3                             # Show 3 lines context
--type js                        # Search specific file type
--hidden                         # Search hidden files
```

---

### fd - Better `find`

**Better than:** `find`
**What it does:** Find files and directories

```bash
# Traditional
find . -name "*.js"

# Modern
fd "\.js$"
```

**Features:**
- Faster and simpler syntax
- Colorful output
- Respects .gitignore
- Smart case sensitivity
- Parallel execution

**Usage:**
```bash
fd pattern                       # Find files matching pattern
fd "^test" --type f              # Find files starting with "test"
fd "component" --extension tsx   # Find .tsx files with "component"
fd --hidden --no-ignore          # Search hidden and ignored files
fd --type d "node_modules"       # Find directories only
```

**Useful flags:**
```bash
-t f                             # Files only
-t d                             # Directories only
-e ext                           # Specific extension
-H                               # Include hidden files
-I                               # Include ignored files (gitignore)
-x command                       # Execute command on results
```

---

### fzf - Fuzzy Finder

**Better than:** `Ctrl+R` history search
**What it does:** Interactive fuzzy finder for the command line

```bash
# Press Ctrl+R to search command history
# Type to filter, use arrows to select, Enter to execute
```

**Features:**
- Lightning-fast fuzzy search
- Interactive preview
- Works with any list
- Integrates with shell history
- Customizable keybindings

**Usage:**
```bash
# Command history (Ctrl+R)
history | fzf

# File finder
find . -type f | fzf

# Directory navigation
cd $(find . -type d | fzf)

# Kill process
kill -9 $(ps aux | fzf | awk '{print $2}')

# Git checkout branch
git checkout $(git branch | fzf)
```

**Built-in keybindings:**
```bash
Ctrl+R                           # Search command history
Ctrl+T                           # Search files in current directory
Alt+C                            # Search directories and cd into them
```

---

### zoxide - Smart `cd`

**Better than:** `cd`
**What it does:** Jump to frequently-used directories

```bash
# Traditional
cd ~/projects/my-app/src/components

# Modern (after visiting once)
z components
```

**Features:**
- Learns your most-used directories
- Jump directly without full paths
- Fuzzy matching
- Interactive selection

**Usage:**
```bash
z projects                       # Jump to most frequent "projects" dir
z doc                            # Jump to documents (fuzzy match)
zi projects                      # Interactive selection if multiple matches
```

**How it works:**
- Uses "frecency" (frequency + recency)
- The more you visit a directory, the easier it becomes to jump to it
- Automatically updates its database

---

### tldr - Simplified Man Pages

**Better than:** `man`
**What it does:** Show practical examples of command usage

```bash
# Traditional
man tar

# Modern
tldr tar
```

**Features:**
- Concise, practical examples
- Community-maintained
- Quick reference
- Syntax highlighting

**Usage:**
```bash
tldr git                         # Git examples
tldr docker                      # Docker examples
tldr curl                        # Curl examples
tldr --update                    # Update tldr cache
```

---

### httpie - Better `curl`

**Better than:** `curl` / `wget`
**What it does:** HTTP client for testing APIs

```bash
# Traditional
curl -X POST -H "Content-Type: application/json" -d '{"key":"value"}' https://api.example.com

# Modern
http POST https://api.example.com key=value
```

**Features:**
- Intuitive syntax
- JSON support by default
- Syntax highlighting
- Session support
- Download progress

**Usage:**
```bash
http GET https://api.example.com/users        # GET request
http POST https://api.example.com/users name=John age:=30  # POST JSON
http PUT https://api.example.com/users/1 name=Jane         # PUT request
http DELETE https://api.example.com/users/1               # DELETE request
http --auth user:pass https://api.example.com             # Basic auth
http --download https://example.com/file.zip              # Download file
```

**Syntax:**
```bash
http [METHOD] URL [HEADERS] [DATA]

# Data types:
key=value            # String
key:=value           # Raw JSON
key:=@file.json      # JSON from file
key@file.txt         # File upload
```

---

### jq - JSON Processor

**Better than:** Parsing JSON with `grep` or `sed`
**What it does:** Parse, filter, and transform JSON data

```bash
# Parse API response
curl https://api.example.com/users | jq '.'

# Extract specific field
curl https://api.example.com/users | jq '.users[0].name'
```

**Features:**
- Powerful JSON manipulation
- Pretty printing
- Filtering and mapping
- Supports complex queries

**Usage:**
```bash
echo '{"name":"John","age":30}' | jq '.'                      # Pretty print
echo '{"name":"John","age":30}' | jq '.name'                  # Extract field
echo '[{"a":1},{"a":2}]' | jq '.[].a'                         # Extract from array
echo '{"users":[{"name":"John"}]}' | jq '.users[0].name'      # Nested access
cat data.json | jq 'map(select(.age > 25))'                   # Filter
cat data.json | jq '[.[] | {name, age}]'                      # Transform
```

---

### delta - Better `git diff`

**Better than:** `git diff`
**What it does:** Syntax-highlighted git diffs with line numbers

```bash
# Automatically used when configured
git diff
git show
git log -p
```

**Features:**
- Syntax highlighting
- Side-by-side diffs
- Line numbers
- Git blame integration
- Multiple themes

**Configuration (already in .gitconfig):**
```ini
[core]
    pager = delta

[delta]
    navigate = true
    light = false
    line-numbers = true
    syntax-theme = Dracula

[interactive]
    diffFilter = delta --color-only
```

**Usage:**
```bash
git diff                         # Automatically uses delta
git diff --staged                # Staged changes
git show HEAD                    # Show last commit
git log -p                       # Log with patches
```

---

## 🎯 Quick Reference

| Traditional | Modern Alternative | Purpose |
|------------|-------------------|---------|
| `cat file.txt` | `bat file.txt` | View files |
| `ls -la` | `eza -la` | List files |
| `grep -r "pattern" .` | `rg "pattern"` | Search content |
| `find . -name "*.js"` | `fd "\.js$"` | Find files |
| History search | `fzf` (Ctrl+R) | Command history |
| `cd ~/long/path` | `z path` | Smart navigation |
| `man command` | `tldr command` | Quick help |
| `curl ...` | `http ...` | HTTP requests |
| Parse JSON | `jq` | JSON processing |
| `git diff` | Uses `delta` | Git diffs |

## 💡 Pro Tips

### Combine Tools

```bash
# Find and view
fd "component" --extension tsx | fzf | xargs bat

# Search and edit
rg -l "TODO" | fzf | xargs code

# Find large files
fd --type f --size +10m | fzf

# Interactive git add
git status -s | fzf -m | awk '{print $2}' | xargs git add
```

### Use with fzf

```bash
# Preview files while searching
fd --type f | fzf --preview 'bat --color=always {}'

# Search and open in editor
rg --files | fzf --preview 'bat {}' | xargs code
```

### Aliases to Add

Add these to your `.zshrc` for even more convenience:

```bash
# Quick search and edit
alias search='rg --files | fzf --preview "bat --color=always {}" | xargs code'

# Find and remove node_modules
alias clean-modules='fd -H "^node_modules$" -t d -x rm -rf'

# Git log with fzf
alias glog='git log --oneline | fzf --preview "git show {1}"'
```

## 📚 Learn More

- [bat](https://github.com/sharkdp/bat)
- [eza](https://github.com/eza-community/eza)
- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [fd](https://github.com/sharkdp/fd)
- [fzf](https://github.com/junegunn/fzf)
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- [tldr](https://github.com/tldr-pages/tldr)
- [httpie](https://httpie.io)
- [jq](https://stedolan.github.io/jq/)
- [delta](https://github.com/dandavison/delta)

---

**These tools will transform your command-line workflow!** Give them a try - you'll never want to go back to the traditional alternatives.
