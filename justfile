# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 Hyperpolymath

# WokeLang Justfile
# All local operations must go through `just <recipe>`
# See AUTHORITY_STACK.mustfile-nickel.scm for operational contract

set shell := ["bash", "-euo", "pipefail", "-c"]

# Default recipe: show available recipes
default:
    @just --list

# =============================================================================
# Core OCaml Recipes
# =============================================================================

# Build the OCaml core interpreter
build:
    dune build

# Run the OCaml test suite
test:
    dune test

# Run the golden path demo (hello_world.wl)
demo:
    dune exec -- wokelang examples/hello_world.wl

# Run the full smoke test (build + test + demo)
smoke:
    dune test && dune exec -- wokelang examples/hello_world.wl

# Run conformance corpus
conformance:
    #!/usr/bin/env bash
    set -euo pipefail
    for f in test/conformance/*.wl; do
        echo "=== Testing: $f ==="
        dune exec -- wokelang "$f"
        echo ""
    done
    echo "All conformance tests passed."

# Clean build artifacts
clean:
    dune clean

# =============================================================================
# Development Recipes
# =============================================================================

# Format OCaml code (requires ocamlformat)
fmt:
    dune fmt

# Run REPL (once implemented)
repl:
    @echo "REPL not yet implemented in OCaml core"
    @exit 1

# =============================================================================
# Setup Recipes
# =============================================================================

# Install OCaml dependencies via opam
setup-ocaml:
    opam install . --deps-only --with-test

# Check if OCaml toolchain is available
check-toolchain:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Checking OCaml toolchain..."
    command -v ocaml >/dev/null 2>&1 || { echo "ocaml not found"; exit 1; }
    command -v dune >/dev/null 2>&1 || { echo "dune not found"; exit 1; }
    command -v menhir >/dev/null 2>&1 || { echo "menhir not found"; exit 1; }
    echo "OCaml version: $(ocaml -version)"
    echo "Dune version: $(dune --version)"
    echo "Toolchain OK."

# =============================================================================
# Quarantined Recipes (Rust implementation - optional)
# =============================================================================

# Build Rust implementation (quarantined)
[private]
rust-build:
    cargo build --release

# Run Rust tests (quarantined)
[private]
rust-test:
    cargo test

# =============================================================================
# CI Recipes
# =============================================================================

# Full CI pipeline
ci: build test conformance
    @echo "CI pipeline complete."
