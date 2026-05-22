(* SPDX-License-Identifier: MPL-2.0 *)
(* SPDX-FileCopyrightText: 2026 Hyperpolymath *)

(** WokeLang Parser Test Suite

    Comprehensive Alcotest suite exercising every grammar production in
    [core/parser.mly] against the AST types from [core/ast.ml]:
    - Consent-gated expressions (only if okay)
    - Gratitude blocks (thanks to)
    - Function definitions (to / give back)
    - Variable declarations (remember)
    - Conditionals (when / otherwise)
    - Loops (repeat ... times)
    - Safety blocks (attempt safely / or reassure)
    - Type annotations and custom types
    - Dimensional analysis (measured in units)
    - \@emote annotations
    - Workers and side quests
    - Constants
    - Expressions (arithmetic, comparison, logical, unary)
*)

open Wokelang_core

(** Parse source code into a program AST. *)
let parse source =
  let lexbuf = Lexing.from_string source in
  Parser.program Lexer.token lexbuf

(** Assert that parsing succeeds and return the program. *)
let must_parse source =
  try parse source
  with e ->
    Alcotest.fail
      (Printf.sprintf "Parse failed on:\n%s\nError: %s"
        source (Printexc.to_string e))

(** Assert that parsing fails with a Parser.Error or Lexer.LexError. *)
let must_fail source =
  try
    ignore (parse source);
    Alcotest.fail
      (Printf.sprintf "Expected parse failure on:\n%s" source)
  with
  | Parser.Error -> ()
  | Lexer.LexError _ -> ()

(** Assert that the program has exactly [n] top-level items. *)
let assert_toplevel_count n prog =
  Alcotest.(check int) "top-level item count" n (List.length prog)

(* ── Helpers to extract top-level variants ──────────────────────────── *)

let get_function prog idx =
  match List.nth prog idx with
  | Ast.TLFunction f -> f
  | _ -> Alcotest.fail "expected TLFunction"

let get_gratitude prog idx =
  match List.nth prog idx with
  | Ast.TLGratitude g -> g
  | _ -> Alcotest.fail "expected TLGratitude"

let get_worker prog idx =
  match List.nth prog idx with
  | Ast.TLWorker w -> w
  | _ -> Alcotest.fail "expected TLWorker"

let get_side_quest prog idx =
  match List.nth prog idx with
  | Ast.TLSideQuest sq -> sq
  | _ -> Alcotest.fail "expected TLSideQuest"

let get_const prog idx =
  match List.nth prog idx with
  | Ast.TLConst (name, typ, expr) -> (name, typ, expr)
  | _ -> Alcotest.fail "expected TLConst"

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Function definitions                                                   *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_simple_function () =
  let prog = must_parse "to greet() { }" in
  assert_toplevel_count 1 prog;
  let f = get_function prog 0 in
  Alcotest.(check string) "name" "greet" f.name;
  Alcotest.(check int) "params" 0 (List.length f.params);
  Alcotest.(check bool) "no return type" true (Option.is_none f.return_type);
  Alcotest.(check int) "empty body" 0 (List.length f.body)

let test_function_with_params () =
  let prog = must_parse "to add(a: Int, b: Int) -> Int { give back a + b; }" in
  let f = get_function prog 0 in
  Alcotest.(check string) "name" "add" f.name;
  Alcotest.(check int) "param count" 2 (List.length f.params);
  let p0 = List.nth f.params 0 in
  let p1 = List.nth f.params 1 in
  Alcotest.(check string) "p0 name" "a" p0.name;
  Alcotest.(check string) "p1 name" "b" p1.name;
  Alcotest.(check bool) "p0 has type" true (Option.is_some p0.typ);
  Alcotest.(check bool) "return type present" true (Option.is_some f.return_type);
  (match f.return_type with
   | Some Ast.TInt -> ()
   | _ -> Alcotest.fail "expected return type TInt")

let test_function_untyped_params () =
  let prog = must_parse "to f(x, y) { }" in
  let f = get_function prog 0 in
  Alcotest.(check int) "param count" 2 (List.length f.params);
  let p0 = List.nth f.params 0 in
  Alcotest.(check bool) "p0 no type" true (Option.is_none p0.typ)

