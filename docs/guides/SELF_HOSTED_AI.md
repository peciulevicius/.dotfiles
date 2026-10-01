# Self-Hosted AI

Owning your AI history, memories and documents — and running models locally
where it's worth it.

Companion: [DEGOOGLE.md](DEGOOGLE.md). This is Gap 4 from that guide.

---

## Decision 2026-09-29 — Odysseus on OpenRouter + a shared `~/ai-memory`

- **Your Claude Pro subscription cannot power Odysseus.** Paperclip can use it
  because its `claude_local` agents run **Anthropic's own Claude Code CLI**
  (logged in with the plan) — that's the sanctioned client. Odysseus is a
  third-party app that would call the model API with the subscription's
  credentials, which Anthropic's terms forbid and actively block. Same for
  ChatGPT/Codex. Odysseus therefore runs on **pay-per-token** backends.
- **Backends now:** an **OpenRouter** endpoint (same key as Paperclip's
  OpenRouter connection) is the **default chat model** —
  `deepseek/deepseek-v3.2` (cheap, strong). Pinned alternatives:
  `google/gemini-3.5-flash-lite` (fastest/cheapest), `moonshotai/kimi-k2.5`
  (step up). The existing **Anthropic** API endpoint stays (task/utility
  models on Haiku) until its prepaid credit is used up, then remove it in
  Admin → Models. Local Ollama models were tried and judged not good enough
  (inconsistent, hallucinate on anything non-trivial) — not the default.
- **Shared memory:** `~/ai-memory` — plain markdown, local git repo
  (auto-committed every 15 min, so any agent edit is revertable), backed up
  nightly to R2 (+ NAS copy once the `backups` share exists) and monthly to
  T5/T7. Mounted into Paperclip at `/ai-memory` (Coach, Dietitian, Homelab
  Lead and Studio CEO instructions tell them to read it and write to
  `inbox/`) and into Odysseus at `/ai-memory` (added to
  `tool_path_extra_roots` in `data/settings.json`, so its built-in file tools
  can read/write it — no separate MCP server needed). The Obsidian vault stays
  personal: agents don't write to it (Odysseus only has it read-only for RAG).
  The Coach team's athlete/nutrition data lives at `~/ai-memory/training/` —
  originally its own `~/.training` mount, folded in the same day this was
  written, so it's now readable by every agent here, Odysseus included.

### Finance context is read-only

Glance reads IBKR Flex, Trading 212 account summaries and Kraken wallet balances directly, with
separate provider status and dates. Its total covers connected investments;
Wallet balances and budgets are no longer used. A daily
summary is generated in `~/ai-memory/finance/`, which Paperclip agents and
Odysseus may read to advise on the connected portfolio. **Agents may never place
a trade, transfer, or payment; the human reviews advice and executes every
financial action.** Credentials stay in `~/.config/homelab/` and account data
is kept out of this public repository.

## Your three questions, answered up front

**"Does a cloud backend mean my chats still go through AI servers?"**

Yes — and this distinction matters more than anything else on this page:

| | Where it lives | Who sees it |
|---|---|---|
| **Data sovereignty** ✅ what you get | History, memories, RAG documents, agent configs, attachments — **on your NAS** | Only you |
| **Data privacy** ⚠️ what you don't | The text of each prompt while it's being answered | Anthropic / OpenAI / whoever |

With a cloud backend, the *content of a query* still travels to the provider.
What changes is that **the accumulated record of you stops living in their
account**. PewDiePie's own framing was precise: the more you tell an AI, the
better it works, and the more of yourself you've handed to a company — *"I'm
glad I'm the one who owns this file."* The file is the asset. Own the file,
rent the compute.

A fully-local model is the only way to get both. That's Phase 2.

**"Can I mix — Claude when I need power, local when it's sensitive?"**

Yes, and that's the main reason to run a workspace at all. Both Odysseus and
Open WebUI let you pick the model per conversation. Sensible routing:

