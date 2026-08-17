# OpenSpec config.yaml — Best Practices

**Before adding or changing a "canonical, always include" rule, read
`skills/schema-config/references/propagation-checklist.md`** — canonical rules are mirrored into
`skills/schema-config/references/fragments.md` by design, and it's easy to update one and
silently miss the other.

Reference for generating or reviewing `openspec/config.yaml`. Use this when:
- Helping an engineer populate the file after `openspec init`
- Reviewing an existing config.yaml for quality or completeness
- Adapting the file for a new project type

---

## File structure

```yaml
schema: spec-driven          # always this value — do not change

context: |                   # multi-line block — project context injected into every artifact
  ## Project
  ...
  ## Stack
  ...
  ## Hard conventions
  ...
  ## Domain capabilities
  ...

rules:                       # per-artifact rules — each is one concrete, enforceable line
  proposal:
    - ...
  design:
    - ...
  specs:
    - ...
  tasks:
    - ...
```

---

## `context:` block

The context block is shown to the AI on every OpenSpec operation. Think of it as a project-scoped
CLAUDE.md embedded in OpenSpec. Keep it **in sync with CLAUDE.md** — if a convention exists in
both places, they must agree.

### Subsection: Project

```yaml
context: |
  ## Project
  <service-name>: one sentence on what the service does and its business purpose.
  Mention the domain (e.g., invoicing, auth, notifications), the architectural role (e.g., "owns the
  X lifecycle"), and any key constraint (e.g., "French data-retention rules apply").
```

**Rules:**
- 1–3 sentences maximum — longer is not read
- State what the service does, not how it is built (stack comes next)
- If replacing a prior system, name it and say why ("replaces X that used Y as state machine")

### Subsection: Stack

```yaml
  ## Stack
  - Runtime: [language + version], managed by [tool] (e.g., `uv run`, `nvm`, `asdf`).
  - Framework: [framework + version], any critical config (e.g., custom user model, UUID PKs).
  - Database: [db + version], how it runs (e.g., Docker Compose on Colima), any ORM constraint.
  - API layer: [DRF / FastAPI / Express], auth mechanism.
  - Background jobs: [Celery / Django-Q / BullMQ], broker.
  - Frontend: [HTMX / React / Next.js], build approach (server-rendered vs SPA).
  - Tooling: [linter, formatter, type checker, test framework].
```

**Rules:**
- Mention version numbers when they affect behavior (Python 3.12+ vs 3.10, Django 6 vs 4)
- Call out non-obvious tool usage (e.g., "always run Python via `uv run`", "use `docker-compose` binary not `docker compose`")
- Skip tools that have no agent-visible impact

### Subsection: Hard conventions (required)

```yaml
  ## Hard conventions
  - [One concrete, enforceable rule per bullet]
  - [Example: UUID primary keys everywhere. New models inherit apps.core.models.UUIDModel.]
  - [Example: Full type annotations required: mypy runs with disallow_untyped_defs = true.]
  - [Example: Modern typing: list[str] not List[str], X | None not Optional[X].]
  - [Example: Tests live in each app's tests/ package; factories in <app>/factories.py.]
  - [Example: Commands: make test, make lint, make typecheck, make runserver.]
```

**Rules:**
- Each line is testable in a code review — "write clean code" is not a convention
- Cover: import style, naming, typing approach, test location, commands
- 5–12 bullets is the right range; fewer = incomplete, more = not read
- **For weakly typed languages**, always include the maximum-strictness typing rule (see table below)

**Typing rule by language (include the matching bullet when the language is detected):**

