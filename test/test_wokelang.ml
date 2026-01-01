(* SPDX-License-Identifier: AGPL-3.0-or-later *)
(* SPDX-FileCopyrightText: 2026 Hyperpolymath *)

(** WokeLang Core Test Suite

    Tests for the OCaml core implementation focusing on:
    - Consent gate semantics
    - Units of measure
    - Gratitude tracking
    - Deterministic error diagnostics
*)

open Wokelang_core

(** Parse source code and return AST *)
let parse source =
  let lexbuf = Lexing.from_string source in
  Parser.program Lexer.token lexbuf

(** Run source code and return success/failure *)
let run source =
  try
    let program = parse source in
    Eval.eval_program program;
    true
  with _ -> false

(** Run source and capture output *)
let run_capturing source =
  let buffer = Buffer.create 256 in
  let old_stdout = Unix.dup Unix.stdout in
  let (read_fd, write_fd) = Unix.pipe () in
  Unix.dup2 write_fd Unix.stdout;
  Unix.close write_fd;

  (try
     let program = parse source in
     Eval.eval_program program
   with e ->
     Unix.dup2 old_stdout Unix.stdout;
     Unix.close read_fd;
     Unix.close old_stdout;
     raise e);

  Unix.dup2 old_stdout Unix.stdout;
  flush stdout;

  let bytes_read = ref 1 in
  let temp = Bytes.create 1024 in
  while !bytes_read > 0 do
    bytes_read := Unix.read read_fd temp 0 1024;
    Buffer.add_subbytes buffer temp 0 !bytes_read
  done;
  Unix.close read_fd;
  Unix.close old_stdout;
  Buffer.contents buffer

(** Test counter *)
let tests_run = ref 0
let tests_passed = ref 0

(** Run a test *)
let test name f =
  incr tests_run;
  print_string ("Testing: " ^ name ^ "... ");
  try
    f ();
    incr tests_passed;
    print_endline "PASS"
  with
  | Assert_failure (file, line, _) ->
    Printf.printf "FAIL (assertion at %s:%d)\n" file line
  | e ->
    Printf.printf "FAIL (exception: %s)\n" (Printexc.to_string e)

(** Assert equality *)
let assert_eq expected actual =
  if expected <> actual then
    failwith (Printf.sprintf "Expected %s but got %s"
      (Obj.magic expected |> string_of_int)
      (Obj.magic actual |> string_of_int))

(** Assert that parsing succeeds *)
let assert_parses source =
  try
    ignore (parse source);
    ()
  with e ->
    failwith ("Parse failed: " ^ Printexc.to_string e)

(** Assert that parsing fails *)
let assert_parse_fails source =
  try
    ignore (parse source);
    failwith "Expected parse to fail but it succeeded"
  with
  | Parser.Error -> ()
  | Lexer.LexError _ -> ()
  | _ -> failwith "Parse failed with unexpected error"

(** Assert that evaluation succeeds *)
let assert_runs source =
  if not (run source) then
    failwith "Expected program to run successfully"

(** Assert that evaluation fails *)
let assert_run_fails source =
  if run source then
    failwith "Expected program to fail but it succeeded"

(* ============ Lexer Tests ============ *)

let test_lexer_basic () =
  test "lexer: keywords" (fun () ->
    assert_parses "to main() { }";
    assert_parses "remember x = 5;";
    assert_parses "give back 42;";
    assert_parses "when true { }";
    assert_parses "repeat 3 times { }"
  );

  test "lexer: operators" (fun () ->
    assert_parses "to f() { remember x = 1 + 2; }";
    assert_parses "to f() { remember x = 1 - 2; }";
    assert_parses "to f() { remember x = 1 * 2; }";
    assert_parses "to f() { remember x = 1 / 2; }";
    assert_parses "to f() { remember x = 1 == 2; }";
    assert_parses "to f() { remember x = 1 != 2; }"
  );

  test "lexer: comments" (fun () ->
    assert_parses "// comment\nto main() { }";
    assert_parses "/* block */to main() { }";
    assert_parses "to main() { /* inline */ }"
  );

  test "lexer: strings" (fun () ->
    assert_parses {|to f() { remember s = "hello"; }|};
    assert_parses {|to f() { remember s = "hello world"; }|}
  )

(* ============ Parser Tests ============ *)

let test_parser_functions () =
  test "parser: simple function" (fun () ->
    assert_parses "to greet() { say \"hello\"; }"
  );

  test "parser: function with params" (fun () ->
    assert_parses "to add(a: Int, b: Int) → Int { give back a + b; }"
  );

  test "parser: function with hello/goodbye" (fun () ->
    assert_parses {|
      to demo() {
        hello "Starting";
        say "Working";
        goodbye "Done";
      }
    |}
  );

  test "parser: emote annotations" (fun () ->
    assert_parses "@enthusiastic to greet() { }"
  )

