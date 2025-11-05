# Cleanup & Modernization Audit

Audit of what should be removed, replaced, or kept in this dotfiles repository.

## 🔴 TO REMOVE (Outdated/Unused)

### 1. **Powerlevel10k** → Replace with Starship

**Status:** ⚠️ On "life support" - no longer actively maintained
**Replacement:** [Starship](https://starship.rs/) - modern, cross-shell, actively maintained

**Powerlevel10k:**
- Last active development: ~2023
- Maintainer announced it's on life support
- Still works but won't get updates/fixes
- Zsh-only

**Starship:**
- ✅ Actively maintained (2025)
- ✅ Written in Rust (blazing fast)
- ✅ Cross-shell (zsh, bash, fish, PowerShell)
- ✅ Easy TOML configuration
- ✅ Similar features to p10k
- ✅ Modern, clean, minimal by default

**Action:** Replace p10k with Starship in all installers

---

### 2. **Duplicate/Old Install Scripts**

**Files to remove:**
- `os/mac/install2.sh` - Duplicate of install.sh (CHECK IF USED)
- `os/linux/install.sh` - Old generic installer, replaced by install_arch.sh and install_ubuntu.sh

**Keep:**
- `os/mac/install_minimal.sh` - Primary macOS installer
- `os/mac/install_optional.sh` - Optional tools
- `os/linux/install_arch.sh` - Arch Linux installer
- `os/linux/install_ubuntu.sh` - Ubuntu/Debian installer

---

### 3. **MCP Configuration (AI-MCP)**

**File:** `config/ai-mcp/mcp.json`

**Contains:**
- Desktop Commander
- Sequential Thinking
- Context7

**User mentioned:**
- ❌ No mention of using MCP servers
- ✅ Uses Claude Code (different from MCP)

**Action:** Remove unless user confirms they need it

---

### 4. **Neovim/Vim References**

**User confirmed:**
- ❌ Doesn't use neovim
- ✅ Uses WebStorm + VS Code

**Check and remove:**
- Any neovim packages in installers
- Neovim configs (if any)
- Keep: basic vim config (comes with OS)

---

### 5. **Tmux Configuration**

**File:** `config/tmux/.tmux.conf`

**User mentioned:**
- ❌ No mention of using tmux
- ✅ Uses regular terminal + WebStorm

**Options:**
1. Keep (doesn't hurt, some devs like tmux)
2. Move to optional/advanced configs
3. Remove entirely

**Recommendation:** KEEP - tmux is useful, config doesn't hurt

---

### 6. **Old Package Manager Configs**

**File:** `packages.conf`

**Contains:**
- Cross-platform package mappings
- May be outdated

**Action:** Review and update or remove if not used

---

## 🟡 TO UPDATE (Outdated but Useful)

### 1. **Shell Prompt: p10k → Starship**

**Changes needed:**

**In installers:**
```bash
# OLD (Remove):
brew install powerlevel10k
git clone powerlevel10k

# NEW (Add):
brew install starship
curl -sS https://starship.rs/install.sh | sh  # Linux
```

**In .zshrc:**
```bash
# OLD (Remove):
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# NEW (Add):
eval "$(starship init zsh)"
```

**New config file:**
```bash
# Create: config/starship/starship.toml
# Simple, minimal config
```

---

### 2. **Nerd Fonts**

**Current:** MesloLGS NF (for p10k)
**Update:** Keep MesloLGS or FiraCode (works with Starship too)
**Action:** No change needed

---

## 🟢 TO KEEP (Good as is)

### Modern CLI Tools
- ✅ bat, eza, ripgrep, fd, fzf, zoxide, tldr, httpie, jq, delta
- All actively maintained, modern, useful

### Development Tools
- ✅ Docker, Node.js (nvm), pnpm, Git, GitHub CLI
- User actively uses these

### Applications
- ✅ Chrome, WebStorm, VS Code, Claude Code
- ✅ Bitwarden, NordPass, NordVPN
- ✅ Figma, Notion
- User confirmed uses all of these

### Configs
- ✅ .gitconfig (40+ aliases)
- ✅ .gitignore_global
- ✅ .gitmessage
- ✅ .zshrc (good with or without p10k)
- ✅ .ideavimrc (for WebStorm)
- ✅ .editorconfig
- ✅ .ssh/config template
- ✅ .curlrc

### Scripts
- ✅ update.sh, sync.sh, backup.sh, cleanup.sh, dev-check.sh, setup-gpg.sh
- All useful for maintenance

### Documentation
- ✅ All docs in docs/ folder
- Comprehensive and up-to-date

---

## 📋 Action Plan

### Phase 1: Replace Powerlevel10k with Starship

1. Create Starship config
2. Update all installers
3. Update .zshrc
4. Update documentation
5. Remove .p10k.zsh

### Phase 2: Remove Old Files

1. Check if install2.sh is used
2. Remove os/linux/install.sh (old generic)
3. Check MCP config with user
4. Audit for neovim references

### Phase 3: Clean Documentation

1. Update docs to mention Starship
2. Remove p10k references
3. Update screenshots if any

---

## 🤔 Questions for User

1. **Do you use tmux?** (Keep config or remove?)
2. **Do you use MCP servers?** (ai-mcp/mcp.json - keep or remove?)
3. **Starship vs basic prompt?** (Replace p10k with Starship, or just use basic prompt?)
4. **Any other tools you don't use?** (We can remove them)

---

## 💡 Recommended: Starship

**Why Starship over p10k:**

| Feature | Powerlevel10k | Starship |
|---------|--------------|----------|
| Maintained | ❌ Life support | ✅ Active (2025) |
| Speed | ✅ Very fast | ✅ Blazing fast (Rust) |
| Shell Support | Zsh only | Zsh, Bash, Fish, PowerShell |
| Configuration | Interactive wizard | TOML file |
| Features | Very rich | Rich |
| Popularity | High (legacy) | Growing rapidly |

**Starship is the modern choice.** Most developers are migrating from p10k to Starship.

---

## 📊 Size Savings

Removing old files:
- Old install scripts: ~5KB
- MCP config: ~2KB
- Old docs: ~10KB

Not much space saved, but **cleaner repo**.

---

## 🎯 Summary

**Must Replace:**
- ❌ Powerlevel10k → ✅ Starship

**Should Remove:**
- os/mac/install2.sh (if duplicate)
- os/linux/install.sh (old generic)
- ai-mcp/mcp.json (if not used)
- Neovim packages (user doesn't use)

**Keep:**
- All modern CLI tools
- All apps user mentioned
- All utility scripts
- All documentation
- tmux config (useful even if not using yet)

**Net Result:**
- ✅ Cleaner repo
- ✅ Modern, maintained tools
- ✅ No breaking changes
- ✅ Better performance (Starship is faster)
