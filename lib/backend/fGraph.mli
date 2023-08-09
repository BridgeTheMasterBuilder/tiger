open Agnostic
open Graph
module Flowgraph : Sig.I with type V.label = Assem.insn

type t = {
  control : Flowgraph.t;
  def : (Flowgraph.vertex, Temp.t list) Hashtbl.t;
  use : (Flowgraph.vertex, Temp.t list) Hashtbl.t;
}

val make : Assem.insn list -> t * Flowgraph.vertex list
