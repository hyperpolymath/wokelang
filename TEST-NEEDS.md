# TEST-NEEDS: wokelang
<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->

## Current State

| Category | Count | Details |
|----------|-------|---------|
| **Source modules** | 54 | Rust: ast (2), codegen, dap, ffi (2), formatter, interpreter (2), lexer (2), linter, lsp (10: backend, document, handlers/5, mod, stdlib_metadata, symbols, utils), lib, parser + 3 Idris2 ABI |
| **Unit tests (Rust inline)** | 37 | interpreter=13, parser=8, lsp_integration=8, lexer=4, linter=3, formatter=1 |
| **Unit tests (OCaml)** | 3 files | test_lexer.ml (~213 refs), test_parser.ml (~347 refs), test_wokelang.ml (~114 refs) |
| **Integration tests** | 1 | lsp_integration_test.rs (8 tests) |
| **E2E tests** | 0 | None |
| **Conformance tests** | 2 | consent_grant.wl, gratitude_basic.wl |
| **Benchmarks** | 3 files | vm_bench.rs (Rust), bench_lexer.ml, bench_parser.ml (OCaml) |
| **Fuzz tests** | 0 | None |

## What's Missing

### E2E Tests (CRITICAL)
- [ ] No test that compiles and runs a complete Wokelang program
- [ ] No test for the DAP server with a real debugger
- [ ] Only 2 conformance tests for the entire language spec

### Aspect Tests
- [ ] **Security**: Consent-aware language with only 1 consent_grant test -- needs 50+ consent/permission scenarios
- [ ] **Performance**: Benchmarks exist but need verification
- [ ] **Concurrency**: No tests for concurrent interpreter execution
- [ ] **Error handling**: No tests for runtime errors, stack overflow, infinite loops

### Build & Execution
- [ ] OCaml tests exist but does OCaml build infrastructure still work?
- [ ] No Idris2 ABI compilation test
- [ ] Dual Rust+OCaml codebase -- no cross-validation tests

### Benchmarks Status
- [x] vm_bench.rs (Rust) -- appears real
- [x] bench_lexer.ml (OCaml) -- appears real
- [x] bench_parser.ml (OCaml) -- appears real
- [ ] No codegen benchmark
- [ ] No interpreter throughput benchmark

### Self-Tests
- [ ] No `wokelang --self-test` mode
- [ ] No language conformance runner

## FLAGGED ISSUES
- **OCaml tests have good coverage** (test_lexer 213, test_parser 347, test_wokelang 114) but are they still maintained alongside Rust?
- **37 Rust inline tests for 54 modules** = 0.7 tests/module in Rust
- **LSP has 10 source files but only 8 integration tests** -- handler coverage thin
- **Consent-aware language with 1 consent test** -- the defining feature is barely tested
- **codegen, dap, ffi modules have 0 tests** -- code generation is untested
- **Benchmarks appear genuine** -- vm_bench.rs + OCaml bench files

## Priority: P1 (HIGH)

## FAKE-FUZZ ALERT

- `tests/fuzz/placeholder.txt` is a scorecard placeholder inherited from rsr-template-repo — it does NOT provide real fuzz testing
- Replace with an actual fuzz harness (see rsr-template-repo/tests/fuzz/README.adoc) or remove the file
- Priority: P2 — creates false impression of fuzz coverage
