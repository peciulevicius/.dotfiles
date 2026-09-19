# Start Here

New to this repo? Follow this order.

---

## 1) Install on Your Machine

=== "macOS"

    ```bash
    git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
    cd ~/.dotfiles && ./install.sh
    ```

    Full guide: [HOW_TO_INSTALL.md](./HOW_TO_INSTALL.md)

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
    .\scripts\setup\setup-claude.ps1
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
    scripts/setup/setup-claude.sh   # shows an interactive menu — pick 1
    ```

=== "Windows (PowerShell)"

    ```powershell
    .\scripts\setup\setup-claude.ps1
    ```

=== "Windows (CMD)"

    ```cmd
    scripts\setup\setup-claude.bat
    ```

Full guide: [Claude Code Guide](./CLAUDE_CODE_GUIDE.md)

---

## 3) Learn the Tools

- [Modern CLI Tools](./MODERN_CLI_TOOLS.md) — bat, eza, fzf, zoxide, ripgrep, and more
- [Tool Tutorials](./tutorials/TOOL_TUTORIALS.md) — official docs and video links

---

## 4) Daily Maintenance

=== "macOS / Linux"

    ```bash
    scripts/update.sh     # update all package managers + Claude Code
    scripts/dev-check.sh  # health check
    scripts/backup/backup-dotfiles.sh     # backup configs
    ```

=== "Windows (PowerShell)"

    ```powershell
    .\scripts\update.ps1  # update winget, npm, pnpm, Claude Code
    ```

---

## 5) Find Anything — the map

### Running the homelab

| I want to… | Go to |
|---|---|
| **See what needs doing next** | [HOME_SERVER_TODO.md](./HOME_SERVER_TODO.md) — outstanding work only |
| See what's already been done, and why | [HOME_SERVER_CHANGELOG.md](./HOME_SERVER_CHANGELOG.md) — **check before proposing anything**; several ideas were tried and reverted |
| Look up RAM, drive layout, container paths | [HOME_SERVER_REFERENCE.md](./HOME_SERVER_REFERENCE.md) |
| Set up a Mac mini from scratch | [HOME_SERVER.md](./HOME_SERVER.md) |
| See what each service is and its port | [SERVICES.md](./SERVICES.md) |
| Understand the NAS and its mounts | [NAS.md](./NAS.md) |
| Know what the scripts do | [UTILITY_SCRIPTS.md](./UTILITY_SCRIPTS.md) |
| Change a password and not break things | [CREDENTIALS.md](./CREDENTIALS.md) |
| Fix or add a scheduled job | [../scripts/cron/README.md](../scripts/cron/README.md) |

### The long-running projects

Each has a guide holding the decisions already made. **Read the guide before
reopening the topic** — they record what was ruled out and why.

| Project | Guide | State |
|---|---|---|
| De-Googling | [guides/DEGOOGLE.md](./guides/DEGOOGLE.md) · [alternatives](./guides/DEGOOGLE_ALTERNATIVES.md) | ~90% done. Gaps: email, phone, calendar, AI |
| Notes / PKM | [guides/NOTES.md](./guides/NOTES.md) | Vault + sync exist; capture friction is the real problem |
| Books + Kindle | [guides/BOOKS.md](./guides/BOOKS.md) | Jailbreak decided; waiting on KOReader Scribe support |
| Self-hosted AI | [guides/SELF_HOSTED_AI.md](./guides/SELF_HOSTED_AI.md) | Not started. Odysseus on port 7000 (which is taken) |
| Octopus Deploy | [guides/OCTOPUS_DEPLOY.md](./guides/OCTOPUS_DEPLOY.md) | ❌ Ruled out on RAM — don't re-research |

### Which file do I write in?

- A thing **to do** → `HOME_SERVER_TODO.md`
- A thing **done** → move it to `HOME_SERVER_CHANGELOG.md`, with the *why*
- A **fact** about the machine → `HOME_SERVER_REFERENCE.md`
- A **decision** on a long-running topic → that topic's guide
