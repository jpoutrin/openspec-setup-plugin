# program-design-doc — Baseline Failure Modes (RED)

Without the skill installed, an agent asked to write design.md's "## Program Design" section
exhibits these failures. The skill must prevent all of them.

---

## Failure 1: Conflated with Architecture — writes services instead of code shape

**Without skill:** Agent writes about services/endpoints/schemas again (duplicating or
contradicting the Architecture section) instead of the code-level shape: call stacks, file
changes, typed signatures.

**Expected behavior:** Program Design is one level below Architecture — the shape of the code,
decided before implementation. Never re-describe services/contracts here.

---

## Failure 2: No call-stack diff tree for control-flow changes

**Without skill:** A change to an existing call flow is described in prose ("the handler now
also validates X") with no explicit call-stack representation of what's added/changed/removed.

**Expected behavior:** Give a call-stack diff tree for any control-flow change, using diff
syntax (+/-) when only part of the stack is changing.

---

## Failure 3: No file-tree diff

**Without skill:** New/modified files are mentioned inline in prose, scattered through the
section, with no single tree view of what's new vs. modified and why.

**Expected behavior:** Give a file-tree diff showing what's new/modified, with a one-line
reason per entry.

---

## Failure 4: Missing typed signatures for module-boundary functions

**Without skill:** New/changed functions that cross a module boundary are referenced by name
only, with no parameter or return types given before implementation begins.

**Expected behavior:** Give fully-typed method/function signatures (not bodies) for every
new/changed function that crosses a module boundary.

---

## Failure 5: Writing implementation bodies instead of signatures

**Without skill:** The design phase leaks into implementation — full function bodies appear in
design.md instead of signatures, defeating the purpose of deciding shape before code.

**Expected behavior:** Signatures only. Implementation bodies belong in the actual code, written
during `/opsx:apply`, not in design.md.

---

## Failure 6: No interactive flow — written in one shot

**Without skill:** Agent writes the entire Program Design section in one pass with no context
gathering, no outline-and-confirm step, and no way to iterate before committing to the shape.

**Expected behavior:** Gather context (design.md, proposal.md, existing call flow) first,
propose a structure outline and get confirmation, then write full detail. Iterate via surgical
updates to the specific entries that change, not full rewrites.
