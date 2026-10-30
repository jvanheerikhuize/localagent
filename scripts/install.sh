#!/usr/bin/env bash
# One-shot setup of the local agent stack. Idempotent; safe to re-run.
#   1. Ollama (user install in ~/.local) as a user systemd service
#   2. Models: qwen3.5:4b (default) + qwen3.5:9b (--big)
#   3. Goose CLI (~/.local/bin/goose)
#   4. Goose Desktop (.deb, needs sudo)
#   5. Goose config + `agent` launcher
set -euo pipefail

OLLAMA_VERSION=v0.40.13
GOOSE_VERSION=v1.57.0
REPO=$(cd "$(dirname "$0")/.." && pwd)
DL=$REPO/downloads
mkdir -p "$DL" ~/.local/bin ~/.local/opt ~/.config/systemd/user ~/.config/goose

echo "==> Ollama $OLLAMA_VERSION"
dest=~/.local/opt/ollama-${OLLAMA_VERSION#v}
if [[ ! -x $dest/bin/ollama ]]; then
  curl -fL -o "$DL/ollama.tar.zst" \
    "https://github.com/ollama/ollama/releases/download/$OLLAMA_VERSION/ollama-linux-amd64.tar.zst"
  mkdir -p "$dest" && tar --zstd -xf "$DL/ollama.tar.zst" -C "$dest"
fi
ln -sfn "$dest/bin/ollama" ~/.local/bin/ollama

echo "==> Ollama user service"
# The old system service (/usr/local/bin/ollama 0.19) is too old for qwen3.5; keep it off.
if systemctl is-enabled --quiet ollama 2>/dev/null; then
  sudo systemctl disable --now ollama
fi
ln -sfn "$REPO/config/ollama.service" ~/.config/systemd/user/ollama.service
systemctl --user daemon-reload
systemctl --user enable --now ollama
until curl -fs http://localhost:11434/api/version >/dev/null; do sleep 1; done

echo "==> Models"
~/.local/bin/ollama pull qwen3.5:4b
~/.local/bin/ollama pull qwen3.5:9b

echo "==> Goose CLI $GOOSE_VERSION"
if ! command -v goose >/dev/null || [[ $(goose --version) != *${GOOSE_VERSION#v}* ]]; then
  curl -fL -o "$DL/goose.tar.gz" \
    "https://github.com/aaif-goose/goose/releases/download/$GOOSE_VERSION/goose-x86_64-unknown-linux-gnu.tar.gz"
  tmp=$(mktemp -d) && tar xzf "$DL/goose.tar.gz" -C "$tmp"
  install -m755 "$(find "$tmp" -type f -name goose | head -1)" ~/.local/bin/goose
  rm -rf "$tmp"
fi

echo "==> Goose Desktop $GOOSE_VERSION"
deb=$DL/goose_${GOOSE_VERSION#v}_amd64.deb
[[ -f $deb ]] || curl -fL -o "$deb" \
  "https://github.com/aaif-goose/goose/releases/download/$GOOSE_VERSION/goose_${GOOSE_VERSION#v}_amd64.deb"
sudo apt install -y "$deb"

echo "==> Goose config + launcher"
[[ -f ~/.config/goose/config.yaml ]] || cp "$REPO/config/goose-config.yaml" ~/.config/goose/config.yaml
ln -sfn "$REPO/bin/agent" ~/.local/bin/agent

echo "Done. Terminal: 'agent' (or 'agent --big'). Desktop: launch Goose from the app menu."
