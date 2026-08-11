# schema-config Skill — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the `schema-config` skill — a workflow schema configurator that scans `openspec/config.yaml` for missing workflow fragments, walks the user through adding them one at a time, and writes config.yaml + supporting files in a single confirmed pass.

**Architecture:** Two-file skill — `references/fragments.md` is a pure-data catalog of 6 fragment definitions; `SKILL.md` is the orchestration logic that reads the catalog, marks each entry Clear or Missing by scanning config.yaml, presents missing fragments sequentially, shows a consolidated write plan for confirmation, then writes everything in one pass. TDD for skills: RED baseline first, then GREEN content.

**Tech Stack:** Markdown (SKILL.md + fragments.md), Claude Code skills runtime, OpenSpec CLI (`openspec validate`), Bash (`ls`, `cp`, `mkdir`).

## Global Constraints

- SDO rule: `description:` frontmatter contains ONLY trigger conditions — no workflow summary
- Fragment catalog path: `skills/schema-config/references/fragments.md`
- Global install path: `~/.claude/skills/schema-config/SKILL.md`
- Fragment names (exact): `adr`, `branch-naming`, `commit-conventions`, `epic-breakdown`, `clarify-step`, `worktree-workflow`
- `openspec validate` must be run after every config.yaml write
- branch-naming fragment enforces two-phase model: `spec/<name>` for spec work (merged to main before implementation) → `feat/fix/etc.` for `/opsx:apply`
- Never use plain `make` — always `/usr/bin/make`
- All work on `main` directly (no feature branches)
- Push command: `unset GITHUB_TOKEN && unset GH_TOKEN && git push origin main`
- Commit format: conventional commits (`feat(schema-config): ...`)

---

## File Structure

```
skills/
  schema-config/
    SKILL.md                          ← CREATE: project-committed skill orchestration
    references/
      fragments.md                    ← CREATE: fragment catalog (data file)
    tests/
      baseline-failures.md           ← CREATE: RED behavioral test doc

~/.claude/skills/
  schema-config/
    SKILL.md                         ← WRITE (not committed): globally installed copy
```

Spec doc: `docs/superpowers/specs/2026-08-11-schema-config-design.md`

---

### Task 1: Baseline RED Test — Document Failure Modes Without the Skill

**Goal:** Establish the behavioral acceptance criteria. Document exactly what goes wrong when an agent handles "configure my workflow" without the skill installed. The SKILL.md in Task 3 must prevent all of them.

**Files:**
- Create: `skills/schema-config/tests/baseline-failures.md`

- [ ] **Step 1: Create the tests directory**

```bash
mkdir -p /Users/jeremiepoutrin/projects/github/jpoutrin/openspec-setup-plugin/skills/schema-config/tests
```

- [ ] **Step 2: Write baseline-failures.md**

Create `skills/schema-config/tests/baseline-failures.md` with this exact content:

