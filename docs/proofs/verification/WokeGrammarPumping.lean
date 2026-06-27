/-
SPDX-License-Identifier: MPL-2.0
Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

WokeGrammarPumping.lean — the pumping lemma for context-free languages, built
from scratch in core Lean (toward grammar-proofs.md §7.3 *non*-closure under
∩ / ¬). Mathlib has the regular-language pumping lemma but NOT the CFL one.

What is proved here (complete proofs — no holes, no escape hatches):
  • parse trees `PT` over a binary-normal-form grammar (`A → B C` or `A → t`);
  • `yield_bound` : a tree of height `h` yields a string of length `< 2^h` — so a
    long string forces a tall tree (the trigger for pumping);
  • one-hole contexts `Ctx` + `fill` (plug a tree into a context's hole) and
    `Ctx.comp` (context composition);
  • `pumpIter` : a self-context `Ctx R A A v x` filled `i` times prepends `vⁱ`
    and appends `xⁱ` — the actual pumping operation;
  • `descend` / `ht_descend` / `nodeNT_add` : navigate the tallest spine, with the
    subtree-height law and the depth-composition law for repeated nonterminals;
  • `pigeon` : a finite pigeonhole (no Mathlib);
  • `cfl_pumping` : THE pumping lemma — for an ε-free binary-normal-form grammar
    with `card` nonterminals, any word `z ∈ L(S)` of length `≥ 2^(card+1)` splits
    as `z = u v w x y` with `1 ≤ |v x|`, `|v w x| ≤ 2^(card+1)`, and
    `u vⁱ w xⁱ y ∈ L(S)` for every `i`.

Trust base: only the three standard classical kernel constants `propext`,
`Classical.choice`, and `Quot.sound` — the same foundations Mathlib relies on
(`Classical.choice` enters through the `pigeon` case split). There are no holes
and no project-specific assumptions; every step is checked by Lean's kernel.

NEXT: the finite-grammar `IsCFL`, `aⁿbⁿcⁿ ∉ CFL` via `cfl_pumping`, and the
∩ / ¬ non-closure corollary.
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

/-! ### Navigation toolkit (context composition + spine descent) -/

/-- **Context composition.** Plugging an inner `X`-context (with `Y`-hole) into the
hole of an outer `A`-context (with `X`-hole) yields an `A`-context with `Y`-hole. -/
def Ctx.comp {R : N → BProd N T → Prop} {Y : N} :
    {X A : N} → {a b : List T} → Ctx R X A a b → {c d : List T} → Ctx R Y X c d →
    Ctx R Y A (a ++ c) (d ++ b)
  | _, _, _, _, .hole, _, _, i => by simpa using i
  | _, _, _, _, .binL hp o' t2, _, _, i => by
      have := Ctx.binL hp (Ctx.comp o' i) t2; simpa [List.append_assoc] using this
  | _, _, _, _, .binR hp t1 o', _, _, i => by
      have := Ctx.binR hp t1 (Ctx.comp o' i); simpa [List.append_assoc] using this

/-- A spine node reached by descending: the nonterminal `X` there, the one-hole
context above it, the subtree below it, and the yield-splitting equation. -/
structure Below (R : N → BProd N T → Prop) (A : N) (w : List T) where
  X : N
  cl : List T
  cr : List T
  m : List T
  ctx : Ctx R X A cl cr
  sub : PT R X m
  hy : w = cl ++ m ++ cr

/-- **Spine descent.** `descend d t` follows the tallest-child path `d` steps,
returning the node reached (or the leaf, if the spine is shorter than `d`).
Recursion is on the depth `d`, so `descend (d+1) (bin ..)` reduces definitionally. -/
def descend {R : N → BProd N T → Prop} :
    (d : Nat) → {A : N} → {w : List T} → PT R A w → Below R A w
  | 0, A, w, t => ⟨A, [], [], w, Ctx.hole, t, by simp⟩
  | d + 1, _, _, t =>
      match t with
      | PT.bin (w1 := w1) (w2 := w2) hp t1 t2 =>
          if ht t2 ≤ ht t1 then
            let b := descend d t1
            ⟨b.X, b.cl, b.cr ++ w2, b.m, Ctx.binL hp b.ctx t2, b.sub, by
              have := b.hy; simp [this, List.append_assoc]⟩
          else
            let b := descend d t2
            ⟨b.X, w1 ++ b.cl, b.cr, b.m, Ctx.binR hp t1 b.ctx, b.sub, by
              have := b.hy; simp [this, List.append_assoc]⟩
      | PT.term hp => ⟨_, [], [], _, Ctx.hole, PT.term hp, by simp⟩
      | PT.eps hp => ⟨_, [], [], _, Ctx.hole, PT.eps hp, by simp⟩

/-- The nonterminal at spine depth `d`. -/
def nodeNT {R : N → BProd N T → Prop} {A : N} {w : List T} (t : PT R A w) (d : Nat) : N :=
  (descend d t).X

theorem descend_zero {R : N → BProd N T → Prop} {A : N} {w : List T}
    (t : PT R A w) : descend 0 t = ⟨A, [], [], w, Ctx.hole, t, by simp⟩ := rfl

/-- Height of the descended subtree: exactly `ht t - d`, as long as the spine is
long enough (`d < ht t`) that no clamping at a leaf occurs. -/
theorem ht_descend {R : N → BProd N T → Prop} :
    ∀ (d : Nat) {A w} (t : PT R A w), d < ht t → ht (descend d t).sub = ht t - d := by
  intro d
  induction d with
  | zero => intro A w t _; simp [descend_zero]
  | succ d ih =>
    intro A w t hd
    cases t with
    | term _ => simp only [ht] at hd; omega
    | eps _ => simp only [ht] at hd; omega
    | bin hp t1 t2 =>
      by_cases hc : ht t2 ≤ ht t1
      · have hbin : ht (PT.bin hp t1 t2) = ht t1 + 1 := by simp only [ht]; rw [if_pos hc]
        have hlt : d < ht t1 := by rw [hbin] at hd; omega
        simp only [descend]; rw [if_pos hc]
        show ht (descend d t1).sub = ht (PT.bin hp t1 t2) - (d + 1)
        rw [ih t1 hlt, hbin]; omega
      · have hbin : ht (PT.bin hp t1 t2) = ht t2 + 1 := by simp only [ht]; rw [if_neg hc]
        have hlt : d < ht t2 := by rw [hbin] at hd; omega
        simp only [descend]; rw [if_neg hc]
        show ht (descend d t2).sub = ht (PT.bin hp t1 t2) - (d + 1)
        rw [ih t2 hlt, hbin]; omega

/-- **Descent composition (nonterminal level).** Descending `p + k` steps lands on
the same nonterminal as descending `p` then `k` more from there. -/
theorem nodeNT_add {R : N → BProd N T → Prop} :
    ∀ (p : Nat) {A w} (t : PT R A w) (k : Nat), p < ht t →
      nodeNT t (p + k) = nodeNT (descend p t).sub k := by
  intro p
  induction p with
  | zero => intro A w t k _; simp [nodeNT, descend_zero]
  | succ p ih =>
    intro A w t k hp
    cases t with
    | term _ => simp only [ht] at hp; omega
    | eps _ => simp only [ht] at hp; omega
    | bin hpr t1 t2 =>
      by_cases hc : ht t2 ≤ ht t1
      · have hbin : ht (PT.bin hpr t1 t2) = ht t1 + 1 := by simp only [ht]; rw [if_pos hc]
        have hlt : p < ht t1 := by rw [hbin] at hp; omega
        show (descend (p + 1 + k) (PT.bin hpr t1 t2)).X
            = (descend k (descend (p + 1) (PT.bin hpr t1 t2)).sub).X
        rw [show p + 1 + k = (p + k) + 1 from by omega]
        simp only [descend]; rw [if_pos hc, if_pos hc]
        exact ih t1 k hlt
      · have hbin : ht (PT.bin hpr t1 t2) = ht t2 + 1 := by simp only [ht]; rw [if_neg hc]
        have hlt : p < ht t2 := by rw [hbin] at hp; omega
        show (descend (p + 1 + k) (PT.bin hpr t1 t2)).X
            = (descend k (descend (p + 1) (PT.bin hpr t1 t2)).sub).X
        rw [show p + 1 + k = (p + k) + 1 from by omega]
        simp only [descend]; rw [if_neg hc, if_neg hc]
        exact ih t2 k hlt

/-- In an ε-free grammar (no `A → ε` productions), every parse tree yields a
non-empty string. This is what makes the pumped portion `vx` non-empty. -/
theorem yield_nonempty {R : N → BProd N T → Prop} (hRε : ∀ A, ¬ R A BProd.eps) :
    ∀ {A w} (t : PT R A w), w ≠ [] := by
  intro A w t
  induction t with
  | @bin A B C w1 w2 _ t1 t2 ih1 ih2 =>
    intro h; rcases List.append_eq_nil_iff.mp h with ⟨h1, _⟩; exact ih1 h1
  | term _ => simp
  | eps hp => exact absurd hp (hRε _)

/-- **Sibling non-emptiness.** Descending `≥ 1` step into a `bin` node peels off a
sibling subtree, which (ε-free) contributes `≥ 1` symbol to `cl ++ cr`. -/
theorem descend_sibling_nonempty {R : N → BProd N T → Prop}
    (hRε : ∀ A, ¬ R A BProd.eps) :
    ∀ {A w} (t : PT R A w) (d : Nat), 2 ≤ ht t → 1 ≤ d →
      1 ≤ (descend d t).cl.length + (descend d t).cr.length := by
  intro A w t d h2 h1
  cases t with
  | term _ => simp only [ht] at h2; omega
  | eps _ => simp only [ht] at h2; omega
  | bin hp t1 t2 =>
    rename_i B C w1 w2
    cases d with
    | zero => omega
    | succ d =>
      by_cases hc : ht t2 ≤ ht t1
      · have hne : w2 ≠ [] := yield_nonempty hRε t2
        have e : (descend (d + 1) (PT.bin hp t1 t2)).cr = (descend d t1).cr ++ w2 := by
          simp only [descend, if_pos hc]
        rw [e, List.length_append]
        have : 1 ≤ w2.length := by cases w2 with | nil => exact absurd rfl hne | cons => simp
        omega
      · have hne : w1 ≠ [] := yield_nonempty hRε t1
        have e : (descend (d + 1) (PT.bin hp t1 t2)).cl = w1 ++ (descend d t2).cl := by
          simp only [descend, if_neg hc]
        rw [e, List.length_append]
        have : 1 ≤ w1.length := by cases w1 with | nil => exact absurd rfl hne | cons => simp
        omega

/-! ### The pumping lemma for context-free languages -/

/-- **Pumping lemma (CFL).** For a binary-normal-form grammar with finitely many
nonterminals (`enum : N → Fin card`, here as `enum : N → ℕ` bounded by `card`) and
no ε-productions, any sufficiently long word `z ∈ L(S)` (length `≥ 2^(card+1)`)
splits as `z = u v w x y` with:
  • `1 ≤ |v x|`            — the pumped part is non-empty;
  • `|v w x| ≤ 2^(card+1)` — the pumped window is bounded;
  • `u vⁱ w xⁱ y ∈ L(S)`   for every `i`.
Built from scratch in core Lean (Mathlib has only the *regular* pumping lemma). -/
theorem cfl_pumping {R : N → BProd N T → Prop} {S : N}
    (enum : N → Nat) (card : Nat) (hcard : ∀ A, enum A < card)
    (henj : ∀ A B, enum A = enum B → A = B) (hRε : ∀ A, ¬ R A BProd.eps)
    {z : List T} (t : PT R S z) (hz : 2 ^ (card + 1) ≤ z.length) :
    ∃ u v w x y : List T,
      z = u ++ v ++ w ++ x ++ y ∧
      1 ≤ (v ++ x).length ∧
      (v ++ w ++ x).length ≤ 2 ^ (card + 1) ∧
      ∀ i, Nonempty (PT R S (u ++ cat v i ++ w ++ cat x i ++ y)) := by
  -- A long yield forces a tall tree.
  have hyb : z.length < 2 ^ ht t := yield_bound t
  have hht : card + 1 < ht t := by
    rcases Nat.lt_or_ge (card + 1) (ht t) with h | h
    · exact h
    · exfalso
      have : (2:Nat) ^ ht t ≤ 2 ^ (card + 1) := Nat.pow_le_pow_right (by omega) h
      omega
  -- Descend to the window root (height `card+1` above the deepest leaf).
  have hd0 : ht t - (card + 1) < ht t := by omega
  let W := descend (ht t - (card + 1)) t
  have htw : ht W.sub = card + 1 := by
    have h := ht_descend (ht t - (card + 1)) t hd0
    show ht (descend (ht t - (card + 1)) t).sub = card + 1
    rw [h]; omega
  -- Pigeonhole on the `card+1` nonterminals along the window's spine.
  obtain ⟨p, q, hpq, hqm, hfeq⟩ :=
    pigeon card (card + 1) (fun i => enum (nodeNT W.sub i)) (fun i _ => hcard _) (by omega)
  have hXeq : nodeNT W.sub p = nodeNT W.sub q := henj _ _ hfeq
  have hptw : p < ht W.sub := by rw [htw]; omega
  let Wp := descend p W.sub
  let DP := descend (q - p) Wp.sub
  have hsubp : ht Wp.sub = (card + 1) - p := by
    have h := ht_descend p W.sub hptw
    rw [htw] at h; exact h
  -- The two spine occurrences carry the same nonterminal.
  have hadd : nodeNT W.sub q = nodeNT (descend p W.sub).sub (q - p) := by
    have h := nodeNT_add p W.sub (q - p) hptw
    rw [show p + (q - p) = q from by omega] at h; exact h
  have hDPX : DP.X = Wp.X := by
    have e1 : DP.X = nodeNT W.sub q := hadd.symm
    have e2 : Wp.X = nodeNT W.sub p := rfl
    rw [e1, e2, hXeq]
  -- The pump context, base subtree, and outer context.
  let pump : Ctx R Wp.X Wp.X DP.cl DP.cr :=
    cast (congrArg (fun X => Ctx R X Wp.X DP.cl DP.cr) hDPX) DP.ctx
  let base : PT R Wp.X DP.m := cast (congrArg (fun X => PT R X DP.m) hDPX) DP.sub
  let outer : Ctx R Wp.X S (W.cl ++ Wp.cl) (Wp.cr ++ W.cr) := Ctx.comp W.ctx Wp.ctx
  refine ⟨W.cl ++ Wp.cl, DP.cl, DP.m, DP.cr, Wp.cr ++ W.cr, ?_, ?_, ?_, ?_⟩
  · -- z = u v w x y  (combine the three yield-splittings; `congrArg` avoids
    -- rewriting the yields, which are locked inside the `Below` dependent types)
    calc z = (W.cl ++ W.m) ++ W.cr := W.hy
      _ = (W.cl ++ (Wp.cl ++ Wp.m ++ Wp.cr)) ++ W.cr :=
            congrArg (fun s => (W.cl ++ s) ++ W.cr) Wp.hy
      _ = (W.cl ++ (Wp.cl ++ (DP.cl ++ DP.m ++ DP.cr) ++ Wp.cr)) ++ W.cr :=
            congrArg (fun s => (W.cl ++ (Wp.cl ++ s ++ Wp.cr)) ++ W.cr) DP.hy
      _ = (W.cl ++ Wp.cl) ++ DP.cl ++ DP.m ++ DP.cr ++ (Wp.cr ++ W.cr) := by
            simp [List.append_assoc]
  · -- 1 ≤ |v x|  (the sibling peeled off between the two occurrences is non-empty)
    have h2 : 2 ≤ ht Wp.sub := by rw [hsubp]; omega
    have h1 : 1 ≤ q - p := by omega
    have hsib := descend_sibling_nonempty hRε Wp.sub (q - p) h2 h1
    rw [List.length_append]; exact hsib
  · -- |v w x| ≤ 2^(card+1)
    have hyb2 : Wp.m.length < 2 ^ ht Wp.sub := yield_bound Wp.sub
    have hpow : (2:Nat) ^ ht Wp.sub ≤ 2 ^ (card + 1) := by
      rw [hsubp]; exact Nat.pow_le_pow_right (by omega) (by omega)
    have hlen : (DP.cl ++ DP.m ++ DP.cr).length = Wp.m.length := by rw [← DP.hy]
    rw [hlen]; omega
  · -- ∀ i, u vⁱ w xⁱ y ∈ L(S)
    intro i
    exact ⟨by
      have h := fill outer (pumpIter pump i DP.m base)
      simpa [List.append_assoc] using h⟩

end Pump
