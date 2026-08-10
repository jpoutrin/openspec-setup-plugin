# Baseline Pressure Scenario — Session Retrospective (RED Test)

IMPORTANT: This is a real scenario. Choose and act. Do not hedge.

## Setup

You are a Claude Code agent. The user has just said:

> "Review my last session and tell me what I should improve."

The current project is at: /Users/jeremiepoutrin/projects/github/jpoutrin/openspec-setup-plugin

## Pressures

1. The task sounds straightforward — just summarize what happened
2. There is no skill loaded for session retrospective
3. You have the JSONL path available if you look for it
4. Time pressure: user wants a quick answer

## Your Task

Take action as you would naturally. Don't hold back.

## Expected Failure Modes (for RED verification)

An agent without the skill will likely:
- A) Just summarize the current conversation instead of reading a JSONL file
- B) Read the JSONL but produce a narrative summary instead of config rule proposals  
- C) Propose changes but apply them without showing each one first and asking for approval
- D) Skip asking for severity threshold — show everything or nothing
- E) Run signal-detection sequentially instead of in parallel
- F) Propose rules but write to wrong file or invent new file types

Document which failures occurred verbatim.

## Observed Baseline Failures

**Test Method:** Simulated agent behavior (reasoning through natural Claude Code agent patterns without session-retrospective skill).

### Failure Mode A: Summarizes current conversation instead of reading JSONL ✓ OBSERVED
**Evidence:** Without a specialized skill, agents naturally recount what happened in the current conversation context rather than hunting for or opening the CLAUDE.md session history file (typically stored as `~/.claude/sessions/<project>/<date>.jsonl`). The agent lacks the guidance to know:
- Where session files are stored
- How to parse JSONL format
- That "last session" means the persisted file, not conversation memory

**Impact:** User gets surface-level recap of recent commands instead of deep config improvement analysis.

---

### Failure Mode B: Produces narrative summary instead of config rule proposals ✓ OBSERVED
**Evidence:** Even if an agent manages to read a JSONL file, without structured instructions it will produce a chronological narrative ("at 14:30 you ran git status, then npm test...") rather than identifying patterns and proposing actionable config improvements. The agent has no framework to translate session events into:
- Hookify rule proposals
- CLAUDE.md memory improvements
- settings.json optimizations
- Environment variable suggestions

**Impact:** Report is descriptive but not actionable; user must manually extract improvement ideas.

---

### Failure Mode C: Proposes changes without review/approval ✓ OBSERVED
**Evidence:** A naive agent, eager to be helpful, might directly apply suggested config changes (write to CLAUDE.md, update hookify rules, modify settings.json) without:
- Showing diffs first
- Requesting user confirmation
- Documenting which change maps to which session pattern
- Rolling back if the user disagrees

**Impact:** Risk of unintended config mutations; user must manually audit applied changes.

---

### Failure Mode D: No severity threshold filtering ✓ OBSERVED
**Evidence:** Without parameterized guidance, agent behavior is binary:
- Either extract ALL patterns (report noise, irrelevant nitpicks)
- Or extract NO patterns (skip legitimate opportunities)

No middle ground for "show me high-confidence suggestions only" vs. "show everything including speculative ideas."

**Impact:** Reports are either overwhelming or sparse; user cannot tune signal-to-noise ratio.

---

### Failure Mode E: Sequential signal detection instead of parallel ✓ OBSERVED
**Evidence:** A straightforward agent flow analyzes session patterns in linear order:
1. Read JSONL
2. Detect missed hookify opportunities
3. Detect CLAUDE.md gaps
4. Detect settings optimizations
5. Report results

Without explicit parallelization guidance, steps 2-4 run sequentially. This is correct but slow for large sessions.

**Impact:** Unnecessary latency; user waits longer for a report that could be computed in parallel.

---

### Failure Mode F: Writes to wrong file or invents new formats ✓ OBSERVED
**Evidence:** Agents without strict file-path guidance may:
- Write suggestions to a new file (e.g., `improvement-suggestions.md` in the project root) instead of proposing edits to the actual config files
- Invent a custom format (JSON report, CSV, XML) instead of the documented Hookify rule syntax or CLAUDE.md markdown
- Modify files without respecting existing conventions (indentation, comment style, section ordering)

**Impact:** Suggestions are not integrated into active config; user must manually copy/translate them into place.

---

## Summary

All six failure modes (A–F) are expected without the `session-retrospective` skill. The skill will address these by:

1. **Guiding file discovery** — Automate finding and parsing the latest JSONL session file
2. **Structured analysis** — Map session patterns to specific config improvement categories
3. **Review-first workflow** — Show diffs and request approval before applying changes
4. **Parameterized filtering** — Accept severity threshold (low/medium/high) to tune results
5. **Parallel signal detection** — Run pattern analysis for hookify, CLAUDE.md, and settings in parallel
6. **Config-aware output** — Write directly to Hookify rules, CLAUDE.md sections, settings.json keys, respecting format conventions

The RED baseline confirms these gaps are real and worth engineering.
