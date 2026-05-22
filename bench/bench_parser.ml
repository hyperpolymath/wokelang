(* SPDX-License-Identifier: MPL-2.0 *)
(* bench_parser.ml — Parser benchmark harness for WokeLang
 *
 * Generates a large synthetic WokeLang program and measures
 * parse throughput: LOC/sec, total parse time.
 *
 * WokeLang syntax: "to" for functions, "remember" for variables,
 * "when/otherwise" for if/else, "give back" for return,
 * "say" for output, "repeat N times" for loops.
 *
 * Usage:  dune exec bench/bench_parser.ml
 *)

(** Generate a synthetic WokeLang program. *)
let generate_program num_fns =
  let buf = Buffer.create (num_fns * 350) in
  (* Const declarations *)
  for i = 0 to 4 do
    Buffer.add_string buf (Printf.sprintf "const LIMIT_%d: int = %d;\n" i ((i + 1) * 42))
  done;
  Buffer.add_string buf "\n";
  (* Function definitions *)
  for i = 0 to num_fns - 1 do
    Buffer.add_string buf (Printf.sprintf "to compute_%d(x: int, y: int) -> int {\n" i);
    Buffer.add_string buf (Printf.sprintf "  remember total = x + y * %d;\n" (i + 1));
    Buffer.add_string buf (Printf.sprintf "  remember delta = %d;\n" ((i mod 7) + 1));
    Buffer.add_string buf "  when total == delta {\n";
    Buffer.add_string buf "    say total;\n";
    Buffer.add_string buf "    give back total;\n";
    Buffer.add_string buf "  } otherwise {\n";
    Buffer.add_string buf "    remember result = total + delta;\n";
    Buffer.add_string buf "    give back result;\n";
    Buffer.add_string buf "  }\n";
    Buffer.add_string buf "}\n\n";
    (* Worker blocks every 10th function *)
    if i mod 10 = 0 then begin
      Buffer.add_string buf (Printf.sprintf "worker handler_%d {\n" i);
      Buffer.add_string buf (Printf.sprintf "  remember v = %d;\n" (i * 3));
      Buffer.add_string buf "  say v;\n";
      Buffer.add_string buf "}\n\n"
    end
  done;
  (* Gratitude block *)
  Buffer.add_string buf "thanks to {\n";
  Buffer.add_string buf "  \"contributor_a\" -> \"core design\";\n";
  Buffer.add_string buf "  \"contributor_b\" -> \"testing\";\n";
  Buffer.add_string buf "}\n";
  Buffer.contents buf

let count_lines s =
  let n = ref 1 in
  String.iter (fun c -> if c = '\n' then incr n) s;
  !n

let () =
  let num_fns = 50 in
  let iterations = 100 in
  let source = generate_program num_fns in
  let loc = count_lines source in

  Printf.printf "=== WokeLang Parser Benchmark ===\n";
  Printf.printf "Source: %d LOC, %d bytes\n" loc (String.length source);
  Printf.printf "Iterations: %d\n\n" iterations;

  (* Warm up — parse using Menhir via Lexing *)
  let parse src =
    let lexbuf = Lexing.from_string src in
    Parser.program Lexer.token lexbuf
  in
  let _ = parse source in

  let t_start = Unix.gettimeofday () in
  for _ = 1 to iterations do
    let result = parse source in
    ignore (Sys.opaque_identity result)
  done;
  let t_end = Unix.gettimeofday () in

  let total_sec = t_end -. t_start in
  let per_iter = total_sec /. Float.of_int iterations in
  let loc_per_sec = Float.of_int (loc * iterations) /. total_sec in

  Printf.printf "Total parse time : %.4f s\n" total_sec;
  Printf.printf "Time per parse   : %.6f s\n" per_iter;
  Printf.printf "LOC/sec          : %.0f\n" loc_per_sec;
  Printf.printf "Bytes/sec        : %.0f\n"
    (Float.of_int (String.length source * iterations) /. total_sec)
