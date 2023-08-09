open Containers
open Util

type reg = string
type temp = Temp.t
type label = Temp.label

type insn =
  | Oper of {
      assem : string;
      dst : temp list;
      src : temp list;
      jump : label list option;
    }
  | Label of { assem : string; lab : Temp.label }
  | Move of { assem : string; dst : temp list; src : temp list }

let format saytemp insn =
  let speak (assem, dst, src, jump) =
    let saylab = Symbol.name in
    let ord = Char.code in
    let rec f = function
      | '`' :: 's' :: i :: rest ->
          explode (saytemp (List.nth src (ord i - ord '0'))) @ f rest
      | '`' :: 'd' :: i :: rest ->
          explode (saytemp (List.nth dst (ord i - ord '0'))) @ f rest
      | '`' :: 'j' :: i :: rest ->
          explode (saylab (List.nth jump (ord i - ord '0'))) @ f rest
      | '`' :: '`' :: rest -> '`' :: f rest
      | '`' :: _ :: _ -> ErrorMsg.impossible "bad Assem format"
      | c :: rest -> c :: f rest
      | [] -> []
    in
    implode (f (explode assem))
  in
  match insn with
  | Oper { assem; dst; src; jump = None } -> speak (assem, dst, src, [])
  | Oper { assem; dst; src; jump = Some j } -> speak (assem, dst, src, j)
  | Label { assem; _ } -> assem
  | Move { assem; dst; src } -> speak (assem, dst, src, [])
