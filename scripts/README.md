# Scripts

Quick reference for all scripts in this directory. Full docs: [../docs/UTILITY_SCRIPTS.md](../docs/UTILITY_SCRIPTS.md)

---

## When to run what

### New machine setup
```
install.sh                    ← always start here (detects OS, runs the right installer)
scripts/setup-claude.sh       ← set up Claude Code after install
scripts/setup-gpg.sh          ← (optional) GPG commit signing
```

`install.sh` at the root is the entry point for any OS. It delegates to:
- `os/mac/install.sh` on macOS
- `os/linux/install_arch.sh` or `install_ubuntu.sh` on Linux
- `os/windows/install_wsl.sh` on WSL

You can also run `os/mac/install.sh` directly if you know you're on macOS.

### Regular maintenance
```
scripts/update.sh             ← run weekly (updates packages + pulls dotfiles)
scripts/backup.sh             ← run before major changes
scripts/cleanup.sh            ← run monthly (frees disk space)
scripts/dev-check.sh          ← run when something seems broken
```

### Syncing dotfiles without updating packages
```
scripts/sync.sh               ← pull latest dotfiles from git + re-symlink configs
```

Use this when you just pulled changes and want configs to update — faster than running the full installer.

### Mac mini only
```
scripts/mac-mini.sh sleep off      ← run on first boot (disables sleep, enables auto-restart)
scripts/mac-mini.sh sleep on       ← re-enable normal sleep whenever needed
scripts/mac-mini.sh immich-setup   ← one-time Immich setup (run after drives are connected)
scripts/backup-immich.sh           ← manual photo backup (also runs nightly via cron)
```

### Docs site
```
scripts/docs.sh serve         ← preview docs at localhost:8000
scripts/docs.sh build         ← build static site (runs in CI)
```

---

## All scripts

| Script | What it does | Run on |
|--------|-------------|--------|
| `update.sh` | Updates Homebrew/apt/pacman, npm, pnpm, pip + pulls dotfiles | All machines, weekly |
| `sync.sh` | Pulls dotfiles from git + re-symlinks configs (no package updates) | All machines, as needed |
| `setup-claude.sh` | Syncs Claude Code config (agents, skills, rules, commands) | All machines, after install |
| `backup.sh` | Backs up config files + package lists to a timestamped `.tar.gz` | All machines, as needed |
| `backup-immich.sh` | Rsync Immich photos from T7 → T5 `ImmichBackup` | Mac mini only |
| `cleanup.sh` | Cleans package caches, Docker, IDE caches, temp files | All machines, monthly |
| `dev-check.sh` | Checks all dev tools are installed and configured | All machines |
| `setup-gpg.sh` | Sets up GPG key for signed commits | Once per machine |
| `docs.sh` | Serves or builds the MkDocs documentation site | Dev only |
| `mac-mini.sh` | Toggles sleep mode, runs one-time Immich setup | Mac mini only |

### Subdirectories
| Path | What it is |
|------|-----------|
| `utils/utils.sh` | Shared print/formatting functions used by Linux + Windows installers |
| `wallpapers/` | Wallpaper management script |

---

## backup.sh vs backup-immich.sh — what's the difference?

| | `backup.sh` | `backup-immich.sh` |
|--|--|--|
| **What** | Config files, package lists, dotfiles | Immich photo library |
| **Where to** | `~/dotfiles_backup_<timestamp>.tar.gz` | T5 `ImmichBackup` via rsync |
| **When** | Manually, before major changes | Nightly at 3am via cron |
| **Purpose** | Restore dev environment after wipe | Recover photos if T7 drive fails |

---

## install.sh (root) vs os/mac/install.sh — what's the difference?

`install.sh` at the root is the **cross-platform entry point**. It detects your OS and delegates:

```
install.sh  →  macOS?  →  os/mac/install.sh
            →  Arch?   →  os/linux/install_arch.sh
            →  Ubuntu? →  os/linux/install_ubuntu.sh
            →  WSL?    →  os/windows/install_wsl.sh
```

On a new Mac you can run either — they end up at the same place. On any other OS, always run `install.sh` from the root.
