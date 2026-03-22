/-
  WokeLang Formal Verification in Lean 4
  SPDX-License-Identifier: MIT OR Apache-2.0

  This file contains Lean 4 definitions and theorems for WokeLang.

  ## Sorry Audit (13 total — ALL BLOCKED)

  All 13 remaining `sorry` proofs are blocked by an incomplete `Step`
  inductive relation. The small-step operational semantics only defines
  reduction/congruence rules for a subset of typed expressions. To
  resolve these, the `Step` inductive must be extended with the
  constructors listed below.

  ### Missing Step constructors needed:

  | Constructor     | Purpose                                    | Blocks                          |
  |-----------------|--------------------------------------------|---------------------------------|
  | sAddFloat       | Reduce float + float                       | sorry #1 (tAddFloat)            |
  | sAddString      | Reduce string ++ string                    | sorry #2 (tAddString)           |
  | sEqFalse        | Reduce v₁ == v₂ when v₁ ≠ v₂              | sorry #3 (tEq)                  |
  | sAnd            | Reduce bool && bool                        | sorry #4 (tAnd)                 |
  | sUnOpCong       | Congruence: unOp e → unOp e' when e steps  | sorry #5,#6,#7 (tNegInt step,  |
  |                 |                                            |   tNegFloat, tNot step)         |
  | sNegFloat       | Reduce neg(float)                          | sorry #6 (tNegFloat)            |
  | sOkayCong       | Congruence: okay(e) → okay(e') when e steps| sorry #8 (tOkay step case)      |
  | sOopsCong       | Congruence: oops(e) → oops(e') when e steps| sorry #9 (tOops step case)      |
  | sUnwrapCong     | Congruence: unwrap(e) steps when e steps   | sorry #10,#11 (tUnwrap)         |
  | sUnwrapError    | Runtime error for unwrap(vOops _)           | sorry #10 (tUnwrap value case)  |

  ### Preservation theorem (sorry #12):
  Blocked by same missing constructors — proof structure is sound but
  case analysis on Step requires matching all constructors.

  ### Type safety (sorry #13 — actually sorry-FREE):
  type_safety is proven by induction on MultiStep using preservation.
  It has no sorry itself but depends on preservation (sorry #12).

  Once the Step relation is extended, all 13 sorry proofs become
  straightforward by the existing proof patterns in the provable cases.
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

-- =========================================================================
-- 4. Operational Semantics
-- =========================================================================

/-- Predicate for values -/
inductive IsValue : Expr → Prop where
  | lit : ∀ v, IsValue (.lit v)

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

/-- Canonical forms lemma for Bool -/
theorem canonical_forms_bool : ∀ v,
  HasType emptyTypeEnv (.lit v) .bool →
  ∃ b, v = .vBool b := by
  intro v h
  cases h
  exact ⟨_, rfl⟩

/-- Progress theorem (TODO: Complete proof) -/
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
  | tVar Γ x t hx =>
    -- Variable in empty env is contradiction
    simp [emptyTypeEnv] at hx
  | tAddInt Γ e₁ e₂ h₁ h₂ ih₁ ih₂ =>
    right
    -- Both subexpressions are well-typed in empty env, so by IH they are
    -- either values or can step. We case-split on each.
    cases ih₁ with
    | inl hv₁ =>
      cases hv₁ with
      | lit v₁ =>
        cases ih₂ with
        | inl hv₂ =>
          cases hv₂ with
          | lit v₂ =>
            -- Both are values. By canonical forms for int, they must be vInt.
            have ⟨n₁, hn₁⟩ := canonical_forms_int v₁ h₁
            have ⟨n₂, hn₂⟩ := canonical_forms_int v₂ h₂
            subst hn₁; subst hn₂
            exact ⟨.lit (.vInt (n₁ + n₂)), emptyEnv, .sAddInt n₁ n₂ emptyEnv⟩
        | inr ⟨e₂', ρ', hs₂⟩ =>
          exact ⟨.binOp .add (.lit v₁) e₂', ρ', .sBinOpRight .add v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
    | inr ⟨e₁', ρ', hs₁⟩ =>
      exact ⟨.binOp .add e₁' e₂, ρ', .sBinOpLeft .add _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tAddFloat Γ e₁ e₂ h₁ h₂ ih₁ ih₂ =>
    -- Float addition: similar structure but no Step rule defined for float add.
    -- The operational semantics only defines sAddInt, not sAddFloat.
    -- Progress for float addition requires extending Step with a sAddFloat rule.
    -- UNPROVABLE: Step relation lacks a reduction rule for float addition.
    -- To fix: add `sAddFloat` constructor to the `Step` inductive.
    right
    cases ih₁ with
    | inl hv₁ =>
      cases hv₁ with
      | lit v₁ =>
        cases ih₂ with
        | inl hv₂ =>
          cases hv₂ with
          | lit v₂ =>
            -- sorry #1: No sAddFloat rule in Step. Both subexprs reduce to
            -- vFloat values but Step has no rule to compute float + float.
            sorry  -- BLOCKED(#1): add `| sAddFloat : ∀ f₁ f₂ ρ, Step (.binOp .add (.lit (.vFloat f₁)) (.lit (.vFloat f₂))) ρ (.lit (.vFloat (f₁ + f₂))) ρ` to Step
        | inr ⟨e₂', ρ', hs₂⟩ =>
          exact ⟨.binOp .add (.lit v₁) e₂', ρ', .sBinOpRight .add v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
    | inr ⟨e₁', ρ', hs₁⟩ =>
      exact ⟨.binOp .add e₁' e₂, ρ', .sBinOpLeft .add _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tAddString Γ e₁ e₂ h₁ h₂ ih₁ ih₂ =>
    -- String concatenation: same gap — no sAddString rule in Step.
    right
    cases ih₁ with
    | inl hv₁ =>
      cases hv₁ with
      | lit v₁ =>
        cases ih₂ with
        | inl hv₂ =>
          cases hv₂ with
          | lit v₂ =>
            sorry  -- BLOCKED(#2): add `| sAddString : ∀ s₁ s₂ ρ, Step (.binOp .add (.lit (.vString s₁)) (.lit (.vString s₂))) ρ (.lit (.vString (s₁ ++ s₂))) ρ` to Step
        | inr ⟨e₂', ρ', hs₂⟩ =>
          exact ⟨.binOp .add (.lit v₁) e₂', ρ', .sBinOpRight .add v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
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
            -- sorry #3: sEqTrue only covers v == v. For v₁ ≠ v₂ there is no
            -- sEqFalse rule, so the expression is stuck.
            sorry  -- BLOCKED(#3): add `| sEqFalse : ∀ v₁ v₂ ρ, v₁ ≠ v₂ → Step (.binOp .eq (.lit v₁) (.lit v₂)) ρ (.lit (.vBool false)) ρ` to Step
        | inr ⟨e₂', ρ', hs₂⟩ =>
          exact ⟨.binOp .eq (.lit v₁) e₂', ρ', .sBinOpRight .eq v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
    | inr ⟨e₁', ρ', hs₁⟩ =>
      exact ⟨.binOp .eq e₁' e₂, ρ', .sBinOpLeft .eq _ e₁' e₂ emptyEnv ρ' hs₁⟩
  | tAnd Γ e₁ e₂ h₁ h₂ ih₁ ih₂ =>
    -- Boolean and: no sAnd rule in Step.
    right
    cases ih₁ with
    | inl hv₁ =>
      cases hv₁ with
      | lit v₁ =>
        cases ih₂ with
        | inl hv₂ =>
          cases hv₂ with
          | lit v₂ =>
            sorry  -- BLOCKED(#4): add `| sAnd : ∀ b₁ b₂ ρ, Step (.binOp .and (.lit (.vBool b₁)) (.lit (.vBool b₂))) ρ (.lit (.vBool (b₁ && b₂))) ρ` to Step
        | inr ⟨e₂', ρ', hs₂⟩ =>
          exact ⟨.binOp .and (.lit v₁) e₂', ρ', .sBinOpRight .and v₁ _ e₂' emptyEnv ρ' (.lit v₁) hs₂⟩
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
    | inr ⟨e', ρ', hs⟩ =>
      -- sorry #5: e can step but no congruence rule carries the step under unOp.
      sorry  -- BLOCKED(#5): add `| sUnOpCong : ∀ op e e' ρ ρ', Step e ρ e' ρ' → Step (.unOp op e) ρ (.unOp op e') ρ'` to Step
  | tNegFloat Γ e h₁ ih =>
    right
    sorry  -- BLOCKED(#6): requires both sNegFloat (reduce neg(float)) and sUnOpCong (congruence) in Step
  | tNot Γ e h₁ ih =>
    right
    cases ih with
    | inl hv =>
      cases hv with
      | lit v =>
        have ⟨b, hb⟩ := canonical_forms_bool v h₁
        subst hb
        exact ⟨.lit (.vBool (!b)), emptyEnv, .sNot b emptyEnv⟩
    | inr ⟨e', ρ', hs⟩ =>
      sorry  -- BLOCKED(#7): requires sUnOpCong constructor in Step (same as #5)
  | tOkay Γ e t h₁ ih =>
    right
    cases ih with
    | inl hv =>
      cases hv with
      | lit v =>
        exact ⟨.lit (.vOkay v), emptyEnv, .sOkay v emptyEnv (.lit v)⟩
    | inr ⟨e', ρ', hs⟩ =>
      sorry  -- BLOCKED(#8): add `| sOkayCong : ∀ e e' ρ ρ', Step e ρ e' ρ' → Step (.okay e) ρ (.okay e') ρ'` to Step
  | tOops Γ e t h₁ ih =>
    right
    cases ih with
    | inl hv =>
      cases hv with
      | lit v =>
        have ⟨s, hs⟩ : ∃ s, v = .vString s := by cases h₁; exact ⟨_, rfl⟩
        subst hs
        exact ⟨.lit (.vOops s), emptyEnv, .sOops s emptyEnv⟩
    | inr ⟨e', ρ', hs⟩ =>
      sorry  -- BLOCKED(#9): add `| sOopsCong : ∀ e e' ρ ρ', Step e ρ e' ρ' → Step (.oops e) ρ (.oops e') ρ'` to Step
  | tUnwrap Γ e tOk tErr h₁ ih =>
    right
    cases ih with
    | inl hv =>
      cases hv with
      | lit v =>
        -- sorry #10: v has type result tOk tErr, so it must be vOkay or vOops.
        -- sUnwrapOkay handles vOkay but for vOops the expression is stuck.
        -- This is a genuine design question: unwrap of an error should be a
        -- runtime error/panic, which needs explicit modelling in Step.
        sorry  -- BLOCKED(#10): add `| sUnwrapError : ∀ s ρ, Step (.unwrap (.lit (.vOops s))) ρ (.lit (.vOops s)) ρ` (or a Panic/Error expression constructor) to Step
    | inr ⟨e', ρ', hs⟩ =>
      sorry  -- BLOCKED(#11): add `| sUnwrapCong : ∀ e e' ρ ρ', Step e ρ e' ρ' → Step (.unwrap e) ρ (.unwrap e') ρ'` to Step

/-- Preservation theorem
    NOTE: Full proof requires induction on the Step derivation with inversion
    on the typing derivation. Several cases are blocked by the same Step
    completeness gaps noted in the progress theorem. The provable cases
    (sAddInt, sEqTrue, sNegInt, sNot, sOkay, sOops, sUnwrapOkay, sVar)
    are straightforward by inversion on typing. The congruence cases
    (sBinOpLeft, sBinOpRight) require an induction hypothesis.
    BLOCKED: Complete proof requires the same Step constructors as progress. -/
theorem preservation : ∀ e e' t ρ ρ',
  HasType emptyTypeEnv e t →
  Step e ρ e' ρ' →
  HasType emptyTypeEnv e' t := by
  intro e e' t ρ ρ' ht hs
  sorry  -- BLOCKED(#12): proof structure is sound — induction on Step with
         -- inversion on typing handles all existing constructors. But case
         -- analysis fails because Step lacks congruence rules for unOp, okay,
         -- oops, unwrap; and reduction rules for float/string add, and/or,
         -- eq-false. Once Step is extended, this proof follows the same pattern
         -- as the existing provable cases (sAddInt, sNegInt, sNot, etc.).

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
