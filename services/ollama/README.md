# Ollama

Local LLM inference server. Run Llama, Mistral, Phi, and other models privately.

## Ports

| Port | Service |
|------|---------|
| 11434 | API |

## Quick Start

```bash
cp .env.example .env
docker compose up -d

# Pull a model
docker exec ollama ollama pull llama3.2:3b

# Chat
docker exec -it ollama ollama run llama3.2:3b
```

## API

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2:3b",
  "prompt": "Hello!"
}'
```

## Recommended Models (Mac mini M-series)

| Model | Size | Use |
|-------|------|-----|
| `llama3.2:3b` | 2GB | Fast, general |
| `phi4-mini` | 3.8GB | Reasoning |
| `nomic-embed-text` | 274MB | Embeddings |
