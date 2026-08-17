---
name: vertical-slice-planner
description: >
  Use when ordering or writing an OpenSpec tasks.md — sequencing tasks as vertical,
  independently-testable slices instead of horizontal architectural layers. Triggered by
  "/opsx:propose", "/opsx:apply", "/opsx:ff", "order these tasks", "write tasks.md", "break this
  into vertical slices", "plan the task breakdown", "sequence the implementation tasks". Do NOT
  use for proposal.md or design.md content, and do NOT use to group tasks by layer (models →
  services → serializers → endpoints) — that is the exact anti-pattern this skill prevents.
---

# vertical-slice-planner

Break each capability group's tasks into six vertically-ordered, independently-testable slices,
each with its own Automated/Manual Verification split and an explicit pause point.

**Does NOT write proposal.md or design.md content, and never groups tasks by architectural layer.**

## Step 1: Load the six-step slice model

Every capability group's tasks are ordered as:

1. Contract + mock data — verified with curl or equivalent
2. Frontend or consumer against the mock — iterated directly
3. Wire the real service behind the still-mocked boundary
4. Migrations and real data wiring
5. Business logic
6. Error handling

Each step must be independently testable/touchable before the next begins. Never write "all
models" → "all services" → "all serializers" → "all endpoints."

## Step 2: Map capability groups onto slices

For each capability group named in the proposal/design, break its tasks into the six numbered
steps above. Slot any stack-specific additions into the step they actually belong to:

- Django migrations → step 4 (migrations and real data wiring), not step 1
- `tsc --noEmit` → whichever step introduces the TypeScript change it's checking
- Accessibility verification → step 5 or 6, whichever introduces the UI behavior being checked

## Step 3: Write Automated/Manual Verification per slice

For each of the six steps, write two verification lists:

```
### Automated Verification:
- [ ] [command an execution agent can run — test, curl, type-check, lint]

### Manual Verification:
- [ ] [what a human must check by hand before the next slice starts]
```

After every slice's Automated Verification list, add:
> **Pause here for manual confirmation from the human that the manual testing succeeded before
> starting the next slice.**

## Step 4: Iterate

When review feedback requires re-ordering or re-scoping a slice, edit only the affected slice's
task entries — never regenerate the whole tasks.md. Preserve completed-task checkmarks and
unrelated group detail exactly as they were.

## Step 5: Completion Report

```
Vertical-slice task breakdown complete.

Capability groups: N
Slices per group: 6 (contract+mock, consumer, wire real service, migrations/data, business logic, error handling)
Stack-specific steps placed: [list, with the step number each landed on]
```

## Common Mistakes

**Grouping by layer:** Never write "all models" → "all services" → "all serializers" → "all
endpoints." Order by the six vertical-slice steps within each capability group instead.
(Prevents Failure 1)

**Leaving stub tasks that block on later tasks:** Every task in a group must be independently
runnable/verifiable on its own — not a skeleton waiting for a later task to fill in behavior.
(Prevents Failure 2)

**Writing one vague "test it" step:** Always split verification into an Automated Verification
list (agent-runnable commands) and a Manual Verification list (human checks). (Prevents Failure 3)

**No pause point:** After every slice's Automated Verification, explicitly instruct pausing for
human confirmation before the next slice starts. (Prevents Failure 4)

**Dumping stack-specific steps into their own group:** Place Django migrations, `tsc --noEmit`,
and similar stack-specific steps into the numbered vertical-slice step they belong to — never a
separate layer-named group. (Prevents Failure 5)

**Rewriting the whole tasks.md on feedback:** Re-sequence only the affected slice(s). A full
regeneration discards progress markers and unrelated task detail. (Prevents Failure 6)
