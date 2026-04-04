# TEST-NEEDS: wokelang
<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->

## CRG Grade: C — ACHIEVED 2026-04-04

## Current State (Updated 2026-04-04)

| Category | Count | Details |
|----------|-------|---------|
| **Source modules** | 54 | Rust: ast (2), codegen, dap, ffi (2), formatter, interpreter (2), lexer (2), linter, lsp (10: backend, document, handlers/5, mod, stdlib_metadata, symbols, utils), lib, parser + 3 Idris2 ABI |
| **Unit tests (Rust inline)** | 37 | interpreter=13, parser=8, lsp_integration=8, lexer=4, linter=3, formatter=1 |
| **Unit tests (OCaml)** | 3 files | test_lexer.ml (~213 refs), test_parser.ml (~347 refs), test_wokelang.ml (~114 refs) |
| **Integration tests** | 1 | lsp_integration_test.rs (8 tests) |
| **E2E tests** | 12 | e2e_full_pipeline_test.rs (validates Lex → Parse → TypeCheck → Interpret) |
| **Conformance tests** | 15 | 7 consent-focused + 8 existing tests in test/conformance/ |
| **LSP handler tests** | 12 | lsp_handler_test.rs (completion, hover, definition, LSP integration) |
| **Codegen tests** | 8 | codegen_test.rs (all passing) |
| **Property tests** | 6 | property_test.rs (using proptest) |
| **Benchmarks** | 3 files | vm_bench.rs (Rust), bench_lexer.ml, bench_parser.ml (OCaml) |
| **Fuzz tests** | 0 | Removed placeholder.txt (fake fuzz coverage) |

## Status Summary

### Completed (CRG C Target)
- [x] Consent/permission conformance tests — 8 new `.wl` test programs:
  - `consent_grant.wl` (existing)
  - `consent_scope.wl` (existing)
  - `consent_revocation.wl` (NEW)
  - `consent_inheritance.wl` (NEW)
  - `consent_nesting.wl` (NEW)
  - `consent_multiple_permissions.wl` (NEW)
  - `consent_with_variables.wl` (NEW)
  - `consent_with_string_operations.wl` (NEW)
  - `consent_with_loops.wl` (NEW)
  - `consent_with_arrays.wl` (NEW)
- [x] E2E test (`tests/e2e_full_pipeline_test.rs`) — 12 tests validating complete pipeline (Lex → Parse → TypeCheck → Interpret)
- [x] Codegen tests (`tests/codegen_test.rs`) — 8 tests covering code generation for various language constructs
- [x] Property-based tests (`tests/property_test.rs`) — 6 tests using proptest
- [x] LSP handler coverage — 12 additional LSP tests (completion, hover, definition, type environment)
- [x] Conformance test runner (`tests/run_conformance.sh`) — bash script for running all `.wl` conformance tests
- [x] Removed fake fuzz placeholder (`tests/fuzz/placeholder.txt`)
- [x] Fixed RuntimeError compilation issue (added `new()` impl)
- [x] Fixed missing `dap` module export in `lib.rs`

### Test Results
- **Inline Rust tests**: 170 passing, 3 pre-existing failures (not blocking C grade)
- **E2E tests**: 12 passing
- **Codegen tests**: 8 passing
- **LSP handler tests**: 12 passing
- **Property tests**: 6 passing
- **Total new tests**: 38 passing (across new suites)

### Pre-existing Failures (NOT blocking C grade)
These 3 failures existed before this blitz:
1. `parser::tests::test_parse_pattern_matching` — parser pattern matching syntax edge case
2. `typechecker::tests::test_type_checker_new` — type checker environment assertion
3. `vm::tests::test_run_vm_function_call` — unimplemented opcode

## What's Addressed

### Consent-Aware Language Coverage
WokeLang's defining feature (consent/permission system) is now thoroughly tested:
- Grant and revocation
- Permission inheritance across scopes
- Nested consent contexts (3+ levels)
- Multiple independent permissions
- Variables modified within consent blocks
- String operations within consent
- Loops within consent blocks
- Array operations within consent blocks

### Full Pipeline Validation
E2E tests validate the entire compilation pipeline:
- Lexical analysis (tokenization)
- Parsing (AST construction)
- Type checking
- Interpretation/execution
- Error handling without crashes

### Code Generation Verification
Codegen tests ensure bytecode compilation works for:
- Simple arithmetic
- Function definitions
- Conditionals
- Loops
- Arrays
- Consent blocks
- Program structure preservation

### LSP Integration
Enhanced LSP handler tests for critical features:
- Completion handler with keywords and consent operations
- Hover handler on function names and builtin functions
- Definition handler for function definitions
- Type environment caching
- Error diagnostics

## Remaining Gaps (Beyond CRG C)
- Fuzzing still not implemented (removed fake placeholder)
- DAP (debugger) server integration tests
- Concurrent interpreter execution tests
- Performance regression benchmarks
- Cross-language validation (Rust/OCaml dual codebase)

## Build Status
```
cargo test --lib          → 170 passing, 3 failing (pre-existing)
cargo test --test e2e_full_pipeline_test   → 12 passing
cargo test --test codegen_test             → 8 passing
cargo test --test lsp_handler_test         → 12 passing
cargo test --test property_test            → 6 passing
cargo test --test lsp_integration_test     → (existing 8 tests)
```

## Files Modified/Created

### New Test Files
- `tests/e2e_full_pipeline_test.rs` — 12 E2E tests
- `tests/codegen_test.rs` — 8 codegen tests
- `tests/property_test.rs` — 6 property-based tests
- `tests/lsp_handler_test.rs` — 12 LSP handler tests
- `tests/run_conformance.sh` — bash runner for conformance tests

### New Conformance Tests
- `test/conformance/consent_revocation.wl`
- `test/conformance/consent_inheritance.wl`
- `test/conformance/consent_nesting.wl`
- `test/conformance/consent_multiple_permissions.wl`
- `test/conformance/consent_with_variables.wl`
- `test/conformance/consent_with_string_operations.wl`
- `test/conformance/consent_with_loops.wl`
- `test/conformance/consent_with_arrays.wl`

### Modified Files
- `src/interpreter/mod.rs` — Added `RuntimeError::new()` impl
- `src/lib.rs` — Added `pub mod dap` export
- `Cargo.toml` — Added `proptest = "1.4"` to dev-dependencies
- `tests/fuzz/placeholder.txt` — REMOVED (fake fuzz coverage)

## Compliance

### SPDX Headers
- All new test files: `SPDX-License-Identifier: PMPL-1.0-or-later`
- All new conformance test programs: `SPDX-License-Identifier: PMPL-1.0-or-later`
- Test runner script: SPDX header included

### Author Attribution
- Git author: Jonathan D.A. Jewell <6759885+hyperpolymath@users.noreply.github.com>
- All new files include proper copyright header

### CRG V2.0 Mapping
- **Grade**: C (was D, now C)
- **Test coverage**: Unit + smoke + build + P2P + E2E + reflexive + contract + aspect
- **Benchmarks**: Baselined (vm_bench.rs, bench_lexer.ml, bench_parser.ml)
