-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-- SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
-- Calculus.idr - λ_consent calculus: syntax, types, values, handler algebra
--
-- Mechanises Definition 1 (Syntax) from §7 of arxiv-consent-aware-programming.tex.
-- The calculus extends the simply-typed lambda calculus with four consent-specific
-- forms: only_if_okay, consent_handler, attr, and feel.

module WokeLang.Calculus

%default total

-- ---------------------------------------------------------------------------
-- Consent decisions
-- ---------------------------------------------------------------------------

||| The binary decision a consent handler produces for any given prompt.
||| Handlers are required to be total — they always return one of these.
public export
data ConsentDecision : Type where
  Granted : ConsentDecision
  Denied  : ConsentDecision

-- ---------------------------------------------------------------------------
-- Consent handlers (Definition 1, handler forms)
-- ---------------------------------------------------------------------------

||| A consent handler maps a prompt string to a consent decision.
||| Four canonical forms:
|||   HInteractive      — defers to the user (modelled as Granted here)
|||   HPolicy p         — applies a policy predicate
|||   HAutoGranted      — always grants (auto(granted))
|||   HAutoDenied       — always denies  (auto(denied))
public export
data Handler : Type where
  HInteractive  : Handler
  HPolicy       : (String -> ConsentDecision) -> Handler
  HAutoGranted  : Handler
  HAutoDenied   : Handler

||| Apply a handler to a consent prompt string.
||| This function is total by construction: every case returns a decision.
public export
applyHandler : Handler -> String -> ConsentDecision
applyHandler HInteractive  _ = Granted
applyHandler (HPolicy p)   s = p s
applyHandler HAutoGranted  _ = Granted
applyHandler HAutoDenied   _ = Denied

-- ---------------------------------------------------------------------------
-- Types (Definition 1, type syntax)
-- ---------------------------------------------------------------------------

||| λ_consent types.
|||   TyConsent τ — result gated behind a consent decision
|||   TyDenied    — type of the `denied` terminal value
public export
data Ty : Type where
  TyInt     : Ty
  TyStr     : Ty
  TyBool    : Ty
  TyFun     : Ty -> Ty -> Ty
  TyConsent : Ty -> Ty
  TyDenied  : Ty

-- ---------------------------------------------------------------------------
-- Variable names
-- ---------------------------------------------------------------------------

||| Variables are represented as natural numbers.
public export
Var : Type
Var = Nat

-- ---------------------------------------------------------------------------
-- Expressions (Definition 1, expression syntax)
-- ---------------------------------------------------------------------------

||| λ_consent expression syntax.
|||
||| Core forms:
|||   EVar x            — variable (de-Bruijn-named)
|||   ELam x τ e        — lambda abstraction
|||   EApp f a          — application
|||   ELit n            — integer literal
|||   EAdd e1 e2        — integer addition (representative binary op)
|||
||| Consent-specific forms:
|||   EOnlyIfOkay s e   — consent gate: only_if_okay s e
|||   EConsentHandler h e — handler install: consent_handler h e
|||   EAttr p d e       — attribution annotation: attr p d e
|||   EFeel f e         — empathy annotation: feel f e  (phantom at runtime)
|||
||| Terminal values:
|||   EDenied           — the `denied` terminal produced by a denied consent gate
public export
data Expr : Type where
  EVar          : Var -> Expr
  ELam          : Var -> Ty -> Expr -> Expr
  EApp          : Expr -> Expr -> Expr
  ELit          : Int -> Expr
  EAdd          : Expr -> Expr -> Expr
  EOnlyIfOkay   : String -> Expr -> Expr
  EConsentHandler : Handler -> Expr -> Expr
  EAttr         : String -> String -> Expr -> Expr
  EFeel         : String -> Expr -> Expr
  EDenied       : Expr

-- ---------------------------------------------------------------------------
-- Values (Definition 1, value syntax)
-- ---------------------------------------------------------------------------

||| Values are fully-reduced expressions: lambdas, literals, and denied.
||| `denied` is a value because E-ConsentDenied produces it as a terminal.
public export
data IsValue : Expr -> Type where
  VLam    : IsValue (ELam x τ e)
  VLit    : IsValue (ELit n)
  VDenied : IsValue EDenied

-- ---------------------------------------------------------------------------
-- Capture-avoiding substitution
-- ---------------------------------------------------------------------------

||| e[v/x] — substitute v for x in e.
||| Precondition (caller's responsibility): v is closed.
||| Lambda bodies where the binder shadows x are left unchanged.
public export
subst : (x : Var) -> (v : Expr) -> (e : Expr) -> Expr
subst x v (EVar y) =
  case decEq x y of
    Yes _ => v
    No  _ => EVar y
subst x v (ELam y τ body) =
  case decEq x y of
    Yes _ => ELam y τ body          -- x is shadowed; do not descend
    No  _ => ELam y τ (subst x v body)
subst x v (EApp f a)              = EApp (subst x v f) (subst x v a)
subst _ _ (ELit n)                = ELit n
subst x v (EAdd e1 e2)            = EAdd (subst x v e1) (subst x v e2)
subst x v (EOnlyIfOkay s e)       = EOnlyIfOkay s (subst x v e)
subst x v (EConsentHandler h e)   = EConsentHandler h (subst x v e)
subst x v (EAttr p d e)           = EAttr p d (subst x v e)
subst x v (EFeel f e)             = EFeel f (subst x v e)
subst _ _ EDenied                 = EDenied

-- ---------------------------------------------------------------------------
-- Audit log
-- ---------------------------------------------------------------------------

||| A single entry in the audit accumulator A.
||| ConsentEntry records a handler's decision for a given prompt.
||| AttrEntry records attribution (person, description) when attr is evaluated.
public export
data LogEntry : Type where
  ConsentEntry : ConsentDecision -> String -> LogEntry
  AttrEntry    : String -> String -> LogEntry

||| The audit accumulator A — an ordered sequence of log entries.
public export
AuditLog : Type
AuditLog = List LogEntry
