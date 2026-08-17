# system-architecture-doc — Baseline Failure Modes (RED)

Without the skill installed, an agent asked to write design.md's "## Architecture" section
exhibits these failures. The skill must prevent all of them.

---

## Failure 1: No codebase grounding — architecture invented, not verified

**Without skill:** Agent writes a generic Architecture section describing services, endpoints,
or stores without first checking what actually exists — contradicts the real codebase or
invents relationships that aren't there.

**Expected behavior:** Dispatch `codebase-locator`, `codebase-analyzer`, and
`codebase-pattern-finder` (plus `openspec-expert` for OpenSpec-specific context) before drafting
anything. Ground every claim in what these subagents find.

---

## Failure 2: No options presented — single design with no buy-in

**Without skill:** Agent jumps straight to one architecture design and writes it into design.md
without presenting alternatives or getting explicit user agreement first.

**Expected behavior:** Present 2-3 distinct architecture options with trade-offs and a
recommendation. Get explicit buy-in (AskUserQuestion or equivalent) before writing the section.

---

## Failure 3: Missing sequence diagram for multi-service changes

**Without skill:** A change touching more than one service or consumer gets an Architecture
section with no sequence diagram — the request/message flow is only described in prose.

**Expected behavior:** Any change involving more than one service or consumer gets a mermaid
sequence diagram per `docs/architecture/TEMPLATE.md`.

---

## Failure 4: Incomplete endpoint contracts

**Without skill:** New/changed endpoints are documented with only a path and a one-line
description — method, request/response shape, status codes, or error cases are missing.

**Expected behavior:** Every new/changed endpoint gets the full contract shape: method, path,
request body, response body, status codes, error cases, per `docs/architecture/TEMPLATE.md`.

---

## Failure 5: Data model changes described as prose instead of diff

**Without skill:** New/changed data models are described in a paragraph ("we add a status field
to the Order model") instead of an explicit added/changed/removed diff.

**Expected behavior:** Every new/changed data model is shown as a diff (added/changed/removed
fields), never prose.

---

## Failure 6: Scope creep into Program Design territory

**Without skill:** The Architecture section includes method signatures, call stacks, or
file-level detail that belongs in "## Program Design" — the two sections blur together.

**Expected behavior:** Architecture covers service/endpoint/schema/queue/store relationships
only. Flag anything at the method/call-stack/file level for program-design-doc instead.

---

## Failure 7: No research notes persisted

**Without skill:** Research findings from grounding subagents are used once and discarded —
nothing is written down for later reference or for program-design-doc to build on.

**Expected behavior:** Write research findings to the backend selected by
`skills/setup/references/research-notes-backend.md` before drafting the section.
