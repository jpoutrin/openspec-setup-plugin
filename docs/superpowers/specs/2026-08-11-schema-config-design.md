# schema-config — Design Spec

**Date:** 2026-08-11  
**Status:** Approved for implementation

---

## Overview

`schema-config` is a workflow configurator skill. It reads the project's existing `openspec/config.yaml`, detects which workflow fragments are already configured, walks the user through adding the missing ones one at a time, then writes everything in a single confirmed pass.

**Does NOT:**
- Replace `/opsx:clarify` or any core OpenSpec command
- Auto-run on project setup — always explicit user invocation
- Create OpenSpec change proposals — writes config directly

---

## Invocation

**Skill file:** `skills/schema-config/SKILL.md`  
**Catalog file:** `skills/schema-config/references/fragments.md`

**Trigger phrases:** `/schema-config`, "configure my workflow", "add workflow schemas", "set up ADR", "add commit conventions to OpenSpec", "configure clarify step"

**Relationship to session-retrospective:** Soft handoff only — `session-retrospective` may suggest running `/schema-config` when it detects a workflow gap, but the user invokes it manually. No programmatic coupling between the two skills.

---

## Fragment Catalog

The catalog lives in `skills/schema-config/references/fragments.md`. Each fragment is a named section with four fields: **Description**, **Detection**, **config.yaml patch**, and **Files to create**.

### Fragment set (initial catalog)

| Fragment | config.yaml sections | Supporting files |
|---|---|---|
| `adr` | `rules.proposal`, `rules.tasks` | `docs/adr/0001-template.md` |
| `branch-naming` | `rules.tasks` | none |
| `commit-conventions` | `rules.tasks` | none |
| `epic-breakdown` | `rules.proposal` | none |
| `clarify-step` | `rules.tasks` | verify/copy `~/.claude/skills/opsx-clarify/SKILL.md` |
| `worktree-workflow` | `rules.tasks`, `operations.apply` | none |

### Fragment reference file format

Each fragment in `fragments.md` is a `## Fragment: <name>` section:

```markdown
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
- `docs/adr/0001-template.md` — standard ADR template (title, status, context, decision, consequences)
```

### Fragment definitions

**`adr`**
- Proposal rule: link to ADR when a significant architectural decision is made
- Tasks rule: create an ADR for hard-to-reverse decisions
- Creates: `docs/adr/0001-template.md`
- Detection: "adr" in any tasks/proposal rule OR `docs/adr/` exists

**`branch-naming`**
- Proposal rule: use `spec/<change-name>` branches for spec work (proposal + design + spec-delta); merge to main before starting implementation
- Tasks rule: use `feat/`, `fix/`, `refactor/`, `chore/`, `docs/` branches for the apply step (implementation); branch from main after the spec branch is merged
- Enforces the two-phase branch model: spec work is separate from implementation work and lands first
- Detection: "branch" or "spec/" or "feat/" in any proposal/tasks rule

**`commit-conventions`**
- Tasks rule: conventional commit format — `type(scope): description` where type ∈ {feat, fix, docs, refactor, test, chore}
- Detection: "conventional" or "commit" in any tasks rule

**`epic-breakdown`**
- Proposal rule: for changes spanning more than 3 capabilities or 2 weeks of work, split into sub-proposals — one per independently deliverable slice
- Detection: "epic" or "sub-proposal" in any proposal rule

**`clarify-step`**
- Tasks rule: run `/opsx:clarify` before `/opsx:apply` to fill proposal gaps
- Install check: verify `~/.claude/skills/opsx-clarify/SKILL.md` exists; if missing, copy from `skills/opsx-clarify/SKILL.md`
- Detection: "clarify" in any tasks rule OR `~/.claude/skills/opsx-clarify/SKILL.md` present AND rule already exists

**`worktree-workflow`**
- Tasks rule: before `/opsx:apply`, create an isolated worktree using `superpowers:using-git-worktrees`; never implement on main/master directly
- Operations patch: `operations.apply` guidance to always run from inside a worktree
- Detection: "worktree" in any tasks rule OR `operations.apply` contains "worktree" OR `.worktrees/` directory exists

