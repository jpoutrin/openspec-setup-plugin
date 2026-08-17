# Brownfield Phase Alignment (Architecture / Program Design / Vertical Slices) — Design Spec

**Date:** 2026-08-17
**Status:** Approved for implementation
**Source:** [Why Software Factories Fail](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/wsff.md) (Dex/HumanLayer, 2026) — the essay's "four phases" (Product Review, System Architecture, Program Design, Vertical Slices). Product Review is out of scope here (no ecosystem precedent found for it as an artifact — see `docs/research/brownfield-sdd/humanlayer-skills-research.md` in the keria-marketplace repo); this spec covers the remaining three.

---

## Overview

OpenSpec's default `spec-driven` schema (confirmed from the installed `@fission-ai/openspec@1.8.0` package: `schemas/spec-driven/schema.yaml`) has exactly four fixed artifacts — `proposal`, `specs`, `design`, `tasks` — each with its own template and instruction, shipped inside the global npm package. Custom artifact types require `openspec schema fork spec-driven <name>`, which diverges from the default/community workflow.

This spec **does not fork the schema**. It adds two clearly-labeled, independently-gated subsections inside the existing `design.md` artifact (`## Architecture`, `## Program Design`) and rewrites the `tasks:` rules for vertical-slice ordering — entirely through the `rules:` mechanism the plugin already uses, plus two new bundled reference templates (the same mechanism the existing `adr` fragment uses for `docs/adr/0001-template.md`).

**Revision (2026-08-17, post-Plannotator review):** rule text alone is a probabilistic instruction folded into whatever prompt OpenSpec's `/opsx:propose` builds — there's no guarantee an agent produces a good Architecture/Program Design section, or orders tasks vertically, from a bullet point alone. Rather than rely on "the agent will be smart enough," this plugin now **ships three new dedicated skills** — `system-architecture-doc`, `program-design-doc`, `vertical-slice-planner` — adapted from HumanLayer's own dogfooded (unpackaged) commands in `github.com/humanlayer/humanlayer`'s `.claude/commands/`. Each rule now names its skill explicitly, the way `worktree-workflow` names `superpowers:using-git-worktrees` and `clarify-step` names `/opsx:clarify`. See §4 for the adaptation details and the one open, untested assumption this introduces.

**Does NOT:**
- Fork or touch OpenSpec's own schema/templates (`design.md`'s actual template file is out of reach without forking)
- Add a Product Review artifact or phase (no ecosystem precedent; separate future spec if pursued)
- Change `schema-config`'s additive-only invariant, except for one narrow, explicitly-confirmed exception (see `vertical-slices` fragment below)

---

## Where this lands

Both a canonical default (new projects, via `/openspec:setup`) and an opt-in fragment (existing projects, via `/schema-config`):

| | Canonical default | Opt-in fragment | Dedicated skill |
|---|---|---|---|
| Architecture | `config-best-practices.md` → `design:` rules | new `system-architecture` fragment | `skills/system-architecture-doc/` |
| Program Design | `config-best-practices.md` → `design:` rules | new `program-design` fragment | `skills/program-design-doc/` |
| Vertical Slices | `config-best-practices.md` → `tasks:` rules | new `vertical-slices` fragment | `skills/vertical-slice-planner/` |

The three new skills ship as part of this plugin itself — unlike `clarify-step`'s cross-plugin dependency on `opsx-clarify`, there's no install-check needed: if `openspec-setup-plugin` is installed, all three are present.

---

## 1. Architecture subsection

**Independent inclusion trigger:** the change adds/modifies more than one service, endpoint, queue, or store, or changes how existing ones talk to each other.

**Rules (canonical, in `config-best-practices.md`'s `design:` list, and mirrored in the `system-architecture` fragment's config.yaml patch):**

```yaml
  design:
    - Include a "## Architecture" section whenever the change adds/modifies more than one service, endpoint, queue, or store, or changes how existing ones talk to each other.
    - "## Architecture" covers service/endpoint/schema/queue/store relationships only — no method signatures, call stacks, or file-level detail. That belongs in "## Program Design".
    - Use the system-architecture-doc skill to produce this section.
    - For any change involving more than one service or consumer, include a mermaid sequence diagram showing the request/message flow.
    - For new or changed endpoints, give the contract shape: method, path, request body, response body, status codes, error cases. See docs/architecture/TEMPLATE.md.
    - For new or changed data models, show the shape as a diff (added/changed/removed fields) — not prose.
```

