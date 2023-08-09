open Containers

type symbol = string * int
type 'a table = (symbol, 'a) Hashtbl.t

let nextsym = ref 0
let size_hint = 128
let hashtable : (string, int) Hashtbl.t = Hashtbl.create size_hint

let symbol name =
  match Hashtbl.find_opt hashtable name with
  | Some i -> (name, i)
  | None ->
      let i = !nextsym in
      incr nextsym;
      Hashtbl.add hashtable name i;
      (name, i)

let name (s, _) = s
let empty () = Hashtbl.create size_hint

let enter tbl sym value =
  let tbl = Hashtbl.copy tbl in
  Hashtbl.add tbl sym value;
  tbl

let look = Hashtbl.find_opt
let iter = Hashtbl.iter
let equal = Equal.(map snd int)
