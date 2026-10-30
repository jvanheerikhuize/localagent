#!/usr/bin/env bash
# Smoke-test tool calling + speed for each local model.
set -euo pipefail

models=("${@:-qwen3.5:4b qwen3.5:9b}")
for m in ${models[@]}; do
  echo "== $m"
  curl -s http://localhost:11434/api/chat -d '{
    "model": "'"$m"'", "stream": false, "think": false,
    "messages": [{"role": "user", "content": "List the files in /tmp using the tool."}],
    "tools": [{"type": "function", "function": {
      "name": "run_shell", "description": "Run a shell command",
      "parameters": {"type": "object", "properties": {"command": {"type": "string"}}, "required": ["command"]}}}]
  }' | python3 -c '
import json, sys
r = json.load(sys.stdin)
print("tool_calls:", r["message"].get("tool_calls"))
print("prompt tok/s: %.1f | gen tok/s: %.1f | total s: %.1f" % (
    r["prompt_eval_count"] / r["prompt_eval_duration"] * 1e9,
    r["eval_count"] / r["eval_duration"] * 1e9,
    r["total_duration"] / 1e9))'
done
