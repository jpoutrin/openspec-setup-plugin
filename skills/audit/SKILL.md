---
name: openspec:audit
description: >
  Audit a project's readiness for OpenSpec and AI-assisted development. Detects the project's language and
  tech stack, checks Node.js and OpenSpec CLI versions, finds the right LSP (language server) for the detected
  language — researching it if necessary — recommends context-aware MCP servers, and reports on existing
  CLAUDE.md and Copilot instruction files. ALWAYS invoke this skill when the user says "audit my setup",
  "check what's installed", "what do I need for OpenSpec", "openspec audit", "check my dev tools",
  "is my project ready for AI coding", "what MCP servers should I add", or "which LSP do I need".
  Also invoke it at the start of any troubleshooting session about AI tooling on a project.
---

# OpenSpec Audit

Produce a structured readiness report for AI-assisted spec-driven development. Run all checks first,
then present the full report — one clear document the engineer can act on.

## Reference files

Read both of these before running any checks:
- `references/lsp-catalog.md` — language → LSP server mapping
- `references/mcp-catalog.md` — stack → MCP server recommendations

---

## Checks to run

### Check 1: Node.js version
```bash
node --version 2>/dev/null || echo "NOT_INSTALLED"
```
OpenSpec requires Node.js ≥ 20.19.0.

### Check 2: OpenSpec CLI
```bash
openspec --version 2>/dev/null || echo "NOT_INSTALLED"
```

### Check 3: Language / stack detection

Look for these files (use `ls` or try reading them):

| Indicator | Language |
|-----------|---------|
| `package.json`, `tsconfig.json`, `.nvmrc` | TypeScript / JavaScript |
| `pyproject.toml`, `setup.py`, `requirements.txt`, `poetry.lock` | Python |
| `Cargo.toml` | Rust |
| `go.mod` | Go |
| `pom.xml`, `build.gradle`, `build.gradle.kts` | Java / Kotlin |
| `*.csproj`, `*.sln` | C# |
| `mix.exs` | Elixir |
| `Gemfile` | Ruby |
| `composer.json` | PHP |

Also detect frameworks: `next.config.*` → Next.js, `vite.config.*` → Vite, `fastapi`/`django` in requirements, etc.

For each detected language:
1. Look up its LSP in `references/lsp-catalog.md`
2. If the language is not in the catalog, use WebSearch: `"[language] language server LSP install 2025"` to find the right server. Note in the report that this required a web search.

### Check 4: Existing LSP plugins
```bash
claude plugin list 2>/dev/null | grep -i lsp || echo "no lsp plugins found"
```

### Check 5: MCP recommendations

Using `references/mcp-catalog.md`, match MCP servers to the detected stack.

Additional signals to check:
- `docker-compose.yml` or `Dockerfile` exists → Docker MCP
- `.github/` directory exists or `git remote -v` shows github.com → GitHub MCP
- Search `.env`, `.env.example`, or `docker-compose.yml` for DATABASE_URL, POSTGRES_*, MONGODB_URI, redis:// → database-specific MCP

### Check 6: OpenSpec status
```bash
ls openspec/config.yaml openspec/specs/ .claude/commands/opsx/ 2>/dev/null || true
```

### Check 7: Agent files status
```bash
ls CLAUDE.md .claude/CLAUDE.md .github/copilot-instructions.md 2>/dev/null || true
```

### Check 8: Pre-commit hook

```bash
ls .git/hooks/pre-commit 2>/dev/null && head -3 .git/hooks/pre-commit || echo "NOT_FOUND"
```

### Check 9: Clean-repo guard rules in config.yaml

```bash
grep -c "opsx:apply" openspec/config.yaml 2>/dev/null || echo "NOT_FOUND"
grep -c "opsx:sync" openspec/config.yaml 2>/dev/null || echo "NOT_FOUND"
grep -c "opsx:archive" openspec/config.yaml 2>/dev/null || echo "NOT_FOUND"
```

Verify that `openspec/config.yaml` contains all three clean-repo guard rules in its `tasks:` rules — one each for `/opsx:apply`, `/opsx:sync`, and `/opsx:archive`. These commands mutate the working tree or produce artifacts from it; running them over uncommitted changes silently corrupts the change history. Flag each missing rule individually.