let test_function_hello_goodbye () =
  let prog = must_parse {|
    to demo() {
      hello "Starting up";
      say "working";
      goodbye "Shutting down";
    }
  |} in
  let f = get_function prog 0 in
  Alcotest.(check bool) "has hello" true (Option.is_some f.hello_msg);
  Alcotest.(check bool) "has goodbye" true (Option.is_some f.goodbye_msg);
  (match f.hello_msg with
   | Some "Starting up" -> ()
   | _ -> Alcotest.fail "wrong hello msg");
  (match f.goodbye_msg with
   | Some "Shutting down" -> ()
   | _ -> Alcotest.fail "wrong goodbye msg")

let test_function_unicode_arrow () =
  let prog = must_parse
    ("to id(x: Int) \xe2\x86\x92 Int { give back x; }") in
  let f = get_function prog 0 in
  Alcotest.(check bool) "return type" true (Option.is_some f.return_type)

let test_multiple_functions () =
  let prog = must_parse {|
    to first() { }
    to second() { }
  |} in
  assert_toplevel_count 2 prog

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Variable declarations (remember)                                       *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_remember_simple () =
  let prog = must_parse "to f() { remember x = 42; }" in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SRemember ("x", Ast.EInt 42, None)] -> ()
  | _ -> Alcotest.fail "expected SRemember x = 42"

let test_remember_string () =
  let prog = must_parse {|to f() { remember name = "hello"; }|} in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SRemember ("name", Ast.EString "hello", None)] -> ()
  | _ -> Alcotest.fail "expected SRemember name = string"

let test_remember_bool () =
  let prog = must_parse "to f() { remember flag = true; }" in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SRemember ("flag", Ast.EBool true, None)] -> ()
  | _ -> Alcotest.fail "expected SRemember flag = true"

let test_remember_float () =
  let prog = must_parse "to f() { remember pi = 3.14; }" in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SRemember ("pi", Ast.EFloat _, None)] -> ()
  | _ -> Alcotest.fail "expected SRemember pi = float"

let test_remember_expr () =
  let prog = must_parse "to f() { remember x = 2 + 3 * 4; }" in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SRemember ("x", Ast.EBinOp (Ast.OpAdd, _, _), None)] -> ()
  | _ -> Alcotest.fail "expected SRemember with add expr"

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Assignment                                                             *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_assign () =
  let prog = must_parse "to f() { x = 10; }" in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SAssign ("x", Ast.EInt 10)] -> ()
  | _ -> Alcotest.fail "expected SAssign"

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Give back (return)                                                     *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_give_back_int () =
  let prog = must_parse "to f() { give back 42; }" in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SGiveBack (Ast.EInt 42)] -> ()
  | _ -> Alcotest.fail "expected SGiveBack 42"

let test_give_back_expr () =
  let prog = must_parse "to f() { give back x + y; }" in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SGiveBack (Ast.EBinOp (Ast.OpAdd, _, _))] -> ()
  | _ -> Alcotest.fail "expected SGiveBack with add"

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Consent-gated expressions (only if okay)                               *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_consent_basic () =
  let prog = must_parse {|
    to f() {
      only if okay "camera" {
        say "accessing camera";
      }
    }
  |} in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SConsent ("camera", body)] ->
    Alcotest.(check int) "consent body stmts" 1 (List.length body)
  | _ -> Alcotest.fail "expected SConsent"

let test_consent_nested () =
  let prog = must_parse {|
    to f() {
      only if okay "network" {
        only if okay "location" {
          say "both granted";
        }
      }
    }
  |} in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SConsent ("network", [Ast.SConsent ("location", _)])] -> ()
  | _ -> Alcotest.fail "expected nested SConsent"

let test_consent_multiple_stmts () =
  let prog = must_parse {|
    to f() {
      only if okay "file" {
        remember a = 1;
        remember b = 2;
        say "done";
      }
    }
  |} in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SConsent ("file", body)] ->
    Alcotest.(check int) "body length" 3 (List.length body)
  | _ -> Alcotest.fail "expected SConsent with 3 stmts"

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Gratitude blocks (thanks to)                                           *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_gratitude_basic () =
  let prog = must_parse {|
    thanks to {
      "Alice" -> "Bug fix";
      "Bob" -> "Feature";
    }
  |} in
  assert_toplevel_count 1 prog;
  let g = get_gratitude prog 0 in
  Alcotest.(check int) "entry count" 2 (List.length g);
  let e0 = List.nth g 0 in
  Alcotest.(check string) "contributor" "Alice" e0.contributor;
  Alcotest.(check string) "contribution" "Bug fix" e0.contribution

