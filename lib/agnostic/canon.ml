open Containers
module T = Tree

let linearize stm0 =
  let ( % ) x y =
    match (x, y) with
    | T.Exp (T.Const _), z -> z
    | z, T.Exp (T.Const _) -> z
    | z, w -> T.Seq (z, w)
  in

  let commute = function
    | T.Exp (T.Const _), _ -> true
    | _, T.Name _ -> true
    | _, T.Const _ -> true
    | _ -> false
  in

  let nop = T.Exp (T.Const 0) in

  let rec reorder = function
    | (T.Call _ as e) :: rest ->
        let t = Temp.newtemp () in
        reorder (T.Eseq (T.Move (T.Temp t, e), T.Temp t) :: rest)
    | a :: rest ->
        let stms, e = do_exp a in
        let stms', el = reorder rest in
        if commute (stms', e) then (stms % stms', e :: el)
        else
          let t = Temp.newtemp () in
          (stms % (T.Move (T.Temp t, e) % stms'), T.Temp t :: el)
    | [] -> (nop, [])
  and reorder_exp (el, build) =
    let stms, el' = reorder el in
    (stms, build el')
  and reorder_stm (el, build) =
    let stms, el' = reorder el in
    stms % build el'
  and do_stm = function
    | T.Seq (a, b) -> do_stm a % do_stm b
    | T.Jump (e, labs) ->
        let build_exp = function
          | [ e ] -> T.Jump (e, labs)
          | _ -> assert false
        in
        reorder_stm ([ e ], build_exp)
    | T.Cjump (p, a, b, t, f) ->
        let build_exp = function
          | [ a; b ] -> T.Cjump (p, a, b, t, f)
          | _ -> assert false
        in
        reorder_stm ([ a; b ], build_exp)
    | T.Move (T.Mem e, b) ->
        let build_exp = function
          | [ e; b ] -> T.Move (T.Mem e, b)
          | _ -> assert false
        in
        reorder_stm ([ e; b ], build_exp)
    | T.Move (T.Temp t, T.Call (e, el)) ->
        let build_exp escapes = function
          | e :: el -> T.Move (T.Temp t, T.Call (e, List.combine el escapes))
          | _ -> assert false
        in
        let el, escapes = List.split el in
        reorder_stm (e :: el, build_exp escapes)
    | T.Move (T.Temp t, b) ->
        let build_exp = function
          | [ b ] -> T.Move (T.Temp t, b)
          | _ -> assert false
        in
        reorder_stm ([ b ], build_exp)
    | T.Move (T.Eseq (s, e), b) -> do_stm (T.Seq (s, T.Move (e, b)))
    | T.Exp (T.Call (e, el)) ->
        let build_exp escapes = function
          | e :: el -> T.Exp (T.Call (e, List.combine el escapes))
          | _ -> assert false
        in
        let el, escapes = List.split el in
        reorder_stm (e :: el, build_exp escapes)
    | T.Exp e ->
        let build_exp = function [ e ] -> T.Exp e | _ -> assert false in
        reorder_stm ([ e ], build_exp)
    | s ->
        let build_exp = function [] -> s | _ -> assert false in
        reorder_stm ([], build_exp)
  and do_exp = function
    | T.Binop (p, a, b) ->
        let build_exp = function
          | [ a; b ] -> T.Binop (p, a, b)
          | _ -> assert false
        in
        reorder_exp ([ a; b ], build_exp)
    | T.Mem a ->
        let build_exp = function [ a ] -> T.Mem a | _ -> assert false in
        reorder_exp ([ a ], build_exp)
    | T.Eseq (s, e) ->
        let stms = do_stm s in
        let stms', e = do_exp e in
        (stms % stms', e)
    | T.Call (e, el) ->
        let build_exp escapes = function
          | e :: el -> T.Call (e, List.combine el escapes)
          | _ -> assert false
        in
        let el, escapes = List.split el in
        reorder_exp (e :: el, build_exp escapes)
    | e ->
        let build_exp = function [] -> e | _ -> assert false in
        reorder_exp ([], build_exp)
  in

  let rec linear = function
    | T.Seq (a, b), l -> linear (a, linear (b, l))
    | s, l -> s :: l
  in

  linear (do_stm stm0, [])

let basic_blocks stms =
  let _done = Temp.new_label () in
  let rec blocks = function
    | (T.Label _ as head) :: tail, blist ->
        let rec next = function
          | (T.Jump _ as s) :: rest, thisblock -> endblock (rest, s :: thisblock)
          | (T.Cjump _ as s) :: rest, thisblock ->
              endblock (rest, s :: thisblock)
          | (T.Label lab :: _ as stms), thisblock ->
              next (T.Jump (T.Name lab, [ lab ]) :: stms, thisblock)
          | s :: rest, thisblock -> next (rest, s :: thisblock)
          | [], thisblock ->
              next ([ T.Jump (T.Name _done, [ _done ]) ], thisblock)
        and endblock (stms, thisblock) =
          blocks (stms, List.rev thisblock :: blist)
        in
        next (tail, [ head ])
    | [], blist -> List.rev blist
    | stms, blist -> blocks (T.Label (Temp.new_label ()) :: stms, blist)
  in
  (blocks (stms, []), _done)

let enter_block = function
  | (T.Label s :: _ as b), table -> Symbol.enter table s b
  | _, table -> table

let rec split_last = function
  | [] -> assert false
  | [ x ] -> ([], x)
  | h :: t ->
      let t', last = split_last t in
      (h :: t', last)

let rec trace = function
  | table, (T.Label lab :: _ as b), rest -> (
      let table = Symbol.enter table lab [] in
      match split_last b with
      | most, T.Jump (T.Name lab, _) -> (
          match Symbol.look table lab with
          | Some (_ :: _ as b') -> most @ trace (table, b', rest)
          | _ -> b @ get_next (table, rest))
      | most, T.Cjump (op, x, y, t, f) -> (
          match (Symbol.look table t, Symbol.look table f) with
          | _, Some (_ :: _ as b') -> b @ trace (table, b', rest)
          | Some (_ :: _ as b'), _ ->
              most
              @ [ T.Cjump (T.notRel op, x, y, f, t) ]
              @ trace (table, b', rest)
          | _ ->
              let f' = Temp.new_label () in
              most
              @ [
                  T.Cjump (op, x, y, t, f'); T.Label f'; T.Jump (T.Name f, [ f ]);
                ]
              @ get_next (table, rest))
      | _, T.Jump _ -> b @ get_next (table, rest)
      | _ -> ErrorMsg.impossible "Couldn't construct trace")
  | _ -> ErrorMsg.impossible "Couldn't construct trace"

and get_next = function
  | table, (T.Label lab :: _ as b) :: rest -> (
      match Symbol.look table lab with
      | Some (_ :: _) -> trace (table, b, rest)
      | _ -> get_next (table, rest))
  | _, [] -> []
  | _ -> assert false

let trace_schedule (blocks, exit_label) =
  let res : T.stm list =
    let tbl : T.stm list Symbol.table =
      List.fold_right
        (fun acc tbl -> enter_block (acc, tbl))
        blocks (Symbol.empty ())
    in
    get_next (tbl, blocks)
  in
  res @ [ T.Label exit_label ]
