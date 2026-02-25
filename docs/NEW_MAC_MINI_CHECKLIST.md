# New Mac Mini Checklist

Target: Mac mini M4 (16GB RAM / 256GB SSD)

## Install Plan

1. Clone repo

```bash
git clone https://github.com/peciulevicius/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

2. Run unified mac installer

```bash
./os/mac/install.sh --yes
```

3. Validate

```bash
scripts/dev-check.sh
```

## Local AI Baseline

Install includes local AI (`ollama`, `llama.cpp`) unless you skip that prompt.

Start Ollama:

```bash
brew services start ollama
```

Pull starter models:

```bash
ollama pull llama3.1:8b
ollama pull qwen2.5-coder:7b
```

## Storage Advice (256GB SSD)

- Keep only 2-3 local models at a time
- Prefer 7B/8B quantized models
- Move model cache to external SSD if library grows

## Optional Additions

- Wispr Flow (voice dictation): included via cask in core app prompt
- Open WebUI (for browser UI over Ollama)
- Docker Desktop (already included)

## Final Manual Steps

- `gh auth login`
- `ssh-add ~/.ssh/id_ed25519`
- Log in to VS Code / JetBrains / Bitwarden / Claude as needed
