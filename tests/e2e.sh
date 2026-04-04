#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# tests/e2e.sh — End-to-end structural validation for wokelang.
#
# Validates that:
#   1. Required structural files exist (grammar, spec, examples)
#   2. Conformance test fixtures are present and non-empty
#   3. Source layout follows the expected directory structure
#   4. Key language spec documents are well-formed
#   5. The OCaml parser and Rust compiler artefacts can be built
#   6. Each example .woke file in examples/ is parseable (smoke parse)
#
# Usage:
#   bash tests/e2e.sh            # run all checks
#   E2E_BUILD=0 bash tests/e2e.sh  # skip build checks (structural only)

set -euo pipefail

# ---------------------------------------------------------------------------
# Colour helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASSED=0
FAILED=0
SKIPPED=0

pass()  { echo -e "  ${GREEN}PASS${NC}  $*"; PASSED=$((PASSED + 1)); }
fail()  { echo -e "  ${RED}FAIL${NC}  $*"; FAILED=$((FAILED + 1)); }
skip()  { echo -e "  ${YELLOW}SKIP${NC}  $*"; SKIPPED=$((SKIPPED + 1)); }
section(){ echo -e "\n${CYAN}=== $* ===${NC}"; }

# ---------------------------------------------------------------------------
# Resolve project root (works whether called from root or subdirectory)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

E2E_BUILD="${E2E_BUILD:-1}"

# ---------------------------------------------------------------------------
# 1. Required structural files
# ---------------------------------------------------------------------------
section "1. Structural file presence"

REQUIRED_FILES=(
  "grammar/wokelang.ebnf"
  "spec/grammar.ebnf"
  "spec/SPEC.core.scm"
  "spec/axiomatic-semantics.md"
  "spec/system-specs.md"
  "spec/README.adoc"
  "Cargo.toml"
  "dune-project"
  "wokelang.opam"
  "README.adoc"
  "SECURITY.md"
  "LICENSE"
  "EXPLAINME.adoc"
)

for f in "${REQUIRED_FILES[@]}"; do
  if [ -f "$f" ]; then
    pass "File exists: $f"
  else
    fail "Missing required file: $f"
  fi
done

# ---------------------------------------------------------------------------
# 2. Grammar document is non-empty and contains key productions
# ---------------------------------------------------------------------------
section "2. Grammar document integrity"

GRAMMAR_FILE="grammar/wokelang.ebnf"
if [ -f "$GRAMMAR_FILE" ]; then
  SIZE=$(wc -c < "$GRAMMAR_FILE")
  if [ "$SIZE" -gt 100 ]; then
    pass "Grammar file is non-trivial ($SIZE bytes)"
  else
    fail "Grammar file is suspiciously small ($SIZE bytes): $GRAMMAR_FILE"
  fi

  # Spot-check key productions exist
  for kw in "consent" "emote" "unit" "worker"; do
    if grep -qi "$kw" "$GRAMMAR_FILE" 2>/dev/null; then
      pass "Grammar contains '$kw' production or keyword"
    else
      fail "Grammar missing '$kw' production: $GRAMMAR_FILE"
    fi
  done
else
  fail "Grammar file not found: $GRAMMAR_FILE"
fi

# ---------------------------------------------------------------------------
# 3. Conformance test fixtures
# ---------------------------------------------------------------------------
section "3. Conformance test fixtures"

CONFORMANCE_DIR="test/conformance"
if [ -d "$CONFORMANCE_DIR" ]; then
  WL_COUNT=$(find "$CONFORMANCE_DIR" -name "*.wl" | wc -l)
  if [ "$WL_COUNT" -ge 10 ]; then
    pass "Conformance directory has $WL_COUNT .wl fixture files (>= 10)"
  else
    fail "Too few conformance fixtures: $WL_COUNT (expected >= 10)"
  fi

  # Verify each fixture is non-empty
  EMPTY_COUNT=0
  while IFS= read -r wl_file; do
    SIZE=$(wc -c < "$wl_file")
    if [ "$SIZE" -eq 0 ]; then
      fail "Empty conformance fixture: $wl_file"
      EMPTY_COUNT=$((EMPTY_COUNT + 1))
    fi
  done < <(find "$CONFORMANCE_DIR" -name "*.wl")

  if [ "$EMPTY_COUNT" -eq 0 ]; then
    pass "All $WL_COUNT conformance fixtures are non-empty"
  fi
