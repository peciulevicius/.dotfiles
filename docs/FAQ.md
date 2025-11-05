# Frequently Asked Questions

Common questions about installing, maintaining, and using this dotfiles repository.

## 🔄 Installation & Safety

### What happens if the installer gets interrupted?

**Short answer:** The installer is designed to be **idempotent** - you can safely run it multiple times without breaking anything.

**Details:**

Every installer checks if things are already installed before installing:

```bash
# Example from installer
if command -v docker &> /dev/null; then
    echo "✓ Docker already installed"
    # Skips installation
else
    echo "Installing Docker..."
    # Installs it
fi
```

**If you interrupt the installer:**
1. ✅ Already installed packages will be detected and skipped
2. ✅ Already created symlinks will be left alone
3. ✅ Partial downloads might need to be cleaned up manually
4. ✅ You can just run `./install.sh` again to continue

**Safe to run multiple times:**
- Packages: ✅ Skipped if already installed
- Symlinks: ✅ Won't duplicate if already exist
- Configs: ⚠️ Will create new `.backup` files (see below)
- Git repo: ✅ Won't re-clone if already exists

### What happens if an app is already installed?

The installer will:
1. **Check if it's installed** using package manager queries
2. **Print a message** saying "X already installed"
3. **Skip to the next package** without reinstalling

Example from Arch installer:
```bash
if pacman -Qi "google-chrome" &> /dev/null; then
    echo "✓ google-chrome already installed"  # Skips it
else
    yay -S --noconfirm google-chrome           # Installs it
fi
```

**This means:**
- ✅ Safe to run installer on a machine with apps already installed
- ✅ Won't reinstall/downgrade existing apps
- ✅ Won't break existing configurations
- ✅ Only installs what's missing

### What happens if a config file already exists?

The installer follows this logic:

```bash
# Check if file exists and is NOT a symlink
if [ -f ~/.zshrc ] && [ ! -L ~/.zshrc ]; then
    # Backup the original
    mv ~/.zshrc ~/.zshrc.backup
    echo "Backed up existing .zshrc"
fi

# Create symlink
ln -sf ~/.dotfiles/config/zsh/.zshrc ~/.zshrc
```

**Behavior:**

1. **First time running installer:**
   - Your original `~/.zshrc` → backed up as `~/.zshrc.backup`
   - New symlink created: `~/.zshrc` → `~/.dotfiles/config/zsh/.zshrc`

2. **Second time running installer:**
   - `~/.zshrc` is already a symlink → no backup needed
   - Symlink recreated (points to same place)
   - Original backup preserved

3. **Third time running installer:**
   - Same as second time
   - Only one `.backup` file exists

**What this means:**
- ✅ Your original configs are safe (backed up)
- ✅ Won't create multiple backup files
- ✅ Safe to run installer multiple times
- ⚠️ If you modified the symlinked file, changes are in the dotfiles repo (not backed up separately)

### Can I safely re-run the installer?

**Yes!** The installer is designed to be **idempotent** (safe to run multiple times).

**What happens on re-run:**

| Component | Behavior |
|-----------|----------|
| **Packages** | Skipped if already installed |
| **Symlinks** | Recreated (same target) |
| **Backups** | Only created if file is not already a symlink |
| **Git repo** | Not cloned if already exists |
| **SSH keys** | Skipped if already exist |
| **Oh My Zsh** | Skipped if already exists |

**Use cases for re-running:**

```bash
# After pulling dotfiles updates
cd ~/.dotfiles && git pull
./install.sh  # Re-symlinks any new configs

# After adding new config files
./install.sh  # Creates symlinks for new files

# To verify everything is set up correctly
./install.sh  # Shows what's installed, installs missing items
```

### What if I want to start fresh?

**Option 1: Remove symlinks manually**
```bash
# Remove symlinks (keeps backups)
rm ~/.zshrc ~/.gitconfig ~/.ideavimrc ~/.p10k.zsh

# Re-run installer
cd ~/.dotfiles && ./install.sh
```

