# opsx:clarify Skill — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a Claude Code skill (`skills/opsx-clarify/SKILL.md`) that scans an OpenSpec change's planning artifacts for ambiguity, asks at most 5 targeted questions one at a time with recommendations, and writes answers back into the artifacts incrementally.

**Architecture:** Single SKILL.md following TDD for skills (RED → GREEN → REFACTOR). Skill uses `openspec list --json` + `openspec status --change --json` for change discovery, runs an internal taxonomy scan, asks questions one at a time via the conversation, and writes to `proposal.md` at two levels: a `## Clarifications` log and an inline section update.

**Tech Stack:** Markdown/YAML (SKILL.md), Claude Code skills runtime, OpenSpec CLI (`openspec list`, `openspec status`), AskUserQuestion tool for change selection when ambiguous.

## Global Constraints

- Skill file is a single `SKILL.md` — no supporting files in the installed skill
- Skill name must be `opsx:clarify` (matches the slash command pattern)
- Description frontmatter must NOT summarize the workflow — only trigger conditions (SDO rule)
- Max 5 questions per session — hard cap, never exceeded
- Write to disk after EACH accepted answer — never batch writes
- Every write must update TWO levels: clarifications log AND the relevant artifact section
- Never leave a contradictory older statement alongside a new clarification
- Use `openspec list --json` and `openspec status --change "<name>" --json` — never hardcode filesystem paths to change artifacts

---

## File Structure

```
skills/
  opsx-clarify/
    SKILL.md                             ← CREATE: project-committed skill file
    tests/
      baseline-failures.md              ← CREATE: RED behavioral test doc

~/.claude/skills/
  opsx-clarify/
    SKILL.md                            ← WRITE (not committed): globally installed copy
```

Spec doc: `docs/superpowers/specs/2026-08-11-opsx-clarify-design.md`

---

### Task 1: Baseline RED Test — Document Failure Modes Without the Skill

**Goal:** Establish the behavioral acceptance criteria. Document exactly what goes wrong when an agent handles "clarify my proposal" without the skill installed.

**Files:**
- Create: `skills/opsx-clarify/tests/baseline-failures.md`

- [ ] **Step 1: Create the tests directory**

```bash
mkdir -p skills/opsx-clarify/tests
```

- [ ] **Step 2: Write baseline-failures.md**

Create `skills/opsx-clarify/tests/baseline-failures.md` with this exact content:

```markdown
# opsx:clarify — Baseline Failure Modes (RED)

Without the skill installed, an agent asked to "clarify my proposal" exhibits these failures.
The skill must prevent all of them.

---

## Failure 1: No structured change selection

**Without skill:** Agent asks "which change do you want to clarify?" generically,
or guesses based on conversation context, or picks the wrong one when multiple exist.

**Expected behavior:** Infer from args → infer from context → auto-select if exactly one
active change → AskUserQuestion with list if multiple. Always announce the selection.

---

## Failure 2: No taxonomy scan — improvised questions

**Without skill:** Agent scans the proposal superficially and asks questions based on
what looks thin to it in the moment. Misses systematic coverage gaps (e.g., never asks
about non-functional requirements, never flags vague adjectives like "robust").

**Expected behavior:** Internal scan against 9 taxonomy categories. Each category marked
Clear/Partial/Missing. Priority queue ranked by Impact × Uncertainty. Questions target
the highest-impact unresolved categories first.

---

## Failure 3: No question cap — unpredictable count

**Without skill:** Agent asks 2 questions on a simple proposal, or 15 questions on a
complex one. No consistent stopping point, no quota management.

**Expected behavior:** Hard cap of 5 questions per session. Stop also on: all critical
gaps resolved, user says "done"/"stop"/"proceed".

---

## Failure 4: No recommendation per question — bare options

**Without skill:** Agent presents multiple-choice questions without a recommendation
or reasoning. User must evaluate all options themselves every time.

**Expected behavior:** Every question leads with "Recommended: Option X — <reasoning>".
User can accept with "yes" or "recommended" without reading all options.

---

## Failure 5: No incremental write-back — answers lost or batched

**Without skill:** Clarifications are discussed in conversation but not written to
proposal.md until the end, or only written if the user explicitly asks. If the session
ends early, all clarifications are lost.

**Expected behavior:** Write to disk after EACH accepted answer. Never batch.

---

## Failure 6: Write-back is log-only — artifact sections not updated

**Without skill:** Even when an agent does write clarifications, it appends them to a
log section only. The `## What Changes` and `## Capabilities` sections in proposal.md
remain unupdated — so the clarifications are not integrated into the spec itself.