| Language | Hard convention bullet to include |
|----------|----------------------------------|
| Python | `Full type annotations required on all functions and public variables; mypy runs with strict = true (or disallow_untyped_defs = true + disallow_any_generics = true). Modern syntax: list[str] not List[str], X \| None not Optional[X].` |
| JavaScript (no TS) | `TypeScript strict mode required (strict: true in tsconfig.json); no implicit any; all public functions carry explicit return types.` |
| PHP | `declare(strict_types=1) at the top of every file; PHPStan level 9 (or Psalm strict mode); all public methods carry typed parameters and return types.` |
| Ruby | `Sorbet strict mode (# typed: strict) in all non-generated files; @sig annotations on all public methods; no T.untyped in production code.` |
| Elixir | `@spec typespecs required on all public functions; Dialyzer runs in CI with no_return and unmatched_returns enabled.` |

### Subsection: Frontend conventions (if applicable)

Include only when there is a frontend layer with non-obvious conventions:

```yaml
  ## Frontend conventions
  - Rendering: [server-rendered templates + HTMX / SPA via React / SSR via Next.js]
  - Templates: [where full pages live, where partials live, how HTMX fragments are structured]
  - CSS: [no framework / Tailwind / hand-written BEM], token approach
  - State: [what stays client-side, what triggers a server round-trip]
  - Design system: [where to find it, which components are in the kit, how to add a new one]
  - Accessibility: [requirements, progressive enhancement rules]
```

### Subsection: Domain capabilities

```yaml
  ## Domain capabilities
  - `capability-name`: brief description of what this capability owns and its key API surface.
  - `capability-name`: [another bounded domain with its entry point]
```

**Rules:**
- One bullet per bounded capability — match the names in `openspec/specs/`
- Include the key API endpoint or entry point per capability (useful for proposals)
- Omit internal sub-modules; stay at the capability boundary level

---

## `rules:` section

Rules are injected into the AI prompt when generating each artifact type. Write each rule as a
**single, concrete, enforceable sentence** — the AI must be able to apply it without interpretation.

### `proposal:` rules

The proposal is the change entry point — it frames why and what, not how.

**Canonical rules to include:**

```yaml
rules:
  proposal:
    - Frame with the required sections in order — Why, What Changes, Capabilities, Impact.
    - Keep Why to 1-2 sentences on the problem and why now; put the how in design.
    - List each new capability under New Capabilities in kebab-case; it becomes specs/<name>/spec.md.
    - Only list Modified Capabilities when spec-level requirements change; check openspec/specs/ first.
    - Mark backward-incompatible changes with **BREAKING** and name the affected consumer.
    - Name new/changed models and API endpoints at a high level; leave fields and signatures to design.
    - State non-goals explicitly and name affected code, APIs, deps, env vars, and data migrations in Impact.
```

**Project-specific additions (add when relevant):**
- If there is a shared changelog or ADR process: "Link to the relevant ADR in the Why section."
- If there are multiple services: "Name the downstream services affected under Impact."
- If there is a staging/prod deploy process: "Flag migrations requiring coordinated deploy under Impact."

### `design:` rules

The design document is optional — include it only for changes with real design complexity.

**Canonical rules to include:**

```yaml
  design:
    - Include design.md only for cross-cutting, new-dependency, data-model, security, or migration complexity.
    - Use Context, Goals / Non-Goals, Decisions, Data Model, API & Interfaces, Risks / Trade-offs sections.
    - For every decision give the rationale and the alternatives considered (why X over Y).
    - Define each new/changed model as a field table (name, type, null, default, index, relation).
    - Call out migration and data-backfill implications for every model change.
    - For each API endpoint give method, path, auth scope, request body, response body, status codes, and error cases.
    - Format risks as [Risk] → Mitigation.
```

**Architecture subsection (independently gated — canonical, always include):**

```yaml
  design:
    - 'Include a "## Architecture" section whenever the change adds/modifies more than one service, endpoint, queue, or store, or changes how existing ones talk to each other.'
    - '"## Architecture" covers service/endpoint/schema/queue/store relationships only — no method signatures, call stacks, or file-level detail. That belongs in "## Program Design".'
    - Use the system-architecture-doc skill to produce this section.
    - For any change involving more than one service or consumer, include a mermaid sequence diagram showing the request/message flow.
    - 'For new or changed endpoints, give the contract shape: method, path, request body, response body, status codes, error cases. See docs/architecture/TEMPLATE.md.'
    - For new or changed data models, show the shape as a diff (added/changed/removed fields) — not prose.
```

