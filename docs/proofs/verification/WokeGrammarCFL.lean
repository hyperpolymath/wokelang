/-
SPDX-License-Identifier: MPL-2.0
Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

WokeGrammarCFL.lean — machine-checks grammar-proofs.md §7.3 (positive direction):
the class of context-free languages is closed under union, concatenation and
Kleene star. Self-contained: Lean core prelude only (no Mathlib).

A CFG is a production relation `P : N → List (N ⊕ T) → Prop`; `Gen P A w` is the
derivation relation (a nonterminal generates a terminal string). `IsCFL L` means
some grammar generates exactly `L`. The proofs go through one reusable lemma —
`embGen_iff`, that embedding a grammar's nonterminals into a larger disjoint
grammar preserves the generated language — then build the union/concat/star
grammars (`none → S1 | S2`, `none → S1 S2`, `none → ε | S1 S`) and prove the
language equalities.

Connection to WokeLang: the surface grammar IS context-free (every production of
`grammar/wokelang.ebnf` has the form `A → α`), so it inhabits this class and these
closure operations apply to it.

Scope note: the §7.3 *negative* results (CFL NOT closed under intersection /
complement) need the pumping lemma FOR CFLs (to show e.g. `aⁿbⁿcⁿ` is not
context-free) — a separate, larger development, left scoped.
-/
namespace CFL

variable {T : Type}

abbrev GSym (N T : Type) := N ⊕ T

mutual
  inductive Gen {N : Type} (P : N → List (GSym N T) → Prop) : N → List T → Prop
    | mk {A rhs w} : P A rhs → GenL P rhs w → Gen P A w
  inductive GenL {N : Type} (P : N → List (GSym N T) → Prop) : List (GSym N T) → List T → Prop
    | nil : GenL P [] []
    | consT {t rest w} : GenL P rest w → GenL P (Sum.inr t :: rest) (t :: w)
    | consN {A rest w1 w2} : Gen P A w1 → GenL P rest w2 → GenL P (Sum.inl A :: rest) (w1 ++ w2)
end

def IsCFL (L : List T → Prop) : Prop :=
  ∃ (N : Type) (P : N → List (GSym N T) → Prop) (s : N), ∀ w, L w ↔ Gen P s w

abbrev emap {N1 Nu : Type} (emb : N1 → Nu) : GSym N1 T → GSym Nu T := Sum.map emb id

/-! ### Generic grammar embedding (reused for union / concat / star) -/

mutual
  theorem embLiftGen {N1 Nu} {P1 : N1 → List (GSym N1 T) → Prop} {Pu : Nu → List (GSym Nu T) → Prop}
      {emb : N1 → Nu} (hC : ∀ A rhs, Pu (emb A) rhs ↔ ∃ rhs1, P1 A rhs1 ∧ rhs = rhs1.map (emap emb))
      {A w} (h : Gen P1 A w) : Gen Pu (emb A) w :=
    match h with
    | .mk hP hL => .mk ((hC A _).mpr ⟨_, hP, rfl⟩) (embLiftGenL hC hL)
  theorem embLiftGenL {N1 Nu} {P1 : N1 → List (GSym N1 T) → Prop} {Pu : Nu → List (GSym Nu T) → Prop}
      {emb : N1 → Nu} (hC : ∀ A rhs, Pu (emb A) rhs ↔ ∃ rhs1, P1 A rhs1 ∧ rhs = rhs1.map (emap emb))
      {rhs w} (h : GenL P1 rhs w) : GenL Pu (rhs.map (emap emb)) w :=
    match h with
    | .nil => .nil
    | .consT hL => .consT (embLiftGenL hC hL)
    | .consN hG hL => .consN (embLiftGen hC hG) (embLiftGenL hC hL)
end

