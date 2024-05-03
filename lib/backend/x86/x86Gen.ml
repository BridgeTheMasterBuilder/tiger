open Agnostic
open Containers
module T = Tree
module A = Assem

let string_of_op = function
  | T.Plus -> "add"
  | T.Minus -> "sub"
  | T.Mul -> "imul"
  | T.Div -> "idiv"
  | T.And -> "and"
  | T.Or -> "or"
  | T.Lshift -> "shl"
  | T.Rshift -> "shr"
  | T.Arshift -> "sar"
  | T.Xor -> "xor"

let string_of_relop = function
  | T.Eq -> "e"
  | T.Ne -> "ne"
  | T.Lt -> "l"
  | T.Le -> "le"
  | T.Gt -> "g"
  | T.Ge -> "ge"
  | T.Ult -> "b"
  | T.Ule -> "be"
  | T.Ugt -> "a"
  | T.Uge -> "ae"

let codegen stm =
  let ilist = ref [] in
  let emit x = ilist := x :: !ilist in
  let emit_binop r op e1 s1 e2 s2 =
    let op = string_of_op op in
    emit (A.Move { assem = "mov `d0, " ^ s1; src = e1; dst = [ r ] });
    emit
      (A.Oper
         {
           assem = op ^ " `d0, " ^ s2;
           src = e2 @ [ r ];
           dst = [ r ];
           jump = None;
         })
  in
  let emit_jcc op e1 s1 e2 s2 t f =
    let cc = string_of_relop op in
    emit
      (A.Oper
         {
           assem = "cmp " ^ s1 ^ ", " ^ s2;
           dst = [];
           src = e1 @ e2;
           jump = None;
         });
    emit
      (A.Oper
         { assem = "j" ^ cc ^ " `j0"; dst = []; src = []; jump = Some [ t; f ] })
  in
  let result gen =
    (* TODO May be pointer *)
    let t = Temp.newtemp () in
    gen t;
    t
  in
  let rec munch_stm = function
    | T.Move ((T.Mem _ as lhs), rhs) ->
        let e1, s1, next_index = munch_lhs true 0 lhs in
        let e2, s2 = munch_no_mem_rhs next_index rhs in
        emit
          (A.Move { assem = "mov " ^ s1 ^ ", " ^ s2; src = e1 @ e2; dst = e1 })
    | T.Move (lhs, (Binop _ as rhs)) ->
        let e1, s1, next_index = munch_lhs false 0 lhs in
        let e2, s2, _ = munch_effective_address next_index rhs in
        emit
          (A.Move { assem = "lea " ^ s1 ^ ", [" ^ s2 ^ "]"; src = e2; dst = e1 })
    | T.Move (lhs, rhs) ->
        let e1, s1, next_index = munch_lhs false 0 lhs in
        let e2, s2 = munch_rhs next_index rhs in
        emit (A.Move { assem = "mov " ^ s1 ^ ", " ^ s2; src = e2; dst = e1 })
    | T.Cjump (op, (T.Mem _ as lhs), rhs, t, f) ->
        let e1, s1, next_index = munch_lhs true 0 lhs in
        let e2, s2 = munch_no_mem_rhs next_index rhs in
        emit_jcc op e1 s1 e2 s2 t f
    | T.Cjump (op, lhs, rhs, t, f) ->
        let e1, s1, next_index = munch_lhs true 0 lhs in
        let e2, s2 = munch_rhs next_index rhs in
        emit_jcc op e1 s1 e2 s2 t f
    | T.Jump (T.Name lab, [ l ]) ->
        assert (Symbol.equal lab l);
        emit
          (A.Oper { assem = "jmp `j0"; dst = []; src = []; jump = Some [ lab ] })
    | T.Jump _ -> failwith "Computed jumps not implemented"
    | T.Exp e -> munch_exp e |> ignore
    | T.Label lab -> emit (A.Label { assem = Symbol.name lab ^ ":"; lab })
    | T.Seq _ -> failwith "There shouldn't be any more Seqs"
  and munch_exp = function
    | T.(Binop (Div, lhs, rhs)) ->
        let e1, s1, _ = munch_lhs true 0 lhs in
        let e2, s2, _ = munch_lhs true 0 rhs in

        result (fun r ->
            emit
              (A.Move
                 { assem = "mov rax, " ^ s1; src = e1; dst = [ X86Frame.rax ] });
            emit
              (A.Oper
                 {
                   assem = "xor rdx, rdx";
                   src = [ X86Frame.rdx ];
                   dst = [ X86Frame.rdx ];
                   jump = None;
                 });
            emit
              (A.Oper
                 {
                   assem = "idiv " ^ s2;
                   src = e2 @ [ X86Frame.rax; X86Frame.rdx ];
                   dst = [ X86Frame.rax; X86Frame.rdx ];
                   jump = None;
                 });
            emit
              (A.Move
                 { assem = "mov `d0, rax"; src = [ X86Frame.rax ]; dst = [ r ] }))
    | T.(Binop (op, lhs, rhs)) ->
        let e1, s1 = munch_rhs 0 lhs in
        let e2, s2 = munch_rhs 0 rhs in

        result (fun r -> emit_binop r op e1 s1 e2 s2)
    | T.Call (T.Name f, args) ->
        result (fun r ->
            emit
              (* (A.Oper *)
              (*    { *)
              (*      assem = "call " ^ Symbol.name f; *)
              (*      src = munch_args 0 args; *)
              (*      dst = X86Frame.calldefs; *)
              (*      jump = None; *)
              (*    }); *)
              (A.Call
                 {
                   assem = "call " ^ Symbol.name f;
                   src = munch_args 0 args;
                   dst = X86Frame.calldefs;
                 });
            emit
              (A.Move
                 { assem = "mov `d0, `s0"; src = [ X86Frame.rv ]; dst = [ r ] }))
    | T.Mem e ->
        result (fun r ->
            emit
              (A.Move
                 {
                   assem = "mov `d0, qword [`s0]";
                   src = [ munch_exp e ];
                   dst = [ r ];
                 }))
    | T.Name lab ->
        result (fun r ->
            emit
              (A.Move
                 {
                   assem = "mov `d0, " ^ Symbol.name lab;
                   src = [];
                   dst = [ r ];
                 }))
    | T.Const c ->
        result (fun r ->
            emit
              (A.Move
                 {
                   assem = "mov `d0, " ^ string_of_int c;
                   src = [];
                   dst = [ r ];
                 }))
    | T.Temp t -> t
    | T.Call _ -> failwith "Computed calls not implemented"
    | T.Eseq _ -> failwith "There shouldn't be any more Eseqs"
  and munch_args i = function
    | [] -> []
    | (arg, frame_resident) :: args ->
        let e = munch_exp arg in
        if frame_resident then (
          emit
            (A.Oper
               {
                 assem = "push `s0";
                 src = [ e ];
                 dst = [ X86Frame.rsp ];
                 jump = None;
               });
          munch_args i args)
        else
          let t = List.nth X86Frame.argregs i in
          emit (A.Move { assem = "mov `d0, `s0"; src = [ e ]; dst = [ t ] });
          t :: munch_args (i + 1) args
  and munch_lhs source index lhs =
    match lhs with
    | T.Mem e ->
        let e, s, next_index = munch_effective_address index e in
        (e, "qword [" ^ s ^ "]", next_index)
    | e ->
        ( [ munch_exp e ],
          (if source then "`s" else "`d") ^ string_of_int index,
          if source then index + 1 else 0 )
  and munch_effective_address index lhs =
    let string_of_op = function
      | T.Plus -> "+"
      | T.Minus -> "-"
      | _ -> ErrorMsg.impossible "Impossible operation"
    in
    let const_addition op i =
      match (op, i) with
      | "+", i when i < 0 -> string_of_int i
      | "+", i when i = 0 -> ""
      | "+", i -> "+" ^ string_of_int i
      | "-", i when i < 0 -> "+" ^ string_of_int i
      | "-", i when i = 0 -> ""
      | "-", i -> "-" ^ string_of_int i
      | _ ->
          ErrorMsg.impossible
            "Compiler failed during construction of effective address"
    in
    match lhs with
    | T.(
        Binop
          ( ((Plus | Minus) as op),
            Binop (Plus, e, Binop (Mul, i, Const w)),
            Const k ))
    | T.(
        Binop
          ( ((Plus | Minus) as op),
            Binop (Plus, e, Binop (Mul, Const w, i)),
            Const k ))
    | T.(
        Binop
          ( ((Plus | Minus) as op),
            Binop (Plus, Binop (Mul, i, Const w), e),
            Const k ))
    | T.(
        Binop
          ( ((Plus | Minus) as op),
            Binop (Plus, Binop (Mul, Const w, i), e),
            Const k ))
    | T.(
        Binop
          ( ((Plus | Minus) as op),
            Const k,
            Binop (Plus, e, Binop (Mul, i, Const w)) ))
    | T.(
        Binop
          ( ((Plus | Minus) as op),
            Const k,
            Binop (Plus, e, Binop (Mul, Const w, i)) ))
    | T.(
        Binop
          ( ((Plus | Minus) as op),
            Const k,
            Binop (Plus, Binop (Mul, i, Const w), e) ))
    | T.(
        Binop
          ( ((Plus | Minus) as op),
            Const k,
            Binop (Plus, Binop (Mul, Const w, i), e) )) ->
        (* [ base + idx*N + disp ] *)
        let op = string_of_op op in
        let addition = const_addition op k in
        if w = 1 || w = 2 || w = 4 || w = 8 then
          ( [ munch_exp e; munch_exp i ],
            "`s" ^ string_of_int index ^ "+`s"
            ^ string_of_int (index + 1)
            ^ "*" ^ string_of_int w ^ addition,
            index + 2 )
        else
          ( [ munch_exp e; munch_exp T.(Binop (Mul, i, Const w)) ],
            "`s" ^ string_of_int index ^ "+`s"
            ^ string_of_int (index + 1)
            ^ addition,
            index + 2 )
    | T.(Binop (Plus, e, Binop (Mul, i, Const w)))
    | T.(Binop (Plus, e, Binop (Mul, Const w, i)))
    | T.(Binop (Plus, Binop (Mul, i, Const w), e))
    | T.(Binop (Plus, Binop (Mul, Const w, i), e)) ->
        (* [ base + idx*N ] *)
        if w = 1 || w = 2 || w = 4 || w = 8 then
          ( [ munch_exp e; munch_exp i ],
            "`s" ^ string_of_int index ^ "+`s"
            ^ string_of_int (index + 1)
            ^ "*" ^ string_of_int w,
            index + 2 )
        else
          ( [ munch_exp e; munch_exp T.(Binop (Mul, i, Const w)) ],
            "`s" ^ string_of_int index ^ "+`s" ^ string_of_int (index + 1),
            index + 2 )
    | T.(Binop (((Plus | Minus) as op), e, Const i))
    | T.(Binop (((Plus | Minus) as op), Const i, e)) ->
        (* [ base + disp ] *)
        let op = string_of_op op in
        let addition = const_addition op i in
        ([ munch_exp e ], "`s" ^ string_of_int index ^ addition, index + 1)
    | T.(Binop (Plus, e1, e2)) ->
        (* [ base + idx*1 ] *)
        ( [ munch_exp e1; munch_exp e2 ],
          "`s" ^ string_of_int index ^ "+`s" ^ string_of_int (index + 1),
          index + 2 )
    | T.(Binop (Mul, Const w, e)) | T.(Binop (Mul, e, Const w)) ->
        (* [ idx*N ] *)
        if w = 1 || w = 2 || w = 4 || w = 8 then
          ( [ munch_exp e ],
            "`s" ^ string_of_int index ^ "*" ^ string_of_int w,
            index + 1 )
        else
          ( [ munch_exp T.(Binop (Mul, e, Const w)) ],
            "`s" ^ string_of_int index,
            index + 1 )
    | T.(Name label) ->
        (* [ label ] *)
        ([], Symbol.name label, index)
    | e ->
        (* [ base ] *)
        ([ munch_exp e ], "`s" ^ string_of_int index, index + 1)
  and munch_rhs index = function
    | T.Const c -> ([], string_of_int c)
    | e ->
        let e, s, _ = munch_lhs true index e in
        (e, s)
  and munch_no_mem_rhs index = function
    | T.Const c -> ([], string_of_int c)
    | e -> ([ munch_exp e ], "`s" ^ string_of_int index)
  in

  munch_stm stm;
  List.rev !ilist
