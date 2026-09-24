# Start here

This repository holds workstation dotfiles for macOS, Linux and Windows, and
the configuration and documentation for a self-hosted homelab running on a Mac
mini with a UGREEN NAS.

---

## 1. Install

=== "macOS"

    ```bash
    git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
    cd ~/.dotfiles && ./install.sh
    ```

    Full guide: [HOW_TO_INSTALL.md](./HOW_TO_INSTALL.md)

=== "Linux (Arch / Ubuntu / Debian)"

    ```bash
    git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
    cd ~/.dotfiles && ./install.sh   # detects the distribution
    ```

=== "Windows (PowerShell)"

    Windows support covers Claude Code configuration and package updates via
    winget. For the full shell environment, use WSL.

    ```powershell
    # One-time: allow local scripts to run
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

    git clone https://github.com/peciulevicius/.dotfiles.git $HOME\.dotfiles
    cd $HOME\.dotfiles
    .\scripts\setup\setup-claude.ps1
    ```

=== "WSL"

    ```bash
    git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
    cd ~/.dotfiles && ./install.sh   # detects WSL
    ```

Verify the installation:

```bash
scripts/dev-check.sh
```

---

## 2. Set up Claude Code

Installs agents, skills, rules and commands into `~/.claude/`.

=== "macOS / Linux / WSL"

    ```bash
    scripts/setup/setup-claude.sh   # interactive menu; option 1 installs everything
    ```

=== "Windows (PowerShell)"

    ```powershell
    .\scripts\setup\setup-claude.ps1
    ```

=== "Windows (CMD)"

    ```cmd
    scripts\setup\setup-claude.bat
    ```

Full guide: [CLAUDE_CODE_GUIDE.md](./CLAUDE_CODE_GUIDE.md)

---

## 3. Command-line tools

- [MODERN_CLI_TOOLS.md](./MODERN_CLI_TOOLS.md) — bat, eza, fzf, zoxide, ripgrep and others
- [tutorials/TOOL_TUTORIALS.md](./tutorials/TOOL_TUTORIALS.md) — official documentation and video links

---

## 4. Maintenance

=== "macOS / Linux"

    ```bash
    scripts/update.sh                   # update package managers and Claude Code
    scripts/dev-check.sh                # health check
    scripts/backup/backup-dotfiles.sh   # back up configuration files
    ```

=== "Windows (PowerShell)"

    ```powershell
    .\scripts\update.ps1   # update winget, npm, pnpm and Claude Code
    ```

---

## 5. Documentation map

### Homelab operations

| Task | Document |
|---|---|
| Outstanding work | [HOME_SERVER_TODO.md](./HOME_SERVER_TODO.md) |
| Completed work and the reasons behind it | [HOME_SERVER_CHANGELOG.md](./HOME_SERVER_CHANGELOG.md) — check before proposing changes; several approaches were tried and reverted |
| Memory, drive layout, container paths, backups | [HOME_SERVER_REFERENCE.md](./HOME_SERVER_REFERENCE.md) |
| Setting up a Mac mini from scratch | [HOME_SERVER_REFERENCE.md](./HOME_SERVER_REFERENCE.md) and [SERVICES.md](./SERVICES.md). [HOME_SERVER.md](./HOME_SERVER.md) describes the pre-NAS architecture and is historical. |
| Services and ports | [SERVICES.md](./SERVICES.md) |
| NAS storage and mounts | [NAS.md](./NAS.md) |
| Scripts | [UTILITY_SCRIPTS.md](./UTILITY_SCRIPTS.md) |
| Scheduled jobs | [scripts/cron/README.md](https://github.com/peciulevicius/.dotfiles/blob/main/scripts/cron/README.md) |
| Credential inventory (no secrets) | [CREDENTIAL_MIGRATION.md](./CREDENTIAL_MIGRATION.md) |

### Project guides

Each guide records decisions already made and the options ruled out. Read it
before reopening the topic.

| Project | Guide | State |
|---|---|---|
| Email | [guides/EMAIL.md](./guides/EMAIL.md) | In progress: Cloudflare Email Routing live (receive only); cutover to Purelymail pending |
| De-Googling | [guides/DEGOOGLE.md](./guides/DEGOOGLE.md), [alternatives](./guides/DEGOOGLE_ALTERNATIVES.md) | Mostly complete; remaining: 2FA, email, calendar/contacts |
| Notes | [guides/NOTES.md](./guides/NOTES.md) | Vault and Kindle import running; mobile sync setup pending |
| Books and Kindle | [guides/BOOKS.md](./guides/BOOKS.md), [Kindle setup](./guides/KINDLE_SETUP.md) | Kindle jailbroken; KOReader, OPDS and read-along working |
| Self-hosted AI | [guides/SELF_HOSTED_AI.md](./guides/SELF_HOSTED_AI.md) | Odysseus running on port 7001 with native Ollama |
| Octopus Deploy | [guides/OCTOPUS_DEPLOY.md](./guides/OCTOPUS_DEPLOY.md) | Not deployed (insufficient memory) |

### Automation and repository safety

| Component | Purpose |
|---|---|
| `.claude/skills/` | Project skills: `homelab-service`, `credential-rotation`, `homelab-audit` |
| `scripts/utils/homelab-audit.sh` | Weekly health audit (cron → Discord on failure) |
| `.githooks/pre-commit` | gitleaks scan that blocks commits containing secrets |
| `.github/workflows/checks.yml` | gitleaks, shellcheck and a strict docs build on every push |

### Where to record changes

| Content | File |
|---|---|
| Outstanding work | `HOME_SERVER_TODO.md` |
| Completed work, with the reason | `HOME_SERVER_CHANGELOG.md` |
| Facts about the machine | `HOME_SERVER_REFERENCE.md` |
| Decisions on a project | That project's guide |

> **Warning:** This repository is public. Passwords, tokens and webhook URLs
> belong in `~/services/<svc>/.env`, `~/.config/homelab/` or Vaultwarden, never
> in a tracked file.
