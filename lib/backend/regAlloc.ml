open Agnostic
open Containers
open Frame
open Color
open Liveness
open Codegen

type allocation = Frame.register Temp.table

module IntSet = Set.Make (Int)

let update_references temp reg = function
  | Assem.Move { assem; src; dst; _ }
  | Assem.Call { assem; src; dst; _ } (* TODO ? *) ->
      let src = List.map (fun t -> if Temp.equal temp t then reg else t) src in
      let dst = List.map (fun t -> if Temp.equal temp t then reg else t) dst in
      Assem.Move { assem; src; dst }
  | Assem.Oper { assem; src; dst; jump } ->
      let src = List.map (fun t -> if Temp.equal temp t then reg else t) src in
      let dst = List.map (fun t -> if Temp.equal temp t then reg else t) dst in
      Assem.Oper { assem; src; dst; jump }
  | _ -> ErrorMsg.impossible "There's a bug in the Ocaml compiler"

let spill_temporary t frame ({ prologue; body; epilogue; sink } : Frame.body)
    available_regs =
  let rec aux i local insns prologue body epilogue sink saved_temp =
    match insns with
    | insn :: insns ->
        let src, dst =
          match insn with
          | Assem.Move { src; dst; _ }
          | Assem.Oper { src; dst; _ }
          | Assem.Call { src; dst; _ } ->
              (src, dst)
          | _ -> ([], [])
        in
        (* TODO extract to function *)
        let spills, saved_temp =
          match (List.mem t src, List.mem t dst) with
          | true, true ->
              let fetch, temp =
                (* TODO May be pointer, note in frame *)
                let temp = Temp.newtemp () in
                (* let move = Tree.(Move (Temp temp, local)) |> Codegen.codegen in *)
                let move1 =
                  Tree.(Move (Temp t, Frame.exp (Tree.Temp Frame.fp) local))
                  |> Codegen.codegen
                in
                let move2 =
                  Tree.(Move (Temp temp, Temp t)) |> Codegen.codegen
                in
                let insn = update_references t temp insn in
                Hashtbl.replace Temp.pointer_map temp
                  (Hashtbl.find Temp.pointer_map t);
                (* (insn :: move, temp) *)
                ((insn :: move2) @ move1, temp)
              in
              let store =
                Tree.(Move (Frame.exp (Tree.Temp Frame.fp) local, Temp temp))
                |> Codegen.codegen
              in
              Hashtbl.replace (Frame.pointer_map frame) local
                (Hashtbl.find Temp.pointer_map temp);
              (store @ fetch, None)
          | true, false ->
              (* TODO May be pointer, note in frame *)
              let temp = Temp.newtemp () in
              (* let move = Tree.(Move (Temp temp, local)) |> Codegen.codegen in *)
              let move1 =
                Tree.(Move (Temp t, Frame.exp (Tree.Temp Frame.fp) local))
                |> Codegen.codegen
              in
              let move2 = Tree.(Move (Temp temp, Temp t)) |> Codegen.codegen in
              let insn = update_references t temp insn in
              Hashtbl.replace Temp.pointer_map temp
                (Hashtbl.find Temp.pointer_map t);
              (* (insn :: move, Some temp) *)
              ((insn :: move2) @ move1, Some temp)
          | false, true ->
              let fetch =
                match saved_temp with
                | None ->
                    (* TODO May be pointer, note in frame *)
                    let temp = Temp.newtemp () in
                    let insn = update_references t temp insn in
                    (* let move = *)
                    (*   Tree.(Move (local, Temp temp)) |> Codegen.codegen *)
                    (* in *)
                    let move1 =
                      Tree.(Move (Temp temp, Temp t)) |> Codegen.codegen
                    in
                    let move2 =
                      Tree.(
                        Move (Frame.exp (Tree.Temp Frame.fp) local, Temp temp))
                      |> Codegen.codegen
                    in
                    Hashtbl.replace Temp.pointer_map temp
                      (Hashtbl.find Temp.pointer_map t);
                    Hashtbl.replace (Frame.pointer_map frame) local
                      (Hashtbl.find Temp.pointer_map temp);
                    (* move @ [ insn ] *)
                    move1 @ move2 @ [ insn ]
                | Some temp ->
                    (* TODO May be pointer, note in frame *)
                    let insn = update_references t temp insn in
                    let move =
                      Tree.(
                        Move (Frame.exp (Tree.Temp Frame.fp) local, Temp temp))
                      |> Codegen.codegen
                    in
                    Hashtbl.replace (Frame.pointer_map frame) local
                      (Hashtbl.find Temp.pointer_map temp);
                    (* let move1 = *)
                    (*   Tree.(Move (Temp temp, Temp t)) |> Codegen.codegen *)
                    (* in *)
                    (* let move2 = *)
                    (*   Tree.(Move (local, Temp temp)) |> Codegen.codegen *)
                    (* in *)
                    (* Hashtbl.replace Temp.pointer_map temp *)
                    (*   (Hashtbl.find Temp.pointer_map t); *)
                    move @ [ insn ]
                (* move1 @ move2 @ [ insn ] *)
              in
              (fetch, None)
          | false, false -> ([ insn ], saved_temp)
        in
        aux (i + 1) local insns prologue (spills @ body) epilogue sink
          saved_temp
    | [] ->
        ( ({ prologue; body = List.rev body; epilogue; sink } : Frame.body),
          available_regs )
  in
  (* TODO just let the compiler use whatever register it wants and use the allocation table afterwards to figure out which registers to save *)
  match available_regs with
  | reg :: regs ->
      let src =
        match sink with
        | Assem.Oper { assem = ""; src; _ } -> src
        | _ -> ErrorMsg.impossible "Invalid sink instruction"
      in
      let protected_regs =
        TemporarySet.(of_list src |> remove reg |> elements)
      in
      let rewritten_sink =
        Assem.Oper { assem = ""; src = protected_regs; dst = []; jump = None }
      in
      Frame.save_register frame reg;
      (({ prologue; body; epilogue; sink = rewritten_sink } : Frame.body), regs)
  | [] ->
      let local =
        (* Frame.alloc_local frame true |> Frame.exp (Tree.Temp Frame.fp) *)
        Frame.alloc_local frame true
      in
      aux 0 local body prologue [] epilogue sink None

