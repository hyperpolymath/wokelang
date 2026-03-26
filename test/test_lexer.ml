(* SPDX-License-Identifier: PMPL-1.0-or-later *)
(* SPDX-FileCopyrightText: 2026 Hyperpolymath *)

(** WokeLang Lexer Test Suite

    Comprehensive Alcotest suite exercising every token category produced by
    [core/lexer.mll]:
    - Consent-based keywords (okay, reassure, complain, only, if, attempt, safely)
    - Gratitude keyword (thanks)
    - Concurrency keywords (spawn, superpower, worker, side, quest)
    - Control-flow keywords (when, otherwise, repeat, times, to, give, back)
    - Lifecycle keywords (hello, goodbye)
    - Operators (arithmetic, comparison, logical)
    - Literals (int, float, string, bool)
    - Comments (line and block)
    - Identifiers, delimiters, and special tokens
*)

open Wokelang_core

(** Helper: lex an entire source string into a token list (excluding EOF). *)
let tokenize source =
  let lexbuf = Lexing.from_string source in
  let rec collect acc =
    match Lexer.token lexbuf with
    | Parser.EOF -> List.rev acc
    | tok -> collect (tok :: acc)
  in
  collect []

(** Helper: lex a source string and return only the first token. *)
let first_token source =
  let lexbuf = Lexing.from_string source in
  Lexer.token lexbuf

(** Helper: assert that lexing raises [Lexer.LexError]. *)
let assert_lex_error source =
  try
    ignore (tokenize source);
    Alcotest.fail ("Expected LexError for input: " ^ source)
  with Lexer.LexError _ -> ()

(* ── Token equality testable ────────────────────────────────────────────── *)

(** Rough token-to-string for diagnostics — covers every variant. *)
let token_to_string = function
  | Parser.LPAREN -> "LPAREN" | Parser.RPAREN -> "RPAREN"
  | Parser.LBRACE -> "LBRACE" | Parser.RBRACE -> "RBRACE"
  | Parser.LBRACKET -> "LBRACKET" | Parser.RBRACKET -> "RBRACKET"
  | Parser.COMMA -> "COMMA" | Parser.SEMICOLON -> "SEMICOLON"
  | Parser.COLON -> "COLON" | Parser.EQUALS -> "EQUALS"
  | Parser.AT -> "AT" | Parser.ARROW -> "ARROW"
  | Parser.HASH -> "HASH" | Parser.UNDERSCORE -> "UNDERSCORE"
  | Parser.PLUS -> "PLUS" | Parser.MINUS -> "MINUS"
  | Parser.STAR -> "STAR" | Parser.SLASH -> "SLASH"
  | Parser.PERCENT -> "PERCENT"
  | Parser.EQEQ -> "EQEQ" | Parser.NE -> "NE"
  | Parser.LT -> "LT" | Parser.GT -> "GT"
  | Parser.LE -> "LE" | Parser.GE -> "GE"
  | Parser.TO -> "TO" | Parser.GIVE -> "GIVE" | Parser.BACK -> "BACK"
  | Parser.REMEMBER -> "REMEMBER"
  | Parser.WHEN -> "WHEN" | Parser.OTHERWISE -> "OTHERWISE"
  | Parser.REPEAT -> "REPEAT" | Parser.TIMES -> "TIMES"
  | Parser.ONLY -> "ONLY" | Parser.IF -> "IF" | Parser.OKAY -> "OKAY"
  | Parser.ATTEMPT -> "ATTEMPT" | Parser.SAFELY -> "SAFELY"
  | Parser.OR -> "OR" | Parser.REASSURE -> "REASSURE"
  | Parser.COMPLAIN -> "COMPLAIN"
  | Parser.THANKS -> "THANKS"
  | Parser.HELLO -> "HELLO" | Parser.GOODBYE -> "GOODBYE"
  | Parser.WORKER -> "WORKER" | Parser.SIDE -> "SIDE"
  | Parser.QUEST -> "QUEST" | Parser.SPAWN -> "SPAWN"
  | Parser.SUPERPOWER -> "SUPERPOWER"
  | Parser.DECIDE -> "DECIDE" | Parser.BASED -> "BASED" | Parser.ON -> "ON"
  | Parser.MEASURED -> "MEASURED" | Parser.IN -> "IN"
  | Parser.CARE -> "CARE" | Parser.STRICT -> "STRICT"
  | Parser.VERBOSE -> "VERBOSE"
  | Parser.TYPE_STRING -> "TYPE_STRING" | Parser.TYPE_INT -> "TYPE_INT"
  | Parser.TYPE_FLOAT -> "TYPE_FLOAT" | Parser.TYPE_BOOL -> "TYPE_BOOL"
  | Parser.MAYBE -> "MAYBE" | Parser.CONST -> "CONST"
  | Parser.TYPE -> "TYPE" | Parser.USE -> "USE" | Parser.RENAMED -> "RENAMED"
  | Parser.TRUE -> "TRUE" | Parser.FALSE -> "FALSE"
  | Parser.AND -> "AND" | Parser.NOT -> "NOT"
  | Parser.MUST -> "MUST" | Parser.HAVE -> "HAVE"
  | Parser.SAY -> "SAY"
  | Parser.INT n -> Printf.sprintf "INT(%d)" n
  | Parser.FLOAT f -> Printf.sprintf "FLOAT(%g)" f
  | Parser.STRING s -> Printf.sprintf "STRING(%s)" s
  | Parser.IDENT s -> Printf.sprintf "IDENT(%s)" s
  | Parser.EOF -> "EOF"

