/-
SPDX-License-Identifier: MPL-2.0
Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

WokeGrammarPumping.lean — the FOUNDATION of the pumping lemma for context-free
languages (toward grammar-proofs.md §7.3 *non*-closure under ∩ / ¬). Mathlib has
the regular-language pumping lemma but NOT the CFL one, so this is built from
scratch in core Lean. This file is the verified engine; the final assembly
(repeated-nonterminal extraction ⇒ the pumping lemma ⇒ aⁿbⁿcⁿ ∉ CFL ⇒
non-closure) follows incrementally.

What is proved here (complete proofs — no holes, no escape hatches):
  • parse trees `PT` over a binary-normal-form grammar (`A → B C` or `A → t`);
  • `yield_bound` : a tree of height `h` yields a string of length `< 2^h` — so a
    long string forces a tall tree (the trigger for pumping);
  • one-hole contexts `Ctx` + `fill` (plug a tree into a context's hole);
  • `pumpIter` : a self-context `Ctx R A A v x` filled `i` times prepends `vⁱ`
    and appends `xⁱ` — the actual pumping operation;
  • `spine` / `spine_length` : the tallest root-to-leaf path has length `= height`;
  • `pigeon` : a finite pigeonhole (no Mathlib).

NEXT (assembly): `spine` longer than the nonterminal count ⇒ a repeated
nonterminal (pigeonhole) ⇒ navigate to the two nestings ⇒ outer-`Ctx` · pump-`Ctx`
· base ⇒ the pumping lemma via `pumpIter`.
-/

-- A grammar in binary normal form: every production is A → B C, A → t, or A → ε.
namespace Pump

variable {N T : Type}

/-- A production in binary normal form. -/
inductive BProd (N T : Type)
  | bin : N → N → BProd N T      -- A → B C
  | term : T → BProd N T          -- A → t
  | eps : BProd N T               -- A → ε

/-- Parse tree over a production relation `R : N → BProd N T → Prop`. -/
inductive PT (R : N → BProd N T → Prop) : N → List T → Type
  | bin {A B C w1 w2} : R A (BProd.bin B C) → PT R B w1 → PT R C w2 → PT R A (w1 ++ w2)
  | term {A t} : R A (BProd.term t) → PT R A [t]
  | eps {A} : R A BProd.eps → PT R A []

/-- Tree height (taller child + 1), using an explicit `if` so `omega` can reason
about it after a case split. -/
def ht {R : N → BProd N T → Prop} : {A : N} → {w : List T} → PT R A w → Nat
  | _, _, .bin _ t1 t2 => (if ht t2 ≤ ht t1 then ht t1 else ht t2) + 1
  | _, _, .term _ => 1
  | _, _, .eps _ => 1

/-- **Yield bound:** a tree of height `h` yields a string of length `< 2^h`
(binary branching ⇒ at most `2^(h-1)` leaves, each contributing ≤ 1 symbol). -/
theorem yield_bound {R : N → BProd N T → Prop} :
    ∀ {A w} (t : PT R A w), w.length < 2 ^ ht t := by
  intro A w t
  induction t with
  | @bin A B C w1 w2 _ t1 t2 ih1 ih2 =>
    have key : ∀ (a b : Nat), w1.length < 2 ^ a → w2.length < 2 ^ b →
        (w1 ++ w2).length < 2 ^ ((if b ≤ a then a else b) + 1) := by
      intro a b ha hb
      have ea : (2:Nat) ^ a ≤ 2 ^ (if b ≤ a then a else b) :=
        Nat.pow_le_pow_right (by omega) (by split <;> omega)
      have eb : (2:Nat) ^ b ≤ 2 ^ (if b ≤ a then a else b) :=
        Nat.pow_le_pow_right (by omega) (by split <;> omega)
      rw [List.length_append, Nat.pow_succ]; omega
    simpa [ht] using key (ht t1) (ht t2) ih1 ih2
  | term _ => simp [ht]
  | eps _ => simp [ht]

/-- A one-hole context: an `A`-rooted tree with a single `H`-shaped hole. Yields
`vl ++ (hole) ++ vr`. -/
inductive Ctx (R : N → BProd N T → Prop) (H : N) : N → List T → List T → Type
  | hole : Ctx R H H [] []
  | binL {A B C vl vr w2} :
      R A (BProd.bin B C) → Ctx R H B vl vr → PT R C w2 → Ctx R H A vl (vr ++ w2)
  | binR {A B C w1 vl vr} :
      R A (BProd.bin B C) → PT R B w1 → Ctx R H C vl vr → Ctx R H A (w1 ++ vl) vr

/-- Filling a context's hole with a tree. -/
def fill {R : N → BProd N T → Prop} {H : N} :
    {A : N} → {vl vr : List T} → Ctx R H A vl vr → {w : List T} → PT R H w →
    PT R A (vl ++ w ++ vr)
  | _, _, _, .hole, _, p => by simpa using p
  | _, _, _, .binL hp c t2, _, p => by
      have := PT.bin hp (fill c p) t2; simpa [List.append_assoc] using this
  | _, _, _, .binR hp t1 c, _, p => by
      have := PT.bin hp t1 (fill c p); simpa [List.append_assoc] using this

/-- `l` concatenated `i` times. -/
def cat (l : List T) (i : Nat) : List T := (List.replicate i l).flatten

@[simp] theorem cat_zero (l : List T) : cat l 0 = [] := rfl
theorem cat_succ_left (l : List T) (i : Nat) : cat l (i + 1) = l ++ cat l i := by
  simp [cat, List.replicate_succ]
theorem cat_succ_right (l : List T) (i : Nat) : cat l (i + 1) = cat l i ++ l := by
  simp [cat, List.replicate_succ', List.flatten_append]

/-- **Pump iteration:** a self-context `Ctx R A A v x` can be filled `i` times,
prepending `vⁱ` and appending `xⁱ`. -/
def pumpIter {R : N → BProd N T → Prop} {A : N} {v x : List T} (pc : Ctx R A A v x) :
    (i : Nat) → (w : List T) → PT R A w → PT R A (cat v i ++ w ++ cat x i)
  | 0, _, p => by simpa using p
  | i + 1, w, p => by
      have h := fill pc (pumpIter pc i w p)
      have ex : v ++ (cat v i ++ w ++ cat x i) ++ x = cat v (i+1) ++ w ++ cat x (i+1) := by
        rw [cat_succ_left v i, cat_succ_right x i]; simp [List.append_assoc]
      rw [ex] at h; exact h

/-! ### Spine and the repeated-nonterminal milestone -/

/-- The nonterminals along the tallest root-to-leaf path. Length = `ht t`. -/
def spine {R : N → BProd N T → Prop} : {A : N} → {w : List T} → PT R A w → List N
  | A, _, .term _ => [A]
  | A, _, .eps _ => [A]
  | A, _, .bin _ t1 t2 => A :: (if ht t2 ≤ ht t1 then spine t1 else spine t2)

theorem spine_length {R : N → BProd N T → Prop} :
    ∀ {A w} (t : PT R A w), (spine t).length = ht t := by
  intro A w t
  induction t with
  | term _ => simp [spine, ht]
  | eps _ => simp [spine, ht]
  | @bin A B C w1 w2 _ t1 t2 ih1 ih2 =>
    simp only [spine, ht, List.length_cons]
    by_cases hc : ht t2 ≤ ht t1
    · simp only [if_pos hc, ih1]
    · simp only [if_neg hc, ih2]

/-- Finite pigeonhole (no Mathlib): a list longer than `n` whose entries are all
`< n` has a repeated entry. -/
theorem pigeon : ∀ (n m : Nat) (f : Nat → Nat),
    (∀ i, i < m → f i < n) → n < m → ∃ i j, i < j ∧ j < m ∧ f i = f j := by
  intro n
  induction n with
  | zero => intro m f hf hnm; have := hf 0 (by omega); omega
  | succ n ih =>
    intro m f hf hnm
    by_cases hcol : ∃ j, j < m - 1 ∧ f j = f (m - 1)
    · obtain ⟨j, hj, hfj⟩ := hcol; exact ⟨j, m - 1, by omega, by omega, by omega⟩
    · have hcol' : ∀ j, j < m - 1 → f j ≠ f (m - 1) := fun j hj hfj => hcol ⟨j, hj, hfj⟩
      let g : Nat → Nat := fun i => if f i < f (m - 1) then f i else f i - 1
      have hg : ∀ i, i < m - 1 → g i < n := by
        intro i hi; have := hf i (by omega); have := hcol' i hi; have := hf (m - 1) (by omega)
        simp only [g]; by_cases hlt : f i < f (m - 1) <;> simp [hlt] <;> omega
      obtain ⟨i, j, hij, hjm, hgij⟩ := ih (m - 1) g hg (by omega)
      refine ⟨i, j, hij, by omega, ?_⟩
      have := hcol' i (by omega); have := hcol' j hjm
      simp only [g] at hgij
      by_cases hi : f i < f (m - 1) <;> by_cases hj : f j < f (m - 1) <;>
        simp [hi, hj] at hgij <;> omega

-- NEXT (assembly turn): `spine`-pigeonhole ⇒ a repeated nonterminal, then
-- navigate the tree at the two positions to extract `Ctx`/`Ctx`/`PT` (outer
-- context · pump context · base) and conclude the pumping lemma via `pumpIter`.

end Pump
