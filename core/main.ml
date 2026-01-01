(* SPDX-License-Identifier: AGPL-3.0-or-later *)
(* SPDX-FileCopyrightText: 2026 Hyperpolymath *)

(** WokeLang CLI

    Command-line interface for the WokeLang interpreter.
    Supports running .wl files and provides deterministic
    error diagnostics.
*)

(** Read entire file contents *)
let read_file filename =
  let ic = open_in filename in
  let n = in_channel_length ic in
  let s = really_input_string ic n in
  close_in ic;
  s

(** Parse source code into AST *)
let parse_source source =
  let lexbuf = Lexing.from_string source in
  try
    Parser.program Lexer.token lexbuf
  with
  | Lexer.LexError msg ->
    let pos = lexbuf.Lexing.lex_curr_p in
    Printf.eprintf "Lexical error at line %d, column %d: %s\n"
      pos.Lexing.pos_lnum
      (pos.Lexing.pos_cnum - pos.Lexing.pos_bol)
      msg;
    exit 1
  | Parser.Error ->
    let pos = lexbuf.Lexing.lex_curr_p in
    Printf.eprintf "Parse error at line %d, column %d: unexpected token\n"
      pos.Lexing.pos_lnum
      (pos.Lexing.pos_cnum - pos.Lexing.pos_bol);
    exit 1

(** Run a WokeLang program from source *)
let run_source source =
  let program = parse_source source in
  try
    Eval.eval_program program
  with
  | Eval.RuntimeError msg ->
    Printf.eprintf "Runtime error: %s\n" msg;
    exit 1
  | Eval.ConsentDenied perm ->
    Printf.eprintf "Consent denied for: %s\n" perm;
    exit 1

(** Run a WokeLang file *)
let run_file filename =
  if not (Sys.file_exists filename) then begin
    Printf.eprintf "Error: File not found: %s\n" filename;
    exit 1
  end;
  let source = read_file filename in
  run_source source

(** Print usage information *)
let usage () =
  print_endline "WokeLang - A Human-Centered Programming Language";
  print_endline "";
  print_endline "Usage: wokelang <file.wl>";
  print_endline "       wokelang --help";
  print_endline "       wokelang --version";
  print_endline "";
  print_endline "Options:";
  print_endline "  --help       Show this help message";
  print_endline "  --version    Show version information";
  print_endline "";
  print_endline "Examples:";
  print_endline "  wokelang examples/hello_world.wl";
  print_endline "  wokelang my_program.wl"

(** Print version information *)
let version () =
  print_endline "WokeLang 0.1.0";
  print_endline "OCaml Core Implementation";
  print_endline "Copyright (c) 2026 Hyperpolymath";
  print_endline "Licensed under AGPL-3.0-or-later"

(** Main entry point *)
let () =
  let args = Array.to_list Sys.argv |> List.tl in
  match args with
  | [] ->
    usage ();
    exit 0
  | ["--help"] | ["-h"] ->
    usage ();
    exit 0
  | ["--version"] | ["-v"] ->
    version ();
    exit 0
  | [filename] ->
    run_file filename
  | _ ->
    Printf.eprintf "Error: Too many arguments\n";
    usage ();
    exit 1
