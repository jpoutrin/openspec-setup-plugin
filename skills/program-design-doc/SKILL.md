---
name: program-design-doc
description: >
  Use when writing or updating the "## Program Design" section of an OpenSpec design.md — the
  call-stack shape, file changes, and typed signatures for a change that introduces a non-trivial
  new call flow, more than ~2 new functions/methods, or changes an existing call flow beyond a
  one-line edit. Triggered by "/opsx:propose", "/opsx:new", "/opsx:ff", "write the program design
  section", "design.md Program Design section", "plan the call stack for this change", "give
  typed signatures before implementing". Do NOT use for service/endpoint/schema-level
  architecture (use system-architecture-doc instead), and do NOT use to write actual
  implementation code — signatures only.
---

# program-design-doc

Decide the shape of the code — call stack, file changes, typed signatures — before
implementation begins, through an interactive context-gather → outline → detail flow.

**Does NOT describe services/endpoints/schemas (that's Architecture) or write function bodies.**

## Step 1: Confirm the section is warranted

Include "## Program Design" only when the change introduces a non-trivial new call flow, more
than ~2 new functions/methods, or changes an existing call flow beyond a one-line edit. If not,
respond: "This change is too small for a Program Design section — a one-line edit doesn't need
one." and stop.

## Step 2: Gather context

Read `proposal.md`, `design.md` (including any "## Architecture" section already written), and
the relevant `openspec/specs/` capability files.

Read `skills/setup/references/research-notes-backend.md` to find the research-notes file for
this change (created by system-architecture-doc, if it ran first). Append to that file rather
than creating a duplicate.

Dispatch:
- **codebase-analyzer** — understand the current call flow this change modifies or extends
- **codebase-pattern-finder** — find similar existing call-stack/file-organization patterns to model the new code after

## Step 3: Propose a structure outline

Before writing full detail, propose the high-level shape:

```
Proposed shape:
- New/modified files: [list, one line each on why]
- Functions crossing module boundaries: [names only]
- Call-flow change: [1-2 sentence summary]

Does this shape make sense before I write full signatures and diffs?
```

Get confirmation before proceeding to Step 4.

## Step 4: Write the Program Design section

Use `docs/program-design/TEMPLATE.md` as the section skeleton. Include, in this order:

1. **Call-stack diff tree** — for any control-flow change. Use diff syntax (+/-) when only part
   of the stack is changing; write the full tree when the flow is entirely new.
2. **File-tree diff** — every new/modified file, with a one-line reason per entry.
3. **Typed signatures** — fully-typed, no bodies, for every new/changed function that crosses a
   module boundary.

Scope discipline: this is the shape of the code, one level below Architecture. Do not write
function bodies. Do not re-describe services/endpoints/schemas already covered in "## Architecture".

## Step 5: Iterate

If the user requests a change after this section is written, make a surgical update to the
specific call-stack node, file-tree entry, or signature that changed — do not regenerate the
whole section.

## Step 6: Completion Report

```
Program Design section complete.

Files: N new, M modified
Module-boundary signatures: N
Call-stack diff: yes/no
design.md: "## Program Design" section written
```

## Common Mistakes

**Re-describing Architecture content:** If a sentence names a service, an endpoint, or a schema
relationship, it belongs in "## Architecture", not here. This section is call stacks, file
changes, and signatures only. (Prevents Failure 1)

**Skipping the call-stack diff tree:** Any control-flow change gets an explicit diff tree — not
a prose description of what changed. (Prevents Failure 2)

**Omitting the file-tree diff:** Always give a single file-tree diff view with one-line reasons
per entry — never scatter file mentions through prose. (Prevents Failure 3)

**Missing typed signatures:** Every new/changed function crossing a module boundary gets a full
signature before implementation starts. Naming a function without its signature is incomplete.
(Prevents Failure 4)

**Writing function bodies:** Signatures only. If you're tempted to write the body, stop — that's
implementation, which happens during `/opsx:apply`, not design. (Prevents Failure 5)

**Writing in one shot:** Always gather context, propose a structure outline, and get
confirmation before writing full detail. When the user requests changes, edit surgically — don't
rewrite the whole section. (Prevents Failure 6)