```markdown
# schema-config — Baseline Failure Modes (RED)

Without the skill installed, an agent asked to "configure my workflow" exhibits these failures.
The skill must prevent all of them.

---

## Failure 1: No catalog scan — manual guessing

**Without skill:** Agent improvises fragment names and rules based on what "seems right."
Guesses at config.yaml structure. Misses the canonical fragment set (`adr`, `branch-naming`,
`commit-conventions`, `epic-breakdown`, `clarify-step`, `worktree-workflow`).

**Expected behavior:** Read `skills/schema-config/references/fragments.md` at skill start.
Treat it as the single source of fragment truth — never add, rename, or invent fragments.

---

## Failure 2: No existing-config scan — re-adds already-configured fragments

**Without skill:** Agent writes all fragments regardless of what's already in config.yaml.
Produces duplicate rules. Doesn't check for existing coverage before presenting fragments.

**Expected behavior:** Read `openspec/config.yaml` first. For each catalog fragment, apply
its Detection criteria against existing rules. Mark each fragment Clear (already present)
or Missing (not present). Only present Missing fragments to the user.

---

## Failure 3: No sequential loop — dumps all missing fragments at once

**Without skill:** Agent lists every missing fragment in one message and asks "which ones
do you want?" User must evaluate all options at once. No per-fragment description or
"Tell me more" option.

**Expected behavior:** Present one fragment at a time: name + description + what it adds.
AskUserQuestion with [Yes / Skip / Tell me more]. "Tell me more" shows the full
config.yaml patch inline, then re-asks.

---

## Failure 4: No consolidated confirmation — writes immediately after each selection

**Without skill:** Agent writes config.yaml rules as each fragment is accepted. No preview
of the full set of changes before writing. User cannot see the combined impact before
committing.

**Expected behavior:** Collect all selections first. Show a consolidated plan — all
config.yaml additions, all files to create, all install checks — and ask "Apply all of
this?" before writing anything.

---

## Failure 5: No clarify-step install check — adds rule without verifying skill exists

**Without skill:** Agent adds the `clarify-step` rule to config.yaml even when
`~/.claude/skills/opsx-clarify/SKILL.md` does not exist. The rule references a skill
the user doesn't have installed.

**Expected behavior:** Before writing the `clarify-step` rule, check
`~/.claude/skills/opsx-clarify/SKILL.md`. If missing, try to copy from the project.
If the project copy is also missing, skip this fragment and explain why.

---

## Failure 6: No post-write validation — config.yaml left potentially invalid

**Without skill:** Agent writes config.yaml rules without running `openspec validate`.
Syntax errors or schema violations go undetected.

**Expected behavior:** Run `openspec validate` immediately after every config.yaml write.
Report the result. If validation fails, stop and show the error verbatim.

---

## Failure 7: No worktree follow-up note in completion report

**Without skill:** After adding the `worktree-workflow` fragment, agent writes the rule
but gives no guidance on how to use it.

**Expected behavior:** The completion report must include the follow-up note:
"Added worktree rules. To use: invoke `superpowers:using-git-worktrees` before your
next `/opsx:apply`."
```

- [ ] **Step 3: Commit**

```bash
git add skills/schema-config/tests/baseline-failures.md
git commit -m "test(schema-config): RED baseline — 7 failure modes without skill"
```

---

### Task 2: GREEN Fragment Catalog — references/fragments.md

**Goal:** Write the complete data file for all 6 fragments. This is pure transcription — every field value is specified below. No content decisions are required from the implementer.

**Files:**
- Create: `skills/schema-config/references/fragments.md`

**Interfaces:**
- Produces: `skills/schema-config/references/fragments.md` — consumed by SKILL.md in Task 3

- [ ] **Step 1: Create the references directory**

```bash
mkdir -p /Users/jeremiepoutrin/projects/github/jpoutrin/openspec-setup-plugin/skills/schema-config/references
```

- [ ] **Step 2: Write fragments.md**

Create `skills/schema-config/references/fragments.md` with this exact content (note: inner yaml/markdown code blocks use 3 backticks):

````markdown
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

Content of `docs/adr/0001-template.md`:
```markdown
# ADR-0001: [Decision Title]

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-XXXX

## Context

What is the issue we're addressing? What forces are at play? What constraints exist?

## Decision

What decision was made? State it clearly and directly.

## Consequences

**Positive:**
- ...

**Negative:**
- ...

**Risks:**
- ...
```

---

## Fragment: branch-naming

**Description:** Enforces a two-phase branch model — spec branches for OpenSpec planning work, implementation branches for applying specs via `/opsx:apply`.

**Detection:** `rules.proposal` or `rules.tasks` contains "branch" or "spec/" or "feat/".

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

**Detection:** `rules.tasks` contains "conventional" or "commit".

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
````

- [ ] **Step 3: Verify all 6 fragments are present**

```bash
grep "^## Fragment:" /Users/jeremiepoutrin/projects/github/jpoutrin/openspec-setup-plugin/skills/schema-config/references/fragments.md
```

Expected output (6 lines, in this exact order):
```
## Fragment: adr
## Fragment: branch-naming
## Fragment: commit-conventions
## Fragment: epic-breakdown
## Fragment: clarify-step
## Fragment: worktree-workflow
```

If any fragment is missing or out of order, fix the file before committing.

