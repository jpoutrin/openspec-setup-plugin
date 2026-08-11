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
