open Agnostic

type unique = unit ref

type ty =
  | Record of (Symbol.symbol * ty) list * unique
  | Nil
  | Int
  | String
  | Array of ty * unique
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
