<!--
SPDX-License-Identifier: MPL-2.0
SPDX-FileCopyrightText: 2026 Hyperpolymath
-->
# WokeLang Lean4 Proof Audit

This document records a completeness/correspondence audit of
`WokeLang.lean`, answering the two questions raised in
[`PROOF-NEEDS.md`](../../../PROOF-NEEDS.md): *is the sorry-free claim still
true?* and *do the proofs cover the full type system or only a subset?*

## Toolchain

- **Prover:** Lean 4, pinned to **v4.30.0** (`lean-toolchain` in this
  directory).
- **Build / check:** the proof file has **no external dependencies**
  (no Mathlib — only the Lean core prelude), so it is checked directly:

  ```sh
  lean docs/proofs/verification/WokeLang.lean   # exit 0, no output ⇒ verified
  ```

- **CI:** `.github/workflows/lean-proofs.yml` installs the pinned toolchain
  and runs the check on every push. See the headline finding below for why
  this gate was added.

## Headline finding — the proofs had bit-rotted (now fixed)

The file's doc-comment claimed *"all 12 `sorry` eliminated … verified"*. That
claim was **true against an older Lean but had silently broken**: under Lean
4.30.0 the file did **not** compile (~100 errors). Two root causes:

1. **`deriving DecidableEq` no longer applies** to `Value` and `WokeType`.
   `Value` contains `Float` (no `DecidableEq` in Lean 4 — NaN), and both types
   nest `List Self`, which the `DecidableEq` deriving handler does not see
   through. Fixed by deriving only `Repr`; equality decisions that the proofs
   need (`by_cases v₁ = v₂`) work via Lean's classical fallback with no
   instance required.
2. **`induction h` on `HasType emptyTypeEnv …`** fails because `emptyTypeEnv`
   is a *concrete* (non-variable) index. Fixed by generalising the index
   (`generalize hΓ : emptyTypeEnv = Γ at h`) and threading the equation
   through the induction hypotheses.

The decisive lesson: **no CI ever ran the prover** (workflows only covered the
OCaml core and e2e), so the headline correctness claim was never enforced.
The repair restores `sorry`-free compilation *and* adds the missing CI gate.

> The numeric "12 `sorry`" figure in the file header is historical; the
> verified invariant going forward is simply *the CI `lean` check is green*.

## Coverage — Lean model vs. the real language

The Lean model formalises a **clean expression core** and is a **strict
subset** of the surface language defined in `core/ast.ml` and implemented by
the Rust type checker (`src/typechecker/mod.rs`).

| Area | Lean `WokeLang.lean` | Surface language (`core/ast.ml`, `src/typechecker`) |
|---|---|---|
| Literals | int, float, string, bool, unit | + arrays, measured, `thanks` |
| Arithmetic | `add` only (int/float/string) | `add sub mul div mod` (+ div/mod-by-zero), **mixed int/float promotion** |
| Comparison | `eq` (same-type), no ordering | `eq ne lt gt le ge`, structural `eq` across **any** types |
| Logical | `and` (both `bool`) | `and or` with **`to_bool` coercion** of any value |
| Result type | `okay`/`oops`/`unwrap`/`error`, `tOkay…tUnwrap` | present in **Rust** typechecker (`Result(_, _)`); **absent** from `core/eval.ml` |
| Unary | `neg` (int/float), `not` | + measured propagation |
| Calls / arrays | `call`, `array` exprs (no typing rules) | builtins + user functions; arrays typed |
| Statements | declared (`Stmt`), **no typing/exec** | full eval in `core/eval.ml` |
| Units of measure | **not modelled** | `EMeasured` / `VMeasured`, unit-match checking |
| Pattern matching, workers, custom types | **not modelled** | present |
| Consent | `consent_monotonicity/preservation` | matches **spec** `axiomatic-semantics.md` (consent Hoare logic) |
| Capabilities | data + `capSubsumes`/`hasCapability` (no theorems) | — |

### What *is* proven (and now machine-checked)
`canonical_forms_{int,float,string,bool,result}`, **`progress`**,
**`preservation`**, **`type_safety`** (multi-step), and
`consent_{monotonicity,preservation}` — for the expression core above,
including the Result/`unwrap`/`error` panic-propagation fragment.

## Correspondence map (re PROOF-NEEDS #2)

PROOF-NEEDS #2 ("prove evaluation semantics match the Lean spec") rests on a
**mismatch that must be acknowledged**: the three artefacts model *different*
languages.

- **Lean type system / Result / progress+preservation** ⟷ the **Rust**
  `src/typechecker` (Hindley–Milner unification with `Result`, function
  types). This is the right correspondence target for the type-safety story.
- **Lean `consent_*`** ⟷ the **spec** `spec/axiomatic-semantics.md` (consent
  Hoare triples). In correspondence. ✓
- **`core/eval.ml`** is a *separate, older tree-walking interpreter*: it has
  **no Result type**, but adds units-of-measure, `to_bool` coercions, mixed
  int/float arithmetic, and structural cross-type `eq`. It is **not** the
  language the Lean `Step` relation models.

Consequently, "eval matches the Lean spec" is **not** currently a
well-posed single theorem — the evaluator and the spec diverge. The honest
options are (a) treat `WokeLang.lean` as the **normative spec** and converge
the implementations toward it, or (b) build a *second* Lean model faithful to
`core/eval.ml` (units + coercions + no Result) and prove properties there.

## Recommended next proof steps

1. **Broaden the verified core toward the Rust type system** (each is a small,
   pattern-following extension to `Step`/`HasType` + the `progress`/
   `preservation` cases, fully checkable):
   - integer `sub`/`mul` (total), then `div`/`mod` with a divide-by-zero
     `error` step (mirrors `unwrap`-of-`oops` panic propagation already
     proven);
   - ordering comparisons `lt/gt/le/ge` ⇒ `bool`;
   - `or` (mirror of `and`).
2. **Array typing** (`tArray`, an `array` congruence/▸ value rule) to retire
   one of the `array`-shaped TODO gaps.
3. **Decide the eval-correspondence question** (a) vs (b) above with the
   maintainer before attempting PROOF-NEEDS #2.
4. **Compiler/VM track** (the file's §8 TODO stubs: bytecode, compiler,
   VM semantics, compiler-correctness) remains open and is a larger effort.

## Status

- Repair to `sorry`-free under Lean 4.30.0: see CI / `lean` check.
- Coverage: **subset** of the surface language, as tabulated above — *not* a
  full-language proof, and honestly so.
