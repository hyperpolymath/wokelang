-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-- SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
-- Typing.idr - λ_consent typing judgment and substitution lemma
--
-- Mechanises Definition 2 (Typing Rules) from §7 of arxiv-consent-aware-programming.tex.
--
-- Substitution design note:
--   We prove the CLOSED-VALUE substitution lemma (substLemma): the substituted
--   value v must be typed in the empty context [].  This is sufficient for
--   Preservation because the whole term is typed in [] and every function
--   argument at a beta-redex is therefore itself typed in [].
--
--   The proof handles nested lambdas via a CONTEXT EXCHANGE lemma: when the
--   substitution variable x is encountered under a lambda binder y ≠ x, the
--   two adjacent bindings (y,τy)::(x,τx) are swapped to (x,τx)::(y,τy),
--   putting x back at the head so the recursive substLemma call applies.
--
-- Key invariant fixed vs. the paper:
--   T-Consent requires Σ = h :: hs (non-empty).  The paper's T-Consent allows
--   empty Σ, but Progress requires a handler in scope for the consent gate.

module WokeLang.Typing

import WokeLang.Calculus
import Data.List

%default total

-- ---------------------------------------------------------------------------
-- Typing and consent contexts
-- ---------------------------------------------------------------------------

public export
TyCtx : Type
TyCtx = List (Var, Ty)

||| Consent context = runtime handler stack.
||| Σ in the judgment Γ ; Σ ⊢ e : τ.
public export
ConsentCtx : Type
ConsentCtx = List Handler

-- ---------------------------------------------------------------------------
-- Context lookup (DecEq-based for proof-friendly case splitting)
-- ---------------------------------------------------------------------------

public export
ctxLookup : (x : Var) -> (ctx : TyCtx) -> Maybe Ty
ctxLookup _ [] = Nothing
ctxLookup x ((y, τ) :: rest) =
  case decEq x y of
    Yes _ => Just τ
    No  _ => ctxLookup x rest

-- ---------------------------------------------------------------------------
-- Lookup lemmas
-- ---------------------------------------------------------------------------

export
lookupHere : (x : Var) -> (τ : Ty) -> (ctx : TyCtx)
           -> ctxLookup x ((x, τ) :: ctx) = Just τ
lookupHere x τ ctx with (decEq x x)
  lookupHere x τ ctx | Yes Refl = Refl
  lookupHere x τ ctx | No  neq  = absurd (neq Refl)

