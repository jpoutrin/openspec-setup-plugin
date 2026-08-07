# LSP Catalog

Language server recommendations for use with Claude Code's LSP plugin system.
For languages not listed here, use WebSearch: `"[language] language server LSP install 2025"`.

---

## TypeScript / JavaScript

- **Official Claude Code plugin**: `typescript-lsp@claude-plugins-official`
  ```bash
  claude plugin install typescript-lsp
  ```
- **Manual LSP server**: typescript-language-server
  ```bash
  npm install -g typescript-language-server typescript
  ```
- **Extensions**: `.ts`, `.tsx`, `.js`, `.jsx`, `.mts`, `.cts`, `.mjs`, `.cjs`

---

## Python

- **LSP**: pylsp (Python LSP Server) — covers linting, completion, references
  ```bash
  pip install python-lsp-server[all]
  # or with uv:
  uv tool install python-lsp-server
  ```
- **Alternative**: Pyright — stricter types, faster
  ```bash
  npm install -g pyright
  ```
- **Check for official plugin first**:
  ```bash
  claude plugin list | grep -i python
  ```
- **Extensions**: `.py`

---

## Rust

- **LSP**: rust-analyzer (bundled with rustup)
  ```bash
  rustup component add rust-analyzer
  ```
- **Check for official plugin first**:
  ```bash
  claude plugin list | grep -i rust
  ```
- **Extensions**: `.rs`

---

## Go

- **LSP**: gopls (official Go language server)
  ```bash
  go install golang.org/x/tools/gopls@latest
  ```
- **Extensions**: `.go`

---

## Java

- **LSP**: Eclipse JDT Language Server (jdtls)
  ```bash
  # macOS with Homebrew:
  brew install jdtls
  # or download from: https://github.com/eclipse-jdtls/eclipse.jdt.ls/releases
  ```
- **Extensions**: `.java`

---

## Kotlin

- **LSP**: kotlin-language-server
  ```bash
  # macOS:
  brew install kotlin-language-server
  # or download from: https://github.com/fwcd/kotlin-language-server/releases
  ```
- **Extensions**: `.kt`, `.kts`

---

## C\#

- **LSP**: csharp-ls (lightweight, cross-platform)
  ```bash
  dotnet tool install --global csharp-ls
  ```
- **Alternative**: OmniSharp (heavier, more features)
  ```bash
  # macOS:
  brew install omnisharp
  ```
- **Extensions**: `.cs`

---

## C / C++

- **LSP**: clangd (part of LLVM)
  ```bash
  # macOS:
  brew install llvm
  # Ubuntu/Debian:
  sudo apt install clangd
  # Fedora/RHEL:
  sudo dnf install clang-tools-extra
  ```
- **Extensions**: `.c`, `.cpp`, `.h`, `.hpp`, `.cc`, `.cxx`

---

## Ruby

- **LSP**: Solargraph
  ```bash
  gem install solargraph
  ```
- **Alternative**: ruby-lsp (Shopify, more actively maintained)
  ```bash
  gem install ruby-lsp
  ```
- **Extensions**: `.rb`, `.rake`

---

## PHP

- **LSP**: Intelephense
  ```bash
  npm install -g intelephense
  ```
- **Extensions**: `.php`

---

## Swift

- **LSP**: SourceKit-LSP (bundled with Xcode — macOS only)
  ```bash
  # Install Xcode from the App Store, then:
  xcrun sourcekit-lsp
  ```
- **Extensions**: `.swift`

---

## Elixir

- **LSP**: ElixirLS
  ```bash
  # Download latest release from:
  # https://github.com/elixir-lsp/elixir-ls/releases
  # Extract and point your config at the language_server.sh script
  ```
- **Alternative via mix**: `mix elixir_ls.release`
- **Extensions**: `.ex`, `.exs`

---

## Haskell

- **LSP**: HLS (Haskell Language Server) — install via GHCup
  ```bash
  # Install GHCup first: https://www.haskell.org/ghcup/
  ghcup install hls
  ```
- **Extensions**: `.hs`, `.lhs`

---

## Lua

- **LSP**: lua-language-server
  ```bash
  # macOS:
  brew install lua-language-server
  # or download from: https://github.com/LuaLS/lua-language-server/releases
  ```
- **Extensions**: `.lua`

---

## Zig

- **LSP**: ZLS (Zig Language Server)
  ```bash
  # macOS:
  brew install zls
  # or download from: https://github.com/zigtools/zls/releases
  # Match ZLS version to your Zig version
  ```
- **Extensions**: `.zig`

---

## Language not listed above?

Use WebSearch with: `"[language name] language server LSP install 2025"`

Good general resources:
- https://langserver.org — community-maintained list of language servers
- https://microsoft.github.io/language-server-protocol/implementors/servers/

Always note in the audit report that the recommendation came from a web search so the engineer can verify it.