let token_equal a b =
  match (a, b) with
  | Parser.INT x, Parser.INT y -> x = y
  | Parser.FLOAT x, Parser.FLOAT y -> Float.equal x y
  | Parser.STRING x, Parser.STRING y -> String.equal x y
  | Parser.IDENT x, Parser.IDENT y -> String.equal x y
  | _ -> a = b

let token_testable : Parser.token Alcotest.testable =
  Alcotest.testable
    (fun ppf tok -> Format.pp_print_string ppf (token_to_string tok))
    token_equal

let token_list_testable : Parser.token list Alcotest.testable =
  Alcotest.list token_testable

let check_token msg expected actual =
  Alcotest.check token_testable msg expected actual

let check_tokens msg expected actual =
  Alcotest.check token_list_testable msg expected actual

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Consent-based keywords                                                 *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_keyword_okay () =
  check_token "okay" Parser.OKAY (first_token "okay")

let test_keyword_reassure () =
  check_token "reassure" Parser.REASSURE (first_token "reassure")

let test_keyword_complain () =
  check_token "complain" Parser.COMPLAIN (first_token "complain")

let test_keyword_only () =
  check_token "only" Parser.ONLY (first_token "only")

let test_keyword_if () =
  check_token "if" Parser.IF (first_token "if")

let test_keyword_attempt () =
  check_token "attempt" Parser.ATTEMPT (first_token "attempt")

let test_keyword_safely () =
  check_token "safely" Parser.SAFELY (first_token "safely")

let test_consent_keyword_sequence () =
  check_tokens "only if okay sequence"
    [Parser.ONLY; Parser.IF; Parser.OKAY; Parser.STRING "camera"]
    (tokenize {|only if okay "camera"|})

let test_attempt_safely_sequence () =
  check_tokens "attempt safely ... or reassure"
    [Parser.ATTEMPT; Parser.SAFELY; Parser.OR; Parser.REASSURE]
    (tokenize "attempt safely or reassure")

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Gratitude keyword                                                      *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_keyword_thanks () =
  check_token "thanks" Parser.THANKS (first_token "thanks")

let test_thanks_to_sequence () =
  check_tokens "thanks to {"
    [Parser.THANKS; Parser.TO; Parser.LBRACE]
    (tokenize "thanks to {")

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Concurrency keywords                                                   *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_keyword_spawn () =
  check_token "spawn" Parser.SPAWN (first_token "spawn")

