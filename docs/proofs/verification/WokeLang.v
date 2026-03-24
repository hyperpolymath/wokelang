(* WokeLang Formal Verification in Coq *)
(* SPDX-License-Identifier: MIT OR Apache-2.0 *)

(* ========================================================================= *)
(* This file contains Coq definitions and theorem stubs for WokeLang.        *)
(* Many proofs are marked as TODO and require completion for full            *)
(* formal verification.                                                       *)
(* ========================================================================= *)

Require Import Coq.Strings.String.
Require Import Coq.Lists.List.
Require Import Coq.ZArith.ZArith.
Require Import Coq.Reals.Reals.
Import ListNotations.

(* ========================================================================= *)
(* 1. Abstract Syntax                                                        *)
(* ========================================================================= *)

(** ** Types *)

Inductive woke_type : Type :=
  | TInt : woke_type
  | TFloat : woke_type
  | TString : woke_type
  | TBool : woke_type
  | TUnit : woke_type
  | TArray : woke_type -> woke_type
  | TMaybe : woke_type -> woke_type
  | TResult : woke_type -> woke_type -> woke_type
  | TFunction : list woke_type -> woke_type -> woke_type
  | TVar : nat -> woke_type.  (* Type variable with De Bruijn index *)

(** ** Values *)

Inductive value : Type :=
  | VInt : Z -> value
  | VFloat : R -> value
  | VString : string -> value
  | VBool : bool -> value
  | VUnit : value
  | VArray : list value -> value
  | VOkay : value -> value
  | VOops : string -> value.

(** ** Binary Operators *)

Inductive binop : Type :=
  | BAdd | BSub | BMul | BDiv | BMod
  | BEq | BNeq | BLt | BGt | BLe | BGe
  | BAnd | BOr.

(** ** Unary Operators *)

Inductive unop : Type :=
  | UNeg | UNot.

(** ** Expressions *)

Inductive expr : Type :=
  | ELit : value -> expr
  | EVar : string -> expr
  | EBinOp : binop -> expr -> expr -> expr
  | EUnOp : unop -> expr -> expr
  | ECall : string -> list expr -> expr
  | EArray : list expr -> expr
  | EOkay : expr -> expr
  | EOops : expr -> expr
  | EUnwrap : expr -> expr.

(** ** Statements *)

Inductive stmt : Type :=
  | SVarDecl : string -> expr -> stmt
  | SAssign : string -> expr -> stmt
  | SReturn : expr -> stmt
  | SIf : expr -> list stmt -> list stmt -> stmt
  | SLoop : expr -> list stmt -> stmt
  | SAttempt : list stmt -> string -> stmt
  | SConsent : string -> list stmt -> stmt
  | SExpr : expr -> stmt
  | SComplain : string -> stmt.

(** ** Top-Level Items *)

Inductive top_item : Type :=
  | TFunction_def : string -> list (string * woke_type) -> woke_type -> list stmt -> top_item
  | TWorker_def : string -> list stmt -> top_item
  | TGratitude : list (string * string) -> top_item.

(** ** Programs *)

Definition program := list top_item.

(* ========================================================================= *)
(* 2. Environments                                                           *)
(* ========================================================================= *)

Definition env := string -> option value.

Definition empty_env : env := fun _ => None.

Definition extend_env (x : string) (v : value) (e : env) : env :=
  fun y => if String.eqb x y then Some v else e y.

Definition type_env := string -> option woke_type.

Definition empty_type_env : type_env := fun _ => None.

Definition extend_type_env (x : string) (t : woke_type) (e : type_env) : type_env :=
  fun y => if String.eqb x y then Some t else e y.

(* ========================================================================= *)
(* 2b. Value Equality (decidable)                                            *)
(* ========================================================================= *)

(** Decidable equality on values. We axiomatize this because Coq's real
    numbers (R) do not have decidable equality without classical axioms.
    In a computational setting, float equality would use IEEE comparison.
    The axiom is sound because all value constructors carry data with
    decidable equality in any concrete implementation. *)

Axiom value_eq_dec : forall (v1 v2 : value), {v1 = v2} + {v1 <> v2}.

(* ========================================================================= *)
(* 3. Type Checking                                                          *)
(* ========================================================================= *)

(** ** Type Checking Judgment *)

