---
name: openspec:figma
description: >
  Integrate Figma with OpenSpec for design-fidelity-enforced spec-driven development. Covers one-time
  project setup (detect integration tier, install Figma MCP, run create_design_system_rules, write
  openspec/config.yaml rules that enforce frame links and design token codeSyntax across all proposals
  and specs) and day-to-day workflow (which Figma MCP tool to call at each OpenSpec phase:
  get_variable_defs before writing specs, get_code_connect_map for real component paths, get_design_context
  during apply). Supports three tiers: Basic (any plan), Standard (Tokens Studio pipeline), Full (Code
  Connect for component-level precision).
  ALWAYS invoke this skill when the user mentions "set up Figma with OpenSpec", "configure Figma MCP",
  "connect Figma to Claude Code", "add design token rules to config.yaml", "how do I use Figma in my spec",
  "get design tokens from Figma", "which Figma MCP tool should I call", "add Figma frame to my proposal",
  "Code Connect with OpenSpec", or "enforce design tokens in my OpenSpec project".
hooks:
  PostToolUse:
    - matcher: "Write"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/hooks/validate-config.sh"
---

# OpenSpec + Figma

Wire Figma into the OpenSpec workflow so that design token references, frame links, and component paths
become structural requirements in every proposal and spec — not optional conventions.

**First time on this project?** Start with **Part 1 — Setup** (run once per project).  
**Already set up?** Jump to **Part 2 — Day-to-day workflow**.

Read `references/config-templates.md` and `references/figma-mcp-tools.md` as needed.

---

# Part 1 — One-time Setup

## Step 1: Detect the integration tier

| Tier | Plan required | Key capability |
|------|--------------|---------------|
| **Basic** | Any Figma plan | MCP + config.yaml rules: frame links and token variable paths enforced |
| **Standard** | Professional+ | Tokens Studio pipeline: tokens.json in repo, Style Dictionary transforms |
| **Full** | Organization or Enterprise | Code Connect: agents resolve real component import paths |

**Detection signals** — check before asking:
- `.figma` files in the repo → Full (Code Connect already configured)
- `tokens.json` or `tokens/` directory → Standard or Full
- Ask: "Is Code Connect set up in your Figma file?" if still unclear

## Step 2: Install the Figma MCP

```bash
claude mcp list 2>/dev/null | grep -i figma || echo "not connected"
```

Skip if already connected.

**Option A — Remote plugin (recommended)**
```bash
claude plugin install figma@claude-plugins-official
```
Restart Claude Code → `/plugin` → Installed tab → select `figma` → Enter → Allow access in browser.
Provides all tools including `search_design_system` and `get_libraries`.

**Option B — Desktop Dev Mode server (org/enterprise or offline)**
Figma desktop: open Design file → Dev Mode → enable MCP server toggle.
```bash
claude mcp add --transport http figma-desktop http://127.0.0.1:3845/mcp
```
Limitation: server only runs while Figma is open in Dev Mode.

Verify: `claude mcp list` → figma shows `connected`.

## Step 3: Generate design system context

Call `create_design_system_rules` to let Figma generate the `context` block for `openspec/config.yaml`.
This scans the file and produces component inventory, token naming conventions, and framework defaults.

Run in a Claude Code session:
```
Use the Figma MCP create_design_system_rules tool on [Figma file URL]
and show me the output to add to openspec/config.yaml
```

If unavailable, collect manually — one question at a time:
1. "What is the URL of your main Figma design file?"
2. "What is the design system called?"
3. "What token naming convention? (e.g., `color/brand/*`, `--color-brand-*`)"
4. "What framework? (React, Vue, Svelte…)"
5. *(Standard/Full)* "Where does tokens.json live in the repo?"
6. *(Full)* "Is Code Connect set up in the Figma file?"

## Step 4: Write openspec/config.yaml

Open (or create) `openspec/config.yaml` and apply the template from `references/config-templates.md`
for the detected tier. Three structural elements to configure:

**`context`** — injected into every artifact. Grounds all agents permanently in the design system,
token naming convention, and available MCP tools.

**`rules.<artifact>`** — constraints injected per artifact type. This is what makes design fidelity
structural rather than advisory:
- `rules.proposal` → require frame link, component names, new tokens flagged
- `rules.specs` → require `get_variable_defs` call, codeSyntax only, no hardcoded values
- `rules.spec-delta` → token names must match `get_variable_defs` output
- `rules.tasks` → each UI task cites its frame link

**`operations.apply.guidance`** — injected at implementation time, enforces the mandatory MCP calls.

Fill in the bracketed placeholders with the values from Step 3.

## Step 5: Tier-specific additional setup

### Standard — Tokens Studio pipeline
1. Install **Tokens Studio** in Figma (free, search Figma Community)
2. Connect to repo: Settings → Sync → GitHub (needs a PAT with `repo` scope)
3. Install Style Dictionary: `npm install --save-dev style-dictionary`
4. Create `style-dictionary.config.js` → `tokens.json` to `src/styles/tokens/`
5. Add to config.yaml context: `Token pipeline: Tokens Studio → tokens.json → Style Dictionary → [output]`

### Full — Code Connect setup
1. Figma desktop, Dev Mode → select a component → right panel → **Add Code Connect**
2. Link to the code component: file path + component name + snippet
3. Repeat for all design system components
4. Add to config.yaml context: `Code Connect: configured — always call get_code_connect_map before implementing a component`

