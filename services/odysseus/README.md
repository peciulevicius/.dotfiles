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
⚠️ **On this host it is unusable, and it says so itself.** Confirmed 2026-09-21 —
its Scan tab reports:

> **No GPU visible inside Docker** — "Cookbook is scanning hardware from inside
> the Odysseus container. If your host has a GPU, Docker may not be exposing it
> to the container, so model recommendations may be CPU-only or too
> conservative."
>
> Detected hardware: `No GPU` · `3.1 / 9.7 GB RAM` · `10 cores` · `cpu_arm`

That is the container's view, not the M4's. The resulting advice is wrong in
both directions: it rates **1.5B and 861M** models as "PERFECT", while its
"trending models that fit your hardware" list offers **70GB** downloads.

**Ignore Cookbook's Download and Launch tabs.** Anything it serves runs inside
the container — CPU-only, no Metal — which is the likely real cause of the
earlier abandoned attempt.

Serve models with native Ollama instead:

```bash
ollama pull llama3.2:3b     # fast default, no thinking mode
ollama pull qwen3:4b        # reasoning model, slower by design
ollama pull qwen2.5:7b      # step up, still inside the ~8B ceiling
```

### Measured model comparison (2026-09-21)

Same prompt to all three — a real training question, not a toy one ("resting
heart rate up from 48 to 55 over two weeks, sleep worse, 8h/week"). All ran
**100% on the GPU** via native Ollama.

| | `llama3.2:3b` | `qwen3:4b` | `qwen2.5:7b` |
|---|---|---|---|
| Speed | **42.9 tok/s** | 31.9 tok/s | 20.1 tok/s |
| Wall clock | **14s** | ⚠️ **80s** | 30s |
| RAM loaded | 2.5 GB | 3.2 GB | 4.8 GB |
| Tokens written | 451 | **2445** | 479 |
| Answer quality | shallow, generic | verbose, not smarter | **best** |

**Use `qwen2.5:7b` for chats** — the only one whose answers engaged with the
actual numbers in the question. 30s for a considered reply is a fair trade.

**Use `llama3.2:3b` for Odysseus's background calls** — chat titles, summaries,
tagging. Those need speed, not intelligence, and you never see them.

⚠️ **`qwen3:4b` is dominated on both axes** — slower end to end than the 7B
*and* less useful. It is a reasoning model: it wrote **2445 tokens** to answer
one question, and Ollama's `"think": false` does not suppress that cleanly —
the reasoning leaks into the visible reply instead. Don't make it the default.

⚠️ **A 7B is not Claude.** It gives sensible, safe, general advice and keeps the
data on your disk — which is the whole point — but don't expect real reasoning.

### Host headroom at 7B

`qwen2.5:7b` loaded pushed the host to **23% memory free** with macOS growing
swap to 7 GB (6.5 used), all 43 containers still running. It works and nothing
crashed, but that is the ceiling. If the machine starts feeling sluggish,
`llama3.2:3b` is the safe fallback. Reducing Docker's 9.7 GiB VM allocation is
the lever if a 7B becomes the routine default.

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
downloads), `data/local/` (Cookbook packages), `data/fastembed_cache/`
(embedding model, including `.incomplete` partial downloads — leaking into the
backup was caught 2026-09-21), `logs/`, and `.git/`.

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