let test_gratitude_unicode_arrow () =
  let prog = must_parse
    ("thanks to {\n  \"Alice\" \xe2\x86\x92 \"Docs\";\n}") in
  let g = get_gratitude prog 0 in
  Alcotest.(check int) "entry count" 1 (List.length g)

let test_gratitude_empty () =
  let prog = must_parse "thanks to { }" in
  let g = get_gratitude prog 0 in
  Alcotest.(check int) "empty gratitude" 0 (List.length g)

let test_gratitude_single () =
  let prog = must_parse {|
    thanks to {
      "Contributor" -> "Everything";
    }
  |} in
  let g = get_gratitude prog 0 in
  Alcotest.(check int) "single entry" 1 (List.length g)

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Conditionals (when / otherwise)                                        *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_when_basic () =
  let prog = must_parse {|
    to f() {
      when true {
        say "yes";
      }
    }
  |} in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SWhen (Ast.EBool true, body, None)] ->
    Alcotest.(check int) "then body" 1 (List.length body)
  | _ -> Alcotest.fail "expected SWhen without otherwise"

let test_when_otherwise () =
  let prog = must_parse {|
    to f() {
      when x > 0 {
        say "positive";
      } otherwise {
        say "non-positive";
      }
    }
  |} in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SWhen (_, then_body, Some else_body)] ->
    Alcotest.(check int) "then body" 1 (List.length then_body);
    Alcotest.(check int) "else body" 1 (List.length else_body)
  | _ -> Alcotest.fail "expected SWhen with otherwise"

let test_when_comparison () =
  let prog = must_parse {|
    to f() {
      when a == b {
        say "equal";
      }
    }
  |} in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SWhen (Ast.EBinOp (Ast.OpEq, _, _), _, _)] -> ()
  | _ -> Alcotest.fail "expected SWhen with OpEq"

let test_when_nested () =
  let prog = must_parse {|
    to f() {
      when x > 0 {
        when x < 10 {
          say "single digit";
        }
      }
    }
  |} in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SWhen (_, [Ast.SWhen _], None)] -> ()
  | _ -> Alcotest.fail "expected nested SWhen"

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Loops (repeat ... times)                                               *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_repeat_literal () =
  let prog = must_parse {|
    to f() {
      repeat 5 times {
        say "loop";
      }
    }
  |} in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SRepeat (Ast.EInt 5, body)] ->
    Alcotest.(check int) "loop body" 1 (List.length body)
  | _ -> Alcotest.fail "expected SRepeat 5"

let test_repeat_variable () =
  let prog = must_parse {|
    to f() {
      repeat n times {
        say "go";
      }
    }
  |} in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SRepeat (Ast.EIdent "n", _)] -> ()
  | _ -> Alcotest.fail "expected SRepeat with variable"

let test_repeat_expr () =
  let prog = must_parse {|
    to f() {
      repeat 2 + 3 times {
        say "five";
      }
    }
  |} in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SRepeat (Ast.EBinOp (Ast.OpAdd, _, _), _)] -> ()
  | _ -> Alcotest.fail "expected SRepeat with expr"

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Safety blocks (attempt safely / or reassure)                           *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_attempt_safely () =
  let prog = must_parse {|
    to f() {
      attempt safely {
        say "trying";
      } or reassure "all good";
    }
  |} in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SAttempt (body, msg)] ->
    Alcotest.(check int) "attempt body" 1 (List.length body);
    Alcotest.(check string) "reassure msg" "all good" msg
  | _ -> Alcotest.fail "expected SAttempt"

let test_attempt_multi_stmt () =
  let prog = must_parse {|
    to f() {
      attempt safely {
        remember x = 1;
        remember y = 2;
      } or reassure "handled";
    }
  |} in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SAttempt (body, _)] ->
    Alcotest.(check int) "attempt body stmts" 2 (List.length body)
  | _ -> Alcotest.fail "expected SAttempt with 2 stmts"

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Dimensional analysis (measured in units)                               *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_measured_in_remember () =
  (* The expr rule consumes "measured in" via EMeasured in primary_expr,
     so the optional unit on SRemember is None. *)
  let prog = must_parse "to f() { remember d = 5 measured in km; }" in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SRemember ("d", Ast.EMeasured (Ast.EInt 5, "km"), None)] -> ()
  | _ -> Alcotest.fail "expected SRemember with EMeasured expr"

