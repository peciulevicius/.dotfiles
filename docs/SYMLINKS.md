# Understanding Symlinks in Dotfiles

A comprehensive guide to how symlinks work in this dotfiles repository.

## 🔗 What is a Symlink?

A **symlink** (symbolic link) is like a shortcut or pointer to another file. Instead of copying files, we create links that point to the original.

**Think of it like:**
- **Regular copy:** Two separate files that can get out of sync
- **Symlink:** A pointer that always points to the source file

```
Regular file:
~/.zshrc  →  [actual file content here]

Symlink:
~/.zshrc  →  points to  →  ~/.dotfiles/config/zsh/.zshrc  →  [actual content here]
```

## 📂 How It Works in This Repo

### Before Installing Dotfiles

Your home directory has actual config files:

```
/home/you/
├── .zshrc              [File with content]
├── .gitconfig          [File with content]
├── .ideavimrc          [File with content]
└── .tmux.conf          [File with content]
```

### After Installing Dotfiles

The installer:
1. **Backs up** your original files (→ `.backup`)
2. **Creates symlinks** pointing to the dotfiles repo

```
/home/you/
├── .zshrc              →  symlink to ~/.dotfiles/config/zsh/.zshrc
├── .gitconfig          →  symlink to ~/.dotfiles/config/git/.gitconfig
├── .ideavimrc          →  symlink to ~/.dotfiles/config/idea/.ideavimrc
├── .tmux.conf          →  symlink to ~/.dotfiles/config/tmux/.tmux.conf
│
├── .zshrc.backup       [Original backed up]
├── .gitconfig.backup   [Original backed up]
└── .ideavimrc.backup   [Original backed up]

/home/you/.dotfiles/
└── config/
    ├── zsh/
    │   └── .zshrc      [ACTUAL file - the source]
    ├── git/
    │   └── .gitconfig  [ACTUAL file - the source]
    └── idea/
        └── .ideavimrc  [ACTUAL file - the source]
```

## 🎯 Why Use Symlinks?

### 1. **Single Source of Truth**

Without symlinks (traditional approach):
```bash
# On Machine 1
edit ~/.zshrc
git commit -m "Add alias"
git push

# On Machine 2
git pull
cp ~/.dotfiles/config/zsh/.zshrc ~/.zshrc  # Manual copy - easy to forget!
```

With symlinks (this repo):
```bash
# On Machine 1
edit ~/.zshrc  # Automatically edits ~/.dotfiles/config/zsh/.zshrc
git commit -m "Add alias"
git push

# On Machine 2
git pull
# That's it! Changes are live immediately (it's a symlink)
```

### 2. **Automatic Sync**

When you edit `~/.zshrc`, you're actually editing `~/.dotfiles/config/zsh/.zshrc`:

```bash
# These are the SAME file (symlink!)
vim ~/.zshrc                              # Edit via symlink
vim ~/.dotfiles/config/zsh/.zshrc        # Edit directly

# Both edit the same content!
```

### 3. **Easy to Track Changes**

Since actual files are in the git repo:

```bash
cd ~/.dotfiles
git status          # Shows your changes
git diff            # See what you changed
git commit -a       # Commit all config changes
```

### 4. **Easy to Sync Between Machines**

```bash
# Machine 1: Make changes
vim ~/.zshrc        # Edit (via symlink)
cd ~/.dotfiles && git add -A && git commit -m "Add aliases" && git push

# Machine 2: Get changes
cd ~/.dotfiles && git pull
# Changes are immediately live! (no copying needed)
```

## 🔍 Seeing Symlinks in Action

### Check if a file is a symlink

```bash
# Method 1: ls -la
ls -la ~/.zshrc
# Output: lrwxr-xr-x  1 user  staff  40 Nov  5 12:00 /home/user/.zshrc -> /home/user/.dotfiles/config/zsh/.zshrc
#         ^
#         'l' means it's a symlink (link)

# Method 2: file command
file ~/.zshrc
# Output: /home/user/.zshrc: symbolic link to /home/user/.dotfiles/config/zsh/.zshrc

# Method 3: readlink
readlink ~/.zshrc
# Output: /home/user/.dotfiles/config/zsh/.zshrc
```

### Check all symlinks in your home directory

```bash
ls -la ~ | grep "^l"
# Shows all symlinks (lines starting with 'l')
```

### Find broken symlinks (shouldn't happen with this repo)

```bash
find ~ -maxdepth 1 -type l ! -exec test -e {} \; -print
# Shows symlinks that point to non-existent files
```

