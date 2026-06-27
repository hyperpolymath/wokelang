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
    `u vⁱ w xⁱ y ∈ L(S)` for every `i`;
  • `IsCFL` + `anbncn_not_cfl` : the canonical application — `aⁿbⁿcⁿ` is NOT
    context-free. Apply `cfl_pumping` to `aᵖbᵖcᵖ`; pumping down to `i = 0` forces
    equal letter-counts in the pumped part, so it spans an `a` and a `c`, which
    (positional core `prefix_pure`/`abc_window`) makes `|v w x| > p` — contradicting
    `|v w x| ≤ p`.
  • `cfl_not_closed_inter` : THE non-closure theorem — the context-free languages
    are not closed under intersection. Witnesses `L₁ = {aⁱbⁱcʲ}` and `L₂ = {aᵐbⁿcⁿ}`
    are both context-free (explicit ε-free binary-normal-form grammars `R1`, `R2`,
    each with full soundness via tree inversion + completeness via tree building),
    but `L₁ ∩ L₂ = {aⁿbⁿcⁿ}`, which `anbncn_not_cfl` rules out. (With CFL ∪-closure
    and De Morgan this also refutes closure under complement.)

Trust base: only the three standard classical kernel constants `propext`,
`Classical.choice`, and `Quot.sound` — the same foundations Mathlib relies on
(`Classical.choice` enters through the `pigeon` case split). There are no holes
and no project-specific assumptions; every step is checked by Lean's kernel.
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
theorem yield_nonempty {R : N → BProd N T → Prop} (hRε : ∀ A, ¬ R A BProd.eps)
    {A : N} {w : List T} (t : PT R A w) : w ≠ [] := by
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

/-! ### Application: `aⁿbⁿcⁿ` is not context-free -/

/-- The terminal alphabet `{a, b, c}`. -/
inductive Letter | a | b | c
  deriving DecidableEq

open Letter List

/-- A language over `{a,b,c}` is **context-free** iff some ε-free binary-normal-form
grammar with finitely many nonterminals generates exactly it. (Every ε-free CFL has
such a grammar — ε-free Chomsky normal form — so this is the standard CFL class for
ε-free languages, taken here as the definition.) -/
def IsCFL (L : List Letter → Prop) : Prop :=
  ∃ (M : Type) (R : M → BProd M Letter → Prop) (S : M) (enum : M → Nat) (card : Nat),
    (∀ A, enum A < card) ∧ (∀ A B, enum A = enum B → A = B) ∧
    (∀ A, ¬ R A BProd.eps) ∧ (∀ z, L z ↔ Nonempty (PT R S z))

/-- `aⁿbⁿcⁿ`. -/
def abc (n : Nat) : List Letter :=
  replicate n a ++ replicate n b ++ replicate n c

theorem count_repl_ne {x y : Letter} (n : Nat) (h : x ≠ y) :
    count x (replicate n y) = 0 := by
  rw [count_eq_zero]; intro hm; exact h (eq_of_mem_replicate hm)

theorem count_abc (ℓ : Letter) (n : Nat) : count ℓ (abc n) = n := by
  unfold abc
  rw [count_append, count_append]
  cases ℓ <;>
    rw [count_replicate_self] <;>
    rw [count_repl_ne _ (by decide), count_repl_ne _ (by decide)] <;>
    omega

theorem length_abc (n : Nat) : (abc n).length = 3 * n := by
  unfold abc; rw [length_append, length_append, length_replicate,
    length_replicate, length_replicate]; omega

/-- Every element of a `{a,b,c}`-list is `a`, `b`, or `c`, so its length is the sum
of the three letter-counts. -/
theorem length_eq_counts (l : List Letter) :
    l.length = count a l + count b l + count c l := by
  induction l with
  | nil => simp
  | cons hd t ih => cases hd <;> simp [length_cons] <;> omega