**Expected behavior:** Two-level write after each answer:
  Level 1 → `## Clarifications / ### Session YYYY-MM-DD` bullet
  Level 2 → Inline update to the relevant artifact section
```

- [ ] **Step 3: Commit**

```bash
git add skills/opsx-clarify/tests/baseline-failures.md
git commit -m "test(opsx-clarify): RED baseline — 6 failure modes without skill"
```

---

### Task 2: Write the Skill — GREEN

**Goal:** Write `skills/opsx-clarify/SKILL.md` that prevents all 6 failure modes documented in Task 1.

**Files:**
- Create: `skills/opsx-clarify/SKILL.md`

- [ ] **Step 1: Create the skill directory**

```bash
mkdir -p skills/opsx-clarify
```

- [ ] **Step 2: Write skills/opsx-clarify/SKILL.md**

Create `skills/opsx-clarify/SKILL.md` with this exact content:

````markdown
---
name: opsx:clarify
description: >
  Use when the user wants to clarify, refine, or fill gaps in an OpenSpec change proposal
  before implementing it. Triggered by "/opsx:clarify", "clarify my proposal",
  "fill gaps before applying", "refine the spec", "I want to clarify the change before
  implementing". Do NOT use for open-ended exploration (use /opsx:explore) or for
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
````

- [ ] **Step 3: Verify file was written correctly**

Check that the frontmatter name is exactly `opsx:clarify` and the description contains only trigger conditions (no workflow summary):

```bash
head -10 skills/opsx-clarify/SKILL.md
```

Expected output includes:
```
name: opsx:clarify
description: >
  Use when the user wants to clarify, refine, or fill gaps...