---

## Skill Flow

```
1. Load catalog      Read skills/schema-config/references/fragments.md

2. Scan              Read openspec/config.yaml — mark each fragment Clear or Missing

3. Report            Show what's already configured (one line each), list what's missing

4. Sequential loop   For each missing fragment (in catalog order):
                       - Show fragment name + description + what it adds
                       - AskUserQuestion: "Add this fragment?" [Yes / Skip / Tell me more]
                       - "Tell me more" → show the full config.yaml patch inline, re-ask
                       - Record selections; skip if user selects Skip

5. Consolidated plan Show everything that will be written before touching any file:
                       - config.yaml additions grouped by fragment
                       - Files to create
                       - Install checks (clarify-step)
                       AskUserQuestion: "Apply all of this?" [Yes / Edit first / Cancel]

6. Write             Apply config.yaml patches → create supporting files → run install checks

7. Validate          openspec validate

8. Report            Confirm what was written; list any manual follow-up steps
```

**Early stops:**
- `openspec/config.yaml` not found → "Run `/openspec:setup` or `openspec init` first." Stop.
- All fragments already present → "All workflow fragments already configured." Stop.
- User selects Skip for every fragment in the loop → "No fragments selected. Nothing written." Stop.

---

## Write Behavior

### config.yaml patching

Append fragment rules to the existing rules list — never replace existing rules. Before appending, scan the target list for duplicate intent (e.g., if `rules.tasks` already contains "worktree", skip that fragment's task rule silently). Run `openspec validate` immediately after writing.

### Supporting files

Create only if the file does not already exist. If it exists, skip and note it in the completion report ("already exists — not overwritten").

### clarify-step install check

```bash
ls ~/.claude/skills/opsx-clarify/SKILL.md
```

- Present → add config.yaml rule only
- Missing, project copy exists → copy `skills/opsx-clarify/SKILL.md` → `~/.claude/skills/opsx-clarify/SKILL.md`, then add rule
- Missing, project copy also missing → tell the user: "opsx:clarify skill not found. Install it first, then re-run `/schema-config`." Skip this fragment.

### worktree-workflow

No files created. Add to the completion report:
> "Added worktree rules. To use: invoke `superpowers:using-git-worktrees` before your next `/opsx:apply`."

---

## Completion Report Format

```
schema-config complete.

Applied fragments: adr, commit-conventions, clarify-step

Changes written:
  openspec/config.yaml  ← 5 rules added (proposal: 1, tasks: 3, operations: 1)
  docs/adr/0001-template.md  ← created
  ~/.claude/skills/opsx-clarify/SKILL.md  ← installed

Skipped fragments: branch-naming (already configured), epic-breakdown (user skipped)

Validation: openspec validate ✅

Follow-up:
  - Fill in the context: block in config.yaml if not done (/openspec:setup Phase 3)
  - Review docs/adr/0001-template.md and adjust to your team's ADR format
```

---

## SDO Description (Skill Discovery Optimization)

The `description:` frontmatter contains only trigger conditions:

```yaml
description: >
  Use when the user wants to configure workflow schemas or add workflow fragments to an OpenSpec
  project. Triggered by "/schema-config", "configure my workflow", "add workflow schemas",
  "set up ADR", "add commit conventions to OpenSpec", "configure clarify step",
  "add worktree workflow", "add branch naming conventions". Do NOT use for creating change
  proposals (use /opsx:propose) or for exploring a codebase (use /opsx:explore).
```

---

## File Structure

```
skills/
  schema-config/
    SKILL.md                          ← orchestration logic
    references/
      fragments.md                    ← fragment catalog (data)
```

---

## Explicitly Out of Scope

- Custom fragment authoring UI — users extend `fragments.md` directly
- Forking or creating custom OpenSpec schemas (`openspec schema fork`) — this is config.yaml rules only
- Running on projects without `openspec/config.yaml` — always requires OpenSpec to be initialized first
- Automatic invocation from `session-retrospective` — soft handoff only