- [ ] **Step 4: Verify each fragment has all required fields**

Each of the 6 fragments must have `**Description:**`, `**Detection:**`, `**config.yaml patch:**`, and `**Files to create:**`. Run:

```bash
for f in adr branch-naming commit-conventions epic-breakdown clarify-step worktree-workflow; do
  count=$(grep -A 30 "^## Fragment: $f$" /Users/jeremiepoutrin/projects/github/jpoutrin/openspec-setup-plugin/skills/schema-config/references/fragments.md | grep -c "^\*\*\(Description\|Detection\|config\.yaml patch\|Files to create\):")
  echo "$f: $count/4 fields"
done
```

All lines must show `4/4 fields`. If any show less, re-read the file and fix the missing field.

- [ ] **Step 5: Commit**

```bash
git add skills/schema-config/references/fragments.md
git commit -m "feat(schema-config): GREEN — add fragment catalog (references/fragments.md)"
```

---

### Task 3: GREEN Skill — SKILL.md

**Goal:** Write `skills/schema-config/SKILL.md` — the 8-step orchestration logic that reads the catalog, scans config.yaml, walks the user through fragment selection, confirms before writing, writes in one pass, validates, and reports. Must include a Common Mistakes section covering all 7 baseline failures from Task 1.

**Files:**
- Create: `skills/schema-config/SKILL.md`

**Interfaces:**
- Consumes: `skills/schema-config/references/fragments.md` (referenced in Step 1 of the skill)
- Produces: `skills/schema-config/SKILL.md` — installed globally in Task 4

- [ ] **Step 1: Verify the catalog and baseline failures exist**

```bash
ls /Users/jeremiepoutrin/projects/github/jpoutrin/openspec-setup-plugin/skills/schema-config/references/fragments.md
ls /Users/jeremiepoutrin/projects/github/jpoutrin/openspec-setup-plugin/skills/schema-config/tests/baseline-failures.md
```

Both must exist. If either is missing, stop — Task 2 or Task 1 was not completed.

- [ ] **Step 2: Write skills/schema-config/SKILL.md**

Create `skills/schema-config/SKILL.md` with this exact content:

```markdown
---
name: schema-config
description: >
  Use when the user wants to configure workflow schemas or add workflow fragments to an OpenSpec
  project. Triggered by "/schema-config", "configure my workflow", "add workflow schemas",
  "set up ADR", "add commit conventions to OpenSpec", "configure clarify step",
  "add worktree workflow", "add branch naming conventions".
  Do NOT use for creating change proposals (use /opsx:propose) or for exploring a codebase
  (use /opsx:explore).
---

# schema-config

Scan `openspec/config.yaml` for missing workflow fragments, walk the user through adding
them one at a time, and write everything in a single confirmed pass.

**Does NOT create OpenSpec change proposals, replace `/opsx:clarify`, or run automatically.**

## Step 1: Load Fragment Catalog

Read `~/.claude/skills/schema-config/references/fragments.md`.

This file is the single source of truth for all fragments. Do not invent, add, or rename
fragments not listed in the catalog. Each `## Fragment: <name>` section contains four
fields: Description, Detection, config.yaml patch, and Files to create.

## Step 2: Scan Existing Config

Read `openspec/config.yaml`.

**If `openspec/config.yaml` does not exist:** respond:
"No `openspec/config.yaml` found. Run `/openspec:setup` or `openspec init` first." and stop.

For each fragment in the catalog (in catalog order), apply its Detection criteria against
the existing config.yaml content:
- **Clear** — Detection criteria matched (fragment already configured)
- **Missing** — Detection criteria not matched (fragment not configured)

## Step 3: Report Current State

Show a one-line summary:

```
Already configured: [list or "none"]
Missing: [list or "none"]
```

**If all fragments are Clear:** respond "All workflow fragments already configured." and stop.

## Step 4: Sequential Fragment Loop

For each **Missing** fragment in catalog order (adr → branch-naming → commit-conventions →
epic-breakdown → clarify-step → worktree-workflow):

Present one fragment at a time. Never reveal which fragments come next.

