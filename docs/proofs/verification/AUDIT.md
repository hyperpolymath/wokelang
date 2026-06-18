<!--
SPDX-License-Identifier: MPL-2.0
SPDX-FileCopyrightText: 2026 Hyperpolymath
-->
# WokeLang Proof Audit (Lean 4 + Coq)

This document records a completeness/correspondence audit of the two formal
developments — `WokeLang.lean` (Lean 4) and `WokeLang.v` (Coq) — answering the
questions raised in [`PROOF-NEEDS.md`](../../../PROOF-NEEDS.md): *is the
verified/sorry-free claim still true?* and *do the proofs cover the full type
system or only a subset?* (The Lean sections come first; the Coq audit is its
own section below.)

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
| Calls / arrays | `call` (no typing rule); **arrays typed + evaluated** (`tArray`/`tArrayVal`, `sArrayStep`/`sArrayVal`/`sArrayErr`) | builtins + user functions; arrays typed |
| Statements | **typing judgment** (`StmtWellTyped`, context-threading) + monotonicity/append metatheorems; execution/preservation not yet | full eval in `core/eval.ml` |
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
2. ~~**Array typing** (`tArray`, an `array` congruence/▸ value rule)~~ —
   **DONE (2026-06-18).** `tArray`/`tArrayVal` + `sArrayStep`/`sArrayVal`/
   `sArrayErr`, with full `progress`/`preservation` coverage (see
   "Extensions landed" below). This brings Lean to parity with Coq on arrays.
3. ~~Statement typing~~ — **DONE (2026-06-18):** `StmtWellTyped`/
   `StmtsWellTyped` + monotonicity/append (see "Statement typing landed"
   below). **Next on statements: a dynamic story** — a statement execution
   relation + a store-typing *preservation* theorem. The prerequisite is
   generalising the expression `preservation`/`type_safety` to **open** terms
   (non-empty context + a store-typing agreement), since statement-embedded
   expressions reference declared variables (the current expression proofs
   assume the empty context, deriving a contradiction in the `var` case).
4. **Decide the eval-correspondence question** (a) vs (b) above with the
   maintainer before attempting PROOF-NEEDS #2.
5. **Compiler/VM track** (the file's §8 TODO stubs: bytecode, compiler,
   VM semantics, compiler-correctness) remains open and is a larger effort.

## Echo-types design compatibility (checked 2026-06-14)

Checked against echo-types `main` before extending WokeLang's type system, so
the extensions don't box out a future echo/loss layer. The precedent is
`EchoEphapaxBridge`: **Ephapax** (a linear-typed language) ports
`EchoLinear.agda` + `EchoResidue.agda` into its prover as an **L3 layer**
(`formal/Echo.v`, 584 lines Coq, zero axioms), preserving the headline
theorems (`weaken_collapses_distinction`, `affine_canonical`,
`no_section_collapse_to_residue`, `degrade_mode_comp`).

- The echo/loss layer is a **`Mode`-indexed decoration** (`linear ⊑ affine`,
  `weaken : LEcho linear → LEcho affine`) sitting *on top of* a base type
  system as a **separate module** — not a change to `progress`/`preservation`.
  So the Tier-1 base-operator extensions (`or`/`sub`/`mul`/…) are **orthogonal
  and compatible** by construction.
- echo-types' `DecorationStructure` is a **preorder** (`≤-refl`, `≤-trans`,
  `≤-prop`, `join`). WokeLang's **capability subsumption is that shape** — the
  `capSubsumes_refl` / `capSubsumes_trans` lemmas are deliberately on-path to
  host echo decorations later.
- **Integration blueprint** (not yet started): a Lean port of `EchoLinear` +
  `EchoResidue` as a `WokeLang/Echo.lean` L3 module, à la Ephapax's Coq port,
  leaving the base type-safety proofs intact.

## Extensions landed (2026-06-14)

- **Tier 1 (base operators)** — each with `HasType` + `Step` rules and full
  `progress`/`preservation` coverage:
  - logical: `or`;
  - integer arithmetic: `sub`, `mul`, `div`, `mod` — where `div`/`mod` panic on
    a zero divisor (step to `error`, reusing the proven `unwrap`-of-`oops`
    panic fragment);
  - ordering comparisons: `lt`, `gt`, `le`, `ge` (integer → `bool`, via
    `decide`).
