(* SPDX-License-Identifier: AGPL-3.0-or-later *)
(* SPDX-FileCopyrightText: 2026 Hyperpolymath *)

(** WokeLang Abstract Syntax Tree

    This module defines the core AST for the WokeLang language,
    supporting consent gates, gratitude blocks, units of measure,
    and emotionally-aware programming constructs.
*)

(** Location information for error reporting *)
type location = {
  line: int;
  column: int;
  filename: string option;
}

(** Type annotations *)
type typ =
  | TString
  | TInt
  | TFloat
  | TBool
  | TArray of typ
  | TMaybe of typ
  | TUnit
  | TCustom of string

(** Unit of measure (e.g., meters, seconds, kg) *)
type unit_of_measure = string

(** Emote tag for emotional annotations *)
type emote_tag = {
  name: string;
  params: (string * expr) list;
}

(** Expressions *)
and expr =
  | EInt of int
  | EFloat of float
  | EString of string
  | EBool of bool
  | EIdent of string
  | EArray of expr list
  | ECall of string * expr list
  | EBinOp of binop * expr * expr
  | EUnaryOp of unaryop * expr
  | EMeasured of expr * unit_of_measure
  | EThanks of string  (** thanks("contributor") literal *)

(** Binary operators *)
and binop =
  | OpAdd | OpSub | OpMul | OpDiv | OpMod
  | OpEq | OpNe | OpLt | OpGt | OpLe | OpGe
  | OpAnd | OpOr
  | OpConcat  (** String concatenation with + *)

(** Unary operators *)
and unaryop =
  | OpNot
  | OpNeg

(** Statements *)
type stmt =
  | SRemember of string * expr * unit_of_measure option  (** remember x = expr [measured in unit] *)
  | SAssign of string * expr                              (** x = expr *)
  | SGiveBack of expr                                     (** give back expr *)
  | SWhen of expr * stmt list * stmt list option          (** when expr { ... } [otherwise { ... }] *)
  | SRepeat of expr * stmt list                           (** repeat n times { ... } *)
  | SAttempt of stmt list * string                        (** attempt safely { ... } or reassure "msg" *)
  | SConsent of string * stmt list                        (** only if okay "permission" { ... } *)
  | SExpr of expr                                         (** expression statement *)
  | SComplain of string                                   (** complain "error message" *)
  | SEmoteAnnotated of emote_tag * stmt                   (** @emote stmt *)
  | SSpawnWorker of string                                (** spawn worker name *)

(** Gratitude entry: contributor -> contribution *)
type gratitude_entry = {
  contributor: string;
  contribution: string;
}

(** Pattern for pattern matching *)
type pattern =
  | PInt of int
  | PString of string
  | PBool of bool
  | PIdent of string
  | PWildcard

(** Match arm for decide blocks *)
type match_arm = pattern * stmt list

(** Function parameter *)
type param = {
  name: string;
  typ: typ option;
}

(** Function definition *)
type func_def = {
  name: string;
  params: param list;
  return_type: typ option;
  hello_msg: string option;    (** Optional hello message *)
  body: stmt list;
  goodbye_msg: string option;  (** Optional goodbye message *)
  emote: emote_tag option;     (** Optional emote annotation *)
}

(** Worker definition *)
type worker_def = {
  worker_name: string;
  worker_body: stmt list;
}

(** Side quest definition *)
type side_quest_def = {
  quest_name: string;
  quest_body: stmt list;
}

(** Top-level program items *)
type top_level =
  | TLFunction of func_def
  | TLGratitude of gratitude_entry list  (** thanks to { ... } *)
  | TLWorker of worker_def
  | TLSideQuest of side_quest_def
  | TLConst of string * typ option * expr  (** const name : type = expr *)

(** Complete program *)
type program = top_level list

(** Pretty printing helpers *)
let rec string_of_typ = function
  | TString -> "String"
  | TInt -> "Int"
  | TFloat -> "Float"
  | TBool -> "Bool"
  | TArray t -> "[" ^ string_of_typ t ^ "]"
  | TMaybe t -> "Maybe " ^ string_of_typ t
  | TUnit -> "()"
  | TCustom s -> s

let string_of_binop = function
  | OpAdd -> "+"
  | OpSub -> "-"
  | OpMul -> "*"
  | OpDiv -> "/"
  | OpMod -> "%"
  | OpEq -> "=="
  | OpNe -> "!="
  | OpLt -> "<"
  | OpGt -> ">"
  | OpLe -> "<="
  | OpGe -> ">="
  | OpAnd -> "and"
  | OpOr -> "or"
  | OpConcat -> "+"

let string_of_unaryop = function
  | OpNot -> "not"
  | OpNeg -> "-"
