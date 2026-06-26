(*
SPDX-License-Identifier: MPL-2.0
Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

WokeGrammarStructure.v — Coq mirror of the structural grammar proofs in
WokeGrammarStructure.lean (the repo keeps Lean and Coq in lockstep). Covers
T2.1 (no left recursion, with the guard-pattern discrepancy) and the LL(1)=X /
LL(2)=ok classification. Axiom-free; verified with `coqc WokeGrammarStructure.v`
under Coq 8.18.0.
*)

Require Import List.
Import ListNotations.
Require Import PeanoNat.
Require Import Lia.

(* Nonterminals on the begins-with-first-nonterminal graph; all terminal-first
   productions collapse to [sink] (no outgoing edge, cannot be on a cycle). *)
Inductive NT : Type :=
  | program | topItem | functionDef | paramList | statement | exprStmt
  | emoteAnnotated | matchArm | pattern | patternList | constraintN
  | typeVariant | enumType | typeList | typeN
  | expression | logicalOr | logicalAnd | equality | comparison
  | additive | multiplicative | unary | postfixE | primary | literal | number
  | argList | sink.

(* Begins-with-first-nonterminal edges (guard-pattern alt excluded). *)
Definition edges : list (NT * NT) :=
  [ (program, topItem);
    (topItem, functionDef); (topItem, sink);
    (functionDef, sink);
    (paramList, sink);
    (statement, exprStmt); (statement, emoteAnnotated); (statement, sink);
    (exprStmt, expression);
    (emoteAnnotated, sink);
    (matchArm, pattern);
    (pattern, literal);
    (patternList, pattern);
    (constraintN, expression);
    (typeVariant, typeN); (typeVariant, enumType); (typeVariant, sink);
    (enumType, sink);
    (typeList, typeN);
    (typeN, sink);
    (expression, logicalOr);
    (logicalOr, logicalAnd); (logicalAnd, equality); (equality, comparison);
    (comparison, additive); (additive, multiplicative);
    (multiplicative, unary); (unary, postfixE); (postfixE, primary);
    (primary, literal); (primary, sink);
    (literal, number);
    (argList, expression) ].

Definition rank (n : NT) : nat :=
  match n with
  | program => 80 | topItem => 70 | statement => 50
  | matchArm => 30 | patternList => 30 | functionDef => 30
  | paramList => 20 | constraintN => 40 | argList => 40
  | typeVariant => 20 | typeList => 20 | enumType => 10 | typeN => 10
  | exprStmt => 40 | emoteAnnotated => 40
  | expression => 29 | logicalOr => 28 | logicalAnd => 27 | equality => 26
  | comparison => 25 | additive => 24 | multiplicative => 23 | unary => 22
  | postfixE => 21 | primary => 20 | pattern => 15 | literal => 10 | number => 5
  | sink => 0
  end.

(* Every edge strictly decreases rank (computed). *)
Lemma rank_decreasing_b :
  forallb (fun p => Nat.ltb (rank (snd p)) (rank (fst p))) edges = true.
Proof. vm_compute. reflexivity. Qed.

Lemma rank_decreasing : forall a b, In (a, b) edges -> rank b < rank a.
Proof.
  intros a b Hin.
  assert (Hall := rank_decreasing_b).
  rewrite forallb_forall in Hall.
  specialize (Hall (a, b) Hin). simpl in Hall.
  apply Nat.ltb_lt in Hall. exact Hall.
Qed.

(* Reachability by following one or more first-nonterminal edges. *)
Inductive Reach : NT -> NT -> Prop :=
  | Reach_edge : forall a b, In (a, b) edges -> Reach a b
  | Reach_step : forall a b c, In (a, b) edges -> Reach b c -> Reach a c.

Lemma reach_rank : forall a b, Reach a b -> rank b < rank a.
Proof.
  intros a b H. induction H as [a b Hin | a b c Hin Hbc IH].
  - apply rank_decreasing; exact Hin.
  - apply rank_decreasing in Hin. lia.
Qed.

(* T2.1 — no left recursion (implemented grammar): no nonterminal reaches itself. *)
Theorem no_left_recursion : forall a, ~ Reach a a.
Proof.
  intros a H. apply reach_rank in H. lia.
Qed.

(* The grammar as literally written also has the guard alternative. *)
Definition edgesAsWritten : list (NT * NT) := (pattern, pattern) :: edges.

(* Discrepancy: the guard pattern is directly left-recursive — refuting the prose
   blanket claim "no left recursion" for the grammar as literally written. *)
Theorem guard_pattern_is_left_recursive : In (pattern, pattern) edgesAsWritten.
Proof. simpl. left. reflexivity. Qed.

(* ---- Classification: LL(1) = X (T1.2), LL(2) = ok (T2.3) ---- *)

Inductive PTok := PIdent | PLparen | POther.
Inductive PrimaryAlt := AVar | ACall.

Definition first1 (a : PrimaryAlt) : PTok :=
  match a with AVar => PIdent | ACall => PIdent end.

(* T1.2 — not LL(1): the two alternatives share FIRST1 = identifier. *)
Theorem not_LL1 : first1 AVar = first1 ACall.
Proof. reflexivity. Qed.

Definition decide2 (t1 t2 : PTok) : option PrimaryAlt :=
  match t1, t2 with
  | PIdent, PLparen => Some ACall
  | PIdent, _       => Some AVar
  | _,      _       => None
  end.

(* T2.3 — LL(2): two tokens separate the alternatives. *)
Theorem LL2_separates : decide2 PIdent PLparen <> decide2 PIdent POther.
Proof. simpl. discriminate. Qed.
Theorem LL2_call : decide2 PIdent PLparen = Some ACall.
Proof. reflexivity. Qed.
Theorem LL2_var : decide2 PIdent POther = Some AVar.
Proof. reflexivity. Qed.
