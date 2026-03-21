# WokeLang OCaml Core Setup

This document describes the minimal OCaml-only setup path for building and
running WokeLang core. No Rust, WASM, or Vyper dependencies are required.

## Prerequisites

- OCaml 5.0+ (install via opam)
- dune 3.0+ (install via opam)
- menhir (install via opam)

### Quick Install (Linux/macOS)

```bash
# Install opam if not present
bash -c "sh <(curl -fsSL https://opam.ocaml.org/install.sh)"

# Initialize opam
opam init
eval $(opam env)

# Install OCaml 5.0+ and tools
opam switch create 5.1.0
eval $(opam env)
opam install dune menhir
```

### Guix Install

```bash
guix install ocaml ocaml-dune ocaml-menhir
```

### Nix Install

```bash
nix-shell -p ocaml dune_3 ocamlPackages.menhir
```

## Building

From the repository root:

```bash
# Build the core interpreter
dune build

# Install locally
dune install --prefix=.local
```

## Running

### Run a WokeLang file

```bash
dune exec -- wokelang examples/hello_world.wl
```

### Run tests

```bash
dune test
```

### Smoke test (golden path)

```bash
dune test && dune exec -- wokelang examples/hello_world.wl
```

## Project Structure (Core)

```
wokelang/
├── core/                 # OCaml core implementation
│   ├── dune              # Build configuration
│   ├── ast.ml            # Abstract Syntax Tree
│   ├── lexer.mll         # Lexer (ocamllex)
│   ├── parser.mly        # Parser (menhir)
│   ├── eval.ml           # Tree-walking interpreter
│   └── main.ml           # CLI entry point
├── test/                 # Test suite
│   ├── dune              # Test configuration
│   └── test_wokelang.ml  # Core tests
├── examples/             # Example programs
│   └── hello_world.wl    # Golden path example
├── dune-project          # Dune project configuration
└── docs/
    └── core/
        └── SETUP.md      # This file
```

## Success Criteria

The core is considered working when:

1. `dune build` completes without errors
2. `dune test` passes all tests
3. `dune exec -- wokelang examples/hello_world.wl` runs successfully
4. Invalid programs produce deterministic error messages

## Optional Components (Quarantined)

The following components are NOT required for core functionality:

- **Rust implementation** (`src/`, `Cargo.toml`) - Alternative implementation
- **WASM build** - Browser/Node.js target
- **Vyper FFI** - Blockchain integration

These remain in the repository but are not part of the core build path.

## Troubleshooting

### "menhir not found"

```bash
opam install menhir
eval $(opam env)
```

### "OCaml version too old"

```bash
opam switch create 5.1.0
eval $(opam env)
```

### "dune not found"

```bash
opam install dune
eval $(opam env)
```

## Next Steps

After setting up the core:

1. Try the examples in `examples/`
2. Read the language specification in `grammar/wokelang.ebnf`
3. Explore the formal semantics in `docs/proofs/`
