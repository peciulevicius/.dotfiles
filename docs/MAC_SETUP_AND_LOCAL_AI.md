# macOS Setup and Local AI Guide

This guide answers four things:
- What is missing from your current setup
- How to install everything quickly
- What each tool is for and when to use it
- What to install for local AI on a Mac mini M4 (16GB/256GB)

## Current State (from `scripts/dev-check.sh`)

Core environment is healthy. Missing items are mostly optional productivity tools:
- `gh`, `wget`
- `bat`, `eza`, `fd`, `fzf`, `zoxide`, `tlrc`, `httpie`, `git-delta`
- `nvm`, `pnpm`, `code`
- `starship`, optional runtimes (`go`, `rust`)

## Install Everything You Listed

### CLI tools (recommended baseline)

```bash
brew install gh wget bat eza fd fzf zoxide tlrc httpie git-delta nvm pnpm starship
```

### GUI app (if you want VS Code)

```bash
brew install --cask visual-studio-code
```

### Optional language toolchains

```bash
brew install go rust
```

### After installing `nvm`

```bash
mkdir -p ~/.nvm
source ~/.zshrc
nvm install --lts
nvm alias default 'lts/*'
```

## Do Your Dotfiles Handle This?

Mostly yes:
- Installers already include essentials and optional tools in `os/mac/`
- `scripts/dev-check.sh` checks health and now shows accurate required vs optional status
- `scripts/sync.sh` handles symlinks and config refresh

What is not fully automatic yet:
- Installing every optional GUI app by default (intentionally interactive/optional)
- Local AI stack (recommended to keep optional because of disk/RAM tradeoffs)

## Tool Cheat Sheet (What + When)

- `gh`: GitHub from terminal. Use for PRs, issues, auth.
- `wget`: quick file downloads, recursive/mirror-style fetch.
- `bat`: syntax-highlighted file viewing.
- `eza`: better `ls` with git status/icons.
- `rg` (`ripgrep`): fast code/text search.
- `fd`: fast file discovery.
- `fzf`: fuzzy picker for history/files/branches.
- `zoxide`: smart directory jumping (`z project`).
- `tlrc`: concise examples for commands (maintained replacement for old `tldr` formula on Homebrew).
- `httpie`: readable API calls (`http GET ...`).
- `jq`: JSON parsing/transform.
- `git-delta`: better colored git diffs.
- `nvm`: manage multiple Node versions safely.
- `pnpm`: fast, space-efficient Node package manager.
- `starship`: cross-shell prompt.

## Local AI on Mac mini M4 (16GB RAM, 256GB SSD)

For this hardware, prioritize efficient 7B/8B models and keep disk usage controlled.

### Recommended stack

1. `Ollama` for model management and serving
2. `Open WebUI` (or another lightweight UI) for chat UX
3. Optional `llama.cpp` for low-level tuning/benchmarking

### Install

```bash
brew install ollama
brew install llama.cpp
```

Start Ollama:

```bash
ollama serve
```

Pull practical models (start small):

```bash
ollama pull llama3.1:8b
ollama pull qwen2.5-coder:7b
```

### About the tools you mentioned

- Ollama: best default choice for local model lifecycle.
- OpenClaw: UI option; use if you prefer this UX, but keep one UI to avoid bloat.
- GPT4All: all-in-one desktop app; good for quick start, less flexible than CLI-first stack.
- llama.cpp: best for advanced control, quantization experiments, benchmarking.
- Core ML variants: useful for Apple Silicon optimization; good once baseline setup is stable.

## Storage and Performance Advice for 16GB/256GB

- Keep only 2-3 active models locally.
- Prefer 7B/8B quantized models for responsiveness.
- Avoid many 14B+ models on internal disk.
- Consider external SSD for model cache if you expand model library.

## Suggested Next Steps

1. Install baseline CLI tools now (`brew install ...` above).
2. Re-run `scripts/dev-check.sh`.
3. Add Ollama + one coding model first (`qwen2.5-coder:7b`).
4. Add a UI only if you actually need browser/chat workflows.
