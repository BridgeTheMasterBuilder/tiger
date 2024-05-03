type t
type label = Symbol.symbol
type 'a table = (t, 'a) Hashtbl.t

val pointer_map : bool table
val newtemp : unit -> t
val to_int : t -> int
val make_string : t -> string
val new_label : unit -> label
val named_label : string -> label
val global_label : string -> label
val compare : t -> t -> int
val equal : t -> t -> bool
