-- SPDX-License-Identifier: PMPL-1.0-or-later
-- SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
-- Safety.idr - Progress, Preservation, and Consent Non-Evasion
--
-- Mechanises Theorems 1–3 from §7 of arxiv-consent-aware-programming.tex.
--
-- Theorem 1 (Progress): a closed well-typed non-value can step.
-- Theorem 2 (Preservation): stepping preserves well-typedness; type may change
--   for consent gates (Consent[τ] → τ on grant, → TyDenied on deny).
-- Theorem 3 (Non-Evasion): only SConsentGranted/SConsentDenied step into a
--   consent gate body; both append a ConsentEntry to the audit log.

module WokeLang.Safety

import WokeLang.Calculus
import WokeLang.Typing
import WokeLang.Reduction

%default total

-- ---------------------------------------------------------------------------
-- Type-change relation (used to state Preservation)
-- ---------------------------------------------------------------------------

public export
data TypeChange : Ty -> Ty -> Type where
  TCRefl    : TypeChange τ τ
  TCGranted : TypeChange (TyConsent τ) τ
  TCDenied  : TypeChange (TyConsent τ) TyDenied

-- ---------------------------------------------------------------------------
-- Canonical forms helpers
-- ---------------------------------------------------------------------------

||| A value typed at a function type must be a lambda.
canonFun : IsValue e -> Typed [] sigma e (TyFun τ1 τ2) ->
           (x : Var ** τ' : Ty ** body : Expr ** e = ELam x τ' body)
canonFun VLam    _   = (_ ** _ ** _ ** Refl)
canonFun VLit    prf = case prf of {}    -- only TLam types ELam; TLit gives TyInt
canonFun VDenied prf = case prf of {}    -- TDenied gives TyDenied

||| A value typed at TyInt must be an integer literal.
intValueIsLit : IsValue e -> Typed [] sigma e TyInt ->
                (n : Int ** e = ELit n)
intValueIsLit VLit    _   = (_ ** Refl)
intValueIsLit VLam    prf = case prf of {}   -- TLam gives TyFun, not TyInt
intValueIsLit VDenied prf = case prf of {}   -- TDenied gives TyDenied

-- ---------------------------------------------------------------------------
-- Theorem 1: Progress
-- ---------------------------------------------------------------------------

public export
data ProgressResult : Expr -> List Handler -> AuditLog -> Type where
  IsVal   : IsValue e -> ProgressResult e H A
  CanStep : Step e H A e' H' A' -> ProgressResult e H A

||| Theorem 1 (Progress, Theorem 1 in §7).
|||
||| For a closed term [] ; Σ ⊢ e : τ, with runtime stack H = Σ,
||| either e is a value or ⟨e, H, A⟩ reduces.
export
progress :
  Typed [] sigma e τ ->
  (A : AuditLog) ->
  ProgressResult e sigma A
-- Values
progress TLit         _ = IsVal VLit
progress (TLam _)     _ = IsVal VLam
progress TDenied      _ = IsVal VDenied
-- Impossible: TVar in empty context (ctxLookup x [] = Nothing)
progress (TVar prf)   _ = absurd prf
-- TAdd: reduce left; if left is a literal, reduce right; then compute.
progress (TAdd l r) A =
  case progress l A of
    CanStep sl => CanStep (SAddLeft sl)
    IsVal  vl  =>
      case intValueIsLit vl l of
        (_ ** Refl) =>
          case progress r A of
            CanStep sr => CanStep (SAddRight sr)
            IsVal  vr  =>
              case intValueIsLit vr r of
                (_ ** Refl) => CanStep SAddLits
-- TApp: reduce function; if value, reduce argument; if both values, beta-reduce.
progress (TApp fTy aTy) A =
  case progress fTy A of
    CanStep sf => CanStep (SAppFun sf)
    IsVal  vf  =>
      case canonFun vf fTy of
        (_ ** _ ** _ ** Refl) =>
          case progress aTy A of
            CanStep sa => CanStep (SAppArg vf sa)
            IsVal  va  => CanStep (SBeta va)
-- TConsent: sigma is non-empty (h :: hs) per T-Consent.
-- applyHandler is total; exactly one of the two consent rules fires.
progress {sigma = h :: hs} {e = EOnlyIfOkay s _} (TConsent _) A =
  case applyHandler h s of
    Granted => CanStep (SConsentGranted Refl)
    Denied  => CanStep (SConsentDenied Refl)
-- THandler: if body is a value, done; otherwise, body steps.
progress (THandler bodyTy) A =
  case progress bodyTy A of
    IsVal  vb => CanStep (SConsentDone vb)
    CanStep s => CanStep (SConsentCong s)
-- TAttr: transparent wrapper.
progress (TAttr eTy) A =
  case progress eTy A of
    IsVal  ve => CanStep (SAttrDone ve)
    CanStep s => CanStep (SAttrCong s)
-- TFeel: phantom wrapper.
progress (TFeel eTy) A =
  case progress eTy A of
    IsVal  ve => CanStep (SFeelDone ve)
    CanStep s => CanStep (SFeelCong s)

