type exp =
  | Const of int
  | Name of Temp.label
  | Temp of Temp.t
  | Binop of binop * exp * exp
  | Mem of exp
  | Call of exp * (exp * bool) list
  | Eseq of stm * exp

and stm =
  | Move of exp * exp
  | Exp of exp
  | Jump of exp * Temp.label list
  | Cjump of relop * exp * exp * Temp.label * Temp.label
  | Seq of stm * stm
  | Label of Temp.label

and binop =
  | Plus
  | Minus
  | Mul
  | Div
  | And
  | Or
  | Lshift
  | Rshift
  | Arshift
  | Xor

and relop = Eq | Ne | Lt | Gt | Le | Ge | Ult | Ule | Ugt | Uge

let notRel (op : relop) : relop =
  match op with
  | Eq -> Ne
  | Ne -> Eq
  | Lt -> Ge
  | Le -> Gt
  | Gt -> Le
  | Ge -> Lt
  | Ult -> Uge
  | Ule -> Ugt
  | Ugt -> Ule
  | Uge -> Ult