let test_measured_in_expr () =
  let prog = must_parse "to f() { remember t = 3.5 measured in seconds; }" in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SRemember ("t", Ast.EMeasured (Ast.EFloat _, "seconds"), None)] -> ()
  | _ -> Alcotest.fail "expected SRemember with EMeasured float"

let test_measured_in_expression_context () =
  (* measured in as an expression: 42 measured in meters *)
  let prog = must_parse "to f() { give back 42 measured in meters; }" in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SGiveBack (Ast.EMeasured (Ast.EInt 42, "meters"))] -> ()
  | _ -> Alcotest.fail "expected SGiveBack with EMeasured"

(* ═══════════════════════════════════════════════════════════════════════ *)
(* @emote annotations                                                     *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_emote_function () =
  let prog = must_parse "@enthusiastic to greet() { }" in
  let f = get_function prog 0 in
  match f.emote with
  | Some e ->
    Alcotest.(check string) "emote name" "enthusiastic" e.name;
    Alcotest.(check int) "no params" 0 (List.length e.params)
  | None -> Alcotest.fail "expected emote tag"

let test_emote_with_params () =
  let prog = must_parse "@mood(level = 5) to greet() { }" in
  let f = get_function prog 0 in
  match f.emote with
  | Some e ->
    Alcotest.(check string) "emote name" "mood" e.name;
    Alcotest.(check int) "param count" 1 (List.length e.params);
    let (pname, pval) = List.nth e.params 0 in
    Alcotest.(check string) "param name" "level" pname;
    (match pval with
     | Ast.EInt 5 -> ()
     | _ -> Alcotest.fail "expected param value EInt 5")
  | None -> Alcotest.fail "expected emote tag"

let test_emote_multi_params () =
  let prog = must_parse {|@style(color = "red", size = 12) to f() { }|} in
  let f = get_function prog 0 in
  match f.emote with
  | Some e ->
    Alcotest.(check int) "param count" 2 (List.length e.params)
  | None -> Alcotest.fail "expected emote tag"

let test_emote_on_statement () =
  let prog = must_parse {|
    to f() {
      @careful remember x = 42;
    }
  |} in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SEmoteAnnotated (emote, Ast.SRemember _)] ->
    Alcotest.(check string) "emote name" "careful" emote.name
  | _ -> Alcotest.fail "expected SEmoteAnnotated"

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Workers and side quests                                                *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_worker_def () =
  let prog = must_parse {|
    worker background {
      remember x = 1;
    }
  |} in
  let w = get_worker prog 0 in
  Alcotest.(check string) "worker name" "background" w.worker_name;
  Alcotest.(check int) "body stmts" 1 (List.length w.worker_body)

let test_worker_empty () =
  let prog = must_parse "worker idle { }" in
  let w = get_worker prog 0 in
  Alcotest.(check string) "worker name" "idle" w.worker_name;
  Alcotest.(check int) "empty body" 0 (List.length w.worker_body)

let test_side_quest_def () =
  let prog = must_parse {|
    side quest bonus {
      say "side quest";
    }
  |} in
  let sq = get_side_quest prog 0 in
  Alcotest.(check string) "quest name" "bonus" sq.quest_name;
  Alcotest.(check int) "body stmts" 1 (List.length sq.quest_body)

let test_spawn_worker_stmt () =
  let prog = must_parse {|
    to f() {
      spawn worker bg;
    }
  |} in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SSpawnWorker "bg"] -> ()
  | _ -> Alcotest.fail "expected SSpawnWorker"

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Constants                                                              *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_const_typed () =
  let prog = must_parse "const PI: Float = 3.14;" in
  let (name, typ, _expr) = get_const prog 0 in
  Alcotest.(check string) "name" "PI" name;
  (match typ with
   | Some Ast.TFloat -> ()
   | _ -> Alcotest.fail "expected TFloat")

