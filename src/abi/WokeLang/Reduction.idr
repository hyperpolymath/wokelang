-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-- SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
-- Reduction.idr - λ_consent small-step operational semantics
--
-- Mechanises Definition 3 (Small-Step Semantics) from §7 of
-- arxiv-consent-aware-programming.tex.
--
-- Machine configuration: ⟨e, H, A⟩ where
--   e : Expr        — the expression being evaluated
--   H : List Handler — the consent handler stack (= ConsentCtx Σ at runtime)
--   A : AuditLog    — the attribution / audit accumulator
--
-- The single-step relation `Step e H A e' H' A'` corresponds to
--   ⟨e, H, A⟩ → ⟨e', H', A'⟩   in the paper.
--
-- Consent rules (the paper's contribution):
--   SConsentGranted / SConsentDenied — fire when H is non-empty and the top
--     handler returns a decision.  Both append a ConsentEntry to A.
--   SConsentCong — inner expression steps inside an extended handler stack.
--   SConsentDone — handler wrapper unwraps once the body is a value.
--
-- E-Attr is modelled as two rules:
--   SAttrCong — congruence: inner expression steps (attr wrapper preserved).
--   SAttrDone — once the body is a value, unwrap and append an AttrEntry.
-- E-Feel is fully phantom: only a congruence rule + a done rule with no log entry.

module WokeLang.Reduction

import WokeLang.Calculus
import WokeLang.Typing

%default total

-- ---------------------------------------------------------------------------
-- The small-step relation
-- ---------------------------------------------------------------------------

||| One-step reduction: ⟨e, H, A⟩ → ⟨e', H', A'⟩.
|||
||| Constructors are named after the paper's reduction rules with an S prefix.
public export
data Step : Expr -> List Handler -> AuditLog -> Expr -> List Handler -> AuditLog -> Type where

  -- Standard STLC rules ---------------------------------------------------

  -- E-Beta: beta-reduce a fully-applied lambda.
  SBeta : IsValue v
        -> Step (EApp (ELam x τ body) v) H A (subst x v body) H A

  -- E-AppFun: reduce the function position.
  SAppFun : Step f H A f' H' A'
          -> Step (EApp f e2) H A (EApp f' e2) H' A'

  -- E-AppArg: reduce the argument once the function is a value.
  SAppArg : IsValue vf
          -> Step e2 H A e2' H' A'
          -> Step (EApp vf e2) H A (EApp vf e2') H' A'

  -- E-Add: evaluate left operand.
  SAddLeft : Step e1 H A e1' H' A'
           -> Step (EAdd e1 e2) H A (EAdd e1' e2) H' A'

  -- E-AddRight: left is an integer literal; evaluate right.
  SAddRight : Step e2 H A e2' H' A'
            -> Step (EAdd (ELit n) e2) H A (EAdd (ELit n) e2') H' A'

  -- E-AddLits: reduce a fully-applied addition.
  SAddLits : Step (EAdd (ELit n1) (ELit n2)) H A (ELit (n1 + n2)) H A

  -- Consent gate rules (the paper's novel contribution) -------------------

  -- E-ConsentGranted (Definition 3): H is non-empty, top handler grants.
  -- The body e is released for evaluation; the consent decision is logged.
  SConsentGranted : {h : Handler} -> {hs : List Handler}
                  -> applyHandler h s = Granted
                  -> Step (EOnlyIfOkay s e) (h :: hs) A
                           e (h :: hs) (ConsentEntry Granted s :: A)

  -- E-ConsentDenied (Definition 3): H is non-empty, top handler denies.
  -- The entire gate reduces to the `denied` terminal value; decision is logged.
  SConsentDenied : {h : Handler} -> {hs : List Handler}
                 -> applyHandler h s = Denied
                 -> Step (EOnlyIfOkay s e) (h :: hs) A
                          EDenied (h :: hs) (ConsentEntry Denied s :: A)

  -- E-Handler / E-HandlerCong: evaluate the body inside the extended stack.
  SConsentCong : Step e (h :: H) A e' (h :: H) A'
               -> Step (EConsentHandler h e) H A (EConsentHandler h e') H A'

  -- E-HandlerDone: once the body is a value, unwrap the handler.
  SConsentDone : IsValue v
               -> Step (EConsentHandler h v) H A v H A

  -- Attribution annotation rules ------------------------------------------

  -- Congruence: body steps; wrapper is preserved.
  SAttrCong : Step e H A e' H' A'
            -> Step (EAttr p d e) H A (EAttr p d e') H' A'

  -- Done: body is a value; unwrap, log attribution.
  SAttrDone : IsValue v
            -> Step (EAttr p d v) H A v H (AttrEntry p d :: A)

  -- Empathy annotation rules (phantom — no log entry) ---------------------

  SFeelCong : Step e H A e' H' A'
            -> Step (EFeel f e) H A (EFeel f e') H' A'

  SFeelDone : IsValue v -> Step (EFeel f v) H A v H A

-- ---------------------------------------------------------------------------
-- Multi-step (reflexive-transitive closure)
-- ---------------------------------------------------------------------------

||| Zero or more small steps.
public export
data Steps : Expr -> List Handler -> AuditLog -> Expr -> List Handler -> AuditLog -> Type where
  Refl  : Steps e H A e H A
  Trans : Step e H A e' H' A'
        -> Steps e' H' A' e'' H'' A''
        -> Steps e H A e'' H'' A''

-- ---------------------------------------------------------------------------
-- Determinism (value-progress disjunction lemma used in Safety.idr)
-- ---------------------------------------------------------------------------

||| Values do not step: no rule fires for a fully-reduced expression.
export
valuesDontStep : IsValue e -> Step e H A e' H' A' -> Void
valuesDontStep VLam  step = case step of {}
valuesDontStep VLit  step = case step of {}
valuesDontStep VDenied step = case step of {}
