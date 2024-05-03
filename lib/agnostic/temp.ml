open Containers

type temp = int
type t = temp
type label = Symbol.symbol
type 'a table = (t, 'a) Hashtbl.t

let pointer_map = Hashtbl.create 1000
let nexttemp = ref 0

let newtemp () =
  let temp = !nexttemp in
  incr nexttemp;
  Hashtbl.replace pointer_map temp false;
  temp

let to_int temp = temp
let make_string temp = "t" ^ string_of_int temp
let next_label = ref 0

let new_label () =
  let label = !next_label in
  incr next_label;
  Symbol.symbol ("L" ^ string_of_int label)

let named_label name =
  let label = !next_label in
  incr next_label;
  Symbol.symbol ("L" ^ string_of_int label ^ "_" ^ name)

let global_label = Symbol.symbol
let compare a b = Stdlib.compare a b
let equal a b = a = b
