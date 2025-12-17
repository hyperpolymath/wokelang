# WokeLang Roadmap

> A human-centered, consent-driven programming language

## Vision

WokeLang aims to be a programming language that prioritizes:
- **Human readability** over machine optimization
- **Explicit consent** for sensitive operations
- **Gratitude and attribution** as first-class concepts
- **Emotional context** through emote annotations
- **Safety by default** with gentle error handling

---

## Phase 1: Foundation (Current) ✅

### Core Language
- [x] EBNF grammar specification
- [x] Lexer with logos
- [x] Recursive descent parser
- [x] Complete AST types
- [x] Tree-walking interpreter

### Basic Features
- [x] Functions with `to`/`give back`
- [x] Variables with `remember`
- [x] Conditionals with `when`/`otherwise`
- [x] Loops with `repeat...times`
- [x] Basic types: Int, Float, String, Bool, Array

### Tooling
- [x] CLI (`woke` command)
- [x] Interactive REPL
- [x] WASM compilation
- [x] C/Zig FFI

---

## Phase 2: Language Completeness (Q1 2026)

### Type System
- [ ] Static type inference
- [ ] Generic types (`to map[T, U](list: [T], f: T -> U) -> [U]`)
- [ ] Union types (`String | Int`)
- [ ] Structural typing for records
- [ ] Unit types with compile-time checking

### Pattern Matching
- [ ] Destructuring in `decide based on`
- [ ] Guard clauses
- [ ] Exhaustiveness checking
- [ ] Nested patterns

### Module System
- [ ] Package management (`woke.toml`)
- [ ] Import/export with `use`/`share`
- [ ] Namespaces
- [ ] Circular dependency detection

### Error Handling
- [ ] Result types (`Okay[T] | Oops[E]`)
- [ ] Error propagation operator (`?`)
- [ ] Stack traces with source locations
- [ ] Custom error types

---

## Phase 3: Concurrency & Safety (Q2 2026)

### Worker System
- [ ] True async workers
- [ ] Message passing between workers
- [ ] Worker pools
- [ ] Cancellation tokens

### Side Quests
- [ ] Background task scheduling
- [ ] Progress reporting
- [ ] Resource cleanup

### Superpowers
- [ ] Capability-based security
- [ ] Permission inheritance
- [ ] Audit logging
- [ ] Sandboxing

### Consent System
- [ ] Persistent consent storage
- [ ] Scoped permissions
- [ ] Consent revocation
- [ ] Consent UI integration

---

## Phase 4: Standard Library (Q3 2026)

### Core Modules
- [ ] `std.io` - File I/O with consent
- [ ] `std.net` - Networking with consent
- [ ] `std.json` - JSON parsing/generation
- [ ] `std.time` - Date/time handling
- [ ] `std.math` - Mathematical functions
- [ ] `std.text` - String manipulation
- [ ] `std.collections` - Data structures

### Consent-Aware Modules
- [ ] `std.fs` - Filesystem with permission checks
- [ ] `std.http` - HTTP client with URL consent
- [ ] `std.crypto` - Cryptography primitives
- [ ] `std.env` - Environment variables

### Unit System
- [ ] `std.units.si` - SI units
- [ ] `std.units.imperial` - Imperial units
- [ ] `std.units.currency` - Currency types
- [ ] Automatic unit conversion
- [ ] Dimensional analysis

---

## Phase 5: Compiler & Performance (Q4 2026)

### WASM Target
- [ ] Full WASM feature support
- [ ] WASI integration
- [ ] Memory management
- [ ] String handling in WASM
- [ ] Array operations
- [ ] Exception handling

### Native Compilation
- [ ] LLVM backend
- [ ] Native binaries
- [ ] Cross-compilation
- [ ] Link-time optimization

### Optimizations
- [ ] Constant folding
- [ ] Dead code elimination
- [ ] Inlining
- [ ] Tail call optimization
- [ ] Loop unrolling

---

## Phase 6: Tooling & Ecosystem (2027)