| Use | Model |
|---|---|
| Coding, hard reasoning, long context | **Claude** (nothing local competes) |
| Journal, health, finances, personal docs, anything from Paperless | **Local** |
| Bulk drudgery — summarise, reformat, extract, rename | **Local** (it's free and fast enough) |
| Offline / travelling / provider outage | **Local** |

**"Do I need a separate machine with more RAM later?"**

For local models that genuinely rival Claude — yes, and it's a real purchase
(see Phase 3). For a *useful* local model that handles the sensitive-data
column above — no, your current hardware manages. Phase 1 needs no hardware
at all.

---

## Hardware reality check

This has been tried here before and failed. From `HOME_SERVER_CHANGELOG.md:168`:

> ~~Ollama + Open WebUI~~ — removed (not enough RAM, using Claude instead)

Before repeating it, the actual numbers:

| Machine | Spec | Usable for inference |
|---|---|---|
| Mac mini M4 | 16GB unified, 42 containers using 5.2GB of a 10GB Docker VM | ~6–8GB headroom |
| MacBook Air M1 | 16GB unified, **fanless** | ~10GB, but throttles under sustained load |

**The likely reason the first attempt felt bad: Ollama was running in Docker.**
Docker Desktop/OrbStack on macOS runs a Linux VM with **no GPU passthrough** —
Metal is unreachable, so the model runs on CPU at a fraction of the speed. The
same model run natively via Homebrew uses the M4's GPU and is several times
faster.

**Rule: models run natively on macOS. Only the web UI goes in Docker.**
The container reaches the host with `http://host.docker.internal:11434`.

---

## Phase 1 — The workspace (do this first, costs nothing)

This is the part worth having regardless of whether you ever run a local model.

### Which one

| | Odysseus | Open WebUI |
|---|---|---|
| What it is | PewDiePie's AI workspace — the video's subject | The mature, established self-hosted LLM UI |
| Maturity | New, fast-moving, AGPL-3.0 | Years old, huge community, well-tested |
| Backends | Ollama, llama.cpp, vLLM, OpenRouter, any OpenAI-compatible API | Same |
| Extras | Agent, deep research, email client, calendar, notes, docs editor, image editor, **Cookbook** | Chat, RAG, tools, pipelines |
| macOS support | ⚠️ see below | ✅ Docker, well-trodden |

**What Odysseus actually bundles** (from the release video):

- **Agent** — built on [OpenCode](https://opencode.ai). Runs on your machine:
  reads, writes, edits files, browses the web. His example was finding a video
  on another machine, converting it, running Whisper, returning the transcript.
  It's *self-evolving* — writes its own instructions after doing a task once.
- **Memory extraction** — pulls durable facts out of conversations into a file
  you own. This is the sovereignty argument made concrete.
- **Email client with AI triage** — reads mail, flags what's genuinely urgent,
  drafts auto-replies, summarises. Born from hating having to check email
  constantly. **This pairs directly with your email migration** — if you end up
  on Purelymail/Migadu with plain IMAP, this can sit on top of it.
- **Deep research** — adapted from Tongyi Labs, with a visual mode you can
  interrogate further.
- **Document editor** — Claude-Artifacts-style, but deliberately built so *you*
  write and the AI only fixes formatting, spelling, and fact-checks.
- **Built-in search**, calendar, Keep-style notes, characters, themes, an image
  editor with background removal, and a responsive mobile UI.
- **Cookbook** — see below, this is the important one for you.

**Repo:** <https://github.com/odysseus-dev/odysseus> — AGPL-3.0-or-later.

> ✅ **macOS is supported.** At release he said *"there is no Windows or Mac
> port"*, but the repo now ships `build-macos-app.sh` and `start-macos.sh`
> alongside a Windows portable build and a Linux `install-service.sh`. The
> Docker Compose path is still the right one for the Mac mini — it keeps
> Odysseus consistent with your other 42 services.

```bash
git clone https://github.com/odysseus-dev/odysseus.git
cd odysseus
cp .env.example .env
docker compose up -d --build
# http://localhost:7000 — admin password is printed in the logs
```

Three details from the README that matter for your setup:

- **`AUTH_ENABLED=true`** — the project explicitly warns to keep this on for any
  network-accessible deployment. Non-negotiable behind your tunnel.
- **IMAP/SMTP email integration** with triage and summaries — so it plugs
  straight into whichever mailbox you pick in [DEGOOGLE.md](DEGOOGLE.md),
  provided that mailbox speaks plain IMAP. One more reason to avoid
  Bridge-only providers.
- **CalDAV sync** — it can talk to Nextcloud Calendar directly, and **MCP**
  support means it can use the same tool servers Claude Code does.

**Recommendation:** try Odysseus first — it's what you actually saw and the
feature set is far ahead. Keep **Open WebUI as the fallback** if it turns out to
be rough on macOS/ARM. Both read the same backends, so switching costs nothing
but time.

### Cookbook answers your RAM question for you

The single most useful feature for your situation. Cookbook **scans your
hardware and scores what you can actually run**, then downloads the model,
serves it, and wires the endpoint into the workspace automatically — no more
guessing whether a quantisation fits in 16GB, and no more `/v1` endpoint
fiddling.

So the honest answer to *"do I need a machine with more RAM?"* is: **install
this, let it score your Mac mini, and find out** rather than deciding in
advance.

### Make room first

You have ~400MB of RAM sitting in containers your own changelog says were
removed. From `HOME_SERVER_TODO.md`:

- [x] ~~Stop `karakeep` + `karakeep-chrome` + `karakeep-meilisearch`~~ —
      removed 2026-09-19 (containers and images; see changelog)
- [x] ~~Stop `actual-budget`~~ — removed 2026-09-19

That reconciliation was already on the list. Doing it now funds the workspace.

### Steps

> ✅ **Deployed 2026-09-21** — on **port 7001** (7000 is macOS AirPlay),
> Tailscale-only. Live configuration work is tracked in
> `HOME_SERVER_TODO.md` step 8 and `services/odysseus/README.md`; the list
> below is the original plan, ticked against what shipped.

- [x] ~~Free RAM (above)~~
- [x] ~~Read the Odysseus repo README; confirm macOS/ARM64 status~~
- [x] ~~`services/odysseus/`~~ — upstream's own compose via `setup.sh` +
      `.env.example`, rather than a hand-written compose file
- [x] ~~Store data on the **internal SSD**~~ — `~/services/odysseus/data`
- [ ] Add an Anthropic or OpenRouter API key as the first backend
- [x] ~~Expose at `ai.peciulevicius.com`~~ — **decided against for now**: it is
      Tailscale-only. Public exposure only if a non-Tailscale device ever
      needs it, and then behind Cloudflare Access
- [x] ~~Keep **`AUTH_ENABLED=true`**~~ — set in `.env.example`, with TOTP 2FA.
      This holds the whole conversational history and the agent can execute
      code; do not put it on the open internet.
- [x] ~~Add the data directory to `rclone-backup.sh`~~ — `odysseus/data/`
      minus the regenerable model caches
- [x] ~~Glance tile~~ — done. [ ] Uptime Kuma check — not confirmed

---

## Phase 2 — Local models, natively

Once the workspace is up, add a local backend for the sensitive-data column.

- [x] ~~`brew install ollama && brew services start ollama`~~ — native, 2026-09-21
- [x] ~~Point the workspace at `http://host.docker.internal:11434`~~ —
      `OLLAMA_BASE_URL` in `.env.example`
- [x] ~~Start with a 4B model~~ — `qwen3:4b` was tried and removed (slower end
      to end than the 7B and far wordier); **`qwen2.5:7b`** for chat and
      **`llama3.2:3b`** for background calls. Benchmarks in
      `services/odysseus/README.md`

Realistic for 16GB shared with 40+ containers:

| Model | ~RAM (Q4) | Honest verdict |
|---|---|---|
| Qwen3 4B | ~2.5GB | Summarising, extraction, tagging. Fine at it. |
| Gemma 3 4B | ~3GB | Similar; better prose |
| Qwen3 8B | ~5GB | Noticeably better reasoning; tight alongside Docker |
| Anything 30B+ | 18GB+ | **Not possible on this hardware** |

Set expectations correctly: a 4–8B model is **not** a Claude replacement. It is
a competent local worker for jobs where the data matters more than the
brilliance. Used that way it's genuinely valuable; used as a Claude substitute
it will disappoint, which is exactly what happened last time.

**Where it earns its keep:** RAG over your own corpus. You have Paperless-NGX
(documents), Obsidian (notes), Linkwarden (bookmarks) and Calibre (books) — a
small model with retrieval over *your* documents beats a large model that has
never seen them. That's the "smaller models are amazing once you add retrieval"
point, and it's true.

---

## Phase 3 — Dedicated hardware (only if Phase 2 leaves you wanting)

Don't buy anything until you've run Phase 2 and know what you're missing.

| Option | Cost | Buys you |
|---|---|---|
| Mac mini M4 Pro, 48–64GB | ~€1,600–2,200 | 30B–70B quantised, quiet, low power, Metal |
| Used RTX 3090 (24GB) in a PC | ~€700–1,000 | Much faster tokens/sec, 30B comfortably, noisy and power-hungry |
| 2× used 3090 | ~€1,500–2,000 | 70B quantised — approaching PewDiePie territory |

For scale: his rig is ~$20K — eight modded 48GB 4090s plus 2× RTX 4000, running
Llama-3.1-70B, GPT-OSS-120B and Qwen3-235B with a "council" of models voting on
answers. That is not a consumer target and shouldn't be treated as one.

**The unsentimental maths:** Claude costs you ~€20/month. A €2,000 box is eight
years of subscription, still won't match Claude on coding, and needs
maintenance. Buy it if you want local inference *as a goal* — that's a
perfectly good reason. Don't buy it expecting to save money.

---

## Bringing your Claude + ChatGPT history home

You asked for this specifically, and it's the most satisfying part — it turns
years of accumulated context into something you own and can grep.

### Export

- [ ] **ChatGPT** — Settings → Data Controls → Export Data. Emailed zip
      containing `conversations.json`.
- [ ] **Claude** — Settings → Privacy → Export Data. Emailed JSON.
- [ ] **ChatGPT memories** — Settings → Personalization → Manage Memory.
      Not in the export; copy them out by hand.
- [ ] **Claude memories/projects** — copy project instructions and any custom
      instructions manually.

### Import

Neither export matches any workspace's import format, so this needs a small
converter — a genuinely good little project for this repo:

- [ ] `scripts/ai/import-chat-history.py` — read both exports, normalise to
      `{title, created_at, messages[{role, content, timestamp}]}`, emit the
      target workspace's import JSON
- [ ] Check first whether Odysseus or Open WebUI already ship a ChatGPT
      importer — Open WebUI has had community converters; don't write what exists
- [ ] Keep the raw exports on the NAS under `/Volumes/unsorted/ai-exports/`
      regardless — they're the source of truth
- [ ] Add that path to `rclone-backup.sh`

### Then feed it back

Once imported, point the workspace's RAG at the archive. Your own past
conversations become a searchable corpus — and the memory extraction can build
a profile from years of history that currently only exists inside someone
else's account.

---

## Security notes

This service is different from the rest of the stack. It will hold your email,
your documents, your memories, and an agent that can execute code on your
machine.

- **Never expose it without Cloudflare Access.** A public Odysseus instance with
  the agent enabled is remote code execution on the Mac mini.
- **Understand the agent before enabling it.** It reads, writes and deletes
  files. Scope what it can reach.
- **API keys are server-side only** — they go in `.env`, which is gitignored.
- **Back up the memories file.** It becomes irreplaceable faster than you expect.
- **Local ≠ automatically safe.** PewDiePie's line that the AI reading his email
  is fine "because it's a local AI" holds only if the instance is actually
  locked down. Yours is reachable over a Cloudflare tunnel. Lock it down.

---

## Resources

- [github.com/odysseus-dev/odysseus](https://github.com/odysseus-dev/odysseus) — the workspace, AGPL-3.0
- [openwebui.com](https://openwebui.com) — mature alternative
- [opencode.ai](https://opencode.ai) — the agent Odysseus builds on
- [ollama.com](https://ollama.com) — `brew install ollama`
- [LM Studio](https://lmstudio.ai) — GUI alternative, good for testing what fits
