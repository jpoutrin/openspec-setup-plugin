# MCP Server Recommendations

Context-aware MCP server recommendations based on detected project stack.
Always recommend the Universal MCPs first, then add stack-specific ones.

---

## Universal (recommend for every project)

### context7
Pulls live, up-to-date documentation for any library directly into the agent's context. Prevents
hallucinated APIs and wrong function signatures — especially valuable on projects with frequently
updated dependencies.

```json
// Add to ~/.claude/settings.json or .claude/settings.json (project-level):
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    }
  }
}
```

**Covers**: npm packages, PyPI packages, crates.io, pkg.go.dev, docs.rs, and more.

---

## By Language / Framework

### Node.js / TypeScript / JavaScript
- **context7** — covers npm docs well, no additional MCPs typically needed.
- If Next.js detected: context7 covers Next.js docs.

### Python
- **context7** — covers PyPI packages and major Python frameworks (FastAPI, Django, SQLAlchemy).

### Rust
- **context7** — covers docs.rs and the standard library.

### Go
- **context7** — covers pkg.go.dev.

### Java / Kotlin
- **context7** — covers Maven Central packages and Spring docs.

---

## By Infrastructure Detected

### Database

**Detection signals**: `DATABASE_URL`, `POSTGRES_URL`, `MONGODB_URI`, `redis://` in `.env`, `db:` service in
`docker-compose.yml`, `sqlalchemy`, `psycopg`, `mongoose` in dependencies.

**PostgreSQL**:
```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres", "${DATABASE_URL}"]
    }
  }
}
```
Use: query the database schema, run read-only queries for context.

**SQLite**:
```json
{
  "mcpServers": {
    "sqlite": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sqlite", "--db-path", "./path/to/db.sqlite"]
    }
  }
}
```

**MongoDB**: Search MCP registry for a maintained MongoDB server — `npx @modelcontextprotocol/server-*` options evolve frequently; verify at https://github.com/modelcontextprotocol/servers.

### Docker

**Detection signals**: `docker-compose.yml`, `Dockerfile`, `compose.yaml`.

Docker MCP gives the agent visibility into running containers, images, and compose services:
```bash
docker extension install docker/labs-ai-tools-for-devs:latest
```
Or check https://github.com/docker/mcp-server for the latest Docker MCP.

### GitHub Repository

**Detection signals**: `.github/` directory, `git remote -v` shows `github.com`.

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "<your-token>"
      }
    }
  }
}
```
Use: create/list issues and PRs, review code, search the repo — without leaving the terminal.

### REST API Project

**Detection signals**: OpenAPI/Swagger spec (`openapi.yaml`, `swagger.json`), `routes/` directory, `express`,
`fastapi`, `flask`, `koa` in dependencies.

```json
{
  "mcpServers": {
    "fetch": {
      "command": "uvx",
      "args": ["mcp-server-fetch"]
    }
  }
}
```
Use: the agent can make HTTP requests to test endpoints during development.

---

## Adding MCP Servers to Claude Code

MCP servers are declared in a settings JSON file. Project-level config (`.claude/settings.json`) takes
precedence over user-level (`~/.claude/settings.json`).

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@package/name"],
      "env": {
        "OPTIONAL_VAR": "value"
      }
    }
  }
}
```

**After adding**: restart Claude Code (or run `/mcp` to reload) for the new servers to appear.

**Verify servers are connected**: run `/mcp` in a Claude Code session to see the list of active MCP servers.

---

### Figma (design-heavy projects)

**Detection signals**: `figma` in README or docs, `.figma` files, design tokens files (`tokens.json`,
`design-tokens/`), team mentions Figma in CLAUDE.md, or project is a UI component library / front-end app.

Install via the official Claude Code plugin (handles auth automatically):
```bash
claude plugin install figma@claude-plugins-official
```

Alternatively, use the Figma desktop Dev Mode server (org/enterprise use):
```bash
claude mcp add --transport http figma-desktop http://127.0.0.1:3845/mcp
```

Use: agents can read Figma frame layouts, components, and design variables to implement designs faithfully.
Run `openspec:figma` for full setup and workflow guidance.

---

## MCP Registry

For servers not listed here, browse: https://github.com/modelcontextprotocol/servers
The registry is community-maintained and updated frequently.
