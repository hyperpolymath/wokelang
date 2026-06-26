(*
SPDX-License-Identifier: MPL-2.0
Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

WokeGrammarParser.v — Coq 8.18.0 port of the universal parser metatheory in
WokeGrammar.lean (Lean↔Coq parity for the expression-grammar proofs). A faithful
fuel-based precedence-climbing parser, with termination (totality), the concrete
precedence/associativity/rejection battery, and the universal completeness
round-trip `completeness_rp` via the key lemma `prefix_rt`.
*)

Require Import List.
Import ListNotations.
Require Import PeanoNat.
Require Import Lia.

Inductive BinOp := Or | And | EqB | Ne | Lt | Gt | Le | Ge | Add | Sub | Mul | DivB | ModB.
Inductive UnOp := Neg | Notb.
Inductive Tok :=
  | TNum (n:nat) | TIdent (s:nat) | TLpar | TRpar
  | TOr | TAnd | TEq | TNe | TLt | TGt | TLe | TGe
  | TPlus | TMinus | TStar | TSlash | TPercent | TNot.
Inductive Expr :=
  | ELit (n:nat) | EVar (s:nat) | EUn (u:UnOp) (e:Expr) | EBin (op:BinOp) (l r:Expr).

Definition binLevel (op:BinOp) : nat :=
  match op with
  | Or => 1 | And => 2 | EqB | Ne => 3 | Lt | Gt | Le | Ge => 4
  | Add | Sub => 5 | Mul | DivB | ModB => 6 end.
Definition unaryLevel := 7.

Definition tokBin (t:Tok) : option BinOp :=
  match t with
  | TOr => Some Or | TAnd => Some And | TEq => Some EqB | TNe => Some Ne
  | TLt => Some Lt | TGt => Some Gt | TLe => Some Le | TGe => Some Ge
  | TPlus => Some Add | TMinus => Some Sub | TStar => Some Mul
  | TSlash => Some DivB | TPercent => Some ModB | _ => None end.

(* Precedence-climbing parser, fuel-structural (hence total — T3.3). *)
Fixpoint parsePrec (fuel minl:nat) (ts:list Tok) {struct fuel} : option (Expr * list Tok) :=
  match fuel with
  | 0 => None
  | S f =>
    match parsePrefix f ts with
    | None => None
    | Some (lhs, rest) => parseInfix f minl lhs rest
    end
  end
