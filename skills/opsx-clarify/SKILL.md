---
name: opsx:clarify
description: >
  Use when the user wants to clarify, refine, or fill gaps in an OpenSpec change proposal
  before implementing it. Triggered by "/opsx:clarify", "clarify my proposal",
  "fill gaps before applying", "refine the spec", "I want to clarify the change before
  implementing", "fill in the gaps in the proposal", "what's missing from my proposal".
  Do NOT use for open-ended exploration (use /opsx:explore) or for
  modifying tasks (use /opsx:update-change).
---

# opsx:clarify

Reduce ambiguity in an OpenSpec change's planning artifacts before implementation. Scan
`proposal.md` and `design.md` for gaps using a structured taxonomy, ask at most 5 targeted
questions one at a time (each with a built-in recommendation), and write answers back into
the artifacts incrementally.

**Does NOT write code, modify `tasks.md`, or replace `/opsx:explore`.**

## Step 1: Change Selection

**If a change name was passed as an argument**, use it directly. Announce: "Using change: `<name>`."

**Otherwise:**
1. Infer from conversation context — did the user mention a change name recently?
2. Run: `openspec list --json`
3. Parse the JSON. If exactly one active change exists, auto-select it and announce:
   "Using change: `<name>` (only active change)."
4. If multiple exist, use **AskUserQuestion** to present them. For each option show:
   name, schema, task progress (e.g., "2/5 tasks"), and how recently it was modified.
   Mark the most recently modified as `(Recommended)`.

Always announce the selection and how to override:
"To use a different change, run `/opsx:clarify <other-name>`."

## Step 2: Artifact Loading

Run:
```bash
openspec status --change "<name>" --json
```

Parse `artifactPaths` from the JSON to get the paths to `proposal.md` and `design.md`.
Read both files.

If only one exists, analyze that file only.

**If neither exists:** respond "No planning artifacts found for `<name>`. Run
`/opsx:propose <name>` first." and stop.

## Step 3: Taxonomy Scan (Internal)

Scan both loaded artifacts. For each category below, assign a status:
**Clear** (adequately specified), **Partial** (present but underspecified),
or **Missing** (entirely absent and needed).

| Category | What to look for |
|---|---|
| Functional scope | Core goals, success criteria, explicit out-of-scope declarations |
| Domain & data model | Entities, attributes, relationships, state transitions |
| User flows & UX | Critical journeys, error/empty/loading states |
| Non-functional | Performance targets, reliability, security posture, observability signals |
| Integration & dependencies | External APIs/services, failure modes, versioning assumptions |
| Edge cases & errors | Negative scenarios, conflict resolution, rate limiting |
| Constraints & tradeoffs | Tech constraints, explicitly rejected alternatives |
| Completion signals | Acceptance criteria testability, Definition of Done indicators |
| Placeholders | TODO markers, vague adjectives ("robust", "intuitive") without quantification |
| Terminology & consistency | Canonical terms, synonym conflicts, undefined jargon |

**Do not output the coverage map** unless no questions will be asked.

Internally, generate a priority queue of at most **5 candidate questions**,
ranked by `Impact × Uncertainty`:
- Only include questions whose answers materially affect architecture, data modeling,
  task decomposition, test design, or operational readiness
- Skip questions where the answer wouldn't change the implementation or can better
  be deferred to planning phase
- If more than 5 Partial/Missing categories exist, select the top 5 by impact

**Early exit:** If all categories are Clear → output:
"No critical ambiguities detected in `<name>`. Ready for `/opsx:apply`." and stop.

## Step 4: Sequential Questioning Loop

Present exactly **one question at a time**. Never reveal future questions.
Show the question number: "Question N of ≤5:".

**For multiple-choice questions:**

```
Question N of ≤5:

<Question text>

**Recommended:** Option <X> — <1–2 sentence reasoning>

| Option | Description |
|--------|-------------|
| A      | ...         |
| B      | ...         |
| C      | ...         |

Reply with a letter, "yes" to accept the recommendation, or a short answer (≤5 words).
```

**For short-answer questions:**