-- ---------------------------------------------------------------------------
-- Theorem 2: Preservation
-- ---------------------------------------------------------------------------

||| Theorem 2 (Preservation, Theorem 2 in §7).
|||
||| If [] ; Σ ⊢ e : τ and ⟨e, Σ, A⟩ → ⟨e', Σ', A'⟩,
||| there exists τ' with TypeChange τ τ' and [] ; Σ' ⊢ e' : τ'.
|||
||| Consent gate steps are the only cases where the type changes:
|||   SConsentGranted → TCGranted: Consent[τ] becomes τ
|||   SConsentDenied  → TCDenied:  Consent[τ] becomes TyDenied
export
preservation :
  Typed [] sigma e τ ->
  Step e sigma A e' sigma' A' ->
  (τ' : Ty ** TypeChange τ τ' ** Typed [] sigma' e' τ')
-- SBeta: type of the result is the body's return type (unchanged by substLemma).
preservation (TApp (TLam bodyTy) argTy) (SBeta _) =
  (_ ** TCRefl ** substLemma _ bodyTy argTy)
-- Congruence: function or argument steps.
preservation (TApp fTy aTy) (SAppFun sf) =
  let (_ ** tc ** fTy') = preservation fTy sf
  in  (_ ** tc ** TApp fTy' aTy)
preservation (TApp fTy aTy) (SAppArg _ sa) =
  let (_ ** tc ** aTy') = preservation aTy sa
  in  (_ ** tc ** TApp fTy aTy')
-- Addition congruence and reduction.
preservation (TAdd l r) (SAddLeft sl) =
  let (_ ** tc ** l') = preservation l sl
  in  (_ ** tc ** TAdd l' r)
preservation (TAdd l r) (SAddRight sr) =
  let (_ ** tc ** r') = preservation r sr
  in  (_ ** tc ** TAdd l r')
preservation (TAdd _ _) SAddLits = (_ ** TCRefl ** TLit)
-- SConsentGranted: Consent[τ] → τ.  Body e is exactly the result.
preservation (TConsent bodyTy) (SConsentGranted _) = (_ ** TCGranted ** bodyTy)
-- SConsentDenied: Consent[τ] → TyDenied.  EDenied is always typeable at TyDenied.
preservation (TConsent _)      (SConsentDenied _)  = (_ ** TCDenied ** TDenied)
-- Handler body steps (type preserved).
preservation (THandler bodyTy) (SConsentCong s) =
  let (_ ** tc ** bodyTy') = preservation bodyTy s
  in  (_ ** tc ** THandler bodyTy')
-- Handler done: body was a value; unwrap gives that same type.
preservation (THandler bodyTy) (SConsentDone _) = (_ ** TCRefl ** bodyTy)
-- Attribution and empathy: transparent/phantom.
preservation (TAttr eTy) (SAttrCong s) =
  let (_ ** tc ** eTy') = preservation eTy s
  in  (_ ** tc ** TAttr eTy')
preservation (TAttr eTy) (SAttrDone _) = (_ ** TCRefl ** eTy)
preservation (TFeel eTy) (SFeelCong s) =
  let (_ ** tc ** eTy') = preservation eTy s
  in  (_ ** tc ** TFeel eTy')
preservation (TFeel eTy) (SFeelDone _) = (_ ** TCRefl ** eTy)

-- ---------------------------------------------------------------------------
-- Theorem 3: Consent Non-Evasion
-- ---------------------------------------------------------------------------

||| Evidence that a ConsentEntry for prompt s appears in the audit log A.
public export
data DecisionLogged : AuditLog -> String -> Type where
  LogHere  : DecisionLogged (ConsentEntry d s :: rest) s
  LogThere : DecisionLogged rest s -> DecisionLogged (other :: rest) s

||| Theorem 3 (Consent Non-Evasion, Theorem 3 in §7).
|||
||| The ONLY rules that step the head form EOnlyIfOkay s e are
||| SConsentGranted and SConsentDenied.  Both require a handler decision
||| and append ConsentEntry d s to A.  This follows by structural inversion
||| on the Step derivation — no other constructor matches EOnlyIfOkay.
export
nonEvasion :
  Step (EOnlyIfOkay s e) H A e' H' A' ->
  (d : ConsentDecision ** DecisionLogged A' s)
nonEvasion (SConsentGranted _) = (Granted ** LogHere)
nonEvasion (SConsentDenied _)  = (Denied  ** LogHere)

||| Corollary: accessing the consent gate body requires a logged decision.
||| In the granted case e' = e (body released); in the denied case e' = EDenied.
export
consentBodyRequiresLog :
  Step (EOnlyIfOkay s e) H A e' H' A' ->
  (d : ConsentDecision **
   DecisionLogged A' s **
   Either (e' = e, d = Granted) (e' = EDenied, d = Denied))
consentBodyRequiresLog (SConsentGranted _) =
  (Granted ** LogHere ** Left  (Refl, Refl))
consentBodyRequiresLog (SConsentDenied _)  =
  (Denied  ** LogHere ** Right (Refl, Refl))
