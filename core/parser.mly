(* SPDX-License-Identifier: AGPL-3.0-or-later *)
(* SPDX-FileCopyrightText: 2026 Hyperpolymath *)

%{
open Ast
%}

(* Tokens - Delimiters *)
%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET
%token COMMA SEMICOLON COLON EQUALS AT ARROW HASH UNDERSCORE

(* Tokens - Operators *)
%token PLUS MINUS STAR SLASH PERCENT
%token EQEQ NE LT GT LE GE

(* Tokens - Keywords - Control Flow *)
%token TO GIVE BACK REMEMBER WHEN OTHERWISE REPEAT TIMES

(* Tokens - Keywords - Consent and Safety *)
%token ONLY IF OKAY ATTEMPT SAFELY OR REASSURE COMPLAIN

(* Tokens - Keywords - Gratitude *)
%token THANKS

(* Tokens - Keywords - Lifecycle *)
%token HELLO GOODBYE

(* Tokens - Keywords - Concurrency *)
%token WORKER SIDE QUEST SPAWN SUPERPOWER

(* Tokens - Keywords - Pattern Matching *)
%token DECIDE BASED ON

(* Tokens - Keywords - Units *)
%token MEASURED IN

(* Tokens - Keywords - Pragmas *)
%token CARE STRICT VERBOSE

(* Tokens - Keywords - Types *)
%token TYPE_STRING TYPE_INT TYPE_FLOAT TYPE_BOOL MAYBE
%token CONST TYPE USE RENAMED

(* Tokens - Keywords - Boolean *)
%token TRUE FALSE AND NOT

(* Tokens - Keywords - Constraints *)
%token MUST HAVE

(* Tokens - Keywords - IO *)
%token SAY

(* Tokens - Literals *)
%token <int> INT
%token <float> FLOAT
%token <string> STRING
%token <string> IDENT

(* Token - End of File *)
%token EOF

(* Precedence and associativity *)
%left OR
%left AND
%left EQEQ NE
%left LT GT LE GE
%left PLUS MINUS
%left STAR SLASH PERCENT
%right NOT
%right UMINUS

%start <Ast.program> program

%%

program:
  | items = list(top_level_item); EOF { items }
  ;

top_level_item:
  | f = function_def { TLFunction f }
  | g = gratitude_block { TLGratitude g }
  | w = worker_def { TLWorker w }
  | s = side_quest_def { TLSideQuest s }
  | c = const_def { c }
  ;

function_def:
  | emote = option(emote_tag); TO; name = IDENT;
    LPAREN; params = separated_list(COMMA, param); RPAREN;
    ret = option(preceded(ARROW, typ));
    LBRACE;
    hello_msg = option(preceded(HELLO, terminated(STRING, SEMICOLON)));
    body = list(statement);
    goodbye_msg = option(preceded(GOODBYE, terminated(STRING, SEMICOLON)));
    RBRACE
    { { name; params; return_type = ret; hello_msg; body; goodbye_msg; emote } }
  ;

param:
  | name = IDENT; t = option(preceded(COLON, typ)) { { name; typ = t } }
  ;

typ:
  | TYPE_STRING { TString }
  | TYPE_INT { TInt }
  | TYPE_FLOAT { TFloat }
  | TYPE_BOOL { TBool }
  | LBRACKET; t = typ; RBRACKET { TArray t }
  | MAYBE; t = typ { TMaybe t }
  | name = IDENT { TCustom name }
  ;

gratitude_block:
  | THANKS; TO; LBRACE; entries = list(gratitude_entry); RBRACE
    { entries }
  ;

gratitude_entry:
  | contributor = STRING; ARROW; contribution = STRING; SEMICOLON
    { { contributor; contribution } }
  ;

worker_def:
  | WORKER; name = IDENT; LBRACE; body = list(statement); RBRACE
    { { worker_name = name; worker_body = body } }
  ;

side_quest_def:
  | SIDE; QUEST; name = IDENT; LBRACE; body = list(statement); RBRACE
    { { quest_name = name; quest_body = body } }
  ;

const_def:
  | CONST; name = IDENT; COLON; t = typ; EQUALS; e = expr; SEMICOLON
    { TLConst (name, Some t, e) }
  | CONST; name = IDENT; EQUALS; e = expr; SEMICOLON
    { TLConst (name, None, e) }
  ;

emote_tag:
  | AT; name = IDENT; params = option(delimited(LPAREN, emote_params, RPAREN))
    { { name; params = Option.value ~default:[] params } }
  ;

emote_params:
  | params = separated_nonempty_list(COMMA, emote_param) { params }
  ;

