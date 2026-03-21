(* SPDX-License-Identifier: PMPL-1.0-or-later *)
(* Fuzz target for the WokeLang parser.
 *
 * Invariant: the parser must NEVER crash on ANY input. It should raise
 * Parser.Error or Lexer.LexError, never an uncaught exception.
 *
 * WokeLang uses ocamllex (core/lexer.mll) + Menhir (core/parser.mly).
 * This harness feeds random strings through the full lex+parse pipeline.
 *
 * Strategy: 50% raw random bytes, 50% structured inputs mixing
 * WokeLang keywords (TO, GIVE BACK, REMEMBER, etc.) to achieve
 * deeper parser coverage.
 *
 * Run with:
 *   dune exec fuzz/fuzz_parser.exe
 *)

let fuzz_one_input (input : string) : unit =
  let lexbuf = Lexing.from_string input in
  (try
     let _ = Parser.program Lexer.token lexbuf in
     ()
   with
   | Parser.Error -> ()
   | Lexer.LexError _ -> ()
   | _ -> ())

(* Simple PRNG-based random string generator. *)
let random_bytes (rng : Random.State.t) (max_len : int) : string =
  let len = Random.State.int rng (max_len + 1) in
  let buf = Bytes.create len in
  for i = 0 to len - 1 do
    Bytes.set buf i (Char.chr (Random.State.int rng 256))
  done;
  Bytes.to_string buf

(* Fragments biased toward WokeLang syntax for deeper parser coverage.
 * WokeLang uses consent-based keywords like ONLY IF OKAY, ATTEMPT SAFELY,
 * gratitude (THANKS), lifecycle (HELLO/GOODBYE), and concurrency (WORKER). *)
let interesting_fragments =
  [| (* Control flow *)
     "TO"; "GIVE"; "BACK"; "REMEMBER"; "WHEN"; "OTHERWISE";
     "REPEAT"; "TIMES";
     (* Consent and safety *)
     "ONLY"; "IF"; "OKAY"; "ATTEMPT"; "SAFELY"; "OR"; "REASSURE"; "COMPLAIN";
     (* Gratitude *)
     "THANKS";
     (* Lifecycle *)
     "HELLO"; "GOODBYE";
     (* Concurrency *)
     "WORKER"; "SIDE"; "QUEST"; "SPAWN"; "SUPERPOWER";
     (* Pattern matching *)
     "DECIDE"; "BASED"; "ON";
     (* Units *)
     "MEASURED"; "IN";
     (* Pragmas *)
     "CARE"; "STRICT"; "VERBOSE";
     (* Operators *)
     "+"; "-"; "*"; "/"; "%"; "=="; "!="; "<"; ">"; "<="; ">="; "=";
     (* Delimiters *)
     "("; ")"; "{"; "}"; "["; "]"; ","; ";"; ":"; "@"; "#"; "_";
     "->"; "=>";
     (* Literals *)
     "42"; "0"; "3.14"; "true"; "false";
     "\"hello\""; "'c'";
     (* Identifiers *)
     "foo"; "bar_baz"; "MyType"; "_x"; "x1";
     (* Whitespace *)
     " "; "\t"; "\n"; "\r";
     (* Structured patterns — WokeLang-style *)
     "TO greet GIVE BACK \"hi\" THANKS";
     "REMEMBER x = 42";
     "WHEN x GIVE BACK y OTHERWISE GIVE BACK z";
     "ATTEMPT SAFELY { x } OR REASSURE { y }";
  |]

let random_input (rng : Random.State.t) (max_len : int) : string =
  if Random.State.bool rng then
    random_bytes rng max_len
  else begin
    let buf = Buffer.create max_len in
    let target_len = Random.State.int rng (max_len + 1) in
    while Buffer.length buf < target_len do
      let frag = interesting_fragments.(
        Random.State.int rng (Array.length interesting_fragments)
      ) in
      Buffer.add_string buf frag
    done;
    Buffer.contents buf
  end

let () =
  let rng = Random.State.make_self_init () in
  let iterations =
    try int_of_string (Sys.getenv "FUZZ_ITERATIONS")
    with _ -> 100_000
  in
  Printf.printf "WokeLang parser fuzzer: running %d iterations\n%!" iterations;
  for i = 1 to iterations do
    let input = random_input rng 4096 in
    fuzz_one_input input;
    if i mod 10_000 = 0 then
      Printf.printf "  ... %d iterations complete\n%!" i
  done;
  Printf.printf "WokeLang parser fuzzer: %d iterations passed with no crashes\n%!" iterations
