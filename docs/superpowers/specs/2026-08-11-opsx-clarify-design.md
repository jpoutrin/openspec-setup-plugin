# opsx:clarify — Design Spec

**Date:** 2026-08-11  
**Status:** Approved for implementation

---

## Overview

`opsx:clarify` is a pre-apply gap-filler skill for the OpenSpec workflow. It slots between `/opsx:propose` (which generates `proposal.md`, `design.md`, and `tasks.md` in one pass) and `/opsx:apply` (which implements from `tasks.md`).

Its job: scan the change's planning artifacts for ambiguity, ask at most 5 targeted questions one at a time with a built-in recommendation for each, and write answers back into the proposal incrementally — so the implementer never hits an underspecified decision mid-task.

**Does NOT:**
- Write code or modify `tasks.md`
- Replace `/opsx:explore` (open-ended thinking mode; this is structured gap-closing)
- Run automatically — always user-invoked

---

## Invocation

Skill file: `skills/opsx-clarify/SKILL.md`

Trigger phrases:
- `/opsx:clarify`
- `/opsx:clarify <change-name>`
- "clarify my proposal"
- "fill gaps before applying"
- "refine the spec"
- "I want to clarify the change before implementing"

---

## Process

### Step 1 — Change Selection

Follow the `openspec-apply-change` pattern exactly:

1. If a change name was passed as an argument, use it.
2. Otherwise, infer from conversation context (did the user mention a change name recently?).
3. Run `openspec list --json` to enumerate active changes.
4. If exactly one active change exists, auto-select it silently.
5. If multiple exist, use `AskUserQuestion` to let the user pick — show name, schema, task progress, and last-modified for each. Mark the most recently modified as `(Recommended)`.

Always announce: `"Using change: <name>"` and how to override (e.g., `/opsx:clarify <other-name>`).

---

### Step 2 — Artifact Loading

```bash
openspec status --change "<name>" --json
```

Parse `artifactPaths` from the JSON response to locate `proposal.md` and `design.md`.

Load both files. If only one exists, analyze that one.

**If neither exists:** tell the user "No planning artifacts found. Run `/opsx:propose <name>` first." and stop.

---

### Step 3 — Gap Detection (Taxonomy Scan)

Scan both loaded artifacts internally. For each taxonomy category, assign a status: **Clear / Partial / Missing**.

| Category | What to look for |
|---|---|
| Functional scope | Core goals, success criteria, explicit out-of-scope declarations |
| Domain & data model | Entities, attributes, relationships, state transitions |
| User flows & UX | Critical journeys, error/empty/loading states |
| Non-functional | Performance targets, reliability, security posture, observability |
| Integration & dependencies | External APIs, failure modes, versioning assumptions |
| Edge cases & errors | Negative scenarios, conflict resolution, rate limiting |
| Constraints & tradeoffs | Tech constraints, explicitly rejected alternatives |
| Completion signals | Acceptance criteria testability, Definition of Done indicators |
| Placeholders | TODO markers, vague adjectives ("robust", "intuitive") without quantification |

Generate an internal priority queue of **at most 5 questions**, ranked by `Impact × Uncertainty`. Never output the full queue upfront — only ever show one question at a time.

**Early exit:** If all categories are Clear → respond: "No critical ambiguities detected. Ready for `/opsx:apply`." and stop.

---

### Step 4 — Sequential Questioning Loop

Present exactly one question at a time. Each question includes a recommendation.

**Multiple-choice format:**
```
Question 2 of 5:

<Question text>

**Recommended:** Option B — <1-2 sentence reasoning why this is the best choice>

| Option | Description |
|--------|-------------|
| A      | ...         |
| B      | ...         |
| C      | ...         |

Reply with a letter, "yes" to accept the recommendation, or a short answer (≤5 words).
```

**Short-answer format:**
```
Question 2 of 5:

<Question text>

**Suggested:** <answer> — <brief reasoning>

Format: short answer (≤5 words). Reply "yes" to accept the suggestion.
```

