open Containers

type entry = { key : Temp.label }
type t = entry list

let entries = ref []
let get_entries = List.rev !entries
let new_entry key = entries := { key } :: !entries
