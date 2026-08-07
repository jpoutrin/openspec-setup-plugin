# openspec/config.yaml Templates — Figma Integration

Three templates matching the three integration tiers. Fill in the bracketed placeholders with
the values gathered in Step 3 of the `openspec:figma` skill.

---

## Tier 1 — Basic (any Figma plan)

MCP connected, token variable paths enforced, frame links required in proposals.

```yaml
schema: spec-driven

context: |
  Design system: [Name, e.g. "Acme Design System"]
  Figma file: [URL to the main Figma file or library]
  Design tokens: Figma Variables — query with get_variable_defs before writing specs
  Token naming: [e.g., color/brand/*, spacing/*, radius/*, typography/*]
  Framework: [e.g., React, Vue, Svelte]
  MCP: figma remote plugin (or figma-desktop — requires Figma open in Dev Mode)
  Code Connect: not configured

rules:
  proposal:
    - Include a "Design" section with a direct Figma frame link (right-click a frame → Copy link to selection)
    - List the Figma component names visible in the frame
    - Flag any new design tokens required, using Figma variable path format (e.g., color/brand/new-accent) — do not invent values; the design team creates tokens in Figma first
  specs:
    - Before writing: call get_variable_defs on the relevant Figma frame to extract exact token names and codeSyntax
    - Reference tokens by their codeSyntax for the target platform (e.g., var(--color-brand-primary) for web) — never hardcoded hex, pixel, or raw Tailwind values
    - For each UI element, name the Figma component it comes from
    - Specify interaction states using exact Figma variant names (e.g., Button variant=primary state=hover)
  spec-delta:
    - Token references must match entries returned by get_variable_defs — do not invent token names
    - If new tokens are needed, flag them explicitly so the design team can create them in Figma before implementation begins
  tasks:
    - Each task touching UI must cite its Figma frame link
    - Mark a UI task done only when no hardcoded color, spacing, or typography values remain in the implementation

operations:
  apply:
    guidance: |
      Before implementing any UI element:
      1. Call get_variable_defs on the Figma frame to get exact token codeSyntax for colors and spacing
      2. Use only token references in code — var(--token-name) for CSS, imported token constants for JS/TS
      3. Verify every component exists in the Figma design system before creating a new one
      4. If a component is missing from the design system, flag it in the implementation notes rather than inventing styles
  archive:
    guidance: |
      Before archiving:
      - Confirm no hardcoded color, spacing, or typography values were introduced (grep -r '#[0-9a-fA-F]' src/components)
      - If new tokens were used, verify they now exist in Figma Variables
```

---

## Tier 2 — Standard (Professional+ with Tokens Studio)

Adds a token pipeline: Tokens Studio syncs Figma Variables → `tokens.json` in the repo → Style Dictionary
generates platform-specific files. Specs can now be verified against the JSON source of truth.

```yaml
schema: spec-driven

context: |
  Design system: [Name]
  Figma file: [URL]
  Design tokens: Figma Variables — query with get_variable_defs; source of truth is tokens.json
  Token file: [path, e.g., tokens/tokens.json or openspec/specs/design-system/tokens.json]
  Token pipeline: Tokens Studio (Figma plugin) → tokens.json → Style Dictionary → [output path, e.g., src/styles/tokens/]
  Token naming: [e.g., color/brand/*, spacing/*, radius/*, typography/*]
  Framework: [e.g., React + Tailwind]
  MCP: figma remote plugin
  Code Connect: not configured

rules:
  proposal:
    - Include a "Design" section with a direct Figma frame link
    - List the Figma component names visible in the frame
    - Flag any new design tokens required — new tokens must be added in Figma first, then synced via Tokens Studio before implementation
  specs:
    - Before writing: call get_variable_defs on the Figma frame to extract exact token names
    - Reference tokens by their codeSyntax (e.g., var(--color-brand-primary)) — verify the token exists in tokens.json before referencing it
    - Never hardcode hex, px, or arbitrary Tailwind classes for design-system values
    - For each UI element, name the Figma component and its relevant variant
  spec-delta:
    - Token references must exist in both Figma Variables (get_variable_defs) and tokens.json
    - New tokens required by this change must be added to both before /opsx:apply runs
  tasks:
    - Each UI task must cite its Figma frame link
    - Include a sub-task to verify tokens.json contains all referenced tokens before implementation

operations:
  apply:
    guidance: |
      Before implementing any UI:
      1. Call get_variable_defs to get exact token codeSyntax
      2. Cross-check against tokens.json — if a token is in Figma but not in tokens.json, sync Tokens Studio first
      3. Use only Style Dictionary output files (e.g., src/styles/tokens/variables.css) for token imports
      4. Never hardcode values that should be tokens
  archive:
    guidance: |
      Before archiving:
      - grep -r '#[0-9a-fA-F]\{3,6\}' src/components — confirm no hardcoded colors
      - Verify any new tokens are in tokens.json and have been processed by Style Dictionary
      - If Tokens Studio sync is pending, complete it before archiving
```

---

## Tier 3 — Full (Organization/Enterprise with Code Connect)

