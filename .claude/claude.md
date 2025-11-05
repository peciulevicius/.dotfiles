# Claude Code Assistant Instructions

This file contains instructions for AI assistants (like Claude Code) working with this dotfiles repository.

## 📚 Repository Overview

This is a cross-platform dotfiles repository that provides:
- **Consistent development environment** across macOS, Linux (Arch, Debian/Ubuntu), and Windows/WSL
- **Modern CLI tools** (bat, eza, ripgrep, fd, fzf, zoxide, etc.)
- **Comprehensive documentation** in the `docs/` folder
- **Utility scripts** for maintenance (update, backup, cleanup, health check)
- **Installation scripts** for automated setup on new machines

## 🎯 Core Principles

When working with this repository:

1. **Cross-platform compatibility** - All changes must work on macOS, Arch Linux, and Debian/Ubuntu
2. **Documentation-first** - Document everything thoroughly in the `docs/` folder
3. **User-friendly** - Installation should be simple and guided with clear prompts
4. **Non-destructive** - Always backup existing configurations before overwriting
5. **Modern tools** - Prefer modern CLI alternatives (bat over cat, eza over ls, etc.)

## 📁 Repository Structure

```
.dotfiles/
├── README.md                    # Main overview (keep concise)
├── install.sh                   # Main installer (detects OS)
├── docs/                        # All documentation
│   ├── README.md                # Documentation index
│   ├── QUICKSTART.md            # Quick start guide
│   ├── HOW_TO_INSTALL.md        # Complete installation guide
│   ├── CONFIG_GUIDE.md          # Configuration details
│   ├── MODERN_CLI_TOOLS.md      # CLI tools guide
│   └── UTILITY_SCRIPTS.md       # Scripts documentation
├── config/                      # Configuration files
│   ├── git/                     # Git config
│   ├── zsh/                     # Zsh config
│   ├── ssh/                     # SSH config template
│   ├── tmux/                    # Tmux config
│   ├── claude/                  # Claude Code settings
│   └── .editorconfig            # EditorConfig
├── os/                          # OS-specific installers
│   ├── mac/                     # macOS installers
│   ├── linux/                   # Linux installers
│   └── windows/                 # Windows/WSL installer
└── scripts/                     # Utility scripts
    ├── update.sh                # Update all packages
    ├── backup.sh                # Backup configs
    ├── cleanup.sh               # Clean caches
    ├── dev-check.sh             # Health check
    └── setup-gpg.sh             # GPG signing setup
```

## 🔧 Common Tasks

### Adding a New Config File

1. Create the config file in `config/` directory
2. Add symlink logic to relevant OS installers
3. Document it in `docs/CONFIG_GUIDE.md`
4. Update `docs/README.md` if it's a major addition

### Adding a New Tool

1. Add to package list in all OS installers (`os/mac/`, `os/linux/`)
2. Document usage in `docs/MODERN_CLI_TOOLS.md`
3. Add helpful aliases to `config/zsh/.zshrc`
4. Update installation guides

### Creating a New Script

1. Create script in `scripts/` directory
2. Make it executable: `chmod +x scripts/your-script.sh`
3. Use consistent formatting (colors, headers, success/error messages)
4. Document it in `docs/UTILITY_SCRIPTS.md`
5. Add usage example to relevant docs

### Updating Documentation

1. Keep docs in `docs/` folder (not root)
2. Update `docs/README.md` if adding new docs
3. Use clear headings and examples
4. Include troubleshooting sections
5. Cross-reference related docs

## 💡 Best Practices

### Installer Scripts

```bash
# Always include:
- OS detection
- Existing file/package checks
- Interactive prompts for optional items
- Backup of existing configs
- Clear success/error messages
- Post-installation summary
- Troubleshooting hints

# Example pattern:
if command -v tool &> /dev/null; then
    print_success "tool already installed"
else
    echo "Installing tool..."
    install_command
    print_success "tool installed"
fi
```

### Configuration Files

```bash
# Always include:
- Comments explaining what each section does
- Examples of usage
- Platform-specific notes
- Links to documentation

# Example:
# Git Configuration
# See: docs/CONFIG_GUIDE.md

[core]
    editor = vim        # Default editor for commit messages
    # ...
```

### Documentation

```markdown
# Use this structure:
## Overview (what it does)
## Installation (how to set up)
## Usage (how to use)
## Examples (practical examples)
## Troubleshooting (common issues)
## See Also (related docs)
```

## 🚨 Important Notes

### Git Configuration

The user's git config includes:
- Name: Džiugas Pečiulevičius
- Email: 43075730+peciulevicius@users.noreply.github.com
- 40+ useful git aliases
- Optional GPG commit signing

**Never modify these without explicit permission.**

### Platform-Specific Considerations

**macOS:**
- Uses Homebrew for package management
- Apple Silicon vs Intel paths differ
- Includes macOS preferences automation

