open Containers
module T = Tree

let print (s0 : Tree.stm) : unit =
  let say s = print_string s in
  let sayln s =
    say s;
    say "\n"
  in
  let rec indent = function
    | 0 -> ()
    | i when i mod 4 = 0 ->
        indent (i - 1);
        say "+"
    | i ->
        indent (i - 1);
        say "-"
  in
  let rec stm : Tree.stm * int -> unit = function
    | T.Seq (a, b), d ->
        indent d;
        sayln "SEQ(";
        stm (a, d + 1);
        sayln ",";
        stm (b, d + 1);
        say ")"
    | T.Label lab, d ->
        indent d;
        say "LABEL ";
        say (Symbol.name lab)
    | T.Jump (e, _), d ->
        indent d;
        sayln "JUMP(";
        exp (e, d + 1);
        say ")"
    | T.Cjump (r, a, b, t, f), d ->
        indent d;
        say "CJUMP(";
        relop r;
        sayln ",";
        exp (a, d + 1);
        sayln ",";
        exp (b, d + 1);
        sayln ",";
        indent (d + 1);
        say (Symbol.name t);
        say ",";
        say (Symbol.name f);
        say ")"
    | T.Move (a, b), d ->
        indent d;
        sayln "MOVE(";
        exp (a, d + 1);
        sayln ",";
        exp (b, d + 1);
        say ")"
    | T.Exp e, d ->
        indent d;
        sayln "EXP(";
        exp (e, d + 1);
        say ")"
  and exp : Tree.exp * int -> unit = function
    | T.Binop (p, a, b), d ->
        indent d;
        say "BINOP(";
        binop p;
        sayln ",";
        exp (a, d + 1);
        sayln ",";
        exp (b, d + 1);
        say ")"
    | T.Mem e, d ->
        indent d;
        sayln "MEM(";
        exp (e, d + 1);
        say ")"
    | T.Temp t, d ->
        indent d;
        say "TEMP t";
        say (string_of_int (Temp.to_int t))
    | T.Eseq (s, e), d ->
        indent d;
        sayln "ESEQ(";
        stm (s, d + 1);
        sayln ",";
        exp (e, d + 1);
        say ")"
    | T.Name lab, d ->
        indent d;
        say "NAME ";
        say (Symbol.name lab)
    | T.Const i, d ->
        indent d;
        say "CONST ";
        say (string_of_int i)
    | T.Call (e, el), d ->
        indent d;
        sayln "CALL(";
        exp (e, d + 1);
        List.iter
          (fun (a, _) ->
            sayln ",";
            exp (a, d + 2))
          el;
        say ")"
  and binop : Tree.binop -> unit = function
    | T.Plus -> say "PLUS"
    | T.Minus -> say "MINUS"
    | T.Mul -> say "MUL"
    | T.Div -> say "DIV"
    | T.And -> say "AND"
    | T.Or -> say "OR"
    | T.Lshift -> say "LSHIFT"
    | T.Rshift -> say "RSHIFT"
    | T.Arshift -> say "ARSHIFT"
    | T.Xor -> say "XOR"
  and relop : Tree.relop -> unit = function
    | T.Eq -> say "EQ"
    | T.Ne -> say "NE"
    | T.Lt -> say "LT"
    | T.Gt -> say "GT"
    | T.Le -> say "LE"
    | T.Ge -> say "GE"
    | T.Ult -> say "ULT"
    | T.Ule -> say "ULE"
    | T.Ugt -> say "UGT"
    | T.Uge -> say "UGE"
  in
  stm (s0, 0);
  sayln ""