Adds Code Connect: `get_code_connect_map` resolves every Figma component instance to its real code
component (`codeConnectSrc`, `codeConnectName`). Agents use real imports, not generated HTML/CSS.

```yaml
schema: spec-driven

context: |
  Design system: [Name]
  Figma file: [URL]
  Design tokens: Figma Variables — get_variable_defs; source of truth is tokens.json
  Token file: [path]
  Token pipeline: Tokens Studio → tokens.json → Style Dictionary → [output path]
  Token naming: [naming convention]
  Code Connect: configured — use get_code_connect_map to resolve component paths and import snippets
  Framework: [e.g., React + Tailwind]
  Component library: [e.g., src/components/ui/ — all components have Code Connect mappings]
  MCP: figma remote plugin

rules:
  proposal:
    - Include a "Design" section with the Figma frame link
    - List the Figma component names and their Code Connect code names (obtainable via get_code_connect_map)
    - Flag any components without a Code Connect mapping — these need to be mapped before /opsx:apply
    - Flag any new design tokens required
  specs:
    - Before writing: call get_variable_defs for tokens AND get_code_connect_map for component mappings
    - Reference tokens by codeSyntax — never hardcoded values
    - For every UI component: include codeConnectSrc (file path) and codeConnectName (component name)
    - Usage examples must use real component imports (from Code Connect), not raw HTML/CSS
    - Specify props and variants using the exact names from Code Connect mappings
    - Document states (hover, focus, disabled) using the Figma variant names
  spec-delta:
    - Token references must match get_variable_defs output
    - Component references must match get_code_connect_map — if a component has no mapping, flag it explicitly; do not invent imports
    - New components added by this change must be mapped in Code Connect before being referenced in specs
  tasks:
    - Each UI task must cite: Figma frame link, component codeConnectSrc, and relevant token names
    - Include a Code Connect verification task if any new components are introduced

operations:
  apply:
    guidance: |
      Before implementing any UI:
      1. Call get_variable_defs to get exact token codeSyntax for all colors, spacing, and typography
      2. Call get_code_connect_map on the Figma frame to get real component import paths
      3. Prefer get_design_context output — it returns framework-specific code using Code Connect mappings
      4. If get_design_context output is available, use it as the implementation starting point
      5. Never create a raw HTML/CSS implementation of something that exists in the component library
      6. Use only token references — verify against tokens.json
  archive:
    guidance: |
      Before archiving:
      - No hardcoded values (grep check)
      - All components used are from the library via Code Connect paths — no hand-rolled equivalents
      - New tokens added to Figma and synced to tokens.json
      - Any new components have Code Connect mappings created in Figma Dev Mode

githubCopilot:
  cloudAgent: false
```

---

## Custom schema — design-first (optional, any tier)

For teams that want a mandatory `design.md` artifact that blocks `/opsx:apply` until it exists.
Use this when the Basic/Standard/Full rules alone aren't strict enough — this adds a hard structural gate.

```bash
openspec schema fork spec-driven design-first
```

Then edit `openspec/schemas/design-first/schema.yaml`:

```yaml
name: design-first
version: 1
description: Requires a design artifact (Figma frame + tokens + components) before tasks or implementation

artifacts:
  - id: proposal
    generates: proposal.md
    template: proposal.md
    instruction: Create a proposal explaining WHY this change is needed.
    requires: []

  - id: design
    generates: design.md
    template: design.md
    instruction: |
      Create a design document with:
      - Figma frame URL(s)
      - Design tokens used (from get_variable_defs — codeSyntax format)
      - Components used (from get_code_connect_map if Code Connect is active)
      - Responsive behavior notes
    requires:
      - proposal

  - id: tasks
    generates: tasks.md
    template: tasks.md
    requires:
      - design

apply:
  requires: [tasks]
  tracks: tasks.md
```

And create `openspec/schemas/design-first/templates/design.md`:

```markdown
# Design — [change name]

## Figma frames
<!-- Link to each frame/screen involved. Use right-click → Copy link to selection. -->
- Main frame: [URL]
- [Additional state/screen]: [URL]

## Design tokens
<!-- From get_variable_defs — use codeSyntax, never raw hex/px -->
| Property | Token path | Web codeSyntax |
|----------|-----------|----------------|
| [e.g., Background] | [e.g., color/brand/primary] | [e.g., var(--color-brand-primary)] |

## Components
<!-- From get_code_connect_map or Figma component panel -->
| Figma component | Code component | Import path |
|----------------|---------------|-------------|
| [e.g., Button/Primary] | [e.g., Button] | [e.g., src/components/ui/Button.tsx] |

## States and variants
<!-- Use exact Figma variant property names -->
- Default: [description]
- Hover: [description + token if color changes]
- Focus: [description]
- Disabled: [description]

## Responsive behavior
<!-- Figma auto-layout rules or breakpoint behavior -->
- Mobile (< 768px): [description]
- Desktop (≥ 768px): [description]

## Open questions
<!-- Anything unclear from the Figma frame that needs design team input -->
```

Enable the schema in `openspec/config.yaml`:
```yaml
schema: design-first
```
