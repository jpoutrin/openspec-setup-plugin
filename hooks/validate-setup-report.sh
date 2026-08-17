#!/bin/bash
# Stop hook: if the last assistant response is a Phase 4 setup summary,
# validates it confirms all quality gates were addressed.
# Exits 2 with a message if anything is missing — Claude will see the output and revise.

TRANSCRIPT="$(jq -r '.transcript_path // empty' 2>/dev/null)"
[[ -z "$TRANSCRIPT" || ! -f "$TRANSCRIPT" ]] && exit 0

# Extract text from the last assistant message in the transcript
LAST_TEXT=$(jq -rs '[.[] | select(.message.role == "assistant") |
  [.message.content[]? | select(.type == "text") | .text] | join("\n")] | last // ""' \
  "$TRANSCRIPT" 2>/dev/null)

# Only validate Phase 4 setup summaries — bail out silently for everything else
echo "$LAST_TEXT" | grep -q "Setup Complete" || exit 0

REQUIRED=(
  "### Done"
  "### Your next steps"
  "pre-commit hook"
  "config.yaml"
  "Fragment catalog"
)

MISSING=()
for section in "${REQUIRED[@]}"; do
  echo "$LAST_TEXT" | grep -qF "$section" || MISSING+=("$section")
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "[openspec:setup] Setup summary is missing required confirmations:"
  printf '  ✗ %s\n' "${MISSING[@]}"
  echo "The Phase 4 summary must confirm pre-commit hook installation and config.yaml generation."
  exit 2
fi

echo "[openspec:setup] Setup summary validation passed ✓"
