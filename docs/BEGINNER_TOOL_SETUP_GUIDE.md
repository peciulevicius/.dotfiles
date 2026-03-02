# Beginner Tool Setup Guide (Mac)

This guide explains every tool installed by `os/mac/install.sh` in plain language:
- What it is
- Why you might use it
- What to do right after install

If you have not run installer yet:

```bash
./os/mac/install.sh
```

## 1. Core CLI Tools (Terminal)

### `git`

What it does:
- Tracks code changes and lets you commit/push to GitHub.

Setup:
1. Set your identity:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "you@example.com"
   ```
2. Verify:
   ```bash
   git config --global --list | rg 'user.name|user.email'
   ```

### `gh` (GitHub CLI)

What it does:
- Lets you use GitHub from terminal (auth, PRs, issues).

Setup:
1. Login:
   ```bash
   gh auth login
   ```
2. Verify:
   ```bash
   gh auth status
   ```

### `wget`

What it does:
- Downloads files from URLs.

Setup:
1. Test:
   ```bash
   wget -O /tmp/example.html https://example.com
   ls -lh /tmp/example.html
   ```

### `bat`

What it does:
- Better `cat` with colors and line numbers.

Setup:
1. Test:
   ```bash
   bat ~/.zshrc
   ```

### `eza`

What it does:
- Better `ls` with readable output.

Setup:
1. Test:
   ```bash
   eza -la --git
   ```

### `ripgrep` (`rg`)

What it does:
- Very fast text search in files.

Setup:
1. Test:
   ```bash
   rg "alias" ~/.dotfiles/config/zsh/.zshrc
   ```

### `fd`

What it does:
- Very fast file finder.

Setup:
1. Test:
   ```bash
   fd zsh ~/.dotfiles
   ```

### `fzf`

What it does:
- Interactive fuzzy picker for files/history.

Setup:
1. Test:
   ```bash
   history | fzf
   ```

### `zoxide`

What it does:
- Smart folder jumping based on your usage.

Setup:
1. Visit a few folders:
   ```bash
   cd ~/.dotfiles
   cd ~
   ```
2. Jump quickly:
   ```bash
   z dotfiles
   ```

### `tlrc` (`tldr` command)

What it does:
- Short examples for commands.

Setup:
1. Test:
   ```bash
   tldr git
   ```

### `httpie` (`http`)

What it does:
- Human-friendly API requests.

Setup:
1. Test:
   ```bash
   http GET https://httpbin.org/get
   ```

### `jq`

What it does:
- Reads and transforms JSON.

Setup:
1. Test:
   ```bash
   echo '{"name":"alex","age":30}' | jq '.name'
   ```

### `git-delta` (`delta`)

What it does:
- Better colored diffs for Git.

Setup:
1. Test in any git repo:
   ```bash
   git diff
   ```

### `nvm`

What it does:
- Manages Node.js versions safely.

Setup:
1. Install LTS Node:
   ```bash
   nvm install --lts
   nvm alias default 'lts/*'
   ```
2. Verify:
   ```bash
   node -v
   npm -v
   ```

### `pnpm`

What it does:
- Fast package manager for JavaScript/TypeScript projects.

Setup:
1. Verify:
   ```bash
   pnpm -v
   ```
2. Optional first project test:
   ```bash
   mkdir -p /tmp/pnpm-test && cd /tmp/pnpm-test
   pnpm init
   ```

### `starship`

What it does:
- Fast shell prompt with git/language info.

Setup:
1. Open new terminal tab.
2. Verify command:
   ```bash
   starship --version
   ```
3. Customize prompt:
   - Edit `config/starship/starship.toml`

## 2. Local AI Tools

### `ollama`

What it does:
- Runs LLMs locally on your machine.

Setup:
1. Start service:
   ```bash
   brew services start ollama
   ```
2. Pull a model:
   ```bash
   ollama pull qwen2.5-coder:7b
   ```
3. Run:
   ```bash
   ollama run qwen2.5-coder:7b "Write a hello world in Python"
   ```
4. Verify:
   ```bash
   ollama list
   ollama ps
   ```

### `llama.cpp`

What it does:
- Low-level local inference/benchmarking tools.

Setup:
1. Verify binary:
   ```bash
   llama-cli --help
   ```
2. Use when you want advanced tuning or fallback testing.

For full local AI flow:
- `docs/ai/LOCAL_AI_SETUP.md`
- `docs/ai/REMOTE_ACCESS.md`

## 3. Core Apps (GUI)

### `google-chrome`

What it does:
- Main browser.

Setup:
1. Open Chrome once from Applications.
2. Sign in to sync bookmarks/passwords if desired.
3. Optional: set as default browser in macOS settings.

### `brave-browser`

What it does:
- Privacy-focused second browser.

Setup:
1. Open Brave once and complete first-run wizard.
2. Optional: import bookmarks from Chrome.

### `visual-studio-code`

What it does:
- Primary code editor.

Setup:
1. Open VS Code.
2. Install essential extensions (GitHub Copilot, ESLint, Prettier, etc. as needed).
3. Enable shell command:
   - Command Palette -> "Shell Command: Install 'code' command in PATH"
4. Verify:
   ```bash
   code --version
   ```

### `docker`

What it does:
- Runs containers for local services/dev environments.

Setup:
1. Open Docker Desktop and wait for "Engine running".
2. Verify:
   ```bash
   docker --version
   docker run --rm hello-world
   ```
3. Optional Open WebUI for local AI chat:
   - Follow `docs/ai/LOCAL_AI_SETUP.md`.

### `claude`

What it does:
- Claude desktop chat app.

Setup:
1. Open app from Applications.
2. Sign in.
3. Configure preferences (notifications, shortcuts) as you like.

### `bitwarden`

What it does:
- Password manager.

Setup:
1. Open app.
2. Sign in or create account.
3. Enable unlock method (password or biometrics).
4. Optional: install browser extension.

### `jetbrains-toolbox`

What it does:
- Installs and updates JetBrains IDEs.

Setup:
1. Open JetBrains Toolbox.
2. Sign in to your JetBrains account.
3. Install IDEs you use (WebStorm/IntelliJ/PyCharm).

### `discord`

What it does:
- Team/community chat.

Setup:
1. Open app and sign in.
2. Join your servers.
3. Adjust notification settings.

### `figma`

What it does:
- Design and collaborative UI tool.

Setup:
1. Open app and sign in.
2. Open or create team/project.
3. Optional: set app for opening `.fig` links by default.

### `wispr-flow`

What it does:
- Voice dictation workflow app.

Setup:
1. Open app.
2. Grant microphone permissions when prompted.
3. Complete onboarding and hotkey setup.

### `darktable`

What it does:
- Photo editing and RAW workflow.

Setup:
1. Open app.
2. Import a photo folder.
3. Confirm output/export directory.

### `calibre`

What it does:
- Ebook library manager and reader tool.

Setup:
1. Open app.
2. Choose library location.
3. Add books and test opening one.

### `logi-options+`

What it does:
- Logitech mouse/keyboard configuration.

Setup:
1. Open app.
2. Connect/sign in if required.
3. Pair device and set button mappings.

### `yt-music`

What it does:
- YouTube Music desktop app.

Setup:
1. Open app.
2. Sign in with Google account.
3. Set launch-at-login only if you want background playback.

### `the-unarchiver`

What it does:
- Opens zip/rar/7z and other archives.

Setup:
1. Open app once.
2. In preferences, choose archive file types to associate.

### `tg-pro`

What it does:
- Mac temperature/fan monitoring and controls.

Setup:
1. Open app.
2. Grant permissions it asks for.
3. Configure alert thresholds and menu bar display.

## 4. Optional Apps (Off by Default)

### `iterm2`

What it does:
- Advanced terminal alternative to Terminal.app.

Setup:
1. Open iTerm2.
2. Optional: set iTerm2 as default terminal.
3. Optional: import profile/theme if you have one.

### `raycast`

What it does:
- Fast launcher/workflow automation app.

Setup:
1. Open Raycast.
2. Set global hotkey (usually `Cmd + Space`, if replacing Spotlight).
3. Enable extensions you need.

## 5. Optional AI Coding-Agent Apps

### `claude-code`

What it does:
- Claude coding-agent desktop/launcher app.

Setup:
1. Open app.
2. Sign in.
3. Connect local projects/workspaces.
4. Review API/subscription usage settings.

### `opencode-desktop`

What it does:
- OpenCode desktop coding-agent client.

Setup:
1. Open app.
2. Sign in or configure API key.
3. Connect project folder and run first prompt.

## 6. Manual App

### Kindle app (manual install)

What it does:
- Read Kindle books on desktop.

Setup:
1. Install from Amazon/App Store.
2. Sign in.
3. Download a sample book to verify.

## 7. Final Verification (Noob-Friendly Checklist)

Run:

```bash
scripts/dev-check.sh
```

Then manually confirm:
1. Terminal opens and prompt looks correct.
2. `git`, `gh`, `node`, `pnpm`, `docker` commands work.
3. At least one browser and one editor open successfully.
4. Ollama runs one prompt if local AI was installed.
5. Password manager and key daily apps launch/sign in.

