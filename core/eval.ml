(* SPDX-License-Identifier: AGPL-3.0-or-later *)
(* SPDX-FileCopyrightText: 2026 Hyperpolymath *)

(** WokeLang Evaluator

    Tree-walking interpreter for the WokeLang language,
    implementing consent-aware control flow, gratitude tracking,
    and units of measure semantics.
*)

open Ast

(** Runtime values *)
type value =
  | VInt of int
  | VFloat of float
  | VString of string
  | VBool of bool
  | VArray of value list
  | VMeasured of value * unit_of_measure
  | VUnit
  | VFunction of func_def
  | VThanks of string

(** Runtime errors *)
exception RuntimeError of string
exception Return of value
exception ConsentDenied of string

(** Environment for variable bindings *)
type env = {
  vars: (string, value) Hashtbl.t;
  parent: env option;
  consent_grants: (string, bool) Hashtbl.t;  (** Tracks granted consents *)
  gratitude: (string * string) list ref;      (** Contributor -> contribution *)
}

(** Create a new environment *)
let make_env ?parent () = {
  vars = Hashtbl.create 16;
  parent;
  consent_grants = Hashtbl.create 8;
  gratitude = ref [];
}

(** Look up a variable in the environment chain *)
let rec lookup env name =
  match Hashtbl.find_opt env.vars name with
  | Some v -> Some v
  | None ->
    match env.parent with
    | Some p -> lookup p name
    | None -> None

(** Bind a variable in the current environment *)
let bind env name value =
  Hashtbl.replace env.vars name value

(** Pretty print a value *)
let rec string_of_value = function
  | VInt n -> string_of_int n
  | VFloat f -> string_of_float f
  | VString s -> s
  | VBool b -> if b then "true" else "false"
  | VArray vs ->
    "[" ^ String.concat ", " (List.map string_of_value vs) ^ "]"
  | VMeasured (v, unit) ->
    string_of_value v ^ " measured in " ^ unit
  | VUnit -> "()"
  | VFunction f -> "<function " ^ f.name ^ ">"
  | VThanks s -> "thanks(\"" ^ s ^ "\")"

(** Convert value to boolean *)
let to_bool = function
  | VBool b -> b
  | VInt 0 -> false
  | VInt _ -> true
  | VString "" -> false
  | VString _ -> true
  | VArray [] -> false
  | VArray _ -> true
  | VUnit -> false
  | _ -> true

(** Convert value to integer *)
let to_int = function
  | VInt n -> n
  | VFloat f -> int_of_float f
  | VBool true -> 1
  | VBool false -> 0
  | v -> raise (RuntimeError ("Cannot convert to int: " ^ string_of_value v))

(** Check consent - in this implementation, always grants for testing
    In production, this would prompt the user *)
let check_consent env permission =
  match Hashtbl.find_opt env.consent_grants permission with
  | Some granted -> granted
  | None ->
    (* For testing/demo: auto-grant consents *)
    Printf.printf "[Consent] Granting permission: %s\n" permission;
    Hashtbl.replace env.consent_grants permission true;
    true

