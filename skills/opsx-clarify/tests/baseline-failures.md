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

**Expected behavior:** Internal scan against 10 taxonomy categories. Each category marked
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
