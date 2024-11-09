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
    let runtime_dir = Sys.getenv "TIGERC_RUNTIME_DIR" in
    Symbol.iter
      (fun k _ -> Printf.fprintf output_channel "extern %s\n" (Symbol.name k))
      Env.base_venv;
    Printf.fprintf output_channel "extern init_array\n";
    Printf.fprintf output_channel "extern alloc_record\n";
    Printf.fprintf output_channel "extern str_cmp\n\n";
    Printf.fprintf output_channel "global ptrmap_root\n\n";
    Printf.fprintf output_channel "global tigermain\n\n";
    let string_literals = ref [] in
    let last_ptrmap_entry = ref (Temp.named_label "ptrmap") in
    Printf.fprintf output_channel "section .text\n";
    let ptrmap =
      ref
        [
          Printf.sprintf "%s:\ndq 0\ndq 0\ndb 0\n"
            (Symbol.name !last_ptrmap_entry);
        ]
    in
    let handle_moves insns allocation frame =
      List.filter
        (fun node ->
          match FGraph.Flowgraph.V.label node with
          | Assem.Move { assem; dst = [ dst ]; src = [ src ]; _ }
            when (not (String.contains assem '['))
                 (* TODO this isn't portable, maybe add a predicate to Assem *)
                 && String.equal
                      (Hashtbl.find allocation dst)
                      (Hashtbl.find allocation src) ->
              (* Ignore self-moves *)
              false
          | _ -> true)
        insns
    in
    List.iter
      (function
        | Frame.Proc { body; frame } ->
            let stms = Canon.linearize body in
            let blocks = Canon.basic_blocks stms in
            let trace = Canon.trace_schedule blocks in
            let insns = List.map Codegen.codegen trace |> List.flatten in
            let print_insns insns allocation live_map =
              List.iter
                (fun node ->
                  match FGraph.Flowgraph.V.label node with
                  (* | Assem.Move { assem; dst = [ dst ]; src = [ src ]; _ } *)
                  (*   when (not (String.contains assem '[')) *)
                  (*        (\* TODO this isn't portable, maybe add a predicate to Assem *\) *)
                  (*        && String.equal *)
                  (*             (Hashtbl.find allocation dst) *)
                  (*             (Hashtbl.find allocation src) -> *)
                  (*     (\* Ignore self-moves *\) *)
                  (*     () *)
                  (* TODO add return label to Assem.Call, check *)
                  (* take in live_map param to this function check *)
                  (* and then if this instruction is a call instruction check *)
                  (* create a pointer map entry keyed by the return label and which contains *)
                  (* the live registers and frame locations for this call *)
                  (* in some format *)
                  (* Also need to pretty print frame variables check, kind of *)
                  | Assem.Call { ret; _ } as insn ->
                      (* Printf.printf "Checking %s - %s - %s:\n" *)
                      (*   (Symbol.name (Frame.name frame)) *)
                      (*   (Symbol.name ret) *)
                      (*   (Assem.format (Frame.map_temp allocation) insn); *)
                      let open Iter in
                      (* Liveness.LiveSet.to_iter *)
                      (*   (Hashtbl.find_opt live_map node *)
                      (*   |> Option.get_or ~default:Liveness.LiveSet.empty) *)
                      (* |> map (fun b -> (Frame.map_temp allocation b, b)) *)
                      (* |> iter (fun (s, b) -> *)
                      (*        Printf.printf "%s(%s) - %b\n" s *)
                      (*          (Temp.make_string b) *)
                      (*          (Hashtbl.find Temp.pointer_map b)); *)
                      (* Hashtbl.to_iter (Frame.pointer_map frame) *)
                      (* |> map (fun (local, b) -> *)
                      (*        (Frame.string_of_local allocation local, b)) *)
                      (* |> iter (fun (s, b) -> *)
                      (*        Printf.printf "%s(?) - %b\n" s *)
                      (*          (\* (Temp.make_string b) *\) b); *)
                      let reg_iter =
                        Liveness.LiveSet.to_iter
                          (Hashtbl.find_opt live_map node
                          |> Option.get_or ~default:Liveness.LiveSet.empty)
                        |> filter (Hashtbl.find Temp.pointer_map)
                        |> map (Frame.map_temp allocation)
                        (* |> map Temp.make_string *)
                      in
                      let frame_iter =
                        Hashtbl.to_iter (Frame.pointer_map frame)
                        |> filter (fun (_, b) -> b)
                        |> map (fun (local, _) ->
                               Frame.string_of_local allocation local)
                      in
                      let ptrs = append reg_iter frame_iter |> to_list in
                      let n = List.length ptrs in
                      if n > 0 then (
                        let ptrmap_entry = Temp.named_label "ptrmap" in
                        Printf.printf "OK %s\n" (Symbol.name ptrmap_entry);
                        let s =
                          Printf.sprintf "%s:\ndq %s\ndq %s\ndb %d\n%s"
                            (Symbol.name ptrmap_entry)
                            (Symbol.name !last_ptrmap_entry)
                            (Symbol.name ret) n
                            (List.fold_left
                               (fun s p -> Printf.sprintf "db \"%s\"\n" p ^ s)
                               "" ptrs)
                        in
                        ptrmap := s :: !ptrmap;
                        last_ptrmap_entry := ptrmap_entry);
                      (* List.iter (Printf.printf "db \"%s\"\n") ptrs; *)
                      let s = Assem.format (Frame.map_temp allocation) insn in
                      (* let s = Assem.format Temp.make_string insn in *)
                      Printf.fprintf output_channel "%s\n" s
                  | insn ->
                      let s = Assem.format (Frame.map_temp allocation) insn in
                      (* let s = Assem.format Temp.make_string insn in *)
                      if not (String.equal s "") then
                        Printf.fprintf output_channel "%s\n" s)
                insns
            in
            let body = Frame.proc_entry_exit frame insns in
            let insns, allocation, live_map =
              RegAlloc.alloc frame body Frame.calleesaves
              (* RegAlloc.alloc frame body [] *)
            in
            let insns = handle_moves insns allocation frame in
            print_insns insns allocation live_map
            (* Printf.printf "%s:\n" (Symbol.name (Frame.name frame)); *)
            (* Hashtbl.iter *)
            (*   (fun insn live_set -> *)
            (*     (\* Printf.printf "%s\n" *\) *)
            (*     (\*   (Assem.format *\) *)
            (*     (\*      (Frame.map_temp allocation) *\) *)
            (*     (\*      (FGraph.Flowgraph.V.label insn)); *\) *)
            (*     Liveness.LiveSet.iter *)
            (*       (fun t -> *)
            (*         if Hashtbl.find Temp.pointer_map t then *)
            (*           Printf.printf "%s contains a pointer\n" *)
            (*             (Frame.map_temp allocation t)) *)
            (*       live_set) *)
            (*   live_map; *)
            (* Hashtbl.iter *)
            (*   (fun local b -> *)
            (*     if b then Printf.printf "Frame variable contains a pointer\n") *)
            (*   (Frame.pointer_map frame) *)
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
    Printf.fprintf output_channel "ptrmap_root:\n";
    List.iter (Printf.fprintf output_channel "%s") !ptrmap;
    flush output_channel;
    if output_assembly then ()
    else if
      Sys.command ("nasm -felf64 " ^ output_filename ^ " -o " ^ object_file) = 0
    then (
      if
        Sys.command
          (Printf.sprintf
             "gcc -no-pie -Wl,--no-warn-execstack -Wl,--wrap=getchar \
              %s/runtime.o %s"
             runtime_dir object_file)
        <> 0
      then ErrorMsg.impossible "Linking phase failed.")
    else ErrorMsg.impossible "Compiler emitted invalid assembly code.";
    ()
  with
  | ErrorMsg.Error -> exit 1
  | Parser.Error ->
      prerr_endline "Syntax error.";
      exit 1
