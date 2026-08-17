# Research Notes Backend Detection

Reference for any skill that writes intermediate research findings before producing a design.md
section or tasks.md breakdown. Read this file before writing any research notes — do not
hardcode a path.

## Detection (run these checks in order, per repo)

1. Check whether `hlyr` is on `PATH`:
   ```bash
   which hlyr 2>/dev/null || echo "NOT_FOUND"
   ```
2. If found, check whether this specific repo already has thoughts initialized:
   ```bash
   hlyr thoughts status 2>/dev/null && echo "INITIALIZED" || echo "NOT_INITIALIZED"
   ```

## Backend selection

**If `hlyr` is on PATH AND `hlyr thoughts status` succeeds (INITIALIZED):**
- Write research notes to `thoughts/shared/research/YYYY-MM-DD-<change-name>-research.md`
- After writing, run `hlyr thoughts sync` to sync the note into the shared thoughts repo

**Otherwise (hlyr missing, or present but this repo never ran `hlyr thoughts init`):**
- Create `thoughts/research/` in the current repo if it doesn't already exist:
  ```bash
  mkdir -p thoughts/research
  ```
- Write research notes to `thoughts/research/YYYY-MM-DD-<change-name>-research.md`
- This directory is git-tracked normally as part of the project's own repo — no separate repo,
  no hooks, no `hlyr` dependency, no new `config.yaml` field or toggle

## Notes format

Each research note should capture, at minimum:
- The change name and date
- Which subagents were dispatched (`codebase-locator`, `codebase-analyzer`, `codebase-pattern-finder`, `openspec-expert`) and what each was asked
- Key file:line findings that inform the design decision
- Any open questions the research could not resolve

## Why this detection, not a hard dependency

`hlyr`'s full `thoughts/` system (a separate synced git repo, pre/post-commit hooks, a
`searchable/` hardlink directory) is a real dependency this plugin never requires installing.
Detection is per-repo because `hlyr thoughts init` is itself a per-repo mapping — a repo that
never ran it correctly falls through to the local-folder default automatically.