The existing canonical bullets for field tables, migration implications, and stack-specific auth-scope additions (Django/DRF, HTMX, REST) stay as-is, just now explicitly grouped under this labeled subsection instead of a flat list.

---

## 2. Program Design subsection

**Independent inclusion trigger:** the change introduces a non-trivial new call flow, more than ~2 new functions/methods, or a change to an existing call flow that isn't a one-line edit.

**Rules (canonical, in `config-best-practices.md`'s `design:` list, and mirrored in the `program-design` fragment's config.yaml patch):**

```yaml
  design:
    - Include a "## Program Design" section whenever the change introduces a non-trivial new call flow, more than ~2 new functions/methods, or changes an existing call flow beyond a one-line edit.
    - "## Program Design" is one level below Architecture: the shape of the code itself, decided before implementation — not the architecture (services/contracts) and not the implementation (bodies).
    - Use the program-design-doc skill to produce this section.
    - Give a call-stack diff tree for any control-flow change — use diff syntax (+/-) when only part of the stack is changing. See docs/program-design/TEMPLATE.md.
    - Give a file-tree diff showing what's new/modified, with a one-line reason per entry.
    - Give fully-typed method/function signatures (not bodies) for every new or changed function that crosses a module boundary.
```

The "fully-typed signatures" bullet moves here from its current position in the flat `design:` list (previously the only nod to program design, buried among architecture bullets).

---

## 3. Vertical Slices — `tasks:` rule rewrite

**Problem:** the current canonical rule — *"Start each capability group with a stub task — typed model/service/serializer skeletons — before behavior tasks"* — is the horizontal/stack-order pattern the essay explicitly warns against: nothing is touchable/testable until every layer's stub exists.