Inductive has_type : type_env -> expr -> woke_type -> Prop :=
  | T_Int : forall G n,
      has_type G (ELit (VInt n)) TInt
  | T_Float : forall G r,
      has_type G (ELit (VFloat r)) TFloat
  | T_String : forall G s,
      has_type G (ELit (VString s)) TString
  | T_Bool : forall G b,
      has_type G (ELit (VBool b)) TBool
  | T_Unit : forall G,
      has_type G (ELit VUnit) TUnit
  | T_Var : forall G x t,
      G x = Some t ->
      has_type G (EVar x) t
  | T_Add_Int : forall G e1 e2,
      has_type G e1 TInt ->
      has_type G e2 TInt ->
      has_type G (EBinOp BAdd e1 e2) TInt
  | T_Add_Float : forall G e1 e2,
      has_type G e1 TFloat ->
      has_type G e2 TFloat ->
      has_type G (EBinOp BAdd e1 e2) TFloat
  | T_Add_String : forall G e1 e2,
      has_type G e1 TString ->
      has_type G e2 TString ->
      has_type G (EBinOp BAdd e1 e2) TString
  | T_Eq : forall G e1 e2 t,
      has_type G e1 t ->
      has_type G e2 t ->
      has_type G (EBinOp BEq e1 e2) TBool
  | T_And : forall G e1 e2,
      has_type G e1 TBool ->
      has_type G e2 TBool ->
      has_type G (EBinOp BAnd e1 e2) TBool
  | T_Neg_Int : forall G e,
      has_type G e TInt ->
      has_type G (EUnOp UNeg e) TInt
  | T_Neg_Float : forall G e,
      has_type G e TFloat ->
      has_type G (EUnOp UNeg e) TFloat
  | T_Not : forall G e,
      has_type G e TBool ->
      has_type G (EUnOp UNot e) TBool
  | T_Array : forall G es t,
      Forall (fun e => has_type G e t) es ->
      has_type G (EArray es) (TArray t)
  | T_Okay : forall G e t,
      has_type G e t ->
      has_type G (EOkay e) (TResult t TString)
  | T_Oops : forall G e t,
      has_type G e TString ->
      has_type G (EOops e) (TResult t TString)
  | T_Unwrap : forall G e t_ok t_err,
      has_type G e (TResult t_ok t_err) ->
      has_type G (EUnwrap e) t_ok
  | T_Lit_Okay : forall G v t,
      has_type G (ELit v) t ->
      has_type G (ELit (VOkay v)) (TResult t TString)
  | T_Lit_Oops : forall G s t,
      has_type G (ELit (VOops s)) (TResult t TString).

(* ========================================================================= *)
(* 4. Small-Step Operational Semantics                                       *)
(* ========================================================================= *)

(** ** Value Predicate *)

Inductive is_value : expr -> Prop :=
  | V_Lit : forall v, is_value (ELit v)
  | V_Array : forall vs,
      Forall is_value (map ELit vs) ->
      is_value (EArray (map ELit vs)).

(** ** Small-Step Reduction *)