(** Evaluate a binary operation *)
let eval_binop op v1 v2 =
  match op, v1, v2 with
  (* Arithmetic on integers *)
  | OpAdd, VInt a, VInt b -> VInt (a + b)
  | OpSub, VInt a, VInt b -> VInt (a - b)
  | OpMul, VInt a, VInt b -> VInt (a * b)
  | OpDiv, VInt a, VInt b ->
    if b = 0 then raise (RuntimeError "Division by zero")
    else VInt (a / b)
  | OpMod, VInt a, VInt b ->
    if b = 0 then raise (RuntimeError "Modulo by zero")
    else VInt (a mod b)

  (* Arithmetic on floats *)
  | OpAdd, VFloat a, VFloat b -> VFloat (a +. b)
  | OpSub, VFloat a, VFloat b -> VFloat (a -. b)
  | OpMul, VFloat a, VFloat b -> VFloat (a *. b)
  | OpDiv, VFloat a, VFloat b ->
    if b = 0.0 then raise (RuntimeError "Division by zero")
    else VFloat (a /. b)

  (* Mixed int/float arithmetic *)
  | OpAdd, VInt a, VFloat b -> VFloat (float_of_int a +. b)
  | OpAdd, VFloat a, VInt b -> VFloat (a +. float_of_int b)
  | OpSub, VInt a, VFloat b -> VFloat (float_of_int a -. b)
  | OpSub, VFloat a, VInt b -> VFloat (a -. float_of_int b)
  | OpMul, VInt a, VFloat b -> VFloat (float_of_int a *. b)
  | OpMul, VFloat a, VInt b -> VFloat (a *. float_of_int b)
  | OpDiv, VInt a, VFloat b -> VFloat (float_of_int a /. b)
  | OpDiv, VFloat a, VInt b -> VFloat (a /. float_of_int b)

  (* String concatenation with + *)
  | OpAdd, VString a, VString b -> VString (a ^ b)
  | OpAdd, VString a, v -> VString (a ^ string_of_value v)
  | OpAdd, v, VString b -> VString (string_of_value v ^ b)

  (* Comparison operators *)
  | OpEq, a, b -> VBool (a = b)
  | OpNe, a, b -> VBool (a <> b)
  | OpLt, VInt a, VInt b -> VBool (a < b)
  | OpGt, VInt a, VInt b -> VBool (a > b)
  | OpLe, VInt a, VInt b -> VBool (a <= b)
  | OpGe, VInt a, VInt b -> VBool (a >= b)
  | OpLt, VFloat a, VFloat b -> VBool (a < b)
  | OpGt, VFloat a, VFloat b -> VBool (a > b)
  | OpLe, VFloat a, VFloat b -> VBool (a <= b)
  | OpGe, VFloat a, VFloat b -> VBool (a >= b)

  (* Logical operators *)
  | OpAnd, a, b -> VBool (to_bool a && to_bool b)
  | OpOr, a, b -> VBool (to_bool a || to_bool b)

  (* Measured values - propagate units *)
  | op, VMeasured (v1, u1), VMeasured (v2, u2) when u1 = u2 ->
    VMeasured (eval_binop op v1 v2, u1)
  | _, VMeasured (_, u1), VMeasured (_, u2) ->
    raise (RuntimeError (Printf.sprintf "Unit mismatch: %s vs %s" u1 u2))

  | _ ->
    raise (RuntimeError (Printf.sprintf "Invalid operation: %s %s %s"
      (string_of_value v1) (string_of_binop op) (string_of_value v2)))

(** Evaluate a unary operation *)
let eval_unaryop op v =
  match op, v with
  | OpNot, v -> VBool (not (to_bool v))
  | OpNeg, VInt n -> VInt (-n)
  | OpNeg, VFloat f -> VFloat (-.f)
  | OpNeg, VMeasured (v, u) -> VMeasured (eval_unaryop OpNeg v, u)
  | _ -> raise (RuntimeError ("Invalid unary operation on: " ^ string_of_value v))

(** Evaluate an expression *)
let rec eval_expr env = function
  | EInt n -> VInt n
  | EFloat f -> VFloat f
  | EString s -> VString s
  | EBool b -> VBool b
  | EIdent name ->
    (match lookup env name with
     | Some v -> v
     | None -> raise (RuntimeError ("Undefined variable: " ^ name)))
  | EArray exprs ->
    VArray (List.map (eval_expr env) exprs)
  | ECall (name, args) ->
    eval_call env name args
  | EBinOp (op, e1, e2) ->
    let v1 = eval_expr env e1 in
    let v2 = eval_expr env e2 in
    eval_binop op v1 v2
  | EUnaryOp (op, e) ->
    eval_unaryop op (eval_expr env e)
  | EMeasured (e, unit) ->
    VMeasured (eval_expr env e, unit)
  | EThanks s ->
    VThanks s

(** Evaluate a function call *)
and eval_call env name args =
  let arg_values = List.map (eval_expr env) args in
  match name with
  (* Built-in functions *)
  | "say" ->
    (match arg_values with
     | [v] ->
       print_endline (string_of_value v);
       VUnit
     | _ -> raise (RuntimeError "say expects exactly one argument"))
  | "print" ->
    List.iter (fun v -> print_string (string_of_value v)) arg_values;
    VUnit
  | "println" ->
    List.iter (fun v -> print_string (string_of_value v)) arg_values;
    print_newline ();
    VUnit
  | "len" ->
    (match arg_values with
     | [VString s] -> VInt (String.length s)
     | [VArray arr] -> VInt (List.length arr)
     | _ -> raise (RuntimeError "len expects a string or array"))
  | "int" ->
    (match arg_values with
     | [v] -> VInt (to_int v)
     | _ -> raise (RuntimeError "int expects exactly one argument"))
  | "float" ->
    (match arg_values with
     | [VInt n] -> VFloat (float_of_int n)
     | [VFloat f] -> VFloat f
     | _ -> raise (RuntimeError "float expects a numeric argument"))
  | "string" ->
    (match arg_values with
     | [v] -> VString (string_of_value v)
     | _ -> raise (RuntimeError "string expects exactly one argument"))
  (* User-defined functions *)
  | _ ->
    (match lookup env name with
     | Some (VFunction f) ->
       eval_function env f arg_values
     | Some _ -> raise (RuntimeError (name ^ " is not a function"))
     | None -> raise (RuntimeError ("Undefined function: " ^ name)))

