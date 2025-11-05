# Arch Installer - What Actually Happens

## Current Flow (Step by Step)

When you run `./os/linux/install_arch.sh`:

### 1. Confirmation Prompt
```
This will set up your Arch Linux development environment to match your Mac setup.
Continue? (y/n)
```

### 2. Install Essentials (automatic)
✅ **Always installed without asking:**
- git
- github-cli (gh command)
- curl, wget
- base-devel (needed for compiling)
- openssh

### 3. Install Developer CLI Tools (automatic)
✅ **Always installed without asking:**
- docker
- nodejs, npm
- zsh

✅ **AUR packages (installs yay if needed):**
- nvm (Node version manager)
- pnpm-bin (fast npm alternative)

### 4. Setup Zsh (asks)
```
Install Powerlevel10k theme? (y/n)
```
- If yes: Clones p10k to Oh My Zsh directory
- If no: You get basic prompt from .zshrc

### 5. Install GUI Applications (asks)
```
This will install your standard app suite:
  • Google Chrome
  • VS Code
  • NordPass + NordVPN
  • Figma
  • Notion

Install all GUI applications? (y/n)
```

✅ **If yes, installs:**
- google-chrome
- visual-studio-code-bin
- nordpass-bin
- nordvpn-bin
- figma-linux
- notion-app

❌ **NOT INSTALLED:**
- Bitwarden (missing - should this replace NordPass?)
- Claude Code (only shows instructions)

### 6. Install JetBrains Toolbox (asks)
```
Install JetBrains Toolbox (for WebStorm)? (y/n)
```
- If yes: Installs jetbrains-toolbox
- Then shows instructions for WebStorm setup

### 7. Claude Code (manual only)
❌ **NOT AUTOMATED:**
```
Claude Code needs to be downloaded manually:
  1. Visit: https://claude.ai/download
  2. Download the Linux .deb or .AppImage
  3. Install with: sudo pacman -U <package>.pkg.tar.zst

Open Claude Code download page? (y/n)
```
- Just opens browser to download page

### 8. Optional Apps (asks for each)
```
Install spotify? (y/n)
Install discord? (y/n)
Install slack-desktop? (y/n)
Install postman-bin? (y/n)
```

### 9. Setup Dotfiles (automatic)
✅ **Always done:**
- Clones dotfiles repo if not present
- Creates symlinks:
  - ~/.gitconfig
  - ~/.zshrc
  - ~/.ideavimrc
  - ~/.p10k.zsh

### 10. Setup SSH (asks)
```
Generate SSH key? (y/n)
```
- Creates ed25519 key
- Adds to ssh-agent
- Shows public key to add to GitHub

### 11. GitHub CLI Auth (asks)
```
Authenticate with GitHub now? (y/n)
```
- Runs `gh auth login` interactively

### 12. Enable Docker (automatic)
✅ **Always done:**
- Enables docker service
- Adds user to docker group
- ⚠️ Requires logout to take effect

### 13. Change Shell to Zsh (automatic)
✅ **Always done:**
- Sets zsh as default shell
- ⚠️ Requires logout to take effect

### 14. Summary
Shows what was installed and what still needs to be done manually.

---

## What's MISSING

### ❌ Not Automated:
1. **Claude Code** - Only shows download link
2. **Bitwarden** - Not included at all (you mentioned using it)
3. **Fonts** - No Nerd Fonts installed (needed for p10k icons)

### ⚠️ Requires Manual Steps After:
1. Download Claude Code manually
2. Open JetBrains Toolbox, install WebStorm
3. Enable IdeaVim plugin in WebStorm
4. Sign into NordPass/Bitwarden
5. Sign into NordVPN
6. **Log out and back in** (for docker group and zsh)

---

## What Could Be Better

### 1. Claude Code
**Current:** Manual download
**Could be:**
- Check AUR for `claude-desktop` or similar package
- Or script the download + installation
- Or use Flatpak/AppImage auto-install

### 2. Bitwarden vs NordPass
**Current:** Only NordPass
**Should:**
- Ask which password manager you use
- Or install both
- Which do you actually use?

### 3. Fonts
**Current:** Not installed
**Should:**
- Install Nerd Fonts (Meslo, FiraCode)
- Needed for p10k icons to display correctly

### 4. JetBrains Toolbox
**Current:** Installs but requires manual WebStorm setup
**Could be:**
- Script to auto-configure WebStorm settings
- Or at least better instructions

### 5. Oh My Zsh
**Current:** Not installed
**Should:**
- Install Oh My Zsh if using p10k
- Or clarify p10k works standalone

---

## Questions for You

1. **Password Manager:** Do you use NordPass or Bitwarden or both?
2. **Claude Code:** Want me to try to automate this via AUR or AppImage?
3. **Fonts:** Should I auto-install Nerd Fonts?
4. **Oh My Zsh:** Should I install this too or keep p10k standalone?
5. **Any other apps missing?** Think about what you use daily.

---

## What I Should Add

Based on your needs, I think I should:

1. ✅ Add Bitwarden (or replace NordPass?)
2. ✅ Try to automate Claude Code (check AUR for `claude-desktop-bin`)
3. ✅ Install Nerd Fonts automatically
4. ✅ Add Oh My Zsh installation (needed for p10k in Arch script)
5. ✅ Better post-install instructions
6. ✅ Maybe add more dev tools (Docker Compose, etc.)

Should I make these updates?
