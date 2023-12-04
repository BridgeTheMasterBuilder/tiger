open Agnostic
open Containers
open Util
open FGraph
module F = Flowgraph
open Graph

module IGraph = Imperative.Graph.Concrete (struct
  type t = Temp.t

  let hash = Temp.to_int
  let compare a b = Stdlib.compare (hash a) (hash b)
  let equal a b = hash a = hash b
end)

module LivenessCalculator = Traverse.Dfs (F)

type t = {
  graph : IGraph.t;
  moves : F.vertex list;
  move_list : (IGraph.vertex, F.vertex) Hashtbl.t;
}

module LiveSet = Set.Make (Temp)

type liveSet = LiveSet.t
type liveMap = (F.vertex, liveSet) Hashtbl.t

module ReferenceMap = CCMultiMap.MakeBidir (Temp) (Int)

let compute_liveness flowgraph nodes =
  let changed = ref false in
  let moves = ref [] in
  let n = List.length nodes in
  let move_list = Hashtbl.create n in
  let rec aux live_in live_out =
    let live_in' = Hashtbl.copy live_in in
    let live_out' = Hashtbl.copy live_out in
    LivenessCalculator.postfix
      (fun insn ->
        let use, def =
          match F.V.label insn with
          | Assem.Move { assem; src = [ src ]; dst = [ dst ]; _ } ->
              (* We only consider move instructions of the form t_i <- t_j,
                 not those with memory operands and arbitrary addressing modes *)
              (* TODO this isn't portable, maybe add a predicate to Assem *)
              if not (String.contains assem '[') then (
                ListRef.push insn moves;
                let dst_node = IGraph.V.create dst in
                Hashtbl.add move_list dst_node insn;
                let src_node = IGraph.V.create src in
                Hashtbl.add move_list src_node insn);
              ([ src ], [ dst ])
          | Assem.Oper { src; dst; _ } | Assem.Move { src; dst; _ } -> (src, dst)
          | _ -> ([], [])
        in
        let live_out_set =
          F.fold_succ
            (fun s live_out_set ->
              Hashtbl.find_opt live_in s
              |> Option.map_or ~default:live_out_set
                   (fun successor_live_in_set ->
                     LiveSet.fold
                       (fun k live_out_set -> LiveSet.add k live_out_set)
                       live_out_set successor_live_in_set))
            flowgraph insn LiveSet.empty
        in
        Hashtbl.find_opt live_out' insn
        |> Option.iter (fun old_live_out_set ->
               changed := LiveSet.compare old_live_out_set live_out_set = 0);
        Hashtbl.replace live_out insn live_out_set;
        let live_in_set =
          List.fold_left
            (fun live_in_set t -> LiveSet.add t live_in_set)
            LiveSet.empty use
          |> LiveSet.fold
               (fun k live_in_set ->
                 if not (List.mem k def) then LiveSet.add k live_in_set
                 else live_in_set)
               (Hashtbl.find live_out insn)
        in
        Hashtbl.find_opt live_in' insn
        |> Option.iter (fun old_live_in_set ->
               changed := LiveSet.compare old_live_in_set live_in_set = 0);
        Hashtbl.replace live_in insn live_in_set)
      flowgraph;
    if !changed then (!moves, move_list, live_out) else aux live_in live_out
  in
  let n = List.length nodes in
  let live_in = Hashtbl.create n in
  let live_out = Hashtbl.create n in
  aux live_in live_out

let interference_graph (({ control = flowgraph; _ } : FGraph.t), nodes) =
  let moves, move_list, live_map = compute_liveness flowgraph nodes in
  let graph = IGraph.create () in
  List.iter
    (fun node ->
      let def =
        match F.V.label node with
        | Assem.Move { dst; _ } | Assem.Oper { dst; _ } -> dst
        | _ -> []
      in
      Hashtbl.find_opt live_map node
      |> Option.iter (fun ts ->
             List.iter
               (fun d ->
                 let node_d = IGraph.V.create d in
                 IGraph.add_vertex graph node_d;
                 LiveSet.iter
                   (fun t ->
                     let node_t = IGraph.V.create t in
                     IGraph.add_vertex graph node_t;
                     if not (Temp.equal d t) then
                       IGraph.add_edge graph node_d node_t)
                   ts)
               def))
    nodes;

  { graph; moves; move_list }
