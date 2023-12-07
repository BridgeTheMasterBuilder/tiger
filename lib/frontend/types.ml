open Agnostic

type unique = unit ref
type record_descriptor = string
type array_descriptor = bool

type ty =
  | Record of (Symbol.symbol * ty) list * unique * record_descriptor
  | Nil
  | Int
  | String
  | Array of ty * unique * array_descriptor
  | Name of Symbol.symbol * ty option ref
  | Unit

let string_of_ty = function
  | Record _ -> "record"
  | Nil -> "nil"
  | Int -> "int"
  | String -> "string"
  | Array _ -> "array"
  | Name (name, _) -> Symbol.name name
  | Unit -> "unit"

let is_pointer = function Record _ | Array _ | String -> true | _ -> false
