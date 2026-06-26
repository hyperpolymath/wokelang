/-
SPDX-License-Identifier: MPL-2.0
Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

WokeGrammarStructure.lean — structural / classification proofs about the WokeLang
grammar (`grammar/wokelang.ebnf`). Self-contained (Lean core prelude only).

This file mechanizes **T2.1 (no left recursion)** for the *whole* grammar, and
in doing so surfaces a genuine discrepancy with the prose `grammar-proofs.md`
§2.1: the grammar **as literally written** DOES contain one left-recursive
production — the guard pattern `pattern = … | pattern "when" expression` — which
the grammar's own NOTE flags as "parser implementation pending" and which the
real parser (`src/parser/mod.rs`) does not implement. With that single
unimplemented alternative excluded, the grammar is provably left-recursion-free.

Method: a left-recursive grammar has a nonterminal A that, following only
*first* symbols, can reach itself. We encode the "begins with first nonterminal"
graph of every production (all terminal-first productions collapse to the single
`sink` node — they have no outgoing edge and so cannot lie on a cycle), exhibit a
rank that strictly decreases along every edge, and conclude no cycle exists.
-/

namespace WokeGrammarStructure

/-- Nonterminals that participate in the begins-with-first-nonterminal graph of
`grammar/wokelang.ebnf`. Every terminal-first production (the vast majority —
`remember`, `when`, `to`, `worker`, `"`, `[`, `|`, …) is a `sink`: it has no
outgoing first-nonterminal edge and therefore cannot be on a cycle. -/
inductive NT where
  | program | topItem | functionDef | paramList | statement | exprStmt
  | emoteAnnotated | matchArm | pattern | patternList | constraint
  | typeVariant | enumType | typeList | type
  | expression | logicalOr | logicalAnd | equality | comparison
  | additive | multiplicative | unary | postfixE | primary | literal | number
  | argList | sink
  deriving DecidableEq, Repr

open NT

/-- Every begins-with-first-nonterminal edge of the grammar, **excluding** the
unimplemented guard-pattern alternative `pattern → pattern`. Terminal-first
alternatives are recorded as an edge to `sink`. -/
def edges : List (NT × NT) :=
  [ (program, topItem),
    (topItem, functionDef), (topItem, sink),
    (functionDef, sink),
    (paramList, sink),
    (statement, exprStmt), (statement, emoteAnnotated), (statement, sink),
    (exprStmt, expression),
    (emoteAnnotated, sink),
    (matchArm, pattern),
    (pattern, literal),               -- the guard alt `pattern "when" …` is excluded
    (patternList, pattern),
    (constraint, expression),
    (typeVariant, type), (typeVariant, enumType), (typeVariant, sink),
    (enumType, sink),
    (typeList, type),
    (type, sink),
    (expression, logicalOr),
    (logicalOr, logicalAnd), (logicalAnd, equality), (equality, comparison),
    (comparison, additive), (additive, multiplicative),
    (multiplicative, unary), (unary, postfixE), (postfixE, primary),
    (primary, literal), (primary, sink),
    (literal, number),
    (argList, expression) ]

/-- A topological rank: strictly decreases along every edge (witnessing that the
begins-graph is a DAG). Higher = closer to the start symbol. -/
def rank : NT → Nat
  | program => 80 | topItem => 70 | statement => 50
  | matchArm => 30 | patternList => 30 | functionDef => 30
  | paramList => 20 | constraint => 40 | argList => 40
  | typeVariant => 20 | typeList => 20 | enumType => 10 | type => 10
  | exprStmt => 40 | emoteAnnotated => 40
  | expression => 29 | logicalOr => 28 | logicalAnd => 27 | equality => 26
  | comparison => 25 | additive => 24 | multiplicative => 23 | unary => 22
  | postfixE => 21 | primary => 20 | pattern => 15 | literal => 10 | number => 5
  | sink => 0

