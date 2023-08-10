open Agnostic
open Containers
open Frontend
open Backend
open Backend.Frame
open Backend.Codegen

let run filename output_assembly =
  try
    ErrorMsg.filename := filename;
    let lexbuf = Lexing.from_channel (open_in filename) in
    let ast = Parser.program Lexer.initial lexbuf in
    FindEscape.find_escape ast;
    let fragments = Semant.transProg ast in
    let base_filename = Filename.(basename filename |> remove_extension) in

    let output_filename, output_channel =
      if output_assembly then
        let output_filename = base_filename ^ ".asm" in
        let output_channel = open_out output_filename in
        (output_filename, output_channel)
      else Filename.open_temp_file (base_filename ^ "_") ".asm"
    in
    let base_filename = Filename.remove_extension output_filename in
    let object_file = base_filename ^ ".o" in
    Symbol.iter
      (fun k _ -> Printf.fprintf output_channel "extern %s\n" (Symbol.name k))
      Env.base_venv;
    Printf.fprintf output_channel "extern initArray\n";
    Printf.fprintf output_channel "extern malloc\n";
    Printf.fprintf output_channel "extern strCmp\n\n";
    Printf.fprintf output_channel "global tigermain\n\n";
    let string_literals = ref [] in
    Printf.fprintf output_channel "section .text\n";
    List.iter
      (fun frag ->
        match frag with
        | Frame.Proc { body; frame } ->
            let stms = Canon.linearize body in
            let blocks = Canon.basic_blocks stms in
            let trace = Canon.trace_schedule blocks in
            let insns = List.map Codegen.codegen trace |> List.flatten in
            let print_insns insns allocation =
              List.iter
                (fun insn ->
                  match insn with
                  | Assem.Move { assem; dst = [ dst ]; src = [ src ]; _ }
                    when (not (String.contains assem '['))
                         (* TODO *)
                         && String.equal
                              (Hashtbl.find allocation dst)
                              (Hashtbl.find allocation src) ->
                      (* Ignore self-moves *)
                      ()
                  | _ ->
                      let s = Assem.format (Frame.map_temp allocation) insn in
                      if not (String.equal s "") then
                        Printf.fprintf output_channel "%s\n" s)
                insns
            in
            let body = Frame.proc_entry_exit frame insns in
            let insns, allocation =
              RegAlloc.alloc frame body Frame.calleesaves
            in
            print_insns insns allocation
        | Frame.String (lab, s) ->
            string_literals := (lab, s) :: !string_literals)
      fragments;

    Printf.fprintf output_channel "section .rodata\n";
    List.iter
      (fun (lab, s) ->
        (* TODO AWFUL hack *)
        let s = "\"" ^ s ^ "\"" in
        let s = Str.global_replace (Str.regexp "\"\n\"") "0xA" s in
        let s = Str.global_replace (Str.regexp "\"\n") "0xA, \"" s in
        let s = Str.global_replace (Str.regexp "\n\"") "\", 0xA" s in
        Printf.fprintf output_channel "%s: db %s, 0\n" (Symbol.name lab) s)
      !string_literals;
    flush output_channel;
    if output_assembly then ()
    else if
      Sys.command ("nasm -felf64 " ^ output_filename ^ " -o " ^ object_file) = 0
    then (
      if
        Sys.command
          ("gcc -no-pie -fno-builtin -Wl,--no-warn-execstack " ^ " runtime.o "
         ^ object_file)
        <> 0
      then ErrorMsg.impossible "Linking phase failed.")
    else ErrorMsg.impossible "Compiler emitted invalid assembly code.";
    ()
  with
  | ErrorMsg.Error -> exit 1
  | Parser.Error ->
      prerr_endline "Syntax error.";
      exit 1
