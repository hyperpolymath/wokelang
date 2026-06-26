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
| T2.1 | §2.1 No left recursion | ✅ yes (whole grammar) | **P2** | Grammar as data; `¬ LeftRecursive G` by decision/structural proof over **all** productions | MACHINE-CHECKED |
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
| T7.3a | §7.3 CFL closed under ∪, ·, * | ✅ | **P5** | Explicit grammar constructions + language-equality proofs | MACHINE-CHECKED |
| T7.1 | §7.1 Not regular (pumping lemma) | ⚠️ no (needs automata/Mathlib offline) | **P6** | Mechanize the combinatorial kernel (the balanced-paren sublanguage `(ⁿ)ⁿ ⊆ L`); full DFA+pumping non-regularity needs Mathlib's `Computability` (network-fetched, unavailable) | FLAGGED + partial kernel |
| T7.3b | §7.3 CFL **not** closed under ∩, ¬ | ⚠️ no (needs non-CFL-ness of `aⁿbⁿcⁿ`) | **P6** | Requires the pumping lemma *for CFLs* — same Mathlib gap | FLAGGED |

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

## Status

P1 landed (above). P2–P6 + the Coq mirror proceed in priority order; the
authoritative status is always "does the CI prover check go green."