```
Fragment: <name>

<Description from catalog>

What this adds to config.yaml:
<config.yaml patch — yaml block>

Add this fragment?
```

Use **AskUserQuestion** with options: Yes / Skip / Tell me more

- **Yes** → record selection; move to next fragment
- **Skip** → record as skipped; move to next fragment
- **Tell me more** → show the full `config.yaml patch` section from the catalog verbatim, then re-ask with the same three options (does not loop again — re-ask once and move on regardless of answer)

**If user selects Skip for every fragment:** respond "No fragments selected. Nothing written." and stop.

## Step 5: Consolidated Plan

Before writing anything, show everything that will be written:

```
Here is what will be applied:

config.yaml additions:
  <fragment name>: <one-line summary of rules added>
  ...

Files to create:
  <path> — <description>    (or "none")

Install checks:
  clarify-step: ~/.claude/skills/opsx-clarify/SKILL.md    (or "not selected")
```

Use **AskUserQuestion** with options: Apply all of this / Edit first / Cancel

- **Apply all of this** → proceed to Step 6
- **Edit first** → ask what to change; loop back to this step with the updated selection
- **Cancel** → respond "Cancelled. Nothing written." and stop

## Step 6: Write

Apply all selected fragments in one pass:

**config.yaml patching:** For each selected fragment, append its `rules:` and `operations:`
entries to the existing config.yaml structure. Before appending each rule, scan the
target rule list for a semantically equivalent rule — if one exists, skip that individual
rule silently. Never replace or delete existing rules.

**Supporting files:** For each file under `Files to create`, create it only if it does not
already exist. If the file exists, skip it and note "already exists — not overwritten" in
the completion report.

**clarify-step install check:** Before writing the `clarify-step` rule:

1. Run: `ls ~/.claude/skills/opsx-clarify/SKILL.md`
2. **Present** → add the config.yaml rule only.
3. **Missing** → run: `ls skills/opsx-clarify/SKILL.md`
   - **Present** → run:
     ```bash
     mkdir -p ~/.claude/skills/opsx-clarify
     cp skills/opsx-clarify/SKILL.md ~/.claude/skills/opsx-clarify/SKILL.md
     ```
     Then add the config.yaml rule.
   - **Also missing** → skip this fragment entirely. Add to completion report:
     "clarify-step skipped — opsx:clarify skill not found. Install it first, then re-run `/schema-config`."

## Step 7: Validate

Run:

```bash
openspec validate
```

Report the result inline. If validation fails, stop immediately and show the error output
verbatim. Do not continue past a validation failure.

## Step 8: Completion Report

```
schema-config complete.

Applied fragments: [comma-separated list, or "none"]

Changes written:
  openspec/config.yaml  ← N rules added (proposal: X, tasks: Y, operations: Z)
  [file path]  ← created    (one line per file created, or omit if none)
  ~/.claude/skills/opsx-clarify/SKILL.md  ← installed    (only if clarify-step was installed)

Skipped fragments: [name (reason)]    (or "none")

Validation: openspec validate ✅ / ❌

Follow-up:
  [worktree-workflow note — always include if that fragment was applied]
  [any "already exists — not overwritten" notes]
  [clarify-step skip reason if applicable]
```

**worktree-workflow follow-up note** (always include if `worktree-workflow` was applied):
> "Added worktree rules. To use: invoke `superpowers:using-git-worktrees` before your next `/opsx:apply`."

## Common Mistakes

**Writing from memory instead of reading the catalog:** Always read
`~/.claude/skills/schema-config/references/fragments.md` at skill start. Do not use mentally
recalled fragment names, rules, or patches — the catalog is the single source of truth. (Prevents Failure 1)

**Re-adding already-configured fragments:** Run the Detection scan (Step 2) before presenting
fragments. Only present Missing fragments to the user. (Prevents Failure 2)

**Presenting all missing fragments at once:** Present exactly one fragment per AskUserQuestion
call. Revealing future fragments defeats the one-at-a-time loop. (Prevents Failure 3)

**Writing immediately on each selection:** Collect all selections first. Show the consolidated
plan (Step 5) and wait for confirmation before writing anything. (Prevents Failure 4)