- **Tier 3 (capability):** `capSubsumes` is a preorder (`_refl`, `_trans`).
- Still open in Tier 1: **float** arithmetic variants (`sub`/`mul`/`div` on
  `float`, mirroring `add` on float).

## Statement typing landed (2026-06-18) — both provers, in parity

Statements went from *declared datatype with no judgments* to a typed
sub-language with machine-checked metatheory, in **both** Lean (`WokeLang.lean`)
and Coq (`WokeLang.v`):

- **Judgment** `StmtWellTyped Γ s Γ'` / `StmtsWellTyped Γ ss Γ'` — a
  context-threading typing relation over all nine statement forms (`varDecl`,
  `assign`, `return`, `if`, `loop`, `attempt`, `consent`, `expr`, `complain`),
  mutually inductive (blocks contain statements). `varDecl` extends the
  context; `assign` requires a prior declaration at the assigned type;
  compound statements are block-scoped (they return the incoming context).
  This is the statement-level analogue of the expression `has_type`/`HasType`.
- **Metatheorems (all proved):**
  - `ctxDomSub_{refl,trans,extend}` — the context-domain preorder + the
    extension fact;
  - `stmt_wellTyped_mono` / `stmts_wellTyped_mono` — **context monotonicity**:
    a well-typed statement (or block) never undeclares a variable;
  - `stmts_wellTyped_append` — **sequencing composes**: typing one block then
    another from the resulting context types their concatenation;
  - `stmts_wellTyped_example` — an inhabitation smoke (`let x = 0; x`).
- **Method note:** the single-statement metatheorems are non-recursive (blocks
  are scoped), which breaks the mutual dependency; the block versions then go
  by ordinary induction on the *list* (sidestepping a mutual-induction scheme).
- **Soundness:** Lean is `sorry`-free; in Coq `Print Assumptions` reports all
  four statement lemmas **"Closed under the global context"** — i.e. axiom-free
  (they do not touch the classical-reals axioms the float fragment needs).

