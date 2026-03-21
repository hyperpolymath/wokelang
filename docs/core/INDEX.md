# WokeLang Documentation Index

This index separates **core** documentation (required for the OCaml implementation)
from **optional** documentation (for quarantined/experimental features).

## Core Documentation

Essential documentation for the OCaml-based WokeLang implementation:

| Document | Description |
|----------|-------------|
| [SETUP.md](SETUP.md) | OCaml-only setup instructions |
| [../grammar.ebnf](../grammar.ebnf) | Complete EBNF grammar specification |
| [SPEC.core.scm](SPEC.core.scm) | Core language semantics (consent + units) |

### Core Language Features

- **Consent gates** (`only if okay`) - Explicit permission for sensitive operations
- **Units of measure** (`measured in`) - Type-safe physical quantities
- **Gratitude blocks** (`thanks to`) - Attribution in code
- **Natural control flow** (`when`/`otherwise`, `repeat times`)
- **Safe error handling** (`attempt safely`/`or reassure`)
- **Emote annotations** (`@enthusiastic`) - Emotional context

## Optional Documentation

Documentation for quarantined/experimental features:

| Document | Description | Status |
|----------|-------------|--------|
| WASM build | Browser/Node.js compilation | Quarantined |
| Rust implementation | Alternative implementation | Quarantined |
| Vyper FFI | Blockchain integration | Quarantined |

## Conformance Corpus

Test cases focusing on core semantics:

### Consent Semantics

- `test/consent_grant.wl` - Consent is requested and granted
- `test/consent_deny.wl` - Consent is denied
- `test/consent_scope.wl` - Consent scoping rules

### Units Semantics

- `test/units_basic.wl` - Basic unit operations
- `test/units_mismatch.wl` - Unit mismatch errors (deterministic)
- `test/units_conversion.wl` - Unit conversion (future)

### Error Diagnostics

- All error messages must be deterministic
- Line/column information must be accurate
- Error messages should be helpful and human-centered

## Implementation Reference

The authoritative reference implementation is:

```
core/
├── ast.ml       # AST definitions
├── lexer.mll    # Lexer
├── parser.mly   # Parser
├── eval.ml      # Evaluator
└── main.ml      # CLI
```

This OCaml implementation is the source of truth for language semantics.
