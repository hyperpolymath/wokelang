<!-- SPDX-License-Identifier: MPL-2.0 -->
<!-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk> -->

# WokeLang Formal-Verification Roadmap

Scope for taking WokeLang from "a model of the expression core + grammar
metatheory is machine-checked" to "fully proved." Companion to
[`verification/AUDIT.md`](verification/AUDIT.md),
[`verification/GRAMMAR-PROOF-INVENTORY.md`](verification/GRAMMAR-PROOF-INVENTORY.md),
and [`../../PROOF-NEEDS.md`](../../PROOF-NEEDS.md). Derived from a four-part survey
of every proof document and the implementation (2026-06).

## The two axes (and the honest reality)

"Fully proved across its entire extent" means two very different things:

- **Axis 1 — breadth of the *models*:** mechanize every prose proof (type
  inference, semantics, compiler, security, complexity, concurrency) in Lean 4
  (4.30.0, Mathlib-free, single-file) and/or Coq 8.18.0. Mostly tractable; a few
  items are infeasible without Mathlib.
- **Axis 2 — depth, *model ↔ real code*:** connect the proofs to the actual
  **~23k-LOC Rust** implementation (plus a divergent ~1.1k-LOC OCaml `core/`).
  There is currently **no extraction, no refinement proof, no translation
  validation** in place. The machine-checked proofs cover roughly **10–15 %** of
  the 94-production surface language, and they verify **models, not code**.

> **Reality check.** Literal "fully proved against the shipping Rust" is
> CompCert + RustBelt scale — multiple person-years, research-grade tooling that
> does not exist for this codebase (async / `tokio` / proc-macros). It is a new
> research program, not an extension of the present work. What *is* achievable is
> **"the language model fully proved, plus an empirical bridge to the code."**

## Current baseline (machine-checked, hole-free, CI-gated)

| File | Covers |
|---|---|
| `verification/WokeLang.lean` / `.v` | expression-core **type safety** (progress, preservation, type-safety, canonical forms, arrays, `Result`/`unwrap` panic); statement *typing* (no execution); consent monotonicity/preservation; capability preorder |
| `verification/WokeGrammar.lean` | verified-parser core (soundness, completeness, termination, precedence, determinism) |
| `verification/WokeGrammarStructure.{lean,v}` | no-left-recursion (whole grammar), maximal munch, keyword priority, LL(1)✗/LL(2)✓ |
| `verification/WokeGrammar{CFL,Regular,Pumping}.lean` | CFL closure, non-regularity, the CFL pumping lemma, `aⁿbⁿcⁿ ∉ CFL`, ∩ non-closure |

## Fix-first: five spec bugs (each Small, do as the phase is reached)

These are *wrong as written* and will block the corresponding proofs:

1. **HM `unify(Int,Float)=promote`** makes the "most general unifier" theorems
   false — model widening as **subtyping**, not unification. (blocks Phase 3a)
2. **`Step` is non-deterministic** (`sArrayVal` overlaps element rules) — blocks
   any determinism proof. (blocks Phase 1c)
3. **Float `==` reflexivity** is false on `NaN` — the memory-model equality claim
   needs restating (decidable structural eq, or exclude floats).
4. **Unbounded `Int` vs `ℤ₆₄`** — the model uses ℤ; the language is 64-bit
   wrapping. Affects arithmetic laws and compiler/WASM correctness. (cross-cutting)
5. **Three-way divergence** — Rust, OCaml `core/`, and the Lean/Coq models
   disagree on `Result`/units/coercions, so "the impl refines the proof" is
   currently ill-posed. Resolve by making one model **normative**. (blocks Axis 2)

## Axis 1 — phases (dependency-ordered)

| Phase | Deliverable | Effort | Mathlib-free? | Depends on |
|---|---|---|---|---|
| **1. Full type safety** | substitution lemma + `[T-Call]`/`Φ` + indexing → progress/preservation for the full *expression* language | M | yes | core |
| **1b. Statement dynamics** | statement execution relation + store-typing preservation | L | yes | 1 |
| **1c. Operational metatheory** | fix determinism, add big-step, big↔small equivalence | M | yes | bug 2, 1b |
| **2a. Capability order** | antisymmetry + `hasCapability` satisfaction lemmas (+ Coq `cap_subsumes_trans`) | S | yes | — |
| **2b. Consent state machine** | duration/expiry, protocol completeness + determinism + unforgability, isolation | M | yes (excl. IO persistence, LTL/CTL) | — |
| **2c. Capability state machine** | no-privilege-escalation, confinement, revocation, temporal, audit | M | yes | 2a |
| **3a. HM inference (soundness)** | `unify` (well-founded + occurs check) + Algorithm W **soundness** | L | yes (hand-rolled `FTV`/`Subst`) | 1, bug 1 |
| **3b. HM completeness** | principal types / most-general | XL | yes but large | 3a |
| **4a. Compiler simulation** | Lean bytecode IR + VM + `compile` + forward simulation (interpret↔VM) | L | yes | 1c |
| **4b. Lexer/parser in Lean** | `tokenize`/`parse` + EBNF conformance (beyond current structural facts) | M ea. | yes | — |
| **4c. WASM preservation** | WASM-subset semantics + preservation | L | yes (partial) | 4a |
| **5a. Category theory (concrete)** | functor / monad / naturality laws for `Maybe`/`Result`/`List`/`State` | S–M | yes | — |
| **6. Complexity (structural)** | AST-size + `bytecode ≤ k·AST` size theorems only | L | yes | 4a |
| **7. Concurrency (scoped)** | interleaving semantics + worker isolation + message-non-loss safety | L | yes | 1b |