**Adding clarify-step rule without checking install:** Always check
`~/.claude/skills/opsx-clarify/SKILL.md` before writing the `clarify-step` rule. Follow the
three-path logic in Step 6. (Prevents Failure 5)

**Skipping openspec validate:** Run `openspec validate` after every config.yaml write. A
write that produces invalid YAML is a correctness failure. (Prevents Failure 6)

**Omitting the worktree follow-up note:** If `worktree-workflow` is applied, the completion
report must include the `superpowers:using-git-worktrees` invocation note. (Prevents Failure 7)
```

- [ ] **Step 3: Verify SDO compliance**

The `description:` field must contain ONLY trigger conditions — not a workflow description:

```bash
head -12 /Users/jeremiepoutrin/projects/github/jpoutrin/openspec-setup-plugin/skills/schema-config/SKILL.md
```

Confirm: description contains trigger phrases and "Do NOT use for" exclusions only. Confirm it does NOT describe what the skill does internally (no "scans", "walks", "writes in one pass" in the description field).

- [ ] **Step 4: Verify Common Mistakes covers all 7 baseline failures**

```bash
grep -c "Prevents Failure" /Users/jeremiepoutrin/projects/github/jpoutrin/openspec-setup-plugin/skills/schema-config/SKILL.md
```

Expected: `7`. If less, find the missing `(Prevents Failure N)` annotation and add the corresponding Common Mistakes entry.

- [ ] **Step 5: Commit**

```bash
git add skills/schema-config/SKILL.md
git commit -m "feat(schema-config): GREEN — write schema-config skill orchestration"
```

---

### Task 4: Global Install + Push

**Goal:** Install the skill globally so it's accessible from any project, then push all commits to remote.

**Files:**
- Write (not committed): `~/.claude/skills/schema-config/SKILL.md`

**Interfaces:**
- Consumes: `skills/schema-config/SKILL.md` from Task 3

- [ ] **Step 1: Create global skill directory**

```bash
mkdir -p ~/.claude/skills/schema-config
```

- [ ] **Step 2: Copy SKILL.md and fragments.md to global location**

```bash
cp /Users/jeremiepoutrin/projects/github/jpoutrin/openspec-setup-plugin/skills/schema-config/SKILL.md ~/.claude/skills/schema-config/SKILL.md
mkdir -p ~/.claude/skills/schema-config/references
cp /Users/jeremiepoutrin/projects/github/jpoutrin/openspec-setup-plugin/skills/schema-config/references/fragments.md ~/.claude/skills/schema-config/references/fragments.md
```

The catalog must be installed alongside SKILL.md — the skill reads it from the absolute
path `~/.claude/skills/schema-config/references/fragments.md` so it works from any project.

- [ ] **Step 3: Verify both copies are identical**

```bash
diff /Users/jeremiepoutrin/projects/github/jpoutrin/openspec-setup-plugin/skills/schema-config/SKILL.md ~/.claude/skills/schema-config/SKILL.md
diff /Users/jeremiepoutrin/projects/github/jpoutrin/openspec-setup-plugin/skills/schema-config/references/fragments.md ~/.claude/skills/schema-config/references/fragments.md
```

Expected: no output from either diff. If there is a diff, re-copy the affected file.

- [ ] **Step 4: Commit the install step (empty commit as a ledger marker)**

```bash
git commit --allow-empty -m "chore(schema-config): install skill globally at ~/.claude/skills/schema-config/"
```

(The global copy is outside the repo — no files to stage. The empty commit marks this step in the SDD ledger.)

- [ ] **Step 5: Push all commits to remote**

```bash
unset GITHUB_TOKEN && unset GH_TOKEN && git push origin main
```

- [ ] **Step 6: Verify push**

```bash
git log --oneline -5
```

Confirm these commits appear (most recent first):
```
chore(schema-config): install skill globally at ~/.claude/skills/schema-config/
feat(schema-config): GREEN — write schema-config skill orchestration
feat(schema-config): GREEN — add fragment catalog (references/fragments.md)
test(schema-config): RED baseline — 7 failure modes without skill
```
