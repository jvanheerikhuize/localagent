# localagent

A fully local coding agent: **Ollama** serves an open-weight model, and **Goose** is the
agent, usable from the terminal (`agent`) or the Goose Desktop app. Both share
`~/.config/goose/config.yaml`.

## Hardware this is tuned for

| | |
|---|---|
| CPU | Intel i5-8365U, 4C/8T, AVX2 |
| RAM | 15 GB (≈9 GB free in normal use) |
| GPU | Intel UHD 620 (not usable for inference) — **CPU-only** |

## Model choice

| Model | Size | Prompt | Generate | Role |
|---|---|---|---|---|
| `qwen3.5:4b` | 3.3 GB | ~29 tok/s | ~3.6 tok/s | **default** (`agent`) |
| `qwen3.5:9b` | 6.6 GB | ~16 tok/s | ~2.6 tok/s | harder tasks (`agent --big`) |

Measured on this machine with `scripts/bench.sh` (2026-10-30); both emitted correct tool calls.

Why these: Qwen3.5 small models are Apache-2.0, support native tool calling, and are the
strongest agentic models that fit in ~9 GB of free RAM. Rejected:

- `gpt-oss:20b` — ~14 GB of weights; would swap constantly on 15 GB total.
- `devstral-small-2`, `qwen3-coder:30b` — need a GPU or 24 GB+ RAM.
- `qwen2.5-coder:7b` — good coder, weaker/less reliable tool calling.

**Expect it to be slow.** An agent's system prompt + tool schemas is several thousand tokens,
so the first turn of a session can take a few minutes; later turns reuse Ollama's prompt
cache and are faster. Keep tasks small and focused.

## Install

```bash
~/Repos/localagent/scripts/install.sh
```

It asks for sudo twice: to disable the old system Ollama service (0.19, too old for
qwen3.5) and to `apt install` the Goose Desktop `.deb`.

## Use

```bash
cd ~/Repos/<project>
agent            # Goose on qwen3.5:4b
agent --big      # Goose on qwen3.5:9b
```

Desktop: open **Goose** from the app menu; it picks up the same provider/model config.
Switch models in its settings.

Ollama runs as a user service: `systemctl --user {status,restart,stop} ollama`.
Tuning (16k context, q8 KV cache, 1 model loaded, 30 min keep-alive) lives in
`config/ollama.service`.

## Layout

```
bin/agent                 terminal launcher (symlinked to ~/.local/bin/agent)
config/ollama.service     user systemd unit (symlinked into ~/.config/systemd/user)
config/goose-config.yaml  Goose defaults (copied to ~/.config/goose/config.yaml if absent)
scripts/install.sh        idempotent setup
scripts/bench.sh          tool-calling + speed smoke test
```