Also check for hook managers (which replace raw `.git/hooks/`):
```bash
# husky
ls .husky/pre-commit 2>/dev/null || true
# lefthook
ls lefthook.yml .lefthook.yml 2>/dev/null | xargs grep -l "pre-commit" 2>/dev/null || true
# pre-commit framework
ls .pre-commit-config.yaml 2>/dev/null || true
```

Report which path is active: raw hook, hook manager, or none.

---

## Report format

Always produce the full report, even if some checks pass cleanly. An engineer should be able to screenshot
this and have a complete picture.

```
# OpenSpec Readiness Audit

## Project
- **Type**: [Greenfield / Brownfield]
- **Language(s)**: [list]
- **Framework(s)**: [list, or "none detected"]

## Prerequisites
| Tool | Status | Action |
|------|--------|--------|
| Node.js | ✅ v[X.Y.Z] / ❌ not found | [install URL if missing] |
| OpenSpec CLI | ✅ v[X.Y.Z] / ❌ not installed | `npm install -g @fission-ai/openspec@latest` |

## LSP Setup
[For each detected language:]
- **[Language]**: ✅ [plugin] already installed  /  ❌ not found
  → Install: `[exact command]`
  [If researched via web:] _(source: web search — verify at [URL])_

## Recommended MCP Servers
| MCP | Why | How to add |
|-----|-----|-----------|
| context7 | Fetches live library docs into context | `npx -y @upstash/context7-mcp` |
| [others based on stack] | [reason] | [command] |

## OpenSpec Status
| Item | Status |
|------|--------|
| `openspec/config.yaml` | ✅ found / ❌ not initialized |
| `openspec/specs/` | ✅ / ❌ |
| Claude Code slash commands | ✅ `.claude/commands/opsx/` found / ❌ |

## Agent Files
| File | Status |
|------|--------|
| `CLAUDE.md` | ✅ present / ❌ missing |
| `.github/copilot-instructions.md` | ✅ present / ❌ missing |

## Quality Gates
| Gate | Status | Notes |
|------|--------|-------|
| Pre-commit hook | ✅ `.git/hooks/pre-commit` / ✅ husky / ✅ lefthook / ✅ pre-commit / ❌ none | [what it checks, or "not configured"] |
| Apply guard rule | ✅ present in `tasks:` rules / ❌ missing from config.yaml | Prevents `/opsx:apply` on uncommitted working tree |
| Sync guard rule | ✅ present in `tasks:` rules / ❌ missing from config.yaml | Prevents `/opsx:sync` on uncommitted working tree |
| Archive guard rule | ✅ present in `tasks:` rules / ❌ missing from config.yaml | Prevents `/opsx:archive` on uncommitted working tree |

## Action Items
[Ordered by priority — each item is a single, actionable step:]
1. [Most critical first — e.g., install Node.js if missing]
2. ...
[If pre-commit hook is missing, include:]
- Install pre-commit quality gate (compile + tests): run `openspec:setup` Phase 3 Step 3c
[If any clean-repo guard rule is missing from config.yaml tasks: rules, include one action item per missing rule:]
- Add apply guard: `Never run /opsx:apply on a working tree with uncommitted changes — commit or stash all pending changes before applying a proposal.`
- Add sync guard: `Never run /opsx:sync on a working tree with uncommitted changes — commit or stash all pending changes before syncing specs.`
- Add archive guard: `Never run /opsx:archive on a working tree with uncommitted changes — commit or stash all pending changes before archiving a change.`

---
_Run `openspec:setup` to handle all of the above interactively._
```

---

## Edge cases

**Multiple languages detected** (e.g., TypeScript frontend + Python backend): list LSP recommendations for all
detected languages and note which directories they apply to.

**Language not in catalog**: Report "LSP researched via web search" and include the source URL so the engineer
can verify. If WebSearch is unavailable, note "could not look up LSP — check https://langserver.org for options."

**OpenSpec partially configured** (config.yaml exists but no slash commands): flag this specifically —
it likely means `openspec init` was run for a different tool. Suggest running `openspec init --tools claude,copilot`
to add the missing integrations.

**Pre-commit hook present but empty or trivial** (e.g., just a shebang): report as ❌ not configured —
a hook file that doesn't run compile + tests provides no quality gate.
