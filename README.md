# .dotfiles

Cross-platform dotfiles for macOS, Linux (Arch, Debian/Ubuntu, Kali) and
Windows/WSL, plus the configuration and documentation for a self-hosted homelab
(Mac mini + UGREEN NAS).

- **Shell and CLI:** Zsh with Starship, and modern replacements for common
  tools (bat, eza, ripgrep, fd, fzf, zoxide, tldr, httpie, jq, delta).
- **Configuration:** git (50+ aliases, commit template, optional GPG signing),
  SSH, tmux, EditorConfig, IdeaVim, Neovim, Claude Code.
- **Installers:** OS-specific, interactive, with backups of any files they
  replace.
- **Maintenance scripts:** update, backup, cleanup and environment health
  checks.
- **Homelab:** Docker Compose stacks for about 25 services (Immich,
  Vaultwarden, Nextcloud, Jellyfin and others), Cloudflare R2 backups,
  monitoring and audit scripts.
- **Documentation:** in `docs/`, published with MkDocs.

## Quick start

```bash
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh          # detects the OS
```

Non-interactive on macOS: `./os/mac/install.sh --yes`

Start with [docs/START_HERE.md](docs/START_HERE.md); the full walkthrough is in
[docs/HOW_TO_INSTALL.md](docs/HOW_TO_INSTALL.md).

## Supported platforms

| Platform | Support | Installer |
|---|---|---|
| macOS 12+ | Full | `os/mac/install.sh` |
| Arch Linux | Full | `os/linux/install_arch.sh` |
| Ubuntu / Debian / Kali | Full | `os/linux/install_ubuntu.sh` |
| Windows (PowerShell) | Claude Code configuration and package updates | `scripts/setup/setup-claude.ps1`, `scripts/update.ps1` |
| Windows (WSL) | Shell tools | `os/windows/install_wsl.sh` |

## What is installed

### Command-line tools

| Replaces | Tool | Benefit |
|---|---|---|
| `cat` | `bat` | Syntax highlighting, line numbers, git integration |
| `ls` | `eza` | Colours, icons, git status, tree view |
| `grep` | `rg` (ripgrep) | Faster; respects `.gitignore` |
| `find` | `fd` | Simpler syntax, faster |
| History search | `fzf` | Fuzzy finder (Ctrl+R) |
| `cd` | `z` (zoxide) | Jumps to frequently used directories |
| `man` | `tldr` (via `tlrc`) | Example-based help |
| `curl` | `http` (httpie) | Readable syntax for APIs |
| JSON processing | `jq` | Query and transform JSON |
| `git diff` | `delta` | Syntax-highlighted diffs |

Usage: [docs/MODERN_CLI_TOOLS.md](docs/MODERN_CLI_TOOLS.md).

### Development tools

git, GitHub CLI, Docker and Docker Compose, Node.js (nvm, npm, pnpm), VS Code,
JetBrains Toolbox and Claude Code.

### Configuration

Files in `config/` are symlinked into the home directory:

| Area | Files |
|---|---|
| git | `.gitconfig`, `.gitignore_global`, `.gitmessage` |
| Shell | `.zshrc` (platform detection, aliases), Starship |
| SSH | `config` template for multiple accounts |
| tmux | `.tmux.conf` with vim-style bindings |
| Editors | `.editorconfig`, `.ideavimrc`, Neovim |
| Claude Code | Agents, skills, rules, commands, settings |

Details: [docs/CONFIG_GUIDE.md](docs/CONFIG_GUIDE.md) and
[docs/SYMLINKS.md](docs/SYMLINKS.md).

### Scripts

```bash
~/.dotfiles/scripts/update.sh                   # update package managers and Claude Code
~/.dotfiles/scripts/sync.sh                     # pull the dotfiles and refresh symlinks
~/.dotfiles/scripts/backup/backup-dotfiles.sh   # archive configuration and package lists
~/.dotfiles/scripts/cleanup.sh                  # clear caches
~/.dotfiles/scripts/dev-check.sh                # environment health check
~/.dotfiles/scripts/setup/setup-gpg.sh          # GPG commit signing
```

