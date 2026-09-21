# Odysseus — self-hosted AI workspace

Chat, agents, research, RAG and memory, with **your** history on your own disk.
Gap 4 of the de-Googling effort: *own the file, rent the compute.*

**Port:** 7001 · **Source:** <https://github.com/odysseus-dev/odysseus> · AGPL-3.0

## The one thing to get right

🔒 **Sensitive topics go to the local model, never the cloud one.**

A cloud backend gives you **sovereignty** — the accumulated record of you lives
here, not in someone's account. It does **not** give you privacy from the
provider: the text of each prompt still travels to them.

| Topic | Backend |
|---|---|
| Health, finances, journal, anything out of Paperless | 🔒 **Local (Ollama)** |
| Coding | Claude Code, not this |
| General reasoning, research, long context | Cloud API key |
| Bulk drudgery — summarise, reformat, extract | Local |

## It builds from source

The only service here that does. Its upstream repo lives at
`~/services/odysseus` and is **not** vendored into the dotfiles repo — only
`.env.example`, this README and `setup.sh` are ours.

```bash
~/.dotfiles/services/odysseus/setup.sh      # clone + stage .env
cd ~/services/odysseus
nano .env                                   # set ODYSSEUS_ADMIN_PASSWORD
docker compose up -d --build                # long first build
```

Four containers: `odysseus`, `chromadb` (vectors), `searxng` (search),
`ntfy` (notifications).

## ⚠️ Local models run on the host, never in Docker

`brew services start ollama` — **not** a container.

Docker on macOS has **no GPU passthrough**, so a model served inside any
container is CPU-only. This is the likely real cause of the earlier failed
attempt recorded in the changelog as *"not enough RAM"*.

Ollama must also listen beyond loopback or the container cannot reach it:

```bash
launchctl setenv OLLAMA_HOST "0.0.0.0:11434"
OLLAMA_HOST=0.0.0.0:11434 brew services start ollama
ollama pull qwen3:4b          # ~2.5GB; hardware ceiling here is ~8B quantised
```

Verify from inside the container — this is the check that matters:

```bash
docker exec odysseus-odysseus-1 curl -s http://host.docker.internal:11434/api/tags
```

### 🧑‍🍳 Cookbook: use it to browse, not to serve

Cookbook scores which models fit your hardware and can download and serve them.
⚠️ **But upstream's own compose says "Inside Docker, 'Local' means the Odysseus
container"** — so a model it serves "locally" runs CPU-only here, and its
hardware scan measures the container rather than the M4.

Browse and compare with it; serve with native Ollama.

## Local overrides

`docker-compose.override.yml` (on the host, not in this repo) drops SearXNG's
host port: upstream publishes `127.0.0.1:8080`, which collides with Nextcloud.
Odysseus reaches it internally at `http://searxng:8080`, so the mapping is
unnecessary. Keeping it in an override means `git pull` never clobbers it.

## Access

| From | URL |
|---|---|
| Mac mini | `http://localhost:7001` |
| Anywhere, over Tailscale | `http://100.81.171.49:7001` |

**No public hostname, deliberately.** This holds health and finance history and
its agent can execute code. The iPhone is on the tailnet, so Tailscale already
gives phone access from anywhere — a public hostname would add exposure and buy
nothing. `AUTH_ENABLED=true` regardless.

⚠️ 7000 is macOS **AirPlay Receiver**; upstream's own docs warn about it.

## Backup

`data/` is backed up to R2 — **owning the chat history, memories and RAG corpus
is the entire point.** Excluded as regenerable: `data/huggingface/` (model
downloads), `data/local/` (Cookbook packages), `logs/`, and `.git/`.

## Measured footprint (2026-09-21)

| Container | RAM |
|---|---|
| odysseus | ~745MB |
| searxng | ~141MB |
| ntfy | ~45MB |
| chromadb | ~28MB |

~960MB for the stack. Image 686MB built. ⚠️ Host headroom afterwards: **2.11
GiB**, 30% memory free. **SearXNG is the first thing to drop** if it gets tight
— it only powers web search.