let rewrite_program available_regs frame (body : Frame.body) spilled_nodes =
  TemporarySet.fold
    (fun t (body, available_regs) ->
      spill_temporary t frame body available_regs)
    spilled_nodes (body, available_regs)

let rec alloc frame procedure_body available_regs =
  let ({ body; sink; _ } : Frame.body) = procedure_body in
  let ({ prologue; epilogue; _ } : Frame.body) =
    Frame.proc_entry_exit frame body
  in
  let insns = prologue @ body @ [ sink ] @ epilogue in
  let flowgraph, nodes = FGraph.make insns in
  let interference = Liveness.interference_graph (flowgraph, nodes) in
  let igraph = interference.graph in
  let allocation, spills, coalesced_moves =
    let precolored = Frame.temp_map in
    let degree = Hashtbl.create (List.length nodes) in
    let initial =
      Liveness.IGraph.fold_vertex
        (fun node initial ->
          Hashtbl.replace degree node (Liveness.IGraph.out_degree igraph node);
          if not (Hashtbl.mem precolored node) then node :: initial else initial)
        igraph []
    in
    color_graph
      {
        interference;
        precolored;
        initial;
        degree;
        (* TODO *)
        spill_cost = (fun _ -> 1);
        registers = Color.Colors.of_list Frame.registers;
      }
  in
  if not (TemporarySet.is_empty spills) then
    let body, available_regs =
      rewrite_program available_regs frame procedure_body spills
    in
    alloc frame body available_regs
  else
    let nodes =
      MoveSet.fold
        (fun m nodes ->
          List.remove
            ~eq:(fun insn1 insn2 ->
              match
                (FGraph.Flowgraph.V.label insn1, FGraph.Flowgraph.V.label insn2)
              with
              | ( Assem.Move { src = [ src1 ]; dst = [ dst1 ]; _ },
                  Assem.Move { src = [ src2 ]; dst = [ dst2 ]; _ } ) ->
                  Temp.equal src1 src2 && Temp.equal dst1 dst2
              | _ -> false)
            ~key:m nodes)
        coalesced_moves nodes
    in
    (List.map FGraph.Flowgraph.V.label nodes, allocation, interference.live_map)
