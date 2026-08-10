# Session Retrospective Skill — Design Spec

**Date:** 2026-08-10  
**Status:** Approved for implementation

---

## Overview

A Claude Code skill that reviews past project sessions (JSONL transcripts) to surface impactful improvement opportunities across all configuration layers: CLAUDE.md rules, hookify rules, memory entries, and settings.json permissions.

**Why this exists:** hookify's `conversation-analyzer` reviews only the current session and produces only hookify rules. No existing tool does cross-session analysis across all config layers with ranked, actionable proposals.

---

## Invocation

Skill file: `~/.claude/skills/session-retrospective/SKILL.md`

Triggers on user phrases like:
- `/session-retrospective`
- "review my last session"
- "session retro"
- "what should I improve from this session"
- "find improvement opportunities from my session"

---

## User Flow

### Step 1 — Session Selection

1. Read `~/.claude/projects/<encoded-project-path>/sessions-index.json`
2. Display the 5 most recent sessions in a table:
   ```
   [1] 2026-08-10 14:32  "let's create a new skill to review..."  (408KB)
   [2] 2026-08-09 09:15  "add authentication to the API..."        (275KB)
   ...
   [↵] Default: most recent session
   ```
3. User confirms (Enter) or types a number to pick a different session.

### Step 2 — Severity Threshold

Ask upfront before any analysis:
> "What level of findings do you want to see?  
> [H] High only — significant friction, repeated corrections, blocking errors  
> [M] High + Medium — includes style violations, minor friction patterns  
> [A] All — includes low-severity preferences and confirmations to preserve"

### Step 3 — Parallel Analysis

Dispatch 4 subagents in parallel against the chosen JSONL file. Each returns a structured findings list.

#### Signal Detection Agents

**Agent 1 — Correction signals**
Scans user messages following assistant turns for:
- Explicit negations: "don't", "stop", "never", "avoid", "that's wrong", "I didn't ask for that"
- Re-prompts: same intent rephrased 2+ times in sequence
- User reverting or redoing work that Claude produced

**Agent 2 — Error signals**
Scans tool result entries for:
- `is_error: true` in JSONL tool results
- Bash commands retried 3+ times with the same failure
- Edit conflicts or write rejections

**Agent 3 — Friction signals**
Scans tool-call sequences for:
- 5+ tool calls before a task resolves that should have taken 2
- Abandoned subtasks (task started, then direction changed mid-way)
- Permission prompts that blocked flow and could be pre-allowed

**Agent 4 — Praise signals**
Scans user messages for:
- Confirmations of non-obvious choices: "yes exactly", "perfect, keep doing that"
- Accepting an unusual approach without pushback
- Explicit praise ("great", "this is exactly right")

#### Finding Schema (each agent returns)

```json
{
  "signal_type": "correction | error | friction | praise",
  "severity": "high | medium | low",
  "evidence": "<exact quote or tool call from JSONL>",
  "context": "<what task was being attempted>",
  "candidate_config_layers": ["claude_md", "hookify", "memory", "settings"]
}
```

### Step 4 — Synthesis

A synthesis subagent receives all findings from the 4 agents and:

1. **Deduplicates** findings that point at the same root behavior (e.g., correction + friction both targeting the same tool pattern)
2. **Assigns config layer** using this decision tree:
   ```
   Interceptable via regex on a tool call at execution time?
     → hookify rule
   Behavioral instruction (how to work, what to avoid doing)?
     → CLAUDE.md rule (always project-level; user can promote to global manually)
   User preference or fact about user/project?
     → memory entry (type: user | feedback | project | reference)
   Permission to pre-allow or deny a tool/command?
     → settings.json (allowedTools or permissions)
   ```
3. **Ranks** by impact: high corrections first, then high errors, medium corrections, medium errors, friction, praise last
4. **Filters** to the user's chosen severity threshold

### Step 5 — One-at-a-Time Presentation

For each finding (highest impact first), display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Finding 1 of 7  [HIGH · CLAUDE.md rule]

What happened:
  You corrected me 3 times about not using `make` directly —
  "use /usr/bin/make". Same instruction each time.

Evidence: "use /usr/bin/make not make" (turn 4), "I said use
  full path" (turn 12), "stop using plain make" (turn 19)

Proposed rule to add to CLAUDE.md:
  Always use the full path `/usr/bin/make` for all make commands.
  Never use plain `make`.

[A]pply  [S]kip  [E]dit  [Q]uit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**On Apply:** Write the change to the target file, show a one-line confirmation ("✓ Added to CLAUDE.md"), advance to next finding.

**On Edit:** Show the proposed text, let the user modify it in-conversation, write the edited version, then advance.

**On Skip:** Log the skip silently, advance to next finding.

**On Quit:** Stop the loop, show a summary of what was applied in this session.

---

## Config Layer Write Behavior

| Layer | Target file | Write method |
|---|---|---|
| CLAUDE.md | `<project>/CLAUDE.md` or `~/.claude/CLAUDE.md` | Append rule under appropriate section |
| Hookify | `.claude/hookify.{name}.local.md` | Create new file with YAML frontmatter + message |
| Memory | `~/.claude/projects/.../memory/{slug}.md` + update `MEMORY.md` index | Create new file per memory system format |
| Settings | `.claude/settings.json` | JSON patch to `allowedTools` or `permissions` block |

---

## Explicitly Out of Scope

- Reviewing the current (ongoing) session — use hookify's conversation-analyzer for that
- Producing narrative summaries — all output is actionable rule proposals
- Bulk-applying all findings — always one at a time with user approval
- Cross-project session analysis — always scoped to the current project's sessions

---

## Skill File Structure

```
~/.claude/skills/
  session-retrospective/
    SKILL.md    ← single file, all logic inline
```

No supporting files needed.

---

## Sources

| Source | Key insight used |
|---|---|
| [RPAR paper (arxiv)](https://arxiv.org/pdf/2606.14302) | Scan end-to-end, find earliest deviation — not just the last error |
| [RuAG paper (arxiv)](https://arxiv.org/pdf/2411.03349) | Extracted rules must be declarative and verifiable, not narrative summaries |
| [claude-improve by TerenceBristol](https://github.com/TerenceBristol/claude-improve) | Parallel discovery agents; 9 signal categories; ranked by impact tier; one-at-a-time proposal |
| [claude-skill-session-retrospective by accidentalrebel](https://github.com/accidentalrebel/claude-skill-session-retrospective/blob/master/SKILL.md) | JSONL parsing approach: `is_error: true` entries + user correction messages |
| [hookify conversation-analyzer](https://github.com/claude-plugins-official/hookify) | Signal taxonomy (corrections, errors, praise); what to NOT duplicate |
| [Addy Osmani: Self-Improving Coding Agents](https://addyosmani.com/blog/self-improving-agents/) | Praise signals matter — capture what to *preserve*, not just what to fix |
| [Splunk: LLM Log File Analysis](https://www.splunk.com/en_us/blog/learn/log-file-analysis-llms.html) | Signal taxonomy prevents noise; need structured categories before mining |
| [Claude Code Hooks reference](https://code.claude.com/docs/en/hooks) | Hook event types: bash, file, stop, prompt, all |