### IDE Support
- [ ] VS Code extension
  - Syntax highlighting
  - Error diagnostics
  - Auto-completion
  - Go to definition
  - Rename refactoring
- [ ] Language Server Protocol (LSP)
- [ ] Tree-sitter grammar
- [ ] Vim/Neovim plugin
- [ ] JetBrains plugin

### Package Manager
- [ ] `woke pkg` command
- [ ] Central package registry
- [ ] Version resolution
- [ ] Lock files
- [ ] Security auditing

### Testing
- [ ] Built-in test framework
- [ ] Property-based testing
- [ ] Mocking support
- [ ] Coverage reporting
- [ ] Benchmark suite

### Documentation
- [ ] `woke doc` generator
- [ ] Inline documentation
- [ ] Example extraction
- [ ] API reference generation

---

## Phase 7: Frameworks (2027+)

### Web Framework (WokeWeb)
- [ ] HTTP server
- [ ] Routing with consent
- [ ] Middleware system
- [ ] Template engine
- [ ] WebSocket support
- [ ] Static file serving

### CLI Framework (WokeCLI)
- [ ] Argument parsing
- [ ] Interactive prompts
- [ ] Progress bars
- [ ] Color output
- [ ] Configuration files

### GUI Framework (WokeUI)
- [ ] Cross-platform windowing
- [ ] Declarative UI
- [ ] Event handling
- [ ] Theming
- [ ] Accessibility

### Data Framework (WokeData)
- [ ] Database abstraction
- [ ] Query builder
- [ ] Migrations
- [ ] Connection pooling
- [ ] Consent-aware queries

---

## Technical Milestones

### Lexer Enhancements
| Feature | Status | Version |
|---------|--------|---------|
| Unicode identifiers | Planned | 0.3.0 |
| Heredoc strings | Planned | 0.3.0 |
| Raw strings | Planned | 0.3.0 |
| String interpolation | Planned | 0.4.0 |
| Custom operators | Planned | 0.5.0 |

### Parser Enhancements
| Feature | Status | Version |
|---------|--------|---------|
| Error recovery | Planned | 0.3.0 |
| Incremental parsing | Planned | 0.5.0 |
| Macro expansion | Planned | 0.6.0 |
| Custom syntax | Planned | 1.0.0 |

### Compiler Targets
| Target | Status | Version |
|--------|--------|---------|
| Tree-walking interpreter | ✅ Done | 0.1.0 |
| WASM (basic) | ✅ Done | 0.1.0 |
| WASM (full) | Planned | 0.4.0 |
| LLVM IR | Planned | 0.6.0 |
| Native (x86_64) | Planned | 0.7.0 |
| Native (ARM64) | Planned | 0.8.0 |

### REPL Features
| Feature | Status | Version |
|---------|--------|---------|
| Basic evaluation | ✅ Done | 0.1.0 |
| History | ✅ Done | 0.1.0 |
| Multi-line input | Planned | 0.2.0 |
| Tab completion | Planned | 0.3.0 |
| Syntax highlighting | Planned | 0.4.0 |
| Debugger integration | Planned | 0.6.0 |

---

## Version Timeline

```
2024 Q4  v0.1.0  Foundation release (completed)
2026 Q1  v0.2.0  Type system, modules
2026 Q2  v0.3.0  Concurrency, safety
2026 Q3  v0.4.0  Standard library
2026 Q4  v0.5.0  Optimizing compiler
2027 Q1  v0.6.0  IDE support, LSP
2027 Q2  v0.7.0  Package manager
2027 Q3  v0.8.0  Web framework
2027 Q4  v1.0.0  Stable release
```

---

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for how to get involved.

### Priority Areas
1. Standard library implementations
2. Documentation and examples
3. IDE tooling
4. Performance optimization
5. Security auditing

---

## Links

- [Language Specification](spec/language.md)
- [Wiki Home](wiki/Home.md)
- [API Reference](api/README.md)
- [Tutorials](tutorials/README.md)
