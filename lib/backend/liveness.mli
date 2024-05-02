open Agnostic
open Containers
open Graph
module IGraph : Sig.I with type V.label = Temp.t and type V.t = Temp.t
module LiveSet : Set.S with type elt = Temp.t

type live_set = LiveSet.t
type live_map = (FGraph.Flowgraph.vertex, live_set) Hashtbl.t

type t = {
  graph : IGraph.t;
  (* tnode : Temp.t -> IGraph.vertex; *)
  (* gtemp : IGraph.vertex -> Temp.t; *)
  moves : FGraph.Flowgraph.vertex list;
  move_list : (IGraph.vertex, FGraph.Flowgraph.vertex) Hashtbl.t;
  live_map : live_map;
}

module ReferenceMap :
  CCMultiMap.BIDIR with type left = Temp.t and type right = int

val interference_graph : FGraph.t * FGraph.Flowgraph.vertex list -> t
