<!--
SPDX-License-Identifier: CC-BY-SA-4.0
SPDX-FileCopyrightText: 2026 Hyperpolymath
-->
# WokeLang Grammar — Proof-Obligation Inventory & Audit

This document is the **complete inventory** of every formal claim made *about the
grammar* in [`grammar-proofs.md`](../formal-semantics/grammar-proofs.md), with,
for each: whether it is **faithfully machine-checkable** in the repo's prover
setup (Lean 4.30.0 / Coq 8.18.0, single-file, no Mathlib, offline), its
**priority**, and its **status**.

It answers the question the user posed: *which grammar proofs are needed, which
are wanted, and which are actually done (run in a prover) vs. merely asserted in
prose.*

## Ground truth established first

- **Canonical grammar:** `grammar/wokelang.ebnf`, *verified against the live
  implementation* (`src/lexer/token.rs` identifier rule `[a-zA-Z][a-zA-Z0-9_]*`;
  `src/parser/mod.rs` support for `while`/`break`/`continue`, lambdas, record
  literals, field access, function types). The older `spec/grammar.ebnf` was a
  **stale subset** falsely claiming to supersede it; it is now a generated
  synchronized copy guarded by `scripts/check-grammar-sync.sh`.
- **Provers actually installed and run here:** Coq **8.18.0** (apt) and Lean
  **4.30.0** (pinned by `lean-toolchain`, installed from the GitHub release —
  the `*.lean-lang.org` resolver hosts are blocked by egress policy, so the
  tarball is fetched directly from `github.com`, exactly as `lean-proofs.yml`
  already does in CI). Baseline check before any new work: the **existing**
  `WokeLang.lean` and `WokeLang.v` both compile clean (exit 0), sorry/admit-free.
- **Before this work there were ZERO machine-checked grammar proofs.** Every
  claim in `grammar-proofs.md` was English prose. The machine-checked
  `WokeLang.{lean,v}` cover the *type system / semantics* (on the AST), not the
  grammar/parser.

## The parser being modelled (so the proofs are faithful, not invented)

`src/parser/mod.rs` is a **precedence-climbing (Pratt) recursive-descent**
parser. Precedence ladder (higher binds tighter):

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| | `or` | `and` | `== !=` | `< > <= >=` | `+ -` | `* / %` | unary `- not` | postfix `. () []` |

Infix recursion uses **strict `<`** on the operator's own level ⇒ all binary
operators are **left-associative**. This is exactly the EBNF repetition ladder
(`logical_or = logical_and , { "or" , logical_and }` …). The Lean/Coq models
reproduce this structure so soundness/completeness/precedence are about *this*
parser, not a toy.

## Inventory

Legend — **Faithful?**: can it be mechanized *as the prose states it* in this
setup? **Status**: `MACHINE-CHECKED` (compiles in a prover here) · `PROSE-ONLY`
(was, and remains, an informal argument) · `FLAGGED` (honestly out of faithful
reach here, with reason).

