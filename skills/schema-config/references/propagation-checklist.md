# Propagation Checklist — Adding or Changing a Fragment or Canonical Rule

This plugin duplicates rule content across several files by design (see each file's own header
for why). That duplication is the single biggest source of drift risk in this repo — a rule
changed in one place and silently not changed everywhere else. Before committing a change to a
fragment (`fragments.md`) or a canonical "always include" rule (`config-best-practices.md`),
check every item below.

1. **`skills/schema-config/references/fragments.md`** — the fragment entry itself (Description,
   Detection, config.yaml patch, Files to create).
2. **`skills/setup/references/config-best-practices.md`** — the mirrored canonical rule, if the
   rule is "canonical, always include" (written into every new project regardless of fragment
   selection). Wording must match the fragment's own rule text verbatim — quoting style may
   differ only if both forms are valid YAML.
3. **`skills/schema-config/SKILL.md`** — the catalog order in Step 4, and the Common Mistakes
   count (`grep -c "Prevents Failure"` must equal the baseline failure count).
4. **`skills/schema-config/tests/baseline-failures.md`** — Failure 1's fragment list, and the
   total failure count if you added a new failure mode.
5. **`skills/audit/SKILL.md`** — Check 6b already loops over the whole `fragments.md` catalog
   generically, so a new fragment needs no code change there. Only touch Check 6b if you add a
   genuinely new *kind* of special case (like `vertical-slices`' replace-exception three-state
   status).
6. **`hooks/validate-config.sh`** — if the rule is "canonical, always include" (mandatory, no
   skip path — like the clean-repo guards), add a hard-blocking check here. If it's an opt-in
   fragment rule (skippable via `/schema-config`'s Yes/Skip flow), add a non-blocking warning
   instead, or nothing at all — do not hard-block on something a user can legitimately Skip.
7. **`skills/agent-files/references/quality-criteria.md`** — if the rule affects a convention
   that would also show up in CLAUDE.md (typing strictness, commit format, branch naming, test
   location), add or update the OpenSpec-specific check that CLAUDE.md doesn't contradict it.
8. **`README.md`** — the `## Skills` list and Plugin Structure tree, if you added a new skill or
   reference file.
9. **Detection-anchor uniqueness** — grep the new rule's Detection literal-string anchor against
   every OTHER fragment's `config.yaml patch` block in `fragments.md`. If any other fragment's
   rule text contains that same substring, anchor on a longer, unique phrase instead. This is
   exactly the bug class that broke `system-architecture`/`program-design` detection the first
   time: each fragment's own scope-boundary sentence referenced the OTHER fragment's section
   name, and a loose "contains X" Detection matched inside the wrong fragment's own text.

Not every item applies to every change — a wording-only fix to one fragment's Description
doesn't need a hooks change. But check each item consciously rather than skipping the whole list.
