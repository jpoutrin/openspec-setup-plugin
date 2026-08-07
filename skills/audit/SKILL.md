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

## Action Items
[Ordered by priority — each item is a single, actionable step:]
1. [Most critical first — e.g., install Node.js if missing]
2. ...

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
