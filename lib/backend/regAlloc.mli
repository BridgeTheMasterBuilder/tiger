open Agnostic
open Frame

type allocation = Frame.register Temp.table

val alloc :
  Frame.t ->
  Frame.body ->
  Temp.t list ->
  (* Assem.insn list * allocation * Liveness.live_map *)
  FGraph.Flowgraph.vertex list * allocation * Liveness.live_map