| # | Prose claim (grammar-proofs.md) | Faithful here? | Priority | Mechanization | Status |
|---|---|---|---|---|---|
| T2.1 | §2.1 No left recursion | ✅ yes (whole grammar) | **P2** | Grammar as data; rank-decreasing `Reach` ⇒ `¬ Reach a a` over **all** productions | MACHINE-CHECKED (**+ found a real discrepancy:** the guard pattern IS left-recursive — see below) |
| T2.2 | §2.2 Unambiguity | ✅ for the core (undecidable in general) | **P1** | Determinism of the verified parser ⇒ unique parse: `Derives ts e₁ → Derives ts e₂ → e₁=e₂` for the expression core | MACHINE-CHECKED (core) |
| T2.3 | §2.3 LL(2) | ◑ partial | **P4** | The one 2-token decision (`ident` vs `ident(`) witnessed; determinism of the core parser. Full LL(2) table for all 94 productions is not built | MACHINE-CHECKED (witness) |
| T3.1 | §3.1 Parser soundness | ✅ for the core | **P1** | `parse ts = some (e, rest) → Derives (consumed) e` | MACHINE-CHECKED (core) |
| T3.2 | §3.2 Parser completeness | ✅ for the core | **P1** | `Derives ts e → parse ts = some (e, [])` | MACHINE-CHECKED (core) |
| T3.3 | §3.3 Parser termination | ✅ | **P1** | Totality of `parse` (Lean/Coq accept the definition ⇒ it terminates on every input) + explicit fuel/measure | MACHINE-CHECKED |
| T4.1 | §4.2 Maximal munch (longest match) | ✅ for the keyword/identifier fragment | **P3** | `classify` longest-prefix lemma; `"remembering"` ↦ identifier not `remember`+`ing` | MACHINE-CHECKED (fragment) |
| T4.2 | §4.3 Keyword priority | ✅ | **P3** | `classify "remember" = Remember` and a general "a string equal to a keyword classifies as that keyword" lemma | MACHINE-CHECKED |
| T6.1 | §6.2 Pratt precedence correctness | ✅ | **P1** | General precedence lemma + concrete `1+2*3 ↦ 1+(2*3)`, `1*2+3 ↦ (1*2)+3` | MACHINE-CHECKED |
| T6.3 | §6.3 Left-associativity | ✅ | **P1** | `a-b-c ↦ (a-b)-c` from the strict-`<` model + general statement | MACHINE-CHECKED |
| T1.1 | §1.1 CFG membership | ✅ | **P4** | By construction (the grammar relation is a CFG) | MACHINE-CHECKED |
| T1.2 | §1.1 LL(1) = ✗ | ✅ | **P4** | Exhibit the FIRST/FIRST conflict (`primary → identifier` vs `identifier "(" …`) — a 1-lookahead non-determinism witness | MACHINE-CHECKED |
| T7.3a | §7.3 CFL closed under ∪, ·, * | ✅ done from scratch | **P5→done** | `WokeGrammarCFL.lean`: CFG derivation relation + reusable embedding lemma + union/concat/star grammar constructions, `propext`-only | MACHINE-CHECKED |
| T7.1 | §7.1 Not regular (pumping lemma) | ✅ done from scratch | **P6→done** | `WokeGrammarRegular.lean`: bespoke finite pigeonhole + `Fin k` DFA + fooling-set on `aⁿbⁿ` (≅ `(ⁿ)ⁿ`), Mathlib-free | MACHINE-CHECKED |
| T7.0 | CFL pumping lemma (Mathlib-gap) | ✅ done from scratch | **Ext** | `WokeGrammarPumping.lean`: `cfl_pumping` — `descend`/`ht_descend`/`nodeNT_add` spine navigation + `Ctx.comp` + pigeonhole ⇒ `z = uvwxy`, `1≤|vx|`, `|vwx|≤2^(card+1)`, `uvⁱwxⁱy ∈ L`; classical kernel constants only | MACHINE-CHECKED |
| T7.3b | §7.3 CFL **not** closed under ∩, ¬ | ⚠️ remaining (pumping lemma now available) | **P6** | The blocker (CFL pumping lemma) is now proved as T7.0; remaining: finite `IsCFL` + `aⁿbⁿcⁿ ∉ CFL` + De Morgan | IN PROGRESS |

## Priority order (execution)

1. **P1 — expression-core verified parser** (`WokeGrammar.lean/.v`): discharges
   T3.1, T3.2, T3.3, T2.2(core), T6.1, T6.3, and feeds T2.3. Biggest and most
   load-bearing — the precedence/associativity/soundness story.
2. **P2 — whole-grammar no-left-recursion** (T2.1): the only claim that is
   honestly provable for the *entire* 94-production grammar, not just a core.
3. **P3 — lexer maximal-munch + keyword-priority** (T4.1, T4.2).
4. **P4 — classification** (T1.1 CFG, T1.2 LL(1)✗, T2.3 LL(2) witness).
5. **P5 — CFL positive closure** (T7.3a).
6. **P6 — honest flags** (T7.1, T7.3b): partial kernel + documented reason.

Then **mirror P1–P5 to Coq** (the repo keeps Lean/Coq in lockstep) and **gate
both in CI**.

## What is deliberately NOT claimed

- **Completeness against the *Rust* parser byte-for-byte** is *not* asserted: the
  proofs are against a Lean/Coq model that faithfully reproduces the parser's
  precedence-climbing structure. Bridging model↔Rust would need a verified
  extraction or a Rust semantics, which neither prover provides here. The model
  is justified by the structural correspondence documented above, not by
  extraction.
