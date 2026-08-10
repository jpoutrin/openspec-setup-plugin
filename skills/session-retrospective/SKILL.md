---
name: session-retrospective
description: Use when the user asks to review a past project session, do a "session retro",
  find improvement opportunities from a previous session, or improve CLAUDE.md/hookify rules/
  memory/settings based on past behavior. Triggered by "/session-retrospective", "review my
  last session", "what should I improve", "session retro". Do NOT use for the current session.
---

# Session Retrospective

## Overview

Reviews a saved project session JSONL file to surface actionable improvements across all configuration layers — CLAUDE.md rules, hookify rules, memory entries, settings.json permissions. Presents findings one at a time, highest-impact first, for user approval before writing.

**Do NOT use** for the current ongoing session — use hookify's conversation-analyzer for that.

## Process

### Step 1: Session Selection

1. Find the encoded project path by replacing `/` with `-` (the leading `/` becomes a leading `-`). Example: `/Users/foo/projects/bar` → `-Users-foo-projects-bar`.

2. Read sessions index:
   ```bash
   cat ~/.claude/projects/{ENCODED_PATH}/sessions-index.json
   ```

3. Display the 5 most recent sessions:
   ```
   Recent sessions for this project:
   [1] 2026-08-10 14:32 — "let's create a new skill to review..." (408KB)
   [2] 2026-08-09 09:15 — "add authentication to the API..."      (275KB)
   [3] 2026-08-08 11:00 — "fix the database connection issue"     (180KB)
   
   Press Enter for [1] (most recent), or type a number to pick.
   ```

4. Default to [1]. Wait for user confirmation or number. Store the JSONL `fullPath` as `{JSONL_PATH}`.

### Step 2: Severity Threshold

Before dispatching any agents, ask:

> "What level of findings do you want?
> [H] High — repeated corrections, blocking errors, significant friction
> [M] High + Medium — includes style issues, minor patterns (recommended)
> [A] All — includes low-severity preferences and confirmations to preserve"

Wait for answer. Store threshold (`H`, `M`, or `A`).

### Step 3: Parallel Signal Detection

**HARD GATE: Launch all 4 subagents in a single parallel batch — one message, four agent dispatches. Running them sequentially is a correctness failure.**

---

**Subagent 1 — Correction Signals**

> You are analyzing a Claude Code session JSONL for correction signals.
>
> Read this file: `{JSONL_PATH}`
>
> Find every instance where a user message:
> - Contains explicit negations: "don't", "stop", "never", "avoid", "that's wrong", "I didn't ask for that", "that's not what I meant"
> - Repeats the same intent 2+ times rephrased (had to re-explain)
> - Reverts or re-does work the assistant produced
>
> Return ONLY a JSON array (no prose). Each element:
> ```json
> {
>   "signal_type": "correction",
>   "severity": "high|medium|low",
>   "evidence": "<exact user quote from JSONL>",
>   "context": "<what task was being attempted>",
>   "candidate_config_layers": ["claude_md"]
> }
> ```
> severity rules: "high" = repeated 3+ or clearly frustrated; "medium" = repeated 2x; "low" = single minor.
> candidate_config_layers: ["hookify"] if interceptable via tool regex; ["claude_md"] if behavioral; ["memory"] if preference; ["settings"] if permission-related.
> Return [] if nothing found.

---

**Subagent 2 — Error Signals**

> You are analyzing a Claude Code session JSONL for error signals.
>
> Read this file: `{JSONL_PATH}`
>
> Find every instance where:
> - A tool result entry has `"is_error": true`
> - A Bash command is retried 3+ times with the same failure
> - An Edit/Write fails or is rejected
>
> Return ONLY a JSON array (no prose). Each element:
> ```json
> {
>   "signal_type": "error",
>   "severity": "high|medium|low",
>   "evidence": "<tool call and error text from JSONL>",
>   "context": "<what task was being attempted>",
>   "candidate_config_layers": ["hookify"]
> }
> ```
> severity: "high" = blocking/repeated; "medium" = recovered slowly; "low" = single minor.
> Return [] if nothing found.

---

**Subagent 3 — Friction Signals**

> You are analyzing a Claude Code session JSONL for friction signals.
>
> Read this file: `{JSONL_PATH}`
>
> Find sequences where:
> - 5+ tool calls occur before a task resolves that should take 2
> - A task is started then abandoned mid-way (direction change)
> - A permission prompt blocked flow that could be pre-allowed in settings.json
>
> Return ONLY a JSON array (no prose). Each element:
> ```json
> {
>   "signal_type": "friction",
>   "severity": "high|medium|low",
>   "evidence": "<tool call sequence summary with approximate turn numbers>",
>   "context": "<what task was being attempted>",
>   "candidate_config_layers": ["claude_md"]
> }
> ```
> severity: "high" = task abandoned or 8+ tools for simple task; "medium" = 5-7 tools or major misdirection; "low" = minor inefficiency.
> candidate_config_layers: ["settings"] if a permission prompt was the blocker; ["claude_md"] otherwise.
> Return [] if nothing found.

---

**Subagent 4 — Praise Signals**