let test_const_untyped () =
  let prog = must_parse "const MAX = 100;" in
  let (name, typ, _expr) = get_const prog 0 in
  Alcotest.(check string) "name" "MAX" name;
  Alcotest.(check bool) "no type" true (Option.is_none typ)

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Type annotations                                                       *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_type_string () =
  let prog = must_parse "to f(x: String) { }" in
  let f = get_function prog 0 in
  match (List.nth f.params 0).typ with
  | Some Ast.TString -> ()
  | _ -> Alcotest.fail "expected TString"

let test_type_array () =
  let prog = must_parse "to f(xs: [Int]) { }" in
  let f = get_function prog 0 in
  match (List.nth f.params 0).typ with
  | Some (Ast.TArray Ast.TInt) -> ()
  | _ -> Alcotest.fail "expected TArray TInt"

let test_type_maybe () =
  let prog = must_parse "to f(x: Maybe String) { }" in
  let f = get_function prog 0 in
  match (List.nth f.params 0).typ with
  | Some (Ast.TMaybe Ast.TString) -> ()
  | _ -> Alcotest.fail "expected TMaybe TString"

let test_type_custom () =
  let prog = must_parse "to f(x: MyType) { }" in
  let f = get_function prog 0 in
  match (List.nth f.params 0).typ with
  | Some (Ast.TCustom "MyType") -> ()
  | _ -> Alcotest.fail "expected TCustom MyType"

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Expressions                                                            *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let extract_remember_expr src =
  let prog = must_parse ("to f() { remember r = " ^ src ^ "; }") in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SRemember (_, e, _)] -> e
  | _ -> Alcotest.fail "expected SRemember"

let test_expr_int () =
  match extract_remember_expr "42" with
  | Ast.EInt 42 -> ()
  | _ -> Alcotest.fail "expected EInt 42"

let test_expr_float () =
  match extract_remember_expr "2.5" with
  | Ast.EFloat f when f = 2.5 -> ()
  | _ -> Alcotest.fail "expected EFloat 2.5"

let test_expr_string () =
  match extract_remember_expr {|"hello"|} with
  | Ast.EString "hello" -> ()
  | _ -> Alcotest.fail "expected EString hello"

let test_expr_bool_true () =
  match extract_remember_expr "true" with
  | Ast.EBool true -> ()
  | _ -> Alcotest.fail "expected EBool true"

let test_expr_bool_false () =
  match extract_remember_expr "false" with
  | Ast.EBool false -> ()
  | _ -> Alcotest.fail "expected EBool false"

let test_expr_ident () =
  match extract_remember_expr "myVar" with
  | Ast.EIdent "myVar" -> ()
  | _ -> Alcotest.fail "expected EIdent myVar"

let test_expr_array () =
  match extract_remember_expr "[1, 2, 3]" with
  | Ast.EArray [Ast.EInt 1; Ast.EInt 2; Ast.EInt 3] -> ()
  | _ -> Alcotest.fail "expected EArray [1,2,3]"

let test_expr_empty_array () =
  match extract_remember_expr "[]" with
  | Ast.EArray [] -> ()
  | _ -> Alcotest.fail "expected EArray []"

let test_expr_call_no_args () =
  match extract_remember_expr "foo()" with
  | Ast.ECall ("foo", []) -> ()
  | _ -> Alcotest.fail "expected ECall foo()"

let test_expr_call_with_args () =
  match extract_remember_expr "add(1, 2)" with
  | Ast.ECall ("add", [Ast.EInt 1; Ast.EInt 2]) -> ()
  | _ -> Alcotest.fail "expected ECall add(1, 2)"

let test_expr_nested_call () =
  match extract_remember_expr "f(g(x))" with
  | Ast.ECall ("f", [Ast.ECall ("g", [Ast.EIdent "x"])]) -> ()
  | _ -> Alcotest.fail "expected nested call"

let test_expr_add () =
  match extract_remember_expr "1 + 2" with
  | Ast.EBinOp (Ast.OpAdd, Ast.EInt 1, Ast.EInt 2) -> ()
  | _ -> Alcotest.fail "expected add"

let test_expr_sub () =
  match extract_remember_expr "5 - 3" with
  | Ast.EBinOp (Ast.OpSub, Ast.EInt 5, Ast.EInt 3) -> ()
  | _ -> Alcotest.fail "expected sub"

let test_expr_mul () =
  match extract_remember_expr "2 * 3" with
  | Ast.EBinOp (Ast.OpMul, Ast.EInt 2, Ast.EInt 3) -> ()
  | _ -> Alcotest.fail "expected mul"

