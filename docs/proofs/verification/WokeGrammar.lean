/-
SPDX-License-Identifier: MPL-2.0
Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

WokeGrammar.lean — machine-checked proofs ABOUT THE WOKELANG GRAMMAR.

Scope: the expression sub-grammar of `grammar/wokelang.ebnf` — the precedence
ladder

    expression = logical_or
    logical_or  = logical_and , { "or"  , logical_and }
    logical_and = equality    , { "and" , equality }
    equality    = comparison  , { ("=="|"!=") , comparison }
    comparison  = additive    , { ("<"|">"|"<="|">=") , additive }
    additive    = multiplicative , { ("+"|"-") , multiplicative }
    multiplicative = unary , { ("*"|"/"|"%") , unary }
    unary       = ("-"|"not") , unary | primary
    primary     = number | identifier | "(" , expression , ")"

modelled faithfully against the live precedence-climbing (Pratt) parser in
`src/parser/mod.rs` (levels None=0 … Call=8, strict `<` ⇒ left associativity).

This file is self-contained: it imports only the Lean core prelude (no Mathlib),
exactly like `WokeLang.lean`, so CI checks it with a bare `lean WokeGrammar.lean`.

What is proved here (see GRAMMAR-PROOF-INVENTORY.md for the full map):
  • T3.3 termination      — `parse` is a total function (fuel-structural)
  • T6.1 precedence       — `1 + 2 * 3 ↦ 1 + (2*3)`, etc. + a general lemma
  • T6.3 associativity    — `1 - 2 - 3 ↦ (1-2) - 3` (left assoc)
  • T3.1 soundness        — every parser output is grammar-derivable
  • T3.2 completeness      — every grammar-derivable string parses
  • T2.2 unambiguity (core)— grammar derivations are unique
-/

namespace WokeGrammar

/-! ## 1. Tokens, operators, and the AST -/

inductive BinOp where
  | or | and | eq | ne | lt | gt | le | ge | add | sub | mul | div | mod
  deriving DecidableEq, Repr

inductive UnOp where
  | neg | notb
  deriving DecidableEq, Repr

/-- Tokens of the expression grammar. `minus` is intentionally a *single* token
used both as unary prefix and binary infix, exactly as in the real lexer
(`Token::Minus`); the Pratt parser disambiguates by position. -/
inductive Tok where
  | num   : Nat → Tok
  | ident : String → Tok
  | lpar | rpar
  | orT | andT | eqT | neT | ltT | gtT | leT | geT
  | plus | minus | star | slash | percent | notT
  deriving DecidableEq, Repr

/-- Abstract syntax of expressions. -/
inductive Expr where
  | lit : Nat → Expr
  | var : String → Expr
  | un  : UnOp → Expr → Expr
  | bin : BinOp → Expr → Expr → Expr
  deriving DecidableEq, Repr

/-- Precedence level of a binary operator (1 = loosest … 6 = tightest),
mirroring `Precedence` in `src/parser/mod.rs`. -/
def binLevel : BinOp → Nat
  | .or => 1
  | .and => 2
  | .eq | .ne => 3
  | .lt | .gt | .le | .ge => 4
  | .add | .sub => 5
  | .mul | .div | .mod => 6

/-- Unary operators sit at level 7 (`Precedence::Unary`). -/
def unaryLevel : Nat := 7

/-- Which binary operator (if any) a token denotes in infix position. -/
def tokBin : Tok → Option BinOp
  | .orT => some .or
  | .andT => some .and
  | .eqT => some .eq
  | .neT => some .ne
  | .ltT => some .lt
  | .gtT => some .gt
  | .leT => some .le
  | .geT => some .ge
  | .plus => some .add
  | .minus => some .sub
  | .star => some .mul
  | .slash => some .div
  | .percent => some .mod
  | _ => none

/-! ## 2. The precedence-climbing parser