**Option 2: Use your backups**
```bash
# Restore original configs
mv ~/.zshrc.backup ~/.zshrc
mv ~/.gitconfig.backup ~/.gitconfig

# Then re-run installer if you want
cd ~/.dotfiles && ./install.sh
```

**Option 3: Nuclear option (complete reset)**
```bash
# Remove everything (including backups!)
rm -rf ~/.dotfiles
rm ~/.zshrc ~/.gitconfig ~/.ideavimrc ~/.p10k.zsh ~/.tmux.conf ~/.editorconfig

# Start over
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh
```

---

## 🛠️ Maintenance & Updates

### Do maintenance scripts update my configs?

**Short answer:** Only `update.sh` pulls dotfiles changes. You need to **re-run the installer** to apply config updates.

**What each script does:**

#### `update.sh` - Updates packages and pulls dotfiles
```bash
~/.dotfiles/scripts/update.sh
```

**Updates:**
- ✅ Package managers (Homebrew, apt, pacman, yay)
- ✅ Language tools (npm, pnpm, pip, Rust)
- ✅ Oh My Zsh
- ✅ **Pulls latest dotfiles changes** (`git pull`)

**Does NOT:**
- ❌ Re-create symlinks
- ❌ Install new packages added to installer
- ❌ Apply config changes to existing files

**After running `update.sh`, if dotfiles changed:**
```bash
cd ~/.dotfiles
./install.sh  # Re-symlink updated configs
```

#### `backup.sh` - Backs up configs (read-only)
```bash
~/.dotfiles/scripts/backup.sh
```

**Does:**
- ✅ Creates timestamped backup archive
- ✅ Backs up all config files
- ✅ Exports package lists
- ✅ Lists git repositories

**Does NOT:**
- ❌ Modify any files
- ❌ Update anything
- ❌ Change system state

#### `cleanup.sh` - Cleans caches (safe)
```bash
~/.dotfiles/scripts/cleanup.sh
```

**Cleans:**
- ✅ Package manager caches
- ✅ Docker containers/images
- ✅ npm/pnpm/pip caches
- ✅ Browser caches
- ✅ Temp files

**Does NOT:**
- ❌ Delete configs
- ❌ Delete source code
- ❌ Delete user data
- ❌ Uninstall packages

#### `dev-check.sh` - Health check (read-only)
```bash
~/.dotfiles/scripts/dev-check.sh
```

**Does:**
- ✅ Checks what's installed
- ✅ Verifies configs exist
- ✅ Checks SSH keys
- ✅ Tests GitHub auth
- ✅ Shows summary

**Does NOT:**
- ❌ Install anything
- ❌ Fix anything
- ❌ Modify files

### How do I update my configs after pulling changes?

**Option 1: Quick Sync (Recommended for config-only changes)**

Use the sync script to update configs without reinstalling everything:

```bash
~/.dotfiles/scripts/sync.sh
```

This will:
- ✅ Pull latest dotfiles changes
- ✅ Update all configuration symlinks
- ✅ Show you what changed
- ❌ **Does NOT** install new packages

**Option 2: Full Installer (When new tools were added)**

```bash
cd ~/.dotfiles
git pull
./install.sh  # Installs new tools + updates configs
```

**When to use which:**

| What Changed | Use |
|--------------|-----|
| `.zshrc`, `.gitconfig`, other configs | `sync.sh` (fast) |
| New packages added to installer | `./install.sh` (full) |
| Not sure | `sync.sh` first, then check FAQ |

**Complete workflow:**

```bash
# 1. Sync dotfiles (pulls + updates configs)
~/.dotfiles/scripts/sync.sh

# 2. Check what changed
cd ~/.dotfiles && git log -3

# 3. If new packages were added, run installer
./install.sh

# 4. Reload shell
source ~/.zshrc  # Or restart terminal
```

**What gets updated with sync.sh:**
- ✅ Config files (symlinks recreated)
- ✅ Latest dotfiles pulled
- ✅ New aliases/functions in `.zshrc`
- ✅ New git aliases in `.gitconfig`
- ❌ New packages (need full installer for this)