with parseInfix (fuel minl:nat) (lhs:Expr) (ts:list Tok) {struct fuel} : option (Expr * list Tok) :=
  match fuel with
  | 0 => None
  | S f =>
    match ts with
    | [] => Some (lhs, [])
    | t :: rest =>
      match tokBin t with
      | None => Some (lhs, t :: rest)
      | Some op =>
        if Nat.ltb minl (binLevel op) then
          match parsePrec f (binLevel op) rest with
          | None => None
          | Some (rhs, rest') => parseInfix f minl (EBin op lhs rhs) rest'
          end
        else Some (lhs, t :: rest)
      end
    end
  end
with parsePrefix (fuel:nat) (ts:list Tok) {struct fuel} : option (Expr * list Tok) :=
  match fuel with
  | 0 => None
  | S f =>
    match ts with
    | TNum n :: rest => Some (ELit n, rest)
    | TIdent s :: rest => Some (EVar s, rest)
    | TLpar :: rest =>
      match parsePrec f 0 rest with
      | Some (e, TRpar :: rest') => Some (e, rest')
      | _ => None
      end
    | TMinus :: rest =>
      match parsePrec f unaryLevel rest with
      | None => None
      | Some (e, rest') => Some (EUn Neg e, rest')
      end
    | TNot :: rest =>
      match parsePrec f unaryLevel rest with
      | None => None
      | Some (e, rest') => Some (EUn Notb e, rest')
      end
    | _ => None
    end
  end.

Definition budget (ts:list Tok) := 2 * length ts + 2.
Definition parseAll (ts:list Tok) : option Expr :=
  match parsePrec (budget ts) 0 ts with
  | Some (e, []) => Some e
  | _ => None
  end.

(* ---- Precedence (T6.1) and associativity (T6.3): concrete checks ---- *)
Example prec_mul_over_add :
  parseAll [TNum 1; TPlus; TNum 2; TStar; TNum 3]
    = Some (EBin Add (ELit 1) (EBin Mul (ELit 2) (ELit 3))).
Proof. vm_compute. reflexivity. Qed.

Example prec_add_after_mul :
  parseAll [TNum 1; TStar; TNum 2; TPlus; TNum 3]
    = Some (EBin Add (EBin Mul (ELit 1) (ELit 2)) (ELit 3)).
Proof. vm_compute. reflexivity. Qed.

Example assoc_sub_left :
  parseAll [TNum 1; TMinus; TNum 2; TMinus; TNum 3]
    = Some (EBin Sub (EBin Sub (ELit 1) (ELit 2)) (ELit 3)).
Proof. vm_compute. reflexivity. Qed.

Example grouping_overrides :
  parseAll [TLpar; TNum 1; TPlus; TNum 2; TRpar; TStar; TNum 3]
    = Some (EBin Mul (EBin Add (ELit 1) (ELit 2)) (ELit 3)).
Proof. vm_compute. reflexivity. Qed.

Example full_ladder :
  parseAll [TNum 1; TOr; TNum 2; TAnd; TNum 3; TEq; TNum 4; TLt;
            TNum 5; TPlus; TNum 6; TStar; TNum 7]
    = Some (EBin Or (ELit 1)
              (EBin And (ELit 2)
                (EBin EqB (ELit 3)
                  (EBin Lt (ELit 4)
                    (EBin Add (ELit 5) (EBin Mul (ELit 6) (ELit 7))))))).
Proof. vm_compute. reflexivity. Qed.

Example unary_tighter :
  parseAll [TMinus; TNum 2; TStar; TNum 3]
    = Some (EBin Mul (EUn Neg (ELit 2)) (ELit 3)).
Proof. vm_compute. reflexivity. Qed.

(* ---- Rejection battery (T3.1, no over-acceptance) ---- *)
Example rej_lead_op : parseAll [TPlus; TNum 1] = None.
Proof. vm_compute. reflexivity. Qed.
Example rej_two_atoms : parseAll [TNum 1; TNum 2] = None.
Proof. vm_compute. reflexivity. Qed.
Example rej_trail_op : parseAll [TNum 1; TPlus] = None.
Proof. vm_compute. reflexivity. Qed.
Example rej_unclosed : parseAll [TLpar; TNum 1] = None.
Proof. vm_compute. reflexivity. Qed.
Example rej_extra_rpar : parseAll [TLpar; TNum 1; TRpar; TRpar] = None.
Proof. vm_compute. reflexivity. Qed.
Example rej_empty : parseAll [] = None.
Proof. vm_compute. reflexivity. Qed.

(* ===== Universal metatheory: completeness + unambiguity ===== *)

Definition opTok (op:BinOp) : Tok :=
  match op with
  | Or => TOr | And => TAnd | EqB => TEq | Ne => TNe | Lt => TLt | Gt => TGt
  | Le => TLe | Ge => TGe | Add => TPlus | Sub => TMinus | Mul => TStar
  | DivB => TSlash | ModB => TPercent end.

Lemma tokBin_opTok : forall op, tokBin (opTok op) = Some op.
Proof. destruct op; reflexivity. Qed.

Lemma binLevel_pos : forall op, Nat.ltb 0 (binLevel op) = true.
Proof. destruct op; reflexivity. Qed.

Fixpoint rp (e:Expr) : list Tok :=
  match e with
  | ELit n => [TNum n]
  | EVar s => [TIdent s]
  | EUn Neg e => [TLpar; TMinus] ++ rp e ++ [TRpar]
  | EUn Notb e => [TLpar; TNot] ++ rp e ++ [TRpar]
  | EBin op l r => [TLpar] ++ rp l ++ [opTok op] ++ rp r ++ [TRpar]
  end.

Lemma rp_len_pos : forall e, 1 <= length (rp e).
Proof. intros e; destruct e; try destruct u; simpl; lia. Qed.

(* One-step unfold equations (definitional). *)
Lemma u_lpar : forall f rest, parsePrefix (S f) (TLpar :: rest) =
  match parsePrec f 0 rest with Some (e, TRpar :: r) => Some (e, r) | _ => None end.
Proof. reflexivity. Qed.
Lemma u_minus : forall f rest, parsePrefix (S f) (TMinus :: rest) =
  match parsePrec f unaryLevel rest with None => None | Some (e, r) => Some (EUn Neg e, r) end.
Proof. reflexivity. Qed.
Lemma u_not : forall f rest, parsePrefix (S f) (TNot :: rest) =
  match parsePrec f unaryLevel rest with None => None | Some (e, r) => Some (EUn Notb e, r) end.
Proof. reflexivity. Qed.
Lemma u_prec : forall f minl ts, parsePrec (S f) minl ts =
  match parsePrefix f ts with None => None | Some (lhs, rest) => parseInfix f minl lhs rest end.
Proof. reflexivity. Qed.
Lemma u_infix_nil : forall f minl lhs, parseInfix (S f) minl lhs [] = Some (lhs, []).
Proof. reflexivity. Qed.

(* Key lemma: the prefix parser recovers any fully-parenthesised expression. *)
Lemma prefix_rt : forall e rest F,
  2 * length (rp e) <= F -> parsePrefix F (rp e ++ rest) = Some (e, rest).
Proof.
  induction e as [n|s|u e IH|op l IHl r IHr]; intros rest F HF.
  - (* ELit *) destruct F; simpl in HF; [lia|]. reflexivity.
  - (* EVar *) destruct F; simpl in HF; [lia|]. reflexivity.
  - (* EUn *)
    pose proof (rp_len_pos e) as Hpe.
    assert (Hlen: length (rp (EUn u e)) = 3 + length (rp e))
      by (destruct u; cbn [rp]; rewrite !app_length; cbn [length]; lia).
    rewrite Hlen in HF.
    do 5 (destruct F as [|F]; [lia|]).
    destruct u.
    + (* Neg *)
      assert (Hnorm: rp (EUn Neg e) ++ rest = TLpar :: TMinus :: (rp e ++ TRpar :: rest)).
      { cbn [rp]. rewrite <- ?app_assoc. reflexivity. }
      rewrite Hnorm.
      assert (H1: parsePrefix (S F) (rp e ++ TRpar :: rest) = Some (e, TRpar :: rest))
        by (apply IH; lia).
      assert (H3: parsePrec (S (S F)) unaryLevel (rp e ++ TRpar :: rest) = Some (e, TRpar :: rest))
        by (rewrite u_prec, H1; reflexivity).
      assert (H4: parsePrefix (S (S (S F))) (TMinus :: (rp e ++ TRpar :: rest))
                  = Some (EUn Neg e, TRpar :: rest))
        by (rewrite u_minus, H3; reflexivity).
      assert (H6: parsePrec (S (S (S (S F)))) 0 (TMinus :: (rp e ++ TRpar :: rest))
                  = Some (EUn Neg e, TRpar :: rest))
        by (rewrite u_prec, H4; reflexivity).
      rewrite u_lpar, H6. reflexivity.
    + (* Notb *)
      assert (Hnorm: rp (EUn Notb e) ++ rest = TLpar :: TNot :: (rp e ++ TRpar :: rest)).
      { cbn [rp]. rewrite <- ?app_assoc. reflexivity. }
      rewrite Hnorm.
      assert (H1: parsePrefix (S F) (rp e ++ TRpar :: rest) = Some (e, TRpar :: rest))
        by (apply IH; lia).
      assert (H3: parsePrec (S (S F)) unaryLevel (rp e ++ TRpar :: rest) = Some (e, TRpar :: rest))
        by (rewrite u_prec, H1; reflexivity).
      assert (H4: parsePrefix (S (S (S F))) (TNot :: (rp e ++ TRpar :: rest))
                  = Some (EUn Notb e, TRpar :: rest))
        by (rewrite u_not, H3; reflexivity).
      assert (H6: parsePrec (S (S (S (S F)))) 0 (TNot :: (rp e ++ TRpar :: rest))
                  = Some (EUn Notb e, TRpar :: rest))
        by (rewrite u_prec, H4; reflexivity).
      rewrite u_lpar, H6. reflexivity.
  - (* EBin *)
    pose proof (rp_len_pos l) as Hpl. pose proof (rp_len_pos r) as Hpr.
    assert (Hlen: length (rp (EBin op l r)) = 3 + length (rp l) + length (rp r))
      by (cbn [rp]; rewrite !app_length; cbn [length]; lia).
    rewrite Hlen in HF.
    do 5 (destruct F as [|F]; [lia|]).
    assert (Hnorm: rp (EBin op l r) ++ rest
                   = TLpar :: (rp l ++ opTok op :: (rp r ++ TRpar :: rest))).
    { cbn [rp]. rewrite <- ?app_assoc. reflexivity. }
    rewrite Hnorm.
    assert (HR: parsePrefix (S F) (rp r ++ TRpar :: rest) = Some (r, TRpar :: rest))
      by (apply IHr; lia).
    assert (HRp: parsePrec (S (S F)) (binLevel op) (rp r ++ TRpar :: rest)
                 = Some (r, TRpar :: rest))
      by (rewrite u_prec, HR; reflexivity).
    assert (HL: parsePrefix (S (S (S F))) (rp l ++ opTok op :: (rp r ++ TRpar :: rest))
                = Some (l, opTok op :: (rp r ++ TRpar :: rest)))
      by (apply IHl; lia).
    assert (HLi: parseInfix (S (S (S F))) 0 l (opTok op :: (rp r ++ TRpar :: rest))
                 = Some (EBin op l r, TRpar :: rest)).
    { cbn [parseInfix]. rewrite tokBin_opTok. simpl Nat.ltb. rewrite binLevel_pos.
      rewrite HRp. reflexivity. }
    assert (HLp: parsePrec (S (S (S (S F)))) 0 (rp l ++ opTok op :: (rp r ++ TRpar :: rest))
                 = Some (EBin op l r, TRpar :: rest))
      by (rewrite u_prec, HL; exact HLi).
    rewrite u_lpar, HLp. reflexivity.
Qed.

Lemma parse_closed : forall e F, 2 * length (rp e) + 2 <= F -> parsePrec F 0 (rp e) = Some (e, []).
Proof.
  intros e F HF. pose proof (rp_len_pos e).
  destruct F as [|[|F]]; try lia.
  assert (Hp: parsePrefix (S F) (rp e) = Some (e, [])).
  { pose proof (prefix_rt e [] (S F)) as Hpr. rewrite app_nil_r in Hpr. apply Hpr. lia. }
  rewrite u_prec, Hp. apply u_infix_nil.
Qed.

(* T3.2 completeness (universal): every expression's concrete syntax parses back. *)
Theorem completeness_rp : forall e, parseAll (rp e) = Some e.
Proof.
  intros e. unfold parseAll. rewrite (parse_closed e (budget (rp e))).
  - reflexivity.
  - unfold budget. lia.
Qed.

(* T2.2 unambiguity: the parser is a function. *)
Theorem parse_deterministic : forall ts e1 e2,
  parseAll ts = Some e1 -> parseAll ts = Some e2 -> e1 = e2.
Proof. intros ts e1 e2 H1 H2. rewrite H1 in H2. injection H2; auto. Qed.

(* Distinct expressions have distinct concrete forms (via the parser). *)
Theorem rp_injective : forall a b, rp a = rp b -> a = b.
Proof.
  intros a b H.
  assert (He: parseAll (rp a) = parseAll (rp b)) by (rewrite H; reflexivity).
  rewrite !completeness_rp in He. injection He; auto.
Qed.
