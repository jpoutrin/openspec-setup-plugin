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

Read `skills/schema-config/references/fragments.md`.

This file is the single source of truth for all fragments. Do not invent, add, or rename
fragments not listed in the catalog. Each `## Fragment: <name>` section contains four
fields: Description, Detection, config.yaml patch, and Files to create.

## Step 2: Scan Existing Config

Read `openspec/config.yaml`.

**If `openspec/config.yaml` does not exist:** respond:
"No `openspec/config.yaml` found. Run `/openspec:setup` or `openspec init` first." and stop.

For each fragment in the catalog (in catalog order), apply its Detection criteria against
the existing config.yaml content. For any fragment whose Detection criteria includes an "OR
`<directory>` exists" clause (`adr`, `system-architecture`, `program-design`,
`worktree-workflow`), also check for that directory, e.g.:
```bash
ls docs/adr docs/architecture docs/program-design .worktrees 2>/dev/null
```
A fragment is Clear if either half of its Detection matches:
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

For each **Missing** fragment in catalog order (adr → system-architecture → program-design →
vertical-slices → branch-naming → commit-conventions → epic-breakdown → clarify-step →
worktree-workflow):

Present one fragment at a time. Never reveal which fragments come next.

**Exception:** before presenting `vertical-slices`, first run the replace-exception check
described in Step 6 — if the old stub-first rule is found, it replaces the normal
Yes/Skip/Tell-me-more prompt for this one fragment with a different question.

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
- **Tell me more** → show the full `config.yaml patch` section from the catalog verbatim, then re-ask with the same three options. If the user picks "Tell me more" again, treat it as Skip and move to the next fragment.

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
rule silently. Never replace or delete existing rules, except for the one narrow
`vertical-slices` exception described immediately below.

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

**vertical-slices replace-exception check:** Before presenting or writing the `vertical-slices`
fragment (Step 4), check whether `rules.tasks` contains the old stub-first rule text verbatim:
`Start each capability group with a stub task — typed model/service/serializer skeletons —
before behavior tasks.`

- **If found:** skip the normal Yes/Skip/Tell-me-more flow for this fragment. Present instead:
  > "Your project has the old stub-first task rule (`Start each capability group with a stub
  > task...`), which conflicts with vertical-slice ordering. Replace it with the vertical-slice
  > rule?"
  >
  > AskUserQuestion: **Replace it / Keep both (not recommended) / Skip this fragment**
  - **Replace it** → in Step 6, remove the old rule line before appending the new
    `vertical-slices` rules. Completion report line:
    `openspec/config.yaml ← 1 rule replaced (tasks: stub-first → vertical-slice ordering)`
  - **Keep both** → append the new rules alongside the old one. Completion report must warn:
    "Both the old stub-first rule and the new vertical-slice rule are now active — these
    conflict. Recommend manually removing the stub-first rule."
  - **Skip this fragment** → no change, same as any other Skip.
- **If not found:** `vertical-slices` behaves like every other fragment — pure addition, normal
  Yes/Skip/Tell-me-more flow, "Never replace or delete existing rules" applies as usual.

This is the only fragment in the catalog with replace logic. Never apply this replace-exception
pattern to `adr`, `system-architecture`, `program-design`, `branch-naming`,
`commit-conventions`, `epic-breakdown`, `clarify-step`, or `worktree-workflow`.

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
`skills/schema-config/references/fragments.md` at skill start. Do not use mentally
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

**Applying the vertical-slices replace exception to any other fragment:** The replace-exception
branch in Step 6 applies only to `vertical-slices`. Every other fragment — including the two new
ones, `system-architecture` and `program-design` — follows the normal additive-only flow: never
replace or delete an existing rule for any fragment other than `vertical-slices`.
(Prevents Failure 8)