**Replacement (canonical, in `config-best-practices.md`'s `tasks:` list):**

```yaml
  tasks:
    - Order tasks as vertical slices, not by architectural layer: (1) contract + mock data, verified with curl or equivalent, (2) frontend or consumer against the mock, iterated directly, (3) wire the real service behind the still-mocked boundary, (4) migrations and real data wiring, (5) business logic, (6) error handling. Each slice must be independently testable/touchable before the next begins.
    - Never group tasks as "all models" → "all services" → "all serializers" → "all endpoints." A capability group's tasks must each be individually runnable/verifiable, not stubs waiting on later groups.
    - Use the vertical-slice-planner skill to produce the task breakdown.
```

Stack-specific additions (Django migrations, TypeScript `tsc --noEmit`, etc.) are unaffected — they slot into whichever numbered step they belong to (e.g., Django migrations land at step 4, not step 1).

### The replace exception

Because this replaces rather than adds to an existing rule, it breaks `schema-config`'s additive-only invariant ("never replace or delete existing rules" — see `docs/superpowers/specs/2026-08-11-schema-config-design.md`). This is handled as **one narrow, explicitly-confirmed exception**, scoped only to this fragment:

- `vertical-slices` fragment Detection gains a second check: does `rules.tasks` contain the old stub-first rule text verbatim?
- If found, the fragment does **not** follow the normal Yes/Skip/Tell-me-more flow. Instead it presents a distinct prompt:
  > "Your project has the old stub-first task rule (`Start each capability group with a stub task...`), which conflicts with vertical-slice ordering. Replace it with the vertical-slice rule?"
  > AskUserQuestion: **Replace it / Keep both (not recommended) / Skip this fragment**
- **Replace it** → remove the old rule line, add the new one, and note the replacement explicitly in the completion report (`openspec/config.yaml ← 1 rule replaced (tasks: stub-first → vertical-slice ordering)`).
- **Keep both** → add the new rule alongside the old one, but the completion report must warn: "Both the old stub-first rule and the new vertical-slice rule are now active — these conflict. Recommend manually removing the stub-first rule."
- **Skip this fragment** → no change, same as any other Skip.
- If the old rule text is **not** found, `vertical-slices` behaves like every other fragment (pure addition, normal Yes/Skip/Tell-me-more flow).

This is the only fragment in the catalog with replace logic. No other fragment gains this capability.

---

## 4. New skills: `system-architecture-doc`, `program-design-doc`, `vertical-slice-planner`

### Why these exist

A config.yaml rule bullet is a probabilistic instruction folded into a larger generation prompt — it doesn't guarantee good output, and (this is the open assumption flagged below) it isn't even guaranteed to be read as an instruction to *invoke a skill* rather than just descriptive text. Each of the three subsections/rewrites above now has a dedicated skill backing it, mirroring how `worktree-workflow` names `superpowers:using-git-worktrees` and `clarify-step` names `/opsx:clarify` rather than relying on inline prose alone.

### Adaptation source: HumanLayer's dogfooded commands

Fetched directly from `github.com/humanlayer/humanlayer/.claude/commands/` (not packaged as skills there — repo-local commands): `research_codebase.md` (213 lines), `create_plan.md` (449 lines), `implement_plan.md` (84 lines), `iterate_plan.md` (249 lines), `validate_plan.md` (166 lines).

**Important finding from reading the full files (not just summaries):** these don't map 1:1 onto Architecture / Program Design / Vertical Slices. They're organized by *workflow stage* (research → plan → implement → iterate → validate), and `create_plan.md` in particular conflates architecture-level and program-design-level thinking into one generic "plan" with numbered phases — it doesn't use call-stack diff trees, file-tree diffs, or a services/contracts vs. types/signatures split anywhere. So each new skill is a **genuine adaptation**, not a port: process/interaction patterns come from HumanLayer, but the exact output shape for Architecture and Program Design comes from this plugin's own templates (§5) and the source essay, not from HumanLayer's format.

**Stripped entirely** (HumanLayer-specific, no equivalent in this plugin, no clean adaptation path): Linear ticket integration, GitHub permalink generation, and `thoughts-locator`/`thoughts-analyzer` (these two exist specifically to mine HumanLayer's multi-user `thoughts/alice/`, `thoughts/shared/` history — not applicable to the simplified single-folder version adopted here, see below).

**Ported (revised from the original "strip entirely" call, per 2026-08-17 Plannotator feedback):** the three codebase-research subagents — `codebase-locator.md` (122 lines — "super Grep/Glob/LS," finds WHERE code lives, documentarian-only, no critique), `codebase-analyzer.md` (143 lines — explains HOW existing code works, with file:line references), `codebase-pattern-finder.md` (227 lines — finds similar existing patterns to model a new feature after). Fetched directly from `github.com/humanlayer/humanlayer/.claude/agents/`. These are already environment-agnostic (no `thoughts/`, Linear, or HumanLayer-specific references in their own content) — they port with only cosmetic changes (e.g., stripping any HumanLayer-specific example text). They ship as new `.agents/codebase-locator.md`, `.agents/codebase-analyzer.md`, `.agents/codebase-pattern-finder.md` in this plugin, available as subagents to the three new skills (and to `openspec-expert`), replacing plain ad-hoc Read/Grep/Bash for grounding research.

### Pluggable research-notes backend

HumanLayer's `research_codebase.md`/`create_plan.md` write intermediate research findings into `thoughts/shared/research/` — a real gap OpenSpec doesn't otherwise fill (there's no schema artifact for "notes from researching the codebase before writing design.md"). But HumanLayer's actual `thoughts/` system (confirmed from `hlyr/THOUGHTS.md`) is a full separate feature: a private git repo (default `~/thoughts`) that your project's `thoughts/` folder symlinks into, with pre/post-commit git hooks for auto-sync and a `searchable/` hardlink directory — all driven by their own `hlyr` CLI. Requiring that as a dependency doesn't fit an OpenSpec-focused plugin.

**Resolution: detect per repo, matching this plugin's existing hook-manager-detection pattern** (see `setup` Phase 3 Step 3c's husky/lefthook/raw-git-hook detection):

- If `hlyr` is on `PATH` **and** this specific repo already has thoughts initialized (`hlyr thoughts status` succeeds) → write research notes into HumanLayer's system at `thoughts/shared/research/YYYY-MM-DD-<change-name>-research.md`, and run `hlyr thoughts sync` afterward.
- Otherwise → create (if missing) and use a plain local `thoughts/research/` directory, git-tracked normally as part of the project's own repo — no separate repo, no hooks, no `hlyr` dependency.

This detection is inherently per-repo: `hlyr thoughts init` is itself a per-repo mapping, so a repo that never ran it correctly falls through to the local-folder default — no new config.yaml field or explicit toggle needed.

This logic lives in one shared reference, **`skills/setup/references/research-notes-backend.md`**, read by all three new skills before writing any research notes (avoids duplicating the detection logic three times) — same "shared reference, multiple consumers" precedent as `config-best-practices.md`.

**Kept and adapted per skill:**

- **`system-architecture-doc`** (design.md's `## Architecture`) — adapts `create_plan.md`'s Step 2 "present findings and design options" pattern: ground in the actual codebase first (via the ported `codebase-locator`/`codebase-analyzer`/`codebase-pattern-finder` agents, plus `openspec-expert` for OpenSpec-specific context), then present 2-3 architecture options with trade-offs and get explicit user buy-in *before* writing the section — not writing it in one shot. Output scoped strictly to services/endpoints/schemas/queues/stores, per §1's rules, using `docs/architecture/TEMPLATE.md`.
- **`program-design-doc`** (design.md's `## Program Design`) — adapts `create_plan.md`'s overall interactive flow (context gathering → research → structure outline → detailed writing → iterate) but at program-design granularity. The output format itself (call-stack diff tree, file-tree diff, typed signatures) is **not** from HumanLayer — it's this plugin's own, per §2/§5 — HumanLayer's `create_plan.md` uses a different "Phase N: Changes Required / File / Changes" shape that doesn't match the essay's format.
- **`vertical-slice-planner`** (tasks.md ordering) — the strongest direct match: adapts `create_plan.md`'s per-phase **Automated Verification / Manual Verification** split almost directly, remapped from arbitrary phase names onto the six fixed vertical-slice steps from §3. Also adapts `implement_plan.md`'s "pause after each phase for manual verification before continuing" discipline, informing how tasks should be phrased so `/opsx:apply` naturally pauses at slice boundaries. `iterate_plan.md`'s "surgical update, don't rewrite" pattern informs how this skill handles re-sequencing slices after review feedback.

### File layout (matching this plugin's existing conventions)

```
.agents/
  codebase-locator.md          ← ported from humanlayer/humanlayer .claude/agents/
  codebase-analyzer.md         ← ported from humanlayer/humanlayer .claude/agents/
  codebase-pattern-finder.md   ← ported from humanlayer/humanlayer .claude/agents/
skills/
  system-architecture-doc/
    SKILL.md
    references/            (if needed — e.g. example sequence-diagram walkthroughs)
    tests/baseline-failures.md
  program-design-doc/
    SKILL.md
    references/
    tests/baseline-failures.md
  vertical-slice-planner/
    SKILL.md
    references/
    tests/baseline-failures.md
  setup/
    references/
      research-notes-backend.md   ← shared detection logic (new)
```

### Open, untested assumption — flag for implementation

Whether a `rules.design`/`rules.tasks` bullet like *"Use the system-architecture-doc skill to produce this section"* — injected into whatever prompt OpenSpec's own `/opsx:propose` (or `/opsx:new`/`/opsx:ff`) builds — actually causes the executing agent to fire the Skill tool, versus just reading it as one more descriptive sentence, **is not yet verified**. Skills are normally discovered by matching the executing agent's own intent against the skill's `description:` frontmatter, not by an instruction embedded in an arbitrary rules blob written by a different tool (OpenSpec) altogether.

Mitigations to carry into the implementation plan:
- Write each new skill's `description:` frontmatter for strong trigger-matching on its own terms (mentioning "OpenSpec", "design.md", "Architecture section" / "Program Design section" / "tasks.md ordering", "/opsx:propose", "/opsx:new" as trigger phrases) — so Claude Code's own semantic matching has the best chance of firing it independent of the rule-text hook.
- Add a manual smoke-test acceptance criterion: run `/opsx:propose` (or `/opsx:new`) on a test change that should trigger each section, and confirm the corresponding skill actually gets invoked (not just good output — actual Skill-tool invocation, observable in the transcript).
- If the smoke test shows the rule text alone doesn't reliably trigger invocation, the fallback is unchanged: the rule's own inline instructions (§1/§2/§3) plus the bundled templates (§5) still produce usable output without the skill firing — the skill is additive quality, not a hard dependency for the rules to function at all.

---

## 5. Bundled templates

Same mechanism as the existing `adr` fragment (`docs/adr/0001-template.md`). Canonical source files live under `skills/setup/references/` (referenced by both the canonical `setup` path and the two new fragments, matching the existing cross-skill reference precedent set by `clarify-step`, which references `skills/opsx-clarify/SKILL.md`):

- **`skills/setup/references/architecture-template.md`** → copied to `docs/architecture/TEMPLATE.md`:
  - Mermaid sequence diagram skeleton (placeholder participants/messages)
  - Endpoint contract table skeleton (method / path / request / response / status / errors)
  - Data model diff skeleton (added/changed/removed field list format)
- **`skills/setup/references/program-design-template.md`** → copied to `docs/program-design/TEMPLATE.md`:
  - Call-stack diff tree example (fenced diff block, +/- lines)
  - File-tree diff example (fenced diff block, NEW/MODIFIED annotations)
  - Typed signature block skeleton (language-agnostic placeholder)

**Canonical path (`setup` skill):** Phase 3, Step 3, gains a new step: always create both template files for new projects (unconditional — these become canonical defaults, unlike `adr` which stays fragment-only/opt-in). Skip creation if the file already exists (same "already exists — not overwritten" behavior as every other file-creation step in this plugin).

**Opt-in path (fragments):** each of `system-architecture` and `program-design` lists its own template file under "Files to create," created only when that specific fragment is selected — same behavior as the existing `adr` fragment.

---

## 6. Fragment catalog changes — `skills/schema-config/references/fragments.md`

Three new `## Fragment:` entries, same four-field shape (Description / Detection / config.yaml patch / Files to create) as every existing entry:

| Fragment | config.yaml sections | Supporting files | Special behavior |
|---|---|---|---|
| `system-architecture` | `rules.design` | `docs/architecture/TEMPLATE.md` | none |
| `program-design` | `rules.design` | `docs/program-design/TEMPLATE.md` | none |
| `vertical-slices` | `rules.tasks` | none | replace exception (see §3) |

**Detection criteria:**
- `system-architecture`: `rules.design` contains "Architecture" section marker OR `docs/architecture/` directory exists.
- `program-design`: `rules.design` contains "Program Design" section marker OR `docs/program-design/` directory exists.
- `vertical-slices`: `rules.tasks` contains "vertical slice" (Missing state) — plus the separate old-rule-text check described in §3, which only fires when Missing.

---

## 7. Skill orchestration changes

**`skills/schema-config/SKILL.md`:**
- Step 4's hardcoded catalog order (`adr → branch-naming → commit-conventions → epic-breakdown → clarify-step → worktree-workflow`) becomes: `adr → system-architecture → program-design → vertical-slices → branch-naming → commit-conventions → epic-breakdown → clarify-step → worktree-workflow` (grouping the three new design/architecture-adjacent fragments right after `adr`, before the process-oriented fragments).
- Step 6 gains the replace-exception branch for `vertical-slices` only (§3).
- "Common Mistakes" section gains an 8th entry: "Applying the vertical-slices replace exception to any other fragment" → Prevents Failure 8.

**`skills/schema-config/tests/baseline-failures.md`:**
- Failure 1's fragment list updated to the new 9-fragment catalog.
- New **Failure 8**: "No replace-exception handling — vertical-slices silently stacks a contradictory rule." Without skill: agent adds the new vertical-slice rule alongside the old stub-first rule with no warning, leaving both active. Expected: detect the old rule text, present the Replace/Keep both/Skip choice, and surface the conflict explicitly in the completion report if both are kept.

**`skills/setup/SKILL.md`:**
- Phase 3, Step 3 gains the "create architecture/program-design templates" sub-step (§5).
- The `config.yaml` interview/generation guidance references the restructured `design:` rule groups (Architecture / Program Design, each independently gated) instead of the old flat list.

**`README.md`:**
- `## Skills` gains three new entries — `system-architecture-doc`, `program-design-doc`, `vertical-slice-planner` — same format as the existing four (purpose, trigger examples).
- `## Plugin Structure` tree gains the three new `skills/*/` directories (§4).

---

## 8. Audit and setup visibility

Per 2026-08-17 Plannotator feedback: these principles shouldn't only take effect silently inside `config.yaml` — the two skills that touch OpenSpec readiness gain explicit surfacing.

**`skills/audit/SKILL.md`** — the "OpenSpec Status" block in the Audit Report gains three read-only checks, reusing the same Detection criteria as the `system-architecture`/`program-design`/`vertical-slices` fragments (§6) but without offering to apply anything — audit only reports:

```
### OpenSpec Status
- config.yaml: ✅ found
- Slash commands: ✅
- Architecture rules: ✅ present  /  ❌ missing → run /schema-config to add
- Program Design rules: ✅ present  /  ❌ missing → run /schema-config to add
- Vertical-slice task ordering: ✅ present  /  ⚠️ conflicting (old stub-first rule still active) → run /schema-config  /  ❌ missing → run /schema-config to add
```

This makes `audit` a complete, read-only preview of what `schema-config` would detect — consistent with `audit`'s existing "no changes, just report" contract.

**`skills/setup/SKILL.md`** — Phase 3's `config.yaml` interview gains a short explanatory note (not just silent application) before generating the `design:`/`tasks:` rules, e.g.:

> "I'm also adding three rules that keep AI-generated changes reviewable before code is written: an Architecture section for multi-service changes, a Program Design section for non-trivial new code shape, and vertical-slice task ordering instead of layer-by-layer stubs. Each is scoped to when it's actually needed — see docs/architecture/TEMPLATE.md and docs/program-design/TEMPLATE.md for the format."

Shown once, before the generated `config.yaml` is presented for confirmation (Step 3's existing "Does this look right?" gate) — not a new interactive question, just added context the engineer reads before approving.

---

## 9. Versioning

`.claude-plugin/plugin.json`: `1.0.0` → `1.1.0` (new capability — three new skills, three ported agents, plus rule/template/audit/setup changes — additive to existing skills, no breaking change to any existing fragment or command).

---

## Explicitly Out of Scope

- **Product Review** as a phase/artifact — no ecosystem precedent found (see HumanLayer research); would need its own spec if pursued later.
- **Schema forking** — no new first-class OpenSpec artifacts; everything stays inside `design.md` and `tasks.md`.
- **General replace/delete capability for schema-config** — the vertical-slices exception is scoped to that one fragment and one specific old-rule string; no other fragment gains replace logic.
- **Automated migration** of existing projects' `config.yaml` — the fragment flow requires explicit user confirmation via `/schema-config`; no silent rewrite of anyone's existing config.
- **Linear ticket integration, GitHub permalink generation, `thoughts-locator`/`thoughts-analyzer`** — no clean adaptation path (see §4). (Revised from the original blanket "skip all HumanLayer research infrastructure" call — `codebase-locator`/`codebase-analyzer`/`codebase-pattern-finder` are now ported, and a simplified, auto-detected `thoughts/research/` note-taking layer is included; see §4.)
- **HumanLayer's full `thoughts/` system** — the separate synced git repo, `hlyr` CLI dependency, symlinks, and git hooks. This plugin never requires installing `hlyr`; it only detects and uses it opportunistically if a repo already has it configured, falling back to a plain local folder otherwise (§4).
- **A general-purpose planning skill** matching HumanLayer's `create_plan.md`/`iterate_plan.md`/`validate_plan.md` scope — only the parts relevant to Architecture, Program Design, and vertical-slice task ordering are adapted; this plugin doesn't add an OpenSpec-wide equivalent to `/opsx:verify` (which OpenSpec's expanded profile already provides) or a general iterate-any-plan skill.