let test_expr_div () =
  match extract_remember_expr "10 / 2" with
  | Ast.EBinOp (Ast.OpDiv, Ast.EInt 10, Ast.EInt 2) -> ()
  | _ -> Alcotest.fail "expected div"

let test_expr_mod () =
  match extract_remember_expr "7 % 3" with
  | Ast.EBinOp (Ast.OpMod, Ast.EInt 7, Ast.EInt 3) -> ()
  | _ -> Alcotest.fail "expected mod"

let test_expr_precedence_mul_over_add () =
  (* 1 + 2 * 3 should parse as 1 + (2 * 3) *)
  match extract_remember_expr "1 + 2 * 3" with
  | Ast.EBinOp (Ast.OpAdd, Ast.EInt 1,
      Ast.EBinOp (Ast.OpMul, Ast.EInt 2, Ast.EInt 3)) -> ()
  | _ -> Alcotest.fail "expected correct precedence: 1 + (2 * 3)"

let test_expr_precedence_parens () =
  (* (1 + 2) * 3 should parse as (1 + 2) * 3 *)
  match extract_remember_expr "(1 + 2) * 3" with
  | Ast.EBinOp (Ast.OpMul,
      Ast.EBinOp (Ast.OpAdd, Ast.EInt 1, Ast.EInt 2),
      Ast.EInt 3) -> ()
  | _ -> Alcotest.fail "expected (1 + 2) * 3"

let test_expr_comparison_eq () =
  match extract_remember_expr "a == b" with
  | Ast.EBinOp (Ast.OpEq, Ast.EIdent "a", Ast.EIdent "b") -> ()
  | _ -> Alcotest.fail "expected OpEq"

let test_expr_comparison_ne () =
  match extract_remember_expr "a != b" with
  | Ast.EBinOp (Ast.OpNe, Ast.EIdent "a", Ast.EIdent "b") -> ()
  | _ -> Alcotest.fail "expected OpNe"

let test_expr_comparison_lt () =
  match extract_remember_expr "a < b" with
  | Ast.EBinOp (Ast.OpLt, Ast.EIdent "a", Ast.EIdent "b") -> ()
  | _ -> Alcotest.fail "expected OpLt"

let test_expr_comparison_gt () =
  match extract_remember_expr "a > b" with
  | Ast.EBinOp (Ast.OpGt, Ast.EIdent "a", Ast.EIdent "b") -> ()
  | _ -> Alcotest.fail "expected OpGt"

let test_expr_comparison_le () =
  match extract_remember_expr "a <= b" with
  | Ast.EBinOp (Ast.OpLe, Ast.EIdent "a", Ast.EIdent "b") -> ()
  | _ -> Alcotest.fail "expected OpLe"

let test_expr_comparison_ge () =
  match extract_remember_expr "a >= b" with
  | Ast.EBinOp (Ast.OpGe, Ast.EIdent "a", Ast.EIdent "b") -> ()
  | _ -> Alcotest.fail "expected OpGe"

let test_expr_logical_and () =
  match extract_remember_expr "true and false" with
  | Ast.EBinOp (Ast.OpAnd, Ast.EBool true, Ast.EBool false) -> ()
  | _ -> Alcotest.fail "expected OpAnd"

let test_expr_logical_or () =
  match extract_remember_expr "true or false" with
  | Ast.EBinOp (Ast.OpOr, Ast.EBool true, Ast.EBool false) -> ()
  | _ -> Alcotest.fail "expected OpOr"

let test_expr_not () =
  match extract_remember_expr "not true" with
  | Ast.EUnaryOp (Ast.OpNot, Ast.EBool true) -> ()
  | _ -> Alcotest.fail "expected OpNot"

let test_expr_negate () =
  match extract_remember_expr "-42" with
  | Ast.EUnaryOp (Ast.OpNeg, Ast.EInt 42) -> ()
  | _ -> Alcotest.fail "expected OpNeg"

let test_expr_thanks () =
  match extract_remember_expr {|thanks("Alice")|} with
  | Ast.EThanks "Alice" -> ()
  | _ -> Alcotest.fail "expected EThanks"