let test_keyword_superpower () =
  check_token "superpower" Parser.SUPERPOWER (first_token "superpower")

let test_keyword_worker () =
  check_token "worker" Parser.WORKER (first_token "worker")

let test_keyword_side () =
  check_token "side" Parser.SIDE (first_token "side")

let test_keyword_quest () =
  check_token "quest" Parser.QUEST (first_token "quest")

let test_side_quest_sequence () =
  check_tokens "side quest name"
    [Parser.SIDE; Parser.QUEST; Parser.IDENT "myTask"]
    (tokenize "side quest myTask")

let test_spawn_worker_sequence () =
  check_tokens "spawn worker name"
    [Parser.SPAWN; Parser.WORKER; Parser.IDENT "bg"]
    (tokenize "spawn worker bg")

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Control-flow keywords                                                  *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_keyword_to () =
  check_token "to" Parser.TO (first_token "to")

let test_keyword_give () =
  check_token "give" Parser.GIVE (first_token "give")

let test_keyword_back () =
  check_token "back" Parser.BACK (first_token "back")

let test_keyword_remember () =
  check_token "remember" Parser.REMEMBER (first_token "remember")

let test_keyword_when () =
  check_token "when" Parser.WHEN (first_token "when")

let test_keyword_otherwise () =
  check_token "otherwise" Parser.OTHERWISE (first_token "otherwise")

let test_keyword_repeat () =
  check_token "repeat" Parser.REPEAT (first_token "repeat")

let test_keyword_times () =
  check_token "times" Parser.TIMES (first_token "times")

let test_give_back_sequence () =
  check_tokens "give back expr"
    [Parser.GIVE; Parser.BACK; Parser.INT 42; Parser.SEMICOLON]
    (tokenize "give back 42;")

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Lifecycle keywords                                                     *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_keyword_hello () =
  check_token "hello" Parser.HELLO (first_token "hello")

let test_keyword_goodbye () =
  check_token "goodbye" Parser.GOODBYE (first_token "goodbye")

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Pattern matching / units / pragmas / constraints / IO                  *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_keyword_decide () =
  check_token "decide" Parser.DECIDE (first_token "decide")

let test_keyword_based () =
  check_token "based" Parser.BASED (first_token "based")

let test_keyword_on () =
  check_token "on" Parser.ON (first_token "on")

let test_keyword_measured () =
  check_token "measured" Parser.MEASURED (first_token "measured")

let test_keyword_in () =
  check_token "in" Parser.IN (first_token "in")

let test_keyword_care () =
  check_token "care" Parser.CARE (first_token "care")

let test_keyword_strict () =
  check_token "strict" Parser.STRICT (first_token "strict")

let test_keyword_verbose () =
  check_token "verbose" Parser.VERBOSE (first_token "verbose")

let test_keyword_must () =
  check_token "must" Parser.MUST (first_token "must")

let test_keyword_have () =
  check_token "have" Parser.HAVE (first_token "have")

let test_keyword_say () =
  check_token "say" Parser.SAY (first_token "say")

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Type keywords                                                          *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_type_string () =
  check_token "String" Parser.TYPE_STRING (first_token "String")

let test_type_int () =
  check_token "Int" Parser.TYPE_INT (first_token "Int")

let test_type_float () =
  check_token "Float" Parser.TYPE_FLOAT (first_token "Float")

let test_type_bool () =
  check_token "Bool" Parser.TYPE_BOOL (first_token "Bool")

let test_type_maybe () =
  check_token "Maybe" Parser.MAYBE (first_token "Maybe")

let test_keyword_const () =
  check_token "const" Parser.CONST (first_token "const")

let test_keyword_type () =
  check_token "type" Parser.TYPE (first_token "type")

let test_keyword_use () =
  check_token "use" Parser.USE (first_token "use")

let test_keyword_renamed () =
  check_token "renamed" Parser.RENAMED (first_token "renamed")

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Boolean keywords                                                       *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_keyword_true () =
  check_token "true" Parser.TRUE (first_token "true")

