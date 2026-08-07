# Figma MCP Tools Reference

Complete list of tools available via the Figma MCP server, with their relevance to the OpenSpec workflow.
"Both" = available on both remote plugin and desktop server. "Remote only" = requires the plugin option.

---

## Design system & tokens

### `get_variable_defs`
**Available**: Both  
**Use in OpenSpec**: Call before writing any spec that involves colors, spacing, or typography.

Returns per design token:
```
name: "color/brand/primary"
resolvedType: COLOR | FLOAT | STRING | BOOLEAN
valuesByMode: { "light": "#0057FF", "dark": "#4D90FF" }
scopes: ["FILL_COLOR", "STROKE_COLOR"]  ← where this token is valid
codeSyntax:
  WEB: "var(--color-brand-primary)"
  ANDROID: "@color/brand_primary"
  iOS: "Color.brandPrimary"
collection: "Brand tokens"
```

**Key usage**: always use `codeSyntax.WEB` (or the target platform) as the token reference in specs
and code — this is the exact CSS variable or constant name in the codebase.

### `create_design_system_rules`
**Available**: Both  
**Use in OpenSpec**: Run once during setup to generate the `context` block for `openspec/config.yaml`.

Scans the Figma file and produces a structured description of the design system — component inventory,
token naming conventions, and framework-specific defaults. Paste the output into the `context` field
of `openspec/config.yaml` so all future agents have permanent design system grounding.

### `search_design_system`
**Available**: Remote only  
**Use in OpenSpec**: Find which design system library a token or component belongs to when working
with multi-library Figma setups.

### `get_libraries`
**Available**: Remote only  
Returns all team libraries linked to the file — useful for documenting which library contains the
project's design tokens.

---

## Component resolution (Code Connect)

### `get_code_connect_map`
**Available**: Both (requires Code Connect to be configured in Figma Dev Mode)  
**Use in OpenSpec**: Call before writing any spec that references UI components.

Returns for each component instance in a frame:
```
nodeId: "123:456"
componentName: "Button/Primary"
codeConnectSrc: "src/components/ui/Button.tsx"
codeConnectName: "Button"
framework: "react"
snippet: "<Button variant=\"primary\" size=\"md\">Label</Button>"
```

**Key usage**: use `codeConnectSrc` as the import path and `snippet` as the usage example in specs.
Without Code Connect, this tool returns empty — agents then generate raw HTML/CSS instead.

### `get_code_connect_suggestions`
**Available**: Remote only  
Proposes mappings between unlinked Figma components and code components. Useful when setting up
Code Connect for the first time — review and accept suggestions via `send_code_connect_mappings`.

### `send_code_connect_mappings` / `add_code_connect_map`
**Available**: Remote / Both  
Establishes Code Connect mappings. `add_code_connect_map` works on both servers;
`send_code_connect_mappings` (remote) confirms a batch of suggested mappings.

---

## Design context & code generation

### `get_design_context`
**Available**: Both  
**Use in OpenSpec**: Call during `/opsx:apply` to get framework-specific implementation code.

With Code Connect configured: returns real component usage (`<Button variant="primary" />`).  
Without Code Connect: returns generated HTML/CSS with inline styles.

Pass a Figma frame URL or node ID. Defaults to React + Tailwind; configurable for other frameworks.
This is the highest-level tool — it combines token data and Code Connect mappings into ready-to-use code.

### `get_metadata`
**Available**: Both  
Returns lightweight XML: layer names, IDs, types, positions, sizes, hierarchy. Useful during
`/opsx:explore` to understand the frame's layer structure before implementation.

### `get_screenshot`
**Available**: Both  
Returns a visual render of a frame. Use for validation — compare implementation screenshots against
the design render.

### `get_motion_context`
**Available**: Both  
Returns keyframe animation data with easing curves, CSS `@keyframes` snippets, and motion.dev snippets.
Use when a proposal involves animations or transitions.

---

## Figma file editing (agents writing back to Figma)

### `use_figma`
**Available**: Remote only  
Executes Figma Plugin API code on the canvas. Allows agents to modify Figma files directly —
create frames, update properties, add annotations.

### `generate_figma_design`
**Available**: Remote only  
Creates a Figma design from a screenshot or description.

### `generate_diagram`
**Available**: Remote only  
Creates a FigJam diagram from Mermaid notation. Useful for documenting architecture in Figma.

### `upload_assets`
**Available**: Remote only  
Uploads images into a Figma file.

---

## Utility

### `whoami`
**Available**: Remote only  
Returns authenticated user info — useful for debugging connection issues.

---

## When to call which tool in the OpenSpec workflow

| OpenSpec phase | Figma MCP tool | Why |
|---------------|---------------|-----|
| `/opsx:propose` | — (human provides frame link) | Frame link added manually by engineer |
| `/opsx:explore` | `get_metadata`, `get_screenshot` | Understand frame structure |
| Writing specs | `get_variable_defs` | Extract exact token codeSyntax |
| Writing specs (Full) | `get_code_connect_map` | Resolve real component import paths |
| `/opsx:apply` | `get_variable_defs` | Verify token references before implementing |
| `/opsx:apply` (Full) | `get_design_context` | Get framework-specific code with real components |
| Validation | `get_screenshot` | Compare render against implementation |
| Config setup | `create_design_system_rules` | Generate `openspec/config.yaml` context block |
