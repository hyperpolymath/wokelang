// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

# Phronesis Toolchain Alignment Gap Analysis
**Date:** 2026-02-01
**Status:** WokeLang catching up to Phronesis toolchain maturity

## Executive Summary

**Phronesis:** 100% complete toolchain (production-ready)
**WokeLang:** 85% complete core language, toolchain needs development

This document tracks what WokeLang needs to implement to match Phronesis's toolchain maturity.

---

## Toolchain Comparison Matrix

| Component | Phronesis | WokeLang | Gap | Priority |
|-----------|-----------|----------|-----|----------|
| **Core Language** | ✅ Complete | ✅ Complete | None | N/A |
| **Parser & Lexer** | ✅ Complete | ✅ Complete | None | N/A |
| **Type System** | ✅ Complete | ✅ Complete (H-M) | None | N/A |
| **Interpreter** | ✅ Complete | ✅ Complete | None | N/A |
| **Bytecode VM** | ✅ Complete | ✅ Complete | None | N/A |
| **REPL** | ✅ Complete | ✅ Complete | None | N/A |
| **CLI** | ✅ Complete | ✅ Complete | None | N/A |
| **LSP Server** | ✅ Complete | ❌ Missing | **MAJOR** | **P1** |
| **Debugger** | ✅ Complete | ❌ Missing | **MAJOR** | **P1** |
| **Testing Framework** | ✅ Complete | ⚠️ Partial | **MAJOR** | **P1** |
| **Profiler** | ✅ Complete | ❌ Missing | **MAJOR** | **P2** |
| **Doc Generator** | ✅ Complete | ❌ Missing | **MAJOR** | **P2** |
| **Static Analyzer** | ✅ Complete | ⚠️ Partial | **MEDIUM** | P3 |
| **Syntax Highlighting** | ✅ Complete | ⚠️ Partial | **MEDIUM** | P3 |
| **Error Reporter** | ✅ Complete | ⚠️ Partial | **MEDIUM** | P3 |
| **Package Manager** | ✅ Complete | ❌ Missing | **MEDIUM** | P4 |
| **VSCode Extension** | ✅ Complete | ❌ Missing | **MEDIUM** | P4 |

---

## Detailed Gap Analysis

### 1. LSP Server ❌ → ✅
**Phronesis has:**
- Full JSON-RPC 2.0 implementation
- textDocument/completion (auto-complete)
- textDocument/hover (documentation)
- textDocument/definition (go-to-definition)
- textDocument/diagnostics (real-time errors)
- VSCode extension integration

**WokeLang needs:**
- Implement LSP server from scratch
- JSON-RPC message handling
- Document synchronization
- Symbol resolution
- Diagnostic reporting
- Language features (completion, hover, etc.)

**Implementation Path:**
```rust
// src/lsp/server.rs
pub struct LspServer {
    documents: HashMap<Url, Document>,
    symbols: SymbolTable,
}

impl LspServer {
    pub fn handle_completion(&self, params: CompletionParams) -> CompletionList { /* ... */ }
    pub fn handle_hover(&self, params: HoverParams) -> Option<Hover> { /* ... */ }
    pub fn handle_definition(&self, params: DefinitionParams) -> Vec<Location> { /* ... */ }
}
```

**Estimated Effort:** 2-3 weeks
**Dependencies:** None (can start immediately)

---

### 2. Debugger ❌ → ✅
**Phronesis has:**
- Interactive debugger REPL
- Breakpoint support
- Step execution (step, next, continue)
- State inspection
- Watch expressions
- Call stack viewing

**WokeLang needs:**
- Debugger infrastructure
- AST instrumentation for breakpoints
- Step-through interpreter mode
- Debug REPL
- Variable inspection commands

**Implementation Path:**
```rust
// src/debugger.rs
pub struct Debugger {
    breakpoints: Vec<SourceLocation>,
    watches: Vec<WatchExpression>,
    call_stack: Vec<Frame>,
    mode: DebugMode, // Running, Paused, Stepping
}

impl Debugger {
    pub fn add_breakpoint(&mut self, location: SourceLocation) { /* ... */ }
    pub fn step(&mut self) { /* ... */ }
    pub fn inspect(&self, var_name: &str) -> Option<Value> { /* ... */ }
}
```

**Estimated Effort:** 1-2 weeks
**Dependencies:** None

---

### 3. Testing Framework ⚠️ → ✅
**Phronesis has:**
- TEST/SCENARIO/GIVEN/EXPECT DSL
- Test runner (`phronesis test`)
- Test discovery
- Assertion framework
- Test reporting

