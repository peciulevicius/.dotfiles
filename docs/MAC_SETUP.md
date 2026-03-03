# macOS Setup

Everything for setting up and running your Mac(s): installer, tools, local AI, remote access.

---

## Quick Setup (New Machine)

```bash
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./os/mac/install.sh
```

Non-interactive (accept all defaults):

```bash
./os/mac/install.sh --yes
```

Validate after install:

```bash
scripts/dev-check.sh
```

Final manual steps:

```bash
gh auth login
ssh-add ~/.ssh/id_ed25519
# Log in to VS Code / JetBrains / Bitwarden / Claude as needed
```

---

## Installer

Two scripts:

1. `os/mac/install.sh` — main installer (interactive, detects Apple Silicon vs Intel)
2. `os/mac/setup_macos_preferences.sh` — optional macOS `defaults` tweaks

### What `setup_macos_preferences.sh` does

Applies opinionated macOS defaults:
- Keyboard repeat and input behavior
- Finder visibility and list view
- Dock behavior and animation speed
- Safari privacy/dev toggles
- Terminal UTF-8 and secure keyboard entry
- Screenshot format and location
- TextEdit plain-text mode

Run it if you want these tweaks. Skip it if you prefer manual settings.

---

## What Gets Installed

### Core CLI

| Tool | Purpose |
|------|---------|
| `git`, `gh`, `wget` | Version control + GitHub CLI + downloads |
| `bat` | Syntax-highlighted file viewing (`cat` replacement) |
| `eza` | Better `ls` with git status and icons |
| `ripgrep` | Fast code/text search |
| `fd` | Fast file discovery |
| `fzf` | Fuzzy picker for history, files, branches |
| `zoxide` | Smart directory jumping (`z project`) |
| `tlrc` | Concise command examples |
| `httpie` | Readable API calls (`http GET ...`) |
| `jq` | JSON parsing and transform |
| `git-delta` | Better colored git diffs |
| `nvm` | Manage multiple Node versions |
| `pnpm` | Fast, space-efficient package manager |
| `starship` | Cross-shell prompt |

### Core Apps

- `google-chrome`, `brave-browser`
- `visual-studio-code`, `jetbrains-toolbox`, `claude`
- `docker`
- `bitwarden`
- `discord`, `figma`, `wispr-flow`
- `darktable`, `calibre`
- `logi-options+`, `yt-music`
- `the-unarchiver`, `tg-pro`

### Optional Apps (off by default, prompted during install)

- `iterm2`
- `raycast`

### Manual

- Kindle — install from Amazon or App Store

---

## Customizing

Edit one file: `os/mac/install.sh`

Change the arrays:
- `CORE_FORMULAS` — CLI tools always installed
- `CORE_CASKS` — GUI apps always installed
- `OPTIONAL_CASKS` — prompted during install

Then rerun. Already-installed packages are skipped.

---

## Maintenance

### Update everything

```bash
scripts/update.sh
```

### Direct Homebrew

```bash
brew update && brew upgrade && brew upgrade --cask && brew cleanup
```

### Check what's outdated

```bash
brew outdated
```

### Update one specific tool

```bash
brew upgrade <formula>
brew upgrade --cask <cask>
```

### Remove something

```bash
brew uninstall <formula>
brew uninstall --cask <cask>
scripts/dev-check.sh  # verify nothing broke
```

---

## Remote Access (Mac mini at home)

Access the Mac mini from your laptop or phone anywhere via Tailscale + SSH. No port forwarding.

### 1) On the Mac mini

Enable SSH:
`System Settings → General → Sharing → Remote Login`

### 2) Set Up Tailscale

1. Install Tailscale on Mac mini, laptop, and phone
2. Sign into the same tailnet account
3. That's it — devices see each other over a private network

**Alternative: Public SSH (without Tailscale)**

Possible, but higher risk. Only do this if you understand the tradeoffs:
1. Enable Remote Login on Mac mini
2. Port-forward `22` on your router to the Mac mini
3. Key-only auth, disable password login
4. Restrict by IP if possible

### 3) From Laptop

SSH into the Mac mini:

```bash
ssh youruser@<mac-mini-tailnet-ip>
```

Use tmux for persistent sessions that survive disconnects:

```bash
tmux new -s dev
# detach: Ctrl+B D  |  reattach: tmux attach -t dev
```

VS Code Remote SSH also works — connect and edit files directly on the mini.

Tunnel a port from Mac mini to laptop (e.g., local dev database):

```bash
ssh -N -L 5432:localhost:5432 youruser@<mac-mini-tailnet-ip>
```

### 4) From Phone

- Tailscale app → Immich at `http://<mac-mini-tailnet-ip>:2283`
- SSH client (e.g., Termius) → connect and use CLI/tmux

### Security Rules

- Use Tailscale + SSH tunnels instead of open ports
- SSH keys only, disable password auth
- Long passwords + 2FA on all accounts

### Troubleshooting

```bash
# SSH: verify Remote Login is enabled in System Settings + correct tailnet IP
tailscale status   # check all devices are connected
```
