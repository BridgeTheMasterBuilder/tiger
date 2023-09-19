open Agnostic
open Containers

type access = InFrame of int | InReg of Temp.t

type body = {
  prologue : Assem.insn list;
  body : Assem.insn list;
  epilogue : Assem.insn list;
  sink : Assem.insn;
}

type t = {
  formals : access list;
  mutable locals : access list;
  mutable number_of_locals : int;
  number_of_frame_params : int;
  label : Temp.label;
  body : body;
  mutable saved_registers : Temp.t list;
}

type frag =
  | Proc of { body : Tree.stm; frame : t }
  | String of Temp.label * string

type register = string

module T = Tree

let rax = Temp.newtemp ()
let rcx = Temp.newtemp ()
let rdx = Temp.newtemp ()
let rbx = Temp.newtemp ()
let rsp = Temp.newtemp ()
let rbp = Temp.newtemp ()
let rsi = Temp.newtemp ()
let rdi = Temp.newtemp ()
let r8 = Temp.newtemp ()
let r9 = Temp.newtemp ()
let r10 = Temp.newtemp ()
let r11 = Temp.newtemp ()
let r12 = Temp.newtemp ()
let r13 = Temp.newtemp ()
let r14 = Temp.newtemp ()
let r15 = Temp.newtemp ()
let rv = rax
let sp = rsp
let fp = rbp

let temp_map =
  let map = Hashtbl.create 16 in
  Hashtbl.add map rax "rax";
  Hashtbl.add map rcx "rcx";
  Hashtbl.add map rdx "rdx";
  Hashtbl.add map rbx "rbx";
  Hashtbl.add map rsp "rsp";
  Hashtbl.add map rbp "rbp";
  Hashtbl.add map rsi "rsi";
  Hashtbl.add map rdi "rdi";
  Hashtbl.add map r8 "r8";
  Hashtbl.add map r9 "r9";
  Hashtbl.add map r10 "r10";
  Hashtbl.add map r11 "r11";
  Hashtbl.add map r12 "r12";
  Hashtbl.add map r13 "r13";
  Hashtbl.add map r14 "r14";
  Hashtbl.add map r15 "r15";
  map

let map_temp allocation t =
  Option.value (Hashtbl.find_opt allocation t) ~default:(Temp.make_string t)

let word_size = 8
let specialregs = [ rv; sp; fp ]
let argregs = [ rdi; rsi; rdx; rcx; r8; r9 ]
let calldefs = [ rax; rcx; rdx; rsi; rdi; r8; r9; r10; r11; rsp ]
let calleesaves = [ rbx; r12; r13; r14; r15 ]

let registers =
  [
    "rax";
    "rcx";
    "rdx";
    "rbx";
    "rsp";
    "rbp";
    "rsi";
    "rdi";
    "r8";
    "r9";
    "r10";
    "r11";
    "r12";
    "r13";
    "r14";
    "r15";
  ]

let save_register frame reg =
  frame.saved_registers <- reg :: frame.saved_registers

let save_reg reg =
  Assem.Oper
    {
      assem = "push " ^ map_temp temp_map reg;
      dst = [];
      src = [ reg ];
      jump = None;
    }

let restore_reg reg =
  Assem.Oper
    {
      assem = "pop " ^ map_temp temp_map reg;
      dst = [ reg ];
      src = [];
      jump = None;
    }

let print_frame frame =
  let { label; formals; locals; _ } = frame in
  Printf.printf "New frame: %s\nFormals:\n" (Symbol.name label);
  List.iter
    (function
      | InFrame offset ->
          Printf.printf "Frame-resident variable at offset %d\n" offset
      | InReg temp ->
          Printf.printf "Register variable %s\n" (Temp.make_string temp))
    (formals @ locals);
  print_newline ()

let new_frame label escapes =
  let avail_registers = ref 6 in
  let count = ref 0 in
  let instructions = ref [] in
  let formals =
    List.map
      (fun escape ->
        if escape || !avail_registers = 0 then (
          let offset = (!count + 2) * word_size in
          incr count;
          InFrame offset)
        else
          let i = 6 - !avail_registers in
          let temp = List.nth argregs i in
          decr avail_registers;
          let t = Temp.newtemp () in
          let insn =
            Assem.Move { assem = "mov `d0, `s0"; dst = [ t ]; src = [ temp ] }
          in
          instructions := insn :: !instructions;
          InReg t)
      escapes
  in
  let frame =
    {
      formals;
      locals = [];
      number_of_locals = 0;
      number_of_frame_params = !count;
      label;
      body =
        {
          prologue = !instructions;
          body = [];
          epilogue = [];
          sink =
            Assem.Oper
              {
                assem = "";
                src = rsp :: rbp :: calleesaves;
                dst = [];
                jump = None;
              };
        };
      saved_registers = [];
    }
  in
  frame

let anonymous_frame = new_frame (Symbol.symbol "")
let name { label; _ } = label
let formals { formals; _ } = formals

let alloc_local frame escape =
  let local =
    if escape then (
      let offset = -(frame.number_of_locals + 1) * word_size in
      frame.number_of_locals <- frame.number_of_locals + 1;
      InFrame offset)
    else
      let temp = Temp.newtemp () in
      InReg temp
  in
  frame.locals <- frame.locals @ [ local ];
  local

let exp address = function
  | InFrame k -> T.(Mem (Binop (Plus, address, Const k)))
  | InReg t -> T.Temp t

let external_call f args =
  let args = List.map (fun arg -> (arg, false)) args in
  T.Call (T.Name (Temp.global_label f), args)

(* TODO adjust stack pointer *)
let proc_entry_exit frame body =
  let {
    number_of_locals;
    number_of_frame_params;
    label;
    body = { prologue; sink; _ };
    _;
  } =
    frame
  in
  let body = prologue @ body in
  let prologue =
    [
      Assem.Label { assem = Symbol.name label ^ ":"; lab = label };
      Assem.Oper { assem = "push rbp"; dst = []; src = [ fp ]; jump = None };
      Assem.Oper
        { assem = "mov rbp, rsp"; dst = [ fp ]; src = [ sp ]; jump = None };
    ]
    @ (if number_of_locals > 0 then
         [
           Assem.Oper
             {
               assem = "sub rsp, " ^ string_of_int (number_of_locals * 8);
               dst = [ sp ];
               src = [];
               jump = None;
             };
         ]
       else [])
    @ List.map save_reg (List.rev frame.saved_registers)
  in
  let epilogue =
    List.map restore_reg frame.saved_registers
    @ [
        Assem.Oper
          { assem = "leave"; dst = [ sp; fp ]; src = [ fp ]; jump = None };
        Assem.Oper
          {
            assem = "ret " ^ string_of_int (number_of_frame_params * 8) ^ "\n";
            dst = [ sp ];
            src = [];
            jump = None;
          };
      ]
  in
  { prologue; body; epilogue; sink }

let frame_resident = function InFrame _ -> true | InReg _ -> false
