open Agnostic
open Containers
open Frame
open Color
open Liveness
open Codegen

type allocation = Frame.register Temp.table

module IntSet = Set.Make (Int)

let update_references temp reg = function
  | Assem.Move { assem; src; dst; _ } ->
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
          | Assem.Move { src; dst; _ } -> (src, dst)
          | Assem.Oper { src; dst; _ } -> (src, dst)
          | _ -> ([], [])
        in
        (* TODO extract to function *)
        let spills, saved_temp =
          match (List.mem t src, List.mem t dst) with
          | true, true ->
              let fetch, temp =
                let temp = Temp.newtemp () in
                let move = Tree.(Move (Temp temp, local)) |> Codegen.codegen in
                let insn = update_references t temp insn in
                (insn :: move, temp)
              in
              let store = Tree.(Move (local, Temp temp)) |> Codegen.codegen in
              (store @ fetch, None)
          | true, false ->
              let temp = Temp.newtemp () in
              let move = Tree.(Move (Temp temp, local)) |> Codegen.codegen in
              let insn = update_references t temp insn in
              (insn :: move, Some temp)
          | false, true ->
              let fetch =
                match saved_temp with
                | None ->
                    let temp = Temp.newtemp () in
                    let insn = update_references t temp insn in
                    let move =
                      Tree.(Move (local, Temp temp)) |> Codegen.codegen
                    in
                    move @ [ insn ]
                | Some temp ->
                    let insn = update_references t temp insn in
                    let move =
                      Tree.(Move (local, Temp temp)) |> Codegen.codegen
                    in
                    move @ [ insn ]
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
        Frame.alloc_local frame true |> Frame.exp (Tree.Temp Frame.fp)
      in
      aux 0 local body prologue [] epilogue sink None

let rewrite_program available_regs frame (body : Frame.body) spilled_nodes
    coalesced_moves =
  (* print_endline "can delete the following moves:"; *)
  (* MoveSet.iter *)
  (*   (fun m -> *)
  (*     print_endline *)
  (*       (Assem.format *)
  (*          (Frame.map_temp Frame.temp_map) *)
  (*          (FGraph.Flowgraph.V.label m))) *)
  (*   coalesced_moves; *)
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
      rewrite_program available_regs frame procedure_body spills coalesced_moves
    in
    alloc frame body available_regs
  else (insns, allocation)