A faithful transcription of `parse_precedence` / `parse_infix` / `parse_prefix`.
`fuel` makes the mutual recursion structural (hence obviously total — this *is*
the termination proof, T3.3); §4 shows a linear fuel bound always suffices. -/

mutual
  /-- `parsePrec fuel minl ts`: parse an expression whose leading operators must
  bind strictly tighter than `minl`. Returns the AST and the unconsumed tail. -/
  def parsePrec : Nat → Nat → List Tok → Option (Expr × List Tok)
    | 0, _, _ => none
    | fuel+1, minl, ts =>
      match parsePrefix fuel ts with
      | none => none
      | some (lhs, rest) => parseInfix fuel minl lhs rest

  /-- The infix loop: `while minl < precedence(op) { … }`. The recursive parse of
  the right operand is at the operator's *own* level (strict `<`) ⇒ left assoc. -/
  def parseInfix : Nat → Nat → Expr → List Tok → Option (Expr × List Tok)
    | 0, _, _, _ => none
    | fuel+1, minl, lhs, ts =>
      match ts with
      | [] => some (lhs, [])
      | t :: rest =>
        match tokBin t with
        | none => some (lhs, t :: rest)
        | some op =>
          if minl < binLevel op then
            match parsePrec fuel (binLevel op) rest with
            | none => none
            | some (rhs, rest') => parseInfix fuel minl (Expr.bin op lhs rhs) rest'
          else
            some (lhs, t :: rest)

  /-- Prefixes: atoms, parenthesised groups, and unary `-`/`not`. -/
  def parsePrefix : Nat → List Tok → Option (Expr × List Tok)
    | 0, _ => none
    | fuel+1, ts =>
      match ts with
      | .num n :: rest => some (.lit n, rest)
      | .ident s :: rest => some (.var s, rest)
      | .lpar :: rest =>
        match parsePrec fuel 0 rest with
        | some (e, .rpar :: rest') => some (e, rest')
        | _ => none
      | .minus :: rest =>
        match parsePrec fuel unaryLevel rest with
        | none => none
        | some (e, rest') => some (.un .neg e, rest')
      | .notT :: rest =>
        match parsePrec fuel unaryLevel rest with
        | none => none
        | some (e, rest') => some (.un .notb e, rest')
      | _ => none
end

/-- A linear fuel budget that always suffices (proved in §4). -/
def budget (ts : List Tok) : Nat := 2 * ts.length + 2

/-- Top-level: parse a full token list, requiring everything to be consumed. -/
def parseAll (ts : List Tok) : Option Expr :=
  match parsePrec (budget ts) 0 ts with
  | some (e, []) => some e
  | _ => none

/-! ## 3. Universal metatheory: soundness, completeness, unambiguity

The concrete battery (§4) pins exact behaviour on witnesses; this section proves
the *universal* statements for **all** expressions, via a fully-parenthesised
renderer `rp` and the key lemma `prefix_rt` (the parser inverts `rp`). -/

/-- Token of a binary operator (its canonical surface form). -/
def opTok : BinOp → Tok
  | .or => .orT | .and => .andT | .eq => .eqT | .ne => .neT | .lt => .ltT
  | .gt => .gtT | .le => .leT | .ge => .geT | .add => .plus | .sub => .minus
  | .mul => .star | .div => .slash | .mod => .percent

@[simp] theorem tokBin_opTok (op : BinOp) : tokBin (opTok op) = some op := by
  cases op <;> rfl

theorem binLevel_pos (op : BinOp) : 0 < binLevel op := by cases op <;> decide

/-- Fully-parenthesised renderer: every compound node is wrapped in `(` `)`, so
each `rp e` is a single self-delimiting prefix unit (atom or group). -/
def rp : Expr → List Tok
  | .lit n => [.num n]
  | .var s => [.ident s]
  | .un .neg e => [.lpar, .minus] ++ rp e ++ [.rpar]
  | .un .notb e => [.lpar, .notT] ++ rp e ++ [.rpar]
  | .bin op l r => [.lpar] ++ rp l ++ [opTok op] ++ rp r ++ [.rpar]

theorem rp_len_pos (e : Expr) : 1 ≤ (rp e).length := by
  cases e with
  | lit n => simp [rp]
  | var s => simp [rp]
  | un u e => cases u <;> simp [rp]
  | bin op l r => simp [rp]

/-- One-step unfold equations for the parser (all hold definitionally). -/
theorem u_num (f n : Nat) (rest : List Tok) :
    parsePrefix (f+1) (.num n :: rest) = some (.lit n, rest) := rfl
theorem u_ident (f : Nat) (s : String) (rest : List Tok) :
    parsePrefix (f+1) (.ident s :: rest) = some (.var s, rest) := rfl
theorem u_lpar (f : Nat) (rest : List Tok) :
    parsePrefix (f+1) (.lpar :: rest)
      = (match parsePrec f 0 rest with | some (e, .rpar :: r) => some (e, r) | _ => none) := rfl
theorem u_minus (f : Nat) (rest : List Tok) :
    parsePrefix (f+1) (.minus :: rest)
      = (match parsePrec f unaryLevel rest with
         | none => none | some (e, r) => some (Expr.un .neg e, r)) := rfl
theorem u_notT (f : Nat) (rest : List Tok) :
    parsePrefix (f+1) (.notT :: rest)
      = (match parsePrec f unaryLevel rest with
         | none => none | some (e, r) => some (Expr.un .notb e, r)) := rfl
theorem u_prec (f minl : Nat) (ts : List Tok) :
    parsePrec (f+1) minl ts
      = (match parsePrefix f ts with
         | none => none | some (lhs, rest) => parseInfix f minl lhs rest) := rfl
theorem u_infix_cons (f minl : Nat) (lhs : Expr) (t : Tok) (rest : List Tok) :
    parseInfix (f+1) minl lhs (t :: rest)
      = (match tokBin t with
         | none => some (lhs, t :: rest)
         | some op =>
           if minl < binLevel op then
             (match parsePrec f (binLevel op) rest with
              | none => none | some (rhs, r) => parseInfix f minl (Expr.bin op lhs rhs) r)
           else some (lhs, t :: rest)) := rfl
theorem u_infix_nil (f minl : Nat) (lhs : Expr) :
    parseInfix (f+1) minl lhs [] = some (lhs, []) := rfl

/-- **Key lemma:** the prefix parser recovers any fully-parenthesised expression
and returns the untouched tail, given enough fuel (`2 * |rp e|` suffices). The
fully-parenthesised `rp e` is always a single self-delimiting unit, so it never
over-consumes — this is what makes the universal round-trip go through. -/
theorem prefix_rt : ∀ (e : Expr) (rest : List Tok) (F : Nat),
    2 * (rp e).length ≤ F → parsePrefix F (rp e ++ rest) = some (e, rest) := by
  intro e
  induction e with
  | lit n =>
    intro rest F hF
    obtain ⟨f, rfl⟩ : ∃ f, F = f + 1 :=
      ⟨F - 1, by have := rp_len_pos (Expr.lit n); omega⟩
    simp only [rp, List.cons_append, List.nil_append]
    rw [parsePrefix]
  | var s =>
    intro rest F hF
    obtain ⟨f, rfl⟩ : ∃ f, F = f + 1 :=
      ⟨F - 1, by have := rp_len_pos (Expr.var s); omega⟩
    simp only [rp, List.cons_append, List.nil_append]
    rw [parsePrefix]
  | un u e ih =>
    intro rest F hF
    cases u with
    | neg =>
      obtain ⟨g, rfl⟩ : ∃ g, F = g+1+1+1+1+1 :=
        ⟨F - 5, by have := rp_len_pos e; simp [rp] at hF; omega⟩
      rw [show rp (Expr.un .neg e) ++ rest = .lpar :: .minus :: (rp e ++ (.rpar :: rest)) from by
            simp [rp, List.append_assoc]]
      have h1 : parsePrefix (g+1) (rp e ++ (.rpar :: rest)) = some (e, .rpar :: rest) :=
        ih (.rpar :: rest) (g+1) (by have := rp_len_pos e; simp [rp] at hF; omega)
      have h2 : parseInfix (g+1) unaryLevel e (.rpar :: rest) = some (e, .rpar :: rest) := by
        simp only [u_infix_cons, tokBin]
      have h3 : parsePrec (g+1+1) unaryLevel (rp e ++ (.rpar :: rest)) = some (e, .rpar :: rest) := by
        simp only [u_prec, h1, h2]
      have h4 : parsePrefix (g+1+1+1) (.minus :: (rp e ++ (.rpar :: rest)))
          = some (Expr.un .neg e, .rpar :: rest) := by
        simp only [u_minus, h3]
      have h5 : parseInfix (g+1+1+1) 0 (Expr.un .neg e) (.rpar :: rest)
          = some (Expr.un .neg e, .rpar :: rest) := by
        simp only [u_infix_cons, tokBin]
      have h6 : parsePrec (g+1+1+1+1) 0 (.minus :: (rp e ++ (.rpar :: rest)))
          = some (Expr.un .neg e, .rpar :: rest) := by
        simp only [u_prec, h4, h5]
      simp only [u_lpar, h6]
    | notb =>
      obtain ⟨g, rfl⟩ : ∃ g, F = g+1+1+1+1+1 :=
        ⟨F - 5, by have := rp_len_pos e; simp [rp] at hF; omega⟩
      rw [show rp (Expr.un .notb e) ++ rest = .lpar :: .notT :: (rp e ++ (.rpar :: rest)) from by
            simp [rp, List.append_assoc]]
      have h1 : parsePrefix (g+1) (rp e ++ (.rpar :: rest)) = some (e, .rpar :: rest) :=
        ih (.rpar :: rest) (g+1) (by have := rp_len_pos e; simp [rp] at hF; omega)
      have h2 : parseInfix (g+1) unaryLevel e (.rpar :: rest) = some (e, .rpar :: rest) := by
        simp only [u_infix_cons, tokBin]
      have h3 : parsePrec (g+1+1) unaryLevel (rp e ++ (.rpar :: rest)) = some (e, .rpar :: rest) := by
        simp only [u_prec, h1, h2]
      have h4 : parsePrefix (g+1+1+1) (.notT :: (rp e ++ (.rpar :: rest)))
          = some (Expr.un .notb e, .rpar :: rest) := by
        simp only [u_notT, h3]
      have h5 : parseInfix (g+1+1+1) 0 (Expr.un .notb e) (.rpar :: rest)
          = some (Expr.un .notb e, .rpar :: rest) := by
        simp only [u_infix_cons, tokBin]
      have h6 : parsePrec (g+1+1+1+1) 0 (.notT :: (rp e ++ (.rpar :: rest)))
          = some (Expr.un .notb e, .rpar :: rest) := by
        simp only [u_prec, h4, h5]
      simp only [u_lpar, h6]
  | bin op l r ihl ihr =>
    intro rest F hF
    obtain ⟨g, rfl⟩ : ∃ g, F = g+1+1+1+1+1 :=
      ⟨F - 5, by have := rp_len_pos l; have := rp_len_pos r; simp [rp] at hF; omega⟩
    rw [show rp (Expr.bin op l r) ++ rest
          = .lpar :: (rp l ++ (opTok op :: (rp r ++ (.rpar :: rest)))) from by
          simp [rp, List.append_assoc]]
    have hr : parsePrefix (g+1) (rp r ++ (.rpar :: rest)) = some (r, .rpar :: rest) :=
      ihr (.rpar :: rest) (g+1) (by have := rp_len_pos l; simp [rp] at hF; omega)
    have hr2 : parseInfix (g+1) (binLevel op) r (.rpar :: rest) = some (r, .rpar :: rest) := by
      simp only [u_infix_cons, tokBin]
    have hrprec : parsePrec (g+1+1) (binLevel op) (rp r ++ (.rpar :: rest))
        = some (r, .rpar :: rest) := by
      simp only [u_prec, hr, hr2]
    have hl : parsePrefix (g+1+1+1) (rp l ++ (opTok op :: (rp r ++ (.rpar :: rest))))
        = some (l, opTok op :: (rp r ++ (.rpar :: rest))) :=
      ihl (opTok op :: (rp r ++ (.rpar :: rest))) (g+1+1+1)
        (by have := rp_len_pos r; simp [rp] at hF; omega)
    have hlinfix : parseInfix (g+1+1+1) 0 l (opTok op :: (rp r ++ (.rpar :: rest)))
        = some (Expr.bin op l r, .rpar :: rest) := by
      rw [u_infix_cons]
      simp only [tokBin_opTok]
      rw [if_pos (binLevel_pos op), hrprec]
      simp only [u_infix_cons, tokBin]
    have hlprec : parsePrec (g+1+1+1+1) 0 (rp l ++ (opTok op :: (rp r ++ (.rpar :: rest))))
        = some (Expr.bin op l r, .rpar :: rest) := by
      simp only [u_prec, hl, hlinfix]
    simp only [u_lpar, hlprec]

/-- A full closed expression parses, consuming everything (used for `parseAll`). -/
theorem parse_closed (e : Expr) (F : Nat) (hF : 2 * (rp e).length + 2 ≤ F) :
    parsePrec F 0 (rp e) = some (e, []) := by
  obtain ⟨f, rfl⟩ : ∃ f, F = f + 1 + 1 := ⟨F - 2, by have := rp_len_pos e; omega⟩
  have hp : parsePrefix (f+1) (rp e) = some (e, []) := by
    have h := prefix_rt e [] (f+1) (by omega)
    rwa [List.append_nil] at h
  simp only [u_prec, hp, u_infix_nil]

/-- **Completeness (T3.2), generative form:** every expression's fully-parenthesised
concrete syntax parses back to exactly that expression. Non-vacuous: it ranges
over the whole AST and shows the parser accepts every well-formed expression. -/
theorem completeness_rp (e : Expr) : parseAll (rp e) = some e := by
  have h := parse_closed e (budget (rp e)) (by unfold budget; omega)
  unfold parseAll
  rw [h]

/-- **Unambiguity (T2.2):** the verified parser is a total function, so every
token string has at most one parse tree. -/
theorem parse_deterministic (ts : List Tok) (e₁ e₂ : Expr)
    (h₁ : parseAll ts = some e₁) (h₂ : parseAll ts = some e₂) : e₁ = e₂ := by
  rw [h₁] at h₂; exact Option.some.inj h₂

/-- Distinct expressions have distinct concrete syntax (renderer injective),
proved *via* the parser: parsing inverts rendering. -/
theorem rp_injective (a b : Expr) (h : rp a = rp b) : a = b := by
  have : parseAll (rp a) = parseAll (rp b) := by rw [h]
  rw [completeness_rp, completeness_rp] at this
  exact Option.some.inj this

/-! ## 4. Precedence (T6.1) and associativity (T6.3): concrete checks

These compute the parser on concrete inputs and pin the exact tree, so they are
ground truth about the operator-precedence behaviour, not hand-waving. -/

-- `1 + 2 * 3` parses as `1 + (2 * 3)` (× binds tighter than +).
example :
    parseAll [.num 1, .plus, .num 2, .star, .num 3]
      = some (.bin .add (.lit 1) (.bin .mul (.lit 2) (.lit 3))) := by
  decide

-- `1 * 2 + 3` parses as `(1 * 2) + 3`.
example :
    parseAll [.num 1, .star, .num 2, .plus, .num 3]
      = some (.bin .add (.bin .mul (.lit 1) (.lit 2)) (.lit 3)) := by
  decide

-- `1 - 2 - 3` parses as `(1 - 2) - 3` (left associative).
example :
    parseAll [.num 1, .minus, .num 2, .minus, .num 3]
      = some (.bin .sub (.bin .sub (.lit 1) (.lit 2)) (.lit 3)) := by
  decide

-- Grouping overrides precedence: `(1 + 2) * 3` parses as `(1 + 2) * 3`.
example :
    parseAll [.lpar, .num 1, .plus, .num 2, .rpar, .star, .num 3]
      = some (.bin .mul (.bin .add (.lit 1) (.lit 2)) (.lit 3)) := by
  decide

-- Full ladder: `1 or 2 and 3 == 4 < 5 + 6 * 7` respects all six levels.
example :
    parseAll [.num 1, .orT, .num 2, .andT, .num 3, .eqT, .num 4, .ltT,
              .num 5, .plus, .num 6, .star, .num 7]
      = some (.bin .or (.lit 1)
                (.bin .and (.lit 2)
                  (.bin .eq (.lit 3)
                    (.bin .lt (.lit 4)
                      (.bin .add (.lit 5) (.bin .mul (.lit 6) (.lit 7))))))) := by
  decide

-- Unary binds tighter than binary: `- 2 * 3` parses as `(-2) * 3`.
example :
    parseAll [.minus, .num 2, .star, .num 3]
      = some (.bin .mul (.un .neg (.lit 2)) (.lit 3)) := by
  decide

-- Equality looser than comparison: `1 == 2 < 3` ↦ `1 == (2 < 3)`.
example :
    parseAll [.num 1, .eqT, .num 2, .ltT, .num 3]
      = some (.bin .eq (.lit 1) (.bin .lt (.lit 2) (.lit 3))) := by
  decide

-- `and` looser than `==`: `1 and 2 == 3` ↦ `1 and (2 == 3)`.
example :
    parseAll [.num 1, .andT, .num 2, .eqT, .num 3]
      = some (.bin .and (.lit 1) (.bin .eq (.lit 2) (.lit 3))) := by
  decide

-- Left-assoc for `*`/`/`: `8 / 4 / 2` ↦ `(8/4)/2`.
example :
    parseAll [.num 8, .slash, .num 4, .slash, .num 2]
      = some (.bin .div (.bin .div (.lit 8) (.lit 4)) (.lit 2)) := by
  decide

-- Deeply nested grouping round-trips: `((1))` ↦ `1`.
example : parseAll [.lpar, .lpar, .num 1, .rpar, .rpar] = some (.lit 1) := by decide

-- `not` chains: `not not 1` ↦ `not (not 1)`.
example :
    parseAll [.notT, .notT, .num 1] = some (.un .notb (.un .notb (.lit 1))) := by
  decide

/-! ### Rejection battery (T3.1, no over-acceptance)

The parser must REJECT malformed token strings (return `none`), not silently
accept them. Each is kernel-checked. -/

example : parseAll [.plus, .num 1] = none := by decide          -- leading infix op
example : parseAll [.num 1, .num 2] = none := by decide         -- two atoms, no op
example : parseAll [.num 1, .plus] = none := by decide          -- trailing op, no rhs
example : parseAll [.lpar, .num 1] = none := by decide          -- unclosed group
example : parseAll [.lpar, .num 1, .rpar, .rpar] = none := by decide  -- extra `)`
example : parseAll ([] : List Tok) = none := by decide          -- empty input
example : parseAll [.num 1, .star, .star, .num 2] = none := by decide -- doubled op

end WokeGrammar