```
Question N of ≤5:

<Question text>

**Suggested:** <answer> — <brief reasoning>

Format: short answer (≤5 words). Reply "yes" to accept the suggestion.
```

**Answer handling:**
- "yes", "recommended", or "suggested" → use the stated recommendation/suggestion
- A letter (A/B/C...) → map to that option's description
- Free-form text ≤5 words → accept as-is
- Free-form text >5 words → ask the user to shorten it; this does not advance the counter

After each accepted answer: write to disk immediately (Step 5), then present the next question.

**Stop when any of:**
- All critical gaps resolved (remaining queued questions are no longer needed)
- User says "done", "stop", "proceed", or "skip"
- 5 questions have been asked and answered

## Step 5: Incremental Write-Back (After Each Accepted Answer)

Write to disk immediately after each accepted answer — never batch.

### Level 1 — Clarifications Log (in proposal.md)

Ensure a `## Clarifications` section exists at the end of `proposal.md` (append if missing).
Under it, ensure a `### Session YYYY-MM-DD` subheading exists for today's date.
Append one bullet per accepted answer:

```markdown
## Clarifications

### Session 2026-08-11
- Q: <question text> → A: <accepted answer>
```

### Level 2 — Inline Section Update

Also update the most relevant section in the artifacts:

| Clarification type | Where to write |
|---|---|
| Functional gap (scope, goals, success criteria) | `proposal.md` → `## What Changes` or `## Capabilities` |
| Data model, entities, state transitions | `design.md` → data model section (create if missing) |
| Non-functional constraint | `design.md` → add a measurable criterion (replace vague adjective with metric) |
| Edge case or error scenario | `design.md` → edge cases section (create if missing) |
| Vague placeholder or TODO | Replace the placeholder in-place with the concrete answer |
| Terminology conflict | Normalize the canonical term across both files |
| User flows & UX (journeys, error/loading states) | `design.md` → user flows section (create if missing) |
| Integration & dependencies (APIs, failure modes) | `design.md` → integration section (create if missing) |
| Constraints & tradeoffs (rejected alternatives) | `design.md` → constraints section (create if missing) |
| Completion signals (acceptance criteria, DoD) | `proposal.md` → `## Capabilities` (add acceptance criteria bullet) |

**Integrity rules — all must hold after every write:**
- No duplicate text: if a section already addresses the point, update it rather than appending
- No contradictions: if an older statement is invalidated, replace it — do not leave both
- No narrative drift: keep inserted text minimal and testable, not explanatory prose
- Preserve heading hierarchy and ordering of unrelated content
- Use the same canonical term in all updated sections

## Step 6: Completion Report

After the questioning loop ends or early termination:

```
Clarification complete.

Questions asked: N/5
Files updated: proposal.md, design.md

Coverage summary:
  Resolved:    <categories addressed by the questions>
  Clear:       <categories already sufficient>
  Deferred:    <categories better addressed in planning — with rationale>
  Outstanding: <categories still Partial/Missing — flag if high-impact>

<"Ready for /opsx:apply" OR "Consider running /opsx:clarify again after <reason>">
```

If **Outstanding** high-impact categories remain, recommend running `/opsx:clarify` again
before proceeding to `/opsx:apply`.

## Common Mistakes

**Asking all questions at once:** Present exactly one question per message. Batching
questions defeats the one-at-a-time loop and is a correctness failure.

**Writing all answers at the end:** Write to disk after EACH accepted answer. Batching
writes risks losing clarifications if the session ends unexpectedly.

**Skipping Level 2 inline update:** The clarifications log alone is insufficient. The
relevant artifact section must also be updated so the answer is discoverable in context.

**Leaving contradictions:** When a clarification invalidates an earlier statement, replace
the old text. Never leave two conflicting statements in the same document.

**Revealing the question queue:** Never show future questions. One question per message.

**Exceeding 5 questions:** Hard cap is 5 asked questions. Clarification retries for a
single ambiguous answer do not count toward the cap.

**Omitting recommendations:** Every question must include a "Recommended:" or "Suggested:"
line with reasoning. Presenting bare options without a recommendation defeats the skill's
purpose — users should be able to accept with "yes" without reading all options.
