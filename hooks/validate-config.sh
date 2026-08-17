#!/bin/bash
# Runs after any Write tool call. If the written file is openspec/config.yaml,
# validates it with the OpenSpec CLI, hard-fails on missing mandatory clean-repo
# guard rules (no legitimate skip path for these — always required), and warns
# (non-blocking) on missing Architecture/Program Design/vertical-slice rule
# groups — these ARE legitimately skippable via /schema-config's fragment
# Yes/Skip flow, so their absence is informational, not a correctness bug.
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

  # Warn (non-blocking) on missing opt-in rule groups
  WARN=()
  grep -qF 'Include a "## Architecture" section whenever' "$f" || WARN+=("Architecture rule group — run /schema-config to add")
  grep -qF 'Include a "## Program Design" section whenever' "$f" || WARN+=("Program Design rule group — run /schema-config to add")
  grep -qF "Order tasks as vertical slices" "$f" || WARN+=("vertical-slice ordering rule — run /schema-config to add")

  if [[ ${#WARN[@]} -gt 0 ]]; then
    echo "[openspec] config.yaml does not have these opt-in rule groups (not required, just a heads-up):"
    printf '  ⚠ %s\n' "${WARN[@]}"
  fi
fi