/-- Every edge strictly decreases `rank` (checked by the kernel). -/
theorem rank_decreasing : ∀ p ∈ edges, rank p.2 < rank p.1 := by decide

/-- Reachability by following one or more first-nonterminal edges. `Reach a a`
is exactly "`a` is (directly or indirectly) left-recursive". -/
inductive Reach : NT → NT → Prop
  | edge {a b} : (a, b) ∈ edges → Reach a b
  | step {a b c} : (a, b) ∈ edges → Reach b c → Reach a c

/-- Rank strictly decreases along any reachability path. -/
theorem reach_rank {a b : NT} (h : Reach a b) : rank b < rank a := by
  induction h with
  | edge hab => exact rank_decreasing _ hab
  | step hab _ ih => exact Nat.lt_trans ih (rank_decreasing _ hab)

/-- **T2.1 — no left recursion (implemented grammar).** With the unimplemented
guard-pattern alternative excluded, no nonterminal is left-recursive: it cannot
reach itself by following first symbols. (Proof: a self-path would force
`rank a < rank a`.) Covers the whole grammar — every terminal-first production is
a `sink`, which has no outgoing edge. -/
theorem no_left_recursion (a : NT) : ¬ Reach a a := by
  intro h; exact Nat.lt_irrefl _ (reach_rank h)

/-! ### The honest discrepancy with the prose §2.1 -/

/-- The grammar **as literally written** also has the guard alternative. -/
def edgesAsWritten : List (NT × NT) := (pattern, pattern) :: edges

