# Local AI Setup (Mac mini + Laptop)

This is the practical setup/run guide for your stack.

## What You Have

From your dotfiles installer:
- `ollama` (model manager + local inference server)
- `llama.cpp` (`llama-cli` for low-level local inference)

Optional (off by default) in installer prompt:
- `codex`
- `claude-code`
- `opencode-desktop`

## Is Ollama an App or Terminal?

- Installed via Homebrew formula: terminal-first workflow.
- You can run it as a background service (`brew services start ollama`).
- If you want a chat UI, use a separate UI layer (see Open WebUI below).
- If you want cloud coding-agent apps, install optional casks from installer prompt.

## Minimal "Get Running" Flow

1. Start Ollama service

```bash
brew services start ollama
```

2. Pull one coding model

```bash
ollama pull qwen2.5-coder:7b
```

3. Run first prompt

```bash
ollama run qwen2.5-coder:7b "Write a Python script that renames files by date"
```

4. Check loaded models

```bash
ollama list
ollama ps
```

This flow is enough to run local AI without Codex/Claude subscriptions.

## Optional UI (Browser Chat)

Run Open WebUI with Docker and connect to local Ollama:

```bash
docker run -d \
  --name open-webui \
  -p 3000:8080 \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -v open-webui:/app/backend/data \
  --restart unless-stopped \
  ghcr.io/open-webui/open-webui:main
```

Then open: `http://localhost:3000`

## Remote Workflow (Mac mini at home, laptop anywhere)

Recommended secure path:

1. Install Tailscale on both devices and join same tailnet.
2. Enable SSH on Mac mini (`System Settings -> General -> Sharing -> Remote Login`).
3. SSH from laptop:

```bash
ssh youruser@<mac-mini-tailscale-ip>
```

4. Keep coding sessions persistent with tmux:

```bash
tmux new -s dev
```

5. (Optional) Use VS Code Remote SSH to edit/run directly on Mac mini.

6. (Optional) Tunnel Ollama API to laptop for local tools:

```bash
ssh -N -L 11434:localhost:11434 youruser@<mac-mini-tailscale-ip>
```

Now laptop can call `http://localhost:11434` securely through SSH tunnel.

## Suggested Model Strategy (16GB RAM / 256GB SSD)

- Keep 1-2 active models.
- Prefer 7B/8B quantized models.
- Add larger models only if needed.
- Move model cache to external SSD if library grows.

## Known Issue Seen on Current Machine

On this machine, `ollama` crashes immediately with an MLX/Metal exception (`NSRangeException`, no Metal device selected).

If you hit this:

1. Ensure you run from a normal logged-in GUI user session (not restricted shell context).
2. Restart Mac and try again.
3. Reinstall Ollama:

```bash
brew reinstall ollama
```

4. Try the app/cask variant instead:

```bash
brew uninstall ollama
brew install --cask ollama
```

5. Use `llama.cpp` as fallback while debugging Ollama:

```bash
llama-cli -m /path/to/model.gguf -p "Hello"
```

## Day-2 Operations

Update everything:

```bash
scripts/update.sh
```

Check environment health:

```bash
scripts/dev-check.sh
```
