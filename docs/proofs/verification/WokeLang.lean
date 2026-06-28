/-
  WokeLang Formal Verification in Lean 4
  SPDX-License-Identifier: MPL-2.0 OR Apache-2.0

  This file contains Lean 4 definitions and theorems for WokeLang.

  ## Completeness Audit: ALL RESOLVED (0 incomplete-proof markers remaining)

  All 12 original incomplete-proof markers have been eliminated by:
  1. Extending the `Step` inductive with 17 constructors:
     - Reduction: sAddFloat, sAddString, sEqFalse, sAnd, sNegFloat, sUnwrapError
     - Congruence: sUnOpCong, sOkayCong, sOopsCong, sUnwrapCong
     - Error propagation: sBinOpErrLeft, sBinOpErrRight, sUnOpErr,
       sOkayErr, sOopsErr, sUnwrapErr
  2. Adding canonical forms lemmas for Float, String, and Result types
  3. Adding value-level typing rules (tOkayVal, tOopsVal) for result values
  4. Adding an `error` expression constructor with polymorphic typing (tError)
  5. Completing the progress theorem for all typing cases
  6. Completing the preservation theorem by induction on Step

  ### Design decisions:

  **unwrap(oops(s))**: sUnwrapError steps `unwrap(oops(s))` to `error s`,
  a dedicated error expression. The `error` constructor is well-typed at any
  type via tError, and is treated as a terminal value (IsValue includes it).
  This models runtime panic propagation cleanly — preservation holds because
  `error s` has the expected type, and progress holds because errors are values.

  **Result values**: tOkayVal and tOopsVal type `lit(vOkay v)` and `lit(vOops s)`
  directly, bridging between expression-level typing (tOkay/tOops on `.okay`/
  `.oops` expression forms) and value-level typing needed after reduction.

  ### Verified theorems:
  - progress: well-typed closed terms are values or can step
  - preservation: stepping preserves types
  - type_safety: multi-step evaluation preserves types (by induction + preservation)
  - consent_monotonicity / consent_preservation: consent system properties

  ### Arrays (parity with Coq's WokeLang.v):
  `tArray` / `tArrayVal` type array expressions and array literal values
  (the mirror of Coq's `T_Array` / `T_Lit_Array`); `Step` gains `sArrayStep`
  (left-most-element congruence), `sArrayVal` (normalise a fully-evaluated
  array to a `.vArray` literal value), and `sArrayErr` (panic propagation).
  `progress` and `preservation` cover all three. The `∀ e ∈ es` premise shape
  yields a per-element induction hypothesis directly, so — unlike the Coq
  development — no well-founded recursion on an expression-size measure is
  needed: `array_split` does the pure-list decomposition and the IH answers
  value-or-steps per element.
-/

namespace WokeLang

-- =========================================================================
-- 1. Abstract Syntax
-- =========================================================================

/-- WokeLang types -/
inductive WokeType where
  | int : WokeType
  | float : WokeType
  | string : WokeType
  | bool : WokeType
  | unit : WokeType
  | array : WokeType → WokeType
  | maybe : WokeType → WokeType
  | result : WokeType → WokeType → WokeType
  | function : List WokeType → WokeType → WokeType
  | typeVar : Nat → WokeType
  deriving Repr

/-- Runtime values -/
inductive Value where
  | vInt : Int → Value
  | vFloat : Float → Value
  | vString : String → Value
  | vBool : Bool → Value
  | vUnit : Value
  | vArray : List Value → Value
  | vOkay : Value → Value
  | vOops : String → Value
  deriving Repr

/-- Binary operators -/
inductive BinOp where
  | add | sub | mul | div | mod
  | eq | neq | lt | gt | le | ge
  | and | or
  deriving Repr, DecidableEq

/-- Unary operators -/
inductive UnOp where
  | neg | not
  deriving Repr, DecidableEq

/-- Expressions -/
inductive Expr where
  | lit : Value → Expr
  | var : String → Expr
  | binOp : BinOp → Expr → Expr → Expr
  | unOp : UnOp → Expr → Expr
  | call : String → List Expr → Expr
  | array : List Expr → Expr
  | okay : Expr → Expr
  | oops : Expr → Expr
  | unwrap : Expr → Expr
  | error : String → Expr  -- Runtime error/panic (from unwrapping Oops)
  deriving Repr

/-- Statements -/
inductive Stmt where
  | varDecl : String → Expr → Stmt
  | assign : String → Expr → Stmt
  | return_ : Expr → Stmt
  | if_ : Expr → List Stmt → List Stmt → Stmt
  | loop : Expr → List Stmt → Stmt
  | attempt : List Stmt → String → Stmt
  | consent : String → List Stmt → Stmt
  | expr : Expr → Stmt
  | complain : String → Stmt
  deriving Repr

/-- Top-level items -/
inductive TopItem where
  | functionDef : String → List (String × WokeType) → WokeType → List Stmt → TopItem
  | workerDef : String → List Stmt → TopItem
  | gratitude : List (String × String) → TopItem
  deriving Repr

/-- A program is a list of top-level items -/
def Program := List TopItem

-- =========================================================================
-- 2. Environments
-- =========================================================================

/-- Value environment -/
def Env := String → Option Value

/-- Empty environment -/
def emptyEnv : Env := fun _ => none

/-- Extend environment -/
def extendEnv (x : String) (v : Value) (ρ : Env) : Env :=
  fun y => if x == y then some v else ρ y

/-- Type environment -/
def TypeEnv := String → Option WokeType

/-- Empty type environment -/
def emptyTypeEnv : TypeEnv := fun _ => none

/-- Extend type environment -/
def extendTypeEnv (x : String) (t : WokeType) (Γ : TypeEnv) : TypeEnv :=
  fun y => if x == y then some t else Γ y

-- =========================================================================
-- 3. Type Checking
-- =========================================================================

/-- Type checking judgment -/
inductive HasType : TypeEnv → Expr → WokeType → Prop where
  | tInt : ∀ Γ n, HasType Γ (.lit (.vInt n)) .int
  | tFloat : ∀ Γ f, HasType Γ (.lit (.vFloat f)) .float
  | tString : ∀ Γ s, HasType Γ (.lit (.vString s)) .string
  | tBool : ∀ Γ b, HasType Γ (.lit (.vBool b)) .bool
  | tUnit : ∀ Γ, HasType Γ (.lit .vUnit) .unit
  | tOkayVal : ∀ Γ v t,
      HasType Γ (.lit v) t →
      HasType Γ (.lit (.vOkay v)) (.result t .string)
  | tOopsVal : ∀ Γ s t,
      HasType Γ (.lit (.vOops s)) (.result t .string)
  | tVar : ∀ Γ x t, Γ x = some t → HasType Γ (.var x) t
  | tAddInt : ∀ Γ e₁ e₂,
      HasType Γ e₁ .int → HasType Γ e₂ .int →
      HasType Γ (.binOp .add e₁ e₂) .int
  | tAddFloat : ∀ Γ e₁ e₂,
      HasType Γ e₁ .float → HasType Γ e₂ .float →
      HasType Γ (.binOp .add e₁ e₂) .float
  | tAddString : ∀ Γ e₁ e₂,
      HasType Γ e₁ .string → HasType Γ e₂ .string →
      HasType Γ (.binOp .add e₁ e₂) .string
  | tEq : ∀ Γ e₁ e₂ t,
      HasType Γ e₁ t → HasType Γ e₂ t →
      HasType Γ (.binOp .eq e₁ e₂) .bool
  | tAnd : ∀ Γ e₁ e₂,
      HasType Γ e₁ .bool → HasType Γ e₂ .bool →
      HasType Γ (.binOp .and e₁ e₂) .bool
  | tOr : ∀ Γ e₁ e₂,
      HasType Γ e₁ .bool → HasType Γ e₂ .bool →
      HasType Γ (.binOp .or e₁ e₂) .bool
  | tSubInt : ∀ Γ e₁ e₂,
      HasType Γ e₁ .int → HasType Γ e₂ .int →
      HasType Γ (.binOp .sub e₁ e₂) .int
  | tMulInt : ∀ Γ e₁ e₂,
      HasType Γ e₁ .int → HasType Γ e₂ .int →
      HasType Γ (.binOp .mul e₁ e₂) .int
  | tLt : ∀ Γ e₁ e₂,
      HasType Γ e₁ .int → HasType Γ e₂ .int →
      HasType Γ (.binOp .lt e₁ e₂) .bool
  | tGt : ∀ Γ e₁ e₂,
      HasType Γ e₁ .int → HasType Γ e₂ .int →
      HasType Γ (.binOp .gt e₁ e₂) .bool
  | tLe : ∀ Γ e₁ e₂,
      HasType Γ e₁ .int → HasType Γ e₂ .int →
      HasType Γ (.binOp .le e₁ e₂) .bool
  | tGe : ∀ Γ e₁ e₂,
      HasType Γ e₁ .int → HasType Γ e₂ .int →
      HasType Γ (.binOp .ge e₁ e₂) .bool
  | tDivInt : ∀ Γ e₁ e₂,
      HasType Γ e₁ .int → HasType Γ e₂ .int →
      HasType Γ (.binOp .div e₁ e₂) .int
  | tModInt : ∀ Γ e₁ e₂,
      HasType Γ e₁ .int → HasType Γ e₂ .int →
      HasType Γ (.binOp .mod e₁ e₂) .int
  | tNegInt : ∀ Γ e,
      HasType Γ e .int →
      HasType Γ (.unOp .neg e) .int
  | tNegFloat : ∀ Γ e,
      HasType Γ e .float →
      HasType Γ (.unOp .neg e) .float
  | tNot : ∀ Γ e,
      HasType Γ e .bool →
      HasType Γ (.unOp .not e) .bool
  | tOkay : ∀ Γ e t,
      HasType Γ e t →
      HasType Γ (.okay e) (.result t .string)
  | tOops : ∀ Γ e t,
      HasType Γ e .string →
      HasType Γ (.oops e) (.result t .string)
  | tUnwrap : ∀ Γ e tOk tErr,
      HasType Γ e (.result tOk tErr) →
      HasType Γ (.unwrap e) tOk
  | tError : ∀ Γ msg t,
      HasType Γ (.error msg) t
  -- Arrays (mirror of Coq's `T_Array` / `T_Lit_Array` in WokeLang.v).
  -- `tArray` types an array *expression* elementwise; `tArrayVal` types a
  -- fully-evaluated array *literal value*. Both premises use the `∀ e ∈ es`
  -- shape, which (unlike Coq's `Forall`) yields a per-element induction
  -- hypothesis directly from `induction`, so the `progress`/`preservation`
  -- array cases need no well-founded recursion on an `expr_size` measure.
  | tArray : ∀ Γ es t,
      (∀ e, e ∈ es → HasType Γ e t) →
      HasType Γ (.array es) (.array t)
  | tArrayVal : ∀ Γ vs t,
      (∀ v, v ∈ vs → HasType Γ (.lit v) t) →
      HasType Γ (.lit (.vArray vs)) (.array t)

-- =========================================================================
-- 4. Operational Semantics
-- =========================================================================

/-- Predicate for values (includes error expressions — panics are terminal) -/
inductive IsValue : Expr → Prop where
  | lit : ∀ v, IsValue (.lit v)
  | error : ∀ msg, IsValue (.error msg)

/-- Small-step reduction -/
inductive Step : Expr → Env → Expr → Env → Prop where
  | sVar : ∀ x ρ v,
      ρ x = some v →
      Step (.var x) ρ (.lit v) ρ
  | sBinOpLeft : ∀ op e₁ e₁' e₂ ρ ρ',
      Step e₁ ρ e₁' ρ' →
      Step (.binOp op e₁ e₂) ρ (.binOp op e₁' e₂) ρ'
  | sBinOpRight : ∀ op v₁ e₂ e₂' ρ ρ',
      IsValue (.lit v₁) →
      Step e₂ ρ e₂' ρ' →
      Step (.binOp op (.lit v₁) e₂) ρ (.binOp op (.lit v₁) e₂') ρ'
  | sAddInt : ∀ n₁ n₂ ρ,
      Step (.binOp .add (.lit (.vInt n₁)) (.lit (.vInt n₂))) ρ
           (.lit (.vInt (n₁ + n₂))) ρ
  | sEqTrue : ∀ v ρ,
      Step (.binOp .eq (.lit v) (.lit v)) ρ (.lit (.vBool true)) ρ
  | sNegInt : ∀ n ρ,
      Step (.unOp .neg (.lit (.vInt n))) ρ (.lit (.vInt (-n))) ρ
  | sNot : ∀ b ρ,
      Step (.unOp .not (.lit (.vBool b))) ρ (.lit (.vBool (!b))) ρ
  | sOkay : ∀ v ρ,
      IsValue (.lit v) →
      Step (.okay (.lit v)) ρ (.lit (.vOkay v)) ρ
  | sOops : ∀ s ρ,
      Step (.oops (.lit (.vString s))) ρ (.lit (.vOops s)) ρ
  | sUnwrapOkay : ∀ v ρ,
      Step (.unwrap (.lit (.vOkay v))) ρ (.lit v) ρ
  | sAddFloat : ∀ f₁ f₂ ρ,
      Step (.binOp .add (.lit (.vFloat f₁)) (.lit (.vFloat f₂))) ρ
           (.lit (.vFloat (f₁ + f₂))) ρ
  | sAddString : ∀ s₁ s₂ ρ,
      Step (.binOp .add (.lit (.vString s₁)) (.lit (.vString s₂))) ρ
           (.lit (.vString (s₁ ++ s₂))) ρ
  | sEqFalse : ∀ v₁ v₂ ρ,
      v₁ ≠ v₂ →
      Step (.binOp .eq (.lit v₁) (.lit v₂)) ρ (.lit (.vBool false)) ρ
  | sAnd : ∀ b₁ b₂ ρ,
      Step (.binOp .and (.lit (.vBool b₁)) (.lit (.vBool b₂))) ρ
           (.lit (.vBool (b₁ && b₂))) ρ
  | sOr : ∀ b₁ b₂ ρ,
      Step (.binOp .or (.lit (.vBool b₁)) (.lit (.vBool b₂))) ρ
           (.lit (.vBool (b₁ || b₂))) ρ
  | sSubInt : ∀ n₁ n₂ ρ,
      Step (.binOp .sub (.lit (.vInt n₁)) (.lit (.vInt n₂))) ρ
           (.lit (.vInt (n₁ - n₂))) ρ
  | sMulInt : ∀ n₁ n₂ ρ,
      Step (.binOp .mul (.lit (.vInt n₁)) (.lit (.vInt n₂))) ρ
           (.lit (.vInt (n₁ * n₂))) ρ
  | sLt : ∀ n₁ n₂ ρ,
      Step (.binOp .lt (.lit (.vInt n₁)) (.lit (.vInt n₂))) ρ
           (.lit (.vBool (decide (n₁ < n₂)))) ρ
  | sGt : ∀ n₁ n₂ ρ,
      Step (.binOp .gt (.lit (.vInt n₁)) (.lit (.vInt n₂))) ρ
           (.lit (.vBool (decide (n₁ > n₂)))) ρ
  | sLe : ∀ n₁ n₂ ρ,
      Step (.binOp .le (.lit (.vInt n₁)) (.lit (.vInt n₂))) ρ
           (.lit (.vBool (decide (n₁ ≤ n₂)))) ρ
  | sGe : ∀ n₁ n₂ ρ,
      Step (.binOp .ge (.lit (.vInt n₁)) (.lit (.vInt n₂))) ρ
           (.lit (.vBool (decide (n₁ ≥ n₂)))) ρ
  | sDivInt : ∀ n₁ n₂ ρ, n₂ ≠ 0 →
      Step (.binOp .div (.lit (.vInt n₁)) (.lit (.vInt n₂))) ρ
           (.lit (.vInt (n₁ / n₂))) ρ
  | sDivZero : ∀ n₁ n₂ ρ, n₂ = 0 →
      Step (.binOp .div (.lit (.vInt n₁)) (.lit (.vInt n₂))) ρ
           (.error "Division by zero") ρ
  | sModInt : ∀ n₁ n₂ ρ, n₂ ≠ 0 →
      Step (.binOp .mod (.lit (.vInt n₁)) (.lit (.vInt n₂))) ρ
           (.lit (.vInt (n₁ % n₂))) ρ
  | sModZero : ∀ n₁ n₂ ρ, n₂ = 0 →
      Step (.binOp .mod (.lit (.vInt n₁)) (.lit (.vInt n₂))) ρ
           (.error "Modulo by zero") ρ
  | sUnOpCong : ∀ op e e' ρ ρ',
      Step e ρ e' ρ' →
      Step (.unOp op e) ρ (.unOp op e') ρ'
  | sNegFloat : ∀ f ρ,
      Step (.unOp .neg (.lit (.vFloat f))) ρ (.lit (.vFloat (-f))) ρ
  | sOkayCong : ∀ e e' ρ ρ',
      Step e ρ e' ρ' →
      Step (.okay e) ρ (.okay e') ρ'
  | sOopsCong : ∀ e e' ρ ρ',
      Step e ρ e' ρ' →
      Step (.oops e) ρ (.oops e') ρ'
  | sUnwrapCong : ∀ e e' ρ ρ',
      Step e ρ e' ρ' →
      Step (.unwrap e) ρ (.unwrap e') ρ'
  | sUnwrapError : ∀ s ρ,
      Step (.unwrap (.lit (.vOops s))) ρ (.error s) ρ
  | sBinOpErrLeft : ∀ op msg e₂ ρ,
      Step (.binOp op (.error msg) e₂) ρ (.error msg) ρ
  | sBinOpErrRight : ∀ op v₁ msg ρ,
      Step (.binOp op (.lit v₁) (.error msg)) ρ (.error msg) ρ
  | sUnOpErr : ∀ op msg ρ,
      Step (.unOp op (.error msg)) ρ (.error msg) ρ
  | sOkayErr : ∀ msg ρ,
      Step (.okay (.error msg)) ρ (.error msg) ρ
  | sOopsErr : ∀ msg ρ,
      Step (.oops (.error msg)) ρ (.error msg) ρ
  | sUnwrapErr : ∀ msg ρ,
      Step (.unwrap (.error msg)) ρ (.error msg) ρ
  -- Array evaluation (mirror of Coq's `S_Array_step` / `S_Array_val`, plus
  -- panic propagation). `sArrayStep` reduces the left-most non-value element;
  -- `sArrayVal` normalises a fully-evaluated array to an array literal value;
  -- `sArrayErr` propagates a panic out of an array, as the binop rules do.
  -- A fully-evaluated array is *not* an `IsValue` (it always steps via
  -- `sArrayVal`); the `IsValue` is the resulting `.lit (.vArray vs)`.
  | sArrayStep : ∀ (vs : List Value) (e e' : Expr) (es : List Expr) (ρ ρ' : Env),
      Step e ρ e' ρ' →
      Step (.array (vs.map Expr.lit ++ e :: es)) ρ
           (.array (vs.map Expr.lit ++ e' :: es)) ρ'
  | sArrayVal : ∀ (vs : List Value) (ρ : Env),
      Step (.array (vs.map Expr.lit)) ρ (.lit (.vArray vs)) ρ
  | sArrayErr : ∀ (vs : List Value) (msg : String) (es : List Expr) (ρ : Env),
      Step (.array (vs.map Expr.lit ++ .error msg :: es)) ρ (.error msg) ρ

/-- Multi-step reduction (reflexive transitive closure) -/
inductive MultiStep : Expr → Env → Expr → Env → Prop where
  | refl : ∀ e ρ, MultiStep e ρ e ρ
  | step : ∀ e₁ e₂ e₃ ρ₁ ρ₂ ρ₃,
      Step e₁ ρ₁ e₂ ρ₂ →
      MultiStep e₂ ρ₂ e₃ ρ₃ →
      MultiStep e₁ ρ₁ e₃ ρ₃

-- =========================================================================
-- 5. Type Safety Theorems
-- =========================================================================

/-- Canonical forms lemma for Int -/
theorem canonical_forms_int : ∀ v,
  HasType emptyTypeEnv (.lit v) .int →
  ∃ n, v = .vInt n := by
  intro v h
  cases h
  exact ⟨_, rfl⟩

/-- Canonical forms lemma for Float -/
theorem canonical_forms_float : ∀ v,
  HasType emptyTypeEnv (.lit v) .float →
  ∃ f, v = .vFloat f := by
  intro v h
  cases h
  exact ⟨_, rfl⟩

/-- Canonical forms lemma for String -/
theorem canonical_forms_string : ∀ v,
  HasType emptyTypeEnv (.lit v) .string →
  ∃ s, v = .vString s := by
  intro v h
  cases h
  exact ⟨_, rfl⟩

/-- Canonical forms lemma for Bool -/
theorem canonical_forms_bool : ∀ v,
  HasType emptyTypeEnv (.lit v) .bool →
  ∃ b, v = .vBool b := by
  intro v h
  cases h
  exact ⟨_, rfl⟩

/-- Canonical forms lemma for Result -/
theorem canonical_forms_result : ∀ v tOk tErr,
  HasType emptyTypeEnv (.lit v) (.result tOk tErr) →
  (∃ inner, v = .vOkay inner) ∨ (∃ s, v = .vOops s) := by
  intro v tOk tErr h
  cases h with
  | tOkayVal _ _ h₁ => left; exact ⟨_, rfl⟩
  | tOopsVal _ _ => right; exact ⟨_, rfl⟩

/-- `isLitB e` is `true` exactly when `e` is a literal-value expression.
    Used by `array_split` to locate the left-most non-literal array element. -/
def isLitB : Expr → Bool
  | .lit _ => true
  | _ => false

theorem isLitB_true {e : Expr} : isLitB e = true → ∃ v, e = .lit v := by
  cases e <;> simp [isLitB]

theorem isLitB_false {e : Expr} : isLitB e = false → ∀ v, e ≠ .lit v := by
  cases e <;> simp [isLitB]

/-- A list of expressions is either all literal values, or splits as a prefix
    of literal values, a left-most non-literal element, and a remainder. This
    is the Lean analogue of Coq's `array_elements_progress` decomposition;
    here it is pure list reasoning, with the "is it a value or does it step?"
    question deferred to the per-element IH in the `tArray` progress case. -/
theorem array_split (es : List Expr) :
    (∃ vs : List Value, es = vs.map Expr.lit) ∨
    (∃ (vs : List Value) (e : Expr) (rest : List Expr),
        es = vs.map Expr.lit ++ e :: rest ∧ ∀ v, e ≠ .lit v) := by
  induction es with
  | nil => left; exact ⟨[], rfl⟩
  | cons hd tl ih =>
    cases hb : isLitB hd with
    | true =>
      obtain ⟨v, rfl⟩ := isLitB_true hb
      cases ih with
      | inl h => obtain ⟨vs, rfl⟩ := h; left; exact ⟨v :: vs, rfl⟩
      | inr h => obtain ⟨vs, e, rest, rfl, hne⟩ := h
                 right; exact ⟨v :: vs, e, rest, rfl, hne⟩
    | false =>
      right; exact ⟨[], hd, tl, rfl, isLitB_false hb⟩

/-- Progress theorem: a well-typed closed expression is either a value or can step.
    unwrap of an error value steps to an error expression via sUnwrapError,
    modelling WokeLang's panic semantics for unwrapping failures. -/
theorem progress : ∀ e t,
  HasType emptyTypeEnv e t →
  IsValue e ∨ ∃ e' ρ', Step e emptyEnv e' ρ' := by
  intro e t h
  induction h with
  | tInt => left; constructor
  | tFloat => left; constructor
  | tString => left; constructor
  | tBool => left; constructor
  | tUnit => left; constructor
  | tOkayVal _ _ _ => left; constructor
  | tOopsVal _ _ => left; constructor
  | tVar x t hx =>
    -- Variable in empty env is contradiction
    simp [emptyTypeEnv] at hx
  | tAddInt e₁ e₂ h₁ h₂ ih₁ ih₂ =>
    right
    cases ih₁ with
    | inl hv₁ =>
      cases hv₁ with
      | lit v₁ =>
        cases ih₂ with
        | inl hv₂ =>
          cases hv₂ with
          | lit v₂ =>
            have ⟨n₁, hn₁⟩ := canonical_forms_int v₁ h₁
            have ⟨n₂, hn₂⟩ := canonical_forms_int v₂ h₂
            subst hn₁; subst hn₂
            exact ⟨.lit (.vInt (n₁ + n₂)), emptyEnv, .sAddInt n₁ n₂ emptyEnv⟩
          | error msg =>
            exact ⟨.error msg, emptyEnv, .sBinOpErrRight .add v₁ msg emptyEnv⟩
        | inr hstp =>
          obtain ⟨e₂', ρ', hs₂⟩ := hstp
          exact ⟨.binOp .add (.lit v₁) e₂', ρ', .sBinOpRight .add v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sBinOpErrLeft .add msg e₂ emptyEnv⟩
    | inr hstp =>
      obtain ⟨e₁', ρ', hs₁⟩ := hstp
      exact ⟨.binOp .add e₁' e₂, ρ', .sBinOpLeft .add _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tAddFloat e₁ e₂ h₁ h₂ ih₁ ih₂ =>
    right
    cases ih₁ with
    | inl hv₁ =>
      cases hv₁ with
      | lit v₁ =>
        cases ih₂ with
        | inl hv₂ =>
          cases hv₂ with
          | lit v₂ =>
            have ⟨f₁, hf₁⟩ := canonical_forms_float v₁ h₁
            have ⟨f₂, hf₂⟩ := canonical_forms_float v₂ h₂
            subst hf₁; subst hf₂
            exact ⟨.lit (.vFloat (f₁ + f₂)), emptyEnv, .sAddFloat f₁ f₂ emptyEnv⟩
          | error msg =>
            exact ⟨.error msg, emptyEnv, .sBinOpErrRight .add v₁ msg emptyEnv⟩
        | inr hstp =>
          obtain ⟨e₂', ρ', hs₂⟩ := hstp
          exact ⟨.binOp .add (.lit v₁) e₂', ρ', .sBinOpRight .add v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sBinOpErrLeft .add msg e₂ emptyEnv⟩
    | inr hstp =>
      obtain ⟨e₁', ρ', hs₁⟩ := hstp
      exact ⟨.binOp .add e₁' e₂, ρ', .sBinOpLeft .add _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tAddString e₁ e₂ h₁ h₂ ih₁ ih₂ =>
    right
    cases ih₁ with
    | inl hv₁ =>
      cases hv₁ with
      | lit v₁ =>
        cases ih₂ with
        | inl hv₂ =>
          cases hv₂ with
          | lit v₂ =>
            have ⟨s₁, hs₁⟩ := canonical_forms_string v₁ h₁
            have ⟨s₂, hs₂⟩ := canonical_forms_string v₂ h₂
            subst hs₁; subst hs₂
            exact ⟨.lit (.vString (s₁ ++ s₂)), emptyEnv, .sAddString s₁ s₂ emptyEnv⟩
          | error msg =>
            exact ⟨.error msg, emptyEnv, .sBinOpErrRight .add v₁ msg emptyEnv⟩
        | inr hstp =>
          obtain ⟨e₂', ρ', hs₂⟩ := hstp
          exact ⟨.binOp .add (.lit v₁) e₂', ρ', .sBinOpRight .add v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sBinOpErrLeft .add msg e₂ emptyEnv⟩
    | inr hstp =>
      obtain ⟨e₁', ρ', hs₁⟩ := hstp
      exact ⟨.binOp .add e₁' e₂, ρ', .sBinOpLeft .add _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tEq e₁ e₂ _ h₁ h₂ ih₁ ih₂ =>
    right
    cases ih₁ with
    | inl hv₁ =>
      cases hv₁ with
      | lit v₁ =>
        cases ih₂ with
        | inl hv₂ =>
          cases hv₂ with
          | lit v₂ =>
            by_cases heq : v₁ = v₂
            · subst heq
              exact ⟨.lit (.vBool true), emptyEnv, .sEqTrue v₁ emptyEnv⟩
            · exact ⟨.lit (.vBool false), emptyEnv, .sEqFalse v₁ v₂ emptyEnv heq⟩
          | error msg =>
            exact ⟨.error msg, emptyEnv, .sBinOpErrRight .eq v₁ msg emptyEnv⟩
        | inr hstp =>
          obtain ⟨e₂', ρ', hs₂⟩ := hstp
          exact ⟨.binOp .eq (.lit v₁) e₂', ρ', .sBinOpRight .eq v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sBinOpErrLeft .eq msg e₂ emptyEnv⟩
    | inr hstp =>
      obtain ⟨e₁', ρ', hs₁⟩ := hstp
      exact ⟨.binOp .eq e₁' e₂, ρ', .sBinOpLeft .eq _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tAnd e₁ e₂ h₁ h₂ ih₁ ih₂ =>
    right
    cases ih₁ with
    | inl hv₁ =>
      cases hv₁ with
      | lit v₁ =>
        cases ih₂ with
        | inl hv₂ =>
          cases hv₂ with
          | lit v₂ =>
            have ⟨b₁, hb₁⟩ := canonical_forms_bool v₁ h₁
            have ⟨b₂, hb₂⟩ := canonical_forms_bool v₂ h₂
            subst hb₁; subst hb₂
            exact ⟨.lit (.vBool (b₁ && b₂)), emptyEnv, .sAnd b₁ b₂ emptyEnv⟩
          | error msg =>
            exact ⟨.error msg, emptyEnv, .sBinOpErrRight .and v₁ msg emptyEnv⟩
        | inr hstp =>
          obtain ⟨e₂', ρ', hs₂⟩ := hstp
          exact ⟨.binOp .and (.lit v₁) e₂', ρ', .sBinOpRight .and v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sBinOpErrLeft .and msg e₂ emptyEnv⟩
    | inr hstp =>
      obtain ⟨e₁', ρ', hs₁⟩ := hstp
      exact ⟨.binOp .and e₁' e₂, ρ', .sBinOpLeft .and _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tOr e₁ e₂ h₁ h₂ ih₁ ih₂ =>
    right
    cases ih₁ with
    | inl hv₁ =>
      cases hv₁ with
      | lit v₁ =>
        cases ih₂ with
        | inl hv₂ =>
          cases hv₂ with
          | lit v₂ =>
            have ⟨b₁, hb₁⟩ := canonical_forms_bool v₁ h₁
            have ⟨b₂, hb₂⟩ := canonical_forms_bool v₂ h₂
            subst hb₁; subst hb₂
            exact ⟨.lit (.vBool (b₁ || b₂)), emptyEnv, .sOr b₁ b₂ emptyEnv⟩
          | error msg =>
            exact ⟨.error msg, emptyEnv, .sBinOpErrRight .or v₁ msg emptyEnv⟩
        | inr hstp =>
          obtain ⟨e₂', ρ', hs₂⟩ := hstp
          exact ⟨.binOp .or (.lit v₁) e₂', ρ', .sBinOpRight .or v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sBinOpErrLeft .or msg e₂ emptyEnv⟩
    | inr hstp =>
      obtain ⟨e₁', ρ', hs₁⟩ := hstp
      exact ⟨.binOp .or e₁' e₂, ρ', .sBinOpLeft .or _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tSubInt e₁ e₂ h₁ h₂ ih₁ ih₂ =>
    right
    cases ih₁ with
    | inl hv₁ =>
      cases hv₁ with
      | lit v₁ =>
        cases ih₂ with
        | inl hv₂ =>
          cases hv₂ with
          | lit v₂ =>
            have ⟨n₁, hn₁⟩ := canonical_forms_int v₁ h₁
            have ⟨n₂, hn₂⟩ := canonical_forms_int v₂ h₂
            subst hn₁; subst hn₂
            exact ⟨.lit (.vInt (n₁ - n₂)), emptyEnv, .sSubInt n₁ n₂ emptyEnv⟩
          | error msg =>
            exact ⟨.error msg, emptyEnv, .sBinOpErrRight .sub v₁ msg emptyEnv⟩
        | inr hstp =>
          obtain ⟨e₂', ρ', hs₂⟩ := hstp
          exact ⟨.binOp .sub (.lit v₁) e₂', ρ', .sBinOpRight .sub v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sBinOpErrLeft .sub msg e₂ emptyEnv⟩
    | inr hstp =>
      obtain ⟨e₁', ρ', hs₁⟩ := hstp
      exact ⟨.binOp .sub e₁' e₂, ρ', .sBinOpLeft .sub _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tMulInt e₁ e₂ h₁ h₂ ih₁ ih₂ =>
    right
    cases ih₁ with
    | inl hv₁ =>
      cases hv₁ with
      | lit v₁ =>
        cases ih₂ with
        | inl hv₂ =>
          cases hv₂ with
          | lit v₂ =>
            have ⟨n₁, hn₁⟩ := canonical_forms_int v₁ h₁
            have ⟨n₂, hn₂⟩ := canonical_forms_int v₂ h₂
            subst hn₁; subst hn₂
            exact ⟨.lit (.vInt (n₁ * n₂)), emptyEnv, .sMulInt n₁ n₂ emptyEnv⟩
          | error msg =>
            exact ⟨.error msg, emptyEnv, .sBinOpErrRight .mul v₁ msg emptyEnv⟩
        | inr hstp =>
          obtain ⟨e₂', ρ', hs₂⟩ := hstp
          exact ⟨.binOp .mul (.lit v₁) e₂', ρ', .sBinOpRight .mul v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sBinOpErrLeft .mul msg e₂ emptyEnv⟩
    | inr hstp =>
      obtain ⟨e₁', ρ', hs₁⟩ := hstp
      exact ⟨.binOp .mul e₁' e₂, ρ', .sBinOpLeft .mul _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tLt e₁ e₂ h₁ h₂ ih₁ ih₂ =>
    right
    cases ih₁ with
    | inl hv₁ =>
      cases hv₁ with
      | lit v₁ =>
        cases ih₂ with
        | inl hv₂ =>
          cases hv₂ with
          | lit v₂ =>
            have ⟨n₁, hn₁⟩ := canonical_forms_int v₁ h₁
            have ⟨n₂, hn₂⟩ := canonical_forms_int v₂ h₂
            subst hn₁; subst hn₂
            exact ⟨.lit (.vBool (decide (n₁ < n₂))), emptyEnv, .sLt n₁ n₂ emptyEnv⟩
          | error msg =>
            exact ⟨.error msg, emptyEnv, .sBinOpErrRight .lt v₁ msg emptyEnv⟩
        | inr hstp =>
          obtain ⟨e₂', ρ', hs₂⟩ := hstp
          exact ⟨.binOp .lt (.lit v₁) e₂', ρ', .sBinOpRight .lt v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sBinOpErrLeft .lt msg e₂ emptyEnv⟩
    | inr hstp =>
      obtain ⟨e₁', ρ', hs₁⟩ := hstp
      exact ⟨.binOp .lt e₁' e₂, ρ', .sBinOpLeft .lt _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tGt e₁ e₂ h₁ h₂ ih₁ ih₂ =>
    right
    cases ih₁ with
    | inl hv₁ =>
      cases hv₁ with
      | lit v₁ =>
        cases ih₂ with
        | inl hv₂ =>
          cases hv₂ with
          | lit v₂ =>
            have ⟨n₁, hn₁⟩ := canonical_forms_int v₁ h₁
            have ⟨n₂, hn₂⟩ := canonical_forms_int v₂ h₂
            subst hn₁; subst hn₂
            exact ⟨.lit (.vBool (decide (n₁ > n₂))), emptyEnv, .sGt n₁ n₂ emptyEnv⟩
          | error msg =>
            exact ⟨.error msg, emptyEnv, .sBinOpErrRight .gt v₁ msg emptyEnv⟩
        | inr hstp =>
          obtain ⟨e₂', ρ', hs₂⟩ := hstp
          exact ⟨.binOp .gt (.lit v₁) e₂', ρ', .sBinOpRight .gt v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sBinOpErrLeft .gt msg e₂ emptyEnv⟩
    | inr hstp =>
      obtain ⟨e₁', ρ', hs₁⟩ := hstp
      exact ⟨.binOp .gt e₁' e₂, ρ', .sBinOpLeft .gt _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tLe e₁ e₂ h₁ h₂ ih₁ ih₂ =>
    right
    cases ih₁ with
    | inl hv₁ =>
      cases hv₁ with
      | lit v₁ =>
        cases ih₂ with
        | inl hv₂ =>
          cases hv₂ with
          | lit v₂ =>
            have ⟨n₁, hn₁⟩ := canonical_forms_int v₁ h₁
            have ⟨n₂, hn₂⟩ := canonical_forms_int v₂ h₂
            subst hn₁; subst hn₂
            exact ⟨.lit (.vBool (decide (n₁ ≤ n₂))), emptyEnv, .sLe n₁ n₂ emptyEnv⟩
          | error msg =>
            exact ⟨.error msg, emptyEnv, .sBinOpErrRight .le v₁ msg emptyEnv⟩
        | inr hstp =>
          obtain ⟨e₂', ρ', hs₂⟩ := hstp
          exact ⟨.binOp .le (.lit v₁) e₂', ρ', .sBinOpRight .le v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sBinOpErrLeft .le msg e₂ emptyEnv⟩
    | inr hstp =>
      obtain ⟨e₁', ρ', hs₁⟩ := hstp
      exact ⟨.binOp .le e₁' e₂, ρ', .sBinOpLeft .le _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tGe e₁ e₂ h₁ h₂ ih₁ ih₂ =>
    right
    cases ih₁ with
    | inl hv₁ =>
      cases hv₁ with
      | lit v₁ =>
        cases ih₂ with
        | inl hv₂ =>
          cases hv₂ with
          | lit v₂ =>
            have ⟨n₁, hn₁⟩ := canonical_forms_int v₁ h₁
            have ⟨n₂, hn₂⟩ := canonical_forms_int v₂ h₂
            subst hn₁; subst hn₂
            exact ⟨.lit (.vBool (decide (n₁ ≥ n₂))), emptyEnv, .sGe n₁ n₂ emptyEnv⟩
          | error msg =>
            exact ⟨.error msg, emptyEnv, .sBinOpErrRight .ge v₁ msg emptyEnv⟩
        | inr hstp =>
          obtain ⟨e₂', ρ', hs₂⟩ := hstp
          exact ⟨.binOp .ge (.lit v₁) e₂', ρ', .sBinOpRight .ge v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sBinOpErrLeft .ge msg e₂ emptyEnv⟩
    | inr hstp =>
      obtain ⟨e₁', ρ', hs₁⟩ := hstp
      exact ⟨.binOp .ge e₁' e₂, ρ', .sBinOpLeft .ge _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tDivInt e₁ e₂ h₁ h₂ ih₁ ih₂ =>
    right
    cases ih₁ with
    | inl hv₁ =>
      cases hv₁ with
      | lit v₁ =>
        cases ih₂ with
        | inl hv₂ =>
          cases hv₂ with
          | lit v₂ =>
            have ⟨n₁, hn₁⟩ := canonical_forms_int v₁ h₁
            have ⟨n₂, hn₂⟩ := canonical_forms_int v₂ h₂
            subst hn₁; subst hn₂
            by_cases hz : n₂ = 0
            · exact ⟨.error "Division by zero", emptyEnv, .sDivZero n₁ n₂ emptyEnv hz⟩
            · exact ⟨.lit (.vInt (n₁ / n₂)), emptyEnv, .sDivInt n₁ n₂ emptyEnv hz⟩
          | error msg =>
            exact ⟨.error msg, emptyEnv, .sBinOpErrRight .div v₁ msg emptyEnv⟩
        | inr hstp =>
          obtain ⟨e₂', ρ', hs₂⟩ := hstp
          exact ⟨.binOp .div (.lit v₁) e₂', ρ', .sBinOpRight .div v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sBinOpErrLeft .div msg e₂ emptyEnv⟩
    | inr hstp =>
      obtain ⟨e₁', ρ', hs₁⟩ := hstp
      exact ⟨.binOp .div e₁' e₂, ρ', .sBinOpLeft .div _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tModInt e₁ e₂ h₁ h₂ ih₁ ih₂ =>
    right
    cases ih₁ with
    | inl hv₁ =>
      cases hv₁ with
      | lit v₁ =>
        cases ih₂ with
        | inl hv₂ =>
          cases hv₂ with
          | lit v₂ =>
            have ⟨n₁, hn₁⟩ := canonical_forms_int v₁ h₁
            have ⟨n₂, hn₂⟩ := canonical_forms_int v₂ h₂
            subst hn₁; subst hn₂
            by_cases hz : n₂ = 0
            · exact ⟨.error "Modulo by zero", emptyEnv, .sModZero n₁ n₂ emptyEnv hz⟩
            · exact ⟨.lit (.vInt (n₁ % n₂)), emptyEnv, .sModInt n₁ n₂ emptyEnv hz⟩
          | error msg =>
            exact ⟨.error msg, emptyEnv, .sBinOpErrRight .mod v₁ msg emptyEnv⟩
        | inr hstp =>
          obtain ⟨e₂', ρ', hs₂⟩ := hstp
          exact ⟨.binOp .mod (.lit v₁) e₂', ρ', .sBinOpRight .mod v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sBinOpErrLeft .mod msg e₂ emptyEnv⟩
    | inr hstp =>
      obtain ⟨e₁', ρ', hs₁⟩ := hstp
      exact ⟨.binOp .mod e₁' e₂, ρ', .sBinOpLeft .mod _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tNegInt e h₁ ih =>
    right
    cases ih with
    | inl hv =>
      cases hv with
      | lit v =>
        have ⟨n, hn⟩ := canonical_forms_int v h₁
        subst hn
        exact ⟨.lit (.vInt (-n)), emptyEnv, .sNegInt n emptyEnv⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sUnOpErr .neg msg emptyEnv⟩
    | inr hstp =>
      obtain ⟨e', ρ', hs⟩ := hstp
      exact ⟨.unOp .neg e', ρ', .sUnOpCong .neg _ e' emptyEnv ρ' hs⟩
  | tNegFloat e h₁ ih =>
    right
    cases ih with
    | inl hv =>
      cases hv with
      | lit v =>
        have ⟨f, hf⟩ := canonical_forms_float v h₁
        subst hf
        exact ⟨.lit (.vFloat (-f)), emptyEnv, .sNegFloat f emptyEnv⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sUnOpErr .neg msg emptyEnv⟩
    | inr hstp =>
      obtain ⟨e', ρ', hs⟩ := hstp
      exact ⟨.unOp .neg e', ρ', .sUnOpCong .neg _ e' emptyEnv ρ' hs⟩
  | tNot e h₁ ih =>
    right
    cases ih with
    | inl hv =>
      cases hv with
      | lit v =>
        have ⟨b, hb⟩ := canonical_forms_bool v h₁
        subst hb
        exact ⟨.lit (.vBool (!b)), emptyEnv, .sNot b emptyEnv⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sUnOpErr .not msg emptyEnv⟩
    | inr hstp =>
      obtain ⟨e', ρ', hs⟩ := hstp
      exact ⟨.unOp .not e', ρ', .sUnOpCong .not _ e' emptyEnv ρ' hs⟩
  | tOkay e _ h₁ ih =>
    right
    cases ih with
    | inl hv =>
      cases hv with
      | lit v =>
        exact ⟨.lit (.vOkay v), emptyEnv, .sOkay v emptyEnv (.lit v)⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sOkayErr msg emptyEnv⟩
    | inr hstp =>
      obtain ⟨e', ρ', hs⟩ := hstp
      exact ⟨.okay e', ρ', .sOkayCong _ e' emptyEnv ρ' hs⟩
  | tOops e _ h₁ ih =>
    right
    cases ih with
    | inl hv =>
      cases hv with
      | lit v =>
        have ⟨s, hs⟩ : ∃ s, v = .vString s := by cases h₁; exact ⟨_, rfl⟩
        subst hs
        exact ⟨.lit (.vOops s), emptyEnv, .sOops s emptyEnv⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sOopsErr msg emptyEnv⟩
    | inr hstp =>
      obtain ⟨e', ρ', hs⟩ := hstp
      exact ⟨.oops e', ρ', .sOopsCong _ e' emptyEnv ρ' hs⟩
  | tUnwrap e tOk tErr h₁ ih =>
    right
    cases ih with
    | inl hv =>
      cases hv with
      | lit v =>
        -- v has type result tOk tErr, so it must be vOkay or vOops.
        -- sUnwrapOkay handles vOkay; sUnwrapError handles vOops.
        have hcf := canonical_forms_result v tOk tErr h₁
        cases hcf with
        | inl hstp =>
          obtain ⟨inner, hinner⟩ := hstp
          subst hinner
          exact ⟨.lit inner, emptyEnv, .sUnwrapOkay inner emptyEnv⟩
        | inr hstp =>
          obtain ⟨s, hs⟩ := hstp
          subst hs
          exact ⟨.error s, emptyEnv, .sUnwrapError s emptyEnv⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sUnwrapErr msg emptyEnv⟩
    | inr hstp =>
      obtain ⟨e', ρ', hs⟩ := hstp
      exact ⟨.unwrap e', ρ', .sUnwrapCong _ e' emptyEnv ρ' hs⟩
  | tError msg _ =>
    -- Error expressions are terminal values (panics).
    left; exact .error msg
  | tArray es t hall ih =>
    -- An array expression is never a value: it either normalises (all
    -- elements are literals ⇒ sArrayVal), propagates a panic (left-most
    -- non-literal is an error ⇒ sArrayErr), or steps its left-most
    -- non-literal element (⇒ sArrayStep). The per-element progress IH `ih`
    -- discharges the last two via `array_split`.
    right
    cases array_split es with
    | inl hsplit =>
      obtain ⟨vs, rfl⟩ := hsplit
      exact ⟨.lit (.vArray vs), emptyEnv, .sArrayVal vs emptyEnv⟩
    | inr hsplit =>
      obtain ⟨vs, e, rest, rfl, hne⟩ := hsplit
      have hin : e ∈ vs.map Expr.lit ++ e :: rest := by simp
      cases ih e hin with
      | inl hv =>
        cases hv with
        | lit v => exact absurd rfl (hne v)
        | error msg => exact ⟨.error msg, emptyEnv, .sArrayErr vs msg rest emptyEnv⟩
      | inr hstp =>
        obtain ⟨e', ρ', hs⟩ := hstp
        exact ⟨.array (vs.map Expr.lit ++ e' :: rest), ρ',
               .sArrayStep vs e e' rest emptyEnv ρ' hs⟩
  | tArrayVal vs t hall ih =>
    -- A fully-evaluated array literal `.lit (.vArray vs)` is a value.
    left; constructor

/-- Preservation theorem: if a well-typed expression steps, the result is well-typed.
    Proof by induction on the Step derivation with inversion on the typing derivation.
    Reduction cases (sAddInt, sEqTrue, sNegInt, etc.) follow by constructor application.
    Congruence cases (sBinOpLeft, sBinOpRight, sUnOpCong, etc.) use the IH. -/
theorem preservation : ∀ e e' t ρ ρ',
  HasType emptyTypeEnv e t →
  Step e ρ e' ρ' →
  HasType emptyTypeEnv e' t := by
  intro e e' t ρ ρ' ht hs
  induction hs generalizing t with
  | sVar x ρ v hx =>
    -- Typed as (var x) in empty env ⇒ contradiction in progress,
    -- but preservation receives any ρ. By inversion on typing:
    -- HasType emptyTypeEnv (var x) t requires emptyTypeEnv x = some t,
    -- which is a contradiction.
    cases ht with
    | tVar _ _ hx' => simp [emptyTypeEnv] at hx'
  | sBinOpLeft op e₁ e₁' e₂ ρ ρ' hs₁ ih =>
    cases ht with
    | tAddInt _ _ h₁ h₂ => exact .tAddInt _ _ _ (ih _ h₁) h₂
    | tAddFloat _ _ h₁ h₂ => exact .tAddFloat _ _ _ (ih _ h₁) h₂
    | tAddString _ _ h₁ h₂ => exact .tAddString _ _ _ (ih _ h₁) h₂
    | tEq _ _ _ h₁ h₂ => exact .tEq _ _ _ _ (ih _ h₁) h₂
    | tAnd _ _ h₁ h₂ => exact .tAnd _ _ _ (ih _ h₁) h₂
    | tOr _ _ h₁ h₂ => exact .tOr _ _ _ (ih _ h₁) h₂
    | tSubInt _ _ h₁ h₂ => exact .tSubInt _ _ _ (ih _ h₁) h₂
    | tMulInt _ _ h₁ h₂ => exact .tMulInt _ _ _ (ih _ h₁) h₂
    | tLt _ _ h₁ h₂ => exact .tLt _ _ _ (ih _ h₁) h₂
    | tGt _ _ h₁ h₂ => exact .tGt _ _ _ (ih _ h₁) h₂
    | tLe _ _ h₁ h₂ => exact .tLe _ _ _ (ih _ h₁) h₂
    | tGe _ _ h₁ h₂ => exact .tGe _ _ _ (ih _ h₁) h₂
    | tDivInt _ _ h₁ h₂ => exact .tDivInt _ _ _ (ih _ h₁) h₂
    | tModInt _ _ h₁ h₂ => exact .tModInt _ _ _ (ih _ h₁) h₂
  | sBinOpRight op v₁ e₂ e₂' ρ ρ' _hv hs₂ ih =>
    cases ht with
    | tAddInt _ _ h₁ h₂ => exact .tAddInt _ _ _ h₁ (ih _ h₂)
    | tAddFloat _ _ h₁ h₂ => exact .tAddFloat _ _ _ h₁ (ih _ h₂)
    | tAddString _ _ h₁ h₂ => exact .tAddString _ _ _ h₁ (ih _ h₂)
    | tEq _ _ _ h₁ h₂ => exact .tEq _ _ _ _ h₁ (ih _ h₂)
    | tAnd _ _ h₁ h₂ => exact .tAnd _ _ _ h₁ (ih _ h₂)
    | tOr _ _ h₁ h₂ => exact .tOr _ _ _ h₁ (ih _ h₂)
    | tSubInt _ _ h₁ h₂ => exact .tSubInt _ _ _ h₁ (ih _ h₂)
    | tMulInt _ _ h₁ h₂ => exact .tMulInt _ _ _ h₁ (ih _ h₂)
    | tLt _ _ h₁ h₂ => exact .tLt _ _ _ h₁ (ih _ h₂)
    | tGt _ _ h₁ h₂ => exact .tGt _ _ _ h₁ (ih _ h₂)
    | tLe _ _ h₁ h₂ => exact .tLe _ _ _ h₁ (ih _ h₂)
    | tGe _ _ h₁ h₂ => exact .tGe _ _ _ h₁ (ih _ h₂)
    | tDivInt _ _ h₁ h₂ => exact .tDivInt _ _ _ h₁ (ih _ h₂)
    | tModInt _ _ h₁ h₂ => exact .tModInt _ _ _ h₁ (ih _ h₂)
  | sAddInt n₁ n₂ _ =>
    cases ht with
    | tAddInt _ _ h₁ h₂ => exact .tInt _ _
    | tAddFloat _ _ h₁ _ => nomatch h₁
    | tAddString _ _ h₁ _ => nomatch h₁
  | sAddFloat f₁ f₂ _ =>
    cases ht with
    | tAddFloat _ _ h₁ h₂ => exact .tFloat _ _
    | tAddInt _ _ h₁ _ => nomatch h₁
    | tAddString _ _ h₁ _ => nomatch h₁
  | sAddString s₁ s₂ _ =>
    cases ht with
    | tAddString _ _ h₁ h₂ => exact .tString _ _
    | tAddInt _ _ h₁ _ => nomatch h₁
    | tAddFloat _ _ h₁ _ => nomatch h₁
  | sEqTrue v _ =>
    cases ht with
    | tEq _ _ _ h₁ h₂ => exact .tBool _ _
  | sEqFalse v₁ v₂ _ hneq =>
    cases ht with
    | tEq _ _ _ h₁ h₂ => exact .tBool _ _
  | sAnd b₁ b₂ _ =>
    cases ht with
    | tAnd _ _ h₁ h₂ => exact .tBool _ _
  | sOr b₁ b₂ _ =>
    cases ht with
    | tOr _ _ h₁ h₂ => exact .tBool _ _
  | sSubInt n₁ n₂ _ =>
    cases ht with
    | tSubInt _ _ h₁ h₂ => exact .tInt _ _
  | sMulInt n₁ n₂ _ =>
    cases ht with
    | tMulInt _ _ h₁ h₂ => exact .tInt _ _
  | sLt n₁ n₂ _ =>
    cases ht with
    | tLt _ _ h₁ h₂ => exact .tBool _ _
  | sGt n₁ n₂ _ =>
    cases ht with
    | tGt _ _ h₁ h₂ => exact .tBool _ _
  | sLe n₁ n₂ _ =>
    cases ht with
    | tLe _ _ h₁ h₂ => exact .tBool _ _
  | sGe n₁ n₂ _ =>
    cases ht with
    | tGe _ _ h₁ h₂ => exact .tBool _ _
  | sDivInt n₁ n₂ _ _ =>
    cases ht with
    | tDivInt _ _ h₁ h₂ => exact .tInt _ _
  | sDivZero n₁ n₂ _ _ =>
    cases ht with
    | tDivInt _ _ h₁ h₂ => exact .tError _ _ _
  | sModInt n₁ n₂ _ _ =>
    cases ht with
    | tModInt _ _ h₁ h₂ => exact .tInt _ _
  | sModZero n₁ n₂ _ _ =>
    cases ht with
    | tModInt _ _ h₁ h₂ => exact .tError _ _ _
  | sNegInt n _ =>
    cases ht with
    | tNegInt _ h₁ => exact .tInt _ _
    | tNegFloat _ h₁ => nomatch h₁
  | sNegFloat f _ =>
    cases ht with
    | tNegFloat _ h₁ => exact .tFloat _ _
    | tNegInt _ h₁ => nomatch h₁
  | sNot b _ =>
    cases ht with
    | tNot _ h₁ => exact .tBool _ _
  | sUnOpCong op e e' ρ ρ' hs₁ ih =>
    cases ht with
    | tNegInt _ h₁ => exact .tNegInt _ _ (ih _ h₁)
    | tNegFloat _ h₁ => exact .tNegFloat _ _ (ih _ h₁)
    | tNot _ h₁ => exact .tNot _ _ (ih _ h₁)
  | sOkay v _ _hv =>
    cases ht with
    | tOkay _ _ h₁ => exact .tOkayVal _ v _ h₁
  | sOkayCong e e' ρ ρ' hs₁ ih =>
    cases ht with
    | tOkay _ _ h₁ => exact .tOkay _ _ _ (ih _ h₁)
  | sOops s _ =>
    cases ht with
    | tOops _ _ h₁ => exact .tOopsVal _ s _
  | sOopsCong e e' ρ ρ' hs₁ ih =>
    cases ht with
    | tOops _ _ h₁ => exact .tOops _ _ _ (ih _ h₁)
  | sUnwrapOkay v _ =>
    cases ht with
    | tUnwrap _ tOk tErr h₁ =>
      -- h₁ : HasType emptyTypeEnv (lit (vOkay v)) (result tOk tErr)
      -- By inversion via tOkayVal, the inner value v has type tOk.
      cases h₁ with
      | tOkayVal _ _ hinner => exact hinner
  | sUnwrapError s _ =>
    cases ht with
    | tUnwrap _ tOk tErr h₁ =>
      -- unwrap(oops(s)) steps to (error s), which is well-typed at any type
      -- via tError. This models runtime panic propagation.
      exact .tError _ s t
  | sUnwrapCong e e' ρ ρ' hs₁ ih =>
    cases ht with
    | tUnwrap _ _ tErr h₁ => exact .tUnwrap _ _ _ _ (ih _ h₁)
  | sBinOpErrLeft op msg e₂ _ =>
    -- error propagates through binOp — result is error, typed at any type via tError.
    cases ht with
    | tAddInt _ _ h₁ h₂ => exact .tError _ msg _
    | tAddFloat _ _ h₁ h₂ => exact .tError _ msg _
    | tAddString _ _ h₁ h₂ => exact .tError _ msg _
    | tEq _ _ _ h₁ h₂ => exact .tError _ msg _
    | tAnd _ _ h₁ h₂ => exact .tError _ msg _
    | tOr _ _ h₁ h₂ => exact .tError _ msg _
    | tSubInt _ _ h₁ h₂ => exact .tError _ msg _
    | tMulInt _ _ h₁ h₂ => exact .tError _ msg _
    | tLt _ _ h₁ h₂ => exact .tError _ msg _
    | tGt _ _ h₁ h₂ => exact .tError _ msg _
    | tLe _ _ h₁ h₂ => exact .tError _ msg _
    | tGe _ _ h₁ h₂ => exact .tError _ msg _
    | tDivInt _ _ h₁ h₂ => exact .tError _ msg _
    | tModInt _ _ h₁ h₂ => exact .tError _ msg _
  | sBinOpErrRight op v₁ msg _ =>
    cases ht with
    | tAddInt _ _ h₁ h₂ => exact .tError _ msg _
    | tAddFloat _ _ h₁ h₂ => exact .tError _ msg _
    | tAddString _ _ h₁ h₂ => exact .tError _ msg _
    | tEq _ _ _ h₁ h₂ => exact .tError _ msg _
    | tAnd _ _ h₁ h₂ => exact .tError _ msg _
    | tOr _ _ h₁ h₂ => exact .tError _ msg _
    | tSubInt _ _ h₁ h₂ => exact .tError _ msg _
    | tMulInt _ _ h₁ h₂ => exact .tError _ msg _
    | tLt _ _ h₁ h₂ => exact .tError _ msg _
    | tGt _ _ h₁ h₂ => exact .tError _ msg _
    | tLe _ _ h₁ h₂ => exact .tError _ msg _
    | tGe _ _ h₁ h₂ => exact .tError _ msg _
    | tDivInt _ _ h₁ h₂ => exact .tError _ msg _
    | tModInt _ _ h₁ h₂ => exact .tError _ msg _
  | sUnOpErr op msg _ =>
    cases ht with
    | tNegInt _ h₁ => exact .tError _ msg _
    | tNegFloat _ h₁ => exact .tError _ msg _
    | tNot _ h₁ => exact .tError _ msg _
  | sOkayErr msg _ =>
    cases ht with
    | tOkay _ _ h₁ => exact .tError _ msg _
  | sOopsErr msg _ =>
    cases ht with
    | tOops _ _ h₁ => exact .tError _ msg _
  | sUnwrapErr msg _ =>
    cases ht with
    | tUnwrap _ tOk tErr h₁ => exact .tError _ msg _
  | sArrayStep vs e e' rest ρ ρ' hs ih =>
    -- Congruence: the stepped element keeps its type (by the IH); every other
    -- element keeps the witness it had from the original `tArray` derivation.
    cases ht with
    | tArray _ t' hall =>
      refine .tArray _ _ t' (fun x hx => ?_)
      rcases List.mem_append.1 hx with hpre | hcons
      · exact hall x (List.mem_append.2 (Or.inl hpre))
      · rcases List.mem_cons.1 hcons with rfl | htail
        · exact ih t' (hall e (List.mem_append.2 (Or.inr List.mem_cons_self)))
        · exact hall x (List.mem_append.2 (Or.inr (List.mem_cons_of_mem _ htail)))
  | sArrayVal vs ρ =>
    -- Normalisation: `.array (vs.map lit) : array t'` becomes the literal value
    -- `.lit (.vArray vs) : array t'`, re-typed via `tArrayVal`.
    cases ht with
    | tArray _ t' hall =>
      exact .tArrayVal _ vs t' (fun v hv => hall (Expr.lit v) (List.mem_map.2 ⟨v, hv, rfl⟩))
  | sArrayErr vs msg rest ρ =>
    -- Panic propagation: the result `.error msg` is well-typed at any type.
    exact .tError _ msg _

/-- Type safety theorem -/
theorem type_safety : ∀ e t v ρ,
  HasType emptyTypeEnv e t →
  MultiStep e emptyEnv (.lit v) ρ →
  HasType emptyTypeEnv (.lit v) t := by
  intro e t v ρ ht hms
  -- emptyEnv and (lit v) are concrete indices of hms; generalise them so the
  -- induction on MultiStep is well-formed. The start value-env need not be
  -- empty (preservation holds for any env), so its equation is cleared.
  generalize hev : (Expr.lit v) = ev at hms ⊢
  generalize hρ0 : emptyEnv = ρ0 at hms
  clear hρ0
  induction hms with
  | refl => exact ht
  | step e₁ e₂ e₃ ρ₁ ρ₂ ρ₃ hs hms' ih =>
    exact ih (preservation e₁ e₂ t ρ₁ ρ₂ ht hs) hev

-- =========================================================================
-- 5b. Statement Typing
-- =========================================================================

/- Statement typing threads a type context: `StmtWellTyped Γ s Γ'` reads
   "in context `Γ`, statement `s` is well-typed and yields context `Γ'`".
   `varDecl` extends the context with the declared binding; `assign` requires
   the variable to already be declared at the assigned type; compound
   statements (`if`/`loop`/`attempt`/`consent`) are block-scoped, so they
   return the incoming context. Mutually inductive with `StmtsWellTyped`,
   which threads the context left-to-right through a block.

   This is the statement-level analogue of the expression `HasType` judgment;
   statements were previously declared (`Stmt`) but had no typing rules. The
   dynamic story (a statement execution relation + a store-typing preservation
   theorem) is the natural next step and is noted in AUDIT.md. -/
mutual
inductive StmtWellTyped : TypeEnv → Stmt → TypeEnv → Prop where
  | varDecl : ∀ Γ x e t,
      HasType Γ e t →
      StmtWellTyped Γ (.varDecl x e) (extendTypeEnv x t Γ)
  | assign : ∀ Γ x e t,
      Γ x = some t → HasType Γ e t →
      StmtWellTyped Γ (.assign x e) Γ
  | return_ : ∀ Γ e t,
      HasType Γ e t →
      StmtWellTyped Γ (.return_ e) Γ
  | if_ : ∀ Γ c thn els Γ₁ Γ₂,
      HasType Γ c .bool → StmtsWellTyped Γ thn Γ₁ → StmtsWellTyped Γ els Γ₂ →
      StmtWellTyped Γ (.if_ c thn els) Γ
  | loop : ∀ Γ c body Γ₁,
      HasType Γ c .bool → StmtsWellTyped Γ body Γ₁ →
      StmtWellTyped Γ (.loop c body) Γ
  | attempt : ∀ Γ body hname Γ₁,
      StmtsWellTyped Γ body Γ₁ →
      StmtWellTyped Γ (.attempt body hname) Γ
  | consent : ∀ Γ p body Γ₁,
      StmtsWellTyped Γ body Γ₁ →
      StmtWellTyped Γ (.consent p body) Γ
  | expr : ∀ Γ e t,
      HasType Γ e t →
      StmtWellTyped Γ (.expr e) Γ
  | complain : ∀ Γ m,
      StmtWellTyped Γ (.complain m) Γ
inductive StmtsWellTyped : TypeEnv → List Stmt → TypeEnv → Prop where
  | nil : ∀ Γ, StmtsWellTyped Γ [] Γ
  | cons : ∀ Γ s ss Γ₁ Γ₂,
      StmtWellTyped Γ s Γ₁ → StmtsWellTyped Γ₁ ss Γ₂ →
      StmtsWellTyped Γ (s :: ss) Γ₂
end

/-- Domain containment on type contexts: every variable declared in `Γ` is
    still declared (at some type) in `Γ'`. -/
def CtxDomSub (Γ Γ' : TypeEnv) : Prop := ∀ x t, Γ x = some t → ∃ t', Γ' x = some t'

theorem ctxDomSub_refl (Γ : TypeEnv) : CtxDomSub Γ Γ := fun _ t h => ⟨t, h⟩

theorem ctxDomSub_trans {Γ₁ Γ₂ Γ₃ : TypeEnv}
    (h₁₂ : CtxDomSub Γ₁ Γ₂) (h₂₃ : CtxDomSub Γ₂ Γ₃) : CtxDomSub Γ₁ Γ₃ :=
  fun x t h => let ⟨t', h'⟩ := h₁₂ x t h; h₂₃ x t' h'

theorem ctxDomSub_extend (Γ : TypeEnv) (x : String) (t : WokeType) :
    CtxDomSub Γ (extendTypeEnv x t Γ) := by
  intro y ty hy
  by_cases hxy : x = y
  · exact ⟨t, by simp [extendTypeEnv, hxy]⟩
  · exact ⟨ty, by simp [extendTypeEnv, hxy, hy]⟩

/-- Context monotonicity (single statement): a well-typed statement never
    undeclares a variable. Non-recursive — compound statements are
    block-scoped, which breaks the mutual dependency for the proof. -/
theorem stmt_wellTyped_mono {Γ s Γ'} (h : StmtWellTyped Γ s Γ') : CtxDomSub Γ Γ' := by
  cases h with
  | varDecl Γ x e t _ => exact ctxDomSub_extend Γ x t
  | assign => exact ctxDomSub_refl _
  | return_ => exact ctxDomSub_refl _
  | if_ => exact ctxDomSub_refl _
  | loop => exact ctxDomSub_refl _
  | attempt => exact ctxDomSub_refl _
  | consent => exact ctxDomSub_refl _
  | expr => exact ctxDomSub_refl _
  | complain => exact ctxDomSub_refl _

/-- Context monotonicity (statement block), by induction on the block. -/
theorem stmts_wellTyped_mono {Γ ss Γ'} (h : StmtsWellTyped Γ ss Γ') : CtxDomSub Γ Γ' := by
  induction ss generalizing Γ Γ' with
  | nil => cases h; exact ctxDomSub_refl _
  | cons s rest ih =>
    cases h with
    | cons _ _ _ Γ₁ _ hs hrest => exact ctxDomSub_trans (stmt_wellTyped_mono hs) (ih hrest)

/-- Sequencing composes: typing a block then another block from the resulting
    context types their concatenation. -/
theorem stmts_wellTyped_append {Γ ss₁ Γ' ss₂ Γ''}
    (h₁ : StmtsWellTyped Γ ss₁ Γ') (h₂ : StmtsWellTyped Γ' ss₂ Γ'') :
    StmtsWellTyped Γ (ss₁ ++ ss₂) Γ'' := by
  induction ss₁ generalizing Γ Γ' with
  | nil => cases h₁; exact h₂
  | cons s rest ih =>
    cases h₁ with
    | cons _ _ _ Γ₁ _ hs hrest => exact .cons _ _ _ _ _ hs (ih hrest h₂)

/-- Inhabitation smoke: `let x = 0; x` is a well-typed block, yielding a
    context in which `x : int`. -/
theorem stmts_wellTyped_example :
    StmtsWellTyped emptyTypeEnv
      [Stmt.varDecl "x" (.lit (.vInt 0)), Stmt.expr (.var "x")]
      (extendTypeEnv "x" .int emptyTypeEnv) :=
  .cons _ _ _ _ _
    (.varDecl _ "x" (.lit (.vInt 0)) .int (.tInt _ _))
    (.cons _ _ _ _ _
      (.expr _ (.var "x") .int (.tVar _ "x" .int (by simp [extendTypeEnv])))
      (.nil _))

-- =========================================================================
-- 6. Consent System
-- =========================================================================

abbrev Permission := String

def ConsentState := Permission → Bool

def emptyConsent : ConsentState := fun _ => false

def grantConsent (p : Permission) (c : ConsentState) : ConsentState :=
  fun q => if p == q then true else c q

def checkConsent (p : Permission) (c : ConsentState) : Bool :=
  c p

/-- Consent monotonicity -/
theorem consent_monotonicity : ∀ p c,
  checkConsent p (grantConsent p c) = true := by
  intro p c
  simp [checkConsent, grantConsent]

/-- Consent preservation for other permissions -/
theorem consent_preservation : ∀ p q c,
  p ≠ q →
  checkConsent q c = checkConsent q (grantConsent p c) := by
  intro p q c hneq
  simp [checkConsent, grantConsent]
  intro h
  exact absurd h hneq

-- =========================================================================
-- 7. Capability System
-- =========================================================================

inductive Capability where
  | fileRead : Option String → Capability
  | fileWrite : Option String → Capability
  | network : Option String → Capability
  | execute : Option String → Capability
  | process : Capability
  | crypto : Capability
  deriving Repr, DecidableEq

def CapabilitySet := List Capability

/-- Capability subsumption -/
def capSubsumes (c₁ c₂ : Capability) : Bool :=
  match c₁, c₂ with
  | .fileRead none, .fileRead _ => true
  | .fileWrite none, .fileWrite _ => true
  | .network none, .network _ => true
  | .execute none, .execute _ => true
  | c₁, c₂ => c₁ == c₂

/-- Check if capability set contains a capability -/
def hasCapability (c : Capability) (cs : CapabilitySet) : Bool :=
  cs.any (fun c' => capSubsumes c' c)

-- Capability subsumption is a PREORDER (reflexive + transitive).
-- This is the order shape that echo-types' `DecorationStructure` requires
-- (`≤-refl`, `≤-trans`) to host echo decorations — see docs AUDIT.md
-- "echo-types compatibility". Proving it here keeps WokeLang's capability
-- lattice on-path for a future echo/loss layer (the Ephapax L3 precedent).

/-- Capability subsumption is reflexive. -/
theorem capSubsumes_refl (c : Capability) : capSubsumes c c = true := by
  cases c with
  | fileRead o => cases o <;> simp [capSubsumes]
  | fileWrite o => cases o <;> simp [capSubsumes]
  | network o => cases o <;> simp [capSubsumes]
  | execute o => cases o <;> simp [capSubsumes]
  | process => simp [capSubsumes]
  | crypto => simp [capSubsumes]

/-- Capability subsumption is transitive. -/
theorem capSubsumes_trans (c₁ c₂ c₃ : Capability) :
    capSubsumes c₁ c₂ = true → capSubsumes c₂ c₃ = true → capSubsumes c₁ c₃ = true := by
  cases c₁ <;> cases c₂ <;> cases c₃ <;> simp_all [capSubsumes]
  all_goals (rename_i a₁ a₂ a₃; cases a₁ <;> cases a₂ <;> cases a₃ <;> simp_all)

/-- Capability subsumption is antisymmetric: mutual subsumption is equality.
Together with `_refl`/`_trans` this makes `capSubsumes` a genuine PARTIAL order
(`Phase 2a` of the verification roadmap). -/
theorem capSubsumes_antisymm (c₁ c₂ : Capability) :
    capSubsumes c₁ c₂ = true → capSubsumes c₂ c₁ = true → c₁ = c₂ := by
  cases c₁ <;> cases c₂ <;> simp_all [capSubsumes]
  all_goals (rename_i a₁ a₂; cases a₁ <;> cases a₂ <;> simp_all)

/-- **Satisfaction is monotone in the capability set:** more capabilities can only
satisfy more requests. -/
theorem hasCapability_mono {c : Capability} {cs cs' : List Capability}
    (hsub : cs ⊆ cs') (h : hasCapability c cs = true) : hasCapability c cs' = true := by
  simp only [hasCapability, List.any_eq_true] at h ⊢
  obtain ⟨c', hmem, hc'⟩ := h
  exact ⟨c', hsub hmem, hc'⟩

/-- **Satisfaction respects subsumption:** if the held capability `c'` subsumes the
requested `c`, then a set satisfying `c'` also satisfies `c`. -/
theorem hasCapability_subsumes {c c' : Capability} {cs : CapabilitySet}
    (hsub : capSubsumes c' c = true) (h : hasCapability c' cs = true) :
    hasCapability c cs = true := by
  simp only [hasCapability, List.any_eq_true] at h ⊢
  obtain ⟨d, hmem, hd⟩ := h
  exact ⟨d, hmem, capSubsumes_trans d c' c hd hsub⟩

-- =========================================================================
-- 7b. Substitution lemma (roadmap Phase 1 core / type-safety.md Lemma 3.4)
-- =========================================================================

/-- Substitute the (closed) value `v` for the free variable `x` in an expression.
Capture-avoiding is trivial here: values are closed, and `Expr` has no binders. -/
def subst (x : String) (v : Value) : Expr → Expr
  | .lit w => .lit w
  | .var y => if x == y then .lit v else .var y
  | .binOp op a b => .binOp op (subst x v a) (subst x v b)
  | .unOp op a => .unOp op (subst x v a)
  | .call f args => .call f (args.map (subst x v))
  | .array es => .array (es.map (subst x v))
  | .okay a => .okay (subst x v a)
  | .oops a => .oops (subst x v a)
  | .unwrap a => .unwrap (subst x v a)
  | .error msg => .error msg

/-- **Substitution Lemma.** If `e` is well typed under `Γ` extended with `x : tx`,
and `v` is a value of type `tx` under `Γ`, then `subst x v e` is well typed under
`Γ` at the same type. Proved by induction on the typing derivation, with the
context generalized. This is the prerequisite for `[T-Call]`'s preservation case
and for Algorithm W's soundness (roadmap Phases 1, 3a). -/
theorem subst_preserves_typing {x : String} {v : Value} {tx : WokeType} :
    ∀ {Δ e t}, HasType Δ e t → ∀ {Γ}, Δ = extendTypeEnv x tx Γ →
      HasType Γ (.lit v) tx → HasType Γ (subst x v e) t := by
  intro Δ e t h
  induction h with
  | tInt n => intro Γ _ _; simp only [subst]; exact .tInt _ _
  | tFloat f => intro Γ _ _; simp only [subst]; exact .tFloat _ _
  | tString s => intro Γ _ _; simp only [subst]; exact .tString _ _
  | tBool b => intro Γ _ _; simp only [subst]; exact .tBool _ _
  | tUnit => intro Γ _ _; simp only [subst]; exact .tUnit _
  | tOkayVal w t' _ ih =>
      intro Γ hΔ hv; simp only [subst]
      exact .tOkayVal _ _ _ (by simpa only [subst] using ih hΔ hv)
  | tOopsVal s t' => intro Γ _ _; simp only [subst]; exact .tOopsVal _ _ _
  | tVar y t' hy =>
      intro Γ hΔ hv; subst hΔ
      by_cases hyx : (x == y) = true
      · rw [show subst x v (.var y) = .lit v from by simp only [subst]; rw [if_pos hyx]]
        have he : extendTypeEnv x tx Γ y = some tx := by
          simp only [extendTypeEnv]; rw [if_pos hyx]
        rw [he] at hy; injection hy with hty; subst hty; exact hv
      · rw [show subst x v (.var y) = .var y from by simp only [subst]; rw [if_neg hyx]]
        refine .tVar _ _ _ ?_
        have he : extendTypeEnv x tx Γ y = Γ y := by
          simp only [extendTypeEnv]; rw [if_neg hyx]
        rw [he] at hy; exact hy
  | tAddInt a b _ _ ih₁ ih₂ => intro Γ hΔ hv; simp only [subst]; exact .tAddInt _ _ _ (ih₁ hΔ hv) (ih₂ hΔ hv)
  | tAddFloat a b _ _ ih₁ ih₂ => intro Γ hΔ hv; simp only [subst]; exact .tAddFloat _ _ _ (ih₁ hΔ hv) (ih₂ hΔ hv)
  | tAddString a b _ _ ih₁ ih₂ => intro Γ hΔ hv; simp only [subst]; exact .tAddString _ _ _ (ih₁ hΔ hv) (ih₂ hΔ hv)
  | tEq a b t' _ _ ih₁ ih₂ => intro Γ hΔ hv; simp only [subst]; exact .tEq _ _ _ _ (ih₁ hΔ hv) (ih₂ hΔ hv)
  | tAnd a b _ _ ih₁ ih₂ => intro Γ hΔ hv; simp only [subst]; exact .tAnd _ _ _ (ih₁ hΔ hv) (ih₂ hΔ hv)
  | tOr a b _ _ ih₁ ih₂ => intro Γ hΔ hv; simp only [subst]; exact .tOr _ _ _ (ih₁ hΔ hv) (ih₂ hΔ hv)
  | tSubInt a b _ _ ih₁ ih₂ => intro Γ hΔ hv; simp only [subst]; exact .tSubInt _ _ _ (ih₁ hΔ hv) (ih₂ hΔ hv)
  | tMulInt a b _ _ ih₁ ih₂ => intro Γ hΔ hv; simp only [subst]; exact .tMulInt _ _ _ (ih₁ hΔ hv) (ih₂ hΔ hv)
  | tLt a b _ _ ih₁ ih₂ => intro Γ hΔ hv; simp only [subst]; exact .tLt _ _ _ (ih₁ hΔ hv) (ih₂ hΔ hv)
  | tGt a b _ _ ih₁ ih₂ => intro Γ hΔ hv; simp only [subst]; exact .tGt _ _ _ (ih₁ hΔ hv) (ih₂ hΔ hv)
  | tLe a b _ _ ih₁ ih₂ => intro Γ hΔ hv; simp only [subst]; exact .tLe _ _ _ (ih₁ hΔ hv) (ih₂ hΔ hv)
  | tGe a b _ _ ih₁ ih₂ => intro Γ hΔ hv; simp only [subst]; exact .tGe _ _ _ (ih₁ hΔ hv) (ih₂ hΔ hv)
  | tDivInt a b _ _ ih₁ ih₂ => intro Γ hΔ hv; simp only [subst]; exact .tDivInt _ _ _ (ih₁ hΔ hv) (ih₂ hΔ hv)
  | tModInt a b _ _ ih₁ ih₂ => intro Γ hΔ hv; simp only [subst]; exact .tModInt _ _ _ (ih₁ hΔ hv) (ih₂ hΔ hv)
  | tNegInt a _ ih => intro Γ hΔ hv; simp only [subst]; exact .tNegInt _ _ (ih hΔ hv)
  | tNegFloat a _ ih => intro Γ hΔ hv; simp only [subst]; exact .tNegFloat _ _ (ih hΔ hv)
  | tNot a _ ih => intro Γ hΔ hv; simp only [subst]; exact .tNot _ _ (ih hΔ hv)
  | tOkay a t' _ ih => intro Γ hΔ hv; simp only [subst]; exact .tOkay _ _ _ (ih hΔ hv)
  | tOops a t' _ ih => intro Γ hΔ hv; simp only [subst]; exact .tOops _ _ _ (ih hΔ hv)
  | tUnwrap a tOk tErr _ ih => intro Γ hΔ hv; simp only [subst]; exact .tUnwrap _ _ _ _ (ih hΔ hv)
  | tError msg t' => intro Γ _ _; simp only [subst]; exact .tError _ _ _
  | tArray es t' _ ih =>
      intro Γ hΔ hv
      simp only [subst]
      refine .tArray _ _ t' (fun e' he' => ?_)
      rw [List.mem_map] at he'
      obtain ⟨e0, he0, rfl⟩ := he'
      exact ih e0 he0 hΔ hv
  | tArrayVal vs t' _ ih =>
      intro Γ hΔ hv
      simp only [subst]
      exact .tArrayVal _ _ _ (fun w hw => by simpa only [subst] using ih w hw hΔ hv)

-- =========================================================================
-- 7c. Store typing (roadmap Phase 1b foundation)
-- =========================================================================

/-- **Store typing.** The runtime store `ρ` agrees with the type context `Γ`:
every variable `Γ` types is bound in `ρ` to a value of that type. This is the
bridge between the static `TypeEnv` and the dynamic `Env`, and the invariant every
statement-execution preservation theorem is stated against. -/
def StoreWellTyped (Γ : TypeEnv) (ρ : Env) : Prop :=
  ∀ x t, Γ x = some t → ∃ v, ρ x = some v ∧ HasType emptyTypeEnv (.lit v) t

/-- The empty store is well typed against the empty context. -/
theorem store_wellTyped_empty : StoreWellTyped emptyTypeEnv emptyEnv := by
  intro x t h; simp [emptyTypeEnv] at h

/-- Looking up a typed variable in a well-typed store yields a value of that type. -/
theorem store_wellTyped_lookup {Γ : TypeEnv} {ρ : Env} {x : String} {t : WokeType}
    (hs : StoreWellTyped Γ ρ) (hx : Γ x = some t) :
    ∃ v, ρ x = some v ∧ HasType emptyTypeEnv (.lit v) t := hs x t hx

/-- **Store-extension lemma.** Extending the context and the store in lockstep with
a value of the declared type preserves store typing. This is exactly what a
`varDecl` statement does to the runtime, and the key step for its preservation. -/
theorem store_wellTyped_extend {Γ : TypeEnv} {ρ : Env} {x : String} {t : WokeType}
    {v : Value} (hs : StoreWellTyped Γ ρ) (hv : HasType emptyTypeEnv (.lit v) t) :
    StoreWellTyped (extendTypeEnv x t Γ) (extendEnv x v ρ) := by
  intro y ty hy
  simp only [extendTypeEnv] at hy
  by_cases hxy : (x == y) = true
  · rw [if_pos hxy] at hy; injection hy with hty; subst hty
    exact ⟨v, by simp only [extendEnv]; rw [if_pos hxy], hv⟩
  · rw [if_neg hxy] at hy
    obtain ⟨v', hv', hvt⟩ := hs y ty hy
    refine ⟨v', ?_, hvt⟩
    simp only [extendEnv]; rw [if_neg hxy]; exact hv'

-- =========================================================================
-- 7d. Expression-evaluation invariants under a store (Phase 1b substrate)
-- =========================================================================

/-- **Expression evaluation never mutates the store.** Every base reduction
returns the store it was given, and every congruence rule threads the
sub-step's store unchanged, so a single expression step leaves `ρ` fixed. This
is what lets statement execution compose: an expression sub-evaluation inside a
statement cannot disturb the variable bindings the statement effect then acts on. -/
theorem step_store_invariant {e e' : Expr} {ρ ρ' : Env}
    (h : Step e ρ e' ρ') : ρ' = ρ := by
  induction h with
  | sBinOpLeft _ _ _ _ _ _ _ ih => exact ih
  | sBinOpRight _ _ _ _ _ _ _ _ ih => exact ih
  | sUnOpCong _ _ _ _ _ _ ih => exact ih
  | sOkayCong _ _ _ _ _ ih => exact ih
  | sOopsCong _ _ _ _ _ ih => exact ih
  | sUnwrapCong _ _ _ _ _ ih => exact ih
  | sArrayStep _ _ _ _ _ _ _ ih => exact ih
  | _ => rfl

/-- Multi-step evaluation is store-preserving too, by transitivity. -/
theorem multiStep_store_invariant {e e' : Expr} {ρ ρ' : Env}
    (h : MultiStep e ρ e' ρ') : ρ' = ρ := by
  induction h with
  | refl => rfl
  | step _ _ _ _ _ _ hs _ ih => rw [ih]; exact step_store_invariant hs

/-- **Literal typing is context-independent.** A literal value's type is
determined structurally and never consults the type context, so a typing for
`.lit v` in one context holds in any context. This is the weakening that lifts
`StoreWellTyped`'s `HasType emptyTypeEnv (.lit v) t` into the arbitrary context
`Γ` that statement-level expression typing lives in. -/
theorem hasType_lit_any {Γ Γ' : TypeEnv} {v : Value} {t : WokeType}
    (h : HasType Γ (.lit v) t) : HasType Γ' (.lit v) t := by
  -- Generalise to a same-expression form so the `vOkay`/`vArray` recursions get
  -- usable induction hypotheses; the `∃ w, e = .lit w` guard rules out the
  -- non-literal typing rules (which `induction` still enumerates).
  have gen : ∀ {Δ e t'}, HasType Δ e t' → ∀ {Δ'}, (∃ w, e = .lit w) → HasType Δ' e t' := by
    intro Δ e t' hh
    induction hh with
    | tInt n => intro _ _; exact .tInt _ _
    | tFloat f => intro _ _; exact .tFloat _ _
    | tString s => intro _ _; exact .tString _ _
    | tBool b => intro _ _; exact .tBool _ _
    | tUnit => intro _ _; exact .tUnit _
    | tOkayVal w t'' _ ih => intro _ _; exact .tOkayVal _ _ _ (ih ⟨w, rfl⟩)
    | tOopsVal s t'' => intro _ _; exact .tOopsVal _ _ _
    | tArrayVal vs t'' _ ih => intro _ _; exact .tArrayVal _ _ _ (fun w hw => ih w hw ⟨w, rfl⟩)
    | _ => intro _ hlit; obtain ⟨w, hw⟩ := hlit; nomatch hw
  exact gen h ⟨v, rfl⟩

/-- **Store-typed preservation.** The expression preservation theorem
generalised from the empty context to an arbitrary type context `Γ`, under a
store typing `StoreWellTyped Γ ρ`. This is the form statement execution needs:
expressions inside a statement are typed in the running context, not in the
empty one. Mirrors `preservation`; the *only* case that differs is `sVar`,
which here discharges via `store_wellTyped_lookup` + `hasType_lit_any` (the
runtime value bound to `x` has the type `Γ` assigns `x`) instead of the
empty-context contradiction. -/
theorem store_step_preservation {Γ : TypeEnv} {e e' : Expr} {ρ ρ' : Env} {t : WokeType}
    (hst : StoreWellTyped Γ ρ) (ht : HasType Γ e t) (hs : Step e ρ e' ρ') :
    HasType Γ e' t := by
  induction hs generalizing t with
  | sVar x ρ₀ v hx =>
    cases ht with
    | tVar _ _ hxt =>
      obtain ⟨v', hv', hvt⟩ := hst x t hxt
      rw [hx] at hv'; injection hv' with hvv; subst hvv
      exact hasType_lit_any hvt
  | sBinOpLeft op e₁ e₁' e₂ ρ ρ' hs₁ ih =>
    cases ht with
    | tAddInt _ _ h₁ h₂ => exact .tAddInt _ _ _ (ih hst h₁) h₂
    | tAddFloat _ _ h₁ h₂ => exact .tAddFloat _ _ _ (ih hst h₁) h₂
    | tAddString _ _ h₁ h₂ => exact .tAddString _ _ _ (ih hst h₁) h₂
    | tEq _ _ _ h₁ h₂ => exact .tEq _ _ _ _ (ih hst h₁) h₂
    | tAnd _ _ h₁ h₂ => exact .tAnd _ _ _ (ih hst h₁) h₂
    | tOr _ _ h₁ h₂ => exact .tOr _ _ _ (ih hst h₁) h₂
    | tSubInt _ _ h₁ h₂ => exact .tSubInt _ _ _ (ih hst h₁) h₂
    | tMulInt _ _ h₁ h₂ => exact .tMulInt _ _ _ (ih hst h₁) h₂
    | tLt _ _ h₁ h₂ => exact .tLt _ _ _ (ih hst h₁) h₂
    | tGt _ _ h₁ h₂ => exact .tGt _ _ _ (ih hst h₁) h₂
    | tLe _ _ h₁ h₂ => exact .tLe _ _ _ (ih hst h₁) h₂
    | tGe _ _ h₁ h₂ => exact .tGe _ _ _ (ih hst h₁) h₂
    | tDivInt _ _ h₁ h₂ => exact .tDivInt _ _ _ (ih hst h₁) h₂
    | tModInt _ _ h₁ h₂ => exact .tModInt _ _ _ (ih hst h₁) h₂
  | sBinOpRight op v₁ e₂ e₂' ρ ρ' _hv hs₂ ih =>
    cases ht with
    | tAddInt _ _ h₁ h₂ => exact .tAddInt _ _ _ h₁ (ih hst h₂)
    | tAddFloat _ _ h₁ h₂ => exact .tAddFloat _ _ _ h₁ (ih hst h₂)
    | tAddString _ _ h₁ h₂ => exact .tAddString _ _ _ h₁ (ih hst h₂)
    | tEq _ _ _ h₁ h₂ => exact .tEq _ _ _ _ h₁ (ih hst h₂)
    | tAnd _ _ h₁ h₂ => exact .tAnd _ _ _ h₁ (ih hst h₂)
    | tOr _ _ h₁ h₂ => exact .tOr _ _ _ h₁ (ih hst h₂)
    | tSubInt _ _ h₁ h₂ => exact .tSubInt _ _ _ h₁ (ih hst h₂)
    | tMulInt _ _ h₁ h₂ => exact .tMulInt _ _ _ h₁ (ih hst h₂)
    | tLt _ _ h₁ h₂ => exact .tLt _ _ _ h₁ (ih hst h₂)
    | tGt _ _ h₁ h₂ => exact .tGt _ _ _ h₁ (ih hst h₂)
    | tLe _ _ h₁ h₂ => exact .tLe _ _ _ h₁ (ih hst h₂)
    | tGe _ _ h₁ h₂ => exact .tGe _ _ _ h₁ (ih hst h₂)
    | tDivInt _ _ h₁ h₂ => exact .tDivInt _ _ _ h₁ (ih hst h₂)
    | tModInt _ _ h₁ h₂ => exact .tModInt _ _ _ h₁ (ih hst h₂)
  | sAddInt n₁ n₂ _ =>
    cases ht with
    | tAddInt _ _ h₁ h₂ => exact .tInt _ _
    | tAddFloat _ _ h₁ _ => nomatch h₁
    | tAddString _ _ h₁ _ => nomatch h₁
  | sAddFloat f₁ f₂ _ =>
    cases ht with
    | tAddFloat _ _ h₁ h₂ => exact .tFloat _ _
    | tAddInt _ _ h₁ _ => nomatch h₁
    | tAddString _ _ h₁ _ => nomatch h₁
  | sAddString s₁ s₂ _ =>
    cases ht with
    | tAddString _ _ h₁ h₂ => exact .tString _ _
    | tAddInt _ _ h₁ _ => nomatch h₁
    | tAddFloat _ _ h₁ _ => nomatch h₁
  | sEqTrue v _ =>
    cases ht with
    | tEq _ _ _ h₁ h₂ => exact .tBool _ _
  | sEqFalse v₁ v₂ _ hneq =>
    cases ht with
    | tEq _ _ _ h₁ h₂ => exact .tBool _ _
  | sAnd b₁ b₂ _ =>
    cases ht with
    | tAnd _ _ h₁ h₂ => exact .tBool _ _
  | sOr b₁ b₂ _ =>
    cases ht with
    | tOr _ _ h₁ h₂ => exact .tBool _ _
  | sSubInt n₁ n₂ _ =>
    cases ht with
    | tSubInt _ _ h₁ h₂ => exact .tInt _ _
  | sMulInt n₁ n₂ _ =>
    cases ht with
    | tMulInt _ _ h₁ h₂ => exact .tInt _ _
  | sLt n₁ n₂ _ =>
    cases ht with
    | tLt _ _ h₁ h₂ => exact .tBool _ _
  | sGt n₁ n₂ _ =>
    cases ht with
    | tGt _ _ h₁ h₂ => exact .tBool _ _
  | sLe n₁ n₂ _ =>
    cases ht with
    | tLe _ _ h₁ h₂ => exact .tBool _ _
  | sGe n₁ n₂ _ =>
    cases ht with
    | tGe _ _ h₁ h₂ => exact .tBool _ _
  | sDivInt n₁ n₂ _ _ =>
    cases ht with
    | tDivInt _ _ h₁ h₂ => exact .tInt _ _
  | sDivZero n₁ n₂ _ _ =>
    cases ht with
    | tDivInt _ _ h₁ h₂ => exact .tError _ _ _
  | sModInt n₁ n₂ _ _ =>
    cases ht with
    | tModInt _ _ h₁ h₂ => exact .tInt _ _
  | sModZero n₁ n₂ _ _ =>
    cases ht with
    | tModInt _ _ h₁ h₂ => exact .tError _ _ _
  | sNegInt n _ =>
    cases ht with
    | tNegInt _ h₁ => exact .tInt _ _
    | tNegFloat _ h₁ => nomatch h₁
  | sNegFloat f _ =>
    cases ht with
    | tNegFloat _ h₁ => exact .tFloat _ _
    | tNegInt _ h₁ => nomatch h₁
  | sNot b _ =>
    cases ht with
    | tNot _ h₁ => exact .tBool _ _
  | sUnOpCong op e e' ρ ρ' hs₁ ih =>
    cases ht with
    | tNegInt _ h₁ => exact .tNegInt _ _ (ih hst h₁)
    | tNegFloat _ h₁ => exact .tNegFloat _ _ (ih hst h₁)
    | tNot _ h₁ => exact .tNot _ _ (ih hst h₁)
  | sOkay v _ _hv =>
    cases ht with
    | tOkay _ _ h₁ => exact .tOkayVal _ v _ h₁
  | sOkayCong e e' ρ ρ' hs₁ ih =>
    cases ht with
    | tOkay _ _ h₁ => exact .tOkay _ _ _ (ih hst h₁)
  | sOops s _ =>
    cases ht with
    | tOops _ _ h₁ => exact .tOopsVal _ s _
  | sOopsCong e e' ρ ρ' hs₁ ih =>
    cases ht with
    | tOops _ _ h₁ => exact .tOops _ _ _ (ih hst h₁)
  | sUnwrapOkay v _ =>
    cases ht with
    | tUnwrap _ tOk tErr h₁ =>
      cases h₁ with
      | tOkayVal _ _ hinner => exact hinner
  | sUnwrapError s _ =>
    cases ht with
    | tUnwrap _ tOk tErr h₁ => exact .tError _ s t
  | sUnwrapCong e e' ρ ρ' hs₁ ih =>
    cases ht with
    | tUnwrap _ _ tErr h₁ => exact .tUnwrap _ _ _ _ (ih hst h₁)
  | sBinOpErrLeft op msg e₂ _ =>
    cases ht with
    | tAddInt _ _ h₁ h₂ => exact .tError _ msg _
    | tAddFloat _ _ h₁ h₂ => exact .tError _ msg _
    | tAddString _ _ h₁ h₂ => exact .tError _ msg _
    | tEq _ _ _ h₁ h₂ => exact .tError _ msg _
    | tAnd _ _ h₁ h₂ => exact .tError _ msg _
    | tOr _ _ h₁ h₂ => exact .tError _ msg _
    | tSubInt _ _ h₁ h₂ => exact .tError _ msg _
    | tMulInt _ _ h₁ h₂ => exact .tError _ msg _
    | tLt _ _ h₁ h₂ => exact .tError _ msg _
    | tGt _ _ h₁ h₂ => exact .tError _ msg _
    | tLe _ _ h₁ h₂ => exact .tError _ msg _
    | tGe _ _ h₁ h₂ => exact .tError _ msg _
    | tDivInt _ _ h₁ h₂ => exact .tError _ msg _
    | tModInt _ _ h₁ h₂ => exact .tError _ msg _
  | sBinOpErrRight op v₁ msg _ =>
    cases ht with
    | tAddInt _ _ h₁ h₂ => exact .tError _ msg _
    | tAddFloat _ _ h₁ h₂ => exact .tError _ msg _
    | tAddString _ _ h₁ h₂ => exact .tError _ msg _
    | tEq _ _ _ h₁ h₂ => exact .tError _ msg _
    | tAnd _ _ h₁ h₂ => exact .tError _ msg _
    | tOr _ _ h₁ h₂ => exact .tError _ msg _
    | tSubInt _ _ h₁ h₂ => exact .tError _ msg _
    | tMulInt _ _ h₁ h₂ => exact .tError _ msg _
    | tLt _ _ h₁ h₂ => exact .tError _ msg _
    | tGt _ _ h₁ h₂ => exact .tError _ msg _
    | tLe _ _ h₁ h₂ => exact .tError _ msg _
    | tGe _ _ h₁ h₂ => exact .tError _ msg _
    | tDivInt _ _ h₁ h₂ => exact .tError _ msg _
    | tModInt _ _ h₁ h₂ => exact .tError _ msg _
  | sUnOpErr op msg _ =>
    cases ht with
    | tNegInt _ h₁ => exact .tError _ msg _
    | tNegFloat _ h₁ => exact .tError _ msg _
    | tNot _ h₁ => exact .tError _ msg _
  | sOkayErr msg _ =>
    cases ht with
    | tOkay _ _ h₁ => exact .tError _ msg _
  | sOopsErr msg _ =>
    cases ht with
    | tOops _ _ h₁ => exact .tError _ msg _
  | sUnwrapErr msg _ =>
    cases ht with
    | tUnwrap _ tOk tErr h₁ => exact .tError _ msg _
  | sArrayStep vs e e' rest ρ ρ' hs ih =>
    cases ht with
    | tArray _ t' hall =>
      refine .tArray _ _ t' (fun x hx => ?_)
      rcases List.mem_append.1 hx with hpre | hcons
      · exact hall x (List.mem_append.2 (Or.inl hpre))
      · rcases List.mem_cons.1 hcons with rfl | htail
        · exact ih hst (hall e (List.mem_append.2 (Or.inr List.mem_cons_self)))
        · exact hall x (List.mem_append.2 (Or.inr (List.mem_cons_of_mem _ htail)))
  | sArrayVal vs ρ =>
    cases ht with
    | tArray _ t' hall =>
      exact .tArrayVal _ vs t' (fun v hv => hall (Expr.lit v) (List.mem_map.2 ⟨v, hv, rfl⟩))
  | sArrayErr vs msg rest ρ =>
    exact .tError _ msg _

/-- Faithfulness check: `store_step_preservation` subsumes the empty-context
`preservation`. The empty type context is *vacuously* store-typed against any
store (`emptyTypeEnv x = none` is never `some t`), so the closed theorem is the
`Γ := emptyTypeEnv` instance. -/
theorem preservation_via_store {e e' : Expr} {ρ ρ' : Env} {t : WokeType}
    (ht : HasType emptyTypeEnv e t) (hs : Step e ρ e' ρ') :
    HasType emptyTypeEnv e' t :=
  store_step_preservation (fun x t h => by simp [emptyTypeEnv] at h) ht hs

-- =========================================================================
-- 7e. Statement execution — simple-statement fragment (Phase 1b)
-- =========================================================================

/- A big-step statement-execution relation `StmtExec s ρ ρ'` ("statement `s`
run in store `ρ` produces store `ρ'`"), with `StmtsExec` threading a block
left-to-right. This increment covers the **simple** statements — those with no
embedded sub-blocks: `complain`, `expr`, `varDecl`, `assign`, `return_`. Each
evaluates its expression (if any) to a value via the closed-store `MultiStep`
(the store is invariant under expression evaluation, `step_store_invariant`),
then applies its store effect. `return_`'s value-propagation / block
short-circuit and the control-flow forms (`if`/`loop`/`attempt`/`consent`,
which introduce block scoping) are deliberately deferred to a later increment.

The metatheorem is **store-typing preservation**: a well-typed statement run in
a well-typed store yields a store well-typed against the statement's output
context (`StmtWellTyped Γ s Γ'`). -/

/-- Multi-step store-typed preservation: evaluating a well-typed expression to
completion in a well-typed store yields a value of the same type. The store is
unchanged throughout (`step_store_invariant`), so the one store typing carries. -/
theorem store_multiStep_preservation {Γ : TypeEnv} {e e' : Expr} {ρ ρ' : Env} {t : WokeType}
    (hst : StoreWellTyped Γ ρ) (ht : HasType Γ e t) (hm : MultiStep e ρ e' ρ') :
    HasType Γ e' t := by
  induction hm generalizing t with
  | refl => exact ht
  | step e₁ e₂ e₃ ρ₁ ρ₂ ρ₃ hs hm' ih =>
      have hρ : ρ₂ = ρ₁ := step_store_invariant hs
      subst hρ
      exact ih hst (store_step_preservation hst ht hs)

/-- **Store-update lemma.** Overwriting an *already-declared* variable with a
value of its declared type preserves store typing against the *same* context.
This is what an `assign` statement does to the runtime (cf. `store_wellTyped_extend`,
which a `varDecl` uses to *grow* the context). -/
theorem store_wellTyped_update {Γ : TypeEnv} {ρ : Env} {x : String} {t : WokeType}
    {v : Value} (hst : StoreWellTyped Γ ρ) (hx : Γ x = some t)
    (hv : HasType emptyTypeEnv (.lit v) t) :
    StoreWellTyped Γ (extendEnv x v ρ) := by
  intro y ty hy
  by_cases hxy : (x == y) = true
  · have hxy' : x = y := eq_of_beq hxy
    subst hxy'
    rw [hx] at hy; injection hy with hty; subst hty
    exact ⟨v, by simp only [extendEnv]; rw [if_pos hxy], hv⟩
  · obtain ⟨v', hv', hvt⟩ := hst y ty hy
    exact ⟨v', by simp only [extendEnv]; rw [if_neg hxy]; exact hv', hvt⟩

-- ── Block-scope restore machinery (faithful lexical scoping) ──────────────
-- A block introduces a new scope: variables it DECLARES (via `varDecl`) are
-- local and vanish on block exit, while ASSIGNMENTS to enclosing variables
-- persist. In the flat `Env` model we realize this with `restoreVars`: on
-- block exit, the names the block declared are rolled back to their entry
-- values, and every other binding (including outer-variable mutations) is kept
-- — exactly the Rust interpreter's `Environment{bindings, parent}` discipline.

/-- The names a single statement declares at its own level. Only `varDecl`
declares; compound statements declare nothing at this level (their inner
declarations are block-local to them and already restored by their own exit). -/
def declaredVarsOf : Stmt → List String
  | .varDecl x _ => [x]
  | _ => []

/-- The names a block declares at top level, left-to-right. -/
def declaredVars : List Stmt → List String
  | [] => []
  | s :: ss => declaredVarsOf s ++ declaredVars ss

/-- Roll back the declared names to their entry values; keep everything else
(including assignments to enclosing variables) from the post-block store. -/
def restoreVars (names : List String) (ρpre ρpost : Env) : Env :=
  fun y => if y ∈ names then ρpre y else ρpost y

/-- A statement leaves the type context unchanged on every variable it does not
declare. -/
theorem stmt_ctx_off_declared {Γ Γ' : TypeEnv} {s : Stmt}
    (hw : StmtWellTyped Γ s Γ') : ∀ x, x ∉ declaredVarsOf s → Γ' x = Γ x := by
  cases hw with
  | varDecl Γ0 x0 e t hte =>
      intro x hx
      simp only [declaredVarsOf, List.mem_singleton] at hx
      simp only [extendTypeEnv]
      rw [if_neg (by simpa [beq_iff_eq] using fun h => hx h.symm)]
  | assign _ _ _ _ _ _ => intro x _; rfl
  | return_ _ _ _ _ => intro x _; rfl
  | if_ _ _ _ _ _ _ _ _ _ => intro x _; rfl
  | loop _ _ _ _ _ _ => intro x _; rfl
  | attempt _ _ _ _ _ => intro x _; rfl
  | consent _ _ _ _ _ => intro x _; rfl
  | expr _ _ _ _ => intro x _; rfl
  | complain _ _ => intro x _; rfl

/-- A whole block leaves the type context unchanged on every variable it does
not declare at top level — by induction on the block typing. (Compound
statements inside the block do not extend the context, so only top-level
`varDecl`s matter.) -/
theorem ctx_agrees_off_declared {Γ Γ₁ : TypeEnv} {body : List Stmt}
    (hw : StmtsWellTyped Γ body Γ₁) : ∀ x, x ∉ declaredVars body → Γ₁ x = Γ x := by
  induction body generalizing Γ Γ₁ with
  | nil => cases hw; intro x _; rfl
  | cons s ss ih =>
      cases hw with
      | cons _ _ _ Γmid _ hws hwss =>
          intro x hx
          simp only [declaredVars, List.mem_append, not_or] at hx
          rw [ih hwss x hx.2, stmt_ctx_off_declared hws x hx.1]

/-- **Restore lemma.** If the entry store is well typed against the outer
context `Γ`, and the post-block store is well typed against the block's output
context `Γ₁`, and `Γ₁` agrees with `Γ` off the declared names, then the restored
store is well typed against `Γ`. The declared names fall back to their (well
typed) entry values; every other `Γ`-variable keeps its post-block value, whose
type `Γ₁` (= `Γ` there) certifies. -/
theorem store_wellTyped_restore {Γ Γ₁ : TypeEnv} {ρ ρb : Env} {body : List Stmt}
    (hpre : StoreWellTyped Γ ρ) (hpost : StoreWellTyped Γ₁ ρb)
    (hagree : ∀ x, x ∉ declaredVars body → Γ₁ x = Γ x) :
    StoreWellTyped Γ (restoreVars (declaredVars body) ρ ρb) := by
  intro x t hx
  by_cases hmem : x ∈ declaredVars body
  · obtain ⟨v, hv, hvt⟩ := hpre x t hx
    exact ⟨v, by simp only [restoreVars, if_pos hmem]; exact hv, hvt⟩
  · have hΓ₁ : Γ₁ x = some t := by rw [hagree x hmem]; exact hx
    obtain ⟨v, hv, hvt⟩ := hpost x t hΓ₁
    exact ⟨v, by simp only [restoreVars, if_neg hmem]; exact hv, hvt⟩

mutual
/-- Big-step execution of a single (simple) statement. -/
inductive StmtExec : Stmt → Env → Env → Prop where
  | complain : ∀ m ρ, StmtExec (.complain m) ρ ρ
  | expr : ∀ e v ρ, MultiStep e ρ (.lit v) ρ → StmtExec (.expr e) ρ ρ
  | varDecl : ∀ x e v ρ, MultiStep e ρ (.lit v) ρ →
      StmtExec (.varDecl x e) ρ (extendEnv x v ρ)
  | assign : ∀ x e v ρ, MultiStep e ρ (.lit v) ρ →
      StmtExec (.assign x e) ρ (extendEnv x v ρ)
  | return_ : ∀ e v ρ, MultiStep e ρ (.lit v) ρ → StmtExec (.return_ e) ρ ρ
  -- Control-flow forms. Each runs its body block, then RESTORES the names the
  -- block declared to their entry values (faithful lexical scoping); outer-var
  -- mutations survive. The bool guard inherits `StmtWellTyped.{if_,loop}`'s
  -- `HasType Γ c .bool` premise (see the divergence note: the interpreters use a
  -- counted-int `loop`; the merged statics fix `.bool`, deferred to a follow-up).
  | ifTrue : ∀ c thn els ρ ρb, MultiStep c ρ (.lit (.vBool true)) ρ → StmtsExec thn ρ ρb →
      StmtExec (.if_ c thn els) ρ (restoreVars (declaredVars thn) ρ ρb)
  | ifFalse : ∀ c thn els ρ ρb, MultiStep c ρ (.lit (.vBool false)) ρ → StmtsExec els ρ ρb →
      StmtExec (.if_ c thn els) ρ (restoreVars (declaredVars els) ρ ρb)
  | loopDone : ∀ c body ρ, MultiStep c ρ (.lit (.vBool false)) ρ → StmtExec (.loop c body) ρ ρ
  | loopStep : ∀ c body ρ ρb ρ', MultiStep c ρ (.lit (.vBool true)) ρ → StmtsExec body ρ ρb →
      StmtExec (.loop c body) (restoreVars (declaredVars body) ρ ρb) ρ' →
      StmtExec (.loop c body) ρ ρ'
  | attemptOk : ∀ body hname ρ ρb, StmtsExec body ρ ρb →
      StmtExec (.attempt body hname) ρ (restoreVars (declaredVars body) ρ ρb)
  -- error mid-body: catch, restore the entry store (op-sem [B-Attempt-Err]).
  | attemptErr : ∀ body hname ρ, StmtExec (.attempt body hname) ρ ρ
  | consentGrant : ∀ p body ρ ρb, StmtsExec body ρ ρb →
      StmtExec (.consent p body) ρ (restoreVars (declaredVars body) ρ ρb)
  -- permission denied: skip the body (op-sem [B-Consent-Deny]).
  | consentDeny : ∀ p body ρ, StmtExec (.consent p body) ρ ρ
/-- Big-step execution of a block, threading the store left-to-right. -/
inductive StmtsExec : List Stmt → Env → Env → Prop where
  | nil : ∀ ρ, StmtsExec [] ρ ρ
  | cons : ∀ s ss ρ ρ' ρ'',
      StmtExec s ρ ρ' → StmtsExec ss ρ' ρ'' → StmtsExec (s :: ss) ρ ρ''
end

/-- **Statement-execution preservation** (single statement). A well-typed
statement run in a well-typed store yields a store well-typed against its output
context. Proved by induction on the execution derivation; the mutual induction
principle supplies, in each control-flow case, an IH for the body block (and, for
`loopStep`, an IH for the recursive loop execution on the restored store).

Simple statements: `varDecl` uses `store_wellTyped_extend`, `assign` uses
`store_wellTyped_update`, the rest leave the store and context fixed. Control
flow: each branch/body's IH gives `StoreWellTyped Γ₁ ρb`, then
`store_wellTyped_restore` rolls the declared names back to `Γ` via
`ctx_agrees_off_declared`. `loop` runs the recursive IH on the restored store (so
outer-variable mutations carry across iterations while declarations are re-scoped
each pass). `attemptErr`/`consentDeny` restore/skip to the entry store. -/
theorem stmt_exec_preservation {Γ Γ' : TypeEnv} {s : Stmt} {ρ ρ' : Env}
    (hst : StoreWellTyped Γ ρ) (hw : StmtWellTyped Γ s Γ') (he : StmtExec s ρ ρ') :
    StoreWellTyped Γ' ρ' := by
  refine StmtExec.rec
    (motive_1 := fun s r r' _ =>
      ∀ Γ Γ', StoreWellTyped Γ r → StmtWellTyped Γ s Γ' → StoreWellTyped Γ' r')
    (motive_2 := fun ss r r' _ =>
      ∀ Γ Γ', StoreWellTyped Γ r → StmtsWellTyped Γ ss Γ' → StoreWellTyped Γ' r')
    ?complain ?expr ?varDecl ?assign ?return_ ?ifTrue ?ifFalse ?loopDone ?loopStep
    ?attemptOk ?attemptErr ?consentGrant ?consentDeny ?nil ?cons he Γ Γ' hst hw
  case complain => intro m ρ Γ Γ' hst hw; cases hw with | complain _ _ => exact hst
  case expr => intro e v ρ hm Γ Γ' hst hw; cases hw with | expr _ _ t _ => exact hst
  case return_ => intro e v ρ hm Γ Γ' hst hw; cases hw with | return_ _ _ t _ => exact hst
  case varDecl =>
      intro x e v ρ hm Γ Γ' hst hw
      cases hw with
      | varDecl _ _ _ t hte =>
          exact store_wellTyped_extend hst
            (hasType_lit_any (store_multiStep_preservation hst hte hm))
  case assign =>
      intro x e v ρ hm Γ Γ' hst hw
      cases hw with
      | assign _ _ _ t hx hte =>
          exact store_wellTyped_update hst hx
            (hasType_lit_any (store_multiStep_preservation hst hte hm))
  case ifTrue =>
      intro c thn els ρ ρb hc hb ihb Γ Γ' hst hw
      cases hw with
      | if_ _ _ _ _ _ _ _ hwthn _ =>
          exact store_wellTyped_restore hst (ihb _ _ hst hwthn) (ctx_agrees_off_declared hwthn)
  case ifFalse =>
      intro c thn els ρ ρb hc hb ihb Γ Γ' hst hw
      cases hw with
      | if_ _ _ _ _ _ _ _ _ hwels =>
          exact store_wellTyped_restore hst (ihb _ _ hst hwels) (ctx_agrees_off_declared hwels)
  case loopDone => intro c body ρ hc Γ Γ' hst hw; cases hw with | loop _ _ _ _ _ _ => exact hst
  case loopStep =>
      intro c body ρ ρb ρ' hc hb hrec ihb ihrec Γ Γ' hst hw
      cases hw with
      | loop _ _ _ _ hcc hwbody =>
          exact ihrec _ _
            (store_wellTyped_restore hst (ihb _ _ hst hwbody) (ctx_agrees_off_declared hwbody))
            (StmtWellTyped.loop _ _ _ _ hcc hwbody)
  case attemptOk =>
      intro body hname ρ ρb hb ihb Γ Γ' hst hw
      cases hw with
      | attempt _ _ _ _ hwbody =>
          exact store_wellTyped_restore hst (ihb _ _ hst hwbody) (ctx_agrees_off_declared hwbody)
  case attemptErr =>
      intro body hname ρ Γ Γ' hst hw; cases hw with | attempt _ _ _ _ _ => exact hst
  case consentGrant =>
      intro p body ρ ρb hb ihb Γ Γ' hst hw
      cases hw with
      | consent _ _ _ _ hwbody =>
          exact store_wellTyped_restore hst (ihb _ _ hst hwbody) (ctx_agrees_off_declared hwbody)
  case consentDeny =>
      intro p body ρ Γ Γ' hst hw; cases hw with | consent _ _ _ _ _ => exact hst
  case nil => intro ρ Γ Γ' hst hw; cases hw with | nil _ => exact hst
  case cons =>
      intro s ss ρ ρ' ρ'' hse hsse ihse ihsse Γ Γ' hst hw
      cases hw with
      | cons _ _ _ Γ₁ _ hws hwss => exact ihsse _ _ (ihse _ _ hst hws) hwss

/-- **Statement-execution preservation** (block). Threads the single-statement
preservation through the block. -/
theorem stmts_exec_preservation {Γ Γ' : TypeEnv} {ss : List Stmt} {ρ ρ' : Env}
    (hst : StoreWellTyped Γ ρ) (hw : StmtsWellTyped Γ ss Γ') (he : StmtsExec ss ρ ρ') :
    StoreWellTyped Γ' ρ' := by
  induction ss generalizing Γ Γ' ρ ρ' with
  | nil => cases hw; cases he; exact hst
  | cons s rest ih =>
      cases hw with
      | cons _ _ _ Γ₁ _ hws hwss =>
          cases he with
          | cons _ _ _ ρ₁ _ hse hsse =>
              exact ih (stmt_exec_preservation hst hws hse) hwss hsse

/-- Smoke test: `let x = 0` executes from the empty store, binding `x ↦ 0`. -/
example :
    StmtExec (.varDecl "x" (.lit (.vInt 0))) emptyEnv (extendEnv "x" (.vInt 0) emptyEnv) :=
  .varDecl "x" _ (.vInt 0) emptyEnv (.refl _ _)

/-- Smoke test: the block `let x = 0; x` runs from the empty store and stays
well-typed against the context it produces (`x : int`), via `stmts_exec_preservation`. -/
example :
    StoreWellTyped (extendTypeEnv "x" .int emptyTypeEnv)
      (extendEnv "x" (.vInt 0) emptyEnv) :=
  stmts_exec_preservation store_wellTyped_empty
    (.cons _ _ _ _ _
      (.varDecl _ "x" (.lit (.vInt 0)) .int (.tInt _ _))
      (.cons _ _ _ _ _ (.expr _ (.var "x") .int (.tVar _ "x" .int (by simp [extendTypeEnv])))
        (.nil _)))
    (.cons _ _ _ _ _
      (.varDecl "x" (.lit (.vInt 0)) (.vInt 0) emptyEnv (.refl _ _))
      (.cons _ _ _ _ _
        (.expr (.var "x") (.vInt 0) (extendEnv "x" (.vInt 0) emptyEnv)
          (.step _ _ _ _ _ _ (.sVar "x" _ (.vInt 0) (by simp [extendEnv])) (.refl _ _)))
        (.nil _)))

/-- Smoke test: `if true {} else {}` runs from the empty store back to the
empty store (the taken branch is empty, so the restore is the identity). -/
example : StmtExec (.if_ (.lit (.vBool true)) [] [])
    emptyEnv (restoreVars (declaredVars ([] : List Stmt)) emptyEnv emptyEnv) :=
  .ifTrue _ _ _ _ _ (.refl _ _) (.nil _)

/-- **Faithfulness smoke test — block-local declarations do not escape.** The
block-local `remember y = 0` inside `if true { … }` is rolled back on block exit,
so running it from the empty store yields the empty store again. This is exactly
what distinguishes faithful lexical scoping from a no-restore model (where `y`
would leak into the enclosing scope). -/
example :
    restoreVars (declaredVars [Stmt.varDecl "y" (.lit (.vInt 0))])
      emptyEnv (extendEnv "y" (.vInt 0) emptyEnv) = emptyEnv := by
  funext z
  simp only [restoreVars, declaredVars, declaredVarsOf, List.append_nil, List.mem_singleton,
    extendEnv, emptyEnv]
  by_cases hz : z = "y"
  · simp [hz]
  · rw [if_neg hz, if_neg (by simpa [beq_iff_eq] using fun h => hz h.symm)]

/-- **Faithfulness smoke test — outer mutations persist through a block.** With
`x : int` already in scope, `if true { x = 1 }` updates `x` and the new value
survives block exit (`assign` declares nothing, so nothing is rolled back). -/
example :
    restoreVars (declaredVars [Stmt.assign "x" (.lit (.vInt 1))])
      (extendEnv "x" (.vInt 0) emptyEnv) (extendEnv "x" (.vInt 1) emptyEnv)
      = extendEnv "x" (.vInt 1) emptyEnv := by
  funext z
  simp only [restoreVars, declaredVars, declaredVarsOf, List.append_nil, List.not_mem_nil,
    if_false]

-- =========================================================================
-- 8. TODO Stubs
-- =========================================================================

-- TODO: Bytecode definition
-- TODO: Compiler function
-- TODO: VM semantics
-- TODO: Compiler correctness theorem
-- TODO: Worker semantics
-- TODO: Concurrency safety proofs

end WokeLang