/-- **Discrepancy (machine-checked).** The guard pattern `pattern = … | pattern
"when" expression` is *directly left-recursive*: `pattern → pattern` is an edge of
the grammar as written. So the prose §2.1 blanket claim "the WokeLang grammar
contains no left recursion" is **false for the grammar as literally written**;
it holds only for the implemented subset (`no_left_recursion`), because the
parser does not implement the guard alternative (the grammar's own NOTE). -/
theorem guard_pattern_is_left_recursive :
    (NT.pattern, NT.pattern) ∈ edgesAsWritten := by decide

/-! ## 2. Lexer: maximal munch (T4.1) and keyword priority (T4.2)

Models the live lexer (`src/lexer/token.rs`, logos): identifiers match
`[a-zA-Z][a-zA-Z0-9_]*` and keywords are exact-string tokens. logos takes the
**longest** match (maximal munch); on a tie it prefers the keyword. We model the
word scanner directly: take the maximal run of identifier characters, then a word
that is exactly a keyword classifies as that keyword, otherwise as an identifier. -/

inductive Lexeme where
  | kw : String → Lexeme
  | ident : String → Lexeme
  deriving DecidableEq, Repr

/-- The reserved keywords of WokeLang (the grammar's RESERVED KEYWORDS list). -/
def keywords : List String :=
  ["to","give","back","remember","when","otherwise","repeat","times","while",
   "break","continue","only","if","okay","attempt","safely","reassure","complain",
   "thanks","hello","goodbye","worker","side","quest","superpower","spawn","send",
   "receive","channel","await","cancel","from","decide","based","on","measured",
   "in","use","renamed","share","type","const","String","Int","Float","Bool",
   "Maybe","Result","must","have","care","strict","verbose","true","false","and",
   "or","not","Okay","Oops","unwrap"]

def isLetter (c : Char) : Bool := c.isAlpha
def isIdentCont (c : Char) : Bool := c.isAlphanum || c == '_'

/-- Take the maximal leading run of identifier-continuation characters. -/
def takeCont : List Char → List Char × List Char
  | [] => ([], [])
  | c :: cs =>
    if isIdentCont c then (c :: (takeCont cs).1, (takeCont cs).2)
    else ([], c :: cs)

/-- Keyword priority: a word equal to a keyword is the keyword token. -/
def classifyWord (w : String) : Lexeme := if w ∈ keywords then .kw w else .ident w

/-- Lex one word: an identifier-start letter, then the maximal identifier run,
then classify (keyword if exact, else identifier). -/
def lexWord : List Char → Option (Lexeme × List Char)
  | [] => none
  | c :: cs =>
    if isLetter c then
      some (classifyWord (String.ofList (c :: (takeCont cs).1)), (takeCont cs).2)
    else none

/-- **T4.2 keyword priority (general):** any reserved word lexes as its keyword. -/
theorem kw_priority {w : String} (h : w ∈ keywords) : classifyWord w = .kw w := by
  unfold classifyWord; rw [if_pos h]

/-- **T4.1 maximal munch (general):** after the maximal identifier run, the
remainder cannot begin with another identifier character — the scanner could not
have stopped earlier. This is the longest-match property. -/
theorem munch_maximal :
    ∀ (cs : List Char) (c : Char) (rest : List Char),
      (takeCont cs).2 = c :: rest → isIdentCont c = false := by
  intro cs
  induction cs with
  | nil => intro c rest h; simp [takeCont] at h
  | cons d ds ih =>
    intro c rest h
    simp only [takeCont] at h
    split at h
    · exact ih c rest h
    · rename_i hd
      obtain ⟨rfl, _⟩ := List.cons.inj h
      simpa using hd

/-! ### Concrete lexer checks (kernel-decided) -/

-- keyword priority: "remember" is the keyword, not a generic identifier.
example : classifyWord "remember" = Lexeme.kw "remember" := by decide
-- maximal munch: "remembering" is ONE identifier, not `remember` + `ing`.
example : lexWord "remembering".toList = some (Lexeme.ident "remembering", []) := by decide
-- "remember(" lexes the keyword then stops at `(` (a non-identifier char).
example : lexWord "remember(".toList = some (Lexeme.kw "remember", "(".toList) := by decide
-- a non-keyword word is an identifier.
example : lexWord "myVar".toList = some (Lexeme.ident "myVar", []) := by decide
-- a leading non-letter is not an identifier start.
example : lexWord "1abc".toList = none := by decide

/-! ## 3. Classification: LL(1) = ✗ (T1.2), LL(2) = ✓ (T2.3)

The grammar is context-free by construction (every production is `A → α`). It is
**not LL(1)**: the `primary` alternatives `identifier` (variable) and
`identifier "(" args ")"` (call) share the FIRST token `identifier`, so one token
of lookahead cannot choose between them. It **is** resolvable with two tokens —
exactly what the real parser does (`parse_prefix` consumes the identifier, then
branches on whether the next token is `(`). -/

inductive PTok where | ident | lparen | other deriving DecidableEq, Repr
inductive PrimaryAlt where | var | call deriving DecidableEq, Repr

/-- FIRST₁ of the two `primary` alternatives that begin with an identifier. -/
def first1 : PrimaryAlt → PTok
  | .var => .ident
  | .call => .ident

/-- **T1.2 — not LL(1):** the two alternatives have identical FIRST₁ (`identifier`),
so a single lookahead token cannot disambiguate `x` (variable) from `x(...)`
(call). This is the FIRST/FIRST conflict the prose §1.1 marks LL(1) = ✗. -/
theorem not_LL1 : first1 .var = first1 .call := rfl

/-- The parser's two-token decision: an identifier followed by `(` is a call,
otherwise a variable (mirrors `parse_prefix` in `src/parser/mod.rs`). -/
def decide2 : PTok → PTok → Option PrimaryAlt
  | .ident, .lparen => some .call
  | .ident, _       => some .var
  | _,      _       => none

/-- **T2.3 — LL(2):** two tokens DO separate the alternatives — `identifier (`
selects the call, `identifier <anything else>` selects the variable, and these
are distinct decisions. -/
theorem LL2_separates : decide2 .ident .lparen ≠ decide2 .ident .other := by decide
theorem LL2_call : decide2 .ident .lparen = some .call := rfl
theorem LL2_var  : decide2 .ident .other  = some .var  := rfl

end WokeGrammarStructure
