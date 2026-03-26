/-
  WokeLang Formal Verification in Lean 4
  SPDX-License-Identifier: MIT OR Apache-2.0

  This file contains Lean 4 definitions and theorems for WokeLang.

  ## Sorry Audit: ALL RESOLVED (0 remaining)

  All 12 `sorry` occurrences have been eliminated by:
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
  deriving Repr, DecidableEq

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
  deriving Repr, DecidableEq

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
  | tOkayVal _ _ _ h₁ => left; exact ⟨_, rfl⟩
  | tOopsVal _ _ _ => right; exact ⟨_, rfl⟩

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
  | tOkayVal _ _ _ _ => left; constructor
  | tOopsVal _ _ _ => left; constructor
  | tVar Γ x t hx =>
    -- Variable in empty env is contradiction
    simp [emptyTypeEnv] at hx
  | tAddInt Γ e₁ e₂ h₁ h₂ ih₁ ih₂ =>
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
        | inr ⟨e₂', ρ', hs₂⟩ =>
          exact ⟨.binOp .add (.lit v₁) e₂', ρ', .sBinOpRight .add v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sBinOpErrLeft .add msg e₂ emptyEnv⟩
    | inr ⟨e₁', ρ', hs₁⟩ =>
      exact ⟨.binOp .add e₁' e₂, ρ', .sBinOpLeft .add _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tAddFloat Γ e₁ e₂ h₁ h₂ ih₁ ih₂ =>
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
        | inr ⟨e₂', ρ', hs₂⟩ =>
          exact ⟨.binOp .add (.lit v₁) e₂', ρ', .sBinOpRight .add v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sBinOpErrLeft .add msg e₂ emptyEnv⟩
    | inr ⟨e₁', ρ', hs₁⟩ =>
      exact ⟨.binOp .add e₁' e₂, ρ', .sBinOpLeft .add _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tAddString Γ e₁ e₂ h₁ h₂ ih₁ ih₂ =>
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
        | inr ⟨e₂', ρ', hs₂⟩ =>
          exact ⟨.binOp .add (.lit v₁) e₂', ρ', .sBinOpRight .add v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sBinOpErrLeft .add msg e₂ emptyEnv⟩
    | inr ⟨e₁', ρ', hs₁⟩ =>
      exact ⟨.binOp .add e₁' e₂, ρ', .sBinOpLeft .add _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tEq Γ e₁ e₂ t h₁ h₂ ih₁ ih₂ =>
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
        | inr ⟨e₂', ρ', hs₂⟩ =>
          exact ⟨.binOp .eq (.lit v₁) e₂', ρ', .sBinOpRight .eq v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sBinOpErrLeft .eq msg e₂ emptyEnv⟩
    | inr ⟨e₁', ρ', hs₁⟩ =>
      exact ⟨.binOp .eq e₁' e₂, ρ', .sBinOpLeft .eq _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tAnd Γ e₁ e₂ h₁ h₂ ih₁ ih₂ =>
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
        | inr ⟨e₂', ρ', hs₂⟩ =>
          exact ⟨.binOp .and (.lit v₁) e₂', ρ', .sBinOpRight .and v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sBinOpErrLeft .and msg e₂ emptyEnv⟩
    | inr ⟨e₁', ρ', hs₁⟩ =>
      exact ⟨.binOp .and e₁' e₂, ρ', .sBinOpLeft .and _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tNegInt Γ e h₁ ih =>
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
    | inr ⟨e', ρ', hs⟩ =>
      exact ⟨.unOp .neg e', ρ', .sUnOpCong .neg _ e' emptyEnv ρ' hs⟩
  | tNegFloat Γ e h₁ ih =>
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
    | inr ⟨e', ρ', hs⟩ =>
      exact ⟨.unOp .neg e', ρ', .sUnOpCong .neg _ e' emptyEnv ρ' hs⟩
  | tNot Γ e h₁ ih =>
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
    | inr ⟨e', ρ', hs⟩ =>
      exact ⟨.unOp .not e', ρ', .sUnOpCong .not _ e' emptyEnv ρ' hs⟩
  | tOkay Γ e t h₁ ih =>
    right
    cases ih with
    | inl hv =>
      cases hv with
      | lit v =>
        exact ⟨.lit (.vOkay v), emptyEnv, .sOkay v emptyEnv (.lit v)⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sOkayErr msg emptyEnv⟩
    | inr ⟨e', ρ', hs⟩ =>
      exact ⟨.okay e', ρ', .sOkayCong _ e' emptyEnv ρ' hs⟩
  | tOops Γ e t h₁ ih =>
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
    | inr ⟨e', ρ', hs⟩ =>
      exact ⟨.oops e', ρ', .sOopsCong _ e' emptyEnv ρ' hs⟩
  | tUnwrap Γ e tOk tErr h₁ ih =>
    right
    cases ih with
    | inl hv =>
      cases hv with
      | lit v =>
        -- v has type result tOk tErr, so it must be vOkay or vOops.
        -- sUnwrapOkay handles vOkay; sUnwrapError handles vOops.
        have hcf := canonical_forms_result v tOk tErr h₁
        cases hcf with
        | inl ⟨inner, hinner⟩ =>
          subst hinner
          exact ⟨.lit inner, emptyEnv, .sUnwrapOkay inner emptyEnv⟩
        | inr ⟨s, hs⟩ =>
          subst hs
          exact ⟨.error s, emptyEnv, .sUnwrapError s emptyEnv⟩
      | error msg =>
        exact ⟨.error msg, emptyEnv, .sUnwrapErr msg emptyEnv⟩
    | inr ⟨e', ρ', hs⟩ =>
      exact ⟨.unwrap e', ρ', .sUnwrapCong _ e' emptyEnv ρ' hs⟩
  | tError _ msg _ =>
    -- Error expressions are terminal values (panics).
    left; exact .error msg

