# Session Retrospective Skill — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a Claude Code skill (`~/.claude/skills/session-retrospective/SKILL.md`) that reviews past project session JSONL files and surfaces actionable improvements across CLAUDE.md, hookify rules, memory entries, and settings.json permissions, one at a time.

**Architecture:** Single SKILL.md following TDD for skills (RED → GREEN → REFACTOR). Agent reads JSONL sessions from `~/.claude/projects/{encoded-path}/`, dispatches 4 parallel signal-detection subagents, synthesizes ranked proposals, and presents one at a time for user approval before writing.

**Tech Stack:** Markdown/YAML (SKILL.md), Claude Code skills runtime, JSONL session files, existing config layers (CLAUDE.md, hookify `.local.md`, memory `.md`, settings.json)

## Global Constraints

- Skill file must be a single `SKILL.md` — no supporting files needed
- Skill name must be `session-retrospective` (letters, numbers, hyphens only)
- Description field must NOT summarize the skill's workflow (SDO rule from writing-skills)
- Signal agents MUST run in parallel — sequential is a correctness failure, not a style issue
- Every finding must be shown to the user before writing — no auto-apply ever
- All writes go to the CLAUDE.md, hookify, memory, or settings layer — never raw files invented by the skill

---

## File Structure

```
~/.claude/skills/
  session-retrospective/
    SKILL.md                          ← CREATE: single skill file, all logic inline

~/.claude/projects/{encoded-path}/   ← READ ONLY: session JSONL files (existing)
  sessions-index.json
  {session-id}.jsonl
```

Spec doc: `docs/superpowers/specs/2026-08-10-session-retrospective-design.md`

---

### Task 1: Baseline RED Test — Watch Agent Fail Without Skill

**Goal:** Verify that without the skill, an agent handles "review my last session" incorrectly so we know the skill addresses real failures.

**Files:**
- Create: `~/.claude/skills/session-retrospective/tests/baseline-scenario.md`

**Interfaces:**
- Produces: documented baseline failure modes used in Task 3 (SKILL.md anti-patterns section)

- [ ] **Step 1: Create the test scenario file**

Create `~/.claude/skills/session-retrospective/tests/baseline-scenario.md` with this content:

```markdown
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
```

- [ ] **Step 2: Run the baseline test**

Dispatch a fresh subagent (no session-retrospective skill loaded) with this prompt:

```
Review my last session and tell me what I should improve.

Current project: /Users/jeremiepoutrin/projects/github/jpoutrin/openspec-setup-plugin
```

Observe and document which failure modes from baseline-scenario.md actually occur.

- [ ] **Step 3: Record failures**

Add a `## Observed Baseline Failures` section to `baseline-scenario.md` documenting exactly what the agent did wrong. These failures drive the anti-patterns section in Task 3.

- [ ] **Step 4: Commit**

```bash
git add ~/.claude/skills/session-retrospective/tests/baseline-scenario.md
git commit -m "test: add RED baseline scenario for session-retrospective skill"
```

---

### Task 2: Write SKILL.md — GREEN Implementation

**Goal:** Write the full SKILL.md that addresses all failures observed in Task 1.

**Files:**
- Create: `~/.claude/skills/session-retrospective/SKILL.md`

**Interfaces:**
- Consumes: baseline failure modes from Task 1 (drives the Common Mistakes section)
- Produces: `~/.claude/skills/session-retrospective/SKILL.md` — the skill that later tasks verify

- [ ] **Step 1: Create the skill directory**

```bash
mkdir -p ~/.claude/skills/session-retrospective/tests
```

- [ ] **Step 2: Write SKILL.md**

Create `~/.claude/skills/session-retrospective/SKILL.md` with this exact content:

````markdown
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

1. Find the encoded project path by replacing `/` with `-` and removing the leading `-` from `$(pwd)`. Example: `/Users/foo/projects/bar` → `-Users-foo-projects-bar`.

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
````

- [ ] **Step 3: Verify file was created correctly**

```bash
head -5 ~/.claude/skills/session-retrospective/SKILL.md
```

Expected: YAML frontmatter with `name: session-retrospective`

- [ ] **Step 4: Commit**

```bash
git add ~/.claude/skills/session-retrospective/SKILL.md
git commit -m "feat: add session-retrospective skill (GREEN)"
```

---

### Task 3: GREEN Verification — Test Skill Under Pressure

**Goal:** Confirm the skill guides an agent through all 5 steps correctly.

**Files:**
- Create: `~/.claude/skills/session-retrospective/tests/green-verification.md`

**Interfaces:**
- Consumes: `~/.claude/skills/session-retrospective/SKILL.md` (Task 2)
- Produces: documented pass/fail per step, and any loopholes to close in Task 4

- [ ] **Step 1: Write the GREEN pressure scenario**

Create `~/.claude/skills/session-retrospective/tests/green-verification.md`:

```markdown
# GREEN Verification Scenario — Session Retrospective

This scenario runs WITH the session-retrospective skill loaded.
Pass = agent follows all 5 steps without shortcuts.

## Prompt to agent

"Review my last session and find improvements."

## Compliance Checklist

- [ ] Step 1: Agent reads sessions-index.json (not just current conversation)
- [ ] Step 1: Agent displays a numbered list of recent sessions
- [ ] Step 1: Agent defaults to most recent and waits for confirmation
- [ ] Step 2: Agent asks severity threshold BEFORE dispatching analysis agents
- [ ] Step 3: Agent dispatches all 4 signal agents in ONE parallel batch
- [ ] Step 4: Agent runs synthesis subagent on merged findings
- [ ] Step 5: Agent shows one finding at a time with [A]/[S]/[E]/[Q] options
- [ ] Step 5: Agent does NOT write any file without user choosing [A]
- [ ] Step 5: Agent writes to the correct config layer (not arbitrary files)

## Failure = any checklist item unchecked
```

- [ ] **Step 2: Run GREEN test**

Dispatch a fresh subagent WITH the session-retrospective skill in its context. Use the same prompt: "Review my last session and find improvements."

Monitor against the compliance checklist. Note any items that fail.

- [ ] **Step 3: Record GREEN results**

Add a `## GREEN Test Results` section to `green-verification.md` with pass/fail per checklist item and any rationalizations the agent used to skip steps.

---

### Task 4: Refactor — Close Loopholes Found in GREEN Test

**Goal:** Update SKILL.md to address any rationalizations or shortcuts found in Task 3.

**Files:**
- Modify: `~/.claude/skills/session-retrospective/SKILL.md`

**Interfaces:**
- Consumes: `green-verification.md` GREEN Test Results (Task 3)
- Produces: hardened SKILL.md that passes re-verification

- [ ] **Step 1: Review GREEN test results**

Read `tests/green-verification.md` GREEN Test Results section. For each failed item, identify the rationalization pattern the agent used.

- [ ] **Step 2: Add counters to SKILL.md**

For each rationalization found, add a specific counter to either:
- The relevant step's description (add a HARD GATE note)
- The Common Mistakes section (add the exact rationalization + why it's wrong)

Example: if agent said "I'll run the agents one at a time to be careful" → add to Common Mistakes: "**'I'll run them one at a time to be careful':** Careful is irrelevant here — parallel is required. The findings are independent and the session file is read-only."

- [ ] **Step 3: Re-run verification**

Dispatch another fresh subagent WITH the updated skill. Confirm all checklist items now pass.

- [ ] **Step 4: Commit**

```bash
git add ~/.claude/skills/session-retrospective/SKILL.md
git add ~/.claude/skills/session-retrospective/tests/
git commit -m "refactor: harden session-retrospective skill against observed rationalizations"
```

---

## Self-Review Against Spec

**Spec coverage check:**

| Spec requirement | Task that covers it |
|---|---|
| Session selection: default latest, show list of 5 | Task 2, Step 1 |
| Severity threshold question | Task 2, Step 2 |
| 4 parallel signal agents | Task 2, Step 3 |
| Synthesis: dedup + layer assignment + rank + filter | Task 2, Step 4 |
| One-at-a-time: A/S/E/Q loop | Task 2, Step 5 |
| Config layer writes: CLAUDE.md, hookify, memory, settings | Task 2, Config Layer Writes |
| TDD: RED baseline test | Task 1 |
| TDD: GREEN verification | Task 3 |
| TDD: Refactor loop | Task 4 |

**Placeholder scan:** No TBDs, TODOs, or vague steps. Every step includes exact commands, file content, or agent prompts. ✓

**Type consistency:** `{JSONL_PATH}`, `{ENCODED_PATH}`, `{THRESHOLD}`, `{ALL_FINDINGS_AS_JSON}` are used consistently across Steps 3, 4, 5. The JSON schema fields (`signal_type`, `severity`, `evidence`, `context`, `candidate_config_layers`) are defined in Step 3 and consumed in Step 4. ✓

## Sources

| Source | Used for |
|---|---|
| [RPAR paper](https://arxiv.org/pdf/2606.14302) | Scan end-to-end; find earliest deviation not just last error |
| [RuAG paper](https://arxiv.org/pdf/2411.03349) | proposed_text must be declarative and exact, not narrative |
| [claude-improve (TerenceBristol)](https://github.com/TerenceBristol/claude-improve) | Parallel agent pattern; 4 signal categories; one-at-a-time proposal flow |
| [accidentalrebel session-retrospective](https://github.com/accidentalrebel/claude-skill-session-retrospective) | JSONL parsing: `is_error: true` and user correction detection |
| [Addy Osmani: Self-Improving Agents](https://addyosmani.com/blog/self-improving-agents/) | Praise signals — preserve what works, not just fix what breaks |
| [hookify conversation-analyzer](https://github.com/claude-plugins-official/hookify) | Signal taxonomy reference; what this skill must NOT duplicate |