mutual
  theorem embReflGen {N1 Nu} {P1 : N1 → List (GSym N1 T) → Prop} {Pu : Nu → List (GSym Nu T) → Prop}
      {emb : N1 → Nu} (hC : ∀ A rhs, Pu (emb A) rhs ↔ ∃ rhs1, P1 A rhs1 ∧ rhs = rhs1.map (emap emb))
      {X w} (h : Gen Pu X w) : ∀ A, X = emb A → Gen P1 A w :=
    match h with
    | .mk hP hL => fun A hX => by
        rw [hX] at hP
        obtain ⟨rhs1, hP1, hrel⟩ := (hC A _).mp hP
        exact Gen.mk hP1 (embReflGenL hC hL rhs1 hrel)
  theorem embReflGenL {N1 Nu} {P1 : N1 → List (GSym N1 T) → Prop} {Pu : Nu → List (GSym Nu T) → Prop}
      {emb : N1 → Nu} (hC : ∀ A rhs, Pu (emb A) rhs ↔ ∃ rhs1, P1 A rhs1 ∧ rhs = rhs1.map (emap emb))
      {s w} (h : GenL Pu s w) : ∀ rhs1, s = rhs1.map (emap emb) → GenL P1 rhs1 w :=
    match h with
    | .nil => fun rhs1 hs => by
        cases rhs1 with
        | nil => exact GenL.nil
        | cons x r => simp [emap] at hs
    | .consT hL' => fun rhs1 hs => by
        cases rhs1 with
        | nil => simp [emap] at hs
        | cons x r =>
          cases x with
          | inl A => simp [emap] at hs
          | inr t =>
            simp only [List.map_cons, emap, Sum.map_inr, id_eq, List.cons.injEq, Sum.inr.injEq] at hs
            obtain ⟨ht, hrest⟩ := hs; subst ht
            exact GenL.consT (embReflGenL hC hL' r hrest)
    | .consN hG hL' => fun rhs1 hs => by
        cases rhs1 with
        | nil => simp [emap] at hs
        | cons x r =>
          cases x with
          | inr t => simp [emap] at hs
          | inl A' =>
            simp only [List.map_cons, emap, Sum.map_inl, List.cons.injEq, Sum.inl.injEq] at hs
            obtain ⟨hA, hrest⟩ := hs
            exact GenL.consN (embReflGen hC hG A' hA) (embReflGenL hC hL' r hrest)
end

theorem embGen_iff {N1 Nu} {P1 : N1 → List (GSym N1 T) → Prop} {Pu : Nu → List (GSym Nu T) → Prop}
    {emb : N1 → Nu} (hC : ∀ A rhs, Pu (emb A) rhs ↔ ∃ rhs1, P1 A rhs1 ∧ rhs = rhs1.map (emap emb))
    {A w} : Gen Pu (emb A) w ↔ Gen P1 A w :=
  ⟨fun h => embReflGen hC h A rfl, embLiftGen hC⟩

/-- A single-nonterminal sentential form generates the same strings as the
nonterminal itself. -/
theorem genL_single {N} {P : N → List (GSym N T) → Prop} {X w} :
    GenL P [Sum.inl X] w ↔ Gen P X w := by
  constructor
  · intro h
    cases h with | consN hG hL => cases hL with | nil => simpa using hG
  · intro h; simpa using GenL.consN h GenL.nil

/-! ### Closure under union -/

section Union
variable {N1 N2 : Type}

def emb1 : N1 → Option (N1 ⊕ N2) := fun A => some (Sum.inl A)
def emb2 : N2 → Option (N1 ⊕ N2) := fun B => some (Sum.inr B)

/-- Union grammar: fresh start `none`, with `none → S1 | S2`, and each side's
productions relabelled into the disjoint copy. -/
def unionP (P1 : N1 → List (GSym N1 T) → Prop) (P2 : N2 → List (GSym N2 T) → Prop)
    (s1 : N1) (s2 : N2) : Option (N1 ⊕ N2) → List (GSym (Option (N1 ⊕ N2)) T) → Prop :=
  fun X rhs => match X with
    | none => rhs = [Sum.inl (emb1 s1)] ∨ rhs = [Sum.inl (emb2 s2)]
    | some (Sum.inl A) => ∃ r1, P1 A r1 ∧ rhs = r1.map (emap (emb1 (N2 := N2)))
    | some (Sum.inr B) => ∃ r2, P2 B r2 ∧ rhs = r2.map (emap (emb2 (N1 := N1)))

variable (P1 : N1 → List (GSym N1 T) → Prop) (P2 : N2 → List (GSym N2 T) → Prop) (s1 : N1) (s2 : N2)

theorem union_left {A w} : Gen (unionP P1 P2 s1 s2) (emb1 A) w ↔ Gen P1 A w :=
  embGen_iff (emb := emb1) (fun _ _ => Iff.rfl)

theorem union_right {B w} : Gen (unionP P1 P2 s1 s2) (emb2 B) w ↔ Gen P2 B w :=
  embGen_iff (emb := emb2) (fun _ _ => Iff.rfl)

theorem cfl_union_gen {w} :
    Gen (unionP P1 P2 s1 s2) none w ↔ (Gen P1 s1 w ∨ Gen P2 s2 w) := by
  constructor
  · intro h
    cases h with
    | mk hP hL =>
      rcases hP with hP | hP <;> rw [hP] at hL <;> rw [genL_single] at hL
      · exact Or.inl ((union_left P1 P2 s1 s2).mp hL)
      · exact Or.inr ((union_right P1 P2 s1 s2).mp hL)
  · intro h
    rcases h with h | h
    · exact Gen.mk (Or.inl rfl) (genL_single.mpr ((union_left P1 P2 s1 s2).mpr h))
    · exact Gen.mk (Or.inr rfl) (genL_single.mpr ((union_right P1 P2 s1 s2).mpr h))

end Union

/-- **§7.3 — CFL closed under union.** -/
theorem cfl_union {L1 L2 : List T → Prop} (h1 : IsCFL L1) (h2 : IsCFL L2) :
    IsCFL (fun w => L1 w ∨ L2 w) := by
  obtain ⟨N1, P1, s1, hL1⟩ := h1
  obtain ⟨N2, P2, s2, hL2⟩ := h2
  refine ⟨Option (N1 ⊕ N2), unionP P1 P2 s1 s2, none, fun w => ?_⟩
  simp only [hL1, hL2]; exact (cfl_union_gen P1 P2 s1 s2).symm

/-! ### Closure under concatenation -/

/-- A two-nonterminal sentential form splits the string between them. -/
theorem genL_pair {N} {P : N → List (GSym N T) → Prop} {X Y w} :
    GenL P [Sum.inl X, Sum.inl Y] w ↔ ∃ w1 w2, w = w1 ++ w2 ∧ Gen P X w1 ∧ Gen P Y w2 := by
  constructor
  · intro h
    cases h with
    | consN hG1 hL2 => cases hL2 with
      | consN hG2 hL3 => cases hL3 with | nil => exact ⟨_, _, by simp, hG1, hG2⟩
  · rintro ⟨w1, w2, rfl, hX, hY⟩
    simpa using GenL.consN hX (GenL.consN hY GenL.nil)

section Concat
variable {N1 N2 : Type}

/-- Concatenation grammar: `none → S1 S2`, plus each side relabelled. -/
def concatP (P1 : N1 → List (GSym N1 T) → Prop) (P2 : N2 → List (GSym N2 T) → Prop)
    (s1 : N1) (s2 : N2) : Option (N1 ⊕ N2) → List (GSym (Option (N1 ⊕ N2)) T) → Prop :=
  fun X rhs => match X with
    | none => rhs = [Sum.inl (emb1 s1), Sum.inl (emb2 s2)]
    | some (Sum.inl A) => ∃ r1, P1 A r1 ∧ rhs = r1.map (emap (emb1 (N2 := N2)))
    | some (Sum.inr B) => ∃ r2, P2 B r2 ∧ rhs = r2.map (emap (emb2 (N1 := N1)))

variable (P1 : N1 → List (GSym N1 T) → Prop) (P2 : N2 → List (GSym N2 T) → Prop) (s1 : N1) (s2 : N2)

theorem concat_left {A w} : Gen (concatP P1 P2 s1 s2) (emb1 A) w ↔ Gen P1 A w :=
  embGen_iff (emb := emb1) (fun _ _ => Iff.rfl)
theorem concat_right {B w} : Gen (concatP P1 P2 s1 s2) (emb2 B) w ↔ Gen P2 B w :=
  embGen_iff (emb := emb2) (fun _ _ => Iff.rfl)

theorem cfl_concat_gen {w} :
    Gen (concatP P1 P2 s1 s2) none w ↔ ∃ w1 w2, w = w1 ++ w2 ∧ Gen P1 s1 w1 ∧ Gen P2 s2 w2 := by
  constructor
  · intro h
    cases h with
    | mk hP hL =>
      rw [hP, genL_pair] at hL
      obtain ⟨w1, w2, hw, hG1, hG2⟩ := hL
      exact ⟨w1, w2, hw, (concat_left P1 P2 s1 s2).mp hG1, (concat_right P1 P2 s1 s2).mp hG2⟩
  · rintro ⟨w1, w2, hw, hG1, hG2⟩
    refine Gen.mk rfl (genL_pair.mpr ⟨w1, w2, hw, ?_, ?_⟩)
    · exact (concat_left P1 P2 s1 s2).mpr hG1
    · exact (concat_right P1 P2 s1 s2).mpr hG2

end Concat

/-- **§7.3 — CFL closed under concatenation.** -/
theorem cfl_concat {L1 L2 : List T → Prop} (h1 : IsCFL L1) (h2 : IsCFL L2) :
    IsCFL (fun w => ∃ w1 w2, w = w1 ++ w2 ∧ L1 w1 ∧ L2 w2) := by
  obtain ⟨N1, P1, s1, hL1⟩ := h1
  obtain ⟨N2, P2, s2, hL2⟩ := h2
  refine ⟨Option (N1 ⊕ N2), concatP P1 P2 s1 s2, none, fun w => ?_⟩
  rw [cfl_concat_gen P1 P2 s1 s2]
  constructor
  · rintro ⟨w1, w2, hw, h1', h2'⟩; exact ⟨w1, w2, hw, (hL1 w1).mp h1', (hL2 w2).mp h2'⟩
  · rintro ⟨w1, w2, hw, h1', h2'⟩; exact ⟨w1, w2, hw, (hL1 w1).mpr h1', (hL2 w2).mpr h2'⟩

/-! ### Closure under Kleene star -/

/-- Right-recursive Kleene star of a language. -/
inductive Star (L : List T → Prop) : List T → Prop
  | nil : Star L []
  | step {w1 w2} : L w1 → Star L w2 → Star L (w1 ++ w2)

section StarS
variable {N1 : Type}

def embS : N1 → Option N1 := some

/-- Star grammar over `Option N1`: `none → ε | S1 S` (right-recursive), and the
original productions relabelled under `some`. -/
def starP (P1 : N1 → List (GSym N1 T) → Prop) (s1 : N1) :
    Option N1 → List (GSym (Option N1) T) → Prop :=
  fun X rhs => match X with
    | none => rhs = [] ∨ rhs = [Sum.inl (embS s1), Sum.inl none]
    | some A => ∃ r1, P1 A r1 ∧ rhs = r1.map (emap embS)

variable (P1 : N1 → List (GSym N1 T) → Prop) (s1 : N1)

theorem star_some {A w} : Gen (starP P1 s1) (embS A) w ↔ Gen P1 A w :=
  embGen_iff (emb := embS) (fun _ _ => Iff.rfl)

mutual
  theorem star_fwd_g {X w} (h : Gen (starP P1 s1) X w) : X = none → Star (Gen P1 s1) w :=
    match h with
    | .mk hP hL => fun hX => by rw [hX] at hP; exact star_fwd_l hL hP
  theorem star_fwd_l {rhs w} (h : GenL (starP P1 s1) rhs w) :
      starP P1 s1 none rhs → Star (Gen P1 s1) w :=
    match h with
    | .nil => fun _ => Star.nil
    | .consT _ => fun hP => by simp [starP] at hP
    | .consN hG1 hL2 =>
      match hL2 with
      | .nil => fun hP => by simp [starP, embS] at hP
      | .consT _ => fun hP => by simp [starP, embS] at hP
      | .consN hG2 hL3 =>
        match hL3 with
        | .consT _ => fun hP => by simp [starP, embS] at hP
        | .consN _ _ => fun hP => by simp [starP, embS] at hP
        | .nil => fun hP => by
            simp only [starP, embS, List.cons.injEq, Sum.inl.injEq, and_true,
              reduceCtorEq, false_or] at hP
            obtain ⟨hX', hY'⟩ := hP
            have h2 := star_fwd_g hG2 hY'
            have h1 := (star_some P1 s1).mp (hX' ▸ hG1)
            simpa using Star.step h1 h2
end

theorem star_bwd {w} (h : Star (Gen P1 s1) w) : Gen (starP P1 s1) none w := by
  induction h with
  | nil => exact Gen.mk (Or.inl rfl) GenL.nil
  | @step w1 w2 hw1 _ ih =>
    refine Gen.mk (Or.inr rfl) ?_
    have h1 : Gen (starP P1 s1) (embS s1) w1 := (star_some P1 s1).mpr hw1
    simpa using GenL.consN h1 (GenL.consN ih GenL.nil)

theorem cfl_star_gen {w} : Gen (starP P1 s1) none w ↔ Star (Gen P1 s1) w :=
  ⟨fun h => star_fwd_g P1 s1 h rfl, star_bwd P1 s1⟩

end StarS

/-- **§7.3 — CFL closed under Kleene star.** -/
theorem cfl_star {L : List T → Prop} (h : IsCFL L) : IsCFL (Star L) := by
  obtain ⟨N1, P1, s1, hL⟩ := h
  refine ⟨Option N1, starP P1 s1, none, fun w => ?_⟩
  rw [cfl_star_gen P1 s1]
  constructor
  · intro hs; induction hs with
    | nil => exact Star.nil
    | step hw1 _ ih => exact Star.step ((hL _).mp hw1) ih
  · intro hs; induction hs with
    | nil => exact Star.nil
    | step hw1 _ ih => exact Star.step ((hL _).mpr hw1) ih

/-- Sanity: the singleton language `{[t]}` is context-free — so `IsCFL` is
non-vacuous and the closure theorems above are not about an empty class. -/
theorem cfl_single (t : T) : IsCFL (fun w => w = [t]) := by
  refine ⟨Unit, fun _ rhs => rhs = [Sum.inr t], (), fun w => ?_⟩
  constructor
  · intro hw; subst hw; exact Gen.mk rfl (GenL.consT GenL.nil)
  · intro h
    cases h with | mk hP hL => subst hP; cases hL with | consT hL' => cases hL' with | nil => rfl

end CFL