## Axis 1 — explicitly out of scope / research-grade

- **Denotational adequacy** (`𝕍 ≅ … + (𝕍→𝕍⊥)`, fixpoints): recursive
  function-summand fails Lean's positivity check; needs Scott domain theory →
  XL, likely infeasible single-file/Mathlib-free. Restrict to the first-order
  fragment (M) or descope.
- **Category-theory headline claims** (CCC, all finite limits/colimits,
  adjunctions, Yoneda, topos): need Mathlib's `CategoryTheory` (policy conflict);
  several are not well-posed about an actual defined category. Descope or
  grant a one-module Mathlib exception.
- **Complexity asymptotics** (`O(·)`, inverse-Ackermann/union-find, crate
  constants): claims about Rust + external crates, not witnessable in a model.
- **Concurrency race/deadlock freedom + CSP trace-equivalence**: evidence is Rust
  ownership / a not-yet-built async runtime — not faithfully mechanizable.
- **Memory model** (use-after-free, double-free, data races, UTF-8,
  atomic-write persistence): Rust/POSIX host properties, *not* object-language
  theorems. Only bounds-safety + equality-relation are real (S).

## Axis 2 — model ↔ implementation

| Approach | Guarantee | Effort | Reality |
|---|---|---|---|
| **(E) Make one model normative; kill 3-way divergence** | well-posedness | M | **Prerequisite** for any bridge being meaningful |
| **(A) Differential + property-based testing** | empirical | S–M | **Only realistic near-term bridge**; tooling exists (`proptest`, `fuzz/`, `conformance/`) |
| **(B) Translation validation for the parser** | per-run certificate | L | model already half-supports it (renderer inversion) |
| **(C) Coq→OCaml extraction of a *new* reference interpreter** | extracted = verified | L | idiomatic, but *replaces* `core/eval.ml` rather than validating it |
| **(D) Rust refinement (Aeneas/Creusot/Verus), core fragment only** | impl ⊑ model | XL | research-grade; async/macros out of tool scope |
| **Full verified source→WASM compiler** | end-to-end | XL (multi-person-year) | CompCert-scale; new project |

## Recommended target — three tiers

- **Tier 1 — the model is fully proved.** Phases 1, 1b, 1c, 2a–2c, 3a, 4a plus the
  five spec-bug fixes: full type safety, sound type inference, a verified compiler
  simulation, and real security state machines. The achievable bulk — all
  Mathlib-free, extending the hole-free core.
- **Tier 2 — empirical bridge to the code.** (E) + (A): resolve divergence and
  stand up cross-backend differential / property testing. Real confidence the
  Rust/OCaml code matches the verified model.
- **Tier 3 — true refinement / verified compilation.** (D) and source→WASM:
  explicitly a research program (multi-person-year). Not a committed deliverable.

**First increment** (lowest risk, highest leverage): the five spec-bug fixes +
**Phase 2a** (capability order, S) + **Phase 1** (full-expression type safety via
the substitution lemma, M). These extend the existing hole-free file directly and
unlock Phases 1c / 3a / 4a.

## Progress

- [x] **Phase 2a (Lean)** — capability partial order (`capSubsumes_antisymm`,
  completing `_refl`/`_trans`) + satisfaction lemmas (`hasCapability_mono`,
  `hasCapability_subsumes`). Coq parity (`cap_subsumes_trans`/`_antisymm`) remains
  a deliberate follow-up — the author left it unproven rather than ship fragile
  6×6×6 automation; a clean Coq proof wants a `cap_subsumes` characterization lemma.
