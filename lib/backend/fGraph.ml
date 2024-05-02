open Agnostic
open Containers
open Graph

module Flowgraph = Imperative.Digraph.Abstract (struct
  type t = Assem.insn
end)

module F = Flowgraph

type t = {
  control : F.t;
  def : (F.vertex, Temp.t list) Hashtbl.t;
  use : (F.vertex, Temp.t list) Hashtbl.t;
}

let create size =
  {
    control = F.create ~size ();
    def = Hashtbl.create size;
    use = Hashtbl.create size;
  }

let make insns =
  let n = List.length insns in
  let flowgraph = create n in
  let labels = Hashtbl.create n in
  let node_of_insn = function
    | Assem.Label { lab; _ } as insn ->
        let node = F.V.create insn in
        Fun.tap (Hashtbl.add labels lab) node
    | insn -> F.V.create insn
  in
  (* let nodes = *)
  (*   List.to_seq insns |> Seq.map node_of_insn *)
  (*   |> Fun.tap (Seq.iter (F.add_vertex flowgraph.control)) *)
  (*   |> List.of_seq *)
  (* in *)
  let nodes =
    Iter.(
      map node_of_insn (of_list insns)
      |> Fun.tap (iter (F.add_vertex flowgraph.control))
      |> to_list)
    |> List.to_seq
  in
  (* let nodes = List.to_seq nodes in *)
  let shifted_nodes =
    Seq.map Option.some nodes |> Seq.drop 1 |> fun shifted_nodes ->
    Seq.append shifted_nodes (Seq.return None)
  in
  (* let shifted_nodes = Iter.(map Option.some nodes |> drop 1 |> snoc None) in *)
  Seq.(
    iter2
      (fun src_node next ->
        try
          let next, def, use =
            match F.V.label src_node with
            | Assem.Move { src; dst; _ }
            | Assem.Oper { jump = None; src; dst; _ } ->
                (next, dst, src)
            | Assem.Oper { jump = Some [ lab ]; src; dst; _ } ->
                let next = Hashtbl.find labels lab in
                (Some next, dst, src)
            | Assem.Oper { jump = Some [ t; f ]; src; dst; _ } ->
                let next = Hashtbl.find labels t in
                let dst_node = next in
                F.add_edge flowgraph.control src_node dst_node;
                let next = Hashtbl.find labels f in
                (Some next, dst, src)
            | Assem.Call { src; dst; _ } -> (next, dst, src)
            | Assem.Label _ -> (next, [], [])
            | _ -> ErrorMsg.impossible "Couldn't construct control flow graph"
          in
          Hashtbl.add flowgraph.use src_node use;
          Hashtbl.add flowgraph.def src_node def;
          Option.iter
            (fun next ->
              let dst_node = next in
              F.add_edge flowgraph.control src_node dst_node)
            next
        with Not_found ->
          ErrorMsg.impossible
            "Couldn't construct control flow graph due to unknown label")
      nodes shifted_nodes);
  (flowgraph, List.of_seq nodes)
