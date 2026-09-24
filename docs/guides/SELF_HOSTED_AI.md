# Self-hosted AI

A self-hosted AI workspace that keeps chat history, memories and documents on
local storage, with local models for sensitive work and cloud models where
capability matters.

Deployment details, configuration and benchmarks:
[services/odysseus/README.md](https://github.com/peciulevicius/.dotfiles/blob/main/services/odysseus/README.md).
Outstanding work: [HOME_SERVER_TODO.md](../HOME_SERVER_TODO.md).

## Current state

| Component | State |
|---|---|
| Workspace | **Odysseus**, deployed 2026-09-21, port 7001, Tailscale only |
| Default chat model | `claude-opus-5-5` (Anthropic API) |
| Task and utility model (titles, memory extraction) | `claude-sonnet-5` (Anthropic API, set 2026-09-24) |
| Local models (sensitive topics) | `qwen2.5:7b` for chat, `llama3.2:3b` for light tasks, via native Ollama |
| Data | `~/services/odysseus/data` on the internal SSD, backed up to R2 |
| Authentication | `AUTH_ENABLED=true` with TOTP |

---

## Sovereignty and privacy

These are different properties, and the difference determines which model to
use.

| | What it covers | Where it lives |
|---|---|---|
| **Sovereignty** | Chat history, memories, RAG documents, agent configuration, attachments | Local storage, for any backend |
| **Privacy** | The content of each prompt while it is answered | Stays local only with a local model |

With a cloud backend, each prompt still reaches the provider; what changes is
that the accumulated record stays in local storage rather than in the
provider's account. Only a local model provides both.

### Routing by sensitivity

The workspace selects the model per conversation.

| Use | Model |
|---|---|
| Coding, complex reasoning, long context | Cloud (Claude) |
| Journal, health, finances, personal documents, Paperless content | Local |
| Bulk work: summarising, reformatting, extraction | Local |
| Offline use or provider outage | Local |

---

## Hardware constraints

| Machine | Memory | Practical inference budget |
|---|---|---|
| Mac mini M4 | 16GB unified, shared with ~40 containers | ~6–8GB |
| MacBook Air M1 | 16GB unified, fanless | ~10GB, throttles under sustained load |

**Models run natively on macOS; only the web UI runs in Docker.** Docker on
macOS runs a Linux VM with no GPU passthrough, so a containerised model runs on
the CPU at a fraction of Metal speed. This was the likely cause of an earlier
failed attempt with Ollama and Open WebUI in Docker. Containers reach the host
at `http://host.docker.internal:11434`.

For the same reason, Odysseus's **Cookbook** (hardware scan and model
download) is unusable here: it scans the container, reports no GPU, and
recommends models that would run CPU-only.

### Model sizing

| Model | RAM (Q4) | Assessment |
|---|---|---|
| `llama3.2:3b` | ~2GB | Fast; suitable for titles, tags, short summaries |
| Qwen3 4B | ~2.5GB | Tried and removed: slower end to end than the 7B and far more verbose |
| `qwen2.5:7b` | ~4.7GB | Current chat model |
| Qwen3 8B | ~5GB | Better reasoning; leaves little headroom beside Docker |
| 30B and above | 18GB+ | Not possible on this hardware |

A 4–8B model does not replace Claude. It is useful where keeping the data local
matters more than raw capability, and particularly with retrieval over local
documents (Paperless, Obsidian, Linkwarden, Calibre).

---

## Workspace choice

| | Odysseus (chosen) | Open WebUI (fallback) |
|---|---|---|
| Maturity | New, fast-moving, AGPL-3.0 | Established, large community |
| Backends | Ollama, llama.cpp, vLLM, OpenRouter, OpenAI-compatible APIs | Same |
| Features | Agent (built on OpenCode), memory extraction, IMAP/SMTP email with triage, deep research, document editor, CalDAV, MCP, notes | Chat, RAG, tools, pipelines |

Both use the same backends, so switching costs only configuration time.

Relevant Odysseus features:

- **Memory extraction** stores durable facts from conversations in local data.
- **IMAP/SMTP email integration** requires a provider with plain IMAP — one
  reason Bridge-only and IMAP-less providers were ruled out
  ([DEGOOGLE.md](DEGOOGLE.md#email)).
- **CalDAV** can sync with Nextcloud Calendar.
- **MCP** support allows the same tool servers Claude Code uses.

### Exposure

Odysseus is **Tailscale-only**. It holds conversation history and memories, and
its agent can read, write and execute on the host; a public instance with the
agent enabled amounts to remote code execution. A public hostname
(`ai.peciulevicius.com`) would only be added if a non-Tailscale device needs
access, and then behind Cloudflare Access.

---

## Cloud API keys

Odysseus uses an Anthropic API key for its default and background models. API
usage is billed separately from a Claude subscription. For the key:

- Store it in `~/services/odysseus/.env` (gitignored) and in Vaultwarden.
- Keep a low prepaid balance with automatic top-up disabled, so a leaked key or
  a runaway agent loop cannot run up charges.

OpenRouter was considered and rejected: a 5.5% top-up fee, one-year credit
expiry, a 24-hour refund window, Discord-only support, and some providers
serving quantised models.

---

## Importing chat history

1. **ChatGPT:** Settings → Data Controls → Export Data (emailed zip with
   `conversations.json`).
2. **Claude:** Settings → Privacy → Export Data (emailed JSON).
3. **ChatGPT memories** are not included in the export; copy them manually from
   Settings → Personalization → Manage Memory.
4. **Claude project and custom instructions** are also copied manually.
5. Keep the raw exports on the NAS under `/Volumes/unsorted/ai-exports/` as the
   source of truth, and include that path in the R2 backup.

Do not bulk-import memories through a small local model. An import on
`qwen2.5:7b` with a 4K context (2026-09-23) merged and dropped facts; the
repair on 2026-09-24 wrote atomic facts directly through Odysseus's
`MemoryManager`. The procedure is in the Odysseus README.

---

## Dedicated hardware

Not planned. Buying hardware only makes sense once the local setup shows a
specific limitation.

| Option | Approximate cost | Capability |
|---|---|---|
| Mac mini M4 Pro, 48–64GB | €1,600–2,200 | 30B–70B quantised; quiet, low power |
| Used RTX 3090 (24GB) in a PC | €700–1,000 | Faster generation; 30B comfortably; loud, power-hungry |
| 2× used RTX 3090 | €1,500–2,000 | 70B quantised |

At about €20/month for a Claude subscription, a €2,000 machine equals roughly
eight years of subscription and still does not match Claude on coding. It is
justified if local inference is the goal in itself, not as a cost saving.

---

## Security

- Keep Odysseus off the public internet (see [Exposure](#exposure)).
- Scope what the agent can reach before enabling it.
- API keys belong in `.env`, never in the repository.
- Memories and history are backed up nightly with the rest of
  `~/services/odysseus/data`.
- A local model is only as private as the instance is locked down.

## References

- [Odysseus](https://github.com/odysseus-dev/odysseus) (AGPL-3.0)
- [Open WebUI](https://openwebui.com)
- [OpenCode](https://opencode.ai)
- [Ollama](https://ollama.com)
- [LM Studio](https://lmstudio.ai)
