# openspec-setup-plugin

A Claude Code plugin with skills to set up [OpenSpec](https://openspec.pro) in any project — greenfield or brownfield.

OpenSpec is a spec-driven development (SDD) framework: teams and AI agents agree on what to build before writing code. It creates a structured `openspec/` directory with specs, proposals, and change history, and installs slash commands (`/opsx:propose`, `/opsx:apply`, etc.) into your AI tool.

---

## Skills

### `openspec:setup` — Full Setup Wizard

Runs the complete setup sequence in three phases:
1. **Audit** — detects stack, checks Node.js and OpenSpec versions, recommends LSP and MCPs
2. **Agent files** — generates or improves CLAUDE.md and `.github/copilot-instructions.md`
3. **OpenSpec init** — guides through installation and initialization

**Trigger examples**:
- "set up OpenSpec on my project"
- "install OpenSpec"
- "configure OpenSpec"
- "bootstrap OpenSpec"

---

### `openspec:audit` — Standalone Audit

Produces a structured readiness report without making any changes. Shows what's installed,
what's missing, and what to do about it.

**Output**: Node.js and OpenSpec versions, detected language(s) with LSP recommendations (researched
via WebSearch if not in the catalog), context-aware MCP server suggestions, and agent file status.

**Trigger examples**:
- "audit my setup"
- "check what's installed"
- "what do I need for OpenSpec"
- "which LSP should I use for this project"

---

### `openspec:agent-files` — Agent File Generator / Reviewer

Creates or improves the AI agent instruction files:
- `CLAUDE.md` — for Claude Code
- `.github/copilot-instructions.md` — for GitHub Copilot

**If files exist**: reads them, evaluates against a quality checklist, and proposes targeted improvements.  
**If files are missing**: runs a 7-question interview and generates both files from scratch.

**Trigger examples**:
- "generate CLAUDE.md"
- "review my CLAUDE.md"
- "create copilot instructions"
- "my CLAUDE.md is outdated, update it"
- "write AI instructions for my project"

---

### `openspec:figma` — Figma Integration (Setup + Day-to-day Workflow)

Single entry point for Figma integration. Covers both one-time project setup (detect tier, install MCP,
run `create_design_system_rules`, write `openspec/config.yaml` rules that enforce frame links and token
codeSyntax) and the day-to-day workflow (which Figma MCP tool to call at each OpenSpec phase). Supports
three tiers: Basic (any plan), Standard (Tokens Studio pipeline), Full (Code Connect).

**Trigger examples**:
- "set up Figma with OpenSpec"
- "connect Figma to Claude Code"
- "how do I use Figma in my spec"
- "get design tokens from Figma"
- "add design token rules to my OpenSpec config"
- "which Figma MCP tool should I call"

---

## Agent

### `openspec-expert`

An expert agent on OpenSpec concepts, commands, and workflows. Available as a subagent to the
skills above, or invocable directly for questions about OpenSpec.

Knows: all slash commands (core and expanded profiles), `config.yaml` options, directory structure,
spec-writing best practices, and the propose → apply → archive workflow. Checks the project's actual
OpenSpec files before answering to give grounded, specific responses.

---

## Supported AI Tools

| Tool | What's generated |
|------|----------------|
| Claude Code | CLAUDE.md, `.claude/commands/opsx/` slash commands |
| GitHub Copilot | `.github/copilot-instructions.md` |

---

## Requirements

- **Node.js ≥ 20.19.0** (required by OpenSpec CLI)
- **OpenSpec**: `npm install -g @fission-ai/openspec@latest`

---

## Installation

```bash
claude plugin install path/to/openspec-setup-plugin
```

Or, once published to a registry:
```bash
claude plugin install openspec-setup@<registry>
```

---

## Plugin Structure

```
openspec-setup-plugin/
├── .claude-plugin/plugin.json
├── .agents/
│   └── openspec-expert.md           ← expert agent definition
├── skills/
│   ├── setup/
│   │   └── SKILL.md                 ← full wizard
│   ├── audit/
│   │   ├── SKILL.md                 ← standalone audit
│   │   └── references/
│   │       ├── lsp-catalog.md       ← 15+ language server recommendations
│   │       └── mcp-catalog.md       ← stack-aware MCP recommendations (incl. Figma)
│   ├── agent-files/
│   │   ├── SKILL.md                 ← generator / reviewer
│   │   └── references/
│   │       └── quality-criteria.md  ← CLAUDE.md review checklist
│   └── figma/
│       ├── SKILL.md                 ← setup + day-to-day Figma workflow (unified)
│       └── references/
│           ├── config-templates.md  ← config.yaml templates per tier (Basic/Standard/Full)
│           └── figma-mcp-tools.md   ← complete Figma MCP tool reference
└── README.md
```