- [~] **Phase 1 (partial)** — the **Substitution Lemma** (`subst` + `subst_preserves_typing`,
  type-safety.md Lemma 3.4) is mechanized on the hole-free core, by induction on the
  typing derivation with the context generalized (axioms `propext`, `Quot.sound`). This is
  the prerequisite for `[T-Call]`'s preservation case and for Algorithm W soundness (3a).
  *Finding:* `[T-Call]` dynamics here are NOT the assumed simple body-substitution —
  `Expr.call` is by name and `TopItem.functionDef` bodies are **statement lists**, so call
  reduction entangles with statement *execution* and belongs with **Phase 1b** (statement
  dynamics), not this step. There is also no `index` constructor, so `[T-Index]` requires an
  AST extension. Roadmap refined accordingly.
- [~] **Phase 1b (foundation)** — **store typing** (`StoreWellTyped`) bridging the
  static `TypeEnv` and the runtime `Env`, with the three lemmas the statement-execution
  preservation proofs rest on: `store_wellTyped_empty` (empty store types against the
  empty context), `store_wellTyped_lookup` (a typed variable resolves to a value of its
  type), and `store_wellTyped_extend` (extending context+store in lockstep — exactly a
  `varDecl` — preserves store typing). Hole-free (axiom `propext` only).
- [~] **Phase 1b (substrate)** — **expression-evaluation invariants under a store**, the
  layer the statement-execution relation sits on: `step_store_invariant` and
  `multiStep_store_invariant` (expression evaluation never mutates `ρ` — so a sub-evaluation
  inside a statement can't disturb the bindings the statement effect then acts on), and
  `hasType_lit_any` (literal typing is context-independent — the weakening that lifts
  `StoreWellTyped`'s `HasType emptyTypeEnv (.lit v) t` into the arbitrary `Γ` statement-level
  typing uses). Hole-free (`hasType_lit_any` needs **no** axioms). *Correction to the prior
  note:* the expression `Step` is **not** closed-term-only — it has an `sVar` rule that
  resolves variables from `ρ`; the closed-context use was only in the `emptyTypeEnv`-stated
  `progress`/`preservation`. So the remaining work is a generalized store-typed preservation
  (`HasType Γ e t` under `StoreWellTyped Γ ρ`), then the statement-execution relation itself.
- [~] **Phase 1b (store-typed preservation)** — `store_step_preservation`: expression
  preservation generalized from the empty context to an arbitrary `Γ` under `StoreWellTyped Γ ρ`
  (`HasType Γ e t → Step e ρ e' ρ' → HasType Γ e' t`). This is the form statement execution
  needs — expressions inside a statement are typed in the *running* context, not the empty one.
  Mirrors `preservation`; the **only** case that differs is `sVar`, which discharges via
  `store_wellTyped_lookup` + `hasType_lit_any` (the runtime value bound to `x` has the type
  `Γ` assigns `x`) instead of the empty-context contradiction. A `preservation_via_store`
  corollary confirms it subsumes the closed theorem (empty context is vacuously store-typed).
  Hole-free (classical kernel base: `propext`, `Classical.choice`, `Quot.sound`). Purely
  additive — the merged `preservation`/`type_safety` are untouched.
- [~] **Phase 1b (statement execution — simple fragment)** — a big-step execution relation
  `StmtExec`/`StmtsExec` (mutual) and its **store-typing preservation** for the simple
  statements (no embedded blocks): `complain`, `expr`, `varDecl`, `assign`, `return_`. Each
  evaluates its expression to a value via the closed-store `MultiStep` then applies its store
  effect; `stmt_exec_preservation` / `stmts_exec_preservation` show a well-typed statement/block
  run in a well-typed store yields a store well-typed against the statement's output context
  (`StmtWellTyped Γ s Γ'`). Supporting lemmas: `store_multiStep_preservation` (multi-step
  store-typed preservation) and `store_wellTyped_update` (overwriting an already-declared
  variable at its type — the `assign` analogue of `store_wellTyped_extend`). Two executable
  smoke tests (`let x = 0`; the block `let x = 0; x`). Hole-free (classical kernel base;
  `store_wellTyped_update` needs none). Purely additive.
  *Deferred to the next increment:* the control-flow forms `if`/`loop`/`attempt`/`consent`,
  which introduce **block scoping** in the flat `Env` model (a block-local `varDecl` shadowing
  an outer variable at a different type would break preservation against the outer context
  unless the store is restored on block exit). That store-restoration design is the open
  modelling decision for control-flow execution; `return_`'s value-propagation / block
  short-circuit (relevant once function calls are modelled) is likewise deferred.
- [ ] Phase 1 (cont.: `[T-Call]` after 1b), 1b (control-flow execution + scoping), 1c — type-safety + operational metatheory.
- [ ] Phase 2b, 2c — consent + capability state machines.
- [ ] Phase 3a (+3b) — HM inference.
- [ ] Phase 4a–4c — compiler / parser / WASM.
- [ ] Phase 5a, 6, 7 — concrete category theory, structural complexity, scoped concurrency.
- [ ] Axis 2 — (E) normative model, (A) differential testing.
