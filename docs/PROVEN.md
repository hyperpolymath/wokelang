<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# Proven Integration

WokeLang uses [proven](https://github.com/hyperpolymath/proven) for formally verified operations where safety is critical.

## What is proven?

proven is an Idris2 library providing mathematically proven safe operations:
- **Cannot crash** - Dependent types prove correctness
- **Totality checking** - All code paths guaranteed to terminate
- **90+ modules** - Comprehensive formally verified functionality
- **89 language bindings** - FFI via Zig C ABI

## Architecture

```
WokeLang (Rust)
      ↓
Rust Bindings
      ↓
Zig FFI Bridge
      ↓
Idris2 proven Library ← MATHEMATICAL PROOFS
```

## Integration Points

### Current

WokeLang currently uses proven for:
- (To be determined based on safety-critical needs)

### Planned

Potential proven integration for:
- **File I/O** - Proven-safe file operations with capability checks
- **String operations** - Bounds-checked string manipulation
- **Collection operations** - Verified data structure operations
- **Parser combinators** - Provably correct parsing

## Using proven in WokeLang

### Setup

1. Ensure Idris2 is installed (see `.tool-versions`)
2. Clone proven:
   ```bash
   git clone https://github.com/hyperpolymath/proven
   cd proven
   make install
   ```

3. Link WokeLang to proven bindings:
   ```bash
   cd wokelang
   # Add proven-rust bindings to Cargo.toml
   ```

### Example

```rust
// Use proven-safe string operations
use proven_rust::string::SafeString;

let s = SafeString::new("Hello").unwrap();
let sub = s.substring(0, 5); // Mathematically proven not to panic
```

## Badge

When WokeLang uses proven modules, add the "Idris Inside" badge to README:

```adoc
image:https://img.shields.io/badge/Idris-Inside-blueviolet?style=flat[Idris Inside]
```

## Performance Note

proven adds FFI overhead for maximum safety. Use for:
- ✓ Safety-critical operations (file I/O, parsing user input)
- ✓ Security boundaries (capability checks, permission validation)
- ✗ Hot loops or performance-critical paths

## References

- proven repo: https://github.com/hyperpolymath/proven
- Idris2 docs: https://idris2.readthedocs.io
- Zig FFI: /var$REPOS_DIR/proven/ffi/zig/
