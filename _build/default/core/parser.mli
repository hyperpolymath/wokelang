
(* The type of tokens. *)

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
  | STRING of (string)
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
  | INT of (int)
  | IN
  | IF
  | IDENT of (string)
  | HELLO
  | HAVE
  | HASH
  | GT
  | GOODBYE
  | GIVE
  | GE
  | FLOAT of (float)
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

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val program: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Ast.program)