let test_expr_measured_in () =
  match extract_remember_expr "100 measured in km" with
  | Ast.EMeasured (Ast.EInt 100, "km") -> ()
  | _ -> Alcotest.fail "expected EMeasured"

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Say statement                                                          *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_say () =
  let prog = must_parse {|to f() { say "hello"; }|} in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SExpr (Ast.ECall ("say", [Ast.EString "hello"]))] -> ()
  | _ -> Alcotest.fail "expected say rewritten to ECall"

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Complain statement                                                     *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_complain () =
  let prog = must_parse {|to f() { complain "error"; }|} in
  let f = get_function prog 0 in
  match f.body with
  | [Ast.SComplain "error"] -> ()
  | _ -> Alcotest.fail "expected SComplain"

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Mixed top-level items                                                  *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_mixed_toplevel () =
  let prog = must_parse {|
    thanks to {
      "Alice" -> "Docs";
    }
    const MAX: Int = 100;
    to main() {
      say "hello";
    }
    worker bg {
      remember x = 1;
    }
    side quest bonus {
      say "side";
    }
  |} in
  assert_toplevel_count 5 prog;
  (match List.nth prog 0 with Ast.TLGratitude _ -> () | _ -> Alcotest.fail "expected TLGratitude at 0");
  (match List.nth prog 1 with Ast.TLConst _ -> () | _ -> Alcotest.fail "expected TLConst at 1");
  (match List.nth prog 2 with Ast.TLFunction _ -> () | _ -> Alcotest.fail "expected TLFunction at 2");
  (match List.nth prog 3 with Ast.TLWorker _ -> () | _ -> Alcotest.fail "expected TLWorker at 3");
  (match List.nth prog 4 with Ast.TLSideQuest _ -> () | _ -> Alcotest.fail "expected TLSideQuest at 4")

let test_empty_program () =
  let prog = must_parse "" in
  assert_toplevel_count 0 prog

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Parse errors                                                           *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let test_error_missing_paren () =
  must_fail "to main( { }"

let test_error_missing_brace () =
  must_fail "to main() {"

let test_error_missing_semicolon () =
  must_fail "to f() { remember x = 5 }"

let test_error_bare_give () =
  must_fail "to f() { give 42; }"

let test_error_consent_no_string () =
  must_fail "to f() { only if okay { } }"

(* ═══════════════════════════════════════════════════════════════════════ *)
(* Suite registration                                                     *)
(* ═══════════════════════════════════════════════════════════════════════ *)

let function_tests =
  [ "simple function",       `Quick, test_simple_function
  ; "function with params",  `Quick, test_function_with_params
  ; "untyped params",        `Quick, test_function_untyped_params
  ; "hello/goodbye",         `Quick, test_function_hello_goodbye
  ; "unicode arrow",         `Quick, test_function_unicode_arrow
  ; "multiple functions",    `Quick, test_multiple_functions
  ]

let remember_tests =
  [ "simple",  `Quick, test_remember_simple
  ; "string",  `Quick, test_remember_string
  ; "bool",    `Quick, test_remember_bool
  ; "float",   `Quick, test_remember_float
  ; "expr",    `Quick, test_remember_expr
  ]

let assign_tests =
  [ "assign", `Quick, test_assign ]

let give_back_tests =
  [ "int",  `Quick, test_give_back_int
  ; "expr", `Quick, test_give_back_expr
  ]

let consent_tests =
  [ "basic",          `Quick, test_consent_basic
  ; "nested",         `Quick, test_consent_nested
  ; "multiple stmts", `Quick, test_consent_multiple_stmts
  ]

let gratitude_tests =
  [ "basic",         `Quick, test_gratitude_basic
  ; "unicode arrow", `Quick, test_gratitude_unicode_arrow
  ; "empty",         `Quick, test_gratitude_empty
  ; "single entry",  `Quick, test_gratitude_single
  ]

let when_tests =
  [ "basic",      `Quick, test_when_basic
  ; "otherwise",  `Quick, test_when_otherwise
  ; "comparison", `Quick, test_when_comparison
  ; "nested",     `Quick, test_when_nested
  ]

let repeat_tests =
  [ "literal",  `Quick, test_repeat_literal
  ; "variable", `Quick, test_repeat_variable
  ; "expr",     `Quick, test_repeat_expr
  ]

let attempt_tests =
  [ "basic",      `Quick, test_attempt_safely
  ; "multi stmt", `Quick, test_attempt_multi_stmt
  ]

