module type AbstractFrame = sig
  type t
  type access

  type body = {
    prologue : Assem.insn list;
    body : Assem.insn list;
    epilogue : Assem.insn list;
    sink : Assem.insn;
  }

  type frag =
    | Proc of { body : Tree.stm; frame : t }
    | String of Temp.label * string

  type register = string

  val rv : Temp.t
  val fp : Temp.t
  val specialregs : Temp.t list
  val calleesaves : Temp.t list
  val registers : register list
  val save_register : t -> Temp.t -> unit
  val word_size : int
  val temp_map : (Temp.t, register) Hashtbl.t
  val new_frame : Temp.label -> bool list -> t
  val anonymous_frame : bool list -> t
  val name : t -> Temp.label
  val formals : t -> access list
  val alloc_local : t -> bool -> access
  val exp : Tree.exp -> access -> Tree.exp
  val external_call : string -> Tree.exp list -> Tree.exp
  val proc_entry_exit : t -> Assem.insn list -> body
  val print_frame : t -> unit
  val map_temp : (Temp.t, register) Hashtbl.t -> Temp.t -> register
  val frame_resident : access -> bool
end
