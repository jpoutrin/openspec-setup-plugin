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