**Program Design subsection (independently gated — canonical, always include):**

```yaml
  design:
    - 'Include a "## Program Design" section whenever the change introduces a non-trivial new call flow, more than ~2 new functions/methods, or changes an existing call flow beyond a one-line edit.'
    - '"## Program Design" is one level below Architecture: the shape of the code itself, decided before implementation — not the architecture (services/contracts) and not the implementation (bodies).'
    - Use the program-design-doc skill to produce this section.
    - Give a call-stack diff tree for any control-flow change — use diff syntax (+/-) when only part of the stack is changing. See docs/program-design/TEMPLATE.md.
    - Give a file-tree diff showing what's new/modified, with a one-line reason per entry.
    - Give fully-typed method/function signatures (not bodies) for every new or changed function that crosses a module boundary.
```

**Stack-specific additions:**

Django / DRF:
```yaml
    - State unique constraints, indexes, and enum/choices for each model; note migration type (nullable first, then constraint).
    - Specify auth scope per endpoint (OAuth2 scope, device-token, session, staff-only).
```

HTMX / server-rendered frontend:
```yaml
    - Decompose each view into one HTMX partial per swappable fragment; specify its hx-target, hx-swap, and trigger.
    - Name new design tokens (custom properties) before the component classes that use them.
```

REST API (any framework):
```yaml
    - Include an OpenAPI/Swagger excerpt for new endpoints when the contract is non-trivial.
```

### `specs:` rules

Specs are the behavioral source of truth — they assert WHAT, never HOW.

**Canonical rules to include:**

```yaml
  specs:
    - Create one spec.md per capability named in the proposal, under specs/<capability>/.
    - Group requirements under delta headers: ADDED, MODIFIED, REMOVED, or RENAMED Requirements.
    - MODIFIED requirements must copy the entire existing requirement block, then edit; never paste partial content.
    - REMOVED requirements must include **Reason** and **Migration** lines.
    - Write each requirement as ### Requirement: <name> using SHALL/MUST (never should/may).
    - Give every requirement at least one #### Scenario: <name> (exactly 4 hashtags) in WHEN/THEN bullet form.
    - Keep specs behavioral (WHAT) — assert observable outcomes; schemas and code stubs belong in design.
    - Make every requirement testable — each scenario maps to a test case.
```

**Common additions:**
- If there is a QA team: "Each scenario must include a **Given** (precondition) alongside WHEN/THEN."
- If specs drive contract tests: "API scenarios must name the endpoint and status code in the THEN clause."
- If there is a frontend: "For UI requirements, assert the user-visible outcome and the no-JS/degraded fallback."

### `tasks:` rules

Tasks are the implementation checklist — ordered, atomic, paired with tests.

**Canonical rules to include:**

```yaml
  tasks:
    - Group tasks under ## N. <Group> headings and write each as - [ ] N.M <description>.
    - Order tasks by dependency; keep each small enough to finish in one session.
    - 'Order tasks as vertical slices, not by architectural layer: (1) contract + mock data, verified with curl or equivalent, (2) frontend or consumer against the mock, iterated directly, (3) wire the real service behind the still-mocked boundary, (4) migrations and real data wiring, (5) business logic, (6) error handling. Each slice must be independently testable/touchable before the next begins.'
    - 'Never group tasks as "all models" → "all services" → "all serializers" → "all endpoints." A capability group''s tasks must each be individually runnable/verifiable, not stubs waiting on later groups.'
    - Use the vertical-slice-planner skill to produce the task breakdown.
    - Pair each code task with a test in the app's tests/ package.
    - Put every new function/method under full type hints; keep functions under ~30 lines.
    - Finish each group with verification tasks (lint, typecheck, test suite).
    - Never run /opsx:apply on a working tree with uncommitted changes — commit or stash all pending changes before applying a proposal.
    - Never run /opsx:sync on a working tree with uncommitted changes — commit or stash all pending changes before syncing specs.
    - Never run /opsx:archive on a working tree with uncommitted changes — commit or stash all pending changes before archiving a change.
```

