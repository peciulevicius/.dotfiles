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

### Local AI (optional prompt during install)

- `ollama` — model manager + local inference server
- `llama.cpp` — low-level inference, benchmarking, fallback

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
- `AI_FORMULAS` — local AI tools (Ollama, llama.cpp)
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

## Local AI

For Mac mini M4 (16GB RAM / 256GB SSD) or any Apple Silicon Mac.

### Get Running

1. Start Ollama service

```bash
brew services start ollama
```

2. Pull a coding model

```bash
ollama pull qwen2.5-coder:7b
```

3. Run a prompt

```bash
ollama run qwen2.5-coder:7b "Write a Python script that renames files by date"
```

4. Check loaded models

```bash
ollama list
ollama ps
```

### Suggested Models

Start with these on 16GB RAM:

```bash
ollama pull llama3.1:8b       # general purpose
ollama pull qwen2.5-coder:7b  # coding tasks
```

Avoid 14B+ models on internal SSD — they saturate RAM and disk.

### Native vs Docker

- Run `ollama` **natively** on macOS — better Apple Silicon GPU/Metal integration
- Run optional UIs (Open WebUI) **in Docker** — stateless, easy to remove

### Optional Browser UI (Open WebUI)

```bash
docker run -d \
  --name open-webui \
  -p 3000:8080 \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -v open-webui:/app/backend/data \
  --restart unless-stopped \
  ghcr.io/open-webui/open-webui:main
```

Open: `http://localhost:3000`

### Storage Advice (256GB SSD)

- Keep 2–3 active models at a time
- Prefer 7B/8B quantized models
- Move model cache to external SSD if the library grows

### Troubleshooting Ollama

If Ollama crashes with an MLX/Metal exception (`NSRangeException`):

1. Run from a normal GUI session (not a restricted shell)
2. Restart Mac and retry
3. Reinstall:

```bash
brew reinstall ollama
```

4. Try the cask variant instead:

```bash
brew uninstall ollama
brew install --cask ollama
```

5. Use `llama.cpp` as fallback:

```bash
llama-cli -m /path/to/model.gguf -p "Hello"
```

---

## Remote Access (Mac mini at home)

Use the Mac mini as a home server — access it from laptop or phone anywhere.

### Recommended Architecture

- Mac mini runs `ollama` on `localhost:11434`
- Optional: Open WebUI in Docker on `localhost:3000`
- Remote access via Tailscale + SSH (no open ports, no port forwarding needed)

### 1) On the Mac mini

```bash
brew services start ollama
# optional: start Open WebUI via Docker (see Local AI section above)
```

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

Use tmux for persistent sessions:

```bash
tmux new -s dev
```

Tunnel Ollama API to local laptop (so local tools can call it):

```bash
ssh -N -L 11434:localhost:11434 youruser@<mac-mini-tailnet-ip>
```

Now `http://localhost:11434` on the laptop routes to the Mac mini.

Tunnel Open WebUI:

```bash
ssh -N -L 3000:localhost:3000 youruser@<mac-mini-tailnet-ip>
```

Open `http://localhost:3000` in laptop browser.

VS Code Remote SSH also works — connect directly and edit/run on the mini.

### 4) From Phone

- Tailscale app → open browser to `http://<mac-mini-tailnet-ip>:3000`
- SSH client app (e.g., Termius) → connect and use CLI/tmux

### Security Rules

- Keep Ollama bound to `localhost` — never expose `11434` to the internet
- Use Tailscale + SSH tunnels instead of open ports
- SSH keys only, disable password auth
- Long passwords + 2FA on all accounts

### Troubleshooting

```bash
brew services restart ollama          # Ollama not responding
docker logs open-webui                # Open WebUI issues
# SSH: verify Remote Login is enabled + correct tailnet IP
```
