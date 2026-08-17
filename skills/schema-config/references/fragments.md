# schema-config Fragment Catalog

Each fragment is a workflow convention that can be added to a project's `openspec/config.yaml`.
The skill reads this file to discover what to offer and how to apply each fragment.

---

## Fragment: adr

**Description:** Architecture Decision Records — structured docs for significant technical decisions.

**Detection:** `rules.proposal` or `rules.tasks` contains "adr" OR `docs/adr/` directory exists.

**config.yaml patch:**
```yaml
rules:
  proposal:
    - Link to the relevant ADR in docs/adr/ when a significant architectural decision is made.
  tasks:
    - Create an ADR in docs/adr/ for any decision that affects system architecture or is hard to reverse.
```

**Files to create:**
- `docs/adr/0001-template.md` — standard ADR template

Content of `docs/adr/0001-template.md`: copy from `skills/schema-config/references/adr-template.md`

---

## Fragment: system-architecture

**Description:** Adds a required "## Architecture" section to design.md for changes touching more than one service, endpoint, queue, or store — scoped to service/endpoint/schema/queue/store relationships only, produced via the system-architecture-doc skill.

**Detection:** `rules.design` contains the literal string `Include a "## Architecture" section whenever` OR `docs/architecture/` directory exists.

**config.yaml patch:**
```yaml
rules:
  design:
    - 'Include a "## Architecture" section whenever the change adds/modifies more than one service, endpoint, queue, or store, or changes how existing ones talk to each other.'
    - '"## Architecture" covers service/endpoint/schema/queue/store relationships only — no method signatures, call stacks, or file-level detail. That belongs in "## Program Design".'
    - Use the system-architecture-doc skill to produce this section.
    - For any change involving more than one service or consumer, include a mermaid sequence diagram showing the request/message flow.
    - 'For new or changed endpoints, give the contract shape: method, path, request body, response body, status codes, error cases. See docs/architecture/TEMPLATE.md.'
    - For new or changed data models, show the shape as a diff (added/changed/removed fields) — not prose.
```

**Files to create:**
- `docs/architecture/TEMPLATE.md` — copy from `skills/setup/references/architecture-template.md`

---

## Fragment: program-design

**Description:** Adds a required "## Program Design" section to design.md for changes with non-trivial new call flow — call-stack diff tree, file-tree diff, and typed signatures, produced via the program-design-doc skill.

**Detection:** `rules.design` contains the literal string `Include a "## Program Design" section whenever` OR `docs/program-design/` directory exists.

**config.yaml patch:**
```yaml
rules:
  design:
    - 'Include a "## Program Design" section whenever the change introduces a non-trivial new call flow, more than ~2 new functions/methods, or changes an existing call flow beyond a one-line edit.'
    - '"## Program Design" is one level below Architecture: the shape of the code itself, decided before implementation — not the architecture (services/contracts) and not the implementation (bodies).'
    - Use the program-design-doc skill to produce this section.
    - Give a call-stack diff tree for any control-flow change — use diff syntax (+/-) when only part of the stack is changing. See docs/program-design/TEMPLATE.md.
    - Give a file-tree diff showing what's new/modified, with a one-line reason per entry.
    - Give fully-typed method/function signatures (not bodies) for every new or changed function that crosses a module boundary.
```

**Files to create:**
- `docs/program-design/TEMPLATE.md` — copy from `skills/setup/references/program-design-template.md`

---

## Fragment: vertical-slices

**Description:** Replaces the horizontal stub-first task ordering with vertical-slice ordering — each capability group's tasks progress contract → consumer → real service → data → logic → errors, each independently testable, produced via the vertical-slice-planner skill.

**Detection:** `rules.tasks` contains "vertical slice" (Missing state) — plus the replace-exception check below, which only runs when Missing.

**config.yaml patch:**
```yaml
rules:
  tasks:
    - 'Order tasks as vertical slices, not by architectural layer: (1) contract + mock data, verified with curl or equivalent, (2) frontend or consumer against the mock, iterated directly, (3) wire the real service behind the still-mocked boundary, (4) migrations and real data wiring, (5) business logic, (6) error handling. Each slice must be independently testable/touchable before the next begins.'
    - 'Never group tasks as "all models" → "all services" → "all serializers" → "all endpoints." A capability group''s tasks must each be individually runnable/verifiable, not stubs waiting on later groups.'
    - Use the vertical-slice-planner skill to produce the task breakdown.
```