/-- **Positional core.** In `replicate n1 k1 ++ replicate n2 k2 ++ replicate n3 k3`,
if the middle segment `m` of a split `u ++ m ++ y` contains a `k1` (and `k1` differs
from `k2`, `k3`), then the prefix `u` contains no `k2` — it lies wholly in the first
block. Proved by induction on the prefix; no indexing needed. -/
theorem prefix_pure {k1 k2 k3 : Letter} (h12 : k1 ≠ k2) (h13 : k1 ≠ k3) :
    ∀ (n1 n2 n3 : Nat) (u m y : List Letter),
      u ++ m ++ y = replicate n1 k1 ++ replicate n2 k2 ++ replicate n3 k3 →
      k1 ∈ m → count k2 u = 0 := by
  intro n1 n2 n3 u
  induction u generalizing n1 with
  | nil => intro m y _ _; simp
  | cons hd u' ih =>
    intro m y heq hmem
    cases n1 with
    | zero =>
      exfalso
      have hin : k1 ∈ (hd :: u') ++ m ++ y :=
        mem_append.mpr (Or.inl (mem_append.mpr (Or.inr hmem)))
      rw [heq] at hin
      simp only [replicate, nil_append, mem_append, mem_replicate] at hin
      rcases hin with ⟨_, h⟩ | ⟨_, h⟩
      · exact h12 h
      · exact h13 h
    | succ n1' =>
      rw [replicate_succ] at heq
      simp only [cons_append] at heq
      obtain ⟨rfl, heq'⟩ := List.cons.inj heq
      rw [count_cons_of_ne h12]
      exact ih n1' m y heq' hmem

/-- **The pumping window spans `a`…`c`.** If a split `abc p = u ++ m ++ y` has `m`
containing both an `a` and a `c`, then `m` already contains the whole `b`-block, so
`p < |m|`. -/
theorem abc_window {p : Nat} {u m y : List Letter}
    (heq : abc p = u ++ m ++ y) (ha : a ∈ m) (hc : c ∈ m) : p < m.length := by
  have hbu : count b u = 0 :=
    prefix_pure (by decide) (by decide) p p p u m y heq.symm ha
  have hby : count b y = 0 := by
    have hrev : (replicate p c ++ replicate p b ++ replicate p a : List Letter)
        = y.reverse ++ m.reverse ++ u.reverse := by
      have hr := congrArg List.reverse heq
      simpa [abc, reverse_append, reverse_replicate, List.append_assoc] using hr
    have hcm : c ∈ m.reverse := mem_reverse.mpr hc
    have := prefix_pure (k1 := c) (k2 := b) (k3 := a) (by decide) (by decide)
      p p p y.reverse m.reverse u.reverse hrev.symm hcm
    rwa [count_reverse] at this
  have hbz : count b (abc p) = p := count_abc b p
  rw [heq, count_append, count_append, hbu, hby] at hbz
  have hcm1 : 1 ≤ count c m := one_le_count_iff.mpr hc
  have hlen := length_eq_counts m
  omega

/-- **`aⁿbⁿcⁿ` is not context-free.** The canonical witness that the context-free
languages are not closed under intersection / complement: apply `cfl_pumping` to
`aᵖbᵖcᵖ` (`p = 2^(card+1)`); pumping down to `i = 0` forces equal counts in the
pumped part, so it spans an `a` and a `c`, contradicting `|v w x| ≤ p`. -/
theorem anbncn_not_cfl : ¬ IsCFL (fun z => ∃ n, 1 ≤ n ∧ z = abc n) := by
  rintro ⟨M, R, S, enum, card, hcard, henj, hRε, hgen⟩
  have hp1 : 1 ≤ 2 ^ (card + 1) := Nat.one_le_two_pow
  obtain ⟨t⟩ : Nonempty (PT R S (abc (2 ^ (card + 1)))) :=
    (hgen _).mp ⟨2 ^ (card + 1), hp1, rfl⟩
  have hlenz : 2 ^ (card + 1) ≤ (abc (2 ^ (card + 1))).length := by
    rw [length_abc]; omega
  obtain ⟨u, v, w, x, y, hz, hvx, hvwx, hpump⟩ :=
    cfl_pumping enum card hcard henj hRε t hlenz
  -- Pump down to i = 0: u w y ∈ L.
  obtain ⟨t0⟩ := hpump 0
  simp only [cat_zero, List.append_nil] at t0
  obtain ⟨m0, _, h0⟩ := (hgen _).mpr ⟨t0⟩
  -- For every letter, the counts removed by deleting `v` and `x` agree.
  have key : ∀ ℓ : Letter, count ℓ v + count ℓ x = 2 ^ (card + 1) - m0 := by
    intro ℓ
    have ep : count ℓ (abc (2 ^ (card + 1))) = 2 ^ (card + 1) := count_abc ℓ _
    have em : count ℓ (abc m0) = m0 := count_abc ℓ _
    rw [hz] at ep
    rw [← h0] at em
    simp only [count_append] at ep em
    omega
  -- `|v x| = 3·(p - m0) ≥ 1`, so `p - m0 ≥ 1`: the pumped part has an `a` and a `c`.
  have hvxlen : (v ++ x).length = 3 * (2 ^ (card + 1) - m0) := by
    have hsum := length_eq_counts (v ++ x)
    simp only [count_append] at hsum
    rw [hsum, key a, key b, key c]; omega
  have hk1 : 1 ≤ 2 ^ (card + 1) - m0 := by
    rw [hvxlen] at hvx; omega
  -- Hence `a` and `c` both occur in `v ++ w ++ x`.
  have hca : 1 ≤ count a (v ++ w ++ x) := by
    have := key a; simp only [count_append]; omega
  have hcc : 1 ≤ count c (v ++ w ++ x) := by
    have := key c; simp only [count_append]; omega
  have hain : a ∈ v ++ w ++ x := one_le_count_iff.mp hca
  have hcin : c ∈ v ++ w ++ x := one_le_count_iff.mp hcc
  -- `v w x` is the window of `abc p`, so it spans `a`…`c` and is longer than `p`.
  have hwin : abc (2 ^ (card + 1)) = u ++ (v ++ w ++ x) ++ y := by
    rw [hz]; simp [List.append_assoc]
  have hgt := abc_window hwin hain hcin
  omega

/-! ### CFLs are not closed under intersection / complement — explicit witnesses

`L₁ = { aⁱbⁱcʲ : i,j ≥ 1 }` and `L₂ = { aᵐbⁿcⁿ : m,n ≥ 1 }` are both context-free
(ε-free binary-normal-form grammars below), but `L₁ ∩ L₂ = { aⁿbⁿcⁿ }`, which is
not (`anbncn_not_cfl`). -/

/-- `aⁱbⁱ`. -/
def ab (i : Nat) : List Letter := replicate i a ++ replicate i b

theorem ab_cons (i : Nat) : [a] ++ (ab i ++ [b]) = ab (i + 1) := by
  have hb : replicate i b ++ [b] = replicate (i + 1) b := replicate_succ'.symm
  have ha : [a] ++ replicate i a = replicate (i + 1) a := by rw [replicate_succ]; rfl
  simp only [ab, List.append_assoc]
  rw [hb, ← List.append_assoc, ha]

/-- Nonterminals for `L₁`'s grammar. -/
inductive M1 | S | X | Z | Y | Ta | Tb | Tc
  deriving DecidableEq

/-- Productions: `S → X Y`, `X → a b | a Z`, `Z → X b`, `Y → c | c Y`, plus the
single-terminal rules. Binary normal form, ε-free. -/
inductive R1 : M1 → BProd M1 Letter → Prop
  | s   : R1 .S  (.bin .X .Y)
  | xab : R1 .X  (.bin .Ta .Tb)
  | xaz : R1 .X  (.bin .Ta .Z)
  | zxb : R1 .Z  (.bin .X .Tb)
  | ycy : R1 .Y  (.bin .Tc .Y)
  | yc  : R1 .Y  (.term .c)
  | ta  : R1 .Ta (.term .a)
  | tb  : R1 .Tb (.term .b)
  | tc  : R1 .Tc (.term .c)

/-- Per-nonterminal language characterization. -/
def Char1 : M1 → List Letter → Prop
  | .S,  w => ∃ i j, 1 ≤ i ∧ 1 ≤ j ∧ w = ab i ++ replicate j c
  | .X,  w => ∃ i, 1 ≤ i ∧ w = ab i
  | .Z,  w => ∃ i, 1 ≤ i ∧ w = ab i ++ [b]
  | .Y,  w => ∃ j, 1 ≤ j ∧ w = replicate j c
  | .Ta, w => w = [a]
  | .Tb, w => w = [b]
  | .Tc, w => w = [c]

/-- **Soundness.** Every parse tree's yield lies in its nonterminal's language —
proved by one structural induction with inversion on the root production. -/
theorem sound_all1 {A : M1} {w : List Letter} (t : PT R1 A w) : Char1 A w := by
  induction t with
  | @bin A B C w1 w2 h _ _ ih1 ih2 =>
    cases h with
    | s => obtain ⟨i, hi, e1⟩ := ih1; obtain ⟨j, hj, e2⟩ := ih2
           exact ⟨i, j, hi, hj, by rw [e1, e2]⟩
    | xab => exact ⟨1, Nat.le_refl 1,
               by rw [show w1 = [a] from ih1, show w2 = [b] from ih2]; simp [ab, replicate_succ]⟩
    | xaz => obtain ⟨i, hi, e2⟩ := ih2
             exact ⟨i + 1, by omega, by rw [show w1 = [a] from ih1, e2, ab_cons]⟩
    | zxb => obtain ⟨i, hi, e1⟩ := ih1
             exact ⟨i, hi, by rw [e1, show w2 = [b] from ih2]⟩
    | ycy => obtain ⟨j, hj, e2⟩ := ih2
             exact ⟨j + 1, by omega, by rw [show w1 = [c] from ih1, e2]; simp [replicate_succ]⟩
  | @term A ltr h =>
    cases h with
    | yc => exact ⟨1, Nat.le_refl 1, by simp [replicate_succ]⟩
    | ta => rfl
    | tb => rfl
    | tc => rfl
  | @eps A h => cases h

def enum1 : M1 → Nat
  | .S => 0 | .X => 1 | .Z => 2 | .Y => 3 | .Ta => 4 | .Tb => 5 | .Tc => 6

/-- **Completeness for `X`:** a tree for every `aⁱ⁺¹bⁱ⁺¹`. -/
theorem tree_X1 : ∀ i, Nonempty (PT R1 .X (ab (i + 1))) := by
  intro i
  induction i with
  | zero => exact ⟨(PT.bin .xab (.term .ta) (.term .tb) : PT R1 .X ([a] ++ [b]))⟩
  | succ m ih =>
    obtain ⟨tx⟩ := ih
    have tz : PT R1 .Z (ab (m + 1) ++ [b]) := .bin .zxb tx (.term .tb)
    have tx2 : PT R1 .X ([a] ++ (ab (m + 1) ++ [b])) := .bin .xaz (.term .ta) tz
    rw [ab_cons] at tx2; exact ⟨tx2⟩

/-- **Completeness for `Y`:** a tree for every `cʲ⁺¹`. -/
theorem tree_Y1 : ∀ j, Nonempty (PT R1 .Y (replicate (j + 1) c)) := by
  intro j
  induction j with
  | zero => exact ⟨.term .yc⟩
  | succ m ih =>
    obtain ⟨ty⟩ := ih
    have h : PT R1 .Y ([c] ++ replicate (m + 1) c) := .bin .ycy (.term .tc) ty
    rw [show [c] ++ replicate (m + 1) c = replicate (m + 2) c from by simp [replicate_succ]] at h
    exact ⟨h⟩

/-- `L₁ = { aⁱbⁱcʲ : i,j ≥ 1 }`. -/
def L1 : List Letter → Prop := fun w => ∃ i j, 1 ≤ i ∧ 1 ≤ j ∧ w = ab i ++ replicate j c

theorem isCFL_L1 : IsCFL L1 := by
  refine ⟨M1, R1, .S, enum1, 7, ?_, ?_, ?_, ?_⟩
  · intro A; cases A <;> decide
  · intro A B; cases A <;> cases B <;> decide
  · intro A; cases A <;> (intro h; cases h)
  · intro w
    constructor
    · rintro ⟨i, j, hi, hj, rfl⟩
      obtain ⟨i', rfl⟩ : ∃ i', i = i' + 1 := ⟨i - 1, by omega⟩
      obtain ⟨j', rfl⟩ : ∃ j', j = j' + 1 := ⟨j - 1, by omega⟩
      obtain ⟨tx⟩ := tree_X1 i'; obtain ⟨ty⟩ := tree_Y1 j'
      exact ⟨.bin .s tx ty⟩
    · rintro ⟨t⟩; exact sound_all1 t

/-! #### `L₂ = { aᵐbⁿcⁿ : m,n ≥ 1 }` — mirror grammar (a⁺ then balanced bc) -/

/-- `bⁿcⁿ`. -/
def bc (i : Nat) : List Letter := replicate i b ++ replicate i c

theorem bc_cons (i : Nat) : [b] ++ (bc i ++ [c]) = bc (i + 1) := by
  have hc : replicate i c ++ [c] = replicate (i + 1) c := replicate_succ'.symm
  have hb : [b] ++ replicate i b = replicate (i + 1) b := by rw [replicate_succ]; rfl
  simp only [bc, List.append_assoc]
  rw [hc, ← List.append_assoc, hb]

inductive M2 | S | A2 | W | Z2 | Ta | Tb | Tc
  deriving DecidableEq

inductive R2 : M2 → BProd M2 Letter → Prop
  | s   : R2 .S  (.bin .A2 .W)
  | aa  : R2 .A2 (.term .a)
  | aaa : R2 .A2 (.bin .Ta .A2)
  | wbc : R2 .W  (.bin .Tb .Tc)
  | wbz : R2 .W  (.bin .Tb .Z2)
  | zwc : R2 .Z2 (.bin .W .Tc)
  | ta  : R2 .Ta (.term .a)
  | tb  : R2 .Tb (.term .b)
  | tc  : R2 .Tc (.term .c)

def Char2 : M2 → List Letter → Prop
  | .S,  w => ∃ m n, 1 ≤ m ∧ 1 ≤ n ∧ w = replicate m a ++ bc n
  | .A2, w => ∃ m, 1 ≤ m ∧ w = replicate m a
  | .W,  w => ∃ n, 1 ≤ n ∧ w = bc n
  | .Z2, w => ∃ n, 1 ≤ n ∧ w = bc n ++ [c]
  | .Ta, w => w = [a]
  | .Tb, w => w = [b]
  | .Tc, w => w = [c]

theorem sound_all2 {A : M2} {w : List Letter} (t : PT R2 A w) : Char2 A w := by
  induction t with
  | @bin A B C w1 w2 h _ _ ih1 ih2 =>
    cases h with
    | s => obtain ⟨m, hm, e1⟩ := ih1; obtain ⟨n, hn, e2⟩ := ih2
           exact ⟨m, n, hm, hn, by rw [e1, e2]⟩
    | aaa => obtain ⟨m, hm, e2⟩ := ih2
             exact ⟨m + 1, by omega, by rw [show w1 = [a] from ih1, e2]; simp [replicate_succ]⟩
    | wbc => exact ⟨1, Nat.le_refl 1,
               by rw [show w1 = [b] from ih1, show w2 = [c] from ih2]; simp [bc, replicate_succ]⟩
    | wbz => obtain ⟨n, hn, e2⟩ := ih2
             exact ⟨n + 1, by omega, by rw [show w1 = [b] from ih1, e2, bc_cons]⟩
    | zwc => obtain ⟨n, hn, e1⟩ := ih1
             exact ⟨n, hn, by rw [e1, show w2 = [c] from ih2]⟩
  | @term A ltr h =>
    cases h with
    | aa => exact ⟨1, Nat.le_refl 1, by simp [replicate_succ]⟩
    | ta => rfl
    | tb => rfl
    | tc => rfl
  | @eps A h => cases h

def enum2 : M2 → Nat
  | .S => 0 | .A2 => 1 | .W => 2 | .Z2 => 3 | .Ta => 4 | .Tb => 5 | .Tc => 6

theorem tree_A2' : ∀ m, Nonempty (PT R2 .A2 (replicate (m + 1) a)) := by
  intro m
  induction m with
  | zero => exact ⟨.term .aa⟩
  | succ k ih =>
    obtain ⟨ta2⟩ := ih
    have h : PT R2 .A2 ([a] ++ replicate (k + 1) a) := .bin .aaa (.term .ta) ta2
    rw [show [a] ++ replicate (k + 1) a = replicate (k + 2) a from by simp [replicate_succ]] at h
    exact ⟨h⟩

theorem tree_W2 : ∀ n, Nonempty (PT R2 .W (bc (n + 1))) := by
  intro n
  induction n with
  | zero => exact ⟨(PT.bin .wbc (.term .tb) (.term .tc) : PT R2 .W ([b] ++ [c]))⟩
  | succ k ih =>
    obtain ⟨tw⟩ := ih
    have tz : PT R2 .Z2 (bc (k + 1) ++ [c]) := .bin .zwc tw (.term .tc)
    have tw2 : PT R2 .W ([b] ++ (bc (k + 1) ++ [c])) := .bin .wbz (.term .tb) tz
    rw [bc_cons] at tw2; exact ⟨tw2⟩

/-- `L₂ = { aᵐbⁿcⁿ : m,n ≥ 1 }`. -/
def L2 : List Letter → Prop := fun w => ∃ m n, 1 ≤ m ∧ 1 ≤ n ∧ w = replicate m a ++ bc n

theorem isCFL_L2 : IsCFL L2 := by
  refine ⟨M2, R2, .S, enum2, 7, ?_, ?_, ?_, ?_⟩
  · intro A; cases A <;> decide
  · intro A B; cases A <;> cases B <;> decide
  · intro A; cases A <;> (intro h; cases h)
  · intro w
    constructor
    · rintro ⟨m, n, hm, hn, rfl⟩
      obtain ⟨m', rfl⟩ : ∃ m', m = m' + 1 := ⟨m - 1, by omega⟩
      obtain ⟨n', rfl⟩ : ∃ n', n = n' + 1 := ⟨n - 1, by omega⟩
      obtain ⟨ta2⟩ := tree_A2' m'; obtain ⟨tw⟩ := tree_W2 n'
      exact ⟨.bin .s ta2 tw⟩
    · rintro ⟨t⟩; exact sound_all2 t

/-! #### The intersection is `aⁿbⁿcⁿ`, hence not context-free -/

/-- `aᵖbᵠcʳ` normal form. -/
def tri (p q r : Nat) : List Letter := replicate p a ++ replicate q b ++ replicate r c

theorem count_tri_a (p q r : Nat) : count a (tri p q r) = p := by
  unfold tri
  rw [count_append, count_append, count_replicate_self, count_repl_ne _ (by decide),
    count_repl_ne _ (by decide)]; omega
theorem count_tri_b (p q r : Nat) : count b (tri p q r) = q := by
  unfold tri
  rw [count_append, count_append, count_repl_ne _ (by decide), count_replicate_self,
    count_repl_ne _ (by decide)]; omega
theorem count_tri_c (p q r : Nat) : count c (tri p q r) = r := by
  unfold tri
  rw [count_append, count_append, count_repl_ne _ (by decide), count_repl_ne _ (by decide),
    count_replicate_self]; omega

/-- `L₁ ∩ L₂ = { aⁿbⁿcⁿ : n ≥ 1 }`: the equal-a-b constraint of `L₁` and the
equal-b-c constraint of `L₂` together force all three counts equal. -/
theorem inter_eq (w : List Letter) :
    (L1 w ∧ L2 w) ↔ ∃ n, 1 ≤ n ∧ w = abc n := by
  constructor
  · rintro ⟨⟨i, j, hi, hj, e1⟩, ⟨m, n, hm, hn, e2⟩⟩
    have h1 : w = tri i i j := e1
    have h2 : w = tri m n n := by rw [e2]; simp [bc, tri, List.append_assoc]
    have key : tri i i j = tri m n n := h1.symm.trans h2
    have cb : i = n := by have := congrArg (count b) key; rwa [count_tri_b, count_tri_b] at this
    have cc : j = n := by have := congrArg (count c) key; rwa [count_tri_c, count_tri_c] at this
    exact ⟨i, hi, by rw [h1, show j = i from by omega]; rfl⟩
  · rintro ⟨n, hn, rfl⟩
    exact ⟨⟨n, n, hn, hn, rfl⟩, ⟨n, n, hn, hn, by simp [abc, bc, List.append_assoc]⟩⟩

/-- **The context-free languages are not closed under intersection.** Witnesses
`L₁ = {aⁱbⁱcʲ}` and `L₂ = {aᵐbⁿcⁿ}` are both context-free, but their intersection
`{aⁿbⁿcⁿ}` is not (`anbncn_not_cfl`). (Closure under complement would, with the
∪-closure of CFLs and De Morgan, give ∩-closure — so this also refutes
complement-closure.) -/
theorem cfl_not_closed_inter :
    ∃ K₁ K₂ : List Letter → Prop,
      IsCFL K₁ ∧ IsCFL K₂ ∧ ¬ IsCFL (fun w => K₁ w ∧ K₂ w) := by
  refine ⟨L1, L2, isCFL_L1, isCFL_L2, ?_⟩
  intro hcfl
  apply anbncn_not_cfl
  have heq : (fun w => L1 w ∧ L2 w) = (fun z => ∃ n, 1 ≤ n ∧ z = abc n) := by
    funext w; exact propext (inter_eq w)
  rwa [heq] at hcfl

end Pump