## 📝 What the Installer Does

Let's walk through exactly what happens when you run `./install.sh`:

### Step 1: Check if source file exists

```bash
source_file="$HOME/.dotfiles/config/zsh/.zshrc"
target_file="$HOME/.zshrc"

if [ ! -f "$source_file" ]; then
    echo "Source doesn't exist, skipping..."
    continue
fi
```

### Step 2: Backup existing file (if not already a symlink)

```bash
# Only backup if it's a real file (not already a symlink)
if [ -f "$target_file" ] && [ ! -L "$target_file" ]; then
    # It exists AND it's NOT a symlink → backup it
    mv "$target_file" "${target_file}.backup"
    echo "Backed up existing .zshrc"
fi
```

### Step 3: Create the symlink

```bash
# -s = create symbolic link
# -f = force (overwrite if exists)
ln -sf "$source_file" "$target_file"
echo "Created symlink: ~/.zshrc → ~/.dotfiles/config/zsh/.zshrc"
```

## 🔄 Workflow with Symlinks

### Editing Config Files

You can edit from either location:

```bash
# Method 1: Edit via the symlink (in home directory)
vim ~/.zshrc

# Method 2: Edit the source directly
vim ~/.dotfiles/config/zsh/.zshrc

# Method 3: Use your IDE
code ~/.zshrc                            # Opens the source file
code ~/.dotfiles/config/zsh/.zshrc      # Same file!
```

**All three methods edit the same file!**

### Committing Changes

```bash
# After editing ~/.zshrc (via symlink):
cd ~/.dotfiles
git status          # Shows config/zsh/.zshrc modified
git diff            # See your changes
git add config/zsh/.zshrc
git commit -m "Add new aliases"
git push
```

### Pulling Changes on Another Machine

```bash
# On another machine:
cd ~/.dotfiles
git pull
# Changes are immediately live! (symlink points to updated file)
source ~/.zshrc     # Reload shell to apply changes
```

## 🔧 Managing Symlinks

### Recreating Symlinks

If you accidentally delete a symlink:

```bash
# Recreate it manually
ln -sf ~/.dotfiles/config/zsh/.zshrc ~/.zshrc

# Or just re-run the installer
cd ~/.dotfiles && ./install.sh
```

### Removing Symlinks

If you want to stop using dotfiles:

```bash
# Option 1: Replace symlink with actual file
rm ~/.zshrc
cp ~/.dotfiles/config/zsh/.zshrc ~/.zshrc

# Option 2: Restore from backup
rm ~/.zshrc
mv ~/.zshrc.backup ~/.zshrc
```

### Checking Symlink Status

```bash
# See where a symlink points
readlink ~/.zshrc
# Output: /home/user/.dotfiles/config/zsh/.zshrc

# Verify all dotfiles symlinks
for file in ~/.zshrc ~/.gitconfig ~/.ideavimrc ~/.tmux.conf; do
    if [ -L "$file" ]; then
        echo "$file → $(readlink $file)"
    else
        echo "$file is NOT a symlink"
    fi
done
```

## 🎨 Visual Representation

### Traditional Approach (No Symlinks)

```
Machine 1:
~/.zshrc [Content A]
~/.gitconfig [Content B]

~/.dotfiles/
  config/zsh/.zshrc [Content A - DUPLICATE]
  config/git/.gitconfig [Content B - DUPLICATE]

Problem: Edit ~/.zshrc → Must manually copy to repo → Easy to forget!
```

### Symlink Approach (This Repo)

```
Machine 1:
~/.zshrc → ~/.dotfiles/config/zsh/.zshrc
~/.gitconfig → ~/.dotfiles/config/git/.gitconfig

~/.dotfiles/
  config/zsh/.zshrc [ONLY COPY - single source of truth]
  config/git/.gitconfig [ONLY COPY - single source of truth]

Benefit: Edit ~/.zshrc → Automatically edits the repo file!
```

## 📋 Complete List of Symlinks Created

The installer creates these symlinks:

| Symlink in ~ | Points to | Description |
|--------------|-----------|-------------|
| `~/.gitconfig` | `~/.dotfiles/config/git/.gitconfig` | Git configuration |
| `~/.gitignore_global` | `~/.dotfiles/config/git/.gitignore_global` | Global git ignores |
| `~/.gitmessage` | `~/.dotfiles/config/git/.gitmessage` | Commit message template |
| `~/.zshrc` | `~/.dotfiles/config/zsh/.zshrc` | Zsh configuration |
| (no symlink) | `~/.dotfiles/config/starship/starship.toml` | Starship config (via `$STARSHIP_CONFIG` env var) |
| `~/.ideavimrc` | `~/.dotfiles/config/idea/.ideavimrc` | IdeaVim config |
| `~/.tmux.conf` | `~/.dotfiles/config/tmux/.tmux.conf` | Tmux configuration |
| `~/.ssh/config` | `~/.dotfiles/config/ssh/config` | SSH configuration |
| `~/.curlrc` | `~/.dotfiles/config/curl/.curlrc` | Curl preferences |
| `~/.editorconfig` | `~/.dotfiles/config/.editorconfig` | EditorConfig |

## ⚠️ Important Notes

### What Happens When You Edit ~/.zshrc

```bash
vim ~/.zshrc
# This edits ~/.dotfiles/config/zsh/.zshrc (the actual file)

# The change is in your git repo:
cd ~/.dotfiles
git status
# Modified: config/zsh/.zshrc

# Commit it:
git add config/zsh/.zshrc
git commit -m "Update zsh config"
git push
```

### Symlinks Survive System Updates

- ✅ OS updates won't break symlinks
- ✅ Symlinks persist across reboots
- ✅ Safe to use in home directory

### Symlinks Don't Copy Content

- Symlinks are tiny (just a path reference)
- Editing the symlink = editing the source
- Deleting the symlink ≠ deleting the source file

## 🚀 Advantages of This Approach

### 1. Version Control

```bash
# See history of your configs
cd ~/.dotfiles
git log config/zsh/.zshrc

# Revert changes
git checkout HEAD~1 config/zsh/.zshrc
```

### 2. Easy Sync Across Machines

```bash
# Machine 1
vim ~/.zshrc
cd ~/.dotfiles && git add -A && git commit -m "Update" && git push

# Machine 2
cd ~/.dotfiles && git pull
# Done! Changes are live immediately
```

### 3. Safe Experimentation

```bash
# Try new config
vim ~/.zshrc

# Doesn't work? Revert easily:
cd ~/.dotfiles
git checkout -- config/zsh/.zshrc
source ~/.zshrc
```

### 4. Backup Built-in

```bash
# Your configs are in git
cd ~/.dotfiles
git push  # Backed up to GitHub

# Restore on new machine
git clone https://github.com/you/.dotfiles ~/.dotfiles
./install.sh  # Symlinks created, you're back!
```

## 💡 Testing Your Symlinks

Try this to see symlinks in action:

```bash
# 1. Check if ~/.zshrc is a symlink
ls -la ~/.zshrc
# Should show: ~/.zshrc -> ~/.dotfiles/config/zsh/.zshrc

# 2. Edit the symlink
echo "# Test comment" >> ~/.zshrc

# 3. Check the source file
tail -1 ~/.dotfiles/config/zsh/.zshrc
# Should show: # Test comment

# 4. They're the same file!
diff ~/.zshrc ~/.dotfiles/config/zsh/.zshrc
# No output = identical (because it's the same file!)

# 5. Remove test
sed -i '' '$ d' ~/.zshrc  # Remove last line
```

## 🔍 Troubleshooting Symlinks

### Symlink appears broken

```bash
# Check where it points
readlink ~/.zshrc

# Check if source exists
ls -la ~/.dotfiles/config/zsh/.zshrc

# If source is missing, symlink is broken
# Fix: Re-run installer or restore from backup
```

### Want to edit without git tracking

```bash
# Option 1: Use .zshrc.local (not symlinked)
vim ~/.zshrc.local
# This file is not in git, won't be tracked

# Option 2: Temporarily remove symlink
mv ~/.zshrc ~/.zshrc.bak
cp ~/.dotfiles/config/zsh/.zshrc ~/.zshrc
# Now ~/.zshrc is a real file, not tracked
```

## 📚 See Also

- [FAQ.md](./FAQ.md) - Common questions about installation and safety
- [HOW_TO_INSTALL.md](./HOW_TO_INSTALL.md) - Installation guide
- [CONFIG_GUIDE.md](./CONFIG_GUIDE.md) - What each config file does

---

**TL;DR:**
- 🔗 **Symlinks are pointers** to files (like shortcuts)
- 📝 **Editing ~/.zshrc** = editing ~/.dotfiles/config/zsh/.zshrc (same file)
- ✅ **Single source of truth** in the git repo
- 🔄 **Automatic sync** - git pull = instant updates
- 💾 **Original backed up** as .backup files
- 🚀 **Easy to manage** - all configs in one git repo