/-- Preservation theorem: if a well-typed expression steps, the result is well-typed.
    Proof by induction on the Step derivation with inversion on the typing derivation.
    Reduction cases (sAddInt, sEqTrue, sNegInt, etc.) follow by constructor application.
    Congruence cases (sBinOpLeft, sBinOpRight, sUnOpCong, etc.) use the IH. -/
theorem preservation : ∀ e e' t ρ ρ',
  HasType emptyTypeEnv e t →
  Step e ρ e' ρ' →
  HasType emptyTypeEnv e' t := by
  intro e e' t ρ ρ' ht hs
  induction hs with
  | sVar x ρ v hx =>
    -- Typed as (var x) in empty env ⇒ contradiction in progress,
    -- but preservation receives any ρ. By inversion on typing:
    -- HasType emptyTypeEnv (var x) t requires emptyTypeEnv x = some t,
    -- which is a contradiction.
    cases ht with
    | tVar _ _ _ hx' => simp [emptyTypeEnv] at hx'
  | sBinOpLeft op e₁ e₁' e₂ ρ ρ' hs₁ ih =>
    cases ht with
    | tAddInt _ _ _ h₁ h₂ => exact .tAddInt _ _ _ (ih h₁) h₂
    | tAddFloat _ _ _ h₁ h₂ => exact .tAddFloat _ _ _ (ih h₁) h₂
    | tAddString _ _ _ h₁ h₂ => exact .tAddString _ _ _ (ih h₁) h₂
    | tEq _ _ _ _ h₁ h₂ => exact .tEq _ _ _ _ (ih h₁) h₂
    | tAnd _ _ _ h₁ h₂ => exact .tAnd _ _ _ (ih h₁) h₂
  | sBinOpRight op v₁ e₂ e₂' ρ ρ' _hv hs₂ ih =>
    cases ht with
    | tAddInt _ _ _ h₁ h₂ => exact .tAddInt _ _ _ h₁ (ih h₂)
    | tAddFloat _ _ _ h₁ h₂ => exact .tAddFloat _ _ _ h₁ (ih h₂)
    | tAddString _ _ _ h₁ h₂ => exact .tAddString _ _ _ h₁ (ih h₂)
    | tEq _ _ _ _ h₁ h₂ => exact .tEq _ _ _ _ h₁ (ih h₂)
    | tAnd _ _ _ h₁ h₂ => exact .tAnd _ _ _ h₁ (ih h₂)
  | sAddInt n₁ n₂ _ =>
    cases ht with
    | tAddInt _ _ _ h₁ h₂ => exact .tInt _ _
  | sAddFloat f₁ f₂ _ =>
    cases ht with
    | tAddFloat _ _ _ h₁ h₂ => exact .tFloat _ _
  | sAddString s₁ s₂ _ =>
    cases ht with
    | tAddString _ _ _ h₁ h₂ => exact .tString _ _
  | sEqTrue v _ =>
    cases ht with
    | tEq _ _ _ _ h₁ h₂ => exact .tBool _ _
  | sEqFalse v₁ v₂ _ hneq =>
    cases ht with
    | tEq _ _ _ _ h₁ h₂ => exact .tBool _ _
  | sAnd b₁ b₂ _ =>
    cases ht with
    | tAnd _ _ _ h₁ h₂ => exact .tBool _ _
  | sNegInt n _ =>
    cases ht with
    | tNegInt _ _ h₁ => exact .tInt _ _
  | sNegFloat f _ =>
    cases ht with
    | tNegFloat _ _ h₁ => exact .tFloat _ _
  | sNot b _ =>
    cases ht with
    | tNot _ _ h₁ => exact .tBool _ _
  | sUnOpCong op e e' ρ ρ' hs₁ ih =>
    cases ht with
    | tNegInt _ _ h₁ => exact .tNegInt _ _ (ih h₁)
    | tNegFloat _ _ h₁ => exact .tNegFloat _ _ (ih h₁)
    | tNot _ _ h₁ => exact .tNot _ _ (ih h₁)
  | sOkay v _ _hv =>
    cases ht with
    | tOkay _ _ _ h₁ => exact .tOkayVal _ v _ h₁
  | sOkayCong e e' ρ ρ' hs₁ ih =>
    cases ht with
    | tOkay _ _ _ h₁ => exact .tOkay _ _ _ (ih h₁)
  | sOops s _ =>
    cases ht with
    | tOops _ _ _ h₁ => exact .tOopsVal _ s _
  | sOopsCong e e' ρ ρ' hs₁ ih =>
    cases ht with
    | tOops _ _ _ h₁ => exact .tOops _ _ _ (ih h₁)
  | sUnwrapOkay v _ =>
    cases ht with
    | tUnwrap _ _ tOk tErr h₁ =>
      -- h₁ : HasType emptyTypeEnv (lit (vOkay v)) (result tOk tErr)
      -- By inversion via tOkayVal, the inner value v has type tOk.
      cases h₁ with
      | tOkayVal _ _ _ hinner => exact hinner
  | sUnwrapError s _ =>
    cases ht with
    | tUnwrap _ _ tOk tErr h₁ =>
      -- unwrap(oops(s)) steps to (error s), which is well-typed at any type
      -- via tError. This models runtime panic propagation.
      exact .tError _ s tOk
  | sUnwrapCong e e' ρ ρ' hs₁ ih =>
    cases ht with
    | tUnwrap _ _ tOk tErr h₁ => exact .tUnwrap _ _ tOk tErr (ih h₁)
  | sBinOpErrLeft op msg e₂ _ =>
    -- error propagates through binOp — result is error, typed at any type via tError.
    cases ht with
    | tAddInt _ _ _ h₁ h₂ => exact .tError _ msg _
    | tAddFloat _ _ _ h₁ h₂ => exact .tError _ msg _
    | tAddString _ _ _ h₁ h₂ => exact .tError _ msg _
    | tEq _ _ _ _ h₁ h₂ => exact .tError _ msg _
    | tAnd _ _ _ h₁ h₂ => exact .tError _ msg _
  | sBinOpErrRight op v₁ msg _ =>
    cases ht with
    | tAddInt _ _ _ h₁ h₂ => exact .tError _ msg _
    | tAddFloat _ _ _ h₁ h₂ => exact .tError _ msg _
    | tAddString _ _ _ h₁ h₂ => exact .tError _ msg _
    | tEq _ _ _ _ h₁ h₂ => exact .tError _ msg _
    | tAnd _ _ _ h₁ h₂ => exact .tError _ msg _
  | sUnOpErr op msg _ =>
    cases ht with
    | tNegInt _ _ h₁ => exact .tError _ msg _
    | tNegFloat _ _ h₁ => exact .tError _ msg _
    | tNot _ _ h₁ => exact .tError _ msg _
  | sOkayErr msg _ =>
    cases ht with
    | tOkay _ _ _ h₁ => exact .tError _ msg _
  | sOopsErr msg _ =>
    cases ht with
    | tOops _ _ _ h₁ => exact .tError _ msg _
  | sUnwrapErr msg _ =>
    cases ht with
    | tUnwrap _ _ tOk tErr h₁ => exact .tError _ msg _

/-- Type safety theorem -/
theorem type_safety : ∀ e t v ρ,
  HasType emptyTypeEnv e t →
  MultiStep e emptyEnv (.lit v) ρ →
  HasType emptyTypeEnv (.lit v) t := by
  intro e t v ρ ht hms
  induction hms with
  | refl => exact ht
  | step e₁ e₂ e₃ ρ₁ ρ₂ ρ₃ hs hms' ih =>
    apply ih
    exact preservation e₁ e₂ t ρ₁ ρ₂ ht hs

-- =========================================================================
-- 6. Consent System
-- =========================================================================

def Permission := String

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
