#!/bin/bash
# Stop hook: if the last assistant response is an OpenSpec audit report,
# validates it contains all required Quality Gates sections.
# Exits 2 with a message if anything is missing — Claude will see the output and revise.

TRANSCRIPT="$(jq -r '.transcript_path // empty' 2>/dev/null)"
[[ -z "$TRANSCRIPT" || ! -f "$TRANSCRIPT" ]] && exit 0

# Extract text from the last assistant message in the transcript
LAST_TEXT=$(jq -rs '[.[] | select(.message.role == "assistant") |
  [.message.content[]? | select(.type == "text") | .text] | join("\n")] | last // ""' \
  "$TRANSCRIPT" 2>/dev/null)

# Only validate audit reports — bail out silently for everything else
echo "$LAST_TEXT" | grep -q "OpenSpec Readiness Audit" || exit 0

REQUIRED=(
  "## Quality Gates"
  "Pre-commit hook"
  "Apply guard rule"
  "Sync guard rule"
  "Archive guard rule"
  "## Action Items"
)

MISSING=()
for section in "${REQUIRED[@]}"; do
  echo "$LAST_TEXT" | grep -qF "$section" || MISSING+=("$section")
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "[openspec:audit] Audit report is missing required sections:"
  printf '  ✗ %s\n' "${MISSING[@]}"
  echo "Revise the report to include all Quality Gates rows before completing."
  exit 2
fi

echo "[openspec:audit] Report validation passed ✓"