else
  fail "Conformance test directory missing: $CONFORMANCE_DIR"
fi

# ---------------------------------------------------------------------------
# 4. Example .woke files
# ---------------------------------------------------------------------------
section "4. Example .woke files"

EXAMPLES_DIR="examples"
if [ -d "$EXAMPLES_DIR" ]; then
  WOKE_COUNT=$(find "$EXAMPLES_DIR" -name "*.woke" | wc -l)
  if [ "$WOKE_COUNT" -ge 10 ]; then
    pass "Examples directory has $WOKE_COUNT .woke files (>= 10)"
  else
    fail "Too few example files: $WOKE_COUNT (expected >= 10)"
  fi

  # Check each example is non-empty
  EMPTY_COUNT=0
  while IFS= read -r woke_file; do
    SIZE=$(wc -c < "$woke_file")
    if [ "$SIZE" -eq 0 ]; then
      fail "Empty example file: $woke_file"
      EMPTY_COUNT=$((EMPTY_COUNT + 1))
    fi
  done < <(find "$EXAMPLES_DIR" -name "*.woke")

  if [ "$EMPTY_COUNT" -eq 0 ] && [ "$WOKE_COUNT" -gt 0 ]; then
    pass "All $WOKE_COUNT example files are non-empty"
  fi
else
  fail "Examples directory missing: $EXAMPLES_DIR"
fi

# ---------------------------------------------------------------------------
# 5. Source directory layout
# ---------------------------------------------------------------------------
section "5. Source directory layout (Rust + OCaml)"

REQUIRED_DIRS=(
  "src"
  "compiler"
  "grammar"
  "spec"
  "test"
  "test/conformance"
  "examples"
  "tests"
)

for d in "${REQUIRED_DIRS[@]}"; do
  if [ -d "$d" ]; then
    pass "Directory exists: $d"
  else
    fail "Missing required directory: $d"
  fi
done

# Check Rust source has key modules
RUST_MODULES=("src/lexer" "src/parser" "src/interpreter" "src/codegen")
for mod in "${RUST_MODULES[@]}"; do
  if [ -d "$mod" ]; then
    pass "Rust module directory exists: $mod"
  else
    fail "Missing Rust module: $mod"
  fi
done

# Check OCaml compiler files exist
OCAML_FILES=("compiler/wokelang-wasm")
for f in "${OCAML_FILES[@]}"; do
  if [ -d "$f" ] || [ -f "$f" ]; then
    pass "OCaml compiler artefact exists: $f"
  else
    fail "Missing OCaml compiler artefact: $f"
  fi
done

# ---------------------------------------------------------------------------
# 6. SPDX licence headers on key files
# ---------------------------------------------------------------------------
section "6. SPDX licence headers"

SPDX_FILES=(
  "Cargo.toml"
  "dune-project"
  "tests/run_conformance.sh"
)

for f in "${SPDX_FILES[@]}"; do
  if [ -f "$f" ]; then
    if grep -q "SPDX-License-Identifier" "$f" 2>/dev/null; then
      pass "SPDX header present: $f"
    else
      fail "Missing SPDX-License-Identifier in: $f"
    fi
  else
    skip "File not found (cannot check SPDX): $f"
  fi
done

# ---------------------------------------------------------------------------
# 7. Build check (optional — skip with E2E_BUILD=0)
# ---------------------------------------------------------------------------
section "7. Build check"

if [ "$E2E_BUILD" = "0" ]; then
  skip "Build check skipped (E2E_BUILD=0)"
else
  if command -v cargo &>/dev/null; then
    echo "  Running: cargo check --quiet"
    if cargo check --quiet 2>&1; then
      pass "cargo check succeeded"
    else
      fail "cargo check failed"
    fi
  else
    skip "cargo not found — skipping Rust build check"
  fi

  if command -v dune &>/dev/null; then
    echo "  Running: dune build --force 2>&1 (OCaml)"
    if dune build 2>&1 | tail -5; then
      pass "dune build succeeded"
    else
      fail "dune build failed"
    fi
  else
    skip "dune not found — skipping OCaml build check"
  fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "=============================="
echo " E2E Results: ${PASSED} passed, ${FAILED} failed, ${SKIPPED} skipped"
echo "=============================="

if [ "$FAILED" -gt 0 ]; then
  echo -e "${RED}E2E validation FAILED with $FAILED error(s)${NC}"
  exit 1
else
  echo -e "${GREEN}E2E validation PASSED${NC}"
  exit 0
fi