let measured_tests =
  [ "in remember",    `Quick, test_measured_in_remember
  ; "float unit",     `Quick, test_measured_in_expr
  ; "expr context",   `Quick, test_measured_in_expression_context
  ]

let emote_tests =
  [ "function",      `Quick, test_emote_function
  ; "with params",   `Quick, test_emote_with_params
  ; "multi params",  `Quick, test_emote_multi_params
  ; "on statement",  `Quick, test_emote_on_statement
  ]

let worker_tests =
  [ "worker def",         `Quick, test_worker_def
  ; "worker empty",       `Quick, test_worker_empty
  ; "side quest def",     `Quick, test_side_quest_def
  ; "spawn worker stmt",  `Quick, test_spawn_worker_stmt
  ]

let const_tests =
  [ "typed const",   `Quick, test_const_typed
  ; "untyped const", `Quick, test_const_untyped
  ]

let type_tests =
  [ "String", `Quick, test_type_string
  ; "array",  `Quick, test_type_array
  ; "Maybe",  `Quick, test_type_maybe
  ; "custom", `Quick, test_type_custom
  ]

let expr_tests =
  [ "int",            `Quick, test_expr_int
  ; "float",          `Quick, test_expr_float
  ; "string",         `Quick, test_expr_string
  ; "bool true",      `Quick, test_expr_bool_true
  ; "bool false",     `Quick, test_expr_bool_false
  ; "ident",          `Quick, test_expr_ident
  ; "array",          `Quick, test_expr_array
  ; "empty array",    `Quick, test_expr_empty_array
  ; "call no args",   `Quick, test_expr_call_no_args
  ; "call with args", `Quick, test_expr_call_with_args
  ; "nested call",    `Quick, test_expr_nested_call
  ; "add",            `Quick, test_expr_add
  ; "sub",            `Quick, test_expr_sub
  ; "mul",            `Quick, test_expr_mul
  ; "div",            `Quick, test_expr_div
  ; "mod",            `Quick, test_expr_mod
  ; "precedence * over +", `Quick, test_expr_precedence_mul_over_add
  ; "parens override",     `Quick, test_expr_precedence_parens
  ; "==",  `Quick, test_expr_comparison_eq
  ; "!=",  `Quick, test_expr_comparison_ne
  ; "<",   `Quick, test_expr_comparison_lt
  ; ">",   `Quick, test_expr_comparison_gt
  ; "<=",  `Quick, test_expr_comparison_le
  ; ">=",  `Quick, test_expr_comparison_ge
  ; "and", `Quick, test_expr_logical_and
  ; "or",  `Quick, test_expr_logical_or
  ; "not", `Quick, test_expr_not
  ; "neg", `Quick, test_expr_negate
  ; "thanks()",    `Quick, test_expr_thanks
  ; "measured in", `Quick, test_expr_measured_in
  ]

let say_tests =
  [ "say stmt", `Quick, test_say ]

let complain_tests =
  [ "complain stmt", `Quick, test_complain ]

let toplevel_tests =
  [ "mixed top-level", `Quick, test_mixed_toplevel
  ; "empty program",   `Quick, test_empty_program
  ]

let error_tests =
  [ "missing paren",      `Quick, test_error_missing_paren
  ; "missing brace",      `Quick, test_error_missing_brace
  ; "missing semicolon",  `Quick, test_error_missing_semicolon
  ; "bare give",          `Quick, test_error_bare_give
  ; "consent no string",  `Quick, test_error_consent_no_string
  ]

let () =
  Alcotest.run "WokeLang Parser"
    [ "functions",          function_tests
    ; "remember",           remember_tests
    ; "assignment",         assign_tests
    ; "give back",          give_back_tests
    ; "consent gates",      consent_tests
    ; "gratitude blocks",   gratitude_tests
    ; "when/otherwise",     when_tests
    ; "repeat times",       repeat_tests
    ; "attempt safely",     attempt_tests
    ; "measured in units",  measured_tests
    ; "emote annotations",  emote_tests
    ; "workers/quests",     worker_tests
    ; "constants",          const_tests
    ; "type annotations",   type_tests
    ; "expressions",        expr_tests
    ; "say",                say_tests
    ; "complain",           complain_tests
    ; "top-level items",    toplevel_tests
    ; "parse errors",       error_tests
    ]