**WokeLang has:**
- Examples that serve as tests
- Basic integration testing via examples

**WokeLang needs:**
- Formal test DSL or syntax
- Test runner infrastructure
- Assertion functions
- Test discovery
- Coverage reporting

**Implementation Path:**
```wokelang
# test/consent_test.woke
test "consent system blocks without permission" {
    #care on;

    remember result = only if okay "file.read" {
        readFile("test.txt")
    };

    expect result to be Oops("Permission denied");
}
```

```rust
// src/test_framework.rs
pub struct TestRunner {
    tests: Vec<TestCase>,
}

impl TestRunner {
    pub fn discover_tests(&mut self, path: &Path) { /* ... */ }
    pub fn run_all(&self) -> TestReport { /* ... */ }
}
```

**Estimated Effort:** 1 week
**Dependencies:** None

---

### 4. Profiler ❌ → ✅
**Phronesis has:**
- Performance profiling (`phronesis profile`)
- Timing measurements per function
- Memory allocation tracking
- HTML/CSV/Markdown reports
- Flame graph generation

**WokeLang needs:**
- Profiler infrastructure
- Instrumentation hooks
- Timing collection
- Report generation

**Implementation Path:**
```rust
// src/profiler.rs
pub struct Profiler {
    samples: Vec<Sample>,
    start_time: Instant,
}

impl Profiler {
    pub fn start_function(&mut self, name: &str) { /* ... */ }
    pub fn end_function(&mut self, name: &str) { /* ... */ }
    pub fn generate_report(&self, format: ReportFormat) -> String { /* ... */ }
}
```

**Estimated Effort:** 1 week
**Dependencies:** None

---

### 5. Documentation Generator ❌ → ✅
**Phronesis has:**
- Doc comment extraction
- HTML/Markdown export
- API reference generation
- Example code inclusion
- Cross-referencing

**WokeLang needs:**
- Doc comment parser
- Documentation AST
- Template system
- Multi-format export

**Implementation Path:**
```rust
// src/doc.rs
pub struct DocGenerator {
    docs: Vec<DocItem>,
}

impl DocGenerator {
    pub fn extract_docs(&mut self, ast: &AST) { /* ... */ }
    pub fn generate_html(&self) -> String { /* ... */ }
    pub fn generate_markdown(&self) -> String { /* ... */ }
}
```

**Estimated Effort:** 1 week
**Dependencies:** None

---

### 6. VSCode Extension ❌ → ✅
**Phronesis has:**
- Full VSCode extension
- Syntax highlighting
- LSP client integration
- Debugger integration
- Custom commands

**WokeLang needs:**
- VSCode extension scaffold
- TextMate grammar (syntax highlighting)
- LSP client configuration
- Extension marketplace publishing

**Implementation Path:**
```
editors/
└── vscode/
    ├── package.json
    ├── syntaxes/
    │   └── wokelang.tmLanguage.json
    ├── language-configuration.json
    └── extension.js
```

**Estimated Effort:** 3-4 days (after LSP is ready)
**Dependencies:** LSP server must be complete

---

### 7. Static Analyzer ⚠️ → ✅
**Phronesis has:**
- Dead code detection
- Unreachable code detection
- Security vulnerability scanning
- Code quality metrics
- Comprehensive checks

**WokeLang has:**
- Basic linter (`woke lint`)
- Some static checks

**WokeLang needs:**
- Advanced analysis passes
- Data flow analysis
- Control flow analysis
- Security checks specific to consent system
- Capability leak detection

**Implementation Path:**
```rust
// src/analyzer.rs
pub struct StaticAnalyzer {
    checks: Vec<AnalysisPass>,
}

impl StaticAnalyzer {
    pub fn analyze(&self, ast: &AST) -> Vec<Finding> { /* ... */ }
}

pub struct DeadCodePass;
impl AnalysisPass for DeadCodePass {
    fn run(&self, ast: &AST) -> Vec<Finding> { /* ... */ }
}
```

**Estimated Effort:** 1-2 weeks
**Dependencies:** None

---

### 8. Syntax Highlighting ⚠️ → ✅
**Phronesis has:**
- VSCode/VSCodium
- Vim/Neovim
- Emacs
- Sublime Text
- Kate/KWrite
- GitHub Linguist

**WokeLang has:**
- Partial GitHub detection (.gitattributes)

**WokeLang needs:**
- Complete TextMate grammar
- Vim syntax file
- Emacs major mode
- Sublime syntax
- Kate XML syntax
- GitHub Linguist registration