let test_parser_consent () =
  test "parser: consent block" (fun () ->
    assert_parses {|
      to main() {
        only if okay "camera" {
          say "accessing camera";
        }
      }
    |}
  )

let test_parser_gratitude () =
  test "parser: gratitude block" (fun () ->
    assert_parses {|
      thanks to {
        "Alice" → "Bug fix";
        "Bob" → "Feature";
      }
    |}
  )

let test_parser_units () =
  test "parser: units of measure" (fun () ->
    assert_parses "to f() { remember d = 5 measured in km; }"
  )

let test_parser_control_flow () =
  test "parser: when/otherwise" (fun () ->
    assert_parses {|
      to f() {
        when x > 0 {
          say "positive";
        } otherwise {
          say "non-positive";
        }
      }
    |}
  );

  test "parser: repeat times" (fun () ->
    assert_parses {|
      to f() {
        repeat 5 times {
          say "loop";
        }
      }
    |}
  );

  test "parser: attempt safely" (fun () ->
    assert_parses {|
      to f() {
        attempt safely {
          say "trying";
        } or reassure "all good";
      }
    |}
  )

(* ============ Evaluator Tests ============ *)

let test_eval_basic () =
  test "eval: arithmetic" (fun () ->
    assert_runs "to main() { remember x = 2 + 3; }"
  );

  test "eval: string concat" (fun () ->
    assert_runs {|to main() { remember s = "hello" + " " + "world"; }|}
  );

  test "eval: boolean ops" (fun () ->
    assert_runs "to main() { remember b = true and false; }";
    assert_runs "to main() { remember b = true or false; }";
    assert_runs "to main() { remember b = not true; }"
  )

let test_eval_functions () =
  test "eval: function call" (fun () ->
    assert_runs {|
      to add(a, b) {
        give back a + b;
      }
      to main() {
        remember result = add(2, 3);
      }
    |}
  );

  test "eval: nested calls" (fun () ->
    assert_runs {|
      to double(x) { give back x * 2; }
      to quadruple(x) { give back double(double(x)); }
      to main() { remember r = quadruple(5); }
    |}
  )

let test_eval_control_flow () =
  test "eval: when true" (fun () ->
    assert_runs {|
      to main() {
        when 1 == 1 {
          say "equal";
        }
      }
    |}
  );

  test "eval: when false with otherwise" (fun () ->
    assert_runs {|
      to main() {
        when 1 == 2 {
          say "equal";
        } otherwise {
          say "not equal";
        }
      }
    |}
  );

  test "eval: repeat" (fun () ->
    assert_runs {|
      to main() {
        remember count = 0;
        repeat 5 times {
          count = count + 1;
        }
      }
    |}
  )

let test_eval_consent () =
  test "eval: consent granted" (fun () ->
    assert_runs {|
      to main() {
        only if okay "test_permission" {
          say "granted";
        }
      }
    |}
  )

let test_eval_safety () =
  test "eval: attempt safely success" (fun () ->
    assert_runs {|
      to main() {
        attempt safely {
          say "working";
        } or reassure "handled";
      }
    |}
  )

(* ============ Diagnostics Tests ============ *)

let test_diagnostics () =
  test "diagnostics: undefined variable" (fun () ->
    assert_run_fails "to main() { say undefined_var; }"
  );

  test "diagnostics: undefined function" (fun () ->
    assert_run_fails "to main() { undefined_func(); }"
  );

  test "diagnostics: parse error" (fun () ->
    assert_parse_fails "to main( { }"  (* missing ) *)
  );

  test "diagnostics: lexer error" (fun () ->
    assert_parse_fails "to main() { remember x = @#$; }"
  )

(* ============ Main ============ *)

let () =
  print_endline "=== WokeLang Core Test Suite ===\n";

  print_endline "--- Lexer Tests ---";
  test_lexer_basic ();

  print_endline "\n--- Parser Tests ---";
  test_parser_functions ();
  test_parser_consent ();
  test_parser_gratitude ();
  test_parser_units ();
  test_parser_control_flow ();

  print_endline "\n--- Evaluator Tests ---";
  test_eval_basic ();
  test_eval_functions ();
  test_eval_control_flow ();
  test_eval_consent ();
  test_eval_safety ();

  print_endline "\n--- Diagnostics Tests ---";
  test_diagnostics ();

  print_endline "\n=== Results ===";
  Printf.printf "Tests: %d passed / %d total\n" !tests_passed !tests_run;

  if !tests_passed = !tests_run then begin
    print_endline "All tests passed!";
    exit 0
  end else begin
    print_endline "Some tests failed.";
    exit 1
  end