## Step 6: Optional — custom design-first schema

Adds a mandatory `design.md` artifact that hard-blocks `/opsx:apply` until it exists.
See the "Custom schema — design-first" section in `references/config-templates.md`.

```bash
openspec schema fork spec-driven design-first
# edit openspec/schemas/design-first/schema.yaml and templates/design.md
```
Enable: `schema: design-first` in config.yaml.

## Step 7: Validate and update CLAUDE.md

`openspec validate` runs automatically via a skill hook after the config is written. If it reports
errors, fix and rewrite the file — the hook re-validates automatically.

Test rules are active: `/opsx:propose test-figma-setup` — the generated `proposal.md` should contain
a "Design" section placeholder confirming `rules.proposal` is being injected.

Add a Figma section to CLAUDE.md:
```markdown
## Design system (Figma)

- MCP: figma remote plugin (or figma-desktop — open Figma in Dev Mode first)
- Figma file: [URL]
- Integration tier: [Basic / Standard / Full]
- Token convention: [e.g., color/brand/* → var(--color-brand-*)]
- Token pipeline: [none / Tokens Studio → tokens.json → Style Dictionary → src/styles/tokens/]
- Code Connect: [configured / not configured]
```

---

# Part 2 — Day-to-day Workflow

## The full workflow at a glance

```
Figma (design) → proposal.md (frame link) → specs (tokens + components) → /opsx:apply (MCP tools) → archive
```

| OpenSpec phase | What to do | MCP tool |
|---------------|-----------|---------|
| `/opsx:propose` | Paste frame link in Design section | — (human step) |
| `/opsx:explore` | Inspect layer structure | `get_metadata` |
| Writing specs | Extract exact token codeSyntax | `get_variable_defs` |
| Writing specs (Full) | Resolve real component import paths | `get_code_connect_map` |
| `/opsx:apply` | Get framework-specific code | `get_design_context` |
| `/opsx:apply` | Verify token codeSyntax before writing | `get_variable_defs` |
| Validation | Visual comparison vs design | `get_screenshot` |

## Proposing a change: `/opsx:propose`

Add a Design section to the generated `proposal.md`:
```markdown
## Design

- Main frame: [right-click frame in Figma → Copy link to selection]
- Components involved: [Figma component names visible in the frame]
- New tokens required: [flag for design team — don't invent values]
```

For multiple screens: link each state separately (empty, loaded, error, etc.).

## Writing specs: tokens

Call `get_variable_defs` on the Figma frame before writing any spec touching color, spacing, or typography.
Use `codeSyntax.WEB` (or target platform) — never the raw hex value.

Spec pattern that satisfies `rules.specs`:
```markdown
## Button — Primary variant

Figma frame: [link]

| Property | Token path | CSS variable |
|----------|-----------|-------------|
| Background | color/brand/primary | var(--color-brand-primary) |
| Text | color/text/on-primary | var(--color-text-on-primary) |
| Padding | spacing/md × spacing/sm | var(--spacing-md) / var(--spacing-sm) |
| Border radius | radius/md | var(--radius-md) |

States (use exact Figma variant names):
- Hover: background → color/brand/primary-hover
- Focus: 2px outline color/focus/ring
- Disabled: opacity 0.5
```

## Writing specs: components (Full tier)

Call `get_code_connect_map` on the frame. Returns per component:
```
codeConnectSrc: "src/components/ui/Button.tsx"
codeConnectName: "Button"
snippet: '<Button variant="primary" size="md">Label</Button>'
```

Add to the spec:
```markdown
Component: Button (src/components/ui/Button.tsx)
Usage: <Button variant="primary" size="md" />
```

## Implementation: `/opsx:apply`

`operations.apply.guidance` from config.yaml is injected automatically.

**Basic/Standard**: call `get_variable_defs` → get codeSyntax → implement with token references only.

**Full tier**: call `get_design_context` on the frame first — returns framework-specific code using
real Code Connect components. Use this as the implementation starting point.

Post-implementation token audit:
```bash
grep -r '#[0-9a-fA-F]\{3,6\}' src/components --include="*.css" --include="*.tsx"
```

## Archiving: `/opsx:archive`

Before archiving (injected via `operations.archive.guidance`):
- No hardcoded color, spacing, or typography values
- *(Standard)* New tokens exist in `tokens.json` and processed by Style Dictionary
- *(Full)* New components have Code Connect mappings in Figma Dev Mode

## Troubleshooting

**Figma MCP disconnected** — remote: re-authenticate via `/plugin` → Installed → figma → Enter.
Desktop: open Figma in Dev Mode, re-enable the MCP server toggle.

**`get_variable_defs` returns empty** — no Figma Variables defined; tokens may be hardcoded styles.
Suggest the design team migrate to Figma Variables.

**`get_code_connect_map` returns empty** — Code Connect not configured, or requires Org/Enterprise plan.
Fall back to Basic/Standard tier; list component paths manually in specs.

**Agent uses hardcoded values despite rules** — check `cat openspec/config.yaml` for `rules.specs`.
Re-run Part 1 Step 4 if rules are missing.

**Frame link gives wrong context** — use right-click → **Copy link to selection** on the specific frame,
not the browser URL bar (which points to the page, not the frame).

For the complete Figma MCP tool reference, see `references/figma-mcp-tools.md`.
For config.yaml templates per tier, see `references/config-templates.md`.