**Arch Linux:**
- Uses pacman + yay (AUR)
- Bleeding edge packages
- User's primary Linux distro

**Debian/Ubuntu:**
- Uses apt
- More conservative package versions
- Includes Kali Linux support

**Windows/WSL:**
- Minimal WSL support
- Most development happens in WSL, not native Windows

### Modern CLI Tools Installed

Always consider these tools when suggesting commands:
- `bat` instead of `cat`
- `eza` instead of `ls`
- `rg` (ripgrep) instead of `grep`
- `fd` instead of `find`
- `fzf` for interactive selection
- `z` (zoxide) instead of `cd`
- `tldr` instead of `man`
- `http` (httpie) instead of `curl`
- `jq` for JSON processing
- `delta` for git diffs

## 🎨 User's Development Stack

### Tools & Apps
- **Browsers:** Google Chrome
- **IDEs:** WebStorm (primary), VS Code (secondary)
- **AI:** Claude Code (you!)
- **Password:** Bitwarden, NordPass
- **VPN:** NordVPN
- **Design:** Figma
- **Notes:** Notion
- **Containers:** Docker + Docker Compose

### Languages & Runtimes
- **Node.js:** via nvm
- **Package Managers:** npm, pnpm
- **Shell:** zsh with Starship prompt

### Not Used
- No nvim (uses IDEs instead)
- No stripe-cli, supabase, angular-cli (removed from installers)
- Removed bloat - only essential tools

## 📝 When Helping the User

### For Installation Questions
→ Direct to `docs/HOW_TO_INSTALL.md` or `docs/QUICKSTART.md`

### For Configuration Questions
→ Direct to `docs/CONFIG_GUIDE.md`

### For Tool Usage Questions
→ Direct to `docs/MODERN_CLI_TOOLS.md`

### For Script Usage
→ Direct to `docs/UTILITY_SCRIPTS.md`

### For Git Workflows
→ Reference git aliases in `.gitconfig`

### For New Machine Setup
```bash
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## 🔍 Common Questions & Answers

**Q: "How do I add a new config file?"**
→ See "Adding a New Config File" section above

**Q: "Should I use zsh/p10k?"**
→ Yes, but `.zshrc` has fallback prompt if p10k not installed

**Q: "Which Linux distros are supported?"**
→ Arch (primary), Debian, Ubuntu, Kali. Fedora/openSUSE would need new installer.

**Q: "Can I use this on Windows?"**
→ Yes, via WSL. Native Windows has minimal support.

**Q: "How often should I run update.sh?"**
→ Weekly, or before starting new projects

**Q: "Where do docs go?"**
→ All documentation goes in `docs/` folder, not root

**Q: "Should I create GitHub issues?"**
→ No, this is a personal repository. Just work directly with user.

## 🤝 Collaboration Guidelines

When the user asks you to:

1. **Add a new feature** → Add it to all relevant OS installers + document it
2. **Fix a bug** → Fix in all affected files + test on multiple OS
3. **Update docs** → Keep cross-references accurate
4. **Create a script** → Follow script patterns + document thoroughly
5. **Modify config** → Test on multiple shells/OS + add comments

## ⚠️ What NOT to Do

- ❌ Don't create files in root (except README.md, install.sh)
- ❌ Don't break cross-platform compatibility
- ❌ Don't add tools the user doesn't need
- ❌ Don't remove existing functionality without asking
- ❌ Don't create undocumented features
- ❌ Don't modify user's git name/email
- ❌ Don't make installers require sudo unnecessarily
- ❌ Don't create overly complex solutions

## ✅ What TO Do

- ✅ Test changes on multiple OS (or note which OS was tested)
- ✅ Add clear comments to all code
- ✅ Document everything in `docs/`
- ✅ Follow existing patterns and conventions
- ✅ Make installers interactive and user-friendly
- ✅ Backup before overwriting files
- ✅ Provide clear error messages
- ✅ Include troubleshooting steps

## 🎯 Success Criteria

Your changes are successful if:
1. ✅ They work on macOS, Arch, and Debian/Ubuntu
2. ✅ Documentation is complete and accurate
3. ✅ Existing functionality still works
4. ✅ Code follows repository patterns
5. ✅ User can understand and maintain it
6. ✅ Installation is smooth and guided

## 📞 Quick Reference Commands

```bash
# Install on new machine
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh

# Maintenance
~/.dotfiles/scripts/update.sh      # Update everything
~/.dotfiles/scripts/backup.sh      # Backup configs
~/.dotfiles/scripts/cleanup.sh     # Clean caches
~/.dotfiles/scripts/dev-check.sh   # Health check

# Quick access
alias dotfiles='cd ~/.dotfiles'
alias update='~/.dotfiles/scripts/update.sh'
alias backup='~/.dotfiles/scripts/backup.sh'
```

---

**Remember:** This is a living repository that the user actively maintains. Keep it clean, documented, and cross-platform compatible. When in doubt, ask the user before making significant changes!
