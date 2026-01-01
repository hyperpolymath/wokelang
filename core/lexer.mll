(* SPDX-License-Identifier: AGPL-3.0-or-later *)
(* SPDX-FileCopyrightText: 2026 Hyperpolymath *)

{
open Parser

exception LexError of string

let line_num = ref 1
let line_start = ref 0

let newline lexbuf =
  incr line_num;
  line_start := Lexing.lexeme_end lexbuf
}

let digit = ['0'-'9']
let alpha = ['a'-'z' 'A'-'Z']
let ident = alpha (alpha | digit | '_')*
let whitespace = [' ' '\t']+
let newline = '\r'? '\n'

rule token = parse
  (* Whitespace and comments *)
  | whitespace     { token lexbuf }
  | newline        { newline lexbuf; token lexbuf }
  | "//" [^ '\n']* { token lexbuf }
  | "/*"           { block_comment lexbuf; token lexbuf }

  (* Delimiters and operators *)
  | '('            { LPAREN }
  | ')'            { RPAREN }
  | '{'            { LBRACE }
  | '}'            { RBRACE }
  | '['            { LBRACKET }
  | ']'            { RBRACKET }
  | ','            { COMMA }
  | ';'            { SEMICOLON }
  | ':'            { COLON }
  | '='            { EQUALS }
  | '@'            { AT }
  | "→"            { ARROW }
  | "->"           { ARROW }

  (* Comparison operators *)
  | "=="           { EQEQ }
  | "!="           { NE }
  | "<="           { LE }
  | ">="           { GE }
  | '<'            { LT }
  | '>'            { GT }

  (* Arithmetic operators *)
  | '+'            { PLUS }
  | '-'            { MINUS }
  | '*'            { STAR }
  | '/'            { SLASH }
  | '%'            { PERCENT }

  (* Keywords - control flow *)
  | "to"           { TO }
  | "give"         { GIVE }
  | "back"         { BACK }
  | "remember"     { REMEMBER }
  | "when"         { WHEN }
  | "otherwise"    { OTHERWISE }
  | "repeat"       { REPEAT }
  | "times"        { TIMES }

  (* Keywords - consent and safety *)
  | "only"         { ONLY }
  | "if"           { IF }
  | "okay"         { OKAY }
  | "attempt"      { ATTEMPT }
  | "safely"       { SAFELY }
  | "or"           { OR }
  | "reassure"     { REASSURE }
  | "complain"     { COMPLAIN }

  (* Keywords - gratitude *)
  | "thanks"       { THANKS }

  (* Keywords - lifecycle *)
  | "hello"        { HELLO }
  | "goodbye"      { GOODBYE }

  (* Keywords - concurrency *)
  | "worker"       { WORKER }
  | "side"         { SIDE }
  | "quest"        { QUEST }
  | "spawn"        { SPAWN }
  | "superpower"   { SUPERPOWER }

  (* Keywords - pattern matching *)
  | "decide"       { DECIDE }
  | "based"        { BASED }
  | "on"           { ON }

  (* Keywords - units *)
  | "measured"     { MEASURED }
  | "in"           { IN }

  (* Keywords - pragmas *)
  | '#'            { HASH }
  | "care"         { CARE }
  | "strict"       { STRICT }
  | "verbose"      { VERBOSE }

  (* Keywords - types *)
  | "String"       { TYPE_STRING }
  | "Int"          { TYPE_INT }
  | "Float"        { TYPE_FLOAT }
  | "Bool"         { TYPE_BOOL }
  | "Maybe"        { MAYBE }
  | "const"        { CONST }
  | "type"         { TYPE }
  | "use"          { USE }
  | "renamed"      { RENAMED }

  (* Keywords - boolean *)
  | "true"         { TRUE }
  | "false"        { FALSE }
  | "and"          { AND }
  | "not"          { NOT }

  (* Keywords - constraints *)
  | "must"         { MUST }
  | "have"         { HAVE }

  (* Keywords - io *)
  | "say"          { SAY }

  (* Literals *)
  | digit+ as n                   { INT (int_of_string n) }
  | digit+ '.' digit+ as f        { FLOAT (float_of_string f) }
  | '"' ([^ '"' '\\'] | '\\' _)* '"' as s
                                  { STRING (String.sub s 1 (String.length s - 2)) }
  | '_'                           { UNDERSCORE }

  (* Identifiers *)
  | ident as id                   { IDENT id }

  (* End of file *)
  | eof                           { EOF }

  (* Error *)
  | _ as c         { raise (LexError (Printf.sprintf "Unexpected character: '%c'" c)) }

and block_comment = parse
  | "*/"           { () }
  | newline        { newline lexbuf; block_comment lexbuf }
  | _              { block_comment lexbuf }
  | eof            { raise (LexError "Unterminated block comment") }