> You are analyzing a Claude Code session JSONL for praise signals (behaviors worth preserving).
>
> Read this file: `{JSONL_PATH}`
>
> Find every instance where a user:
> - Explicitly confirms a non-obvious choice: "yes exactly", "perfect, keep doing that", "great approach"
> - Accepts an unusual or non-default approach without pushback
> - Praises a specific approach the assistant took
>
> Return ONLY a JSON array (no prose). Each element:
> ```json
> {
>   "signal_type": "praise",
>   "severity": "medium|low",
>   "evidence": "<exact user quote from JSONL>",
>   "context": "<what behavior was praised>",
>   "candidate_config_layers": ["claude_md", "memory"]
> }
> ```
> severity: "medium" = confirmed preference for non-obvious choice; "low" = minor/casual praise.
> Return [] if nothing found.

---

Wait for all 4 subagents to complete before proceeding.

### Step 4: Synthesis

Dispatch one synthesis subagent with all findings:

> You are synthesizing session analysis findings into ranked improvement proposals.
>
> Severity threshold: `{THRESHOLD}` (H = high only | M = high+medium | A = all)
>
> All findings:
> `{ALL_FINDINGS_AS_JSON}`
>
> Steps in order:
>
> **1. Deduplicate:** Merge findings pointing at the same root behavior. Keep highest severity, combine evidence.
>
> **2. Assign config layer** — one per finding:
> - Interceptable via regex on a tool call at execution time? → `hookify`
> - Behavioral instruction (how to work, what to avoid)? → `claude_md`
> - User preference or fact about user/project? → `memory`
> - A command/tool to pre-allow to prevent permission friction? → `settings`
>
> **3. Write proposed_text** — this MUST be the exact text to write to the config file, not a description of what to write. For hookify: complete rule file content. For CLAUDE.md: the rule sentence(s). For memory: full memory body. For settings: exact JSON key-value to merge.
>
> **4. Rank:** high corrections > high errors > medium corrections > medium errors > friction > praise.
>
> **5. Filter** to threshold: H = high only; M = high+medium; A = all.
>
> Return JSON array ordered by rank:
> ```json
> [
>   {
>     "rank": 1,
>     "signal_type": "correction",
>     "severity": "high",
>     "config_layer": "claude_md",
>     "evidence": "\"use /usr/bin/make not make\" (turn 4), \"I said use full path\" (turn 12)",
>     "context": "Running make commands — assistant kept using plain `make`",
>     "proposed_text": "Always use the full path `/usr/bin/make` for all make commands. Never use plain `make`.",
>     "target_file": "CLAUDE.md"
>   }
> ]
> ```

### Step 5: One-at-a-Time Presentation

For each finding in rank order, display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Finding {N} of {TOTAL}  [{SEVERITY} · {CONFIG_LAYER}]

What happened:
  {CONTEXT}

Evidence: {EVIDENCE}

Proposed change ({TARGET_FILE}):
  {PROPOSED_TEXT}

[A]pply  [S]kip  [E]dit  [Q]uit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**On [A]pply:** Write to target file (see Config Layer Writes). Confirm "✓ Written to {target_file}". Advance.

**On [S]kip:** Say "Skipped." Advance.

**On [E]dit:** Show proposed_text. Ask "What should it say instead?" Write the user's revised version. Confirm "✓ Written." Advance.

**On [Q]uit:** Show "{N} applied, {M} skipped. Retrospective complete." Stop.

## Config Layer Writes

### CLAUDE.md
Append to project root `CLAUDE.md` (create if missing):
```
\n{proposed_text}
```

### Hookify Rule
Create `.claude/hookify.{kebab-name}.local.md` (create `.claude/` if missing):
```markdown
---
name: {kebab-name}
enabled: true
event: {bash|file|stop|prompt}
pattern: {regex-pattern}
---

{warning message}
```
The event and pattern come from the proposed_text the synthesis agent wrote.

### Memory Entry
1. Create `~/.claude/projects/{encoded_path}/memory/{slug}.md`:
```markdown
---
name: {slug}
description: {one-line summary}
metadata:
  type: {feedback|user|project|reference}
---

{proposed_text}
```
2. Append one line to `~/.claude/projects/{encoded_path}/memory/MEMORY.md`:
```
- [{Title}]({slug}.md) — {one-line hook}
```

### Settings
Edit `.claude/settings.json` — add the tool name to `allowedTools`:
```json
{
  "allowedTools": ["existing-tools...", "{new-tool}"]
}
```
Create `.claude/settings.json` with this structure if it doesn't exist.

## Common Mistakes

**Running signal agents sequentially:** They MUST launch in parallel — one message, four dispatches. Sequential is a correctness failure that triples execution time.

**Writing narrative for proposed_text:** The synthesis agent must write the EXACT text for the config file. "Should add a rule about using full make path" is wrong. "Always use the full path `/usr/bin/make`..." is correct.

**Applying without displaying:** Never write to a config file without first showing the finding display block and receiving [A] or [E].

**Using this skill for the current session:** This skill reads JSONL files from disk. For the current session, use hookify's conversation-analyzer.

**Skipping the severity threshold:** Always ask before dispatching signal agents. Without it, all noise gets included and the user loses trust in the findings.

**Picking the wrong config layer:** If the behavior is interceptable via regex on a specific tool call → hookify. If it's general behavioral guidance → CLAUDE.md. Do not put behavioral rules in hookify or regexable tool patterns in CLAUDE.md.