**Stack-specific additions:**

Django:
```yaml
    - Create model migrations with make makemigrations; new models inherit UUIDModel.
    - Read secrets and external IDs from env (django-environ), never hardcoded.
```

HTMX:
```yaml
    - For UI work, return one partial per HTMX fragment and add CSS tokens before the component classes that use them.
    - Verify new UI for accessibility — semantic markup, labelled controls, keyboard operation, no-JS fallback.
    - When a UI partial or token changes, add/update its component-registry entry and confirm it renders in the styleguide.
```

TypeScript / Node.js:
```yaml
    - Run tsc --noEmit before marking any TypeScript task complete.
    - Prefer named exports; no default exports except for Next.js pages.
```

**Weakly typed language additions (include for the matching detected language):**

Python:
```yaml
    - Annotate every new function parameter and return type; run mypy --strict (or equivalent) before marking any task complete.
    - Use modern union syntax (X | None, list[str]) — never Optional, List, Dict from typing.
```

JavaScript (no TypeScript):
```yaml
    - All new code must be TypeScript; run tsc --noEmit before marking any task complete.
    - No implicit any — add explicit types if inference cannot resolve.
```

PHP:
```yaml
    - Add declare(strict_types=1) at the top of every new file.
    - Run PHPStan at level 9 (or Psalm in strict mode) before marking any task complete.
```

Ruby:
```yaml
    - Add # typed: strict to every new file; annotate all public methods with @sig before marking tasks complete.
    - No T.untyped in production code paths.
```

Elixir:
```yaml
    - Add @spec to every new public function before marking the task complete.
    - Run mix dialyzer in CI; resolve all no_return and unmatched_returns warnings.
```

---

## Checklist: is the config.yaml ready?

**`context:` block**
- [ ] Project subsection: ≤3 sentences, says what the service does
- [ ] Stack: version numbers and non-obvious tool usage noted
- [ ] Hard conventions: ≥5 specific, testable rules
- [ ] Domain capabilities: one bullet per spec in `openspec/specs/`
- [ ] Conventions are consistent with CLAUDE.md (no contradictions)

**`rules:` section**
- [ ] All four artifact types covered: proposal, design, specs, tasks
- [ ] Each rule is a single sentence — no "and also" rules
- [ ] Rules reference project-specific patterns (not just generic advice)
- [ ] Design rules name required sections explicitly
- [ ] Specs rules enforce SHALL/MUST and Scenario format
- [ ] Tasks rules pair code with tests and end each group with verification
- [ ] Tasks rules include the clean-repo guards for apply, sync, and archive (`Never run /opsx:apply / /opsx:sync / /opsx:archive on a working tree with uncommitted changes`)
- [ ] Design rules include the independently-gated Architecture and Program Design subsections (not just the base `design:` list) — see the "Architecture subsection" and "Program Design subsection" blocks above
- [ ] Tasks rules use vertical-slice ordering (contract → consumer → real service → data → logic → errors), not the old layer-first stub rule

**Common mistakes to avoid**
- Aspirational rules ("write clean code", "keep it simple") — too vague to enforce
- Rules that duplicate what OpenSpec already does by default — wasted space
- Context block that copies CLAUDE.md verbatim — summarize conventions, don't paste the whole file
- Missing domain capabilities — if a spec exists but is not listed, agents miss the connection
- Stale stack info — update when you change Python version, migrate from Redis, etc.
