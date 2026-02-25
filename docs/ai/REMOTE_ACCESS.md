# Remote AI Access (Mac mini at home)

Goal: use your Mac mini from laptop/phone while traveling.

## Recommended Architecture

- Mac mini runs:
  - `ollama` service on `localhost:11434`
  - Open WebUI in Docker on `localhost:3000` (optional)
- Secure remote access via Tailscale + SSH (no public open ports)

## 1) On Mac mini

```bash
# Start local LLM server
brew services start ollama

# Optional chat UI
scripts/ai/start-open-webui.sh
```

## 2) Set up secure network

1. Install Tailscale on Mac mini, laptop, and phone.
2. Sign into same tailnet account.
3. Enable macOS SSH on mini: `System Settings -> General -> Sharing -> Remote Login`.

## 3) From laptop

### CLI coding on remote mini

```bash
ssh youruser@<mac-mini-tailnet-ip>
```

Use tmux for persistent sessions:

```bash
tmux new -s dev
```

### Tunnel Ollama API to local laptop apps

```bash
ssh -N -L 11434:localhost:11434 youruser@<mac-mini-tailnet-ip>
```

Now on laptop, apps can call `http://localhost:11434`.

### Tunnel Open WebUI

```bash
ssh -N -L 3000:localhost:3000 youruser@<mac-mini-tailnet-ip>
```

Then open `http://localhost:3000` on laptop browser.

## 4) From phone

Two options:

1. Use Tailscale app on phone and open browser to `http://<mac-mini-tailnet-ip>:3000`
2. Use a zero-trust reverse proxy setup (more advanced)

## Security Rules

- Keep Ollama bound to localhost.
- Do not expose `11434` directly to the public internet.
- Prefer Tailscale + SSH tunnels.
- Use long passwords + 2FA for all accounts.

## Troubleshooting

- Ollama not responding: `brew services restart ollama`
- Open WebUI not starting: `docker compose -f ai/docker-compose.open-webui.yml logs -f`
- SSH issues: verify Remote Login enabled + correct tailnet IP

