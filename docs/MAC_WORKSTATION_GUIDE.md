# Mac Workstation Guide

This is the canonical guide for your laptop + Mac mini setup.

## Two-Script Model

1. Main installer: `os/mac/install.sh`
2. Optional macOS defaults: `os/mac/setup_macos_preferences.sh`

Everything else should be considered legacy documentation.

## What `setup_macos_preferences.sh` Does

It applies macOS `defaults` values for:
- Keyboard repeat and input behavior
- Finder visibility and list view defaults
- Dock behavior and animation speed
- Safari privacy/dev toggles
- Terminal UTF-8 and secure keyboard entry
- Screenshot format/location
- TextEdit plain-text defaults

It can restart Finder/Dock/SystemUIServer at the end.

Use it when you want opinionated OS defaults. Skip it if you prefer manual macOS settings.

## Unified Installer

- Interactive (recommended):

```bash
./os/mac/install.sh
```

- Non-interactive (accept defaults for prompts):

```bash
./os/mac/install.sh --yes
```

## Installed Tool Catalog (Current)

Defined in `os/mac/install.sh` with inline comments.

### Core CLI

- `git`, `gh`, `wget`
- `bat`, `eza`, `ripgrep`, `fd`, `fzf`, `zoxide`, `tlrc`, `httpie`, `jq`, `git-delta`
- `nvm`, `pnpm`, `starship`

### Local AI

- `ollama`
- `llama.cpp`

### Core Apps

- `google-chrome`, `brave-browser`
- `visual-studio-code`, `jetbrains-toolbox`, `claude`
- `docker`
- `bitwarden`
- `discord`, `figma`, `wispr-flow`
- `darktable`, `calibre`
- `logi-options+`, `yt-music`
- `the-unarchiver`, `tg-pro`

### Optional Apps (off by default)

- `iterm2`
- `raycast`

### Manual App

- Kindle app (install manually from Amazon/App Store)

## Clean Setup Notes

- Terminal.app is enough if you don’t need iTerm2 features.
- Spotlight is enough if you don’t need Raycast workflows.
- `nvm` is installed; Node versions should be installed with `nvm`, not `brew node`.

## Customize Later (Easy)

Edit one file:

- `os/mac/install.sh`

Change arrays:
- `CORE_FORMULAS`
- `AI_FORMULAS`
- `CORE_CASKS`
- `OPTIONAL_CASKS`

Then rerun installer. Already-installed packages are skipped.

## Updating Apps and Tools

### Recommended

```bash
scripts/update.sh
```

### Direct Homebrew

```bash
brew update
brew upgrade
brew upgrade --cask
brew cleanup
```

### Check what is outdated

```bash
brew outdated
```

### Update one specific app/tool

```bash
brew upgrade <formula>
brew upgrade --cask <cask>
```

## Remove What You Don’t Need

```bash
brew uninstall <formula>
brew uninstall --cask <cask>
```

Then run:

```bash
scripts/dev-check.sh
```