emote_param:
  | name = IDENT; EQUALS; e = expr { (name, e) }
  ;

statement:
  | s = simple_statement { s }
  | s = compound_statement { s }
  ;

simple_statement:
  | REMEMBER; name = IDENT; EQUALS; e = expr;
    unit = option(preceded(pair(MEASURED, IN), IDENT)); SEMICOLON
    { SRemember (name, e, unit) }
  | name = IDENT; EQUALS; e = expr; SEMICOLON
    { SAssign (name, e) }
  | GIVE; BACK; e = expr; SEMICOLON
    { SGiveBack e }
  | e = expr; SEMICOLON
    { SExpr e }
  | COMPLAIN; msg = STRING; SEMICOLON
    { SComplain msg }
  | SPAWN; WORKER; name = IDENT; SEMICOLON
    { SSpawnWorker name }
  | SAY; e = expr; SEMICOLON
    { SExpr (ECall ("say", [e])) }
  ;

compound_statement:
  | WHEN; cond = expr; LBRACE; then_body = list(statement); RBRACE;
    else_body = option(preceded(OTHERWISE, delimited(LBRACE, list(statement), RBRACE)))
    { SWhen (cond, then_body, else_body) }
  | REPEAT; n = expr; TIMES; LBRACE; body = list(statement); RBRACE
    { SRepeat (n, body) }
  | ATTEMPT; SAFELY; LBRACE; body = list(statement); RBRACE;
    OR; REASSURE; msg = STRING; SEMICOLON
    { SAttempt (body, msg) }
  | ONLY; IF; OKAY; perm = STRING; LBRACE; body = list(statement); RBRACE
    { SConsent (perm, body) }
  | emote = emote_tag; s = statement
    { SEmoteAnnotated (emote, s) }
  ;

expr:
  | e = logical_or_expr { e }
  ;

logical_or_expr:
  | left = logical_or_expr; OR; right = logical_and_expr
    { EBinOp (OpOr, left, right) }
  | e = logical_and_expr { e }
  ;

logical_and_expr:
  | left = logical_and_expr; AND; right = equality_expr
    { EBinOp (OpAnd, left, right) }
  | e = equality_expr { e }
  ;

equality_expr:
  | left = equality_expr; EQEQ; right = comparison_expr
    { EBinOp (OpEq, left, right) }
  | left = equality_expr; NE; right = comparison_expr
    { EBinOp (OpNe, left, right) }
  | e = comparison_expr { e }
  ;

comparison_expr:
  | left = comparison_expr; LT; right = additive_expr
    { EBinOp (OpLt, left, right) }
  | left = comparison_expr; GT; right = additive_expr
    { EBinOp (OpGt, left, right) }
  | left = comparison_expr; LE; right = additive_expr
    { EBinOp (OpLe, left, right) }
  | left = comparison_expr; GE; right = additive_expr
    { EBinOp (OpGe, left, right) }
  | e = additive_expr { e }
  ;

additive_expr:
  | left = additive_expr; PLUS; right = multiplicative_expr
    { EBinOp (OpAdd, left, right) }
  | left = additive_expr; MINUS; right = multiplicative_expr
    { EBinOp (OpSub, left, right) }
  | e = multiplicative_expr { e }
  ;

multiplicative_expr:
  | left = multiplicative_expr; STAR; right = unary_expr
    { EBinOp (OpMul, left, right) }
  | left = multiplicative_expr; SLASH; right = unary_expr
    { EBinOp (OpDiv, left, right) }
  | left = multiplicative_expr; PERCENT; right = unary_expr
    { EBinOp (OpMod, left, right) }
  | e = unary_expr { e }
  ;

unary_expr:
  | NOT; e = unary_expr { EUnaryOp (OpNot, e) }
  | MINUS; e = unary_expr %prec UMINUS { EUnaryOp (OpNeg, e) }
  | e = primary_expr { e }
  ;

primary_expr:
  | n = INT { EInt n }
  | f = FLOAT { EFloat f }
  | s = STRING { EString s }
  | TRUE { EBool true }
  | FALSE { EBool false }
  | name = IDENT; LPAREN; args = separated_list(COMMA, expr); RPAREN
    { ECall (name, args) }
  | name = IDENT { EIdent name }
  | LBRACKET; elems = separated_list(COMMA, expr); RBRACKET { EArray elems }
  | LPAREN; e = expr; RPAREN { e }
  | e = primary_expr; MEASURED; IN; unit = IDENT { EMeasured (e, unit) }
  | THANKS; LPAREN; s = STRING; RPAREN { EThanks s }
  ;