let test_keyword_false () =
  check_token "false" Parser.FALSE (first_token "false")

let test_keyword_and () =
  check_token "and" Parser.AND (first_token "and")

let test_keyword_not () =
  check_token "not" Parser.NOT (first_token "not")

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Operators                                                              *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_arithmetic_operators () =
  check_tokens "arithmetic ops"
    [Parser.PLUS; Parser.MINUS; Parser.STAR; Parser.SLASH; Parser.PERCENT]
    (tokenize "+ - * / %")

let test_comparison_operators () =
  check_tokens "comparison ops"
    [Parser.EQEQ; Parser.NE; Parser.LE; Parser.GE; Parser.LT; Parser.GT]
    (tokenize "== != <= >= < >")

let test_assignment_equals () =
  check_token "=" Parser.EQUALS (first_token "=")

let test_arrow_unicode () =
  check_token "unicode arrow" Parser.ARROW (first_token "\xe2\x86\x92")

let test_arrow_ascii () =
  check_token "ascii arrow" Parser.ARROW (first_token "->")

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Delimiters                                                             *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_delimiters () =
  check_tokens "delimiters"
    [Parser.LPAREN; Parser.RPAREN; Parser.LBRACE; Parser.RBRACE;
     Parser.LBRACKET; Parser.RBRACKET; Parser.COMMA; Parser.SEMICOLON;
     Parser.COLON; Parser.AT; Parser.HASH; Parser.UNDERSCORE]
    (tokenize "( ) { } [ ] , ; : @ # _")

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Literals                                                               *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_int_literal () =
  check_token "integer 0" (Parser.INT 0) (first_token "0");
  check_token "integer 42" (Parser.INT 42) (first_token "42");
  check_token "integer 12345" (Parser.INT 12345) (first_token "12345")

let test_float_literal () =
  check_token "float 3.14" (Parser.FLOAT 3.14) (first_token "3.14");
  check_token "float 0.5" (Parser.FLOAT 0.5) (first_token "0.5")

let test_string_literal () =
  check_token "simple string"
    (Parser.STRING "hello") (first_token {|"hello"|});
  check_token "string with spaces"
    (Parser.STRING "hello world") (first_token {|"hello world"|})