**Answer handling:**
- "yes" or "recommended" or "suggested" → use the stated recommendation/suggestion
- A letter → map to the corresponding option
- Free-form short answer → accept if ≤5 words, else ask for a shorter form (counts as same question, not a new one)

**Stop conditions (any of these):**
- All critical gaps resolved before reaching 5 questions
- User says "done", "stop", "proceed", or "skip"
- 5 questions asked

---

### Step 5 — Incremental Write-Back (After Each Accepted Answer)

Write to disk after every accepted answer — do not batch.

**Level 1 — Clarifications log** (in `proposal.md`):

Ensure a `## Clarifications` section exists at the end of `proposal.md`. Under it, create a `### Session YYYY-MM-DD` subheading if not already present for today. Append one bullet per accepted answer:

```markdown
## Clarifications

### Session 2026-08-11
- Q: <question text> → A: <accepted answer>
```

**Level 2 — Inline update** to the relevant artifact section:

| Clarification type | Where to update |
|---|---|
| Functional gap | `proposal.md` → `## What Changes` or `## Capabilities` |
| Data/domain | `design.md` → data model or entities section |
| Non-functional constraint | `design.md` or `proposal.md` → add measurable criterion |
| Edge case / error flow | `design.md` → edge cases section (create if missing) |
| Vague placeholder | Replace the vague term in-place with the concrete answer |
| Terminology conflict | Normalize the canonical term across both files |

**Integrity rules:**
- No duplicate text: if a section already makes the point, update it rather than appending
- No contradictions: if an older statement is now invalidated, replace it — do not leave both
- No narrative drift: keep inserted text minimal and testable
- Preserve heading hierarchy and section ordering of unrelated content

---

### Step 6 — Completion Report

After the questioning loop ends (or early termination):

```
Clarification complete.

Questions asked: 3/5
Files updated: proposal.md, design.md

Coverage summary:
  Resolved:    Functional scope, Domain model, Placeholders
  Clear:       User flows, Integration, Completion signals
  Deferred:    Non-functional (better suited for planning phase)
  Outstanding: —

Ready for /opsx:apply
```

If any **Outstanding** categories remain (high-impact, unresolved), flag them explicitly and suggest running `/opsx:clarify` again after partial planning.

If any **Deferred** categories exist, note them with the rationale (e.g., "better addressed in tasks.md during `/opsx:apply`").

---

## Skill File Structure

```
skills/
  opsx-clarify/
    SKILL.md    ← single file, all logic inline
```

---

## SDO Description (Skill Discovery Optimization)

The `description:` frontmatter must contain only trigger conditions — not workflow summary:

```yaml
description: >
  Use when the user wants to clarify, refine, or fill gaps in an OpenSpec change proposal
  before implementing it. Triggered by "/opsx:clarify", "clarify my proposal",
  "fill gaps before applying", "refine the spec", "I want to clarify the change before
  implementing". Do NOT use for open-ended exploration (use /opsx:explore) or for
  modifying tasks (use /opsx:update-change).
```

---

## Explicitly Out of Scope

- Writing code or modifying `tasks.md`
- Replacing `/opsx:explore` (unstructured thinking mode)
- Auto-running after `/opsx:propose` — always explicit user invocation
- Cross-change analysis — always scoped to one change at a time
- Generating tasks from answers — that remains `/opsx:apply`'s job

---

## Sources

| Source | Key insight used |
|---|---|
| speckit:clarify (Spec Kit) | Taxonomy scan approach; max-5-question cap; incremental write-back; two-level update (log + inline); recommendation-per-question format; `Impact × Uncertainty` prioritization |
| `openspec-apply-change` skill | Change selection pattern: infer → auto-select if one → AskUserQuestion if multiple |
| `openspec-propose` skill | Artifact structure: proposal.md (what & why), design.md (how), tasks.md (implementation) |
| `openspec status --json` | How to resolve artifact paths rather than hardcoding filesystem assumptions |
