# vertical-slice-planner — Baseline Failure Modes (RED)

Without the skill installed, an agent asked to write or order tasks.md exhibits these failures.
The skill must prevent all of them.

---

## Failure 1: Horizontal/layer ordering — the anti-pattern this skill exists to prevent

**Without skill:** Agent groups tasks as "all models" → "all services" → "all serializers" →
"all endpoints." Nothing is touchable or testable until every layer's stub exists.

**Expected behavior:** Order tasks as vertical slices: (1) contract + mock data, (2) consumer
against the mock, (3) wire the real service behind the still-mocked boundary, (4) migrations and
real data wiring, (5) business logic, (6) error handling.

---

## Failure 2: Tasks aren't independently testable

**Without skill:** A capability group starts with typed model/service/serializer skeletons as
stub tasks — nothing in the group can be run or verified until later tasks in the same group
complete.

**Expected behavior:** Each capability group's tasks must each be individually runnable and
verifiable, not stubs waiting on later tasks in the same group.

---

## Failure 3: No Automated/Manual Verification split

**Without skill:** Tasks list only a vague "test it" step, with no distinction between what an
execution agent can verify automatically and what requires a human to check by hand.

**Expected behavior:** Every slice lists Automated Verification (commands an agent can run) and
Manual Verification (what a human must check) separately.

---

## Failure 4: No pause discipline between slices

**Without skill:** Tasks are written to run straight through from slice to slice with no
explicit point where an execution agent should stop and wait for human confirmation that manual
testing succeeded.

**Expected behavior:** After a slice's automated verification passes, the task text explicitly
says to pause for manual confirmation before starting the next slice.

---

## Failure 5: Stack-specific tasks misplaced

**Without skill:** Stack-specific steps (e.g., Django migrations, `tsc --noEmit`) are dumped into
their own layer-named group instead of the numbered vertical-slice step they actually belong to.

**Expected behavior:** Slot stack-specific additions into the numbered step they belong to (e.g.,
Django migrations land at step 4 — migrations and real data wiring — not step 1).

---

## Failure 6: Full rewrite instead of surgical re-sequencing

**Without skill:** When review feedback requires re-ordering slices, the agent regenerates the
entire tasks.md from scratch, discarding unrelated task detail and progress markers.

**Expected behavior:** Re-sequence only the affected slice(s) — a surgical update, not a rewrite
of the whole tasks.md.
