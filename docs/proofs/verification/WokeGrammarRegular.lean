/-
SPDX-License-Identifier: MPL-2.0
Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

WokeGrammarRegular.lean — machine-checks grammar-proofs.md §7.1: the WokeLang
expression language is NOT regular. Self-contained: Lean core prelude only (no
Mathlib), so CI checks it with a bare `lean WokeGrammarRegular.lean`.

Method: a finite DFA cannot accept the balanced-nesting sublanguage. We
- prove a bespoke finite pigeonhole from scratch (Mathlib's is unavailable here);
- model a DFA over `Fin k` states;
- run the fooling-set / pigeonhole argument (the combinatorial heart of the
  pumping lemma) on `aⁿbⁿ`: among the k+1 prefixes a⁰..aᵏ two reach the same
  state, so aⁱbⁱ (accepted) and aʲbⁱ (j≠i) reach the same final state, forcing
  the DFA to also accept aʲbⁱ ∉ L — contradiction.

Connection to the grammar: the WokeLang expression grammar derives arbitrarily
deep balanced groupings `(ⁿ x )ⁿ` (the `primary = "(" expression ")"` rule, used
n-deep), which is isomorphic to `aⁿbⁿ` under `( ↦ a`, `) ↦ b`. So the expression
language contains a non-regular sublanguage and is itself non-regular.
-/

namespace WokeGrammarRegular

/-- **Finite pigeonhole** (no Mathlib): if `f` maps `[0,m)` into `[0,n)` with
`n < m`, two distinct indices collide. By induction on `n`, collapsing the value
at the last index out of the codomain. -/
theorem pigeon : ∀ (n m : Nat) (f : Nat → Nat),
    (∀ i, i < m → f i < n) → n < m → ∃ i j, i < j ∧ j < m ∧ f i = f j := by
  intro n
  induction n with
  | zero => intro m f hf hnm; have h0 := hf 0 (by omega); omega
  | succ n ih =>
    intro m f hf hnm
    by_cases hcol : ∃ j, j < m - 1 ∧ f j = f (m - 1)
    · obtain ⟨j, hj, hfj⟩ := hcol; exact ⟨j, m - 1, by omega, by omega, by omega⟩
    · have hcol' : ∀ j, j < m - 1 → f j ≠ f (m - 1) := by
        intro j hj hfj; exact hcol ⟨j, hj, hfj⟩
      let g : Nat → Nat := fun i => if f i < f (m - 1) then f i else f i - 1
      have hg : ∀ i, i < m - 1 → g i < n := by
        intro i hi
        have hbound := hf i (by omega); have hne := hcol' i hi
        have hlast := hf (m - 1) (by omega)
        simp only [g]; by_cases hlt : f i < f (m - 1) <;> simp [hlt] <;> omega
      obtain ⟨i, j, hij, hjm, hgij⟩ := ih (m - 1) g hg (by omega)
      refine ⟨i, j, hij, by omega, ?_⟩
      have hnei := hcol' i (by omega); have hnej := hcol' j hjm
      simp only [g] at hgij
      by_cases hi : f i < f (m - 1) <;> by_cases hj : f j < f (m - 1) <;>
        simp [hi, hj] at hgij <;> omega

/-- Two-symbol alphabet (`a ≙ "("`, `b ≙ ")"`). -/
inductive Sym | a | b deriving DecidableEq, Repr

/-- A deterministic finite automaton with `k` states. -/
structure DFA (k : Nat) where
  start : Fin k
  step : Fin k → Sym → Fin k
  accept : Fin k → Bool

def DFA.runFrom {k} (M : DFA k) : Fin k → List Sym → Fin k
  | s, [] => s
  | s, x :: w => M.runFrom (M.step s x) w

def DFA.accepts {k} (M : DFA k) (w : List Sym) : Bool := M.accept (M.runFrom M.start w)

theorem runFrom_append {k} (M : DFA k) (s : Fin k) (w1 w2 : List Sym) :
    M.runFrom s (w1 ++ w2) = M.runFrom (M.runFrom s w1) w2 := by
  induction w1 generalizing s with
  | nil => rfl
  | cons x w ih => simp only [List.cons_append, DFA.runFrom, ih]

/-- The language `aⁿbⁿ`. -/
def isAnBn (w : List Sym) : Prop :=
  ∃ n, w = List.replicate n Sym.a ++ List.replicate n Sym.b

def countA : List Sym → Nat
  | [] => 0
  | Sym.a :: w => countA w + 1
  | Sym.b :: w => countA w

theorem countA_append (u v : List Sym) : countA (u ++ v) = countA u + countA v := by
  induction u with
  | nil => simp [countA]
  | cons x w ih => cases x <;> simp [countA, ih] <;> omega

theorem countA_repl_a (n : Nat) : countA (List.replicate n Sym.a) = n := by
  induction n with
  | zero => rfl
  | succ n ih => simp [List.replicate, countA, ih]

theorem countA_repl_b (n : Nat) : countA (List.replicate n Sym.b) = 0 := by
  induction n with
  | zero => rfl
  | succ n ih => simp [List.replicate, countA, ih]

/-- If `aʲbⁱ = aⁿbⁿ` then `j = n` and `i = n` (count `a`s, then lengths). -/
theorem anbn_inj {i j n : Nat}
    (h : List.replicate j Sym.a ++ List.replicate i Sym.b
       = List.replicate n Sym.a ++ List.replicate n Sym.b) : j = n ∧ i = n := by
  have hc : countA (List.replicate j Sym.a ++ List.replicate i Sym.b)
          = countA (List.replicate n Sym.a ++ List.replicate n Sym.b) := by rw [h]
  rw [countA_append, countA_append, countA_repl_a, countA_repl_a,
      countA_repl_b, countA_repl_b] at hc
  have hlen : (List.replicate j Sym.a ++ List.replicate i Sym.b).length
            = (List.replicate n Sym.a ++ List.replicate n Sym.b).length := by rw [h]
  simp only [List.length_append, List.length_replicate] at hlen
  omega

/-- **T7.1 — not regular.** No finite DFA accepts exactly `aⁿbⁿ`. Via the grammar's
balanced-nesting sublanguage `(ⁿ x )ⁿ` (isomorphic to `aⁿbⁿ`), the WokeLang
expression language is therefore not regular. -/
theorem anbn_not_regular (k : Nat) (M : DFA k) :
    ¬ (∀ w, M.accepts w = true ↔ isAnBn w) := by
  intro hM
  let f : Nat → Nat := fun i => (M.runFrom M.start (List.replicate i Sym.a)).val
  have hf : ∀ i, i < k + 1 → f i < k := fun i _ =>
    (M.runFrom M.start (List.replicate i Sym.a)).isLt
  obtain ⟨i, j, hij, _, hfij⟩ := pigeon k (k + 1) f hf (by omega)
  have hstate : M.runFrom M.start (List.replicate i Sym.a)
              = M.runFrom M.start (List.replicate j Sym.a) := Fin.eq_of_val_eq hfij
  have hacc_i : M.accepts (List.replicate i Sym.a ++ List.replicate i Sym.b) = true :=
    (hM _).mpr ⟨i, rfl⟩
  have hsame : M.accepts (List.replicate j Sym.a ++ List.replicate i Sym.b)
             = M.accepts (List.replicate i Sym.a ++ List.replicate i Sym.b) := by
    simp only [DFA.accepts, runFrom_append, ← hstate]
  have hacc_j : M.accepts (List.replicate j Sym.a ++ List.replicate i Sym.b) = true := by
    rw [hsame]; exact hacc_i
  obtain ⟨n, hn⟩ := (hM _).mp hacc_j
  obtain ⟨hj, hi⟩ := anbn_inj hn
  omega

end WokeGrammarRegular
