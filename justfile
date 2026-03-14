# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2026 Hyperpolymath

# WokeLang Justfile
# All local operations must go through `just <recipe>`
# See AUTHORITY_STACK.mustfile-nickel.scm for operational contract

set shell := ["bash", "-euo", "pipefail", "-c"]

# Default recipe: show available recipes
default:
    @just --list

# =============================================================================
# Core Rust Recipes (Primary Implementation)
# =============================================================================

# Build the Rust implementation
build:
    cargo build --release

# Run the Rust test suite
test:
    cargo test

# Run the golden path demo (hello_world.woke)
demo:
    cargo run --release -- run examples/01_hello.woke

# Run the full smoke test (build + test + demo)
smoke: test demo
    @echo "Smoke test passed: tests pass and demo runs"

# Run conformance corpus (all examples)
conformance:
    #!/usr/bin/env bash
    set -euo pipefail
    for f in examples/*.woke; do
        echo "=== Testing: $f ==="
        cargo run --release -- run "$f"
        echo ""
    done
    echo "All conformance tests passed."

# Clean build artifacts
clean:
    cargo clean

# =============================================================================
# Development Recipes
# =============================================================================

# Format Rust code
fmt:
    cargo fmt

# Check formatting without modifying
fmt-check:
    cargo fmt --check

# Start interactive REPL
repl:
    cargo run --release -- repl

# Parse a file (for debugging)
parse file:
    cargo run --release -- parse {{file}}

# Typecheck a file
typecheck file:
    cargo run --release -- typecheck {{file}}

# Run linter checks
lint:
    cargo clippy -- -D warnings

# Generate documentation
docs:
    cargo doc --no-deps --open

# Install dependencies (none needed - using Cargo)
deps:
    @echo "Dependencies managed by Cargo - run 'cargo build'

# Compile to bytecode
compile file output:
    cargo run --release -- compile {{file}} -o {{output}}

# Run bytecode VM
run-vm file:
    cargo run --release -- run-vm {{file}}

# =============================================================================
# Setup Recipes
# =============================================================================

# Install asdf tools (rust, deno, idris2, zig)
setup-asdf:
    #!/usr/bin/env bash
    set -euo pipefail
    asdf plugin add rust || true
    asdf plugin add deno || true
    asdf plugin add idris2 || true
    asdf plugin add zig || true
    asdf install

# Check if toolchain is available
check-toolchain:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Checking WokeLang toolchain..."
    command -v cargo >/dev/null 2>&1 || { echo "cargo not found - install Rust"; exit 1; }
    command -v deno >/dev/null 2>&1 || { echo "deno not found - run 'just setup-asdf'"; exit 1; }
    command -v idris2 >/dev/null 2>&1 || { echo "idris2 not found - run 'just setup-asdf'"; exit 1; }
    command -v zig >/dev/null 2>&1 || { echo "zig not found - run 'just setup-asdf'"; exit 1; }
    echo "Rust version: $(cargo --version)"
    echo "Deno version: $(deno --version | head -1)"
    echo "Idris2 version: $(idris2 --version)"
    echo "Zig version: $(zig version)"
    echo "Toolchain OK."

# =============================================================================
# Quarantined Recipes (OCaml prototype - optional)
# =============================================================================

# Build OCaml prototype (quarantined - experimental only)
[private]
ocaml-build:
    dune build

# Run OCaml tests (quarantined)
[private]
ocaml-test:
    dune test

# Format OCaml code
[private]
ocaml-fmt:
    dune fmt

# =============================================================================
# CI Recipes
# =============================================================================

# Full CI pipeline
ci: build test conformance
    @echo "CI pipeline complete."
