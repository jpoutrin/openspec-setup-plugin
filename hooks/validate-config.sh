#!/bin/bash
# Runs after any Write tool call. If the written file is openspec/config.yaml,
# validates it with the OpenSpec CLI and surfaces errors to Claude automatically.
f=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)
if [[ "$f" == *openspec/config.yaml* ]]; then
  echo "[openspec] Validating config.yaml..."
  openspec validate 2>&1
fi
