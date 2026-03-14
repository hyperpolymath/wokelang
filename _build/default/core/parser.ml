
module MenhirBasics = struct
  
  exception Error
  
  let _eRR =
    fun _s ->
      raise Error
  
  type token = 
    | WORKER
    | WHEN
    | VERBOSE
    | USE
    | UNDERSCORE
    | TYPE_STRING
    | TYPE_INT
    | TYPE_FLOAT
    | TYPE_BOOL
    | TYPE
    | TRUE
    | TO
    | TIMES
    | THANKS
    | SUPERPOWER
    | STRING of 
# 56 "core/parser.mly"
       (string)
# 30 "core/parser.ml"
  
    | STRICT
    | STAR
    | SPAWN
    | SLASH
    | SIDE
    | SEMICOLON
    | SAY
    | SAFELY
    | RPAREN
    | REPEAT
    | RENAMED
    | REMEMBER
    | REASSURE
    | RBRACKET
    | RBRACE
    | QUEST
    | PLUS
    | PERCENT
    | OTHERWISE
    | OR
    | ONLY
    | ON
    | OKAY
    | NOT
    | NE
    | MUST
    | MINUS
    | MEASURED
    | MAYBE
    | LT
    | LPAREN
    | LE
    | LBRACKET
    | LBRACE
    | INT of 
# 54 "core/parser.mly"
       (int)
# 69 "core/parser.ml"
  
    | IN
    | IF
    | IDENT of 
# 57 "core/parser.mly"
       (string)
# 76 "core/parser.ml"
  
    | HELLO
    | HAVE
    | HASH
    | GT
    | GOODBYE
    | GIVE
    | GE
    | FLOAT of 
# 55 "core/parser.mly"
       (float)
# 88 "core/parser.ml"
  
    | FALSE
    | EQUALS
    | EQEQ
    | EOF
    | DECIDE
    | CONST
    | COMPLAIN
    | COMMA
    | COLON
    | CARE
    | BASED
    | BACK
    | ATTEMPT
    | AT
    | ARROW
    | AND
  
end

include MenhirBasics

# 4 "core/parser.mly"
  
open Ast

# 115 "core/parser.ml"

