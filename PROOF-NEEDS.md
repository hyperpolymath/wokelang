<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# PROOF-NEEDS.md
## Current State

- **LOC**: ~27,300
- **Languages**: OCaml, Rust, ReScript, Lean4, Idris2, Zig
- **Existing ABI proofs**: `src/abi/*.idr` (template-level)
- **Existing verification**: `docs/proofs/verification/WokeLang.lean` — Lean4 proofs exist, 12 `sorry` occurrences previously eliminated
- **Dangerous patterns**: None remaining (Lean4 file mentions sorry elimination is complete)

## What Needs Proving

### Lean4 Proof Completeness Audit
- `WokeLang.lean` claims all 12 `sorry` eliminated — verify this is still true after any subsequent changes
- Audit: do the Lean4 proofs cover the full type system or only a subset?

### OCaml Core (core/)
- `ast.ml`, `eval.ml`, `main.ml` — the runtime evaluator
- If Lean4 proofs cover the type system but not evaluation, there is a gap
- Prove: evaluation semantics match the Lean4 specification

### WASM Backend (compiler/wokelang-wasm/src/lib.rs)
- Compilation to WASM should preserve the properties proven in Lean4
- Prove: WASM codegen produces programs with the same observable behaviour

### Fuzz Coverage
- `fuzz/fuzz_lexer.ml`, `fuzz/fuzz_parser.ml`, `fuzz/fuzz_targets/fuzz_input.rs`
- Fuzzing is a good complement but does not replace proofs for the core semantics

## Recommended Prover

- **Lean4** (already in use — extend to cover evaluation and compilation)
- **Idris2** for ABI layer

## Priority

**MEDIUM** — Good existing proof coverage in Lean4. Focus on extending proofs to evaluation and WASM compilation rather than starting from scratch. The sorry-free status needs periodic re-verification.