**Files to create:** none

**Replace exception (this is the only fragment in the catalog with replace logic — do not apply this pattern to any other fragment):**

Before presenting this fragment normally, check whether `rules.tasks` contains the old
stub-first rule text verbatim: `Start each capability group with a stub task — typed
model/service/serializer skeletons — before behavior tasks.`

- **If found:** do not use the normal Yes/Skip/Tell-me-more flow. Instead present:
  > "Your project has the old stub-first task rule (`Start each capability group with a stub
  > task...`), which conflicts with vertical-slice ordering. Replace it with the vertical-slice
  > rule?"
  >
  > AskUserQuestion: **Replace it / Keep both (not recommended) / Skip this fragment**
  - **Replace it** → remove the old rule line, add the new `vertical-slices` rules, and note the
    replacement explicitly in the completion report:
    `openspec/config.yaml ← 1 rule replaced (tasks: stub-first → vertical-slice ordering)`
  - **Keep both** → add the new rules alongside the old one, but the completion report must warn:
    "Both the old stub-first rule and the new vertical-slice rule are now active — these
    conflict. Recommend manually removing the stub-first rule."
  - **Skip this fragment** → no change, same as any other Skip.
- **If not found:** behave like every other fragment — pure addition, normal Yes/Skip/Tell-me-more flow.

---

## Fragment: branch-naming

**Description:** Enforces a two-phase branch model — spec branches for OpenSpec planning work, implementation branches for applying specs via `/opsx:apply`.

**Detection:** `rules.proposal` or `rules.tasks` contains "spec/" or "branch naming" or "feat/".

**config.yaml patch:**
```yaml
rules:
  proposal:
    - Create a `spec/<change-name>` branch for all spec work (proposal.md, design.md). Merge this branch to main before starting implementation.
  tasks:
    - After the spec branch is merged to main, create a `feat/<change-name>`, `fix/<change-name>`, `refactor/<change-name>`, `chore/<change-name>`, or `docs/<change-name>` branch for the /opsx:apply implementation step.
```

**Files to create:** none

---

## Fragment: commit-conventions

**Description:** Conventional Commits format for all git commits in the project.

**Detection:** `rules.tasks` contains "conventional commit" or "conventional commits".

**config.yaml patch:**
```yaml
rules:
  tasks:
    - Use conventional commit format for all commits: `type(scope): description` where type ∈ {feat, fix, docs, refactor, test, chore}. Keep description under 72 characters.
```

**Files to create:** none

---

## Fragment: epic-breakdown

**Description:** Splits large changes into independently deliverable sub-proposals.

**Detection:** `rules.proposal` contains "epic" or "sub-proposal".

**config.yaml patch:**
```yaml
rules:
  proposal:
    - For changes spanning more than 3 capabilities or more than 2 weeks of work, split into sub-proposals — one per independently deliverable slice. Each sub-proposal must be deployable on its own.
```

**Files to create:** none

---

## Fragment: clarify-step

**Description:** Requires running `/opsx:clarify` before `/opsx:apply` to fill proposal gaps before implementation begins.

**Detection:** `rules.tasks` contains "clarify".

**config.yaml patch:**
```yaml
rules:
  tasks:
    - Before running /opsx:apply, run /opsx:clarify to resolve any ambiguities in the proposal. Do not start implementation if critical gaps remain.
```

**Files to create:** none

**Install check:** Verify `~/.claude/skills/opsx-clarify/SKILL.md` exists before writing this rule. If missing, attempt to copy from `skills/opsx-clarify/SKILL.md`. See skill orchestration (Step 6) for the three-path fallback logic.

---

## Fragment: worktree-workflow

**Description:** Isolates each `/opsx:apply` run in a git worktree — never implements directly on main or master.

**Detection:** `rules.tasks` or `operations.apply` contains "worktree" OR `.worktrees/` directory exists.

**config.yaml patch:**
```yaml
rules:
  tasks:
    - Before /opsx:apply, create an isolated worktree using superpowers:using-git-worktrees. Never implement directly on main or master.
operations:
  apply:
    - Always run /opsx:apply from inside a worktree created by superpowers:using-git-worktrees.
```

**Files to create:** none

**Completion note:** After writing this fragment, the completion report must include:
"Added worktree rules. To use: invoke `superpowers:using-git-worktrees` before your next `/opsx:apply`."
