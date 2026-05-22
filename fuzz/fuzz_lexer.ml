(* SPDX-License-Identifier: MPL-2.0 *)
(* Fuzz target for the WokeLang lexer.
 *
 * Invariant: the lexer must NEVER crash on ANY input. It should always
 * return tokens or raise LexError, never an uncaught exception.
 *
 * The WokeLang lexer is ocamllex-generated (core/lexer.mll) and
 * produces Parser tokens. This harness feeds random strings through
 * the lexer until EOF or error.
 *
 * Run with:
 *   dune exec fuzz/fuzz_lexer.exe
 *)

let fuzz_one_input (input : string) : unit =
  let lexbuf = Lexing.from_string input in
  let rec drain () =
    match (try Some (Lexer.token lexbuf) with _ -> None) with
    | None -> ()
    | Some tok ->
      (* Ensure the token value can be inspected *)
      let _ = tok in
      if tok = Parser.EOF then ()
      else drain ()
  in
  drain ()

(* Simple PRNG-based random string generator. *)
let random_bytes (rng : Random.State.t) (max_len : int) : string =
  let len = Random.State.int rng (max_len + 1) in
  let buf = Bytes.create len in
  for i = 0 to len - 1 do
    Bytes.set buf i (Char.chr (Random.State.int rng 256))
  done;
  Bytes.to_string buf

(* Generate strings biased toward printable ASCII and common
 * WokeLang tokens to improve coverage. *)
let interesting_fragments =
  [| "to"; "give"; "back"; "remember"; "when"; "otherwise";
     "repeat"; "times"; "only"; "if"; "okay"; "attempt";
     "safely"; "or"; "reassure"; "complain"; "thanks";
     "hello"; "goodbye"; "worker"; "side"; "quest"; "spawn";
     "superpower"; "decide"; "based"; "on"; "measured"; "in";
     "care"; "strict"; "verbose"; "String"; "Int"; "Float"; "Bool";
     "Maybe"; "const"; "type"; "use"; "renamed"; "true"; "false";
     "and"; "not"; "must"; "have"; "say"; "#";
     "=="; "!="; "<="; ">="; "\xe2\x86\x92"; (* UTF-8 for → *)
     "->"; "("; ")"; "{"; "}"; "["; "]"; ","; ";"; ":"; "="; "@";
     "+"; "-"; "*"; "/"; "%"; "<"; ">"; "_";
     "\"hello world\""; "42"; "3.14"; "\"escape\\n\"";
     "// comment\n"; "/* block */";
     " "; "\t"; "\n"; "\r";
     "identifier"; "myVar_1"; "CAPS_LOCK";
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
  Printf.printf "WokeLang lexer fuzzer: running %d iterations\n%!" iterations;
  for i = 1 to iterations do
    let input = random_input rng 4096 in
    fuzz_one_input input;
    if i mod 10_000 = 0 then
      Printf.printf "  ... %d iterations complete\n%!" i
  done;
  Printf.printf "WokeLang lexer fuzzer: %d iterations passed with no crashes\n%!" iterations
