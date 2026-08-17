# Quality Criteria for Agent Instruction Files

Use this checklist when reviewing existing CLAUDE.md or Copilot instruction files.
The goal: a new agent reading this file should be able to work on the project correctly,
without asking the same questions a developer would ask on day one.

---

## Required Content

### 1. Project description
- [ ] Present (not just a project name)
- [ ] Says WHAT the project does, in concrete terms
- [ ] Understandable by someone who's never seen the codebase
- [ ] 1–3 sentences — longer descriptions are usually not read

### 2. Development commands
- [ ] **Run** command documented and copy-pasteable (not "start the server")
- [ ] **Test** command documented
- [ ] **Build** command documented, or explicitly marked N/A
- [ ] Commands work from the project root (or the file notes which directory to run from)

### 3. Architecture / key directories
- [ ] At least the main source directories explained
- [ ] Entry points identified (e.g., `src/main.ts`, `app/main.py`, `cmd/server/main.go`)
- [ ] Enough context to know where to put a new feature

### 4. Conventions
- [ ] At least 2–3 specific, actionable rules
- [ ] Covers: import style, file naming, or framework-specific patterns
- [ ] Not aspirational ("write clean code") — specific enough to be testable in a code review

### 5. Off-limits paths
- [ ] Generated/compiled directories listed (e.g., `dist/`, `build/`, `__pycache__/`)
- [ ] Vendor or third-party directories listed if relevant
- [ ] Lock files mentioned if they should not be manually edited

### 6. Environment setup
- [ ] Mentions whether a `.env` file is needed (and where to get it)
- [ ] Lists required external services (database, cache, etc.)
- [ ] First-time setup steps are actionable (copy this file, run this command)

---

## Style Criteria

- [ ] **Scannable** — uses tables, bullet lists, or short sections; minimal prose paragraphs
- [ ] **Concise** — each section as short as it can be while being complete
- [ ] **Specific** — actual commands, not descriptions of commands
- [ ] **Current** — no references to deprecated tools or old commands

---

## OpenSpec-specific (only check if OpenSpec is configured in the project)

- [ ] `openspec/specs/` mentioned as the source of truth
- [ ] Key commands noted (`/opsx:propose`, `/opsx:apply`, `/opsx:archive`)
- [ ] Change workflow briefly described
- [ ] If `openspec/config.yaml` exists, read its `context:` and `rules:` for anything with a
      CLAUDE.md-relevant equivalent (a typing-strictness rule, a commit-format rule, a
      branch-naming rule, a test-location convention) — CLAUDE.md's Conventions section should
      state the same thing, not something that contradicts it. Flag any mismatch as a gap.

---

## Common Gaps (what's usually missing)

These are the issues found most often in real CLAUDE.md files:

1. **No test command** — "run the tests" without the actual command
2. **No environment variable documentation** — agent tries to run the app and fails silently
3. **Architecture section is just a directory listing** — `src/` ← source code. Not helpful.
4. **No off-limits section** — agent modifies generated files or migrations
5. **Wall of text** — no headers, no structure; agent skims and misses key rules
6. **Platform-specific assumptions** — commands work on Mac but not Linux (or vice versa) without noting it
7. **Package manager ambiguity** — project uses `pnpm` but CLAUDE.md says `npm install`
8. **Stale commands** — refers to scripts that have been renamed or removed

---

## Scoring

When reviewing, count the checkboxes above. A file with:
- **All boxes checked**: ready for production AI-assisted development
- **6–9 boxes missing**: usable but will cause repeated questions or mistakes
- **10+ boxes missing**: better to regenerate from scratch via the interview flow

For files with many gaps, suggest regenerating rather than patching — a fragmented CLAUDE.md
updated piecemeal is often harder to read than a fresh one.
