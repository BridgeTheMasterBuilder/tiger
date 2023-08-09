open Agnostic
open Containers
open Graph
open Frame

module GraphPrinter (G : sig
  include Sig.G

  val digraph : bool
  val unique : bool
  val node_printer : V.t -> string
end) =
struct
  let print graph file =
    let table = Hashtbl.create (G.nb_vertex graph) in
    Printf.fprintf file
      (if G.digraph then "digraph {\n" else "strict graph {\n");
    G.iter_vertex
      (fun node ->
        let id =
          if G.unique then Symbol.name (Temp.new_label ())
          else G.node_printer node
        in
        Hashtbl.add table node id;
        Printf.fprintf file "\t%s [label=\"%s\"]\n" id (G.node_printer node))
      graph;
    G.iter_edges
      (fun a b ->
        let id_a = Hashtbl.find table a in
        let id_b = Hashtbl.find table b in
        Printf.fprintf file
          (if G.digraph then "\t%s -> %s\n" else "\t%s -- %s\n")
          id_a id_b)
      graph;
    Printf.fprintf file "}\n";
    flush file
end

module FGraphPrinter = GraphPrinter (struct
  include FGraph.Flowgraph

  let digraph = true
  let unique = true

  let node_printer node =
    Assem.format (Frame.map_temp Frame.temp_map) (V.label node)
end)

module IGraphPrinter = GraphPrinter (struct
  include Liveness.IGraph

  let digraph = false
  let unique = false
  let node_printer node = Frame.map_temp Frame.temp_map (V.label node)
end)