export
lookupSkip : (x y : Var) -> (0 neq : x = y -> Void) -> (ctx : TyCtx) -> (τ' : Ty)
           -> ctxLookup x ((y, τ') :: ctx) = ctxLookup x ctx
lookupSkip x y neq ctx τ' with (decEq x y)
  lookupSkip x x neq ctx τ' | Yes Refl = absurd (neq Refl)
  lookupSkip x y neq ctx τ' | No  _    = Refl

-- ---------------------------------------------------------------------------
-- The typing judgment  Γ ; Σ ⊢ e : τ
-- ---------------------------------------------------------------------------

public export
data Typed : TyCtx -> ConsentCtx -> Expr -> Ty -> Type where

  TVar  : ctxLookup x ctx = Just τ
        -> Typed ctx sigma (EVar x) τ

  TLam  : Typed ((x, τ1) :: ctx) sigma body τ2
        -> Typed ctx sigma (ELam x τ1 body) (TyFun τ1 τ2)

  TApp  : Typed ctx sigma f (TyFun τ1 τ2)
        -> Typed ctx sigma a τ1
        -> Typed ctx sigma (EApp f a) τ2

  TLit  : Typed ctx sigma (ELit n) TyInt

  TAdd  : Typed ctx sigma e1 TyInt
        -> Typed ctx sigma e2 TyInt
        -> Typed ctx sigma (EAdd e1 e2) TyInt

  -- T-Consent: non-empty Σ required (fixes the paper gap).
  TConsent : {h : Handler} -> {hs : List Handler}
           -> Typed ctx (h :: hs) e τ
           -> Typed ctx (h :: hs) (EOnlyIfOkay s e) (TyConsent τ)

  THandler : {h : Handler}
           -> Typed ctx (h :: sigma) e τ
           -> Typed ctx sigma (EConsentHandler h e) τ

  TAttr : Typed ctx sigma e τ -> Typed ctx sigma (EAttr p d e) τ
  TFeel : Typed ctx sigma e τ -> Typed ctx sigma (EFeel f e) τ
  TDenied : Typed ctx sigma EDenied TyDenied

-- ---------------------------------------------------------------------------
-- General weakening via context inclusion
-- ---------------------------------------------------------------------------

public export
CtxInclusion : TyCtx -> TyCtx -> Type
CtxInclusion ctx ctx' =
  (z : Var) -> (τ : Ty) -> ctxLookup z ctx = Just τ -> ctxLookup z ctx' = Just τ

||| Extend a context inclusion under a shared binder.
export
extendInclusion :
  {ctx, ctx' : TyCtx} ->
  (binder : Var) -> (τ_b : Ty) ->
  CtxInclusion ctx ctx' ->
  CtxInclusion ((binder, τ_b) :: ctx) ((binder, τ_b) :: ctx')
extendInclusion binder τ_b incl z τ prf with (decEq z binder)
  -- binder = z: both sides look up z and find τ_b.
  -- prf says ctxLookup binder (...::ctx) = Just τ, and lookupHere says that is Just τ_b,
  -- so τ = τ_b.  Use case-on-Refl to unify and then apply lookupHere for ctx'.
  extendInclusion binder τ_b incl _ τ prf | Yes Refl =
    case trans (sym (lookupHere binder τ_b ctx)) prf of
      Refl => lookupHere binder τ_b ctx'
  -- binder ≠ z: skip the binder on both sides, apply the original inclusion.
  extendInclusion binder τ_b incl z τ prf | No neq =
    trans (lookupSkip z binder neq ctx' τ_b)
          (incl z τ (trans (sym (lookupSkip z binder neq ctx τ_b)) prf))

||| Weaken a typing derivation by any context inclusion.
export
weakenFull :
  CtxInclusion ctx ctx' ->
  Typed ctx sigma e τ ->
  Typed ctx' sigma e τ
weakenFull incl (TVar prf)      = TVar (incl _ _ prf)
weakenFull incl (TLam bodyTy)   = TLam (weakenFull (extendInclusion _ _ incl) bodyTy)
weakenFull incl (TApp fTy aTy)  = TApp (weakenFull incl fTy) (weakenFull incl aTy)
weakenFull _    TLit             = TLit
weakenFull incl (TAdd l r)      = TAdd (weakenFull incl l) (weakenFull incl r)
weakenFull incl (TConsent bTy)  = TConsent (weakenFull incl bTy)
weakenFull incl (THandler bTy)  = THandler (weakenFull incl bTy)
weakenFull incl (TAttr eTy)     = TAttr (weakenFull incl eTy)
weakenFull incl (TFeel eTy)     = TFeel (weakenFull incl eTy)
weakenFull _    TDenied          = TDenied

-- ---------------------------------------------------------------------------
-- Weakening from the empty context
-- ---------------------------------------------------------------------------

||| The empty context is included in every context (vacuously: no bindings).
export
emptyInclusion : (ctx : TyCtx) -> CtxInclusion [] ctx
emptyInclusion _ _ _ prf = absurd prf   -- ctxLookup z [] = Nothing

||| A closed term (typed in []) can be re-typed in any context.
export
weakenFromEmpty : {ctx : TyCtx} -> Typed [] sigma v τ -> Typed ctx sigma v τ
weakenFromEmpty = weakenFull (emptyInclusion _)

-- ---------------------------------------------------------------------------
-- Context exchange: swap two adjacent distinct bindings
-- ---------------------------------------------------------------------------

||| Lookup is equal after swapping two adjacent bindings when the binders differ.
exchangeLookup :
  (z x y : Var) -> (τx τy : Ty) -> (ctx : TyCtx) ->
  (0 neq : x = y -> Void) ->
  ctxLookup z ((y, τy) :: (x, τx) :: ctx) = ctxLookup z ((x, τx) :: (y, τy) :: ctx)
exchangeLookup z x y τx τy ctx neq with (decEq z x), (decEq z y)
  -- z = x = y: impossible since x ≠ y.
  exchangeLookup z x _ _ _ _ neq | Yes Refl | Yes Refl = absurd (neq Refl)
  -- z = x, z ≠ y: LHS = Just τx (skip y, then find x); RHS = Just τx (x at head).
  exchangeLookup z x y τx τy ctx neq | Yes Refl | No neq_zy =
    trans (trans (lookupSkip x y (\e => neq_zy (sym e)) ((x, τx) :: ctx) τy)
                 (lookupHere x τx ctx))
          (sym (lookupHere x τx ((y, τy) :: ctx)))
  -- z = y, z ≠ x: LHS = Just τy (y at head); RHS = Just τy (skip x, then find y).
  exchangeLookup z x y τx τy ctx neq | No neq_zx | Yes Refl =
    trans (lookupHere y τy ((x, τx) :: ctx))
          (sym (trans (lookupSkip y x neq_zx ((y, τy) :: ctx) τx)
                      (lookupHere y τy ctx)))
  -- z ≠ x, z ≠ y: both sides equal ctxLookup z ctx.
  exchangeLookup z x y τx τy ctx neq | No neq_zx | No neq_zy =
    trans (trans (lookupSkip z y (\e => neq_zy (sym e)) ((x, τx) :: ctx) τy)
                 (lookupSkip z x neq_zx ctx τx))
          (sym (trans (lookupSkip z x neq_zx ((y, τy) :: ctx) τx)
                      (lookupSkip z y (\e => neq_zy (sym e)) ctx τy)))

||| Context exchange for typed terms.
export
ctxExchange :
  {ctx : TyCtx} ->
  (x y : Var) -> (τx τy : Ty) ->
  (0 neq : x = y -> Void) ->
  Typed ((y, τy) :: (x, τx) :: ctx) sigma e τ ->
  Typed ((x, τx) :: (y, τy) :: ctx) sigma e τ
ctxExchange x y τx τy neq =
  weakenFull (\z, τ, prf => trans (sym (exchangeLookup z x y τx τy _ neq)) prf)

-- ---------------------------------------------------------------------------
-- Substitution lemma (closed-value variant)
--
-- substLemma x ty_e ty_v:
--   If  [(x, τ1)] ; Σ ⊢ e : τ2  and  [] ; Σ ⊢ v : τ1,
--   then  [] ; Σ ⊢ e[v/x] : τ2.
--
-- The ContextExchange handles the TLam case: when the substitution variable x
-- appears under a lambda binder y ≠ x, we exchange (y,τy)::(x,τx) to
-- (x,τx)::(y,τy) in the body's typing derivation, then recurse.
-- Since v is typed in [] (closed), weakenFromEmpty provides it at any depth.
-- ---------------------------------------------------------------------------

export
substLemma :
  (x : Var) ->
  Typed ((x, τ1) :: ctx) sigma e τ2 ->
  Typed [] sigma v τ1 ->
  Typed ctx sigma (subst x v e) τ2
-- T-Var
substLemma x (TVar {x = z} prf) vTy with (decEq x z)
  -- z = x: variable is the substitution target.
  -- prf shows ctxLookup x ((x,τ1)::ctx) = Just τ2, which by lookupHere is Just τ1,
  -- so τ2 = τ1.  Return v (weakened from [] to ctx).
  substLemma x (TVar {x} prf) vTy | Yes Refl =
    case trans (sym (lookupHere x τ1 ctx)) prf of
      Refl => weakenFromEmpty vTy
  -- z ≠ x: different variable; skip the x-binding and preserve its type.
  substLemma x (TVar {x = z} prf) _ | No neq =
    TVar (trans (sym (lookupSkip z x (\e => neq (sym e)) ctx τ1)) prf)
-- T-Lam
substLemma x (TLam {x = y} bodyTy) vTy with (decEq x y)
  -- x = y: lambda re-binds x; substitution is blocked (shadowing).
  substLemma x (TLam {x} bodyTy) _ | Yes Refl = TLam bodyTy
  -- x ≠ y: descend into the body.
  -- bodyTy : Typed ((y,τy)::(x,τ1)::ctx) sigma body τ_ret
  -- Exchange to get   Typed ((x,τ1)::(y,τy)::ctx) sigma body τ_ret,
  -- then recurse with the same closed value vTy.
  substLemma x (TLam {x = y} bodyTy) vTy | No neq =
    TLam (substLemma x (ctxExchange x y τ1 _ (\e => neq (sym e)) bodyTy) vTy)
-- Remaining cases: straightforward structural recursion.
substLemma x (TApp fTy aTy)   vTy = TApp (substLemma x fTy vTy) (substLemma x aTy vTy)
substLemma _ TLit              _  = TLit
substLemma x (TAdd l r)       vTy = TAdd (substLemma x l vTy) (substLemma x r vTy)
substLemma x (TConsent bTy)   vTy = TConsent (substLemma x bTy vTy)
substLemma x (THandler bTy)   vTy = THandler (substLemma x bTy vTy)
substLemma x (TAttr eTy)      vTy = TAttr (substLemma x eTy vTy)
substLemma x (TFeel eTy)      vTy = TFeel (substLemma x eTy vTy)
substLemma _ TDenied           _  = TDenied
