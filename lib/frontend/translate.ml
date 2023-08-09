open Agnostic
open Containers
open Backend.Frame
module T = Tree

type exp =
  | Ex of Tree.exp
  | Nx of Tree.stm
  | Cx of (Temp.label -> Temp.label -> Tree.stm)

type level = { parent : level option; frame : Frame.t; id : unit ref }
type access = level * Frame.access

let outermost =
  {
    parent = None;
    frame = Frame.new_frame (Symbol.symbol "tigermain") [ false ];
    id = ref ();
  }

let fragments = ref []
let string_map = Hashtbl.create 10

let new_level parent name formals =
  let frame = Frame.new_frame name (true :: formals) in
  { parent = Some parent; frame; id = ref () }

let formals level =
  let { frame; _ } = level in
  let formals = List.tl (Frame.formals frame) in
  List.map (fun access -> (level, access)) formals

let alloc_local level escape =
  let { frame; _ } = level in
  let local = Frame.alloc_local frame escape in
  (level, local)

let get_result () = !fragments

let seq = function
  | x :: xs -> List.fold_left (fun stm seqs -> T.Seq (stm, seqs)) x xs
  | _ -> ErrorMsg.impossible "Translate.seq failure"

let un_ex = function
  | Ex e -> e
  | Cx genstm ->
      let r = Temp.newtemp () in
      let t = Temp.new_label () in
      let f = Temp.new_label () in
      T.Eseq
        ( seq
            [
              T.Move (T.Temp r, T.Const 1);
              genstm t f;
              T.Label f;
              T.Move (T.Temp r, T.Const 0);
              T.Label t;
            ],
          T.Temp r )
  | Nx s -> T.Eseq (s, T.Const 0)

let un_cx = function
  | Cx genstm -> genstm
  | Ex (T.Const 0) -> fun _ f -> T.(Jump (Name f, [ f ]))
  | Ex (T.Const 1) -> fun t _ -> T.(Jump (Name t, [ t ]))
  | Ex e -> fun t f -> T.(Cjump (Ne, e, Const 0, t, f))
  | Nx _ -> failwith "Impossible combination UnCx (Nx _)"

let un_nx = function
  | Nx s -> s
  | Ex e -> T.Exp e
  | Cx genstm ->
      let l = Temp.new_label () in
      T.Seq (genstm l l, T.Label l)

let proc_entry_exit level body =
  let { frame; _ } = level in
  let body = un_ex body in
  let body = un_nx (Nx T.(Move (Temp Frame.rv, body))) in
  fragments := Frame.Proc { body; frame } :: !fragments

let nil_exp () = Ex (T.Const 0)
let int_exp i = Ex (T.Const i)

let string_exp s =
  match Hashtbl.find_opt string_map s with
  | Some label -> Ex (T.Name label)
  | None ->
      let label = Temp.new_label () in
      let fragment = Frame.String (label, s) in
      fragments := fragment :: !fragments;
      Hashtbl.add string_map s label;
      Ex (T.Name label)

let external_call f args =
  let args = List.map un_ex args in
  Ex (Frame.external_call f args)

let create_static_link_chain use_level dec_level =
  let rec aux level =
    let { parent; frame; id } = level in
    if Equal.physical dec_level.id id then T.Temp Frame.fp
    else
      Frame.exp
        (aux
           (Option.get_exn_or
              "Fatal error - the compiler encountered an impossible situation"
              parent))
        (List.hd (Frame.formals frame))
  in
  aux use_level

let call_exp f formals args use_level dec_level =
  let dec_level =
    Option.get_exn_or
      "Fatal error - the compiler encountered an impossible situation"
      dec_level.parent
  in
  let args = List.map un_ex args in
  let sl = create_static_link_chain use_level dec_level in
  let formals =
    List.map (fun (_, formal) -> Frame.frame_resident formal) formals
  in
  Ex (T.Call (T.Name f, List.combine (sl :: args) (true :: formals)))

let arith_exp o e1 e2 =
  let module A = Absyn in
  let o =
    match o with
    | A.PlusOp -> T.Plus
    | A.MinusOp -> T.Minus
    | A.TimesOp -> T.Mul
    | A.DivideOp -> T.Div
    | _ -> failwith "Unreachable"
  in
  let e1 = un_ex e1 in
  let e2 = un_ex e2 in
  Ex (T.Binop (o, e1, e2))

