#!/bin/bash
# Runs after any Write tool call. If the written file is openspec/config.yaml,
# validates it with the OpenSpec CLI and checks for mandatory clean-repo guard rules.
f=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)
if [[ "$f" == *openspec/config.yaml* ]]; then
  echo "[openspec] Validating config.yaml..."
  openspec validate 2>&1

  # Check for mandatory clean-repo guard rules in rules.tasks
  MISSING=()
  grep -q "opsx:apply" "$f" || MISSING+=("/opsx:apply guard")
  grep -q "opsx:sync"  "$f" || MISSING+=("/opsx:sync guard")
  grep -q "opsx:archive" "$f" || MISSING+=("/opsx:archive guard")

  if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo "[openspec] config.yaml is missing mandatory clean-repo guard rules in rules.tasks:"
    printf '  ✗ %s\n' "${MISSING[@]}"
    echo "Add the missing rules under rules.tasks before proceeding."
    exit 2
  fi
fi
