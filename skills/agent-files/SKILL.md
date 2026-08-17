---
name: openspec:agent-files
description: >
  Generate or review and improve the AI agent instruction files for a project: CLAUDE.md (for Claude Code) and
  `.github/copilot-instructions.md` (for GitHub Copilot). If these files already exist, reads them, evaluates
  quality, identifies gaps, and proposes targeted improvements with a diff. If they don't exist, runs a
  brief structured interview and generates both files from scratch.
  ALWAYS invoke this skill when the user mentions "generate CLAUDE.md", "create agent instructions",
  "review my CLAUDE.md", "improve my CLAUDE.md", "update agent files", "write AI instructions for my project",
  "my CLAUDE.md is outdated", "create copilot instructions", "improve copilot instructions",
  or "what should go in CLAUDE.md". Also invoke it whenever the setup wizard reaches the agent-files phase.
---

# OpenSpec Agent Files

Create or improve the AI agent instruction files that tell Claude Code and GitHub Copilot about this project.
Good instruction files eliminate repeated questions, prevent agents from touching the wrong files, and make
the development experience significantly smoother.

Read `references/quality-criteria.md` before doing anything else — it defines what "good" looks like.

---

## Step 1: Check what exists

```bash
ls CLAUDE.md .claude/CLAUDE.md .github/copilot-instructions.md 2>/dev/null
```

- **Any files found** → go to **Review Mode**
- **No files found** → go to **Create Mode**

If only one of the two files exists, treat it as Review Mode for the existing file and Create Mode for the
missing one — handle both in one pass.

---

## Review Mode

Read all existing files in full, then evaluate them against `references/quality-criteria.md`.
If `openspec/config.yaml` exists, read it too — `quality-criteria.md`'s OpenSpec-specific section
checks CLAUDE.md's Conventions against it for contradictions.

Think about what a new agent would understand (or misunderstand) if it only had this file to go on.
The gaps that matter most are missing commands, vague conventions, and absent off-limits sections —
because these are what cause agents to make mistakes or ask the same questions repeatedly.

Present your findings:

```
## Review: CLAUDE.md

### What's working
- [Specific strengths — be concrete, not generic like "good structure"]

### Gaps
1. **[Section name or issue]**: [What's missing or unclear]
   → Proposed addition: [exact text you'd add]
2. ...

### Proposed changes
[Show the actual new/changed content — not a description of it]
```

Then ask: _"Want me to apply these improvements?"_

If yes, make the changes and show a brief summary of what changed.

---

## Create Mode

Run a short interview — one question at a time, waiting for each answer before continuing.
Explain the purpose of each question briefly so the engineer understands what they're shaping.

### Interview

**Q1** — _"What does this project do? (1–2 sentences — this will be the first thing any agent reads about this codebase)"_

**Q2** — _"How do you start the app locally? Give me the exact command (e.g., `npm run dev`, `uvicorn app:main --reload`, `go run ./cmd/server`)"_

**Q3** — _"How do you run the tests?"_

**Q4** — _"How do you build for production? (type 'skip' if this doesn't apply — e.g., for a service that's always run in dev mode)"_

**Q5** — _"Any conventions or patterns agents should always follow? Think: folder structure rules, which libraries to use, things you'd put in a code review comment. (e.g., 'no default exports', 'use Zod for all validation', 'feature-based folder structure under src/features/')"_

**Q6** — _"Are there directories or files agents should NEVER modify? (e.g., `dist/`, `generated/`, `migrations/`, `vendor/`)"_

**Q7** — _"Any environment variables or first-time setup steps a new agent or developer needs? (e.g., 'copy .env.example to .env', 'run docker-compose up -d before starting the server')"_

After collecting all answers, generate both files.

---

## Generated Files

### CLAUDE.md

Place at project root. Use this exact structure — tables and bullets over paragraphs, so it's
scannable in seconds:

```markdown
# [Project Name]

[Project description from Q1]

## Development Commands

| Action | Command |
|--------|---------|
| Run    | `[Q2 answer]` |
| Test   | `[Q3 answer]` |
| Build  | `[Q4 answer, or "N/A"]` |

## Architecture

[Describe key directories and their purpose — 3 to 6 bullet points. Be specific:
"src/features/ — one folder per feature (auth, billing, etc.), each with its own routes, services, and tests"
rather than "src/ — source code"]

## Conventions

[Q5 answer as bullet points. Each point should be a specific, actionable rule, not an aspiration.
If the engineer gave examples, include them.]

## Do Not Touch

[Q6 answer. If nothing was specified, write "None specified — use judgment."]

## Environment Setup

[Q7 answer. Include exact steps, not just "set up your env".]
```

### `.github/copilot-instructions.md`

Copilot reads this file automatically in supported editors. Keep it more concise than CLAUDE.md —
Copilot benefits from brevity in its instruction file.

```markdown
# [Project Name]

[Same 1–2 sentence description]

## Commands
- **Run**: `[Q2]`
- **Test**: `[Q3]`
- **Build**: `[Q4 or N/A]`

## Conventions
[Key rules from Q5 — condensed to the 3–5 most important ones]

## Off-limits
Never modify: [Q6 list]

## Setup
[Q7 — critical steps only]
```

Create the `.github/` directory if it doesn't exist:
```bash
mkdir -p .github
```

---

## After generating or updating files

Tell the engineer:
- Where the files were created/updated
- One suggestion: keep CLAUDE.md updated as the project evolves — outdated instructions are worse than
  none, because they actively mislead

If OpenSpec is configured in this project, add a note to CLAUDE.md:
```markdown
## OpenSpec

This project uses OpenSpec for spec-driven development.
- Specs live in `openspec/specs/`
- Propose changes with `/opsx:propose <name>`
- Implement with `/opsx:apply`, archive with `/opsx:archive`
```