```

- [ ] **Step 4: Commit**

```bash
git add skills/opsx-clarify/SKILL.md
git commit -m "feat(opsx-clarify): GREEN — write opsx:clarify skill"
```

---

### Task 3: Install Globally

**Goal:** Write the skill to `~/.claude/skills/opsx-clarify/SKILL.md` so it is active in all projects without requiring re-installation.

**Files:**
- Write (not committed): `~/.claude/skills/opsx-clarify/SKILL.md`

- [ ] **Step 1: Create the global skill directory**

```bash
mkdir -p ~/.claude/skills/opsx-clarify
```

- [ ] **Step 2: Copy to global location**

```bash
cp skills/opsx-clarify/SKILL.md ~/.claude/skills/opsx-clarify/SKILL.md
```

- [ ] **Step 3: Verify installation**

```bash
head -5 ~/.claude/skills/opsx-clarify/SKILL.md
```

Expected:
```
---
name: opsx:clarify
description: >
```

- [ ] **Step 4: Commit**

```bash
git commit --allow-empty -m "chore(opsx-clarify): install skill globally at ~/.claude/skills/opsx-clarify/"
```

(No files to commit — the global copy is outside the repo. The empty commit marks the installation step as done for the SDD ledger.)

---

### Task 4: REFACTOR — Harden Against Weak Spots

**Goal:** Review both the project and global SKILL.md against the spec and known failure patterns. Fix any gaps found in both copies.

**Files:**
- Modify: `skills/opsx-clarify/SKILL.md`
- Modify: `~/.claude/skills/opsx-clarify/SKILL.md`

- [ ] **Step 1: Check SDO description completeness**

Read the description frontmatter in `skills/opsx-clarify/SKILL.md`. Verify it covers all these trigger phrases:
- `/opsx:clarify` ✓
- `/opsx:clarify <change-name>` (implied by argument handling)
- "clarify my proposal" ✓
- "fill gaps before applying" ✓
- "refine the spec" ✓
- "I want to clarify the change before implementing" ✓
- "fill in the gaps in the proposal"  ← check if present; add if missing
- "what's missing from my proposal" ← check if present; add if missing

If any trigger phrase is missing, add it to the description.

- [ ] **Step 2: Check AskUserQuestion is referenced correctly**

Search the SKILL.md for `AskUserQuestion`:

```bash
grep -n "AskUserQuestion" skills/opsx-clarify/SKILL.md
```

Must appear in Step 1 (Change Selection) for the multi-change case. If missing, add it.

- [ ] **Step 3: Check taxonomy coverage against speckit:clarify**

The speckit:clarify skill has 10 categories. Our taxonomy has 9. Verify the diff is intentional:

Speckit categories not in our taxonomy:
- "Misc / Placeholders" → merged into our "Placeholders" category ✓
- "Terminology & Consistency" → not listed separately

Add a "Terminology & consistency" row to the taxonomy table in Step 3 if it was omitted:

```
| Terminology & consistency | Canonical terms defined, avoided synonyms noted |
```

- [ ] **Step 4: Check Level 2 write-back covers all taxonomy categories**

In Step 5 (Incremental Write-Back), the Level 2 table must have a row for every taxonomy category. Cross-check:

| Taxonomy category | Level 2 row exists? |
|---|---|
| Functional scope | `proposal.md → ## What Changes` ✓ |
| Domain & data model | `design.md → data model section` ✓ |
| User flows & UX | (check — may be missing) |
| Non-functional | `design.md → add measurable criterion` ✓ |
| Integration & dependencies | (check — may be missing) |
| Edge cases & errors | `design.md → edge cases section` ✓ |
| Constraints & tradeoffs | (check — may be missing) |
| Completion signals | (check — may be missing) |
| Placeholders | `Replace placeholder in-place` ✓ |
| Terminology & consistency | `Normalize term across both files` ✓ |

For any category without a Level 2 row, add one:
```
| User flows / UX clarification | `design.md` → user flows section (create if missing) |
| Integration / dependency | `design.md` → integrations section (create if missing) |
| Constraint or tradeoff | `proposal.md` → `## Impact` section |
| Completion signal / DoD | `proposal.md` → `## Capabilities` (add acceptance criteria bullet) |
```

- [ ] **Step 5: Check Common Mistakes section completeness**

The Common Mistakes section must address all 6 RED baseline failures:

| Failure mode | Common Mistake entry covers it? |
|---|---|
| No structured change selection | (should be in Step 1 — not a mistake to document) |
| No taxonomy scan | (implicit in Step 3 — not a mistake per se) |
| No question cap | "Exceeding 5 questions" ✓ |
| No recommendation per question | (Step 4 format — check if there's a mistake entry) |
| No incremental write-back | "Writing all answers at the end" ✓ |
| Write-back is log-only | "Skipping Level 2 inline update" ✓ |

If "no recommendation per question" has no Common Mistakes entry, add:

```markdown
**Omitting recommendations:** Every question must include a "Recommended:" or "Suggested:"
line with reasoning. Presenting bare options without a recommendation defeats the skill's
purpose — users should be able to accept with "yes" without reading all options.
```

- [ ] **Step 6: Apply all fixes found in Steps 1-5 to skills/opsx-clarify/SKILL.md**

Edit the file to incorporate every finding. Then sync to global:

```bash
cp skills/opsx-clarify/SKILL.md ~/.claude/skills/opsx-clarify/SKILL.md
```

- [ ] **Step 7: Commit**

```bash
git add skills/opsx-clarify/SKILL.md
git commit -m "refactor(opsx-clarify): harden skill against weak spots found in review"
```