### Should I run installers or just maintenance scripts?

**Use cases:**

| Scenario | What to Run |
|----------|-------------|
| **Weekly maintenance** | `update.sh` |
| **Dotfiles config changed** | `sync.sh` (fast!) |
| **Monthly cleanup** | `cleanup.sh` |
| **Before important work** | `backup.sh` |
| **Troubleshooting** | `dev-check.sh` |
| **New packages added** | `./install.sh` |
| **New machine** | `./install.sh` |
| **Major dotfiles update** | `sync.sh` then `./install.sh` if needed |

**Recommended aliases:**

Add to your `~/.zshrc.local`:

```bash
# Maintenance shortcuts
alias update='~/.dotfiles/scripts/update.sh'
alias backup='~/.dotfiles/scripts/backup.sh'
alias cleanup='~/.dotfiles/scripts/cleanup.sh'
alias check='~/.dotfiles/scripts/dev-check.sh'
alias sync='~/.dotfiles/scripts/sync.sh'
alias dotfiles='cd ~/.dotfiles'

# For major updates (configs + packages)
alias dotfiles-full='cd ~/.dotfiles && git pull && ./install.sh && cd -'
```

Then:
```bash
update              # Update packages weekly
sync                # Sync dotfiles configs (fast)
backup              # Backup before major changes
cleanup             # Clean disk space monthly
check               # Verify environment health
dotfiles-full       # Full update with new packages
```

---

## 📚 Tool Documentation

### Are all the modern CLI tools documented?

**Yes!** See [MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md) for complete documentation of all tools.

Quick reference of what's installed:

| Tool | Replaces | Documentation |
|------|----------|---------------|
| `bat` | `cat` | [MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md#bat---better-cat) |
| `eza` | `ls` | [MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md#eza---better-ls) |
| `rg` | `grep` | [MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md#ripgrep-rg---better-grep) |
| `fd` | `find` | [MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md#fd---better-find) |
| `fzf` | History search | [MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md#fzf---fuzzy-finder) |
| `z` | `cd` | [MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md#zoxide---smart-cd) |
| `tldr` | `man` | [MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md#tldr---simplified-man-pages) |
| `http` | `curl` | [MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md#httpie---better-curl) |
| `jq` | JSON parsing | [MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md#jq---json-processor) |
| `delta` | `git diff` | [MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md#delta---better-git-diff) |

### Do I need to learn all these tools?

**No!** They're designed to "just work" as drop-in replacements.

**You can use them like the old tools:**

```bash
# These just work better automatically:
cat file.txt    # Actually uses 'bat' (via alias)
ls -la          # Actually uses 'eza' (via alias)
git diff        # Automatically uses 'delta'
```

**Or use their enhanced features:**

```bash
bat file.js                 # Syntax highlighting
eza --tree                  # Tree view
rg "pattern"                # Lightning fast search
Ctrl+R                      # Fuzzy history (fzf)
z projects                  # Smart directory jump
tldr docker                 # Quick examples
```

**Learn as you go:**
- Start with the basics (just use them like the old commands)
- Check `tldr <tool>` for quick examples
- Read [MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md) when you want to learn more

### Quick Start for New Tools

**First week - Learn these 3:**

```bash
# 1. Ctrl+R - Fuzzy history search (fzf)
# Just press Ctrl+R and start typing

# 2. bat - View files beautifully
bat README.md

# 3. eza - Better ls
eza -la
```

**Second week - Add these 2:**

```bash
# 4. rg - Fast search
rg "TODO"                   # Find all TODOs in current dir

# 5. z - Smart cd
z projects                  # Jump to ~/projects (after visiting once)
```

**Third week - Power user:**

```bash
# 6. fd - Quick file finding
fd "component"

# 7. tldr - Quick help
tldr docker

# 8. http - API testing
http GET https://api.github.com

# 9. jq - JSON processing
cat data.json | jq '.users[0].name'
```

**You don't need to learn everything at once!** The tools work fine even if you just use them like the old commands.

---

## 🔍 Troubleshooting

### The installer failed midway. What should I do?

1. **Check what failed:**
   ```bash
   # Look at the error message
   # Usually it's a network issue or missing permission
   ```

2. **Fix the issue** (common problems):
   ```bash
   # Network issues - just wait and retry
   ./install.sh

   # Permission issues
   sudo chown -R $USER ~/.dotfiles

   # Disk space issues
   df -h  # Check available space
   ~/.dotfiles/scripts/cleanup.sh  # Free up space
   ```

3. **Re-run the installer:**
   ```bash
   cd ~/.dotfiles
   ./install.sh
   ```

The installer will skip what's already done and continue where it left off.

### My shell looks different after re-running

This can happen if:
- Powerlevel10k was installed on second run but not first
- Nerd Font was installed after initial setup

**Fix:**
```bash
# If p10k is now installed
p10k configure

# If font is now installed
# Set terminal font to "MesloLGS NF" in terminal preferences
# Restart terminal
```

### I have multiple .backup files

This happens if you:
1. Had an original config file
2. Ran installer (created .backup)
3. Manually modified the symlinked file
4. Deleted the symlink
5. Ran installer again (created another .backup)

**Clean up:**
```bash
# List all backups
ls -la ~/*.backup*

# Keep the most recent, delete others
rm ~/.zshrc.backup.1  # etc
```

**Prevent this:**
- Don't delete symlinks manually
- Modify files in `~/.dotfiles/config/` instead

---

## 💡 Best Practices

### Recommended Workflow

**Daily:**
```bash
# Use your dev environment normally
# Modern CLI tools "just work"
```

**Weekly:**
```bash
update              # Update all packages
sync                # Sync latest dotfiles configs (if any)
```

**Monthly:**
```bash
backup              # Create backup
cleanup             # Free disk space
check               # Verify health
```

**When dotfiles change:**
```bash
sync                # Fast config sync
# Or if new packages were added:
dotfiles-full       # Full update
```

**Before major changes:**
```bash
backup              # Create backup first
# ... make your changes ...
check               # Verify nothing broke
```

### Setting Up Aliases

Add to `~/.zshrc.local` (not tracked by git):

```bash
# Maintenance
alias update='~/.dotfiles/scripts/update.sh'
alias sync='~/.dotfiles/scripts/sync.sh'
alias backup='~/.dotfiles/scripts/backup.sh'
alias cleanup='~/.dotfiles/scripts/cleanup.sh'
alias check='~/.dotfiles/scripts/dev-check.sh'

# Dotfiles management
alias dotfiles='cd ~/.dotfiles'
alias dotfiles-full='cd ~/.dotfiles && git pull && ./install.sh && cd -'
alias dotfiles-edit='cd ~/.dotfiles && code .'

# Git shortcuts (in addition to the 40+ aliases)
alias gs='git status'
alias gp='git pull'
alias gpo='git push'
```

Then reload:
```bash
source ~/.zshrc
```

**Usage:**
```bash
sync                # Daily: sync configs
update              # Weekly: update packages
backup              # Before major changes
cleanup             # Monthly: free space
check               # Troubleshooting
dotfiles-full       # Major updates
```

---

## 📖 See Also

- [HOW_TO_INSTALL.md](./HOW_TO_INSTALL.md) - Installation guide
- [MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md) - Tool documentation
- [UTILITY_SCRIPTS.md](./UTILITY_SCRIPTS.md) - Script details
- [CONFIG_GUIDE.md](./CONFIG_GUIDE.md) - Configuration reference
- [QUICKSTART.md](./QUICKSTART.md) - Quick start guide

---

**TL;DR:**
- ✅ **Safe to re-run** installer anytime
- ✅ **Safe to interrupt** - just re-run to continue
- ✅ **Original configs backed up** automatically
- ✅ **Modern tools work automatically** via aliases
- ✅ **Maintenance scripts are safe** (read-only or clean only)
- ✅ **After pulling changes**, re-run `./install.sh` to apply
- ✅ **Tools are documented** in [MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md)
- ✅ **Learn tools gradually** - they work fine like old commands
