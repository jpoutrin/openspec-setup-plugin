---
name: openspec:setup
description: >
  Full guided wizard for setting up OpenSpec (spec-driven development) in a project — greenfield or brownfield.
  Runs three phases in sequence: (1) audit the environment for Node.js, OpenSpec, LSP, and MCP readiness,
  (2) generate or improve CLAUDE.md and GitHub Copilot instructions, (3) guide through OpenSpec installation
  and initialization. ALWAYS invoke this skill when the user says "set up OpenSpec", "install OpenSpec on my project",
  "configure OpenSpec", "bootstrap OpenSpec", "help me start with OpenSpec", or "how do I add OpenSpec to my project".
  Even if the user only mentions one aspect (e.g. "I just want the CLAUDE.md"), run the full wizard — the phases
  are short and the user can skip any step they've already done.
hooks:
  PostToolUse:
    - matcher: "Write"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/hooks/validate-config.sh"
---

# OpenSpec Setup Wizard

Help an engineer add OpenSpec to their project — from scratch or on an existing codebase. The goal is to arrive at
a project where OpenSpec is installed, the AI agent instruction files are solid, and the engineer knows what commands
to use next.

Work through three phases in order, presenting results and asking for a brief confirmation before advancing.
This keeps the engineer in the loop without requiring them to drive the process.

## Before Starting

Read these reference files before running any phase:
- `skills/audit/references/lsp-catalog.md` — needed in Phase 1
- `skills/audit/references/mcp-catalog.md` — needed in Phase 1
- `skills/setup/references/config-best-practices.md` — needed in Phase 3 to guide config.yaml population

---

## Phase 1: Audit

Run all checks silently, then present the full report. Don't interrupt the engineer for each individual check.

### 1a — Project type detection

Check whether this is greenfield (empty or near-empty, no meaningful source files) or brownfield (existing codebase):
```bash
ls -la
find . -maxdepth 2 -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" 2>/dev/null | head -5
```

### 1b — Prerequisites

```bash
node --version 2>/dev/null || echo "NOT_INSTALLED"
openspec --version 2>/dev/null || echo "NOT_INSTALLED"
```

OpenSpec requires Node.js ≥ 20.19.0. Note the status of each.

### 1c — Language and stack detection

Look for these indicator files (check `ls` output or try reading them):

| Indicator file | Language |
|---------------|---------|
| `package.json`, `tsconfig.json`, `.nvmrc` | TypeScript / JavaScript |
| `pyproject.toml`, `setup.py`, `requirements.txt`, `poetry.lock` | Python |
| `Cargo.toml` | Rust |
| `go.mod` | Go |
| `pom.xml`, `build.gradle`, `build.gradle.kts` | Java / Kotlin |
| `*.csproj`, `*.sln` | C# |
| `mix.exs` | Elixir |
| `Gemfile` | Ruby |
| `composer.json` | PHP |

Also detect frameworks from config files: `next.config.*` → Next.js, `vite.config.*` → Vite, `fastapi` in
requirements → FastAPI, `django` in requirements → Django.

For each detected language, find the LSP recommendation in `skills/audit/references/lsp-catalog.md`.
If the language is not listed there, use WebSearch to find the right language server — then note that
research was needed so the engineer knows where to verify.

### 1d — MCP recommendations

Use `skills/audit/references/mcp-catalog.md` to match MCP servers to the detected stack. Also check for:
- `docker-compose.yml` or `Dockerfile` → Docker MCP
- `.github/` directory or `git remote` showing github.com → GitHub MCP
- Database connection strings in `.env`, `docker-compose.yml`, or config files

### 1e — OpenSpec config status

```bash
ls openspec/config.yaml openspec/specs/ .claude/commands/opsx/ 2>/dev/null
```

### Audit Report

Present findings in this format:

```
## Audit Report

### Project
- Type: [Greenfield / Brownfield]
- Language(s): [list]
- Framework(s): [list or "none detected"]

### Prerequisites
- Node.js [version]: ✅  /  ❌ not found — install from https://nodejs.org (need ≥ 20.19.0)
- OpenSpec CLI [version]: ✅  /  ❌ not installed — will install in Phase 3

### LSP Setup
[For each detected language:]
- [Language]: ✅ [plugin name] already installed  /  ❌ not found
  → Install: [exact command from catalog]

### Recommended MCP Servers
| MCP | Why it fits | How to add |
|-----|-------------|------------|
| context7 | Up-to-date library docs in context | [command] |
| [others] | [reason] | [command] |

### OpenSpec Status
- config.yaml: ✅ found  /  ❌ not yet initialized
- Slash commands: ✅  /  ❌
```

After presenting: _"Ready to move on to your agent files?"_

---

## Phase 2: Agent Files

The agent instruction files (CLAUDE.md and `.github/copilot-instructions.md`) tell AI tools about the project's
commands, conventions, and constraints. Good files prevent repeated questions and wrong assumptions.

### Check what exists

```bash
ls CLAUDE.md .claude/CLAUDE.md .github/copilot-instructions.md 2>/dev/null
```

**If files exist** → go to **Review sub-flow**
**If files are missing** → go to **Create sub-flow**

---

### Review sub-flow

Read the existing files in full, then evaluate them against `skills/agent-files/references/quality-criteria.md`.

Present findings concisely:

```
## Agent File Review

### CLAUDE.md
✅ Strengths:
- [what's already solid]

❌ Gaps:
1. [Missing section or vague entry] → [proposed fix]
2. ...

### .github/copilot-instructions.md
[same format, or "file missing — will create alongside CLAUDE.md improvements"]
```

Ask for confirmation before modifying: _"Want me to apply these improvements?"_

If the user says yes, update the files and show a diff summary.

---

### Create sub-flow