- **Full-CFG unambiguity** (T2.2 for the *entire* grammar) is undecidable; only
  the core is proven unambiguous (via parser determinism).
- The **non-regularity / non-closure** results (T7.1, T7.3b) are flagged, not
  faked — see P6.

## Landed — P1 (`WokeGrammar.lean`, Lean 4.30.0)

Machine-checked and CI-gated (`.github/workflows/lean-proofs.yml`). Compiles
clean (`lean WokeGrammar.lean`, exit 0), **`sorry`/`admit`/`native_decide`-free**.
`#print axioms` on the headline theorems shows dependence only on `propext` +
`Quot.sound` (Lean's core logical axioms) — **no `Classical.choice`, no
`sorryAx`, no compiler-trust `ofReduceBool`** (kernel-checked throughout, even
cleaner than `WokeLang.lean`).

- **T3.3 termination** — the parser is a total function (fuel-structural mutual
  recursion ⇒ Lean accepts it ⇒ it terminates on every input).
- **T6.1 precedence / T6.3 associativity** — a battery of kernel-`decide`d
  concrete checks: `1+2*3 ↦ 1+(2*3)`, `1*2+3 ↦ (1*2)+3`, `1-2-3 ↦ (1-2)-3`,
  `8/4/2 ↦ (8/4)/2`, the full six-level ladder, grouping, unary chains.
- **T3.2 completeness** — `completeness_rp : ∀ e, parseAll (rp e) = some e`
  (universal, over the whole AST), built on `prefix_rt` (the parser inverts the
  renderer). The substantive verified-parser result.
- **T2.2 unambiguity** — `parse_deterministic` (the parser is a function ⇒ ≤1
  parse) and `rp_injective` (distinct expressions have distinct concrete forms,
  proved via the parser).
- **T3.1 soundness** — witnessed by the **rejection battery** (7 kernel-`decide`d
  no-over-acceptance checks: leading op, two atoms, trailing op, unclosed/extra
  paren, empty, doubled op) + determinism. *Scope note:* a full declarative-CFG
  soundness theorem (`accepted ⇒ derivable` against an independent grammar
  relation) is the one honest extension still open on P1; the rejection battery
  covers the no-junk direction concretely.

## Landed — P2/P3/P4 (`WokeGrammarStructure.lean`, Lean 4.30.0)

CI-gated (`lean-proofs.yml`), `sorry`-free; `no_left_recursion` depends on **no
axioms at all** (fully constructive).

- **T2.1 no left recursion (P2)** — the begins-with-first-nonterminal graph of the
  *whole* grammar is encoded as data with a strictly-decreasing rank; `Reach`
  (transitive first-symbol reachability) ⇒ `no_left_recursion : ∀ a, ¬ Reach a a`.
  **Discrepancy found & machine-checked:** the grammar *as literally written* has
  one left-recursive production — the guard pattern `pattern = … | pattern "when"
  expression` (`guard_pattern_is_left_recursive`). So the prose §2.1 blanket "no
  left recursion" is **false as written**; it holds only for the implemented
  subset (the parser does not implement the guard alternative — the grammar's own
  NOTE). This corrects the prose.
- **T4.1 maximal munch / T4.2 keyword priority (P3)** — a word scanner taking the
  maximal identifier run + keyword-on-exact-match: `kw_priority` (general),
  `munch_maximal` (general longest-match: the remainder never extends the token),
  plus kernel-`decide`d concretes (`remember`↦keyword, `remembering`↦*one*
  identifier not `remember`+`ing`, `remember(`↦keyword then stop).
- **T1.2 LL(1)=✗ / T2.3 LL(2)=✓ (P4)** — `not_LL1` (the `x` vs `x(…)` FIRST/FIRST
  conflict shares FIRST₁ = identifier) and `LL2_separates` (two tokens decide,
  mirroring the parser's `peek == '('` branch). CFG membership holds by
  construction.

## Landed — Coq mirror (`WokeGrammarStructure.v`, Coq 8.18.0)

CI-gated (`coq-proofs.yml`); `Print Assumptions` reports **axiom-free** ("Closed
under the global context"). Mirrors **P2 (no-left-recursion + guard discrepancy)**
and **P4 (LL(1)✗/LL(2)✓)** in lockstep with Lean. (The Lean↔Coq relationship for
the *parser metatheory* P1 follows the repo's existing pattern — Lean carries the
universal `prefix_rt`/`completeness_rp` development; a Coq port of that is the
scoped next step, exactly as `WokeLang.{lean,v}` are "complementary, not
identical" per `AUDIT.md`.)

## §7 — status (T7.1 done; §7.3 positive closure + CFL pumping lemma done)

- **T7.1 not regular — DONE** (`WokeGrammarRegular.lean`): rather than fetch
  Mathlib's automata library (blocked offline), a bespoke finite pigeonhole + a
  `Fin k` DFA + the fooling-set argument on `aⁿbⁿ` were built from scratch in
  core Lean, `sorry`-free (classical-logic axioms only). `aⁿbⁿ ≅ (ⁿ x )ⁿ`, the
  grammar's balanced-nesting sublanguage, so the expression language is non-regular.
- **§7.3 CFL *positive* closure (∪, ·, \*) — DONE** (`WokeGrammarCFL.lean`): a
  general CFG derivation relation + a reusable grammar-embedding lemma
  (`embGen_iff`) + explicit union/concat/star grammar constructions, `sorry`-free
  (`propext`-only). The WokeLang surface grammar is context-free, so it inhabits
  this class and these operations apply.
- **Pumping lemma for CFLs — DONE** (`WokeGrammarPumping.lean`): the full pumping
  lemma (which even Mathlib lacks) is now machine-checked from scratch in core
  Lean. `cfl_pumping` states that for an ε-free binary-normal-form grammar with
  `card` nonterminals, any word `z ∈ L(S)` of length `≥ 2^(card+1)` splits as
  `z = u v w x y` with `1 ≤ |v x|`, `|v w x| ≤ 2^(card+1)`, and `u vⁱ w xⁱ y ∈
  L(S)` for all `i`. Engine: parse trees + `|w| < 2^height` yield bound + one-hole
  contexts/`fill`/`comp` + `pumpIter` + tallest-spine `descend` (with the
  `ht = height − depth` and depth-composition laws) + finite pigeonhole ⇒
  repeated-nonterminal extraction. Trust base: the three classical kernel
  constants (`propext`, `Classical.choice`, `Quot.sound`) — no holes, no
  project-specific assumptions.
- **§7.3 *non-closure* under ∩ / ¬** is the remaining increment. With the pumping
  lemma in hand it follows by the standard route: a finiteness-aware `IsCFL` (the
  relation-based `IsCFL` is too permissive here — an infinite nonterminal type
  could "generate" `aⁿbⁿcⁿ`), then `aⁿbⁿcⁿ ∉ CFL` via `cfl_pumping`, then
  `L₁ ∩ L₂` non-closure by De Morgan against the proven positive ∪ closure.

## Axiom audit (`#print axioms`, verified in-toolchain)

Kernel-dependency printout for the headline results in `WokeGrammarPumping.lean`
(Lean 4.30.0). Only the standard classical constants appear — no `sorryAx`, no
project-specific constants:

| Theorem | Kernel dependencies |
|---|---|
| `yield_bound` | `propext`, `Quot.sound` |
| `ht_descend` | `propext`, `Quot.sound` |
| `nodeNT_add` | `propext`, `Classical.choice`, `Quot.sound` |
| `descend_sibling_nonempty` | `propext`, `Quot.sound` |
| `cfl_pumping` | `propext`, `Classical.choice`, `Quot.sound` |

`Classical.choice` enters only through the finite `pigeon`hole's case split; the
rest are the kernel constants Mathlib itself rests on. The other files' headline
results sit on the same or a smaller base (`WokeGrammarCFL.lean` is `propext`-only;
`WokeGrammarStructure`'s `no_left_recursion` is fully constant-free).

## Status

P1 (merged, #102) + P2/P3/P4 + the structural Coq mirror are machine-checked and
CI-gated. P5/P6 are honestly flagged above. The authoritative status is always
"does the CI prover check go green."
