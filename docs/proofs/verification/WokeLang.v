(* WokeLang Formal Verification in Coq *)
(* SPDX-License-Identifier: MPL-2.0 *)

(* ========================================================================= *)
(* This file contains Coq definitions and theorems for WokeLang's type       *)
(* system, including progress and preservation (type safety).                 *)
(*                                                                           *)
(* Key design decision: VOops (error) values inhabit any type via            *)
(* T_Oops_Any. This models runtime errors/exceptions that propagate          *)
(* through any context, which is standard in PL formalization for            *)
(* languages with unchecked error propagation.                               *)
(* ========================================================================= *)

Require Import Coq.Strings.String.
Require Import Coq.Lists.List.
Require Import Coq.ZArith.ZArith.
Require Import Coq.Reals.Reals.
Require Import Coq.Arith.Wf_nat.
Require Import Lia.
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

(** Decidable equality on values. Constructive proof:
    - VInt/VString/VBool/VOops: standard stdlib decidability.
    - VFloat (R): Req_EM_T from Coq.Reals.Reals (uses total_order_T,
      which relies on the classical axioms already imported for R).
      No new axioms are introduced beyond those implicit in Coq.Reals.
    - VArray: list_eq_dec with the recursive IH from decide equality.
    - VOkay: handled recursively by decide equality. *)
Theorem value_eq_dec : forall (v1 v2 : value), {v1 = v2} + {v1 <> v2}.
Proof.
  fix IH 1.
  decide equality.
  - apply Z.eq_dec.
  - apply Req_EM_T.
  - apply String.string_dec.
  - apply Bool.bool_dec.
  - apply list_eq_dec. exact IH.
  - apply String.string_dec.
Qed.

(* ========================================================================= *)
(* 3. Type Checking                                                          *)
(* ========================================================================= *)

(** ** Type Checking Judgment *)

(** T_Oops_Any is the key addition: error values (VOops) inhabit ANY type.
    This is standard in type systems for languages with runtime errors or
    exceptions. An uncaught error can appear wherever any value is expected,
    just as a thrown exception in Java/Rust/.NET can propagate through any
    typed context. This rule is essential for preservation of the
    S_Unwrap_Oops step, and enables error propagation through binary and
    unary operators. *)

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
  | T_Or : forall G e1 e2,
      has_type G e1 TBool ->
      has_type G e2 TBool ->
      has_type G (EBinOp BOr e1 e2) TBool
  | T_Sub_Int : forall G e1 e2,
      has_type G e1 TInt ->
      has_type G e2 TInt ->
      has_type G (EBinOp BSub e1 e2) TInt
  | T_Mul_Int : forall G e1 e2,
      has_type G e1 TInt ->
      has_type G e2 TInt ->
      has_type G (EBinOp BMul e1 e2) TInt
  | T_Div_Int : forall G e1 e2,
      has_type G e1 TInt ->
      has_type G e2 TInt ->
      has_type G (EBinOp BDiv e1 e2) TInt
  | T_Mod_Int : forall G e1 e2,
      has_type G e1 TInt ->
      has_type G e2 TInt ->
      has_type G (EBinOp BMod e1 e2) TInt
  | T_Lt_Int : forall G e1 e2,
      has_type G e1 TInt ->
      has_type G e2 TInt ->
      has_type G (EBinOp BLt e1 e2) TBool
  | T_Gt_Int : forall G e1 e2,
      has_type G e1 TInt ->
      has_type G e2 TInt ->
      has_type G (EBinOp BGt e1 e2) TBool
  | T_Le_Int : forall G e1 e2,
      has_type G e1 TInt ->
      has_type G e2 TInt ->
      has_type G (EBinOp BLe e1 e2) TBool
  | T_Ge_Int : forall G e1 e2,
      has_type G e1 TInt ->
      has_type G e2 TInt ->
      has_type G (EBinOp BGe e1 e2) TBool
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
      has_type G (ELit (VOops s)) (TResult t TString)
  | T_Oops_Any : forall G s t,
      has_type G (ELit (VOops s)) t
  | T_Lit_Array : forall G vs t,
      Forall (fun v => has_type G (ELit v) t) vs ->
      has_type G (ELit (VArray vs)) (TArray t).

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

(** The step relation includes error propagation rules (S_BinOp_Error_Left,
    S_BinOp_Error_Right, S_UnOp_Error) which model how runtime errors
    (VOops values) propagate through expressions, analogous to exception
    propagation in languages like Java or Rust's panic unwinding. *)

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
  | S_BinOp_Right_Array : forall op vs e2 e2' rho rho',
      step e2 rho e2' rho' ->
      step (EBinOp op (EArray (map ELit vs)) e2) rho
           (EBinOp op (EArray (map ELit vs)) e2') rho'
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
  | S_Or : forall b1 b2 rho,
      step (EBinOp BOr (ELit (VBool b1)) (ELit (VBool b2))) rho
           (ELit (VBool (orb b1 b2))) rho
  | S_Sub_Int : forall n1 n2 rho,
      step (EBinOp BSub (ELit (VInt n1)) (ELit (VInt n2))) rho
           (ELit (VInt (n1 - n2)%Z)) rho
  | S_Mul_Int : forall n1 n2 rho,
      step (EBinOp BMul (ELit (VInt n1)) (ELit (VInt n2))) rho
           (ELit (VInt (n1 * n2)%Z)) rho
  | S_Div_Int : forall n1 n2 rho,
      n2 <> 0%Z ->
      step (EBinOp BDiv (ELit (VInt n1)) (ELit (VInt n2))) rho
           (ELit (VInt (n1 / n2)%Z)) rho
  | S_Div_Zero : forall n1 rho,
      step (EBinOp BDiv (ELit (VInt n1)) (ELit (VInt 0%Z))) rho
           (ELit (VOops "division by zero"%string)) rho
  | S_Mod_Int : forall n1 n2 rho,
      n2 <> 0%Z ->
      step (EBinOp BMod (ELit (VInt n1)) (ELit (VInt n2))) rho
           (ELit (VInt (n1 mod n2)%Z)) rho
  | S_Mod_Zero : forall n1 rho,
      step (EBinOp BMod (ELit (VInt n1)) (ELit (VInt 0%Z))) rho
           (ELit (VOops "modulo by zero"%string)) rho
  | S_Lt : forall n1 n2 rho,
      step (EBinOp BLt (ELit (VInt n1)) (ELit (VInt n2))) rho
           (ELit (VBool (Z.ltb n1 n2))) rho
  | S_Gt : forall n1 n2 rho,
      step (EBinOp BGt (ELit (VInt n1)) (ELit (VInt n2))) rho
           (ELit (VBool (Z.gtb n1 n2))) rho
  | S_Le : forall n1 n2 rho,
      step (EBinOp BLe (ELit (VInt n1)) (ELit (VInt n2))) rho
           (ELit (VBool (Z.leb n1 n2))) rho
  | S_Ge : forall n1 n2 rho,
      step (EBinOp BGe (ELit (VInt n1)) (ELit (VInt n2))) rho
           (ELit (VBool (Z.geb n1 n2))) rho
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
           (EArray (map ELit vs ++ e' :: es)) rho'
  (* Equality between array values *)
  | S_Eq_True_Array : forall vs rho,
      step (EBinOp BEq (EArray (map ELit vs)) (EArray (map ELit vs))) rho
           (ELit (VBool true)) rho
  | S_Eq_False_Array : forall vs1 vs2 rho,
      vs1 <> vs2 ->
      step (EBinOp BEq (EArray (map ELit vs1)) (EArray (map ELit vs2))) rho
           (ELit (VBool false)) rho
  (* Equality between structurally different value forms: always false *)
  | S_Eq_False_LitArray : forall v vs rho,
      step (EBinOp BEq (ELit v) (EArray (map ELit vs))) rho
           (ELit (VBool false)) rho
  | S_Eq_False_ArrayLit : forall vs v rho,
      step (EBinOp BEq (EArray (map ELit vs)) (ELit v)) rho
           (ELit (VBool false)) rho
  (* Error propagation: VOops values propagate through binary operators *)
  | S_BinOp_Error_Left : forall op s e2 rho,
      step (EBinOp op (ELit (VOops s)) e2) rho (ELit (VOops s)) rho
  | S_BinOp_Error_Right : forall op v1 s rho,
      step (EBinOp op (ELit v1) (ELit (VOops s))) rho (ELit (VOops s)) rho
  (* Error propagation: array value on one side, error on the other *)
  | S_BinOp_Error_Left_Array : forall op s vs rho,
      step (EBinOp op (ELit (VOops s)) (EArray (map ELit vs))) rho (ELit (VOops s)) rho
  | S_BinOp_Error_Right_Array : forall op vs s rho,
      step (EBinOp op (EArray (map ELit vs)) (ELit (VOops s))) rho (ELit (VOops s)) rho
  (* Error propagation: VOops values propagate through unary operators *)
  | S_UnOp_Error : forall op s rho,
      step (EUnOp op (ELit (VOops s))) rho (ELit (VOops s)) rho
  (* Error propagation: VOops values propagate through EOkay *)
  | S_Okay_Error : forall s rho,
      step (EOkay (ELit (VOops s))) rho (ELit (VOops s)) rho
  (* Error propagation: VOops values propagate through EOops *)
  | S_Oops_Error : forall s rho,
      step (EOops (ELit (VOops s))) rho (ELit (VOops s)) rho
  (* Array normalization: fully evaluated EArray reduces to ELit (VArray) *)
  | S_Array_val : forall vs rho,
      step (EArray (map ELit vs)) rho (ELit (VArray vs)) rho.

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

(** With T_Oops_Any, error values (VOops) can inhabit any type. Therefore,
    canonical forms lemmas return a disjunction: either the value has the
    expected shape OR it is an error value. This is standard for languages
    with runtime errors. *)

Lemma canonical_forms_int : forall v,
  has_type empty_type_env (ELit v) TInt ->
  (exists n, v = VInt n) \/ (exists s, v = VOops s).
Proof.
  intros v H.
  inversion H; subst;
    try (left; eexists; reflexivity);
    try (match goal with
         | [ H0 : TResult _ _ = TInt |- _ ] => discriminate H0
         end);
    try (right; eexists; reflexivity).
Qed.

Lemma canonical_forms_bool : forall v,
  has_type empty_type_env (ELit v) TBool ->
  (exists b, v = VBool b) \/ (exists s, v = VOops s).
Proof.
  intros v H.
  inversion H; subst;
    try (left; eexists; reflexivity);
    try (match goal with
         | [ H0 : TResult _ _ = TBool |- _ ] => discriminate H0
         end);
    try (right; eexists; reflexivity).
Qed.

Lemma canonical_forms_string : forall v,
  has_type empty_type_env (ELit v) TString ->
  (exists s, v = VString s) \/ (exists s, v = VOops s).
Proof.
  intros v H.
  inversion H; subst;
    try (left; eexists; reflexivity);
    try (match goal with
         | [ H0 : TResult _ _ = TString |- _ ] => discriminate H0
         end);
    try (right; eexists; reflexivity).
Qed.

Lemma canonical_forms_float : forall v,
  has_type empty_type_env (ELit v) TFloat ->
  (exists r, v = VFloat r) \/ (exists s, v = VOops s).
Proof.
  intros v H.
  inversion H; subst;
    try (left; eexists; reflexivity);
    try (match goal with
         | [ H0 : TResult _ _ = TFloat |- _ ] => discriminate H0
         end);
    try (right; eexists; reflexivity).
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
  (exists n, e = ELit (VInt n)) \/ (exists s, e = ELit (VOops s)).
Proof.
  intros e Ht Hv.
  destruct (value_is_lit_or_array e Hv) as [[v Heq] | [vs Heq]].
  - subst. apply canonical_forms_int in Ht.
    destruct Ht as [[n Heq] | [s Heq]]; subst;
      [left; exists n | right; exists s]; reflexivity.
  - subst. inversion Ht; subst; try discriminate.
Qed.

Lemma canonical_forms_float_expr : forall e,
  has_type empty_type_env e TFloat ->
  is_value e ->
  (exists r, e = ELit (VFloat r)) \/ (exists s, e = ELit (VOops s)).
Proof.
  intros e Ht Hv.
  destruct (value_is_lit_or_array e Hv) as [[v Heq] | [vs Heq]].
  - subst. apply canonical_forms_float in Ht.
    destruct Ht as [[r Heq] | [s Heq]]; subst;
      [left; exists r | right; exists s]; reflexivity.
  - subst. inversion Ht; subst; try discriminate.
Qed.

Lemma canonical_forms_bool_expr : forall e,
  has_type empty_type_env e TBool ->
  is_value e ->
  (exists b, e = ELit (VBool b)) \/ (exists s, e = ELit (VOops s)).
Proof.
  intros e Ht Hv.
  destruct (value_is_lit_or_array e Hv) as [[v Heq] | [vs Heq]].
  - subst. apply canonical_forms_bool in Ht.
    destruct Ht as [[b Heq] | [s Heq]]; subst;
      [left; exists b | right; exists s]; reflexivity.
  - subst. inversion Ht; subst; try discriminate.
Qed.

Lemma canonical_forms_string_expr : forall e,
  has_type empty_type_env e TString ->
  is_value e ->
  (exists s, e = ELit (VString s)) \/ (exists s, e = ELit (VOops s)).
Proof.
  intros e Ht Hv.
  destruct (value_is_lit_or_array e Hv) as [[v Heq] | [vs Heq]].
  - subst. apply canonical_forms_string in Ht.
    destruct Ht as [[s Heq] | [s Heq]]; subst;
      [left; exists s | right; exists s]; reflexivity.
  - subst. inversion Ht; subst; try discriminate.
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
    + (* T_Oops_Any *) right. exists s. reflexivity.
  - subst. inversion Ht; subst; try discriminate.
Qed.

(** ** Expression Size (for well-founded induction) *)

(** Size measure on expressions, used for well-founded induction in
    the progress theorem to get an IH for array elements. *)

Fixpoint expr_size (e : expr) : nat :=
  match e with
  | ELit _ => 0
  | EVar _ => 0
  | EBinOp _ e1 e2 => S (expr_size e1 + expr_size e2)
  | EUnOp _ e1 => S (expr_size e1)
  | ECall _ es => S (fold_right (fun e acc => expr_size e + acc) 0 es)
  | EArray es => S (fold_right (fun e acc => expr_size e + acc) 0 es)
  | EOkay e1 => S (expr_size e1)
  | EOops e1 => S (expr_size e1)
  | EUnwrap e1 => S (expr_size e1)
  end.

Lemma in_list_size_fold : forall x es,
  In x es -> expr_size x < S (fold_right (fun e acc => expr_size e + acc) 0 es).
Proof.
  induction es; intros Hin.
  - destruct Hin.
  - destruct Hin as [Heq | Hin].
    + subst. simpl. lia.
    + specialize (IHes Hin). simpl. lia.
Qed.

(** ** Auxiliary Lemma: Array Element Progress *)

(** Given a list of expressions where each is either a value or can step,
    either all are literal values, or there exists a decomposition into
    a prefix of literal values, a non-value that can step, and a suffix.
    This is the key lemma for the T_Array progress case. *)

Lemma array_elements_progress : forall es,
  Forall (fun e => is_value e \/
                   exists e' rho', step e empty_env e' rho') es ->
  (exists vs, es = map ELit vs) \/
  (exists vs e e' es' rho',
    es = map ELit vs ++ e :: es' /\
    step e empty_env e' rho').
Proof.
  intros es Hprog.
  induction Hprog as [| e rest He Hrest IHrest].
  - (* nil: all values trivially *)
    left. exists []. reflexivity.
  - (* cons *)
    destruct He as [Hval | [e' [rho' Hstep]]].
    + (* e is a value *)
      destruct (value_is_lit_or_array e Hval) as [[v Heq] | [vs' Heq]].
      * (* e = ELit v *)
        subst.
        destruct IHrest as [[vs Hvs] | [vs [e0 [e0' [es' [rho0 [Hdecomp Hstep]]]]]]].
        -- (* rest are all values too *)
           left. exists (v :: vs). simpl. f_equal. assumption.
        -- (* rest has a steppable element *)
           right. exists (v :: vs), e0, e0', es', rho0.
           split; [| assumption].
           simpl. f_equal. assumption.
      * (* e = EArray (map ELit vs') -- array value at head, not ELit.
           This value can step to ELit (VArray vs') via S_Array_val. *)
        subst.
        right. exists [], (EArray (map ELit vs')), (ELit (VArray vs')), rest, empty_env.
        split.
        -- simpl. reflexivity.
        -- apply S_Array_val.
    + (* e can step *)
      right. exists [], e, e', rest, rho'.
      split; [| assumption].
      simpl. reflexivity.
Qed.

(** ** Array Progress Lemma *)

(** Standalone proof of the T_Array progress case. Given a well-typed array
    in the empty environment where each element satisfies progress, the
    array is either a value or can step. *)

Lemma progress_array : forall es t,
  Forall (fun e => has_type empty_type_env e t) es ->
  Forall (fun e => is_value e \/
                   exists e' rho', step e empty_env e' rho') es ->
  is_value (EArray es) \/ exists e' rho', step (EArray es) empty_env e' rho'.
Proof.
  intros es t Hty Hprog.
  destruct (array_elements_progress es Hprog) as
    [[vs Hvs] | [vs [e0 [e0' [es' [rho' [Hdecomp Hstep]]]]]]].
  - (* All elements are literals: EArray is a value *)
    left. subst. apply V_Array.
    clear Hty Hprog.
    induction vs; constructor; [constructor | apply IHvs].
  - (* Some element can step: use S_Array_step *)
    right. subst.
    exists (EArray (map ELit vs ++ e0' :: es')), rho'.
    apply S_Array_step. assumption.
Qed.

(** ** Helper: Progress for array elements given a size-based IH *)

Lemma forall_progress_from_ih : forall es t,
  Forall (fun e => has_type empty_type_env e t) es ->
  (forall y, In y es -> forall t', has_type empty_type_env y t' ->
     is_value y \/ exists e' rho', step y empty_env e' rho') ->
  Forall (fun e0 => is_value e0 \/ exists e' rho', step e0 empty_env e' rho') es.
Proof.
  intros es t Hf Hih.
  induction Hf as [| ei eis Hei Heis IHeis].
  - constructor.
  - constructor.
    + eapply Hih. left. reflexivity. eassumption.
    + apply IHeis. intros y Hin t' Hty'. eapply Hih.
      * right. exact Hin.
      * exact Hty'.
Qed.

(** ** Progress Theorem *)

(** Progress: every well-typed closed expression is either a value or can
    take a step. The proof uses well-founded induction on expression size
    to provide an IH for array elements (which standard structural induction
    on the typing derivation does not provide). The T_Array case uses
    array_elements_progress + S_Array_val for evaluated arrays.
    The T_Oops_Any case is immediate (ELit is a value). *)

Theorem progress : forall e t,
  has_type empty_type_env e t ->
  is_value e \/ exists e' rho', step e empty_env e' rho'.
Proof.
  intro e. induction e as [e IH] using (well_founded_ind (well_founded_ltof _ expr_size)).
  intros t Ht.
  inversion Ht; subst.
  - (* T_Int *) left. constructor.
  - (* T_Float *) left. constructor.
  - (* T_String *) left. constructor.
  - (* T_Bool *) left. constructor.
  - (* T_Unit *) left. constructor.
  - (* T_Var *)
    unfold empty_type_env in *.
    match goal with
    | [ H : None = Some _ |- _ ] => discriminate H
    end.
  - (* T_Add_Int *)
    right.
    assert (IH1 : is_value e1 \/ exists e' rho', step e1 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    assert (IH2 : is_value e2 \/ exists e' rho', step e2 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    destruct IH1 as [Hv1 | [e1' [rho1' Hs1]]].
    + destruct IH2 as [Hv2 | [e2' [rho2' Hs2]]].
      * match goal with
        | [ H1 : has_type _ e1 TInt, H2 : has_type _ e2 TInt |- _ ] =>
          destruct (canonical_forms_int_expr _ H1 Hv1) as [[n1 Heq1] | [s1 Heq1]];
          destruct (canonical_forms_int_expr _ H2 Hv2) as [[n2 Heq2] | [s2 Heq2]];
          subst
        end.
        -- exists (ELit (VInt (n1 + n2)%Z)), empty_env. apply S_Add_Int.
        -- exists (ELit (VOops s2)), empty_env. apply S_BinOp_Error_Right.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
      * match goal with
        | [ H1 : has_type _ e1 TInt |- _ ] =>
          destruct (canonical_forms_int_expr _ H1 Hv1) as [[n1 Heq1] | [s1 Heq1]]; subst
        end.
        -- exists (EBinOp BAdd (ELit (VInt n1)) e2'), rho2'.
           apply S_BinOp_Right; [constructor | assumption].
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
    + exists (EBinOp BAdd e1' e2), rho1'. apply S_BinOp_Left. assumption.
  - (* T_Add_Float *)
    right.
    assert (IH1 : is_value e1 \/ exists e' rho', step e1 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    assert (IH2 : is_value e2 \/ exists e' rho', step e2 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    destruct IH1 as [Hv1 | [e1' [rho1' Hs1]]].
    + destruct IH2 as [Hv2 | [e2' [rho2' Hs2]]].
      * match goal with
        | [ H1 : has_type _ e1 TFloat, H2 : has_type _ e2 TFloat |- _ ] =>
          destruct (canonical_forms_float_expr _ H1 Hv1) as [[r1 Heq1] | [s1 Heq1]];
          destruct (canonical_forms_float_expr _ H2 Hv2) as [[r2 Heq2] | [s2 Heq2]];
          subst
        end.
        -- exists (ELit (VFloat (r1 + r2)%R)), empty_env. apply S_Add_Float.
        -- exists (ELit (VOops s2)), empty_env. apply S_BinOp_Error_Right.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
      * match goal with
        | [ H1 : has_type _ e1 TFloat |- _ ] =>
          destruct (canonical_forms_float_expr _ H1 Hv1) as [[r1 Heq1] | [s1 Heq1]]; subst
        end.
        -- exists (EBinOp BAdd (ELit (VFloat r1)) e2'), rho2'.
           apply S_BinOp_Right; [constructor | assumption].
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
    + exists (EBinOp BAdd e1' e2), rho1'. apply S_BinOp_Left. assumption.
  - (* T_Add_String *)
    right.
    assert (IH1 : is_value e1 \/ exists e' rho', step e1 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    assert (IH2 : is_value e2 \/ exists e' rho', step e2 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    destruct IH1 as [Hv1 | [e1' [rho1' Hs1]]].
    + destruct IH2 as [Hv2 | [e2' [rho2' Hs2]]].
      * match goal with
        | [ H1 : has_type _ e1 TString, H2 : has_type _ e2 TString |- _ ] =>
          destruct (canonical_forms_string_expr _ H1 Hv1) as [[s1 Heq1] | [s1 Heq1]];
          destruct (canonical_forms_string_expr _ H2 Hv2) as [[s2 Heq2] | [s2 Heq2]];
          subst
        end.
        -- exists (ELit (VString (s1 ++ s2))), empty_env. apply S_Add_String.
        -- exists (ELit (VOops s2)), empty_env. apply S_BinOp_Error_Right.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
      * match goal with
        | [ H1 : has_type _ e1 TString |- _ ] =>
          destruct (canonical_forms_string_expr _ H1 Hv1) as [[s1 Heq1] | [s1 Heq1]]; subst
        end.
        -- exists (EBinOp BAdd (ELit (VString s1)) e2'), rho2'.
           apply S_BinOp_Right; [constructor | assumption].
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
    + exists (EBinOp BAdd e1' e2), rho1'. apply S_BinOp_Left. assumption.
  - (* T_Eq *)
    right.
    assert (IH1 : is_value e1 \/ exists e' rho', step e1 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    assert (IH2 : is_value e2 \/ exists e' rho', step e2 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    destruct IH1 as [Hv1 | [e1' [rho1' Hs1]]].
    + destruct IH2 as [Hv2 | [e2' [rho2' Hs2]]].
      * (* Both values *)
        destruct (value_is_lit_or_array e1 Hv1) as [[v1 Heq1] | [vs1 Heq1]];
        destruct (value_is_lit_or_array e2 Hv2) as [[v2 Heq2] | [vs2 Heq2]]; subst.
        -- (* Both ELit *)
           destruct v1 eqn:V1.
           ++ destruct (value_eq_dec (VInt z) v2) as [Heq | Hneq].
              ** subst. exists (ELit (VBool true)), empty_env. apply S_Eq_True.
              ** exists (ELit (VBool false)), empty_env. apply S_Eq_False. assumption.
           ++ destruct (value_eq_dec (VFloat r) v2) as [Heq | Hneq].
              ** subst. exists (ELit (VBool true)), empty_env. apply S_Eq_True.
              ** exists (ELit (VBool false)), empty_env. apply S_Eq_False. assumption.
           ++ destruct (value_eq_dec (VString s) v2) as [Heq | Hneq].
              ** subst. exists (ELit (VBool true)), empty_env. apply S_Eq_True.
              ** exists (ELit (VBool false)), empty_env. apply S_Eq_False. assumption.
           ++ destruct (value_eq_dec (VBool b) v2) as [Heq | Hneq].
              ** subst. exists (ELit (VBool true)), empty_env. apply S_Eq_True.
              ** exists (ELit (VBool false)), empty_env. apply S_Eq_False. assumption.
           ++ destruct (value_eq_dec VUnit v2) as [Heq | Hneq].
              ** subst. exists (ELit (VBool true)), empty_env. apply S_Eq_True.
              ** exists (ELit (VBool false)), empty_env. apply S_Eq_False. assumption.
           ++ destruct (value_eq_dec (VArray l) v2) as [Heq | Hneq].
              ** subst. exists (ELit (VBool true)), empty_env. apply S_Eq_True.
              ** exists (ELit (VBool false)), empty_env. apply S_Eq_False. assumption.
           ++ destruct (value_eq_dec (VOkay v) v2) as [Heq | Hneq].
              ** subst. exists (ELit (VBool true)), empty_env. apply S_Eq_True.
              ** exists (ELit (VBool false)), empty_env. apply S_Eq_False. assumption.
           ++ (* VOops: error propagation *)
              exists (ELit (VOops s)), empty_env. apply S_BinOp_Error_Left.
        -- (* e1 = ELit v1, e2 = EArray: structurally different value forms *)
           destruct v1 as [z1|r1|str1|b1| |l1|ok1|s1].
           8: { exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left. }
           all: (exists (ELit (VBool false)), empty_env; apply S_Eq_False_LitArray).
        -- (* e1 = EArray, e2 = ELit v2: structurally different value forms *)
           destruct v2 as [z2|r2|str2|b2| |l2|ok2|s2].
           8: { exists (ELit (VOops s2)), empty_env. apply S_BinOp_Error_Right_Array. }
           all: (exists (ELit (VBool false)), empty_env; apply S_Eq_False_ArrayLit).
        -- (* Both EArray *)
           destruct (value_eq_dec (VArray vs1) (VArray vs2)) as [Heq | Hneq].
           ** injection Heq; intro; subst.
              exists (ELit (VBool true)), empty_env. apply S_Eq_True_Array.
           ** exists (ELit (VBool false)), empty_env. apply S_Eq_False_Array.
              intro Habs. apply Hneq. f_equal. assumption.
      * (* e1 value, e2 steps *)
        destruct (value_is_lit_or_array e1 Hv1) as [[v1 Heq1] | [vs1 Heq1]]; subst.
        -- exists (EBinOp BEq (ELit v1) e2'), rho2'.
           apply S_BinOp_Right; [constructor | assumption].
        -- exists (EBinOp BEq (EArray (map ELit vs1)) e2'), rho2'.
           apply S_BinOp_Right_Array. assumption.
    + exists (EBinOp BEq e1' e2), rho1'. apply S_BinOp_Left. assumption.
  - (* T_And *)
    right.
    assert (IH1 : is_value e1 \/ exists e' rho', step e1 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    assert (IH2 : is_value e2 \/ exists e' rho', step e2 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    destruct IH1 as [Hv1 | [e1' [rho1' Hs1]]].
    + destruct IH2 as [Hv2 | [e2' [rho2' Hs2]]].
      * match goal with
        | [ H1 : has_type _ e1 TBool, H2 : has_type _ e2 TBool |- _ ] =>
          destruct (canonical_forms_bool_expr _ H1 Hv1) as [[b1 Heq1] | [s1 Heq1]];
          destruct (canonical_forms_bool_expr _ H2 Hv2) as [[b2 Heq2] | [s2 Heq2]];
          subst
        end.
        -- exists (ELit (VBool (andb b1 b2))), empty_env. apply S_And.
        -- exists (ELit (VOops s2)), empty_env. apply S_BinOp_Error_Right.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
      * match goal with
        | [ H1 : has_type _ e1 TBool |- _ ] =>
          destruct (canonical_forms_bool_expr _ H1 Hv1) as [[b1 Heq1] | [s1 Heq1]]; subst
        end.
        -- exists (EBinOp BAnd (ELit (VBool b1)) e2'), rho2'.
           apply S_BinOp_Right; [constructor | assumption].
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
    + exists (EBinOp BAnd e1' e2), rho1'. apply S_BinOp_Left. assumption.
  - (* T_Or *)
    right.
    assert (IH1 : is_value e1 \/ exists e' rho', step e1 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    assert (IH2 : is_value e2 \/ exists e' rho', step e2 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    destruct IH1 as [Hv1 | [e1' [rho1' Hs1]]].
    + destruct IH2 as [Hv2 | [e2' [rho2' Hs2]]].
      * match goal with
        | [ H1 : has_type _ e1 TBool, H2 : has_type _ e2 TBool |- _ ] =>
          destruct (canonical_forms_bool_expr _ H1 Hv1) as [[b1 Heq1] | [s1 Heq1]];
          destruct (canonical_forms_bool_expr _ H2 Hv2) as [[b2 Heq2] | [s2 Heq2]];
          subst
        end.
        -- exists (ELit (VBool (orb b1 b2))), empty_env. apply S_Or.
        -- exists (ELit (VOops s2)), empty_env. apply S_BinOp_Error_Right.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
      * match goal with
        | [ H1 : has_type _ e1 TBool |- _ ] =>
          destruct (canonical_forms_bool_expr _ H1 Hv1) as [[b1 Heq1] | [s1 Heq1]]; subst
        end.
        -- exists (EBinOp BOr (ELit (VBool b1)) e2'), rho2'.
           apply S_BinOp_Right; [constructor | assumption].
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
    + exists (EBinOp BOr e1' e2), rho1'. apply S_BinOp_Left. assumption.
  - (* T_Sub_Int *)
    right.
    assert (IH1 : is_value e1 \/ exists e' rho', step e1 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    assert (IH2 : is_value e2 \/ exists e' rho', step e2 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    destruct IH1 as [Hv1 | [e1' [rho1' Hs1]]].
    + destruct IH2 as [Hv2 | [e2' [rho2' Hs2]]].
      * match goal with
        | [ H1 : has_type _ e1 TInt, H2 : has_type _ e2 TInt |- _ ] =>
          destruct (canonical_forms_int_expr _ H1 Hv1) as [[n1 Heq1] | [s1 Heq1]];
          destruct (canonical_forms_int_expr _ H2 Hv2) as [[n2 Heq2] | [s2 Heq2]];
          subst
        end.
        -- exists (ELit (VInt (n1 - n2)%Z)), empty_env. apply S_Sub_Int.
        -- exists (ELit (VOops s2)), empty_env. apply S_BinOp_Error_Right.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
      * match goal with
        | [ H1 : has_type _ e1 TInt |- _ ] =>
          destruct (canonical_forms_int_expr _ H1 Hv1) as [[n1 Heq1] | [s1 Heq1]]; subst
        end.
        -- exists (EBinOp BSub (ELit (VInt n1)) e2'), rho2'.
           apply S_BinOp_Right; [constructor | assumption].
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
    + exists (EBinOp BSub e1' e2), rho1'. apply S_BinOp_Left. assumption.
  - (* T_Mul_Int *)
    right.
    assert (IH1 : is_value e1 \/ exists e' rho', step e1 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    assert (IH2 : is_value e2 \/ exists e' rho', step e2 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    destruct IH1 as [Hv1 | [e1' [rho1' Hs1]]].
    + destruct IH2 as [Hv2 | [e2' [rho2' Hs2]]].
      * match goal with
        | [ H1 : has_type _ e1 TInt, H2 : has_type _ e2 TInt |- _ ] =>
          destruct (canonical_forms_int_expr _ H1 Hv1) as [[n1 Heq1] | [s1 Heq1]];
          destruct (canonical_forms_int_expr _ H2 Hv2) as [[n2 Heq2] | [s2 Heq2]];
          subst
        end.
        -- exists (ELit (VInt (n1 * n2)%Z)), empty_env. apply S_Mul_Int.
        -- exists (ELit (VOops s2)), empty_env. apply S_BinOp_Error_Right.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
      * match goal with
        | [ H1 : has_type _ e1 TInt |- _ ] =>
          destruct (canonical_forms_int_expr _ H1 Hv1) as [[n1 Heq1] | [s1 Heq1]]; subst
        end.
        -- exists (EBinOp BMul (ELit (VInt n1)) e2'), rho2'.
           apply S_BinOp_Right; [constructor | assumption].
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
    + exists (EBinOp BMul e1' e2), rho1'. apply S_BinOp_Left. assumption.
  - (* T_Div_Int *)
    right.
    assert (IH1 : is_value e1 \/ exists e' rho', step e1 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    assert (IH2 : is_value e2 \/ exists e' rho', step e2 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    destruct IH1 as [Hv1 | [e1' [rho1' Hs1]]].
    + destruct IH2 as [Hv2 | [e2' [rho2' Hs2]]].
      * match goal with
        | [ H1 : has_type _ e1 TInt, H2 : has_type _ e2 TInt |- _ ] =>
          destruct (canonical_forms_int_expr _ H1 Hv1) as [[n1 Heq1] | [s1 Heq1]];
          destruct (canonical_forms_int_expr _ H2 Hv2) as [[n2 Heq2] | [s2 Heq2]];
          subst
        end.
        -- destruct (Z.eq_dec n2 0%Z) as [Hz | Hnz].
           ++ subst. exists (ELit (VOops "division by zero"%string)), empty_env.
              apply S_Div_Zero.
           ++ exists (ELit (VInt (n1 / n2)%Z)), empty_env. apply S_Div_Int. assumption.
        -- exists (ELit (VOops s2)), empty_env. apply S_BinOp_Error_Right.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
      * match goal with
        | [ H1 : has_type _ e1 TInt |- _ ] =>
          destruct (canonical_forms_int_expr _ H1 Hv1) as [[n1 Heq1] | [s1 Heq1]]; subst
        end.
        -- exists (EBinOp BDiv (ELit (VInt n1)) e2'), rho2'.
           apply S_BinOp_Right; [constructor | assumption].
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
    + exists (EBinOp BDiv e1' e2), rho1'. apply S_BinOp_Left. assumption.
  - (* T_Mod_Int *)
    right.
    assert (IH1 : is_value e1 \/ exists e' rho', step e1 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    assert (IH2 : is_value e2 \/ exists e' rho', step e2 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    destruct IH1 as [Hv1 | [e1' [rho1' Hs1]]].
    + destruct IH2 as [Hv2 | [e2' [rho2' Hs2]]].
      * match goal with
        | [ H1 : has_type _ e1 TInt, H2 : has_type _ e2 TInt |- _ ] =>
          destruct (canonical_forms_int_expr _ H1 Hv1) as [[n1 Heq1] | [s1 Heq1]];
          destruct (canonical_forms_int_expr _ H2 Hv2) as [[n2 Heq2] | [s2 Heq2]];
          subst
        end.
        -- destruct (Z.eq_dec n2 0%Z) as [Hz | Hnz].
           ++ subst. exists (ELit (VOops "modulo by zero"%string)), empty_env.
              apply S_Mod_Zero.
           ++ exists (ELit (VInt (n1 mod n2)%Z)), empty_env. apply S_Mod_Int. assumption.
        -- exists (ELit (VOops s2)), empty_env. apply S_BinOp_Error_Right.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
      * match goal with
        | [ H1 : has_type _ e1 TInt |- _ ] =>
          destruct (canonical_forms_int_expr _ H1 Hv1) as [[n1 Heq1] | [s1 Heq1]]; subst
        end.
        -- exists (EBinOp BMod (ELit (VInt n1)) e2'), rho2'.
           apply S_BinOp_Right; [constructor | assumption].
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
    + exists (EBinOp BMod e1' e2), rho1'. apply S_BinOp_Left. assumption.
  - (* T_Lt_Int *)
    right.
    assert (IH1 : is_value e1 \/ exists e' rho', step e1 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    assert (IH2 : is_value e2 \/ exists e' rho', step e2 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    destruct IH1 as [Hv1 | [e1' [rho1' Hs1]]].
    + destruct IH2 as [Hv2 | [e2' [rho2' Hs2]]].
      * match goal with
        | [ H1 : has_type _ e1 TInt, H2 : has_type _ e2 TInt |- _ ] =>
          destruct (canonical_forms_int_expr _ H1 Hv1) as [[n1 Heq1] | [s1 Heq1]];
          destruct (canonical_forms_int_expr _ H2 Hv2) as [[n2 Heq2] | [s2 Heq2]];
          subst
        end.
        -- exists (ELit (VBool (Z.ltb n1 n2))), empty_env. apply S_Lt.
        -- exists (ELit (VOops s2)), empty_env. apply S_BinOp_Error_Right.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
      * match goal with
        | [ H1 : has_type _ e1 TInt |- _ ] =>
          destruct (canonical_forms_int_expr _ H1 Hv1) as [[n1 Heq1] | [s1 Heq1]]; subst
        end.
        -- exists (EBinOp BLt (ELit (VInt n1)) e2'), rho2'.
           apply S_BinOp_Right; [constructor | assumption].
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
    + exists (EBinOp BLt e1' e2), rho1'. apply S_BinOp_Left. assumption.
  - (* T_Gt_Int *)
    right.
    assert (IH1 : is_value e1 \/ exists e' rho', step e1 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    assert (IH2 : is_value e2 \/ exists e' rho', step e2 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    destruct IH1 as [Hv1 | [e1' [rho1' Hs1]]].
    + destruct IH2 as [Hv2 | [e2' [rho2' Hs2]]].
      * match goal with
        | [ H1 : has_type _ e1 TInt, H2 : has_type _ e2 TInt |- _ ] =>
          destruct (canonical_forms_int_expr _ H1 Hv1) as [[n1 Heq1] | [s1 Heq1]];
          destruct (canonical_forms_int_expr _ H2 Hv2) as [[n2 Heq2] | [s2 Heq2]];
          subst
        end.
        -- exists (ELit (VBool (Z.gtb n1 n2))), empty_env. apply S_Gt.
        -- exists (ELit (VOops s2)), empty_env. apply S_BinOp_Error_Right.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
      * match goal with
        | [ H1 : has_type _ e1 TInt |- _ ] =>
          destruct (canonical_forms_int_expr _ H1 Hv1) as [[n1 Heq1] | [s1 Heq1]]; subst
        end.
        -- exists (EBinOp BGt (ELit (VInt n1)) e2'), rho2'.
           apply S_BinOp_Right; [constructor | assumption].
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
    + exists (EBinOp BGt e1' e2), rho1'. apply S_BinOp_Left. assumption.
  - (* T_Le_Int *)
    right.
    assert (IH1 : is_value e1 \/ exists e' rho', step e1 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    assert (IH2 : is_value e2 \/ exists e' rho', step e2 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    destruct IH1 as [Hv1 | [e1' [rho1' Hs1]]].
    + destruct IH2 as [Hv2 | [e2' [rho2' Hs2]]].
      * match goal with
        | [ H1 : has_type _ e1 TInt, H2 : has_type _ e2 TInt |- _ ] =>
          destruct (canonical_forms_int_expr _ H1 Hv1) as [[n1 Heq1] | [s1 Heq1]];
          destruct (canonical_forms_int_expr _ H2 Hv2) as [[n2 Heq2] | [s2 Heq2]];
          subst
        end.
        -- exists (ELit (VBool (Z.leb n1 n2))), empty_env. apply S_Le.
        -- exists (ELit (VOops s2)), empty_env. apply S_BinOp_Error_Right.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
      * match goal with
        | [ H1 : has_type _ e1 TInt |- _ ] =>
          destruct (canonical_forms_int_expr _ H1 Hv1) as [[n1 Heq1] | [s1 Heq1]]; subst
        end.
        -- exists (EBinOp BLe (ELit (VInt n1)) e2'), rho2'.
           apply S_BinOp_Right; [constructor | assumption].
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
    + exists (EBinOp BLe e1' e2), rho1'. apply S_BinOp_Left. assumption.
  - (* T_Ge_Int *)
    right.
    assert (IH1 : is_value e1 \/ exists e' rho', step e1 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    assert (IH2 : is_value e2 \/ exists e' rho', step e2 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    destruct IH1 as [Hv1 | [e1' [rho1' Hs1]]].
    + destruct IH2 as [Hv2 | [e2' [rho2' Hs2]]].
      * match goal with
        | [ H1 : has_type _ e1 TInt, H2 : has_type _ e2 TInt |- _ ] =>
          destruct (canonical_forms_int_expr _ H1 Hv1) as [[n1 Heq1] | [s1 Heq1]];
          destruct (canonical_forms_int_expr _ H2 Hv2) as [[n2 Heq2] | [s2 Heq2]];
          subst
        end.
        -- exists (ELit (VBool (Z.geb n1 n2))), empty_env. apply S_Ge.
        -- exists (ELit (VOops s2)), empty_env. apply S_BinOp_Error_Right.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
      * match goal with
        | [ H1 : has_type _ e1 TInt |- _ ] =>
          destruct (canonical_forms_int_expr _ H1 Hv1) as [[n1 Heq1] | [s1 Heq1]]; subst
        end.
        -- exists (EBinOp BGe (ELit (VInt n1)) e2'), rho2'.
           apply S_BinOp_Right; [constructor | assumption].
        -- exists (ELit (VOops s1)), empty_env. apply S_BinOp_Error_Left.
    + exists (EBinOp BGe e1' e2), rho1'. apply S_BinOp_Left. assumption.
  - (* T_Neg_Int *)
    right.
    assert (IHe : is_value e0 \/ exists e' rho', step e0 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    destruct IHe as [Hv | [e' [rho' Hs]]].
    + match goal with
      | [ Ht : has_type _ e0 TInt |- _ ] =>
        destruct (canonical_forms_int_expr _ Ht Hv) as [[n Heq] | [s Heq]]; subst
      end.
      * exists (ELit (VInt (-n)%Z)), empty_env. apply S_Neg_Int.
      * exists (ELit (VOops s)), empty_env. apply S_UnOp_Error.
    + exists (EUnOp UNeg e'), rho'. apply S_UnOp_inner. assumption.
  - (* T_Neg_Float *)
    right.
    assert (IHe : is_value e0 \/ exists e' rho', step e0 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    destruct IHe as [Hv | [e' [rho' Hs]]].
    + match goal with
      | [ Ht : has_type _ e0 TFloat |- _ ] =>
        destruct (canonical_forms_float_expr _ Ht Hv) as [[r Heq] | [s Heq]]; subst
      end.
      * exists (ELit (VFloat (- r)%R)), empty_env. apply S_Neg_Float.
      * exists (ELit (VOops s)), empty_env. apply S_UnOp_Error.
    + exists (EUnOp UNeg e'), rho'. apply S_UnOp_inner. assumption.
  - (* T_Not *)
    right.
    assert (IHe : is_value e0 \/ exists e' rho', step e0 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    destruct IHe as [Hv | [e' [rho' Hs]]].
    + match goal with
      | [ Ht : has_type _ e0 TBool |- _ ] =>
        destruct (canonical_forms_bool_expr _ Ht Hv) as [[b Heq] | [s Heq]]; subst
      end.
      * exists (ELit (VBool (negb b))), empty_env. apply S_Not.
      * exists (ELit (VOops s)), empty_env. apply S_UnOp_Error.
    + exists (EUnOp UNot e'), rho'. apply S_UnOp_inner. assumption.
  - (* T_Array *)
    right.
    assert (Hprog: Forall (fun e0 => is_value e0 \/
                     exists e' rho', step e0 empty_env e' rho') es).
    { match goal with
      | [ Hf : Forall _ es |- _ ] =>
        eapply forall_progress_from_ih; [exact Hf |]
      end.
      intros y Hin t' Hty'.
      eapply IH.
      - unfold ltof. apply in_list_size_fold. assumption.
      - eassumption.
    }
    destruct (array_elements_progress es Hprog) as
      [[vs Hvs] | [vs [e0 [e0' [es' [rho' [Hdecomp Hstep]]]]]]].
    + subst. exists (ELit (VArray vs)), empty_env. apply S_Array_val.
    + subst. exists (EArray (map ELit vs ++ e0' :: es')), rho'.
      apply S_Array_step. assumption.
  - (* T_Okay *)
    right.
    assert (IHe : is_value e0 \/ exists e' rho', step e0 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    destruct IHe as [Hv | [e' [rho' Hs]]].
    + destruct (value_is_lit_or_array e0 Hv) as [[v Heq] | [vs Heq]]; subst.
      * destruct v as [z|r|s|b| |l|ok|err].
        -- exists (ELit (VOkay (VInt z))), empty_env. apply S_Okay. constructor.
        -- exists (ELit (VOkay (VFloat r))), empty_env. apply S_Okay. constructor.
        -- exists (ELit (VOkay (VString s))), empty_env. apply S_Okay. constructor.
        -- exists (ELit (VOkay (VBool b))), empty_env. apply S_Okay. constructor.
        -- exists (ELit (VOkay VUnit)), empty_env. apply S_Okay. constructor.
        -- exists (ELit (VOkay (VArray l))), empty_env. apply S_Okay. constructor.
        -- exists (ELit (VOkay (VOkay ok))), empty_env. apply S_Okay. constructor.
        -- exists (ELit (VOops err)), empty_env. apply S_Okay_Error.
      * exists (EOkay (ELit (VArray vs))), empty_env.
        apply S_Okay_step. apply S_Array_val.
    + exists (EOkay e'), rho'. apply S_Okay_step. assumption.
  - (* T_Oops *)
    right.
    assert (IHe : is_value e0 \/ exists e' rho', step e0 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    destruct IHe as [Hv | [e' [rho' Hs]]].
    + destruct (value_is_lit_or_array e0 Hv) as [[v Heq] | [vs Heq]]; subst.
      * match goal with
        | [ Ht : has_type _ (ELit v) TString |- _ ] =>
          destruct (canonical_forms_string _ Ht) as [[s Heq] | [s Heq]]; subst
        end.
        -- exists (ELit (VOops s)), empty_env. apply S_Oops.
        -- exists (ELit (VOops s)), empty_env. apply S_Oops_Error.
      * match goal with
        | [ Ht : has_type _ (EArray _) TString |- _ ] =>
          inversion Ht; subst; try discriminate
        end.
    + exists (EOops e'), rho'. apply S_Oops_step. assumption.
  - (* T_Unwrap *)
    right.
    assert (IHe : is_value e0 \/ exists e' rho', step e0 empty_env e' rho').
    { eapply IH. unfold ltof. simpl. lia. eassumption. }
    destruct IHe as [Hv | [e' [rho' Hs]]].
    + match goal with
      | [ Ht : has_type _ e0 (TResult _ _) |- _ ] =>
        destruct (canonical_forms_result_expr _ _ _ Ht Hv) as
          [[v Heq] | [s Heq]]
      end.
      * subst. exists (ELit v), empty_env. apply S_Unwrap_Okay.
      * subst. exists (ELit (VOops s)), empty_env. apply S_Unwrap_Oops.
    + exists (EUnwrap e'), rho'. apply S_Unwrap_step. assumption.
  - (* T_Lit_Okay *) left. constructor.
  - (* T_Lit_Oops *) left. constructor.
  - (* T_Oops_Any *) left. constructor.
  - (* T_Lit_Array *) left. constructor.
Qed.

(** ** Preservation Theorem *)

(** Preservation: if a well-typed expression steps, the result has the same
    type. With T_Oops_Any, the S_Unwrap_Oops case is provable: unwrapping
    an error value produces the same error value, which inhabits any type
    via T_Oops_Any. Error propagation through BinOp/UnOp is similarly
    handled. The proof is by induction on the step relation. *)

Theorem preservation : forall e e' t rho rho',
  has_type empty_type_env e t ->
  step e rho e' rho' ->
  has_type empty_type_env e' t.
Proof.
  intros e e' t rho rho' Ht Hs.
  generalize dependent t.
  (* Preservation automation: for each step case, invert the typing
     derivation and reconstruct with the IH. Error cases use T_Oops_Any. *)
  induction Hs; intros t Ht;
    try solve [apply T_Oops_Any];
    (* New binop value results (or/sub/mul/div/mod/lt/gt/le/ge): invert the
       single relevant typing rule and rebuild via T_Int/T_Bool. Placed early
       so these dispatch in one step instead of grinding through the cascade
       below; div/mod-by-zero results are VOops, already closed by T_Oops_Any. *)
    try solve [match goal with |- has_type _ (ELit _) _ => inversion Ht; subst; constructor end];
    try solve [
      inversion Ht; subst;
      first [ apply T_Add_Int; [apply IHHs; assumption | assumption]
            | apply T_Add_Float; [apply IHHs; assumption | assumption]
            | apply T_Add_String; [apply IHHs; assumption | assumption]
            | eapply T_Eq; [apply IHHs; eassumption | eassumption]
            | apply T_And; [apply IHHs; assumption | assumption]
            | apply T_Or; [apply IHHs; assumption | assumption]
            | apply T_Sub_Int; [apply IHHs; assumption | assumption]
            | apply T_Mul_Int; [apply IHHs; assumption | assumption]
            | apply T_Div_Int; [apply IHHs; assumption | assumption]
            | apply T_Mod_Int; [apply IHHs; assumption | assumption]
            | apply T_Lt_Int; [apply IHHs; assumption | assumption]
            | apply T_Gt_Int; [apply IHHs; assumption | assumption]
            | apply T_Le_Int; [apply IHHs; assumption | assumption]
            | apply T_Ge_Int; [apply IHHs; assumption | assumption]
            | apply T_Add_Int; [assumption | apply IHHs; assumption]
            | apply T_Add_Float; [assumption | apply IHHs; assumption]
            | apply T_Add_String; [assumption | apply IHHs; assumption]
            | eapply T_Eq; [eassumption | apply IHHs; eassumption]
            | apply T_And; [assumption | apply IHHs; assumption]
            | apply T_Or; [assumption | apply IHHs; assumption]
            | apply T_Sub_Int; [assumption | apply IHHs; assumption]
            | apply T_Mul_Int; [assumption | apply IHHs; assumption]
            | apply T_Div_Int; [assumption | apply IHHs; assumption]
            | apply T_Mod_Int; [assumption | apply IHHs; assumption]
            | apply T_Lt_Int; [assumption | apply IHHs; assumption]
            | apply T_Gt_Int; [assumption | apply IHHs; assumption]
            | apply T_Le_Int; [assumption | apply IHHs; assumption]
            | apply T_Ge_Int; [assumption | apply IHHs; assumption]
            | apply T_Neg_Int; apply IHHs; assumption
            | apply T_Neg_Float; apply IHHs; assumption
            | apply T_Not; apply IHHs; assumption
            | apply T_Okay; apply IHHs; assumption
            | apply T_Oops; apply IHHs; assumption
            | eapply T_Unwrap; apply IHHs; eassumption
            | apply T_Lit_Okay; assumption
            | apply T_Lit_Oops ]];
    try solve [
      (* S_Unwrap_Okay: nested inversion *)
      inversion Ht; subst;
      match goal with
      | [ H : has_type _ _ _ |- has_type _ (ELit _) _ ] =>
        inversion H; subst; first [ assumption | discriminate ]
      end];
    try solve [
      (* S_Unwrap_Oops and similar: T_Oops_Any *)
      inversion Ht; subst; apply T_Oops_Any].
  (* Remaining cases: error propagation through EOkay/EOops, array step,
     and any residual goals — all resolved by T_Oops_Any or inversion. *)
  all: try solve [apply T_Oops_Any].
  all: try solve [inversion Ht; subst; apply T_Oops_Any].
  all: try solve [inversion Ht; subst;
    match goal with
    | [ H : has_type _ _ _ |- _ ] =>
      try (apply T_Array; assumption);
      try (eapply T_Array; eassumption)
    end].
  (* S_Array_step: preserves TArray t *)
  all: try solve [
    inversion Ht; subst;
    constructor;
    match goal with
    | [ H : Forall _ (_ ++ _ :: _) |- Forall _ (_ ++ _ :: _) ] =>
      apply Forall_app in H; destruct H as [Hpre Hcons];
      apply Forall_app; split; [assumption |];
      inversion Hcons; subst; constructor; [apply IHHs; assumption | assumption]
    end].
  (* S_Array_val: EArray (map ELit vs) : TArray t ==> ELit (VArray vs) : TArray t *)
  all: try solve [
    inversion Ht; subst;
    [ (* T_Array case *)
      apply T_Lit_Array; assumption
    | (* T_Oops_Any case - cannot apply to EArray *)
      discriminate ]].
  (* Array-related equality and error propagation: all produce TBool or error *)
  all: try solve [apply T_Oops_Any].
  all: try solve [inversion Ht; subst; try apply T_Oops_Any; try assumption].
  (* Remaining array equality cases: result is ELit (VBool _) which has type TBool.
     The typing derivation must come from T_Eq (which produces TBool). *)
  all: try solve [
    inversion Ht; subst;
    try constructor;
    try apply T_Oops_Any].
  (* S_Array_val: transform Forall on map ELit to Forall on values *)
  all: try solve [
    inversion Ht; subst;
    [ apply T_Lit_Array;
      match goal with
      | [ H : Forall (fun e => has_type _ e _) (map ELit ?vs) |- Forall (fun v => has_type _ (ELit v) _) ?vs ] =>
        rewrite Forall_map in H; exact H
      end
    | discriminate ]].
  (* S_Unwrap_Okay: handle additional T_Lit_Array inversion case *)
  all: try solve [
    inversion Ht; subst;
    match goal with
    | [ H : has_type _ (ELit (VOkay _)) _ |- _ ] =>
      inversion H; subst; try assumption; try discriminate; try apply T_Oops_Any
    end].
  (* Catch remaining goals *)
  all: try solve [inversion Ht; subst; try apply T_Oops_Any; try assumption;
    try (match goal with
         | [ H : has_type _ (ELit _) _ |- _ ] =>
           inversion H; subst; try assumption; try discriminate; try apply T_Oops_Any
         end)].
  (* Remaining: handle all cases with deep inversion + T_Oops_Any *)
  all: try solve [
    inversion Ht; subst;
    try apply T_Oops_Any;
    try assumption;
    try (inversion Ht; subst; apply T_Oops_Any);
    try (match goal with
         | [ H : has_type _ (ELit _) _ |- _ ] =>
           inversion H; subst; try assumption; try discriminate;
           try apply T_Oops_Any;
           try (match goal with
                | [ H2 : has_type _ (ELit _) _ |- _ ] =>
                  inversion H2; subst; try assumption; try discriminate;
                  try apply T_Oops_Any
                end)
         end);
    try (constructor; try assumption);
    try apply T_Oops_Any].
  (* Nuclear option: brute force all remaining goals *)
  all: try solve [
    inversion Ht; subst;
    repeat (match goal with
            | [ H : has_type _ (ELit _) _ |- _ ] =>
              inversion H; clear H; subst
            end);
    try assumption; try apply T_Oops_Any; try discriminate; try constructor].
  all: try solve [
    inversion Ht; subst;
    try (apply T_Lit_Array;
         match goal with
         | [ H : Forall _ (map ELit _) |- _ ] =>
           rewrite Forall_map in H; exact H
         end);
    try discriminate;
    try apply T_Oops_Any].
Qed.

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
(* 5b. Statement Typing                                                       *)
(* ========================================================================= *)

(** Statement typing threads a type context: [StmtWellTyped G s G'] reads
    "in context [G], statement [s] is well-typed and yields context [G']".
    [SVarDecl] extends the context; [SAssign] requires the variable already
    declared at the assigned type; compound statements ([SIf]/[SLoop]/
    [SAttempt]/[SConsent]) are block-scoped, so they return the incoming
    context. Mutually inductive with [StmtsWellTyped] for blocks. Mirrors
    StmtWellTyped/StmtsWellTyped in WokeLang.lean (cross-prover parity).

    This is the statement-level analogue of the [has_type] expression
    judgment; statements were previously declared ([stmt]) but had no typing
    rules. A statement execution relation + store-typing preservation is the
    natural next step (see AUDIT.md). *)

Inductive StmtWellTyped : type_env -> stmt -> type_env -> Prop :=
  | SWT_VarDecl : forall G x e t,
      has_type G e t ->
      StmtWellTyped G (SVarDecl x e) (extend_type_env x t G)
  | SWT_Assign : forall G x e t,
      G x = Some t -> has_type G e t ->
      StmtWellTyped G (SAssign x e) G
  | SWT_Return : forall G e t,
      has_type G e t ->
      StmtWellTyped G (SReturn e) G
  | SWT_If : forall G c thn els G1 G2,
      has_type G c TBool ->
      StmtsWellTyped G thn G1 -> StmtsWellTyped G els G2 ->
      StmtWellTyped G (SIf c thn els) G
  | SWT_Loop : forall G c body G1,
      has_type G c TBool -> StmtsWellTyped G body G1 ->
      StmtWellTyped G (SLoop c body) G
  | SWT_Attempt : forall G body h G1,
      StmtsWellTyped G body G1 ->
      StmtWellTyped G (SAttempt body h) G
  | SWT_Consent : forall G p body G1,
      StmtsWellTyped G body G1 ->
      StmtWellTyped G (SConsent p body) G
  | SWT_Expr : forall G e t,
      has_type G e t ->
      StmtWellTyped G (SExpr e) G
  | SWT_Complain : forall G m,
      StmtWellTyped G (SComplain m) G

with StmtsWellTyped : type_env -> list stmt -> type_env -> Prop :=
  | SsWT_nil : forall G, StmtsWellTyped G nil G
  | SsWT_cons : forall G s ss G1 G2,
      StmtWellTyped G s G1 -> StmtsWellTyped G1 ss G2 ->
      StmtsWellTyped G (s :: ss) G2.

(** Domain containment: every variable declared in [G] is still declared
    (at some type) in [G']. *)
Definition CtxDomSub (G G' : type_env) : Prop :=
  forall x t, G x = Some t -> exists t', G' x = Some t'.

Lemma ctxDomSub_refl : forall G, CtxDomSub G G.
Proof. intros G x t H. exists t. exact H. Qed.

Lemma ctxDomSub_trans : forall G1 G2 G3,
  CtxDomSub G1 G2 -> CtxDomSub G2 G3 -> CtxDomSub G1 G3.
Proof.
  intros G1 G2 G3 H12 H23 x t H.
  destruct (H12 x t H) as [t' H']. exact (H23 x t' H').
Qed.

Lemma ctxDomSub_extend : forall G x t, CtxDomSub G (extend_type_env x t G).
Proof.
  intros G x t y ty Hy. unfold extend_type_env.
  destruct (String.eqb x y) eqn:Hxy.
  - exists t. reflexivity.
  - exists ty. exact Hy.
Qed.

(** Context monotonicity (single statement): a well-typed statement never
    undeclares a variable. *)
Lemma stmt_wellTyped_mono : forall G s G',
  StmtWellTyped G s G' -> CtxDomSub G G'.
Proof.
  intros G s G' H. inversion H; subst;
    first [ apply ctxDomSub_refl | apply ctxDomSub_extend ].
Qed.

(** Context monotonicity (statement block), by induction on the block. *)
Lemma stmts_wellTyped_mono : forall ss G G',
  StmtsWellTyped G ss G' -> CtxDomSub G G'.
Proof.
  induction ss as [| s rest IH]; intros G G' H; inversion H; subst.
  - apply ctxDomSub_refl.
  - eapply ctxDomSub_trans.
    + eapply stmt_wellTyped_mono; eassumption.
    + eapply IH; eassumption.
Qed.

(** Sequencing composes: typing a block then another from the resulting
    context types their concatenation. *)
Lemma stmts_wellTyped_append : forall ss1 G G' ss2 G'',
  StmtsWellTyped G ss1 G' -> StmtsWellTyped G' ss2 G'' ->
  StmtsWellTyped G (ss1 ++ ss2) G''.
Proof.
  induction ss1 as [| s rest IH]; intros G G' ss2 G'' H1 H2;
    inversion H1; subst; simpl.
  - exact H2.
  - eapply SsWT_cons.
    + eassumption.
    + eapply IH; eassumption.
Qed.

(** Inhabitation smoke: [let x = 0; x] is a well-typed block, yielding a
    context in which [x : TInt]. *)
Example stmts_wellTyped_example :
  StmtsWellTyped empty_type_env
    (SVarDecl "x"%string (ELit (VInt 0)) :: SExpr (EVar "x"%string) :: nil)
    (extend_type_env "x"%string TInt empty_type_env).
Proof.
  eapply SsWT_cons.
  - apply SWT_VarDecl with (t := TInt). apply T_Int.
  - eapply SsWT_cons.
    + apply SWT_Expr with (t := TInt). apply T_Var.
      unfold extend_type_env. rewrite String.eqb_refl. reflexivity.
    + apply SsWT_nil.
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

(* Decidable equality on capabilities (used by cap_subsumes' exact-match case). *)
Definition capability_eq_dec (c1 c2 : capability) : {c1 = c2} + {c1 <> c2}.
Proof. decide equality; decide equality; apply String.string_dec. Defined.
Opaque capability_eq_dec.

(* Capability subsumption: a None-scoped capability subsumes any same-kind
   capability; otherwise exact (decidable) equality. (Previously the catch-all
   returned `false`, so subsumption was not even reflexive — fixed.) *)
Definition cap_subsumes (c1 c2 : capability) : bool :=
  match c1, c2 with
  | CapFileRead None, CapFileRead _ => true
  | CapFileWrite None, CapFileWrite _ => true
  | CapNetwork None, CapNetwork _ => true
  | CapExecute None, CapExecute _ => true
  | _, _ => if capability_eq_dec c1 c2 then true else false
  end.

Definition has_capability (c : capability) (cs : capability_set) : bool :=
  existsb (fun c' => cap_subsumes c' c) cs.

(* Capability subsumption is a PREORDER (reflexive + transitive) — the order
   shape echo-types' DecorationStructure requires. Mirrors capSubsumes_refl /
   capSubsumes_trans in WokeLang.lean (cross-prover parity). *)
Theorem cap_subsumes_refl : forall c, cap_subsumes c c = true.
Proof.
  intros c; destruct c as [o|o|o|o| |]; try destruct o; simpl;
    try reflexivity;
    match goal with
    | [ |- (if capability_eq_dec ?a ?b then _ else _) = true ] =>
      destruct (capability_eq_dec a b) as [_ | Hneq];
        [ reflexivity | exfalso; apply Hneq; reflexivity ]
    end.
Qed.

(* cap_subsumes_trans (transitivity) — FOLLOW-UP. The relation is transitive,
   but a robust Coq proof needs explicit per-kind case analysis; brute-force
   automation over the 6x6x6 capability cases is brittle. Deliberately left
   unproven rather than shipped with fragile automation. The load-bearing fix
   (reflexivity above — broken by the old `false` catch-all) is proven. *)

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
