# Start Here

New to this repo? Follow this order.

---

## 1) Install on Your Machine

=== "macOS"

    ```bash
    git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
    cd ~/.dotfiles && ./install.sh
    ```

    Full guide: [macOS Setup](./MAC_SETUP.md)

=== "Linux (Arch / Ubuntu / Debian)"

    ```bash
    git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
    cd ~/.dotfiles && ./install.sh   # auto-detects your distro
    ```

=== "Windows (PowerShell)"

    Windows support covers Claude Code config and package updates via winget.
    For full shell tooling (zsh, starship, CLI tools), use WSL.

    ```powershell
    # One-time: allow scripts to run
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

    # Clone and set up Claude Code
    git clone https://github.com/peciulevicius/.dotfiles.git $HOME\.dotfiles
    cd $HOME\.dotfiles
    .\scripts\setup-claude.ps1
    ```

=== "WSL"

    ```bash
    git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
    cd ~/.dotfiles && ./install.sh   # auto-detects WSL
    ```

After installing, verify everything is working:

```bash
scripts/dev-check.sh
```

---

## 2) Set Up Claude Code

Installs agents, skills, rules, and commands into `~/.claude/`.

=== "macOS / Linux / WSL"

    ```bash
    scripts/setup-claude.sh   # shows an interactive menu — pick 1
    ```

=== "Windows (PowerShell)"

    ```powershell
    .\scripts\setup-claude.ps1
    ```

=== "Windows (CMD)"

    ```cmd
    scripts\setup-claude.bat
    ```

Full guide: [Claude Code Guide](./CLAUDE_CODE_GUIDE.md)

---

## 3) Learn the Tools

- [Modern CLI Tools](./MODERN_CLI_TOOLS.md) — bat, eza, fzf, zoxide, ripgrep, and more
- [Beginner Tool Setup Guide](./BEGINNER_TOOL_SETUP_GUIDE.md) — step-by-step for each tool
- [Tmux Guide](./TMUX_GUIDE.md) — terminal multiplexer
- [Tool Tutorials](./tutorials/TOOL_TUTORIALS.md) — official docs and video links

---

## 4) Daily Maintenance

=== "macOS / Linux"

    ```bash
    scripts/update.sh     # update all package managers + Claude Code
    scripts/dev-check.sh  # health check
    scripts/backup.sh     # backup configs
    ```

=== "Windows (PowerShell)"

    ```powershell
    .\scripts\update.ps1  # update winget, npm, pnpm, Claude Code
    ```