**Implementation Path:**
```
syntax/
├── wokelang.tmLanguage.json  # VSCode/Sublime/GitHub
├── wokelang.vim              # Vim/Neovim
├── wokelang-mode.el          # Emacs
└── wokelang.xml              # Kate
```

**Estimated Effort:** 2-3 days
**Dependencies:** None (can do immediately)

---

### 9. Error Reporter ⚠️ → ✅
**Phronesis has:**
- Colorized error messages
- Source context with line numbers
- Error suggestions ("did you mean...")
- Error codes (E0001, E0002, etc.)
- Related information
- Help text

**WokeLang has:**
- Basic error messages
- Miette integration (partial)

**WokeLang needs:**
- Comprehensive error catalog
- Suggestion engine
- Better formatting
- Error code system

**Implementation Path:**
```rust
// src/diagnostics.rs
pub struct Diagnostic {
    code: ErrorCode,
    message: String,
    location: SourceLocation,
    suggestions: Vec<Suggestion>,
    help: Option<String>,
}

impl Diagnostic {
    pub fn format_fancy(&self) -> String { /* ... */ }
}
```

**Estimated Effort:** 1 week
**Dependencies:** None

---

### 10. Package Manager ❌ → ✅
**Phronesis has:**
- `phronesis pkg` command
- Package registry client
- Dependency resolution
- Version management
- Package publishing

**WokeLang needs:**
- Package manifest format (wokelang.ncl)
- Dependency resolver
- Package registry client
- Version constraint solver
- Lock file format

**Implementation Path:**
```rust
// src/pkg/manager.rs
pub struct PackageManager {
    registry: RegistryClient,
    cache: PackageCache,
}

impl PackageManager {
    pub fn install(&self, name: &str, version: &str) -> Result<()> { /* ... */ }
    pub fn resolve_deps(&self, manifest: &Manifest) -> DependencyGraph { /* ... */ }
}
```

**Estimated Effort:** 2-3 weeks
**Dependencies:** None (but needs registry service eventually)

---

## Implementation Roadmap

### Phase 1: Quick Wins (1 week)
**Goal:** Close easy gaps
1. ✅ Create TOOLCHAIN-WISHLIST.md (complete)
2. ✅ Align justfile structure (complete)
3. Create syntax highlighting files
4. Enhanced error messages

### Phase 2: Testing & Quality (1-2 weeks)
**Goal:** Production readiness
1. Testing framework
2. Static analyzer enhancements
3. Comprehensive test suite
4. Error reporter improvements

### Phase 3: Developer Tools (6-8 weeks)
**Goal:** IDE experience
1. LSP server (3 weeks)
2. Debugger (2 weeks)
3. VSCode extension (1 week)
4. Profiler (1 week)
5. Doc generator (1 week)

### Phase 4: Ecosystem (2-3 weeks)
**Goal:** Package ecosystem
1. Package manager (2 weeks)
2. Package registry (when ready)

---

## Priority Recommendations

**P1 (Start Immediately):**
- Syntax highlighting (quick win, 2-3 days)
- Testing framework (essential, 1 week)

**P2 (Next Month):**
- LSP server (game changer, 2-3 weeks)
- Debugger (essential dev tool, 1-2 weeks)

**P3 (Next Quarter):**
- Profiler (performance, 1 week)
- Doc generator (onboarding, 1 week)
- Static analyzer (quality, 1-2 weeks)

**P4 (As Needed):**
- Package manager (ecosystem growth, 2-3 weeks)
- VSCode extension (after LSP, 3-4 days)

---

## Success Metrics

**Toolchain Parity Achieved When:**
- ✅ LSP server operational
- ✅ Debugger with breakpoints working
- ✅ Testing framework running test suites
- ✅ Profiler generating reports
- ✅ Docs auto-generated from code
- ✅ VSCode extension published
- ✅ Package manager functional

**Timeline to Parity:** 10-12 weeks (focused development)

---

## Resources Needed

**Development:**
- 1 full-time developer: 10-12 weeks
- OR 2 part-time developers: 5-6 weeks (parallelizable)

**Skills Required:**
- Rust programming
- LSP protocol knowledge
- Compiler/interpreter development
- VSCode extension API
- Package management systems

---

**Maintainer:** Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>
**Date:** 2026-02-01
**License:** PMPL-1.0-or-later
**Related:** TOOLCHAIN-WISHLIST.md, NEXT-STEPS.adoc
