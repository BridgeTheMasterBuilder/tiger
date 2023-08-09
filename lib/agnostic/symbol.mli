type symbol
type 'a table

val symbol : string -> symbol
val name : symbol -> string
val empty : unit -> 'a table
val enter : 'a table -> symbol -> 'a -> 'a table
val look : 'a table -> symbol -> 'a option
val iter : (symbol -> 'a -> unit) -> 'a table -> unit
val equal : symbol -> symbol -> bool