let cond_exp o e1 e2 =
  let module A = Absyn in
  let o =
    match o with
    | A.EqOp -> T.Eq
    | A.NeqOp -> T.Ne
    | A.GtOp -> T.Gt
    | A.LtOp -> T.Lt
    | A.GeOp -> T.Ge
    | A.LeOp -> T.Le
    | _ -> failwith "Unreachable"
  in
  let e1 = un_ex e1 in
  let e2 = un_ex e2 in
  Cx (fun t f -> T.Cjump (o, e1, e2, t, f))

let str_cond_exp o e1 e2 =
  let e1 = un_ex e1 in
  let e2 = un_ex e2 in
  let r = Ex (Frame.external_call "strCmp" [ e1; e2 ]) in
  let z = Ex (T.Const 0) in
  cond_exp o r z

let record_exp exps =
  let n = List.length exps in
  let r = Temp.newtemp () in
  let exps =
    List.mapi
      (fun i exp ->
        let exp = un_ex exp in
        T.(Move (Mem (Binop (Plus, Temp r, Const (i * Frame.word_size))), exp)))
      exps
  in
  Ex
    T.(
      Eseq
        ( Seq
            ( Move
                ( Temp r,
                  Frame.external_call "malloc" [ Const (n * Frame.word_size) ]
                ),
              seq exps ),
          Temp r ))

let seq_exp = function
  | [] -> Ex (T.Const 0)
  | [ stm ] -> Ex (un_ex stm)
  | seqs ->
      let reversed = List.rev seqs in
      let exp = List.hd reversed |> un_ex in
      let seqs = List.tl reversed |> List.rev in
      let stms = List.map (fun stm -> T.Exp (un_ex stm)) seqs in
      Ex (T.Eseq (seq stms, exp))

let assign_exp lvalue exp =
  let lhs = un_ex lvalue in
  let rhs = un_ex exp in
  Nx (T.Move (lhs, rhs))

(* TODO special cases *)
let if_exp test then' else' =
  let test = un_cx test in
  let then' = un_ex then' in
  match else' with
  | Some else' ->
      let else' = un_ex else' in
      let r = Temp.newtemp () in
      let t = Temp.new_label () in
      let f = Temp.new_label () in
      let join = Temp.new_label () in
      Ex
        T.(
          Eseq
            ( seq
                [
                  test t f;
                  Label t;
                  Move (Temp r, then');
                  Jump (Name join, [ join ]);
                  Label f;
                  Move (Temp r, else');
                  Label join;
                ],
              Temp r ))
  | None ->
      let t = Temp.new_label () in
      let f = Temp.new_label () in
      Nx (seq [ test t f; Label t; T.Exp then'; Label f ])

let while_exp condition body done_label =
  let test = Temp.new_label () in
  let loop = Temp.new_label () in
  let condition = un_cx condition in
  let body = un_ex body in
  Nx
    (seq
       [
         T.Label test;
         condition loop done_label;
         T.Label loop;
         T.Exp body;
         T.Jump (T.Name test, [ test ]);
         T.Label done_label;
       ])

let break_exp done_label = Nx (T.Jump (T.Name done_label, [ done_label ]))
let unit_exp () = Nx (T.Exp (T.Const 0))

let let_exp decs body =
  let decs = List.map un_nx decs in
  let body = un_ex body in
  if List.is_empty decs then Ex body else Ex (T.Eseq (seq decs, body))

let array_exp length init =
  let length = un_ex length in
  let init = un_ex init in
  Ex (Frame.external_call "initArray" [ length; init ])

let varDec var exp =
  let var = un_ex var in
  let exp = un_ex exp in
  Nx (T.Move (var, exp))

let print exp = Prtree.print (un_nx exp)

let simple_var access use_level =
  let dec_level, access_x = access in
  Ex (Frame.exp (create_static_link_chain use_level dec_level) access_x)

let field_var exp i =
  let exp = un_ex exp in
  Ex T.(Mem (Binop (Plus, exp, Binop (Mul, Const i, Const Frame.word_size))))

let subscript_var exp idx =
  let exp = un_ex exp in
  let idx = un_ex idx in
  Ex T.(Mem (Binop (Plus, exp, Binop (Mul, idx, Const Frame.word_size))))