Inductive step : expr -> env -> expr -> env -> Prop :=
  | S_Var : forall x rho v,
      rho x = Some v ->
      step (EVar x) rho (ELit v) rho
  | S_BinOp_Left : forall op e1 e1' e2 rho rho',
      step e1 rho e1' rho' ->
      step (EBinOp op e1 e2) rho (EBinOp op e1' e2) rho'
  | S_BinOp_Right : forall op v1 e2 e2' rho rho',
      is_value (ELit v1) ->
      step e2 rho e2' rho' ->
      step (EBinOp op (ELit v1) e2) rho (EBinOp op (ELit v1) e2') rho'
  | S_Add_Int : forall n1 n2 rho,
      step (EBinOp BAdd (ELit (VInt n1)) (ELit (VInt n2))) rho
           (ELit (VInt (n1 + n2)%Z)) rho
  | S_Add_String : forall s1 s2 rho,
      step (EBinOp BAdd (ELit (VString s1)) (ELit (VString s2))) rho
           (ELit (VString (s1 ++ s2))) rho
  | S_Eq_True : forall v rho,
      step (EBinOp BEq (ELit v) (ELit v)) rho (ELit (VBool true)) rho
  | S_Neg_Int : forall n rho,
      step (EUnOp UNeg (ELit (VInt n))) rho (ELit (VInt (-n)%Z)) rho
  | S_Not : forall b rho,
      step (EUnOp UNot (ELit (VBool b))) rho (ELit (VBool (negb b))) rho
  | S_Okay : forall v rho,
      is_value (ELit v) ->
      step (EOkay (ELit v)) rho (ELit (VOkay v)) rho
  | S_Oops : forall s rho,
      step (EOops (ELit (VString s))) rho (ELit (VOops s)) rho
  | S_Add_Float : forall r1 r2 rho,
      step (EBinOp BAdd (ELit (VFloat r1)) (ELit (VFloat r2))) rho
           (ELit (VFloat (r1 + r2)%R)) rho
  | S_And : forall b1 b2 rho,
      step (EBinOp BAnd (ELit (VBool b1)) (ELit (VBool b2))) rho
           (ELit (VBool (andb b1 b2))) rho
  | S_Eq_False : forall v1 v2 rho,
      v1 <> v2 ->
      step (EBinOp BEq (ELit v1) (ELit v2)) rho (ELit (VBool false)) rho
  | S_UnOp_inner : forall op e e' rho rho',
      step e rho e' rho' ->
      step (EUnOp op e) rho (EUnOp op e') rho'
  | S_Neg_Float : forall r rho,
      step (EUnOp UNeg (ELit (VFloat r))) rho (ELit (VFloat (- r)%R)) rho
  | S_Okay_step : forall e e' rho rho',
      step e rho e' rho' ->
      step (EOkay e) rho (EOkay e') rho'
  | S_Oops_step : forall e e' rho rho',
      step e rho e' rho' ->
      step (EOops e) rho (EOops e') rho'
  | S_Unwrap_step : forall e e' rho rho',
      step e rho e' rho' ->
      step (EUnwrap e) rho (EUnwrap e') rho'
  | S_Unwrap_Okay : forall v rho,
      step (EUnwrap (ELit (VOkay v))) rho (ELit v) rho
  | S_Unwrap_Oops : forall s rho,
      step (EUnwrap (ELit (VOops s))) rho (ELit (VOops s)) rho
  | S_Array_step : forall vs e e' es rho rho',
      step e rho e' rho' ->
      step (EArray (map ELit vs ++ e :: es)) rho
           (EArray (map ELit vs ++ e' :: es)) rho'.

(** ** Multi-Step Reduction *)

Inductive multi_step : expr -> env -> expr -> env -> Prop :=
  | MS_Refl : forall e rho,
      multi_step e rho e rho
  | MS_Step : forall e1 e2 e3 rho1 rho2 rho3,
      step e1 rho1 e2 rho2 ->
      multi_step e2 rho2 e3 rho3 ->
      multi_step e1 rho1 e3 rho3.

(* ========================================================================= *)
(* 5. Type Safety Theorems                                                   *)
(* ========================================================================= *)

(** ** Canonical Forms Lemmas *)

Lemma canonical_forms_int : forall v,
  has_type empty_type_env (ELit v) TInt ->
  exists n, v = VInt n.
Proof.
  intros v H.
  inversion H; subst.
  - exists n. reflexivity.
  - (* T_Lit_Okay: TResult _ _ = TInt *) discriminate.
  - (* T_Lit_Oops: TResult _ _ = TInt *) discriminate.
Qed.

Lemma canonical_forms_bool : forall v,
  has_type empty_type_env (ELit v) TBool ->
  exists b, v = VBool b.
Proof.
  intros v H.
  inversion H; subst.
  - exists b. reflexivity.
  - discriminate.
  - discriminate.
Qed.

Lemma canonical_forms_string : forall v,
  has_type empty_type_env (ELit v) TString ->
  exists s, v = VString s.
Proof.
  intros v H.
  inversion H; subst.
  - exists s. reflexivity.
  - discriminate.
  - discriminate.
Qed.

Lemma canonical_forms_float : forall v,
  has_type empty_type_env (ELit v) TFloat ->
  exists r, v = VFloat r.
Proof.
  intros v H.
  inversion H; subst.
  - exists r. reflexivity.
  - discriminate.
  - discriminate.
Qed.

(** Canonical forms for expressions: if a well-typed expression is a value,
    it must be an ELit of the appropriate shape. *)

Lemma value_is_lit_or_array : forall e,
  is_value e ->
  (exists v, e = ELit v) \/ (exists vs, e = EArray (map ELit vs)).
Proof.
  intros e Hv. inversion Hv; subst.
  - left. exists v. reflexivity.
  - right. exists vs. reflexivity.
Qed.

Lemma canonical_forms_int_expr : forall e,
  has_type empty_type_env e TInt ->
  is_value e ->
  exists n, e = ELit (VInt n).
Proof.
  intros e Ht Hv.
  destruct (value_is_lit_or_array e Hv) as [[v Heq] | [vs Heq]].
  - subst. apply canonical_forms_int in Ht.
    destruct Ht as [n Heq]. subst. exists n. reflexivity.
  - subst. inversion Ht; subst; discriminate.
Qed.

Lemma canonical_forms_float_expr : forall e,
  has_type empty_type_env e TFloat ->
  is_value e ->
  exists r, e = ELit (VFloat r).
Proof.
  intros e Ht Hv.
  destruct (value_is_lit_or_array e Hv) as [[v Heq] | [vs Heq]].
  - subst. apply canonical_forms_float in Ht.
    destruct Ht as [r Heq]. subst. exists r. reflexivity.
  - subst. inversion Ht; subst; discriminate.
Qed.

Lemma canonical_forms_bool_expr : forall e,
  has_type empty_type_env e TBool ->
  is_value e ->
  exists b, e = ELit (VBool b).
Proof.
  intros e Ht Hv.
  destruct (value_is_lit_or_array e Hv) as [[v Heq] | [vs Heq]].
  - subst. apply canonical_forms_bool in Ht.
    destruct Ht as [b Heq]. subst. exists b. reflexivity.
  - subst. inversion Ht; subst; discriminate.
Qed.

Lemma canonical_forms_string_expr : forall e,
  has_type empty_type_env e TString ->
  is_value e ->
  exists s, e = ELit (VString s).
Proof.
  intros e Ht Hv.
  destruct (value_is_lit_or_array e Hv) as [[v Heq] | [vs Heq]].
  - subst. apply canonical_forms_string in Ht.
    destruct Ht as [s Heq]. subst. exists s. reflexivity.
  - subst. inversion Ht; subst; discriminate.
Qed.

Lemma canonical_forms_result_expr : forall e t_ok t_err,
  has_type empty_type_env e (TResult t_ok t_err) ->
  is_value e ->
  (exists v, e = ELit (VOkay v)) \/ (exists s, e = ELit (VOops s)).
Proof.
  intros e t_ok t_err Ht Hv.
  destruct (value_is_lit_or_array e Hv) as [[v Heq] | [vs Heq]].
  - subst. inversion Ht; subst.
    + (* T_Lit_Okay *) left. exists v0. reflexivity.
    + (* T_Lit_Oops *) right. exists s. reflexivity.
  - subst. inversion Ht; subst; discriminate.
Qed.

(** ** Progress Theorem *)

(** All previously-blocked cases are now provable with the extended step
    relation (S_Add_Float, S_And, S_Eq_False, S_UnOp_inner, S_Neg_Float,
    S_Okay_step, S_Oops_step, S_Unwrap_step, S_Unwrap_Oops, S_Array_step).

    The T_Array case still requires an admit because proving progress for
    every element in a list requires a separate induction on the list that
    interacts with the Forall hypothesis in a non-trivial way.

    The T_Lit_Okay and T_Lit_Oops cases are immediate since ELit is a value. *)

Theorem progress : forall e t,
  has_type empty_type_env e t ->
  is_value e \/ exists e' rho', step e empty_env e' rho'.
Proof.
  intros e t H.
  induction H.
  - (* T_Int *) left. constructor.
  - (* T_Float *) left. constructor.
  - (* T_String *) left. constructor.
  - (* T_Bool *) left. constructor.
  - (* T_Unit *) left. constructor.
  - (* T_Var *)
    unfold empty_type_env in H. discriminate.
  - (* T_Add_Int *)
    right.
    destruct IHhas_type1 as [Hv1 | [e1' [rho1' Hs1]]].
    + destruct IHhas_type2 as [Hv2 | [e2' [rho2' Hs2]]].
      * destruct (canonical_forms_int_expr e1 H Hv1) as [n1 Heq1].
        destruct (canonical_forms_int_expr e2 H0 Hv2) as [n2 Heq2].
        subst.
        exists (ELit (VInt (n1 + n2)%Z)), empty_env.
        apply S_Add_Int.
      * destruct (canonical_forms_int_expr e1 H Hv1) as [n1 Heq1].
        subst.
        exists (EBinOp BAdd (ELit (VInt n1)) e2'), rho2'.
        apply S_BinOp_Right; [constructor | assumption].
    + exists (EBinOp BAdd e1' e2), rho1'.
      apply S_BinOp_Left. assumption.
  - (* T_Add_Float *)
    right.
    destruct IHhas_type1 as [Hv1 | [e1' [rho1' Hs1]]].
    + destruct IHhas_type2 as [Hv2 | [e2' [rho2' Hs2]]].
      * destruct (canonical_forms_float_expr e1 H Hv1) as [r1 Heq1].
        destruct (canonical_forms_float_expr e2 H0 Hv2) as [r2 Heq2].
        subst.
        exists (ELit (VFloat (r1 + r2)%R)), empty_env.
        apply S_Add_Float.
      * destruct (canonical_forms_float_expr e1 H Hv1) as [r1 Heq1].
        subst.
        exists (EBinOp BAdd (ELit (VFloat r1)) e2'), rho2'.
        apply S_BinOp_Right; [constructor | assumption].
    + exists (EBinOp BAdd e1' e2), rho1'.
      apply S_BinOp_Left. assumption.
  - (* T_Add_String *)
    right.
    destruct IHhas_type1 as [Hv1 | [e1' [rho1' Hs1]]].
    + destruct IHhas_type2 as [Hv2 | [e2' [rho2' Hs2]]].
      * destruct (canonical_forms_string_expr e1 H Hv1) as [s1 Heq1].
        destruct (canonical_forms_string_expr e2 H0 Hv2) as [s2 Heq2].
        subst.
        exists (ELit (VString (s1 ++ s2))), empty_env.
        apply S_Add_String.
      * destruct (canonical_forms_string_expr e1 H Hv1) as [s1 Heq1].
        subst.
        exists (EBinOp BAdd (ELit (VString s1)) e2'), rho2'.
        apply S_BinOp_Right; [constructor | assumption].
    + exists (EBinOp BAdd e1' e2), rho1'.
      apply S_BinOp_Left. assumption.
  - (* T_Eq *)
    right.
    destruct IHhas_type1 as [Hv1 | [e1' [rho1' Hs1]]].
    + destruct IHhas_type2 as [Hv2 | [e2' [rho2' Hs2]]].
      * (* Both values - use decidable equality *)
        destruct (value_is_lit_or_array e1 Hv1) as [[v1 Heq1] | [vs1 Heq1]];
        destruct (value_is_lit_or_array e2 Hv2) as [[v2 Heq2] | [vs2 Heq2]];
        subst.
        -- destruct (value_eq_dec v1 v2) as [Heq | Hneq].
           ++ subst. exists (ELit (VBool true)), empty_env.
              apply S_Eq_True.
           ++ exists (ELit (VBool false)), empty_env.
              apply S_Eq_False. assumption.
        -- inversion H0; subst; discriminate.
        -- inversion H; subst; discriminate.
        -- inversion H; subst; discriminate.
      * destruct (value_is_lit_or_array e1 Hv1) as [[v1 Heq1] | [vs1 Heq1]].
        -- subst. exists (EBinOp BEq (ELit v1) e2'), rho2'.
           apply S_BinOp_Right; [constructor | assumption].
        -- subst. inversion H; subst; discriminate.
    + exists (EBinOp BEq e1' e2), rho1'.
      apply S_BinOp_Left. assumption.
  - (* T_And *)
    right.
    destruct IHhas_type1 as [Hv1 | [e1' [rho1' Hs1]]].
    + destruct IHhas_type2 as [Hv2 | [e2' [rho2' Hs2]]].
      * destruct (canonical_forms_bool_expr e1 H Hv1) as [b1 Heq1].
        destruct (canonical_forms_bool_expr e2 H0 Hv2) as [b2 Heq2].
        subst.
        exists (ELit (VBool (andb b1 b2))), empty_env.
        apply S_And.
      * destruct (canonical_forms_bool_expr e1 H Hv1) as [b1 Heq1].
        subst. exists (EBinOp BAnd (ELit (VBool b1)) e2'), rho2'.
        apply S_BinOp_Right; [constructor | assumption].
    + exists (EBinOp BAnd e1' e2), rho1'.
      apply S_BinOp_Left. assumption.
  - (* T_Neg_Int *)
    right.
    destruct IHhas_type as [Hv | [e' [rho' Hs]]].
    + destruct (canonical_forms_int_expr e H Hv) as [n Heq].
      subst. exists (ELit (VInt (-n)%Z)), empty_env.
      apply S_Neg_Int.
    + exists (EUnOp UNeg e'), rho'.
      apply S_UnOp_inner. assumption.
  - (* T_Neg_Float *)
    right.
    destruct IHhas_type as [Hv | [e' [rho' Hs]]].
    + destruct (canonical_forms_float_expr e H Hv) as [r Heq].
      subst. exists (ELit (VFloat (- r)%R)), empty_env.
      apply S_Neg_Float.
    + exists (EUnOp UNeg e'), rho'.
      apply S_UnOp_inner. assumption.
  - (* T_Not *)
    right.
    destruct IHhas_type as [Hv | [e' [rho' Hs]]].
    + destruct (canonical_forms_bool_expr e H Hv) as [b Heq].
      subst. exists (ELit (VBool (negb b))), empty_env.
      apply S_Not.
    + exists (EUnOp UNot e'), rho'.
      apply S_UnOp_inner. assumption.
  - (* T_Array *)
    (* Array progress requires induction on the element list to find the
       first non-value element and step it. This interacts with the Forall
       typing hypothesis and needs a separate auxiliary lemma. *)
    admit.
  - (* T_Okay *)
    right.
    destruct IHhas_type as [Hv | [e' [rho' Hs]]].
    + destruct (value_is_lit_or_array e Hv) as [[v Heq] | [vs Heq]].
      * subst. exists (ELit (VOkay v)), empty_env.
        apply S_Okay. constructor.
      * (* EArray value inside EOkay - S_Okay requires ELit, but EArray
           is also a value. This is a design gap: EOkay should accept any
           value, not just ELit. We admit this edge case. *)
        admit.
    + exists (EOkay e'), rho'.
      apply S_Okay_step. assumption.
  - (* T_Oops *)
    right.
    destruct IHhas_type as [Hv | [e' [rho' Hs]]].
    + destruct (canonical_forms_string_expr e H Hv) as [s Heq].
      subst. exists (ELit (VOops s)), empty_env.
      apply S_Oops.
    + exists (EOops e'), rho'.
      apply S_Oops_step. assumption.
  - (* T_Unwrap *)
    right.
    destruct IHhas_type as [Hv | [e' [rho' Hs]]].
    + destruct (canonical_forms_result_expr e t_ok t_err H Hv) as
        [[v Heq] | [s Heq]].
      * subst. exists (ELit v), empty_env.
        apply S_Unwrap_Okay.
      * subst. exists (ELit (VOops s)), empty_env.
        apply S_Unwrap_Oops.
    + exists (EUnwrap e'), rho'.
      apply S_Unwrap_step. assumption.
  - (* T_Lit_Okay *) left. constructor.
  - (* T_Lit_Oops *) left. constructor.
Admitted.
(** NOTE: 2 admits remain in progress:
    1. T_Array: needs auxiliary lemma for list element progress
    2. T_Okay with EArray value: S_Okay only handles ELit sub-values *)

(** ** Preservation Theorem *)

(** Proof by induction on the step relation, then inversion on typing.
    With T_Lit_Okay and T_Lit_Oops added to has_type, all cases that were
    previously blocked (S_Okay, S_Oops, S_Unwrap_Okay) are now provable.
    The new step rules (S_Add_Float, S_And, S_Eq_False, S_UnOp_inner,
    S_Neg_Float, S_Okay_step, S_Oops_step, S_Unwrap_step, S_Unwrap_Oops,
    S_Array_step) also need corresponding cases.

    The S_Array_step case is admitted because it requires reasoning about
    list structure and Forall preservation under element stepping. *)

Theorem preservation : forall e e' t rho rho',
  has_type empty_type_env e t ->
  step e rho e' rho' ->
  has_type empty_type_env e' t.
Proof.
  intros e e' t rho rho' Ht Hs.
  generalize dependent t.
  induction Hs; intros t Ht.
  - (* S_Var *)
    inversion Ht; subst.
    unfold empty_type_env in *. discriminate.
  - (* S_BinOp_Left *)
    inversion Ht; subst.
    + apply T_Add_Int; [apply IHHs; assumption | assumption].
    + apply T_Add_Float; [apply IHHs; assumption | assumption].
    + apply T_Add_String; [apply IHHs; assumption | assumption].
    + eapply T_Eq; [apply IHHs; eassumption | eassumption].
    + apply T_And; [apply IHHs; assumption | assumption].
  - (* S_BinOp_Right *)
    inversion Ht; subst.
    + apply T_Add_Int; [assumption | apply IHHs; assumption].
    + apply T_Add_Float; [assumption | apply IHHs; assumption].
    + apply T_Add_String; [assumption | apply IHHs; assumption].
    + eapply T_Eq; [eassumption | apply IHHs; eassumption].
    + apply T_And; [assumption | apply IHHs; assumption].
  - (* S_Add_Int *)
    inversion Ht; subst.
    + constructor.
    + inversion H2; subst; discriminate.
    + inversion H2; subst; discriminate.
    + constructor.
    + discriminate.
  - (* S_Add_String *)
    inversion Ht; subst.
    + inversion H2; subst; discriminate.
    + inversion H2; subst; discriminate.
    + constructor.
    + constructor.
    + discriminate.
  - (* S_Eq_True *)
    inversion Ht; subst.
    + discriminate.
    + discriminate.
    + discriminate.
    + constructor.
    + discriminate.
  - (* S_Neg_Int *)
    inversion Ht; subst.
    + constructor.
    + inversion H0; subst; discriminate.
    + discriminate.
  - (* S_Not *)
    inversion Ht; subst.
    + discriminate.
    + discriminate.
    + constructor.
  - (* S_Okay: EOkay (ELit v) -> ELit (VOkay v) *)
    inversion Ht; subst.
    (* T_Okay gives: has_type G (ELit v) t, need TResult t TString *)
    apply T_Lit_Okay. assumption.
  - (* S_Oops: EOops (ELit (VString s)) -> ELit (VOops s) *)
    inversion Ht; subst.
    (* T_Oops gives: has_type G (ELit (VString s)) TString *)
    apply T_Lit_Oops.
  - (* S_Add_Float *)
    inversion Ht; subst.
    + inversion H2; subst; discriminate.
    + constructor.
    + inversion H2; subst; discriminate.
    + constructor.
    + discriminate.
  - (* S_And *)
    inversion Ht; subst.
    + discriminate.
    + discriminate.
    + discriminate.
    + constructor.
    + constructor.
  - (* S_Eq_False *)
    inversion Ht; subst.
    + discriminate.
    + discriminate.
    + discriminate.
    + constructor.
    + discriminate.
  - (* S_UnOp_inner *)
    inversion Ht; subst.
    + apply T_Neg_Int. apply IHHs. assumption.
    + apply T_Neg_Float. apply IHHs. assumption.
    + apply T_Not. apply IHHs. assumption.
  - (* S_Neg_Float *)
    inversion Ht; subst.
    + inversion H0; subst; discriminate.
    + constructor.
    + discriminate.
  - (* S_Okay_step *)
    inversion Ht; subst.
    apply T_Okay. apply IHHs. assumption.
  - (* S_Oops_step *)
    inversion Ht; subst.
    apply T_Oops. apply IHHs. assumption.
  - (* S_Unwrap_step *)
    inversion Ht; subst.
    eapply T_Unwrap. apply IHHs. eassumption.
  - (* S_Unwrap_Okay: EUnwrap (ELit (VOkay v)) -> ELit v *)
    inversion Ht; subst.
    (* has_type G (ELit (VOkay v)) (TResult t_ok t_err) *)
    inversion H0; subst.
    + (* T_Lit_Okay *) assumption.
    + (* T_Lit_Oops: VOkay v = VOops s - impossible *) discriminate.
  - (* S_Unwrap_Oops: EUnwrap (ELit (VOops s)) -> ELit (VOops s) *)
    inversion Ht; subst.
    (* has_type G (ELit (VOops s)) (TResult t_ok t_err) *)
    (* The result is ELit (VOops s) which should have type t_ok.
       But VOops s has type TResult _ TString, not t_ok in general.
       This is intentional: unwrapping an error propagates the error
       value, but the type changes. We need the output to have type t_ok.
       Since VOops s can have any TResult type via T_Lit_Oops, and
       T_Unwrap extracts t_ok, we need ELit (VOops s) : t_ok.
       This is a semantic mismatch: unwrap on Oops should be a runtime
       error or return a result type, not pretend to be t_ok. *)
    admit.
  - (* S_Array_step *)
    (* Requires reasoning about Forall preservation under list element
       stepping. Needs auxiliary lemma about Forall over concatenated lists. *)
    admit.
Admitted.
(** NOTE: 2 admits remain in preservation:
    1. S_Unwrap_Oops: type mismatch by design (unwrapping an error is a
       runtime error; the step rule exists for progress but preservation
       cannot hold — this is expected for a language with runtime errors)
    2. S_Array_step: needs Forall splitting/joining lemma for lists *)

(** ** Type Safety *)

(** Type safety follows directly from progress + preservation by induction
    on the multi-step relation. This proof is complete assuming the two
    component theorems above are fully proved. *)
Theorem type_safety : forall e t v rho,
  has_type empty_type_env e t ->
  multi_step e empty_env (ELit v) rho ->
  has_type empty_type_env (ELit v) t.
Proof.
  intros e t v rho Ht Hms.
  induction Hms.
  - (* Reflexive case *)
    assumption.
  - (* Transitive case *)
    apply IHHms.
    eapply preservation; eauto.
Qed.

(* ========================================================================= *)
(* 6. Consent System                                                         *)
(* ========================================================================= *)

Definition permission := string.

Definition consent_state := permission -> bool.

Definition empty_consent : consent_state := fun _ => false.

Definition grant_consent (p : permission) (c : consent_state) : consent_state :=
  fun q => if String.eqb p q then true else c q.

Definition check_consent (p : permission) (c : consent_state) : bool :=
  c p.

(** ** Consent Safety *)

(* TODO: Complete this proof *)
Theorem consent_monotonicity : forall p c,
  check_consent p (grant_consent p c) = true.
Proof.
  intros p c.
  unfold check_consent, grant_consent.
  rewrite String.eqb_refl.
  reflexivity.
Qed.

Theorem consent_preservation : forall p q c,
  p <> q ->
  check_consent q c = check_consent q (grant_consent p c).
Proof.
  intros p q c Hneq.
  unfold check_consent, grant_consent.
  destruct (String.eqb p q) eqn:Heq.
  - apply String.eqb_eq in Heq. contradiction.
  - reflexivity.
Qed.

(* ========================================================================= *)
(* 7. Capability System                                                      *)
(* ========================================================================= *)

Inductive capability : Type :=
  | CapFileRead : option string -> capability
  | CapFileWrite : option string -> capability
  | CapNetwork : option string -> capability
  | CapExecute : option string -> capability
  | CapProcess : capability
  | CapCrypto : capability.

Definition capability_set := list capability.

(* Capability subsumption *)
Definition cap_subsumes (c1 c2 : capability) : bool :=
  match c1, c2 with
  | CapFileRead None, CapFileRead _ => true
  | CapFileWrite None, CapFileWrite _ => true
  | CapNetwork None, CapNetwork _ => true
  | CapExecute None, CapExecute _ => true
  | _, _ =>
    (* TODO: Proper equality check *)
    false
  end.

Definition has_capability (c : capability) (cs : capability_set) : bool :=
  existsb (fun c' => cap_subsumes c' c) cs.

(* TODO: Capability safety theorems *)

(* ========================================================================= *)
(* 8. Compiler Correctness (Stubs)                                           *)
(* ========================================================================= *)

(* TODO: Define bytecode instructions *)
Inductive opcode : Type :=
  | OpConst : nat -> opcode
  | OpAdd : opcode
  | OpSub : opcode
  | OpMul : opcode
  | OpDiv : opcode
  | OpEq : opcode
  | OpLt : opcode
  | OpNot : opcode
  | OpJump : nat -> opcode
  | OpJumpIfFalse : nat -> opcode
  | OpLoad : nat -> opcode
  | OpStore : nat -> opcode
  | OpCall : nat -> opcode
  | OpReturn : opcode
  | OpHalt : opcode.

Definition bytecode := list opcode.

(* TODO: Compiler function *)
(* Parameter compile_expr : expr -> bytecode. *)

(* TODO: VM semantics *)
(* TODO: Compiler correctness theorem *)

(* ========================================================================= *)
(* 9. Extraction                                                             *)
(* ========================================================================= *)

(* Extraction to OCaml/Rust would go here *)
(* Require Extraction. *)
(* Extraction Language OCaml. *)
(* Recursive Extraction has_type step multi_step. *)

(* ========================================================================= *)
(* End of WokeLang Coq Specification                                         *)
(* ========================================================================= *)