```powershell
.\scripts\update.ps1               # Windows: winget, npm, pnpm, Claude Code
.\scripts\setup\setup-claude.ps1   # Windows: Claude Code configuration
```

Reference: [docs/UTILITY_SCRIPTS.md](docs/UTILITY_SCRIPTS.md).

## Repository layout

```
.dotfiles/
├── install.sh              # entry point; detects the OS
├── config/                 # configuration files (git, zsh, starship, ssh, tmux, nvim, claude, …)
├── os/
│   ├── mac/                # macOS installer, Brewfile, system defaults
│   ├── linux/              # Arch and Debian/Ubuntu/Kali installers
│   └── windows/            # WSL and PowerShell installers
├── scripts/                # maintenance, setup, backup and homelab scripts
├── services/               # Docker Compose stacks for the homelab
├── pkm/                    # Kindle Scribe → Obsidian import
├── wallpapers/             # desktop and Kindle wallpapers
└── docs/                   # documentation (MkDocs)
```

## Git aliases

The git configuration defines more than 50 aliases. Common ones:

| Alias | Action |
|---|---|
| `git st` | Short status |
| `git br` | Branches with last commit |
| `git lg` | Graph log |
| `git ac "message"` | Stage all and commit |
| `git amend` | Amend the last commit without editing the message |
| `git undo` | Undo the last commit, keeping changes |
| `git sync` | Pull, then push |
| `git cleanup` | Delete merged branches |
| `git aliases` | List all aliases |

Full list: [docs/CONFIG_GUIDE.md](docs/CONFIG_GUIDE.md).

## Customisation

| Change | Location |
|---|---|
| Packages | `os/mac/install.sh`, `os/linux/install_arch.sh`, `os/linux/install_ubuntu.sh` |
| Prompt | `config/starship/starship.toml` ([Starship configuration](https://starship.rs/config/)) |
| Machine-local aliases and settings | `~/.zshrc.local` (sourced by `.zshrc`, not tracked) |

## Troubleshooting

1. Run `~/.dotfiles/scripts/dev-check.sh`.
2. Check the relevant guide in `docs/`.
3. Re-run `./install.sh`; it is safe to repeat.

| Symptom | Fix |
|---|---|
| Prompt icons missing | Install a Nerd Font (MesloLGS NF or FiraCode Nerd Font), select it in the terminal, restart |
| CLI tools not found | Complete the installer, run `scripts/update.sh`, ensure `~/.local/bin` is on `PATH` |
| SSH authentication fails | `ssh-keygen -t ed25519 -C "you@example.com"`, `ssh-add ~/.ssh/id_ed25519`, add the key at <https://github.com/settings/keys> |
| Commits not verified on GitHub | Run `scripts/setup/setup-gpg.sh` and add the GPG key on GitHub |

## Homelab

The Mac mini homelab is documented separately:

- [docs/SERVICES.md](docs/SERVICES.md) — services and ports
- [docs/HOME_SERVER_REFERENCE.md](docs/HOME_SERVER_REFERENCE.md) — storage, backups, known behaviours
- [docs/HOME_SERVER_TODO.md](docs/HOME_SERVER_TODO.md) — outstanding work

## Credits

Built on the work of the authors of [bat](https://github.com/sharkdp/bat),
[eza](https://github.com/eza-community/eza),
[ripgrep](https://github.com/BurntSushi/ripgrep),
[fd](https://github.com/sharkdp/fd), [fzf](https://github.com/junegunn/fzf),
[zoxide](https://github.com/ajeetdsouza/zoxide),
[Oh My Zsh](https://ohmyz.sh) and [Starship](https://starship.rs).

## License

MIT.

## Author

Džiugas Pečiulevičius — [@peciulevicius](https://github.com/peciulevicius)