(** Evaluate a user-defined function *)
and eval_function env func args =
  (* Create new environment for function scope *)
  let func_env = make_env ~parent:env () in

  (* Bind parameters to arguments *)
  if List.length func.params <> List.length args then
    raise (RuntimeError (Printf.sprintf
      "Function %s expects %d arguments, got %d"
      func.name (List.length func.params) (List.length args)));

  List.iter2 (fun param arg ->
    bind func_env param.name arg
  ) func.params args;

  (* Print hello message if present *)
  Option.iter (fun msg -> print_endline ("[hello] " ^ msg)) func.hello_msg;

  (* Execute function body *)
  let result =
    try
      List.iter (eval_stmt func_env) func.body;
      VUnit  (* Default return value *)
    with
    | Return v -> v
  in

  (* Print goodbye message if present *)
  Option.iter (fun msg -> print_endline ("[goodbye] " ^ msg)) func.goodbye_msg;

  result

(** Evaluate a statement *)
and eval_stmt env = function
  | SRemember (name, expr, unit_opt) ->
    let value = eval_expr env expr in
    let final_value = match unit_opt with
      | Some unit -> VMeasured (value, unit)
      | None -> value
    in
    bind env name final_value

  | SAssign (name, expr) ->
    if lookup env name = None then
      raise (RuntimeError ("Cannot assign to undefined variable: " ^ name));
    bind env name (eval_expr env expr)

  | SGiveBack expr ->
    raise (Return (eval_expr env expr))

  | SWhen (cond, then_body, else_body) ->
    if to_bool (eval_expr env cond) then
      List.iter (eval_stmt env) then_body
    else
      Option.iter (List.iter (eval_stmt env)) else_body

  | SRepeat (n_expr, body) ->
    let n = to_int (eval_expr env n_expr) in
    for _ = 1 to n do
      List.iter (eval_stmt env) body
    done

  | SAttempt (body, reassure_msg) ->
    (try
       List.iter (eval_stmt env) body
     with
     | RuntimeError _ ->
       print_endline ("[reassure] " ^ reassure_msg))

  | SConsent (permission, body) ->
    if check_consent env permission then
      List.iter (eval_stmt env) body
    else
      raise (ConsentDenied permission)

  | SExpr expr ->
    ignore (eval_expr env expr)

  | SComplain msg ->
    raise (RuntimeError ("Complaint: " ^ msg))

  | SEmoteAnnotated (emote, stmt) ->
    (* Log the emote, then execute the statement *)
    Printf.printf "[emote @%s] " emote.name;
    if emote.params <> [] then begin
      let param_strs = List.map (fun (k, v) ->
        k ^ "=" ^ string_of_value (eval_expr env v)
      ) emote.params in
      print_endline (String.concat ", " param_strs)
    end else
      print_newline ();
    eval_stmt env stmt

  | SSpawnWorker name ->
    Printf.printf "[spawn] Starting worker: %s\n" name

(** Evaluate a top-level item *)
let eval_top_level env = function
  | TLFunction f ->
    bind env f.name (VFunction f)
  | TLGratitude entries ->
    List.iter (fun entry ->
      env.gratitude := (entry.contributor, entry.contribution) :: !(env.gratitude);
      Printf.printf "[thanks] %s → %s\n" entry.contributor entry.contribution
    ) entries
  | TLWorker w ->
    Printf.printf "[worker] Registered worker: %s\n" w.worker_name
  | TLSideQuest q ->
    Printf.printf "[side quest] Registered: %s\n" q.quest_name
  | TLConst (name, _, expr) ->
    bind env name (eval_expr env expr)

(** Evaluate a complete program *)
let eval_program program =
  let env = make_env () in

  (* First pass: register all top-level definitions *)
  List.iter (eval_top_level env) program;

  (* Second pass: look for and execute main function *)
  match lookup env "main" with
  | Some (VFunction main_func) ->
    ignore (eval_function env main_func [])
  | Some _ ->
    raise (RuntimeError "main is not a function")
  | None ->
    (* No main function - just evaluate top-level items *)
    ()
