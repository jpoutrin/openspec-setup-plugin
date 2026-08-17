---
name: system-architecture-doc
description: >
  Use when writing or updating the "## Architecture" section of an OpenSpec design.md — service,
  endpoint, queue, schema, or store relationships for a change that adds/modifies more than one
  service, endpoint, queue, or store, or changes how existing ones talk to each other. Triggered
  by "/opsx:propose", "/opsx:new", "/opsx:ff", "write the architecture section", "design.md
  Architecture section", "document the system architecture for this change", "add a sequence
  diagram for this change", "define the endpoint contract". Do NOT use for changes with no
  cross-service impact (no Architecture section needed), and do NOT use for method-signature,
  call-stack, or file-level detail — that belongs to program-design-doc.
---

# system-architecture-doc

Ground an Architecture section in the actual codebase, present real design options, get
explicit buy-in, then write "## Architecture" into design.md scoped strictly to
service/endpoint/schema/queue/store relationships.

**Does NOT write method signatures, call stacks, or file-level detail — that's program-design-doc's job.**

## Step 1: Confirm the section is warranted

Include "## Architecture" only when the change adds/modifies more than one service, endpoint,
queue, or store, or changes how existing ones talk to each other. If not, respond: "This change
doesn't touch more than one service/endpoint/store — no Architecture section needed." and stop.

## Step 2: Ground in the codebase

Read `skills/setup/references/research-notes-backend.md` to determine the research-notes backend
for this repo (hlyr-backed `thoughts/shared/research/` or local `thoughts/research/`).

Dispatch, in parallel:
- **codebase-locator** — find all files related to the services/endpoints/stores this change touches
- **codebase-analyzer** — understand how the current implementation of those services/endpoints works
- **codebase-pattern-finder** — find similar existing service/endpoint patterns to model after
- **openspec-expert** — check `openspec/specs/` for existing capability boundaries this change interacts with

Read every file these subagents identify as relevant, in full, before proceeding.

Write findings to the backend-selected research notes file at
`<backend-path>/YYYY-MM-DD-<change-name>-research.md` — capture what subagents found, key
file:line references, and open questions.

## Step 3: Present architecture options

Based on the research, draft 2-3 distinct architecture options (e.g., differing on where a new
service boundary sits, sync vs. async integration, which service owns a schema). For each:

```
Option [A/B/C]: [name]
- [1-2 sentence description]
- Pros: [...]
- Cons: [...]
```

State a recommendation. Use **AskUserQuestion** to get explicit agreement on one option before
writing anything into design.md.

## Step 4: Write the Architecture section

Use `docs/architecture/TEMPLATE.md` as the section skeleton. Include, in this order:

1. **Sequence diagram** (mermaid) — required whenever the change involves more than one service
   or consumer. Show the actual request/message flow for the chosen option.
2. **Endpoint contracts** — for every new/changed endpoint: method, path, request body, response
   body, status codes, error cases.
3. **Data model diff** — for every new/changed data model, as an added/changed/removed field
   diff, never prose.

Scope discipline: this section covers service/endpoint/schema/queue/store relationships only.
If you find yourself writing a function signature, a call stack, or a file path with a reason
for changing — stop, that content belongs in "## Program Design" (flag it, don't write it here).

## Step 5: Completion Report

```
Architecture section complete.

Research: [subagents dispatched] — notes written to [backend path]
Option chosen: [A/B/C] — [one-line reason]
design.md: "## Architecture" section written (sequence diagram: yes/no, endpoints: N, models: N)
```

## Common Mistakes

**Writing from assumption instead of grounding:** Always dispatch codebase-locator,
codebase-analyzer, codebase-pattern-finder, and openspec-expert before drafting. Never describe
a service/endpoint/store relationship you haven't verified against the actual codebase.
(Prevents Failure 1)

**Skipping the options step:** Never write directly to one design. Present 2-3 options with
trade-offs and get explicit buy-in via AskUserQuestion first. (Prevents Failure 2)

**Omitting the sequence diagram:** Any change touching more than one service or consumer gets a
mermaid sequence diagram — no exceptions. (Prevents Failure 3)

**Writing incomplete endpoint contracts:** Every new/changed endpoint needs all six fields:
method, path, request body, response body, status codes, error cases. A path alone is not a
contract. (Prevents Failure 4)

**Describing data model changes in prose:** Always show data model changes as an
added/changed/removed field diff — never as a descriptive paragraph. (Prevents Failure 5)

**Bleeding into Program Design territory:** If a claim requires a function signature, a call
stack, or a specific file path with a change reason, it belongs in program-design-doc, not here.
Keep this section at the service/endpoint/schema/store level. (Prevents Failure 6)

**Discarding research findings:** Always write grounding research to the backend selected by
research-notes-backend.md before drafting the section — program-design-doc reuses these notes.
(Prevents Failure 7)