Conduct a brief interview — one question at a time, waiting for each answer before asking the next.
Explain briefly why each question matters so the engineer understands what they're shaping.

1. _"What does this project do? (1–2 sentences — this becomes the first thing any agent reads)"_
2. _"How do you start the app in development? (e.g., `npm run dev`, `uvicorn app:main --reload`)"_
3. _"How do you run the tests?"_
4. _"How do you build for production? (type 'skip' if not applicable)"_
5. _"Any important conventions agents should follow? (e.g., no default exports, always use Zod, feature-based folders)"_
6. _"Are there directories or files agents should NEVER touch? (e.g., `dist/`, `generated/`, `migrations/`)"_
7. _"Any environment variables or first-time setup steps? (e.g., copy .env.example, run docker-compose up -d)"_

Then generate both files:

**CLAUDE.md:**
```markdown
# [Project Name]

[Project description]

## Development Commands

| Action | Command |
|--------|---------|
| Run    | `[run command]` |
| Test   | `[test command]` |
| Build  | `[build command or N/A]` |

## Architecture

[Key directories and what they contain — be specific]

## Conventions

[Actionable rules — the kind an agent needs to follow, not aspirational ideals]

## Do Not Touch

[Paths that must never be modified by an agent]

## Environment Setup

[Required .env variables or setup steps]
```

**`.github/copilot-instructions.md`** (concise variant for Copilot):
```markdown
# [Project Name]

[Same 1–2 sentence description]

## Commands
- Run: `[command]`
- Test: `[command]`
- Build: `[command or N/A]`

## Conventions
[Key rules condensed to bullet points]

## Off-limits
Never modify: [list of paths]

## Setup
[Critical env vars or setup steps]
```

Create `.github/` if it doesn't exist before writing the Copilot file.

After generating: _"Files written. Ready to proceed to OpenSpec initialization?"_

---

## Phase 3: OpenSpec Initialization

### Step 1: Install OpenSpec (if not already installed)

If the audit found OpenSpec missing:
```bash
npm install -g @fission-ai/openspec@latest
```

Verify:
```bash
openspec --version
```

### Step 2: Run `openspec init`

Tell the engineer to run:
```bash
openspec init
```

Explain what the interactive prompts will ask:
- **Tool selection** — choose "Claude Code" and "GitHub Copilot" (based on this project's setup)
- **Profile** — start with `core` (6 workflows); it can be expanded later

The init command will create:
```
openspec/
├── config.yaml          ← project config and profile setting
├── specs/               ← source of truth (add a spec per domain/feature)
└── changes/             ← active proposals (one folder per in-progress change)
    └── archive/         ← completed changes
.claude/commands/opsx/   ← slash commands installed for Claude Code
.github/copilot-instructions.md  ← updated with OpenSpec commands
```

### Step 3: Populate `openspec/config.yaml`

After init, the generated `config.yaml` has a minimal `context:` block and no `rules:`. Guide the
engineer through completing it using `skills/setup/references/config-best-practices.md`.

Conduct a brief interview — one question at a time:

1. _"What does this service/project do, in one sentence? (business purpose, not tech stack)"_
2. _"What's the tech stack? (language + version, framework, database, background jobs, frontend)"_
3. _"Are there any non-obvious tool conventions? (e.g., always use uv run, docker-compose binary)"_
4. _"What are the 5–10 hard conventions agents must follow? (typing, naming, test location, key commands)"_
5. _"What are the bounded capabilities / domains? (these become the specs/ folder names)"_

Then generate the `context:` block from the answers, following the subsection structure in
`config-best-practices.md` (Project, Stack, Hard conventions, Domain capabilities — add Frontend
conventions only if there is a non-trivial frontend layer).

For the `rules:` section, apply the canonical rules from `config-best-practices.md` as the base,
then add any stack-specific rules that apply to the detected project type. Prefer rules that reference
the project's actual tools (e.g., `make test` not `npm test` for a Python/Make project).

Show the full generated `config.yaml` and ask: _"Does this look right? I can adjust any section before writing."_

Write the file only after confirmation.

### Step 3b: Validate `openspec/config.yaml`

Run:
```bash
openspec validate
```

A skill hook also triggers this automatically after every write to `openspec/config.yaml`, so errors
surface immediately even if this step is skipped. If validation reports errors, show the exact output
to the engineer, fix the offending lines (typically malformed YAML, an unknown key, or a missing
required field), re-show the corrected file, and confirm before writing again.

### Step 4: Key commands to know

| Command | What it does |
|---------|-------------|
| `/opsx:propose` | Create a structured change proposal |
| `/opsx:explore` | Analysis phase before implementation |
| `/opsx:apply` | Implement a proposal by spec |
| `/opsx:archive` | Record a completed change |
| `openspec update` | Refresh agent instructions after a package upgrade |

### Step 5: Expanding the profile (optional)

To unlock 8 additional workflows (`/opsx:new`, `/opsx:ff`, `/opsx:verify`, etc.):
```bash
openspec config profile
```

---

## Phase 4: Summary

Close with a clear wrap-up:

```
## Setup Complete

### Done
- ✅ Audit completed — [N action items identified]
- ✅ CLAUDE.md [created / improved]
- ✅ .github/copilot-instructions.md [created / improved]
- ✅ OpenSpec [installed / confirmed] and initialized

### Your next steps
1. [Install LSP if flagged — exact command]
2. [Add recommended MCPs — point to mcp-catalog or specific instructions]
3. Start your first proposal: `/opsx:propose <your-first-feature-name>`

### Good to know
- Specs live in `openspec/specs/` — keep them updated as you build
- Each proposed change gets its own folder in `openspec/changes/`
- Run `openspec update` any time you upgrade the OpenSpec package
```