**Still open on statements:** the *dynamic* story — an execution relation +
store-typing preservation — which first needs open-term expression
preservation (see "Recommended next proof steps" #3).

## Arrays landed (2026-06-18) — Lean now at parity with Coq

The one array-shaped Tier-1 gap is closed on the Lean side, mirroring Coq's
`T_Array`/`T_Lit_Array`:

- **Typing:** `tArray` (array expression, elementwise) and `tArrayVal`
  (fully-evaluated `.vArray` literal value), both with the `∀ e ∈ es` premise.
- **Evaluation:** `sArrayStep` (reduce the left-most non-value element),
  `sArrayVal` (normalise `.array (vs.map .lit)` to `.lit (.vArray vs)`), and
  `sArrayErr` (propagate a panic out of an array, as the binop rules do). A
  fully-evaluated array is *not* an `IsValue` — it always steps via `sArrayVal`
  to the array literal, which is the value. (This is cleaner than Coq, where a
  `map ELit`-array is simultaneously a value *and* steppable, forcing extra
  array-equality step rules; in Lean, array equality reuses the generic
  `.lit`-equality rules after normalisation.)
- **Proofs:** `progress` and `preservation` cover all three step rules,
  `sorry`-free and axiom-free under Lean 4.30.0. The helper `array_split`
  does the pure-list "all-literals vs. prefix + first non-literal" split
  (the analogue of Coq's `array_elements_progress`).
- **Method note:** Lean's `∀ e ∈ es` premise yields a per-element induction
  hypothesis directly from `induction`, so the Lean `progress` needs **no
  well-founded recursion on an `expr_size` measure** — the device the Coq
  proof requires because Coq's `Forall`-based scheme does not recurse into the
  nested `has_type`s. The two developments now prove the same array results by
  different means.

## Coq proofs (`WokeLang.v`) — audited 2026-06-14

A parallel Coq formalization exists. It was given the same meticulous
treatment as the Lean file.

- **Toolchain:** Coq **8.18.0** (ubuntu-24.04 apt). Build / verify (the oracle):
  `cd docs/proofs/verification && coqc WokeLang.v` (exit 0 ⇒ verified). CI gate:
  `.github/workflows/coq-proofs.yml` (pinned to ubuntu-24.04 — the file is
  version-sensitive).

- **Rot found and fixed.** Like the Lean file, `WokeLang.v` did **not compile**
  (no CI ever ran the prover). The *only* breakage: `value_eq_dec` used `decide
  equality; … apply list_eq_dec; assumption`, but the recursive IH for the
  nested `list value` is no longer in scope under 8.18 → "No such assumption".
  Fixed with an explicit fixpoint (`fix IH 1; …; apply list_eq_dec; exact IH`).
  Everything else — including the large `preservation` proof — then compiled.

- **Soundness (meticulous check).** No `Admitted`/`admit`/`Axiom`/`Conjecture`.
  `Print Assumptions` on `progress`/`preservation`/`type_safety` shows they
  depend **only** on `ClassicalDedekindReals.sig_forall_dec` +
  `functional_extensionality` — both pulled in *unavoidably* by modelling
  floats as real numbers (`R`), exactly as the file header claims ("no new
  axioms beyond those implicit in `Coq.Reals`"). Consistent, standard, honest.

- **Coverage vs. the Lean file.** Complementary, not identical:
  - Arrays are **now at parity** (Lean caught up 2026-06-18): both have
    `T_Array`/`T_Lit_Array` (Coq) ⟷ `tArray`/`tArrayVal` (Lean) and array
    stepping. The proofs differ in method: Coq's `progress` uses **well-founded
    induction on `expr_size`** to get an IH for array elements (its
    `Forall`-based induction scheme does not recurse into the nested
    `has_type`s); Lean phrases the premise as `∀ e ∈ es`, which yields the
    per-element IH directly, so no size measure is needed. Coq additionally
    treats a `map ELit`-array as a value (needing extra array-equality step
    rules); Lean normalises arrays to a `.vArray` literal first and reuses
    generic `.lit`-equality.
  - Coq models floats as `ℝ` ⇒ `value_eq_dec` is fully decidable (`Req_EM_T`),
    at the cost of the classical-reals axioms above. (Lean models `Float` as
    opaque IEEE and decides equality classically via `by_cases`.)
  - Coq is now **at parity on integer binops** (landed 2026-06-15): on top of
    `add`/`eq`/`and` it gains `or`, `sub`, `mul`, `div`/`mod` (which panic to
    `VOops` on a zero divisor, mirroring the proven unwrap-of-oops fragment) and
    the comparisons `lt`/`gt`/`le`/`ge` (`Z` → `bool`) — each with a `has_type`
    rule, a `step` rule, and full `progress`/`preservation` coverage, axiom-free.
    Float arithmetic variants remain unmodelled on both sides, and `BNeq` is a
    symmetric gap (neither Lean nor Coq has it).

- **`cap_subsumes` bug fixed.** Its catch-all was `TODO: false`, so the relation
  was **not even reflexive** (`cap_subsumes CapProcess CapProcess = false`).
  Fixed to fall back to decidable equality (`capability_eq_dec`), and
  `cap_subsumes_refl` is now proven (axiom-free). `cap_subsumes_trans` is a
  documented follow-up (the relation is transitive; a robust Coq proof needs
  explicit per-kind case analysis, not the brittle 6×6×6 automation).

- **Quality follow-up (flagged, not blocking).** The `preservation` proof is a
  large brute-force `try solve [...]` pile ending in a literal *"Nuclear
  option"* — it compiles and is axiom-honest, but is fragile and unreviewable.
  A clean per-case rewrite (in the style of the Lean `preservation`) is worth
  doing — the binop-parity work (2026-06-15) extended its `first [...]`
  reconstruction block and added an early literal-result closer rather than
  rewriting it. (That cascade also scales badly: the new ops had to be closed
  early and deterministically to avoid a multi-minute typecheck.)

## Status

- Repair to `sorry`-free under Lean 4.30.0: see CI / `lean` check.
- Coverage: **subset** of the surface language, as tabulated above — *not* a
  full-language proof, and honestly so.
