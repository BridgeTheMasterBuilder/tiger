open Agnostic
open Frame

type allocation = Frame.register Temp.table

module Colors : Set.S with type elt = Frame.register
module TemporarySet : Set.S with type elt = Temp.t
module MoveSet : Set.S with type elt = FGraph.Flowgraph.vertex

module type S = sig
  type elt
  type t

  val add : elt -> t -> unit
  val choose : t -> elt
  val is_empty : t -> bool
  val mem : elt -> t -> bool
  val remove : elt -> t -> unit
end

module TemporarySetRef :
  S with type elt = TemporarySet.elt and type t = TemporarySet.t ref

type t = {
  interference : Liveness.t;
  initial : TemporarySet.elt list;
  degree : (Liveness.IGraph.vertex, int) Hashtbl.t;
  precolored : allocation;
  spill_cost : Liveness.IGraph.vertex -> int;
  registers : Colors.t;
}

val color_graph : t -> allocation * TemporarySet.t * MoveSet.t