type ('s, 'r) _menhir_state = 
  | MenhirState000 : ('s, _menhir_box_program) _menhir_state
    (** State 000.
        Stack shape : <empty>.
        Start symbol: program. *)

  | MenhirState003 : (('s, _menhir_box_program) _menhir_cell1_WORKER _menhir_cell0_IDENT, _menhir_box_program) _menhir_state
    (** State 003.
        Stack shape : WORKER IDENT.
        Start symbol: program. *)

  | MenhirState004 : (('s, _menhir_box_program) _menhir_cell1_WHEN, _menhir_box_program) _menhir_state
    (** State 004.
        Stack shape : WHEN.
        Start symbol: program. *)

  | MenhirState011 : (('s, _menhir_box_program) _menhir_cell1_NOT, _menhir_box_program) _menhir_state
    (** State 011.
        Stack shape : NOT.
        Start symbol: program. *)

  | MenhirState012 : (('s, _menhir_box_program) _menhir_cell1_MINUS, _menhir_box_program) _menhir_state
    (** State 012.
        Stack shape : MINUS.
        Start symbol: program. *)

  | MenhirState013 : (('s, _menhir_box_program) _menhir_cell1_LPAREN, _menhir_box_program) _menhir_state
    (** State 013.
        Stack shape : LPAREN.
        Start symbol: program. *)

  | MenhirState014 : (('s, _menhir_box_program) _menhir_cell1_LBRACKET, _menhir_box_program) _menhir_state
    (** State 014.
        Stack shape : LBRACKET.
        Start symbol: program. *)

  | MenhirState017 : (('s, _menhir_box_program) _menhir_cell1_IDENT, _menhir_box_program) _menhir_state
    (** State 017.
        Stack shape : IDENT.
        Start symbol: program. *)

  | MenhirState027 : (('s, _menhir_box_program) _menhir_cell1_multiplicative_expr, _menhir_box_program) _menhir_state
    (** State 027.
        Stack shape : multiplicative_expr.
        Start symbol: program. *)

  | MenhirState029 : (('s, _menhir_box_program) _menhir_cell1_multiplicative_expr, _menhir_box_program) _menhir_state
    (** State 029.
        Stack shape : multiplicative_expr.
        Start symbol: program. *)

  | MenhirState031 : (('s, _menhir_box_program) _menhir_cell1_multiplicative_expr, _menhir_box_program) _menhir_state
    (** State 031.
        Stack shape : multiplicative_expr.
        Start symbol: program. *)

  | MenhirState036 : (('s, _menhir_box_program) _menhir_cell1_logical_or_expr, _menhir_box_program) _menhir_state
    (** State 036.
        Stack shape : logical_or_expr.
        Start symbol: program. *)

  | MenhirState038 : (('s, _menhir_box_program) _menhir_cell1_logical_and_expr, _menhir_box_program) _menhir_state
    (** State 038.
        Stack shape : logical_and_expr.
        Start symbol: program. *)

  | MenhirState040 : (('s, _menhir_box_program) _menhir_cell1_equality_expr, _menhir_box_program) _menhir_state
    (** State 040.
        Stack shape : equality_expr.
        Start symbol: program. *)

  | MenhirState042 : (('s, _menhir_box_program) _menhir_cell1_comparison_expr, _menhir_box_program) _menhir_state
    (** State 042.
        Stack shape : comparison_expr.
        Start symbol: program. *)

  | MenhirState044 : (('s, _menhir_box_program) _menhir_cell1_additive_expr, _menhir_box_program) _menhir_state
    (** State 044.
        Stack shape : additive_expr.
        Start symbol: program. *)

  | MenhirState046 : (('s, _menhir_box_program) _menhir_cell1_additive_expr, _menhir_box_program) _menhir_state
    (** State 046.
        Stack shape : additive_expr.
        Start symbol: program. *)

  | MenhirState048 : (('s, _menhir_box_program) _menhir_cell1_comparison_expr, _menhir_box_program) _menhir_state
    (** State 048.
        Stack shape : comparison_expr.
        Start symbol: program. *)

  | MenhirState050 : (('s, _menhir_box_program) _menhir_cell1_comparison_expr, _menhir_box_program) _menhir_state
    (** State 050.
        Stack shape : comparison_expr.
        Start symbol: program. *)

  | MenhirState052 : (('s, _menhir_box_program) _menhir_cell1_comparison_expr, _menhir_box_program) _menhir_state
    (** State 052.
        Stack shape : comparison_expr.
        Start symbol: program. *)

  | MenhirState055 : (('s, _menhir_box_program) _menhir_cell1_equality_expr, _menhir_box_program) _menhir_state
    (** State 055.
        Stack shape : equality_expr.
        Start symbol: program. *)

  | MenhirState061 : (('s, _menhir_box_program) _menhir_cell1_expr, _menhir_box_program) _menhir_state
    (** State 061.
        Stack shape : expr.
        Start symbol: program. *)

  | MenhirState070 : ((('s, _menhir_box_program) _menhir_cell1_WHEN, _menhir_box_program) _menhir_cell1_expr, _menhir_box_program) _menhir_state
    (** State 070.
        Stack shape : WHEN expr.
        Start symbol: program. *)

  | MenhirState075 : (('s, _menhir_box_program) _menhir_cell1_SAY, _menhir_box_program) _menhir_state
    (** State 075.
        Stack shape : SAY.
        Start symbol: program. *)

  | MenhirState078 : (('s, _menhir_box_program) _menhir_cell1_REPEAT, _menhir_box_program) _menhir_state
    (** State 078.
        Stack shape : REPEAT.
        Start symbol: program. *)

  | MenhirState081 : ((('s, _menhir_box_program) _menhir_cell1_REPEAT, _menhir_box_program) _menhir_cell1_expr, _menhir_box_program) _menhir_state
    (** State 081.
        Stack shape : REPEAT expr.
        Start symbol: program. *)

  | MenhirState084 : (('s, _menhir_box_program) _menhir_cell1_REMEMBER _menhir_cell0_IDENT, _menhir_box_program) _menhir_state
    (** State 084.
        Stack shape : REMEMBER IDENT.
        Start symbol: program. *)

  | MenhirState095 : (('s, _menhir_box_program) _menhir_cell1_ONLY _menhir_cell0_STRING, _menhir_box_program) _menhir_state
    (** State 095.
        Stack shape : ONLY STRING.
        Start symbol: program. *)

  | MenhirState097 : (('s, _menhir_box_program) _menhir_cell1_IDENT, _menhir_box_program) _menhir_state
    (** State 097.
        Stack shape : IDENT.
        Start symbol: program. *)

  | MenhirState101 : (('s, _menhir_box_program) _menhir_cell1_GIVE, _menhir_box_program) _menhir_state
    (** State 101.
        Stack shape : GIVE.
        Start symbol: program. *)

  | MenhirState109 : (('s, _menhir_box_program) _menhir_cell1_ATTEMPT, _menhir_box_program) _menhir_state
    (** State 109.
        Stack shape : ATTEMPT.
        Start symbol: program. *)

  | MenhirState112 : (('s, _menhir_box_program) _menhir_cell1_AT _menhir_cell0_IDENT, _menhir_box_program) _menhir_state
    (** State 112.
        Stack shape : AT IDENT.
        Start symbol: program. *)

  | MenhirState114 : (('s, _menhir_box_program) _menhir_cell1_IDENT, _menhir_box_program) _menhir_state
    (** State 114.
        Stack shape : IDENT.
        Start symbol: program. *)

  | MenhirState120 : (('s, _menhir_box_program) _menhir_cell1_emote_param, _menhir_box_program) _menhir_state
    (** State 120.
        Stack shape : emote_param.
        Start symbol: program. *)

  | MenhirState123 : (('s, _menhir_box_program) _menhir_cell1_statement, _menhir_box_program) _menhir_state
    (** State 123.
        Stack shape : statement.
        Start symbol: program. *)

  | MenhirState128 : (('s, _menhir_box_program) _menhir_cell1_emote_tag, _menhir_box_program) _menhir_state
    (** State 128.
        Stack shape : emote_tag.
        Start symbol: program. *)

  | MenhirState144 : (((('s, _menhir_box_program) _menhir_cell1_WHEN, _menhir_box_program) _menhir_cell1_expr, _menhir_box_program) _menhir_cell1_list_statement_, _menhir_box_program) _menhir_state
    (** State 144.
        Stack shape : WHEN expr list(statement).
        Start symbol: program. *)

  | MenhirState152 : (('s, _menhir_box_program) _menhir_cell1_THANKS, _menhir_box_program) _menhir_state
    (** State 152.
        Stack shape : THANKS.
        Start symbol: program. *)

  | MenhirState159 : (('s, _menhir_box_program) _menhir_cell1_gratitude_entry, _menhir_box_program) _menhir_state
    (** State 159.
        Stack shape : gratitude_entry.
        Start symbol: program. *)

  | MenhirState164 : (('s, _menhir_box_program) _menhir_cell1_SIDE _menhir_cell0_IDENT, _menhir_box_program) _menhir_state
    (** State 164.
        Stack shape : SIDE IDENT.
        Start symbol: program. *)

  | MenhirState169 : (('s, _menhir_box_program) _menhir_cell1_CONST _menhir_cell0_IDENT, _menhir_box_program) _menhir_state
    (** State 169.
        Stack shape : CONST IDENT.
        Start symbol: program. *)

  | MenhirState172 : (('s, _menhir_box_program) _menhir_cell1_CONST _menhir_cell0_IDENT, _menhir_box_program) _menhir_state
    (** State 172.
        Stack shape : CONST IDENT.
        Start symbol: program. *)

  | MenhirState177 : (('s, _menhir_box_program) _menhir_cell1_MAYBE, _menhir_box_program) _menhir_state
    (** State 177.
        Stack shape : MAYBE.
        Start symbol: program. *)

  | MenhirState178 : (('s, _menhir_box_program) _menhir_cell1_LBRACKET, _menhir_box_program) _menhir_state
    (** State 178.
        Stack shape : LBRACKET.
        Start symbol: program. *)

  | MenhirState184 : ((('s, _menhir_box_program) _menhir_cell1_CONST _menhir_cell0_IDENT, _menhir_box_program) _menhir_cell1_typ, _menhir_box_program) _menhir_state
    (** State 184.
        Stack shape : CONST IDENT typ.
        Start symbol: program. *)

  | MenhirState188 : (('s, _menhir_box_program) _menhir_cell1_top_level_item, _menhir_box_program) _menhir_state
    (** State 188.
        Stack shape : top_level_item.
        Start symbol: program. *)

  | MenhirState193 : (('s, _menhir_box_program) _menhir_cell1_option_emote_tag_ _menhir_cell0_IDENT, _menhir_box_program) _menhir_state
    (** State 193.
        Stack shape : option(emote_tag) IDENT.
        Start symbol: program. *)

  | MenhirState195 : (('s, _menhir_box_program) _menhir_cell1_IDENT, _menhir_box_program) _menhir_state
    (** State 195.
        Stack shape : IDENT.
        Start symbol: program. *)

  | MenhirState200 : (('s, _menhir_box_program) _menhir_cell1_param, _menhir_box_program) _menhir_state
    (** State 200.
        Stack shape : param.
        Start symbol: program. *)

  | MenhirState204 : ((('s, _menhir_box_program) _menhir_cell1_option_emote_tag_ _menhir_cell0_IDENT, _menhir_box_program) _menhir_cell1_loption_separated_nonempty_list_COMMA_param__, _menhir_box_program) _menhir_state
    (** State 204.
        Stack shape : option(emote_tag) IDENT loption(separated_nonempty_list(COMMA,param)).
        Start symbol: program. *)

  | MenhirState211 : ((('s, _menhir_box_program) _menhir_cell1_option_emote_tag_ _menhir_cell0_IDENT, _menhir_box_program) _menhir_cell1_loption_separated_nonempty_list_COMMA_param__ _menhir_cell0_option_preceded_ARROW_typ__ _menhir_cell0_option_preceded_HELLO_terminated_STRING_SEMICOLON___, _menhir_box_program) _menhir_state
    (** State 211.
        Stack shape : option(emote_tag) IDENT loption(separated_nonempty_list(COMMA,param)) option(preceded(ARROW,typ)) option(preceded(HELLO,terminated(STRING,SEMICOLON))).
        Start symbol: program. *)


and ('s, 'r) _menhir_cell1_additive_expr = 
  | MenhirCell1_additive_expr of 's * ('s, 'r) _menhir_state * (Ast.expr)

and ('s, 'r) _menhir_cell1_comparison_expr = 
  | MenhirCell1_comparison_expr of 's * ('s, 'r) _menhir_state * (Ast.expr)

and ('s, 'r) _menhir_cell1_emote_param = 
  | MenhirCell1_emote_param of 's * ('s, 'r) _menhir_state * (string * Ast.expr)

and ('s, 'r) _menhir_cell1_emote_tag = 
  | MenhirCell1_emote_tag of 's * ('s, 'r) _menhir_state * (Ast.emote_tag)

and ('s, 'r) _menhir_cell1_equality_expr = 
  | MenhirCell1_equality_expr of 's * ('s, 'r) _menhir_state * (Ast.expr)

and ('s, 'r) _menhir_cell1_expr = 
  | MenhirCell1_expr of 's * ('s, 'r) _menhir_state * (Ast.expr)

and ('s, 'r) _menhir_cell1_gratitude_entry = 
  | MenhirCell1_gratitude_entry of 's * ('s, 'r) _menhir_state * (Ast.gratitude_entry)

and ('s, 'r) _menhir_cell1_list_statement_ = 
  | MenhirCell1_list_statement_ of 's * ('s, 'r) _menhir_state * (Ast.stmt list)

and ('s, 'r) _menhir_cell1_logical_and_expr = 
  | MenhirCell1_logical_and_expr of 's * ('s, 'r) _menhir_state * (Ast.expr)

and ('s, 'r) _menhir_cell1_logical_or_expr = 
  | MenhirCell1_logical_or_expr of 's * ('s, 'r) _menhir_state * (Ast.expr)

and ('s, 'r) _menhir_cell1_loption_separated_nonempty_list_COMMA_param__ = 
  | MenhirCell1_loption_separated_nonempty_list_COMMA_param__ of 's * ('s, 'r) _menhir_state * (Ast.param list)

and ('s, 'r) _menhir_cell1_multiplicative_expr = 
  | MenhirCell1_multiplicative_expr of 's * ('s, 'r) _menhir_state * (Ast.expr)

and ('s, 'r) _menhir_cell1_option_emote_tag_ = 
  | MenhirCell1_option_emote_tag_ of 's * ('s, 'r) _menhir_state * (Ast.emote_tag option)

and 's _menhir_cell0_option_preceded_ARROW_typ__ = 
  | MenhirCell0_option_preceded_ARROW_typ__ of 's * (Ast.typ option)

and 's _menhir_cell0_option_preceded_HELLO_terminated_STRING_SEMICOLON___ = 
  | MenhirCell0_option_preceded_HELLO_terminated_STRING_SEMICOLON___ of 's * (string option)

and ('s, 'r) _menhir_cell1_param = 
  | MenhirCell1_param of 's * ('s, 'r) _menhir_state * (Ast.param)

and ('s, 'r) _menhir_cell1_statement = 
  | MenhirCell1_statement of 's * ('s, 'r) _menhir_state * (Ast.stmt)

and ('s, 'r) _menhir_cell1_top_level_item = 
  | MenhirCell1_top_level_item of 's * ('s, 'r) _menhir_state * (Ast.top_level)

and ('s, 'r) _menhir_cell1_typ = 
  | MenhirCell1_typ of 's * ('s, 'r) _menhir_state * (Ast.typ)

and ('s, 'r) _menhir_cell1_AT = 
  | MenhirCell1_AT of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_ATTEMPT = 
  | MenhirCell1_ATTEMPT of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_CONST = 
  | MenhirCell1_CONST of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_GIVE = 
  | MenhirCell1_GIVE of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_IDENT = 
  | MenhirCell1_IDENT of 's * ('s, 'r) _menhir_state * 
# 57 "core/parser.mly"
       (string)
# 447 "core/parser.ml"


and 's _menhir_cell0_IDENT = 
  | MenhirCell0_IDENT of 's * 
# 57 "core/parser.mly"
       (string)
# 454 "core/parser.ml"


and ('s, 'r) _menhir_cell1_LBRACKET = 
  | MenhirCell1_LBRACKET of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_LPAREN = 
  | MenhirCell1_LPAREN of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_MAYBE = 
  | MenhirCell1_MAYBE of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_MINUS = 
  | MenhirCell1_MINUS of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_NOT = 
  | MenhirCell1_NOT of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_ONLY = 
  | MenhirCell1_ONLY of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_REMEMBER = 
  | MenhirCell1_REMEMBER of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_REPEAT = 
  | MenhirCell1_REPEAT of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_SAY = 
  | MenhirCell1_SAY of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_SIDE = 
  | MenhirCell1_SIDE of 's * ('s, 'r) _menhir_state

and 's _menhir_cell0_STRING = 
  | MenhirCell0_STRING of 's * 
# 56 "core/parser.mly"
       (string)
# 491 "core/parser.ml"


and ('s, 'r) _menhir_cell1_THANKS = 
  | MenhirCell1_THANKS of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_WHEN = 
  | MenhirCell1_WHEN of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_WORKER = 
  | MenhirCell1_WORKER of 's * ('s, 'r) _menhir_state

and _menhir_box_program = 
  | MenhirBox_program of (Ast.program) [@@unboxed]

let _menhir_action_001 =
  fun left right ->
    (
# 230 "core/parser.mly"
    ( EBinOp (OpAdd, left, right) )
# 511 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_002 =
  fun left right ->
    (
# 232 "core/parser.mly"
    ( EBinOp (OpSub, left, right) )
# 519 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_003 =
  fun e ->
    (
# 233 "core/parser.mly"
                            ( e )
# 527 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_004 =
  fun left right ->
    (
# 218 "core/parser.mly"
    ( EBinOp (OpLt, left, right) )
# 535 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_005 =
  fun left right ->
    (
# 220 "core/parser.mly"
    ( EBinOp (OpGt, left, right) )
# 543 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_006 =
  fun left right ->
    (
# 222 "core/parser.mly"
    ( EBinOp (OpLe, left, right) )
# 551 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_007 =
  fun left right ->
    (
# 224 "core/parser.mly"
    ( EBinOp (OpGe, left, right) )
# 559 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_008 =
  fun e ->
    (
# 225 "core/parser.mly"
                      ( e )
# 567 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_009 =
  fun cond else_body then_body ->
    (
# 180 "core/parser.mly"
    ( SWhen (cond, then_body, else_body) )
# 575 "core/parser.ml"
     : (Ast.stmt))

let _menhir_action_010 =
  fun body n ->
    (
# 182 "core/parser.mly"
    ( SRepeat (n, body) )
# 583 "core/parser.ml"
     : (Ast.stmt))

let _menhir_action_011 =
  fun body msg ->
    (
# 185 "core/parser.mly"
    ( SAttempt (body, msg) )
# 591 "core/parser.ml"
     : (Ast.stmt))

let _menhir_action_012 =
  fun body perm ->
    (
# 187 "core/parser.mly"
    ( SConsent (perm, body) )
# 599 "core/parser.ml"
     : (Ast.stmt))

let _menhir_action_013 =
  fun emote s ->
    (
# 189 "core/parser.mly"
    ( SEmoteAnnotated (emote, s) )
# 607 "core/parser.ml"
     : (Ast.stmt))

let _menhir_action_014 =
  fun e name t ->
    (
# 136 "core/parser.mly"
    ( TLConst (name, Some t, e) )
# 615 "core/parser.ml"
     : (Ast.top_level))

let _menhir_action_015 =
  fun e name ->
    (
# 138 "core/parser.mly"
    ( TLConst (name, None, e) )
# 623 "core/parser.ml"
     : (Ast.top_level))

let _menhir_action_016 =
  fun e name ->
    (
# 151 "core/parser.mly"
                                   ( (name, e) )
# 631 "core/parser.ml"
     : (string * Ast.expr))

let _menhir_action_017 =
  fun params ->
    (
# 147 "core/parser.mly"
                                                         ( params )
# 639 "core/parser.ml"
     : ((string * Ast.expr) list))

let _menhir_action_018 =
  fun name params ->
    (
# 143 "core/parser.mly"
    ( { name; params = Option.value ~default:[] params } )
# 647 "core/parser.ml"
     : (Ast.emote_tag))

let _menhir_action_019 =
  fun left right ->
    (
# 210 "core/parser.mly"
    ( EBinOp (OpEq, left, right) )
# 655 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_020 =
  fun left right ->
    (
# 212 "core/parser.mly"
    ( EBinOp (OpNe, left, right) )
# 663 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_021 =
  fun e ->
    (
# 213 "core/parser.mly"
                        ( e )
# 671 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_022 =
  fun e ->
    (
# 193 "core/parser.mly"
                        ( e )
# 679 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_023 =
  fun body emote goodbye_msg hello_msg name ret xs ->
    let params = 
# 241 "<standard.mly>"
    ( xs )
# 687 "core/parser.ml"
     in
    (
# 97 "core/parser.mly"
    ( { name; params; return_type = ret; hello_msg; body; goodbye_msg; emote } )
# 692 "core/parser.ml"
     : (Ast.func_def))

let _menhir_action_024 =
  fun entries ->
    (
# 116 "core/parser.mly"
    ( entries )
# 700 "core/parser.ml"
     : (Ast.gratitude_entry list))

let _menhir_action_025 =
  fun contribution contributor ->
    (
# 121 "core/parser.mly"
    ( { contributor; contribution } )
# 708 "core/parser.ml"
     : (Ast.gratitude_entry))

let _menhir_action_026 =
  fun () ->
    (
# 216 "<standard.mly>"
    ( [] )
# 716 "core/parser.ml"
     : (Ast.gratitude_entry list))

let _menhir_action_027 =
  fun x xs ->
    (
# 219 "<standard.mly>"
    ( x :: xs )
# 724 "core/parser.ml"
     : (Ast.gratitude_entry list))

let _menhir_action_028 =
  fun () ->
    (
# 216 "<standard.mly>"
    ( [] )
# 732 "core/parser.ml"
     : (Ast.stmt list))

let _menhir_action_029 =
  fun x xs ->
    (
# 219 "<standard.mly>"
    ( x :: xs )
# 740 "core/parser.ml"
     : (Ast.stmt list))

let _menhir_action_030 =
  fun () ->
    (
# 216 "<standard.mly>"
    ( [] )
# 748 "core/parser.ml"
     : (Ast.program))

let _menhir_action_031 =
  fun x xs ->
    (
# 219 "<standard.mly>"
    ( x :: xs )
# 756 "core/parser.ml"
     : (Ast.program))

let _menhir_action_032 =
  fun left right ->
    (
# 204 "core/parser.mly"
    ( EBinOp (OpAnd, left, right) )
# 764 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_033 =
  fun e ->
    (
# 205 "core/parser.mly"
                      ( e )
# 772 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_034 =
  fun left right ->
    (
# 198 "core/parser.mly"
    ( EBinOp (OpOr, left, right) )
# 780 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_035 =
  fun e ->
    (
# 199 "core/parser.mly"
                         ( e )
# 788 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_036 =
  fun () ->
    (
# 145 "<standard.mly>"
    ( [] )
# 796 "core/parser.ml"
     : (Ast.expr list))

let _menhir_action_037 =
  fun x ->
    (
# 148 "<standard.mly>"
    ( x )
# 804 "core/parser.ml"
     : (Ast.expr list))

let _menhir_action_038 =
  fun () ->
    (
# 145 "<standard.mly>"
    ( [] )
# 812 "core/parser.ml"
     : (Ast.param list))

let _menhir_action_039 =
  fun x ->
    (
# 148 "<standard.mly>"
    ( x )
# 820 "core/parser.ml"
     : (Ast.param list))

let _menhir_action_040 =
  fun left right ->
    (
# 238 "core/parser.mly"
    ( EBinOp (OpMul, left, right) )
# 828 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_041 =
  fun left right ->
    (
# 240 "core/parser.mly"
    ( EBinOp (OpDiv, left, right) )
# 836 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_042 =
  fun left right ->
    (
# 242 "core/parser.mly"
    ( EBinOp (OpMod, left, right) )
# 844 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_043 =
  fun e ->
    (
# 243 "core/parser.mly"
                   ( e )
# 852 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_044 =
  fun () ->
    (
# 111 "<standard.mly>"
    ( None )
# 860 "core/parser.ml"
     : ((string * Ast.expr) list option))

let _menhir_action_045 =
  fun x ->
    let x = 
# 205 "<standard.mly>"
    ( x )
# 868 "core/parser.ml"
     in
    (
# 114 "<standard.mly>"
    ( Some x )
# 873 "core/parser.ml"
     : ((string * Ast.expr) list option))

let _menhir_action_046 =
  fun () ->
    (
# 111 "<standard.mly>"
    ( None )
# 881 "core/parser.ml"
     : (Ast.emote_tag option))

let _menhir_action_047 =
  fun x ->
    (
# 114 "<standard.mly>"
    ( Some x )
# 889 "core/parser.ml"
     : (Ast.emote_tag option))

let _menhir_action_048 =
  fun () ->
    (
# 111 "<standard.mly>"
    ( None )
# 897 "core/parser.ml"
     : (Ast.typ option))

let _menhir_action_049 =
  fun x ->
    let x = 
# 188 "<standard.mly>"
    ( x )
# 905 "core/parser.ml"
     in
    (
# 114 "<standard.mly>"
    ( Some x )
# 910 "core/parser.ml"
     : (Ast.typ option))

let _menhir_action_050 =
  fun () ->
    (
# 111 "<standard.mly>"
    ( None )
# 918 "core/parser.ml"
     : (Ast.typ option))

let _menhir_action_051 =
  fun x ->
    let x = 
# 188 "<standard.mly>"
    ( x )
# 926 "core/parser.ml"
     in
    (
# 114 "<standard.mly>"
    ( Some x )
# 931 "core/parser.ml"
     : (Ast.typ option))

let _menhir_action_052 =
  fun () ->
    (
# 111 "<standard.mly>"
    ( None )
# 939 "core/parser.ml"
     : (string option))

let _menhir_action_053 =
  fun x ->
    let x =
      let x = 
# 196 "<standard.mly>"
    ( x )
# 948 "core/parser.ml"
       in
      
# 188 "<standard.mly>"
    ( x )
# 953 "core/parser.ml"
      
    in
    (
# 114 "<standard.mly>"
    ( Some x )
# 959 "core/parser.ml"
     : (string option))

let _menhir_action_054 =
  fun () ->
    (
# 111 "<standard.mly>"
    ( None )
# 967 "core/parser.ml"
     : (string option))

let _menhir_action_055 =
  fun x ->
    let x =
      let x = 
# 196 "<standard.mly>"
    ( x )
# 976 "core/parser.ml"
       in
      
# 188 "<standard.mly>"
    ( x )
# 981 "core/parser.ml"
      
    in
    (
# 114 "<standard.mly>"
    ( Some x )
# 987 "core/parser.ml"
     : (string option))

let _menhir_action_056 =
  fun () ->
    (
# 111 "<standard.mly>"
    ( None )
# 995 "core/parser.ml"
     : (Ast.stmt list option))

let _menhir_action_057 =
  fun x ->
    let x =
      let x = 
# 205 "<standard.mly>"
    ( x )
# 1004 "core/parser.ml"
       in
      
# 188 "<standard.mly>"
    ( x )
# 1009 "core/parser.ml"
      
    in
    (
# 114 "<standard.mly>"
    ( Some x )
# 1015 "core/parser.ml"
     : (Ast.stmt list option))

let _menhir_action_058 =
  fun () ->
    (
# 111 "<standard.mly>"
    ( None )
# 1023 "core/parser.ml"
     : (string option))

let _menhir_action_059 =
  fun x x_inlined1 y ->
    let x =
      let _1 =
        let x = x_inlined1 in
        
# 172 "<standard.mly>"
    ( (x, y) )
# 1034 "core/parser.ml"
        
      in
      
# 188 "<standard.mly>"
    ( x )
# 1040 "core/parser.ml"
      
    in
    (
# 114 "<standard.mly>"
    ( Some x )
# 1046 "core/parser.ml"
     : (string option))

let _menhir_action_060 =
  fun name t ->
    (
# 101 "core/parser.mly"
                                                   ( { name; typ = t } )
# 1054 "core/parser.ml"
     : (Ast.param))

let _menhir_action_061 =
  fun n ->
    (
# 253 "core/parser.mly"
            ( EInt n )
# 1062 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_062 =
  fun f ->
    (
# 254 "core/parser.mly"
              ( EFloat f )
# 1070 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_063 =
  fun s ->
    (
# 255 "core/parser.mly"
               ( EString s )
# 1078 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_064 =
  fun () ->
    (
# 256 "core/parser.mly"
         ( EBool true )
# 1086 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_065 =
  fun () ->
    (
# 257 "core/parser.mly"
          ( EBool false )
# 1094 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_066 =
  fun name xs ->
    let args = 
# 241 "<standard.mly>"
    ( xs )
# 1102 "core/parser.ml"
     in
    (
# 259 "core/parser.mly"
    ( ECall (name, args) )
# 1107 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_067 =
  fun name ->
    (
# 260 "core/parser.mly"
                 ( EIdent name )
# 1115 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_068 =
  fun xs ->
    let elems = 
# 241 "<standard.mly>"
    ( xs )
# 1123 "core/parser.ml"
     in
    (
# 261 "core/parser.mly"
                                                            ( EArray elems )
# 1128 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_069 =
  fun e ->
    (
# 262 "core/parser.mly"
                             ( e )
# 1136 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_070 =
  fun e unit ->
    (
# 263 "core/parser.mly"
                                                 ( EMeasured (e, unit) )
# 1144 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_071 =
  fun s ->
    (
# 264 "core/parser.mly"
                                       ( EThanks s )
# 1152 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_072 =
  fun items ->
    (
# 77 "core/parser.mly"
                                      ( items )
# 1160 "core/parser.ml"
     : (Ast.program))

let _menhir_action_073 =
  fun x ->
    (
# 250 "<standard.mly>"
    ( [ x ] )
# 1168 "core/parser.ml"
     : ((string * Ast.expr) list))

let _menhir_action_074 =
  fun x xs ->
    (
# 253 "<standard.mly>"
    ( x :: xs )
# 1176 "core/parser.ml"
     : ((string * Ast.expr) list))

let _menhir_action_075 =
  fun x ->
    (
# 250 "<standard.mly>"
    ( [ x ] )
# 1184 "core/parser.ml"
     : (Ast.expr list))

let _menhir_action_076 =
  fun x xs ->
    (
# 253 "<standard.mly>"
    ( x :: xs )
# 1192 "core/parser.ml"
     : (Ast.expr list))

let _menhir_action_077 =
  fun x ->
    (
# 250 "<standard.mly>"
    ( [ x ] )
# 1200 "core/parser.ml"
     : (Ast.param list))

let _menhir_action_078 =
  fun x xs ->
    (
# 253 "<standard.mly>"
    ( x :: xs )
# 1208 "core/parser.ml"
     : (Ast.param list))

let _menhir_action_079 =
  fun body name ->
    (
# 131 "core/parser.mly"
    ( { quest_name = name; quest_body = body } )
# 1216 "core/parser.ml"
     : (Ast.side_quest_def))

let _menhir_action_080 =
  fun e name unit ->
    (
# 162 "core/parser.mly"
    ( SRemember (name, e, unit) )
# 1224 "core/parser.ml"
     : (Ast.stmt))

let _menhir_action_081 =
  fun e name ->
    (
# 164 "core/parser.mly"
    ( SAssign (name, e) )
# 1232 "core/parser.ml"
     : (Ast.stmt))

let _menhir_action_082 =
  fun e ->
    (
# 166 "core/parser.mly"
    ( SGiveBack e )
# 1240 "core/parser.ml"
     : (Ast.stmt))

let _menhir_action_083 =
  fun e ->
    (
# 168 "core/parser.mly"
    ( SExpr e )
# 1248 "core/parser.ml"
     : (Ast.stmt))

let _menhir_action_084 =
  fun msg ->
    (
# 170 "core/parser.mly"
    ( SComplain msg )
# 1256 "core/parser.ml"
     : (Ast.stmt))

let _menhir_action_085 =
  fun name ->
    (
# 172 "core/parser.mly"
    ( SSpawnWorker name )
# 1264 "core/parser.ml"
     : (Ast.stmt))

let _menhir_action_086 =
  fun e ->
    (
# 174 "core/parser.mly"
    ( SExpr (ECall ("say", [e])) )
# 1272 "core/parser.ml"
     : (Ast.stmt))

let _menhir_action_087 =
  fun s ->
    (
# 155 "core/parser.mly"
                         ( s )
# 1280 "core/parser.ml"
     : (Ast.stmt))

let _menhir_action_088 =
  fun s ->
    (
# 156 "core/parser.mly"
                           ( s )
# 1288 "core/parser.ml"
     : (Ast.stmt))

let _menhir_action_089 =
  fun f ->
    (
# 81 "core/parser.mly"
                     ( TLFunction f )
# 1296 "core/parser.ml"
     : (Ast.top_level))

let _menhir_action_090 =
  fun g ->
    (
# 82 "core/parser.mly"
                        ( TLGratitude g )
# 1304 "core/parser.ml"
     : (Ast.top_level))

let _menhir_action_091 =
  fun w ->
    (
# 83 "core/parser.mly"
                   ( TLWorker w )
# 1312 "core/parser.ml"
     : (Ast.top_level))

let _menhir_action_092 =
  fun s ->
    (
# 84 "core/parser.mly"
                       ( TLSideQuest s )
# 1320 "core/parser.ml"
     : (Ast.top_level))

let _menhir_action_093 =
  fun c ->
    (
# 85 "core/parser.mly"
                  ( c )
# 1328 "core/parser.ml"
     : (Ast.top_level))

let _menhir_action_094 =
  fun () ->
    (
# 105 "core/parser.mly"
                ( TString )
# 1336 "core/parser.ml"
     : (Ast.typ))

let _menhir_action_095 =
  fun () ->
    (
# 106 "core/parser.mly"
             ( TInt )
# 1344 "core/parser.ml"
     : (Ast.typ))

let _menhir_action_096 =
  fun () ->
    (
# 107 "core/parser.mly"
               ( TFloat )
# 1352 "core/parser.ml"
     : (Ast.typ))

let _menhir_action_097 =
  fun () ->
    (
# 108 "core/parser.mly"
              ( TBool )
# 1360 "core/parser.ml"
     : (Ast.typ))

let _menhir_action_098 =
  fun t ->
    (
# 109 "core/parser.mly"
                                ( TArray t )
# 1368 "core/parser.ml"
     : (Ast.typ))

let _menhir_action_099 =
  fun t ->
    (
# 110 "core/parser.mly"
                   ( TMaybe t )
# 1376 "core/parser.ml"
     : (Ast.typ))

let _menhir_action_100 =
  fun name ->
    (
# 111 "core/parser.mly"
                 ( TCustom name )
# 1384 "core/parser.ml"
     : (Ast.typ))

let _menhir_action_101 =
  fun e ->
    (
# 247 "core/parser.mly"
                        ( EUnaryOp (OpNot, e) )
# 1392 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_102 =
  fun e ->
    (
# 248 "core/parser.mly"
                                       ( EUnaryOp (OpNeg, e) )
# 1400 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_103 =
  fun e ->
    (
# 249 "core/parser.mly"
                     ( e )
# 1408 "core/parser.ml"
     : (Ast.expr))

let _menhir_action_104 =
  fun body name ->
    (
# 126 "core/parser.mly"
    ( { worker_name = name; worker_body = body } )
# 1416 "core/parser.ml"
     : (Ast.worker_def))

let _menhir_print_token : token -> string =
  fun _tok ->
    match _tok with
    | WORKER ->
        "WORKER"
    | WHEN ->
        "WHEN"
    | VERBOSE ->
        "VERBOSE"
    | USE ->
        "USE"
    | UNDERSCORE ->
        "UNDERSCORE"
    | TYPE_STRING ->
        "TYPE_STRING"
    | TYPE_INT ->
        "TYPE_INT"
    | TYPE_FLOAT ->
        "TYPE_FLOAT"
    | TYPE_BOOL ->
        "TYPE_BOOL"
    | TYPE ->
        "TYPE"
    | TRUE ->
        "TRUE"
    | TO ->
        "TO"
    | TIMES ->
        "TIMES"
    | THANKS ->
        "THANKS"
    | SUPERPOWER ->
        "SUPERPOWER"
    | STRING _ ->
        "STRING"
    | STRICT ->
        "STRICT"
    | STAR ->
        "STAR"
    | SPAWN ->
        "SPAWN"
    | SLASH ->
        "SLASH"
    | SIDE ->
        "SIDE"
    | SEMICOLON ->
        "SEMICOLON"
    | SAY ->
        "SAY"
    | SAFELY ->
        "SAFELY"
    | RPAREN ->
        "RPAREN"
    | REPEAT ->
        "REPEAT"
    | RENAMED ->
        "RENAMED"
    | REMEMBER ->
        "REMEMBER"
    | REASSURE ->
        "REASSURE"
    | RBRACKET ->
        "RBRACKET"
    | RBRACE ->
        "RBRACE"
    | QUEST ->
        "QUEST"
    | PLUS ->
        "PLUS"
    | PERCENT ->
        "PERCENT"
    | OTHERWISE ->
        "OTHERWISE"
    | OR ->
        "OR"
    | ONLY ->
        "ONLY"
    | ON ->
        "ON"
    | OKAY ->
        "OKAY"
    | NOT ->
        "NOT"
    | NE ->
        "NE"
    | MUST ->
        "MUST"
    | MINUS ->
        "MINUS"
    | MEASURED ->
        "MEASURED"
    | MAYBE ->
        "MAYBE"
    | LT ->
        "LT"
    | LPAREN ->
        "LPAREN"
    | LE ->
        "LE"
    | LBRACKET ->
        "LBRACKET"
    | LBRACE ->
        "LBRACE"
    | INT _ ->
        "INT"
    | IN ->
        "IN"
    | IF ->
        "IF"
    | IDENT _ ->
        "IDENT"
    | HELLO ->
        "HELLO"
    | HAVE ->
        "HAVE"
    | HASH ->
        "HASH"
    | GT ->
        "GT"
    | GOODBYE ->
        "GOODBYE"
    | GIVE ->
        "GIVE"
    | GE ->
        "GE"
    | FLOAT _ ->
        "FLOAT"
    | FALSE ->
        "FALSE"
    | EQUALS ->
        "EQUALS"
    | EQEQ ->
        "EQEQ"
    | EOF ->
        "EOF"
    | DECIDE ->
        "DECIDE"
    | CONST ->
        "CONST"
    | COMPLAIN ->
        "COMPLAIN"
    | COMMA ->
        "COMMA"
    | COLON ->
        "COLON"
    | CARE ->
        "CARE"
    | BASED ->
        "BASED"
    | BACK ->
        "BACK"
    | ATTEMPT ->
        "ATTEMPT"
    | AT ->
        "AT"
    | ARROW ->
        "ARROW"
    | AND ->
        "AND"

let _menhir_fail : unit -> 'a =
  fun () ->
    Printf.eprintf "Internal failure -- please contact the parser generator's developers.\n%!";
    assert false

include struct
  
  [@@@ocaml.warning "-4-37"]
  
  let _menhir_run_224 : type  ttv_stack. ttv_stack -> _ -> _menhir_box_program =
    fun _menhir_stack _v ->
      let items = _v in
      let _v = _menhir_action_072 items in
      MenhirBox_program _v
  
  let rec _menhir_run_218 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_top_level_item -> _ -> _menhir_box_program =
    fun _menhir_stack _v ->
      let MenhirCell1_top_level_item (_menhir_stack, _menhir_s, x) = _menhir_stack in
      let xs = _v in
      let _v = _menhir_action_031 x xs in
      _menhir_goto_list_top_level_item_ _menhir_stack _v _menhir_s
  
  and _menhir_goto_list_top_level_item_ : type  ttv_stack. ttv_stack -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _v _menhir_s ->
      match _menhir_s with
      | MenhirState188 ->
          _menhir_run_218 _menhir_stack _v
      | MenhirState000 ->
          _menhir_run_224 _menhir_stack _v
      | _ ->
          _menhir_fail ()
  
  let rec _menhir_run_001 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_WORKER (_menhir_stack, _menhir_s) in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | IDENT _v ->
          let _menhir_stack = MenhirCell0_IDENT (_menhir_stack, _v) in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | LBRACE ->
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | WHEN ->
                  _menhir_run_004 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState003
              | TRUE ->
                  _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState003
              | THANKS ->
                  _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState003
              | STRING _v_0 ->
                  _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v_0 MenhirState003
              | SPAWN ->
                  _menhir_run_071 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState003
              | SAY ->
                  _menhir_run_075 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState003
              | REPEAT ->
                  _menhir_run_078 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState003
              | REMEMBER ->
                  _menhir_run_082 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState003
              | ONLY ->
                  _menhir_run_091 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState003
              | NOT ->
                  _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState003
              | MINUS ->
                  _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState003
              | LPAREN ->
                  _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState003
              | LBRACKET ->
                  _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState003
              | INT _v_1 ->
                  _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v_1 MenhirState003
              | IDENT _v_2 ->
                  _menhir_run_096 _menhir_stack _menhir_lexbuf _menhir_lexer _v_2 MenhirState003
              | GIVE ->
                  _menhir_run_100 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState003
              | FLOAT _v_3 ->
                  _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v_3 MenhirState003
              | FALSE ->
                  _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState003
              | COMPLAIN ->
                  _menhir_run_104 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState003
              | ATTEMPT ->
                  _menhir_run_107 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState003
              | AT ->
                  _menhir_run_110 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState003
              | RBRACE ->
                  let _v_4 = _menhir_action_028 () in
                  _menhir_run_148 _menhir_stack _menhir_lexbuf _menhir_lexer _v_4 _tok
              | _ ->
                  _eRR ())
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_004 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_WHEN (_menhir_stack, _menhir_s) in
      let _menhir_s = MenhirState004 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | STRING _v ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | IDENT _v ->
          _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FLOAT _v ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_005 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      let _v = _menhir_action_064 () in
      _menhir_goto_primary_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_goto_primary_expr : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | MEASURED ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | IN ->
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | IDENT _v_0 ->
                  let _tok = _menhir_lexer _menhir_lexbuf in
                  let (e, unit) = (_v, _v_0) in
                  let _v = _menhir_action_070 e unit in
                  _menhir_goto_primary_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
              | _ ->
                  _eRR ())
          | _ ->
              _eRR ())
      | AND | COMMA | EQEQ | GE | GT | LBRACE | LE | LT | MINUS | NE | OR | PERCENT | PLUS | RBRACKET | RPAREN | SEMICOLON | SLASH | STAR | TIMES ->
          let e = _v in
          let _v = _menhir_action_103 e in
          _menhir_goto_unary_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_goto_unary_expr : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match _menhir_s with
      | MenhirState003 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState004 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState013 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState014 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState017 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState036 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState038 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState040 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState042 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState044 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState046 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState048 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState050 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState052 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState055 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState061 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState070 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState075 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState078 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState081 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState084 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState095 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState097 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState101 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState109 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState114 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState123 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState128 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState144 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState164 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState169 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState184 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState211 ->
          _menhir_run_020 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState027 ->
          _menhir_run_028 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState029 ->
          _menhir_run_030 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState031 ->
          _menhir_run_032 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState012 ->
          _menhir_run_067 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState011 ->
          _menhir_run_068 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_020 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let e = _v in
      let _v = _menhir_action_043 e in
      _menhir_goto_multiplicative_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_goto_multiplicative_expr : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match _menhir_s with
      | MenhirState003 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState004 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState013 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState014 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState017 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState036 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState038 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState040 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState042 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState048 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState050 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState052 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState055 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState061 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState070 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState075 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState078 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState081 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState084 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState095 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState097 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState101 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState109 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState114 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState123 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState128 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState144 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState164 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState169 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState184 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState211 ->
          _menhir_run_026 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState044 ->
          _menhir_run_045 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState046 ->
          _menhir_run_047 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_026 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | STAR ->
          let _menhir_stack = MenhirCell1_multiplicative_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_027 _menhir_stack _menhir_lexbuf _menhir_lexer
      | SLASH ->
          let _menhir_stack = MenhirCell1_multiplicative_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_029 _menhir_stack _menhir_lexbuf _menhir_lexer
      | PERCENT ->
          let _menhir_stack = MenhirCell1_multiplicative_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_031 _menhir_stack _menhir_lexbuf _menhir_lexer
      | AND | COMMA | EQEQ | GE | GT | LBRACE | LE | LT | MEASURED | MINUS | NE | OR | PLUS | RBRACKET | RPAREN | SEMICOLON | TIMES ->
          let e = _v in
          let _v = _menhir_action_003 e in
          _menhir_goto_additive_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_027 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_multiplicative_expr -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState027 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | STRING _v ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | IDENT _v ->
          _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FLOAT _v ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_006 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | LPAREN ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | STRING _v ->
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | RPAREN ->
                  let _tok = _menhir_lexer _menhir_lexbuf in
                  let s = _v in
                  let _v = _menhir_action_071 s in
                  _menhir_goto_primary_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
              | _ ->
                  _eRR ())
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_010 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      let s = _v in
      let _v = _menhir_action_063 s in
      _menhir_goto_primary_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_011 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_NOT (_menhir_stack, _menhir_s) in
      let _menhir_s = MenhirState011 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | STRING _v ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | IDENT _v ->
          _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FLOAT _v ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_012 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_MINUS (_menhir_stack, _menhir_s) in
      let _menhir_s = MenhirState012 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | STRING _v ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | IDENT _v ->
          _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FLOAT _v ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_013 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_LPAREN (_menhir_stack, _menhir_s) in
      let _menhir_s = MenhirState013 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | STRING _v ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | IDENT _v ->
          _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FLOAT _v ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_014 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_LBRACKET (_menhir_stack, _menhir_s) in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState014
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState014
      | STRING _v ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v MenhirState014
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState014
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState014
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState014
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState014
      | INT _v ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v MenhirState014
      | IDENT _v ->
          _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v MenhirState014
      | FLOAT _v ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v MenhirState014
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState014
      | RBRACKET ->
          let _v = _menhir_action_036 () in
          _menhir_run_063 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_015 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      let n = _v in
      let _v = _menhir_action_061 n in
      _menhir_goto_primary_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_016 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | LPAREN ->
          let _menhir_stack = MenhirCell1_IDENT (_menhir_stack, _menhir_s, _v) in
          _menhir_run_017 _menhir_stack _menhir_lexbuf _menhir_lexer
      | AND | COMMA | EQEQ | GE | GT | LBRACE | LE | LT | MEASURED | MINUS | NE | OR | PERCENT | PLUS | RBRACKET | RPAREN | SEMICOLON | SLASH | STAR | TIMES ->
          let name = _v in
          let _v = _menhir_action_067 name in
          _menhir_goto_primary_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_017 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_IDENT -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState017
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState017
      | STRING _v ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v MenhirState017
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState017
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState017
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState017
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState017
      | INT _v ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v MenhirState017
      | IDENT _v ->
          _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v MenhirState017
      | FLOAT _v ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v MenhirState017
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState017
      | RPAREN ->
          let _v = _menhir_action_036 () in
          _menhir_run_033 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_018 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      let f = _v in
      let _v = _menhir_action_062 f in
      _menhir_goto_primary_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_019 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      let _v = _menhir_action_065 () in
      _menhir_goto_primary_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_033 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_IDENT -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      match (_tok : MenhirBasics.token) with
      | RPAREN ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let MenhirCell1_IDENT (_menhir_stack, _menhir_s, name) = _menhir_stack in
          let xs = _v in
          let _v = _menhir_action_066 name xs in
          _menhir_goto_primary_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_063 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_LBRACKET -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      match (_tok : MenhirBasics.token) with
      | RBRACKET ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let MenhirCell1_LBRACKET (_menhir_stack, _menhir_s) = _menhir_stack in
          let xs = _v in
          let _v = _menhir_action_068 xs in
          _menhir_goto_primary_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_029 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_multiplicative_expr -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState029 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | STRING _v ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | IDENT _v ->
          _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FLOAT _v ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_031 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_multiplicative_expr -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState031 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | STRING _v ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | IDENT _v ->
          _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FLOAT _v ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_goto_additive_expr : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match _menhir_s with
      | MenhirState042 ->
          _menhir_run_043 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState048 ->
          _menhir_run_049 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState050 ->
          _menhir_run_051 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState052 ->
          _menhir_run_053 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState003 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState004 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState013 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState014 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState017 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState036 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState038 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState040 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState055 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState061 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState070 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState075 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState078 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState081 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState084 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState095 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState097 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState101 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState109 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState114 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState123 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState128 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState144 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState164 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState169 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState184 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState211 ->
          _menhir_run_054 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_043 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_comparison_expr as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | PLUS ->
          let _menhir_stack = MenhirCell1_additive_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_044 _menhir_stack _menhir_lexbuf _menhir_lexer
      | MINUS ->
          let _menhir_stack = MenhirCell1_additive_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_046 _menhir_stack _menhir_lexbuf _menhir_lexer
      | AND | COMMA | EQEQ | GE | GT | LBRACE | LE | LT | MEASURED | NE | OR | RBRACKET | RPAREN | SEMICOLON | TIMES ->
          let MenhirCell1_comparison_expr (_menhir_stack, _menhir_s, left) = _menhir_stack in
          let right = _v in
          let _v = _menhir_action_004 left right in
          _menhir_goto_comparison_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_044 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_additive_expr -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState044 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | STRING _v ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | IDENT _v ->
          _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FLOAT _v ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_046 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_additive_expr -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState046 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | STRING _v ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | IDENT _v ->
          _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FLOAT _v ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_goto_comparison_expr : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match _menhir_s with
      | MenhirState040 ->
          _menhir_run_041 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState055 ->
          _menhir_run_056 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState003 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState004 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState013 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState014 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState017 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState036 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState038 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState061 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState070 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState075 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState078 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState081 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState084 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState095 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState097 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState101 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState109 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState114 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState123 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState128 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState144 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState164 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState169 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState184 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState211 ->
          _menhir_run_057 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_041 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_equality_expr as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | LT ->
          let _menhir_stack = MenhirCell1_comparison_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_042 _menhir_stack _menhir_lexbuf _menhir_lexer
      | LE ->
          let _menhir_stack = MenhirCell1_comparison_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_048 _menhir_stack _menhir_lexbuf _menhir_lexer
      | GT ->
          let _menhir_stack = MenhirCell1_comparison_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_050 _menhir_stack _menhir_lexbuf _menhir_lexer
      | GE ->
          let _menhir_stack = MenhirCell1_comparison_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_052 _menhir_stack _menhir_lexbuf _menhir_lexer
      | AND | COMMA | EQEQ | LBRACE | MEASURED | NE | OR | RBRACKET | RPAREN | SEMICOLON | TIMES ->
          let MenhirCell1_equality_expr (_menhir_stack, _menhir_s, left) = _menhir_stack in
          let right = _v in
          let _v = _menhir_action_020 left right in
          _menhir_goto_equality_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_042 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_comparison_expr -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState042 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | STRING _v ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | IDENT _v ->
          _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FLOAT _v ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_048 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_comparison_expr -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState048 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | STRING _v ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | IDENT _v ->
          _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FLOAT _v ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_050 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_comparison_expr -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState050 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | STRING _v ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | IDENT _v ->
          _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FLOAT _v ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_052 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_comparison_expr -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState052 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | STRING _v ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | IDENT _v ->
          _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FLOAT _v ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_goto_equality_expr : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match _menhir_s with
      | MenhirState038 ->
          _menhir_run_039 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState003 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState004 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState013 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState014 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState017 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState036 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState061 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState070 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState075 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState078 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState081 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState084 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState095 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState097 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState101 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState109 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState114 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState123 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState128 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState144 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState164 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState169 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState184 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState211 ->
          _menhir_run_058 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_039 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_logical_and_expr as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | NE ->
          let _menhir_stack = MenhirCell1_equality_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_040 _menhir_stack _menhir_lexbuf _menhir_lexer
      | EQEQ ->
          let _menhir_stack = MenhirCell1_equality_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_055 _menhir_stack _menhir_lexbuf _menhir_lexer
      | AND | COMMA | LBRACE | MEASURED | OR | RBRACKET | RPAREN | SEMICOLON | TIMES ->
          let MenhirCell1_logical_and_expr (_menhir_stack, _menhir_s, left) = _menhir_stack in
          let right = _v in
          let _v = _menhir_action_032 left right in
          _menhir_goto_logical_and_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_040 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_equality_expr -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState040 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | STRING _v ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | IDENT _v ->
          _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FLOAT _v ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_055 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_equality_expr -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState055 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | STRING _v ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | IDENT _v ->
          _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FLOAT _v ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_goto_logical_and_expr : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match _menhir_s with
      | MenhirState036 ->
          _menhir_run_037 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState003 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState004 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState013 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState014 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState017 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState061 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState070 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState075 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState078 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState081 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState084 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState095 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState097 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState101 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState109 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState114 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState123 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState128 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState144 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState164 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState169 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState184 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState211 ->
          _menhir_run_059 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_037 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_logical_or_expr as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | AND ->
          let _menhir_stack = MenhirCell1_logical_and_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_038 _menhir_stack _menhir_lexbuf _menhir_lexer
      | COMMA | LBRACE | MEASURED | OR | RBRACKET | RPAREN | SEMICOLON | TIMES ->
          let MenhirCell1_logical_or_expr (_menhir_stack, _menhir_s, left) = _menhir_stack in
          let right = _v in
          let _v = _menhir_action_034 left right in
          _menhir_goto_logical_or_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_038 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_logical_and_expr -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState038 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | STRING _v ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | IDENT _v ->
          _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FLOAT _v ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_goto_logical_or_expr : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | OR ->
          let _menhir_stack = MenhirCell1_logical_or_expr (_menhir_stack, _menhir_s, _v) in
          let _menhir_s = MenhirState036 in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | TRUE ->
              _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | THANKS ->
              _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | STRING _v ->
              _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | NOT ->
              _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | MINUS ->
              _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | LPAREN ->
              _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | LBRACKET ->
              _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | INT _v ->
              _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | IDENT _v ->
              _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | FLOAT _v ->
              _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | FALSE ->
              _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | _ ->
              _eRR ())
      | COMMA | LBRACE | MEASURED | RBRACKET | RPAREN | SEMICOLON | TIMES ->
          let e = _v in
          let _v = _menhir_action_022 e in
          _menhir_goto_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_goto_expr : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match _menhir_s with
      | MenhirState014 ->
          _menhir_run_060 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState017 ->
          _menhir_run_060 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState061 ->
          _menhir_run_060 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState013 ->
          _menhir_run_065 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState004 ->
          _menhir_run_069 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState075 ->
          _menhir_run_076 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState078 ->
          _menhir_run_079 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState084 ->
          _menhir_run_085 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState097 ->
          _menhir_run_098 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState101 ->
          _menhir_run_102 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState114 ->
          _menhir_run_115 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState003 ->
          _menhir_run_126 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState070 ->
          _menhir_run_126 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState081 ->
          _menhir_run_126 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState095 ->
          _menhir_run_126 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState109 ->
          _menhir_run_126 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState123 ->
          _menhir_run_126 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState128 ->
          _menhir_run_126 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState144 ->
          _menhir_run_126 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState164 ->
          _menhir_run_126 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState211 ->
          _menhir_run_126 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState169 ->
          _menhir_run_170 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState184 ->
          _menhir_run_185 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_060 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | COMMA ->
          let _menhir_stack = MenhirCell1_expr (_menhir_stack, _menhir_s, _v) in
          let _menhir_s = MenhirState061 in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | TRUE ->
              _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | THANKS ->
              _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | STRING _v ->
              _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | NOT ->
              _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | MINUS ->
              _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | LPAREN ->
              _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | LBRACKET ->
              _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | INT _v ->
              _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | IDENT _v ->
              _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | FLOAT _v ->
              _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | FALSE ->
              _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | _ ->
              _eRR ())
      | RBRACKET | RPAREN ->
          let x = _v in
          let _v = _menhir_action_075 x in
          _menhir_goto_separated_nonempty_list_COMMA_expr_ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_goto_separated_nonempty_list_COMMA_expr_ : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match _menhir_s with
      | MenhirState014 ->
          _menhir_run_021 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState017 ->
          _menhir_run_021 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState061 ->
          _menhir_run_062 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_021 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let x = _v in
      let _v = _menhir_action_037 x in
      _menhir_goto_loption_separated_nonempty_list_COMMA_expr__ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_goto_loption_separated_nonempty_list_COMMA_expr__ : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match _menhir_s with
      | MenhirState017 ->
          _menhir_run_033 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState014 ->
          _menhir_run_063 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_062 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_expr -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_expr (_menhir_stack, _menhir_s, x) = _menhir_stack in
      let xs = _v in
      let _v = _menhir_action_076 x xs in
      _menhir_goto_separated_nonempty_list_COMMA_expr_ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_065 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_LPAREN -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      match (_tok : MenhirBasics.token) with
      | RPAREN ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let MenhirCell1_LPAREN (_menhir_stack, _menhir_s) = _menhir_stack in
          let e = _v in
          let _v = _menhir_action_069 e in
          _menhir_goto_primary_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_069 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_WHEN as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let _menhir_stack = MenhirCell1_expr (_menhir_stack, _menhir_s, _v) in
      match (_tok : MenhirBasics.token) with
      | LBRACE ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | WHEN ->
              _menhir_run_004 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState070
          | TRUE ->
              _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState070
          | THANKS ->
              _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState070
          | STRING _v_0 ->
              _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v_0 MenhirState070
          | SPAWN ->
              _menhir_run_071 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState070
          | SAY ->
              _menhir_run_075 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState070
          | REPEAT ->
              _menhir_run_078 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState070
          | REMEMBER ->
              _menhir_run_082 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState070
          | ONLY ->
              _menhir_run_091 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState070
          | NOT ->
              _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState070
          | MINUS ->
              _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState070
          | LPAREN ->
              _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState070
          | LBRACKET ->
              _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState070
          | INT _v_1 ->
              _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v_1 MenhirState070
          | IDENT _v_2 ->
              _menhir_run_096 _menhir_stack _menhir_lexbuf _menhir_lexer _v_2 MenhirState070
          | GIVE ->
              _menhir_run_100 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState070
          | FLOAT _v_3 ->
              _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v_3 MenhirState070
          | FALSE ->
              _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState070
          | COMPLAIN ->
              _menhir_run_104 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState070
          | ATTEMPT ->
              _menhir_run_107 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState070
          | AT ->
              _menhir_run_110 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState070
          | RBRACE ->
              let _v_4 = _menhir_action_028 () in
              _menhir_run_141 _menhir_stack _menhir_lexbuf _menhir_lexer _v_4 MenhirState070 _tok
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_071 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | WORKER ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | IDENT _v ->
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | SEMICOLON ->
                  let _tok = _menhir_lexer _menhir_lexbuf in
                  let name = _v in
                  let _v = _menhir_action_085 name in
                  _menhir_goto_simple_statement _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
              | _ ->
                  _eRR ())
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_goto_simple_statement : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let s = _v in
      let _v = _menhir_action_087 s in
      _menhir_goto_statement _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_goto_statement : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match _menhir_s with
      | MenhirState003 ->
          _menhir_run_123 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState070 ->
          _menhir_run_123 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState081 ->
          _menhir_run_123 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState095 ->
          _menhir_run_123 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState109 ->
          _menhir_run_123 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState123 ->
          _menhir_run_123 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState144 ->
          _menhir_run_123 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState164 ->
          _menhir_run_123 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState211 ->
          _menhir_run_123 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState128 ->
          _menhir_run_129 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_123 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let _menhir_stack = MenhirCell1_statement (_menhir_stack, _menhir_s, _v) in
      match (_tok : MenhirBasics.token) with
      | WHEN ->
          _menhir_run_004 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState123
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState123
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState123
      | STRING _v_0 ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v_0 MenhirState123
      | SPAWN ->
          _menhir_run_071 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState123
      | SAY ->
          _menhir_run_075 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState123
      | REPEAT ->
          _menhir_run_078 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState123
      | REMEMBER ->
          _menhir_run_082 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState123
      | ONLY ->
          _menhir_run_091 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState123
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState123
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState123
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState123
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState123
      | INT _v_1 ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v_1 MenhirState123
      | IDENT _v_2 ->
          _menhir_run_096 _menhir_stack _menhir_lexbuf _menhir_lexer _v_2 MenhirState123
      | GIVE ->
          _menhir_run_100 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState123
      | FLOAT _v_3 ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v_3 MenhirState123
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState123
      | COMPLAIN ->
          _menhir_run_104 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState123
      | ATTEMPT ->
          _menhir_run_107 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState123
      | AT ->
          _menhir_run_110 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState123
      | GOODBYE | RBRACE ->
          let _v_4 = _menhir_action_028 () in
          _menhir_run_125 _menhir_stack _menhir_lexbuf _menhir_lexer _v_4 _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_075 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_SAY (_menhir_stack, _menhir_s) in
      let _menhir_s = MenhirState075 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | STRING _v ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | IDENT _v ->
          _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FLOAT _v ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_078 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_REPEAT (_menhir_stack, _menhir_s) in
      let _menhir_s = MenhirState078 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | STRING _v ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | IDENT _v ->
          _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FLOAT _v ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_082 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_REMEMBER (_menhir_stack, _menhir_s) in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | IDENT _v ->
          let _menhir_stack = MenhirCell0_IDENT (_menhir_stack, _v) in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | EQUALS ->
              let _menhir_s = MenhirState084 in
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | TRUE ->
                  _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | THANKS ->
                  _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | STRING _v ->
                  _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
              | NOT ->
                  _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | MINUS ->
                  _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | LPAREN ->
                  _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | LBRACKET ->
                  _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | INT _v ->
                  _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
              | IDENT _v ->
                  _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
              | FLOAT _v ->
                  _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
              | FALSE ->
                  _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | _ ->
                  _eRR ())
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_091 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_ONLY (_menhir_stack, _menhir_s) in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | IF ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | OKAY ->
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | STRING _v ->
                  let _menhir_stack = MenhirCell0_STRING (_menhir_stack, _v) in
                  let _tok = _menhir_lexer _menhir_lexbuf in
                  (match (_tok : MenhirBasics.token) with
                  | LBRACE ->
                      let _tok = _menhir_lexer _menhir_lexbuf in
                      (match (_tok : MenhirBasics.token) with
                      | WHEN ->
                          _menhir_run_004 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState095
                      | TRUE ->
                          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState095
                      | THANKS ->
                          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState095
                      | STRING _v_0 ->
                          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v_0 MenhirState095
                      | SPAWN ->
                          _menhir_run_071 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState095
                      | SAY ->
                          _menhir_run_075 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState095
                      | REPEAT ->
                          _menhir_run_078 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState095
                      | REMEMBER ->
                          _menhir_run_082 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState095
                      | ONLY ->
                          _menhir_run_091 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState095
                      | NOT ->
                          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState095
                      | MINUS ->
                          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState095
                      | LPAREN ->
                          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState095
                      | LBRACKET ->
                          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState095
                      | INT _v_1 ->
                          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v_1 MenhirState095
                      | IDENT _v_2 ->
                          _menhir_run_096 _menhir_stack _menhir_lexbuf _menhir_lexer _v_2 MenhirState095
                      | GIVE ->
                          _menhir_run_100 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState095
                      | FLOAT _v_3 ->
                          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v_3 MenhirState095
                      | FALSE ->
                          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState095
                      | COMPLAIN ->
                          _menhir_run_104 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState095
                      | ATTEMPT ->
                          _menhir_run_107 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState095
                      | AT ->
                          _menhir_run_110 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState095
                      | RBRACE ->
                          let _v_4 = _menhir_action_028 () in
                          _menhir_run_137 _menhir_stack _menhir_lexbuf _menhir_lexer _v_4 _tok
                      | _ ->
                          _eRR ())
                  | _ ->
                      _eRR ())
              | _ ->
                  _eRR ())
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_096 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | LPAREN ->
          let _menhir_stack = MenhirCell1_IDENT (_menhir_stack, _menhir_s, _v) in
          _menhir_run_017 _menhir_stack _menhir_lexbuf _menhir_lexer
      | EQUALS ->
          let _menhir_stack = MenhirCell1_IDENT (_menhir_stack, _menhir_s, _v) in
          let _menhir_s = MenhirState097 in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | TRUE ->
              _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | THANKS ->
              _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | STRING _v ->
              _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | NOT ->
              _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | MINUS ->
              _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | LPAREN ->
              _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | LBRACKET ->
              _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | INT _v ->
              _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | IDENT _v ->
              _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | FLOAT _v ->
              _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | FALSE ->
              _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | _ ->
              _eRR ())
      | AND | EQEQ | GE | GT | LE | LT | MEASURED | MINUS | NE | OR | PERCENT | PLUS | SEMICOLON | SLASH | STAR ->
          let name = _v in
          let _v = _menhir_action_067 name in
          _menhir_goto_primary_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_100 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_GIVE (_menhir_stack, _menhir_s) in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | BACK ->
          let _menhir_s = MenhirState101 in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | TRUE ->
              _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | THANKS ->
              _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | STRING _v ->
              _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | NOT ->
              _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | MINUS ->
              _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | LPAREN ->
              _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | LBRACKET ->
              _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | INT _v ->
              _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | IDENT _v ->
              _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | FLOAT _v ->
              _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | FALSE ->
              _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_104 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | STRING _v ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | SEMICOLON ->
              let _tok = _menhir_lexer _menhir_lexbuf in
              let msg = _v in
              let _v = _menhir_action_084 msg in
              _menhir_goto_simple_statement _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_107 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_ATTEMPT (_menhir_stack, _menhir_s) in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | SAFELY ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | LBRACE ->
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | WHEN ->
                  _menhir_run_004 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState109
              | TRUE ->
                  _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState109
              | THANKS ->
                  _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState109
              | STRING _v ->
                  _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v MenhirState109
              | SPAWN ->
                  _menhir_run_071 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState109
              | SAY ->
                  _menhir_run_075 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState109
              | REPEAT ->
                  _menhir_run_078 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState109
              | REMEMBER ->
                  _menhir_run_082 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState109
              | ONLY ->
                  _menhir_run_091 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState109
              | NOT ->
                  _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState109
              | MINUS ->
                  _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState109
              | LPAREN ->
                  _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState109
              | LBRACKET ->
                  _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState109
              | INT _v ->
                  _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v MenhirState109
              | IDENT _v ->
                  _menhir_run_096 _menhir_stack _menhir_lexbuf _menhir_lexer _v MenhirState109
              | GIVE ->
                  _menhir_run_100 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState109
              | FLOAT _v ->
                  _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v MenhirState109
              | FALSE ->
                  _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState109
              | COMPLAIN ->
                  _menhir_run_104 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState109
              | ATTEMPT ->
                  _menhir_run_107 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState109
              | AT ->
                  _menhir_run_110 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState109
              | RBRACE ->
                  let _v = _menhir_action_028 () in
                  _menhir_run_131 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
              | _ ->
                  _eRR ())
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_110 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_AT (_menhir_stack, _menhir_s) in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | IDENT _v ->
          let _menhir_stack = MenhirCell0_IDENT (_menhir_stack, _v) in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | LPAREN ->
              let _menhir_s = MenhirState112 in
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | IDENT _v ->
                  _menhir_run_113 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
              | _ ->
                  _eRR ())
          | AT | ATTEMPT | COMPLAIN | FALSE | FLOAT _ | GIVE | IDENT _ | INT _ | LBRACKET | MINUS | NOT | ONLY | REMEMBER | REPEAT | SAY | SPAWN | STRING _ | THANKS | TO | TRUE | WHEN ->
              let _v = _menhir_action_044 () in
              _menhir_goto_option_delimited_LPAREN_emote_params_RPAREN__ _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_113 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s ->
      let _menhir_stack = MenhirCell1_IDENT (_menhir_stack, _menhir_s, _v) in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | EQUALS ->
          let _menhir_s = MenhirState114 in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | TRUE ->
              _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | THANKS ->
              _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | STRING _v ->
              _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | NOT ->
              _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | MINUS ->
              _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | LPAREN ->
              _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | LBRACKET ->
              _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | INT _v ->
              _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | IDENT _v ->
              _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | FLOAT _v ->
              _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | FALSE ->
              _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_goto_option_delimited_LPAREN_emote_params_RPAREN__ : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_AT _menhir_cell0_IDENT -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell0_IDENT (_menhir_stack, name) = _menhir_stack in
      let MenhirCell1_AT (_menhir_stack, _menhir_s) = _menhir_stack in
      let params = _v in
      let _v = _menhir_action_018 name params in
      _menhir_goto_emote_tag _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_goto_emote_tag : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match _menhir_s with
      | MenhirState003 ->
          _menhir_run_128 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState070 ->
          _menhir_run_128 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState081 ->
          _menhir_run_128 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState095 ->
          _menhir_run_128 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState109 ->
          _menhir_run_128 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState123 ->
          _menhir_run_128 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState128 ->
          _menhir_run_128 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState144 ->
          _menhir_run_128 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState164 ->
          _menhir_run_128 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState211 ->
          _menhir_run_128 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState000 ->
          _menhir_run_221 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState188 ->
          _menhir_run_221 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_128 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let _menhir_stack = MenhirCell1_emote_tag (_menhir_stack, _menhir_s, _v) in
      match (_tok : MenhirBasics.token) with
      | WHEN ->
          _menhir_run_004 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState128
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState128
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState128
      | STRING _v_0 ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v_0 MenhirState128
      | SPAWN ->
          _menhir_run_071 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState128
      | SAY ->
          _menhir_run_075 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState128
      | REPEAT ->
          _menhir_run_078 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState128
      | REMEMBER ->
          _menhir_run_082 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState128
      | ONLY ->
          _menhir_run_091 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState128
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState128
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState128
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState128
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState128
      | INT _v_1 ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v_1 MenhirState128
      | IDENT _v_2 ->
          _menhir_run_096 _menhir_stack _menhir_lexbuf _menhir_lexer _v_2 MenhirState128
      | GIVE ->
          _menhir_run_100 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState128
      | FLOAT _v_3 ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v_3 MenhirState128
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState128
      | COMPLAIN ->
          _menhir_run_104 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState128
      | ATTEMPT ->
          _menhir_run_107 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState128
      | AT ->
          _menhir_run_110 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState128
      | _ ->
          _eRR ()
  
  and _menhir_run_221 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let x = _v in
      let _v = _menhir_action_047 x in
      _menhir_goto_option_emote_tag_ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_goto_option_emote_tag_ : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let _menhir_stack = MenhirCell1_option_emote_tag_ (_menhir_stack, _menhir_s, _v) in
      match (_tok : MenhirBasics.token) with
      | TO ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | IDENT _v ->
              let _menhir_stack = MenhirCell0_IDENT (_menhir_stack, _v) in
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | LPAREN ->
                  let _menhir_s = MenhirState193 in
                  let _tok = _menhir_lexer _menhir_lexbuf in
                  (match (_tok : MenhirBasics.token) with
                  | IDENT _v ->
                      _menhir_run_194 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
                  | RPAREN ->
                      let _v = _menhir_action_038 () in
                      _menhir_goto_loption_separated_nonempty_list_COMMA_param__ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
                  | _ ->
                      _eRR ())
              | _ ->
                  _eRR ())
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_194 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s ->
      let _menhir_stack = MenhirCell1_IDENT (_menhir_stack, _menhir_s, _v) in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | COLON ->
          let _menhir_s = MenhirState195 in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | TYPE_STRING ->
              _menhir_run_173 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | TYPE_INT ->
              _menhir_run_174 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | TYPE_FLOAT ->
              _menhir_run_175 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | TYPE_BOOL ->
              _menhir_run_176 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | MAYBE ->
              _menhir_run_177 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | LBRACKET ->
              _menhir_run_178 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | IDENT _v ->
              _menhir_run_179 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | _ ->
              _eRR ())
      | COMMA | RPAREN ->
          let _v = _menhir_action_050 () in
          _menhir_goto_option_preceded_COLON_typ__ _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_173 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      let _v = _menhir_action_094 () in
      _menhir_goto_typ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_goto_typ : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match _menhir_s with
      | MenhirState178 ->
          _menhir_run_180 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState177 ->
          _menhir_run_182 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState172 ->
          _menhir_run_183 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState195 ->
          _menhir_run_196 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState204 ->
          _menhir_run_205 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_180 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_LBRACKET -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      match (_tok : MenhirBasics.token) with
      | RBRACKET ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let MenhirCell1_LBRACKET (_menhir_stack, _menhir_s) = _menhir_stack in
          let t = _v in
          let _v = _menhir_action_098 t in
          _menhir_goto_typ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_182 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_MAYBE -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_MAYBE (_menhir_stack, _menhir_s) = _menhir_stack in
      let t = _v in
      let _v = _menhir_action_099 t in
      _menhir_goto_typ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_183 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_CONST _menhir_cell0_IDENT as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let _menhir_stack = MenhirCell1_typ (_menhir_stack, _menhir_s, _v) in
      match (_tok : MenhirBasics.token) with
      | EQUALS ->
          let _menhir_s = MenhirState184 in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | TRUE ->
              _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | THANKS ->
              _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | STRING _v ->
              _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | NOT ->
              _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | MINUS ->
              _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | LPAREN ->
              _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | LBRACKET ->
              _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | INT _v ->
              _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | IDENT _v ->
              _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | FLOAT _v ->
              _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | FALSE ->
              _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_196 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_IDENT -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let x = _v in
      let _v = _menhir_action_051 x in
      _menhir_goto_option_preceded_COLON_typ__ _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
  
  and _menhir_goto_option_preceded_COLON_typ__ : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_IDENT -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_IDENT (_menhir_stack, _menhir_s, name) = _menhir_stack in
      let t = _v in
      let _v = _menhir_action_060 name t in
      match (_tok : MenhirBasics.token) with
      | COMMA ->
          let _menhir_stack = MenhirCell1_param (_menhir_stack, _menhir_s, _v) in
          let _menhir_s = MenhirState200 in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | IDENT _v ->
              _menhir_run_194 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | _ ->
              _eRR ())
      | RPAREN ->
          let x = _v in
          let _v = _menhir_action_077 x in
          _menhir_goto_separated_nonempty_list_COMMA_param_ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_goto_separated_nonempty_list_COMMA_param_ : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s ->
      match _menhir_s with
      | MenhirState193 ->
          _menhir_run_198 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | MenhirState200 ->
          _menhir_run_201 _menhir_stack _menhir_lexbuf _menhir_lexer _v
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_198 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_option_emote_tag_ _menhir_cell0_IDENT as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s ->
      let x = _v in
      let _v = _menhir_action_039 x in
      _menhir_goto_loption_separated_nonempty_list_COMMA_param__ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
  
  and _menhir_goto_loption_separated_nonempty_list_COMMA_param__ : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_option_emote_tag_ _menhir_cell0_IDENT as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s ->
      let _menhir_stack = MenhirCell1_loption_separated_nonempty_list_COMMA_param__ (_menhir_stack, _menhir_s, _v) in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | ARROW ->
          let _menhir_s = MenhirState204 in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | TYPE_STRING ->
              _menhir_run_173 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | TYPE_INT ->
              _menhir_run_174 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | TYPE_FLOAT ->
              _menhir_run_175 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | TYPE_BOOL ->
              _menhir_run_176 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | MAYBE ->
              _menhir_run_177 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | LBRACKET ->
              _menhir_run_178 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | IDENT _v ->
              _menhir_run_179 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | _ ->
              _eRR ())
      | LBRACE ->
          let _v = _menhir_action_048 () in
          _menhir_goto_option_preceded_ARROW_typ__ _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_174 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      let _v = _menhir_action_095 () in
      _menhir_goto_typ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_175 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      let _v = _menhir_action_096 () in
      _menhir_goto_typ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_176 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      let _v = _menhir_action_097 () in
      _menhir_goto_typ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_177 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_MAYBE (_menhir_stack, _menhir_s) in
      let _menhir_s = MenhirState177 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TYPE_STRING ->
          _menhir_run_173 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | TYPE_INT ->
          _menhir_run_174 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | TYPE_FLOAT ->
          _menhir_run_175 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | TYPE_BOOL ->
          _menhir_run_176 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MAYBE ->
          _menhir_run_177 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LBRACKET ->
          _menhir_run_178 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | IDENT _v ->
          _menhir_run_179 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_178 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_LBRACKET (_menhir_stack, _menhir_s) in
      let _menhir_s = MenhirState178 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TYPE_STRING ->
          _menhir_run_173 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | TYPE_INT ->
          _menhir_run_174 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | TYPE_FLOAT ->
          _menhir_run_175 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | TYPE_BOOL ->
          _menhir_run_176 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MAYBE ->
          _menhir_run_177 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LBRACKET ->
          _menhir_run_178 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | IDENT _v ->
          _menhir_run_179 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_179 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      let name = _v in
      let _v = _menhir_action_100 name in
      _menhir_goto_typ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_goto_option_preceded_ARROW_typ__ : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_option_emote_tag_ _menhir_cell0_IDENT, _menhir_box_program) _menhir_cell1_loption_separated_nonempty_list_COMMA_param__ -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let _menhir_stack = MenhirCell0_option_preceded_ARROW_typ__ (_menhir_stack, _v) in
      match (_tok : MenhirBasics.token) with
      | LBRACE ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | HELLO ->
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | STRING _v_0 ->
                  let _tok = _menhir_lexer _menhir_lexbuf in
                  (match (_tok : MenhirBasics.token) with
                  | SEMICOLON ->
                      let _tok = _menhir_lexer _menhir_lexbuf in
                      let x = _v_0 in
                      let _v = _menhir_action_055 x in
                      _menhir_goto_option_preceded_HELLO_terminated_STRING_SEMICOLON___ _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
                  | _ ->
                      _eRR ())
              | _ ->
                  _eRR ())
          | AT | ATTEMPT | COMPLAIN | FALSE | FLOAT _ | GIVE | GOODBYE | IDENT _ | INT _ | LBRACKET | LPAREN | MINUS | NOT | ONLY | RBRACE | REMEMBER | REPEAT | SAY | SPAWN | STRING _ | THANKS | TRUE | WHEN ->
              let _v = _menhir_action_054 () in
              _menhir_goto_option_preceded_HELLO_terminated_STRING_SEMICOLON___ _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_goto_option_preceded_HELLO_terminated_STRING_SEMICOLON___ : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_option_emote_tag_ _menhir_cell0_IDENT, _menhir_box_program) _menhir_cell1_loption_separated_nonempty_list_COMMA_param__ _menhir_cell0_option_preceded_ARROW_typ__ -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let _menhir_stack = MenhirCell0_option_preceded_HELLO_terminated_STRING_SEMICOLON___ (_menhir_stack, _v) in
      match (_tok : MenhirBasics.token) with
      | WHEN ->
          _menhir_run_004 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState211
      | TRUE ->
          _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState211
      | THANKS ->
          _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState211
      | STRING _v_0 ->
          _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v_0 MenhirState211
      | SPAWN ->
          _menhir_run_071 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState211
      | SAY ->
          _menhir_run_075 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState211
      | REPEAT ->
          _menhir_run_078 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState211
      | REMEMBER ->
          _menhir_run_082 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState211
      | ONLY ->
          _menhir_run_091 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState211
      | NOT ->
          _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState211
      | MINUS ->
          _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState211
      | LPAREN ->
          _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState211
      | LBRACKET ->
          _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState211
      | INT _v_1 ->
          _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v_1 MenhirState211
      | IDENT _v_2 ->
          _menhir_run_096 _menhir_stack _menhir_lexbuf _menhir_lexer _v_2 MenhirState211
      | GIVE ->
          _menhir_run_100 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState211
      | FLOAT _v_3 ->
          _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v_3 MenhirState211
      | FALSE ->
          _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState211
      | COMPLAIN ->
          _menhir_run_104 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState211
      | ATTEMPT ->
          _menhir_run_107 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState211
      | AT ->
          _menhir_run_110 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState211
      | GOODBYE | RBRACE ->
          let _v_4 = _menhir_action_028 () in
          _menhir_run_212 _menhir_stack _menhir_lexbuf _menhir_lexer _v_4 MenhirState211 _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_212 : type  ttv_stack. (((ttv_stack, _menhir_box_program) _menhir_cell1_option_emote_tag_ _menhir_cell0_IDENT, _menhir_box_program) _menhir_cell1_loption_separated_nonempty_list_COMMA_param__ _menhir_cell0_option_preceded_ARROW_typ__ _menhir_cell0_option_preceded_HELLO_terminated_STRING_SEMICOLON___ as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let _menhir_stack = MenhirCell1_list_statement_ (_menhir_stack, _menhir_s, _v) in
      match (_tok : MenhirBasics.token) with
      | GOODBYE ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | STRING _v_0 ->
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | SEMICOLON ->
                  let _tok = _menhir_lexer _menhir_lexbuf in
                  let x = _v_0 in
                  let _v = _menhir_action_053 x in
                  _menhir_goto_option_preceded_GOODBYE_terminated_STRING_SEMICOLON___ _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
              | _ ->
                  _eRR ())
          | _ ->
              _eRR ())
      | RBRACE ->
          let _v = _menhir_action_052 () in
          _menhir_goto_option_preceded_GOODBYE_terminated_STRING_SEMICOLON___ _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_goto_option_preceded_GOODBYE_terminated_STRING_SEMICOLON___ : type  ttv_stack. (((ttv_stack, _menhir_box_program) _menhir_cell1_option_emote_tag_ _menhir_cell0_IDENT, _menhir_box_program) _menhir_cell1_loption_separated_nonempty_list_COMMA_param__ _menhir_cell0_option_preceded_ARROW_typ__ _menhir_cell0_option_preceded_HELLO_terminated_STRING_SEMICOLON___, _menhir_box_program) _menhir_cell1_list_statement_ -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      match (_tok : MenhirBasics.token) with
      | RBRACE ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let MenhirCell1_list_statement_ (_menhir_stack, _, body) = _menhir_stack in
          let MenhirCell0_option_preceded_HELLO_terminated_STRING_SEMICOLON___ (_menhir_stack, hello_msg) = _menhir_stack in
          let MenhirCell0_option_preceded_ARROW_typ__ (_menhir_stack, ret) = _menhir_stack in
          let MenhirCell1_loption_separated_nonempty_list_COMMA_param__ (_menhir_stack, _, xs) = _menhir_stack in
          let MenhirCell0_IDENT (_menhir_stack, name) = _menhir_stack in
          let MenhirCell1_option_emote_tag_ (_menhir_stack, _menhir_s, emote) = _menhir_stack in
          let goodbye_msg = _v in
          let _v = _menhir_action_023 body emote goodbye_msg hello_msg name ret xs in
          let f = _v in
          let _v = _menhir_action_089 f in
          _menhir_goto_top_level_item _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_goto_top_level_item : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let _menhir_stack = MenhirCell1_top_level_item (_menhir_stack, _menhir_s, _v) in
      match (_tok : MenhirBasics.token) with
      | WORKER ->
          _menhir_run_001 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState188
      | THANKS ->
          _menhir_run_150 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState188
      | SIDE ->
          _menhir_run_161 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState188
      | CONST ->
          _menhir_run_167 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState188
      | AT ->
          _menhir_run_110 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState188
      | EOF ->
          let _v_0 = _menhir_action_030 () in
          _menhir_run_218 _menhir_stack _v_0
      | TO ->
          let _menhir_s = MenhirState188 in
          let _v = _menhir_action_046 () in
          _menhir_goto_option_emote_tag_ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_150 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_THANKS (_menhir_stack, _menhir_s) in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | TO ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | LBRACE ->
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | STRING _v ->
                  _menhir_run_153 _menhir_stack _menhir_lexbuf _menhir_lexer _v MenhirState152
              | RBRACE ->
                  let _v = _menhir_action_026 () in
                  _menhir_run_157 _menhir_stack _menhir_lexbuf _menhir_lexer _v
              | _ ->
                  _eRR ())
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_153 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | ARROW ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | STRING _v_0 ->
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | SEMICOLON ->
                  let _tok = _menhir_lexer _menhir_lexbuf in
                  let (contribution, contributor) = (_v_0, _v) in
                  let _v = _menhir_action_025 contribution contributor in
                  let _menhir_stack = MenhirCell1_gratitude_entry (_menhir_stack, _menhir_s, _v) in
                  (match (_tok : MenhirBasics.token) with
                  | STRING _v_0 ->
                      _menhir_run_153 _menhir_stack _menhir_lexbuf _menhir_lexer _v_0 MenhirState159
                  | RBRACE ->
                      let _v_1 = _menhir_action_026 () in
                      _menhir_run_160 _menhir_stack _menhir_lexbuf _menhir_lexer _v_1
                  | _ ->
                      _eRR ())
              | _ ->
                  _eRR ())
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_160 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_gratitude_entry -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v ->
      let MenhirCell1_gratitude_entry (_menhir_stack, _menhir_s, x) = _menhir_stack in
      let xs = _v in
      let _v = _menhir_action_027 x xs in
      _menhir_goto_list_gratitude_entry_ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
  
  and _menhir_goto_list_gratitude_entry_ : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s ->
      match _menhir_s with
      | MenhirState152 ->
          _menhir_run_157 _menhir_stack _menhir_lexbuf _menhir_lexer _v
      | MenhirState159 ->
          _menhir_run_160 _menhir_stack _menhir_lexbuf _menhir_lexer _v
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_157 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_THANKS -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      let MenhirCell1_THANKS (_menhir_stack, _menhir_s) = _menhir_stack in
      let entries = _v in
      let _v = _menhir_action_024 entries in
      let g = _v in
      let _v = _menhir_action_090 g in
      _menhir_goto_top_level_item _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_161 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_SIDE (_menhir_stack, _menhir_s) in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | QUEST ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | IDENT _v ->
              let _menhir_stack = MenhirCell0_IDENT (_menhir_stack, _v) in
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | LBRACE ->
                  let _tok = _menhir_lexer _menhir_lexbuf in
                  (match (_tok : MenhirBasics.token) with
                  | WHEN ->
                      _menhir_run_004 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState164
                  | TRUE ->
                      _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState164
                  | THANKS ->
                      _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState164
                  | STRING _v_0 ->
                      _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v_0 MenhirState164
                  | SPAWN ->
                      _menhir_run_071 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState164
                  | SAY ->
                      _menhir_run_075 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState164
                  | REPEAT ->
                      _menhir_run_078 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState164
                  | REMEMBER ->
                      _menhir_run_082 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState164
                  | ONLY ->
                      _menhir_run_091 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState164
                  | NOT ->
                      _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState164
                  | MINUS ->
                      _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState164
                  | LPAREN ->
                      _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState164
                  | LBRACKET ->
                      _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState164
                  | INT _v_1 ->
                      _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v_1 MenhirState164
                  | IDENT _v_2 ->
                      _menhir_run_096 _menhir_stack _menhir_lexbuf _menhir_lexer _v_2 MenhirState164
                  | GIVE ->
                      _menhir_run_100 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState164
                  | FLOAT _v_3 ->
                      _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v_3 MenhirState164
                  | FALSE ->
                      _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState164
                  | COMPLAIN ->
                      _menhir_run_104 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState164
                  | ATTEMPT ->
                      _menhir_run_107 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState164
                  | AT ->
                      _menhir_run_110 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState164
                  | RBRACE ->
                      let _v_4 = _menhir_action_028 () in
                      _menhir_run_165 _menhir_stack _menhir_lexbuf _menhir_lexer _v_4 _tok
                  | _ ->
                      _eRR ())
              | _ ->
                  _eRR ())
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_165 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_SIDE _menhir_cell0_IDENT -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      match (_tok : MenhirBasics.token) with
      | RBRACE ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let MenhirCell0_IDENT (_menhir_stack, name) = _menhir_stack in
          let MenhirCell1_SIDE (_menhir_stack, _menhir_s) = _menhir_stack in
          let body = _v in
          let _v = _menhir_action_079 body name in
          let s = _v in
          let _v = _menhir_action_092 s in
          _menhir_goto_top_level_item _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_167 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_CONST (_menhir_stack, _menhir_s) in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | IDENT _v ->
          let _menhir_stack = MenhirCell0_IDENT (_menhir_stack, _v) in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | EQUALS ->
              let _menhir_s = MenhirState169 in
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | TRUE ->
                  _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | THANKS ->
                  _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | STRING _v ->
                  _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
              | NOT ->
                  _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | MINUS ->
                  _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | LPAREN ->
                  _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | LBRACKET ->
                  _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | INT _v ->
                  _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
              | IDENT _v ->
                  _menhir_run_016 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
              | FLOAT _v ->
                  _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
              | FALSE ->
                  _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | _ ->
                  _eRR ())
          | COLON ->
              let _menhir_s = MenhirState172 in
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | TYPE_STRING ->
                  _menhir_run_173 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | TYPE_INT ->
                  _menhir_run_174 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | TYPE_FLOAT ->
                  _menhir_run_175 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | TYPE_BOOL ->
                  _menhir_run_176 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | MAYBE ->
                  _menhir_run_177 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | LBRACKET ->
                  _menhir_run_178 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
              | IDENT _v ->
                  _menhir_run_179 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
              | _ ->
                  _eRR ())
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_201 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_param -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v ->
      let MenhirCell1_param (_menhir_stack, _menhir_s, x) = _menhir_stack in
      let xs = _v in
      let _v = _menhir_action_078 x xs in
      _menhir_goto_separated_nonempty_list_COMMA_param_ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
  
  and _menhir_run_205 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_option_emote_tag_ _menhir_cell0_IDENT, _menhir_box_program) _menhir_cell1_loption_separated_nonempty_list_COMMA_param__ -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let x = _v in
      let _v = _menhir_action_049 x in
      _menhir_goto_option_preceded_ARROW_typ__ _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
  
  and _menhir_run_131 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_ATTEMPT -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      match (_tok : MenhirBasics.token) with
      | RBRACE ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | OR ->
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | REASSURE ->
                  let _tok = _menhir_lexer _menhir_lexbuf in
                  (match (_tok : MenhirBasics.token) with
                  | STRING _v_0 ->
                      let _tok = _menhir_lexer _menhir_lexbuf in
                      (match (_tok : MenhirBasics.token) with
                      | SEMICOLON ->
                          let _tok = _menhir_lexer _menhir_lexbuf in
                          let MenhirCell1_ATTEMPT (_menhir_stack, _menhir_s) = _menhir_stack in
                          let (msg, body) = (_v_0, _v) in
                          let _v = _menhir_action_011 body msg in
                          _menhir_goto_compound_statement _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
                      | _ ->
                          _eRR ())
                  | _ ->
                      _eRR ())
              | _ ->
                  _eRR ())
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_goto_compound_statement : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let s = _v in
      let _v = _menhir_action_088 s in
      _menhir_goto_statement _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_137 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_ONLY _menhir_cell0_STRING -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      match (_tok : MenhirBasics.token) with
      | RBRACE ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let MenhirCell0_STRING (_menhir_stack, perm) = _menhir_stack in
          let MenhirCell1_ONLY (_menhir_stack, _menhir_s) = _menhir_stack in
          let body = _v in
          let _v = _menhir_action_012 body perm in
          _menhir_goto_compound_statement _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_125 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_statement -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_statement (_menhir_stack, _menhir_s, x) = _menhir_stack in
      let xs = _v in
      let _v = _menhir_action_029 x xs in
      _menhir_goto_list_statement_ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_goto_list_statement_ : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match _menhir_s with
      | MenhirState123 ->
          _menhir_run_125 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState109 ->
          _menhir_run_131 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState095 ->
          _menhir_run_137 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState081 ->
          _menhir_run_139 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState070 ->
          _menhir_run_141 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState144 ->
          _menhir_run_145 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState003 ->
          _menhir_run_148 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState164 ->
          _menhir_run_165 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState211 ->
          _menhir_run_212 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_139 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_REPEAT, _menhir_box_program) _menhir_cell1_expr -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      match (_tok : MenhirBasics.token) with
      | RBRACE ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let MenhirCell1_expr (_menhir_stack, _, n) = _menhir_stack in
          let MenhirCell1_REPEAT (_menhir_stack, _menhir_s) = _menhir_stack in
          let body = _v in
          let _v = _menhir_action_010 body n in
          _menhir_goto_compound_statement _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_141 : type  ttv_stack. (((ttv_stack, _menhir_box_program) _menhir_cell1_WHEN, _menhir_box_program) _menhir_cell1_expr as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let _menhir_stack = MenhirCell1_list_statement_ (_menhir_stack, _menhir_s, _v) in
      match (_tok : MenhirBasics.token) with
      | RBRACE ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | OTHERWISE ->
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | LBRACE ->
                  let _tok = _menhir_lexer _menhir_lexbuf in
                  (match (_tok : MenhirBasics.token) with
                  | WHEN ->
                      _menhir_run_004 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState144
                  | TRUE ->
                      _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState144
                  | THANKS ->
                      _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState144
                  | STRING _v_0 ->
                      _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v_0 MenhirState144
                  | SPAWN ->
                      _menhir_run_071 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState144
                  | SAY ->
                      _menhir_run_075 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState144
                  | REPEAT ->
                      _menhir_run_078 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState144
                  | REMEMBER ->
                      _menhir_run_082 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState144
                  | ONLY ->
                      _menhir_run_091 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState144
                  | NOT ->
                      _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState144
                  | MINUS ->
                      _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState144
                  | LPAREN ->
                      _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState144
                  | LBRACKET ->
                      _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState144
                  | INT _v_1 ->
                      _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v_1 MenhirState144
                  | IDENT _v_2 ->
                      _menhir_run_096 _menhir_stack _menhir_lexbuf _menhir_lexer _v_2 MenhirState144
                  | GIVE ->
                      _menhir_run_100 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState144
                  | FLOAT _v_3 ->
                      _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v_3 MenhirState144
                  | FALSE ->
                      _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState144
                  | COMPLAIN ->
                      _menhir_run_104 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState144
                  | ATTEMPT ->
                      _menhir_run_107 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState144
                  | AT ->
                      _menhir_run_110 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState144
                  | RBRACE ->
                      let _v_4 = _menhir_action_028 () in
                      _menhir_run_145 _menhir_stack _menhir_lexbuf _menhir_lexer _v_4 _tok
                  | _ ->
                      _eRR ())
              | _ ->
                  _eRR ())
          | AT | ATTEMPT | COMPLAIN | FALSE | FLOAT _ | GIVE | GOODBYE | IDENT _ | INT _ | LBRACKET | LPAREN | MINUS | NOT | ONLY | RBRACE | REMEMBER | REPEAT | SAY | SPAWN | STRING _ | THANKS | TRUE | WHEN ->
              let _v = _menhir_action_056 () in
              _menhir_goto_option_preceded_OTHERWISE_delimited_LBRACE_list_statement__RBRACE___ _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_145 : type  ttv_stack. (((ttv_stack, _menhir_box_program) _menhir_cell1_WHEN, _menhir_box_program) _menhir_cell1_expr, _menhir_box_program) _menhir_cell1_list_statement_ -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      match (_tok : MenhirBasics.token) with
      | RBRACE ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let x = _v in
          let _v = _menhir_action_057 x in
          _menhir_goto_option_preceded_OTHERWISE_delimited_LBRACE_list_statement__RBRACE___ _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | _ ->
          _eRR ()
  
  and _menhir_goto_option_preceded_OTHERWISE_delimited_LBRACE_list_statement__RBRACE___ : type  ttv_stack. (((ttv_stack, _menhir_box_program) _menhir_cell1_WHEN, _menhir_box_program) _menhir_cell1_expr, _menhir_box_program) _menhir_cell1_list_statement_ -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_list_statement_ (_menhir_stack, _, then_body) = _menhir_stack in
      let MenhirCell1_expr (_menhir_stack, _, cond) = _menhir_stack in
      let MenhirCell1_WHEN (_menhir_stack, _menhir_s) = _menhir_stack in
      let else_body = _v in
      let _v = _menhir_action_009 cond else_body then_body in
      _menhir_goto_compound_statement _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_148 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_WORKER _menhir_cell0_IDENT -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      match (_tok : MenhirBasics.token) with
      | RBRACE ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let MenhirCell0_IDENT (_menhir_stack, name) = _menhir_stack in
          let MenhirCell1_WORKER (_menhir_stack, _menhir_s) = _menhir_stack in
          let body = _v in
          let _v = _menhir_action_104 body name in
          let w = _v in
          let _v = _menhir_action_091 w in
          _menhir_goto_top_level_item _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_129 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_emote_tag -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_emote_tag (_menhir_stack, _menhir_s, emote) = _menhir_stack in
      let s = _v in
      let _v = _menhir_action_013 emote s in
      _menhir_goto_compound_statement _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_076 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_SAY -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      match (_tok : MenhirBasics.token) with
      | SEMICOLON ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let MenhirCell1_SAY (_menhir_stack, _menhir_s) = _menhir_stack in
          let e = _v in
          let _v = _menhir_action_086 e in
          _menhir_goto_simple_statement _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_079 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_REPEAT as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let _menhir_stack = MenhirCell1_expr (_menhir_stack, _menhir_s, _v) in
      match (_tok : MenhirBasics.token) with
      | TIMES ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | LBRACE ->
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | WHEN ->
                  _menhir_run_004 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState081
              | TRUE ->
                  _menhir_run_005 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState081
              | THANKS ->
                  _menhir_run_006 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState081
              | STRING _v_0 ->
                  _menhir_run_010 _menhir_stack _menhir_lexbuf _menhir_lexer _v_0 MenhirState081
              | SPAWN ->
                  _menhir_run_071 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState081
              | SAY ->
                  _menhir_run_075 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState081
              | REPEAT ->
                  _menhir_run_078 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState081
              | REMEMBER ->
                  _menhir_run_082 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState081
              | ONLY ->
                  _menhir_run_091 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState081
              | NOT ->
                  _menhir_run_011 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState081
              | MINUS ->
                  _menhir_run_012 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState081
              | LPAREN ->
                  _menhir_run_013 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState081
              | LBRACKET ->
                  _menhir_run_014 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState081
              | INT _v_1 ->
                  _menhir_run_015 _menhir_stack _menhir_lexbuf _menhir_lexer _v_1 MenhirState081
              | IDENT _v_2 ->
                  _menhir_run_096 _menhir_stack _menhir_lexbuf _menhir_lexer _v_2 MenhirState081
              | GIVE ->
                  _menhir_run_100 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState081
              | FLOAT _v_3 ->
                  _menhir_run_018 _menhir_stack _menhir_lexbuf _menhir_lexer _v_3 MenhirState081
              | FALSE ->
                  _menhir_run_019 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState081
              | COMPLAIN ->
                  _menhir_run_104 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState081
              | ATTEMPT ->
                  _menhir_run_107 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState081
              | AT ->
                  _menhir_run_110 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState081
              | RBRACE ->
                  let _v_4 = _menhir_action_028 () in
                  _menhir_run_139 _menhir_stack _menhir_lexbuf _menhir_lexer _v_4 _tok
              | _ ->
                  _eRR ())
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_085 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_REMEMBER _menhir_cell0_IDENT as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let _menhir_stack = MenhirCell1_expr (_menhir_stack, _menhir_s, _v) in
      match (_tok : MenhirBasics.token) with
      | SEMICOLON ->
          let _v = _menhir_action_058 () in
          let _tok = _menhir_lexer _menhir_lexbuf in
          let MenhirCell1_expr (_menhir_stack, _, e) = _menhir_stack in
          let MenhirCell0_IDENT (_menhir_stack, name) = _menhir_stack in
          let MenhirCell1_REMEMBER (_menhir_stack, _menhir_s) = _menhir_stack in
          let unit = _v in
          let _v = _menhir_action_080 e name unit in
          _menhir_goto_simple_statement _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_098 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_IDENT -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      match (_tok : MenhirBasics.token) with
      | SEMICOLON ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let MenhirCell1_IDENT (_menhir_stack, _menhir_s, name) = _menhir_stack in
          let e = _v in
          let _v = _menhir_action_081 e name in
          _menhir_goto_simple_statement _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_102 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_GIVE -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      match (_tok : MenhirBasics.token) with
      | SEMICOLON ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let MenhirCell1_GIVE (_menhir_stack, _menhir_s) = _menhir_stack in
          let e = _v in
          let _v = _menhir_action_082 e in
          _menhir_goto_simple_statement _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_115 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_IDENT -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_IDENT (_menhir_stack, _menhir_s, name) = _menhir_stack in
      let e = _v in
      let _v = _menhir_action_016 e name in
      match (_tok : MenhirBasics.token) with
      | COMMA ->
          let _menhir_stack = MenhirCell1_emote_param (_menhir_stack, _menhir_s, _v) in
          let _menhir_s = MenhirState120 in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | IDENT _v ->
              _menhir_run_113 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | _ ->
              _eRR ())
      | RPAREN ->
          let x = _v in
          let _v = _menhir_action_073 x in
          _menhir_goto_separated_nonempty_list_COMMA_emote_param_ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_goto_separated_nonempty_list_COMMA_emote_param_ : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s ->
      match _menhir_s with
      | MenhirState112 ->
          _menhir_run_116 _menhir_stack _menhir_lexbuf _menhir_lexer _v
      | MenhirState120 ->
          _menhir_run_121 _menhir_stack _menhir_lexbuf _menhir_lexer _v
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_116 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_AT _menhir_cell0_IDENT -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v ->
      let params = _v in
      let _v = _menhir_action_017 params in
      let _tok = _menhir_lexer _menhir_lexbuf in
      let x = _v in
      let _v = _menhir_action_045 x in
      _menhir_goto_option_delimited_LPAREN_emote_params_RPAREN__ _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
  
  and _menhir_run_121 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_emote_param -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v ->
      let MenhirCell1_emote_param (_menhir_stack, _menhir_s, x) = _menhir_stack in
      let xs = _v in
      let _v = _menhir_action_074 x xs in
      _menhir_goto_separated_nonempty_list_COMMA_emote_param_ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
  
  and _menhir_run_126 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | SEMICOLON ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let e = _v in
          let _v = _menhir_action_083 e in
          _menhir_goto_simple_statement _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_170 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_CONST _menhir_cell0_IDENT -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      match (_tok : MenhirBasics.token) with
      | SEMICOLON ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let MenhirCell0_IDENT (_menhir_stack, name) = _menhir_stack in
          let MenhirCell1_CONST (_menhir_stack, _menhir_s) = _menhir_stack in
          let e = _v in
          let _v = _menhir_action_015 e name in
          _menhir_goto_const_def _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_goto_const_def : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let c = _v in
      let _v = _menhir_action_093 c in
      _menhir_goto_top_level_item _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_185 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_CONST _menhir_cell0_IDENT, _menhir_box_program) _menhir_cell1_typ -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      match (_tok : MenhirBasics.token) with
      | SEMICOLON ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let MenhirCell1_typ (_menhir_stack, _, t) = _menhir_stack in
          let MenhirCell0_IDENT (_menhir_stack, name) = _menhir_stack in
          let MenhirCell1_CONST (_menhir_stack, _menhir_s) = _menhir_stack in
          let e = _v in
          let _v = _menhir_action_014 e name t in
          _menhir_goto_const_def _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_059 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | AND ->
          let _menhir_stack = MenhirCell1_logical_and_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_038 _menhir_stack _menhir_lexbuf _menhir_lexer
      | COMMA | LBRACE | MEASURED | OR | RBRACKET | RPAREN | SEMICOLON | TIMES ->
          let e = _v in
          let _v = _menhir_action_035 e in
          _menhir_goto_logical_or_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_058 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | NE ->
          let _menhir_stack = MenhirCell1_equality_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_040 _menhir_stack _menhir_lexbuf _menhir_lexer
      | EQEQ ->
          let _menhir_stack = MenhirCell1_equality_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_055 _menhir_stack _menhir_lexbuf _menhir_lexer
      | AND | COMMA | LBRACE | MEASURED | OR | RBRACKET | RPAREN | SEMICOLON | TIMES ->
          let e = _v in
          let _v = _menhir_action_033 e in
          _menhir_goto_logical_and_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_056 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_equality_expr as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | LT ->
          let _menhir_stack = MenhirCell1_comparison_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_042 _menhir_stack _menhir_lexbuf _menhir_lexer
      | LE ->
          let _menhir_stack = MenhirCell1_comparison_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_048 _menhir_stack _menhir_lexbuf _menhir_lexer
      | GT ->
          let _menhir_stack = MenhirCell1_comparison_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_050 _menhir_stack _menhir_lexbuf _menhir_lexer
      | GE ->
          let _menhir_stack = MenhirCell1_comparison_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_052 _menhir_stack _menhir_lexbuf _menhir_lexer
      | AND | COMMA | EQEQ | LBRACE | MEASURED | NE | OR | RBRACKET | RPAREN | SEMICOLON | TIMES ->
          let MenhirCell1_equality_expr (_menhir_stack, _menhir_s, left) = _menhir_stack in
          let right = _v in
          let _v = _menhir_action_019 left right in
          _menhir_goto_equality_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_057 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | LT ->
          let _menhir_stack = MenhirCell1_comparison_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_042 _menhir_stack _menhir_lexbuf _menhir_lexer
      | LE ->
          let _menhir_stack = MenhirCell1_comparison_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_048 _menhir_stack _menhir_lexbuf _menhir_lexer
      | GT ->
          let _menhir_stack = MenhirCell1_comparison_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_050 _menhir_stack _menhir_lexbuf _menhir_lexer
      | GE ->
          let _menhir_stack = MenhirCell1_comparison_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_052 _menhir_stack _menhir_lexbuf _menhir_lexer
      | AND | COMMA | EQEQ | LBRACE | MEASURED | NE | OR | RBRACKET | RPAREN | SEMICOLON | TIMES ->
          let e = _v in
          let _v = _menhir_action_021 e in
          _menhir_goto_equality_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_049 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_comparison_expr as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | PLUS ->
          let _menhir_stack = MenhirCell1_additive_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_044 _menhir_stack _menhir_lexbuf _menhir_lexer
      | MINUS ->
          let _menhir_stack = MenhirCell1_additive_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_046 _menhir_stack _menhir_lexbuf _menhir_lexer
      | AND | COMMA | EQEQ | GE | GT | LBRACE | LE | LT | MEASURED | NE | OR | RBRACKET | RPAREN | SEMICOLON | TIMES ->
          let MenhirCell1_comparison_expr (_menhir_stack, _menhir_s, left) = _menhir_stack in
          let right = _v in
          let _v = _menhir_action_006 left right in
          _menhir_goto_comparison_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_051 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_comparison_expr as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | PLUS ->
          let _menhir_stack = MenhirCell1_additive_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_044 _menhir_stack _menhir_lexbuf _menhir_lexer
      | MINUS ->
          let _menhir_stack = MenhirCell1_additive_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_046 _menhir_stack _menhir_lexbuf _menhir_lexer
      | AND | COMMA | EQEQ | GE | GT | LBRACE | LE | LT | MEASURED | NE | OR | RBRACKET | RPAREN | SEMICOLON | TIMES ->
          let MenhirCell1_comparison_expr (_menhir_stack, _menhir_s, left) = _menhir_stack in
          let right = _v in
          let _v = _menhir_action_005 left right in
          _menhir_goto_comparison_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_053 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_comparison_expr as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | PLUS ->
          let _menhir_stack = MenhirCell1_additive_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_044 _menhir_stack _menhir_lexbuf _menhir_lexer
      | MINUS ->
          let _menhir_stack = MenhirCell1_additive_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_046 _menhir_stack _menhir_lexbuf _menhir_lexer
      | AND | COMMA | EQEQ | GE | GT | LBRACE | LE | LT | MEASURED | NE | OR | RBRACKET | RPAREN | SEMICOLON | TIMES ->
          let MenhirCell1_comparison_expr (_menhir_stack, _menhir_s, left) = _menhir_stack in
          let right = _v in
          let _v = _menhir_action_007 left right in
          _menhir_goto_comparison_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_054 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | PLUS ->
          let _menhir_stack = MenhirCell1_additive_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_044 _menhir_stack _menhir_lexbuf _menhir_lexer
      | MINUS ->
          let _menhir_stack = MenhirCell1_additive_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_046 _menhir_stack _menhir_lexbuf _menhir_lexer
      | AND | COMMA | EQEQ | GE | GT | LBRACE | LE | LT | MEASURED | NE | OR | RBRACKET | RPAREN | SEMICOLON | TIMES ->
          let e = _v in
          let _v = _menhir_action_008 e in
          _menhir_goto_comparison_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_045 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_additive_expr as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | STAR ->
          let _menhir_stack = MenhirCell1_multiplicative_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_027 _menhir_stack _menhir_lexbuf _menhir_lexer
      | SLASH ->
          let _menhir_stack = MenhirCell1_multiplicative_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_029 _menhir_stack _menhir_lexbuf _menhir_lexer
      | PERCENT ->
          let _menhir_stack = MenhirCell1_multiplicative_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_031 _menhir_stack _menhir_lexbuf _menhir_lexer
      | AND | COMMA | EQEQ | GE | GT | LBRACE | LE | LT | MEASURED | MINUS | NE | OR | PLUS | RBRACKET | RPAREN | SEMICOLON | TIMES ->
          let MenhirCell1_additive_expr (_menhir_stack, _menhir_s, left) = _menhir_stack in
          let right = _v in
          let _v = _menhir_action_001 left right in
          _menhir_goto_additive_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_047 : type  ttv_stack. ((ttv_stack, _menhir_box_program) _menhir_cell1_additive_expr as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_program) _menhir_state -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | STAR ->
          let _menhir_stack = MenhirCell1_multiplicative_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_027 _menhir_stack _menhir_lexbuf _menhir_lexer
      | SLASH ->
          let _menhir_stack = MenhirCell1_multiplicative_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_029 _menhir_stack _menhir_lexbuf _menhir_lexer
      | PERCENT ->
          let _menhir_stack = MenhirCell1_multiplicative_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_031 _menhir_stack _menhir_lexbuf _menhir_lexer
      | AND | COMMA | EQEQ | GE | GT | LBRACE | LE | LT | MEASURED | MINUS | NE | OR | PLUS | RBRACKET | RPAREN | SEMICOLON | TIMES ->
          let MenhirCell1_additive_expr (_menhir_stack, _menhir_s, left) = _menhir_stack in
          let right = _v in
          let _v = _menhir_action_002 left right in
          _menhir_goto_additive_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_028 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_multiplicative_expr -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_multiplicative_expr (_menhir_stack, _menhir_s, left) = _menhir_stack in
      let right = _v in
      let _v = _menhir_action_040 left right in
      _menhir_goto_multiplicative_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_030 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_multiplicative_expr -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_multiplicative_expr (_menhir_stack, _menhir_s, left) = _menhir_stack in
      let right = _v in
      let _v = _menhir_action_041 left right in
      _menhir_goto_multiplicative_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_032 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_multiplicative_expr -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_multiplicative_expr (_menhir_stack, _menhir_s, left) = _menhir_stack in
      let right = _v in
      let _v = _menhir_action_042 left right in
      _menhir_goto_multiplicative_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_067 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_MINUS -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_MINUS (_menhir_stack, _menhir_s) = _menhir_stack in
      let e = _v in
      let _v = _menhir_action_102 e in
      _menhir_goto_unary_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_068 : type  ttv_stack. (ttv_stack, _menhir_box_program) _menhir_cell1_NOT -> _ -> _ -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_NOT (_menhir_stack, _menhir_s) = _menhir_stack in
      let e = _v in
      let _v = _menhir_action_101 e in
      _menhir_goto_unary_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  let _menhir_run_000 : type  ttv_stack. ttv_stack -> _ -> _ -> _menhir_box_program =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | WORKER ->
          _menhir_run_001 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState000
      | THANKS ->
          _menhir_run_150 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState000
      | SIDE ->
          _menhir_run_161 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState000
      | CONST ->
          _menhir_run_167 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState000
      | AT ->
          _menhir_run_110 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState000
      | EOF ->
          let _v = _menhir_action_030 () in
          _menhir_run_224 _menhir_stack _v
      | TO ->
          let _menhir_s = MenhirState000 in
          let _v = _menhir_action_046 () in
          _menhir_goto_option_emote_tag_ _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
end

let program =
  fun _menhir_lexer _menhir_lexbuf ->
    let _menhir_stack = () in
    let MenhirBox_program v = _menhir_run_000 _menhir_stack _menhir_lexbuf _menhir_lexer in
    v