let test_string_escape () =
  check_token "string with escape"
    (Parser.STRING {|hello\"world|})
    (first_token {|"hello\"world"|})

let test_empty_string () =
  check_token "empty string" (Parser.STRING "") (first_token {|""|})

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Identifiers                                                            *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_identifier_simple () =
  check_token "simple ident" (Parser.IDENT "foo") (first_token "foo")

let test_identifier_with_digits () =
  check_token "ident with digits" (Parser.IDENT "x42") (first_token "x42")

let test_identifier_with_underscore () =
  check_token "ident with underscore"
    (Parser.IDENT "my_var") (first_token "my_var")

let test_identifier_camel () =
  check_token "camelCase ident"
    (Parser.IDENT "myFunction") (first_token "myFunction")

let test_identifier_not_keyword () =
  (* "okay" is a keyword, but "okayish" is an identifier *)
  check_token "okayish is ident"
    (Parser.IDENT "okayish") (first_token "okayish")

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Comments                                                               *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_line_comment () =
  check_tokens "line comment skipped"
    [Parser.INT 42]
    (tokenize "// this is a comment\n42")

let test_line_comment_only () =
  check_tokens "line comment only"
    []
    (tokenize "// nothing here")

let test_block_comment () =
  check_tokens "block comment skipped"
    [Parser.INT 1; Parser.INT 2]
    (tokenize "1 /* skip this */ 2")

let test_block_comment_multiline () =
  check_tokens "multiline block comment"
    [Parser.INT 1; Parser.INT 2]
    (tokenize "1 /* line1\nline2\nline3 */ 2")

let test_unterminated_block_comment () =
  assert_lex_error "/* never closed"

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Whitespace                                                             *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_whitespace_tabs_spaces () =
  check_tokens "tabs and spaces ignored"
    [Parser.INT 1; Parser.INT 2]
    (tokenize "  1  \t  2  ")

let test_newlines () =
  check_tokens "newlines ignored"
    [Parser.INT 1; Parser.INT 2]
    (tokenize "1\n\n2")

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Error cases                                                            *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_unexpected_character () =
  assert_lex_error "~"

let test_unexpected_backtick () =
  assert_lex_error "`"

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Complex token sequences                                                *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_function_header () =
  check_tokens "to add(a: Int, b: Int) -> Int"
    [Parser.TO; Parser.IDENT "add"; Parser.LPAREN;
     Parser.IDENT "a"; Parser.COLON; Parser.TYPE_INT; Parser.COMMA;
     Parser.IDENT "b"; Parser.COLON; Parser.TYPE_INT; Parser.RPAREN;
     Parser.ARROW; Parser.TYPE_INT]
    (tokenize "to add(a: Int, b: Int) -> Int")

let test_remember_with_units () =
  check_tokens "remember d = 5 measured in km"
    [Parser.REMEMBER; Parser.IDENT "d"; Parser.EQUALS;
     Parser.INT 5; Parser.MEASURED; Parser.IN; Parser.IDENT "km";
     Parser.SEMICOLON]
    (tokenize "remember d = 5 measured in km;")

let test_emote_annotation () =
  check_tokens "@enthusiastic to greet()"
    [Parser.AT; Parser.IDENT "enthusiastic";
     Parser.TO; Parser.IDENT "greet"; Parser.LPAREN; Parser.RPAREN]
    (tokenize "@enthusiastic to greet()")

let test_emote_with_params () =
  check_tokens "@mood(level = 5)"
    [Parser.AT; Parser.IDENT "mood"; Parser.LPAREN;
     Parser.IDENT "level"; Parser.EQUALS; Parser.INT 5;
     Parser.RPAREN]
    (tokenize "@mood(level = 5)")

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Suite registration                                                     *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let consent_tests =
  [ "okay",      `Quick, test_keyword_okay
  ; "reassure",  `Quick, test_keyword_reassure
  ; "complain",  `Quick, test_keyword_complain
  ; "only",      `Quick, test_keyword_only
  ; "if",        `Quick, test_keyword_if
  ; "attempt",   `Quick, test_keyword_attempt
  ; "safely",    `Quick, test_keyword_safely
  ; "consent keyword sequence", `Quick, test_consent_keyword_sequence
  ; "attempt safely sequence",  `Quick, test_attempt_safely_sequence
  ]

let gratitude_tests =
  [ "thanks",          `Quick, test_keyword_thanks
  ; "thanks to seq",   `Quick, test_thanks_to_sequence
  ]

let concurrency_tests =
  [ "spawn",      `Quick, test_keyword_spawn
  ; "superpower", `Quick, test_keyword_superpower
  ; "worker",     `Quick, test_keyword_worker
  ; "side",       `Quick, test_keyword_side
  ; "quest",      `Quick, test_keyword_quest
  ; "side quest sequence",  `Quick, test_side_quest_sequence
  ; "spawn worker sequence", `Quick, test_spawn_worker_sequence
  ]

let control_flow_tests =
  [ "to",        `Quick, test_keyword_to
  ; "give",      `Quick, test_keyword_give
  ; "back",      `Quick, test_keyword_back
  ; "remember",  `Quick, test_keyword_remember
  ; "when",      `Quick, test_keyword_when
  ; "otherwise", `Quick, test_keyword_otherwise
  ; "repeat",    `Quick, test_keyword_repeat
  ; "times",     `Quick, test_keyword_times
  ; "give back sequence", `Quick, test_give_back_sequence
  ]

let lifecycle_tests =
  [ "hello",   `Quick, test_keyword_hello
  ; "goodbye", `Quick, test_keyword_goodbye
  ]

let misc_keyword_tests =
  [ "decide",   `Quick, test_keyword_decide
  ; "based",    `Quick, test_keyword_based
  ; "on",       `Quick, test_keyword_on
  ; "measured", `Quick, test_keyword_measured
  ; "in",       `Quick, test_keyword_in
  ; "care",     `Quick, test_keyword_care
  ; "strict",   `Quick, test_keyword_strict
  ; "verbose",  `Quick, test_keyword_verbose
  ; "must",     `Quick, test_keyword_must
  ; "have",     `Quick, test_keyword_have
  ; "say",      `Quick, test_keyword_say
  ]

let type_keyword_tests =
  [ "String",  `Quick, test_type_string
  ; "Int",     `Quick, test_type_int
  ; "Float",   `Quick, test_type_float
  ; "Bool",    `Quick, test_type_bool
  ; "Maybe",   `Quick, test_type_maybe
  ; "const",   `Quick, test_keyword_const
  ; "type",    `Quick, test_keyword_type
  ; "use",     `Quick, test_keyword_use
  ; "renamed", `Quick, test_keyword_renamed
  ]

let boolean_tests =
  [ "true",  `Quick, test_keyword_true
  ; "false", `Quick, test_keyword_false
  ; "and",   `Quick, test_keyword_and
  ; "not",   `Quick, test_keyword_not
  ]

let operator_tests =
  [ "arithmetic",  `Quick, test_arithmetic_operators
  ; "comparison",  `Quick, test_comparison_operators
  ; "assignment",  `Quick, test_assignment_equals
  ; "arrow unicode", `Quick, test_arrow_unicode
  ; "arrow ascii",   `Quick, test_arrow_ascii
  ]

let delimiter_tests =
  [ "all delimiters", `Quick, test_delimiters ]

let literal_tests =
  [ "int",          `Quick, test_int_literal
  ; "float",        `Quick, test_float_literal
  ; "string",       `Quick, test_string_literal
  ; "string escape", `Quick, test_string_escape
  ; "empty string", `Quick, test_empty_string
  ]

let identifier_tests =
  [ "simple",         `Quick, test_identifier_simple
  ; "with digits",    `Quick, test_identifier_with_digits
  ; "with underscore", `Quick, test_identifier_with_underscore
  ; "camelCase",      `Quick, test_identifier_camel
  ; "not a keyword",  `Quick, test_identifier_not_keyword
  ]

let comment_tests =
  [ "line comment",       `Quick, test_line_comment
  ; "line comment only",  `Quick, test_line_comment_only
  ; "block comment",      `Quick, test_block_comment
  ; "block multiline",    `Quick, test_block_comment_multiline
  ; "unterminated block", `Quick, test_unterminated_block_comment
  ]

let whitespace_tests =
  [ "tabs and spaces", `Quick, test_whitespace_tabs_spaces
  ; "newlines",        `Quick, test_newlines
  ]

let error_tests =
  [ "unexpected char",    `Quick, test_unexpected_character
  ; "unexpected backtick", `Quick, test_unexpected_backtick
  ]

let complex_tests =
  [ "function header",     `Quick, test_function_header
  ; "remember with units", `Quick, test_remember_with_units
  ; "emote annotation",    `Quick, test_emote_annotation
  ; "emote with params",   `Quick, test_emote_with_params
  ]

let () =
  Alcotest.run "WokeLang Lexer"
    [ "consent keywords",    consent_tests
    ; "gratitude keywords",  gratitude_tests
    ; "concurrency keywords", concurrency_tests
    ; "control-flow keywords", control_flow_tests
    ; "lifecycle keywords",  lifecycle_tests
    ; "misc keywords",       misc_keyword_tests
    ; "type keywords",       type_keyword_tests
    ; "boolean keywords",    boolean_tests
    ; "operators",           operator_tests
    ; "delimiters",          delimiter_tests
    ; "literals",            literal_tests
    ; "identifiers",         identifier_tests
    ; "comments",            comment_tests
    ; "whitespace",          whitespace_tests
    ; "errors",              error_tests
    ; "complex sequences",   complex_tests
    ]
