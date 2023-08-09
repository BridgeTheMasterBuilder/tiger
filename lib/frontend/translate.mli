open Agnostic
open Backend.Frame

type exp
type level
type access

val outermost : level
val fragments : Frame.frag list ref
val new_level : level -> Temp.label -> bool list -> level
val formals : level -> access list
val alloc_local : level -> bool -> access
val proc_entry_exit : level -> exp -> unit
val get_result : unit -> Frame.frag list
val nil_exp : unit -> exp
val int_exp : int -> exp
val string_exp : string -> exp
val external_call : string -> exp list -> exp
val call_exp : Symbol.symbol -> access list -> exp list -> level -> level -> exp
val arith_exp : Absyn.oper -> exp -> exp -> exp
val cond_exp : Absyn.oper -> exp -> exp -> exp
val str_cond_exp : Absyn.oper -> exp -> exp -> exp
val record_exp : exp list -> exp
val seq_exp : exp list -> exp
val assign_exp : exp -> exp -> exp
val if_exp : exp -> exp -> exp option -> exp
val while_exp : exp -> exp -> Symbol.symbol -> exp
val unit_exp : unit -> exp
val break_exp : Symbol.symbol -> exp
val let_exp : exp list -> exp -> exp
val array_exp : exp -> exp -> exp
val varDec : exp -> exp -> exp
val simple_var : access -> level -> exp
val field_var : exp -> int -> exp
val subscript_var : exp -> exp -> exp
val print : exp -> unit
