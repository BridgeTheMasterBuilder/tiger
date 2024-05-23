open Agnostic
open Containers
open Frame
open Util

type allocation = Frame.register Temp.table

module Colors = Set.Make (String)

module TemporarySet = Set.Make (struct
  type t = Temp.t

  let compare = Stdlib.compare
end)

type t = {
  interference : Liveness.t;
  initial : TemporarySet.elt list;
  degree : (Liveness.IGraph.vertex, int) Hashtbl.t;
  precolored : allocation;
  spill_cost : Liveness.IGraph.vertex -> int;
  registers : Colors.t;
}

open Liveness

module MoveSet = Set.Make (struct
  type t = FGraph.Flowgraph.vertex

  let compare a b =
    let extract_text insn =
      match FGraph.Flowgraph.V.label insn with
      | Assem.Label { assem; _ }
      | Assem.Move { assem; _ }
      | Assem.Oper { assem; _ } ->
          assem
    in
    Stdlib.compare (extract_text a) (extract_text b)
end)

module type S = sig
  type elt
  type t

  val add : elt -> t -> unit
  val choose : t -> elt
  val is_empty : t -> bool
  val mem : elt -> t -> bool
  val remove : elt -> t -> unit
end

module SetRef (S : Set.S) : S with type elt = S.elt and type t = S.t ref =
struct
  type elt = S.elt
  type t = S.t ref

  let add x set = set := S.add x !set
  let choose set = S.choose !set
  let is_empty set = S.is_empty !set
  let mem x set = S.mem x !set
  let remove x set = set := S.remove x !set
end

module TemporarySetRef = SetRef (TemporarySet)
module MoveSetRef = SetRef (MoveSet)
module ColorsRef = SetRef (Colors)

let get_move move =
  match FGraph.Flowgraph.V.label move with
  | Assem.Move { src = [ src ]; dst = [ dst ]; _ } -> (dst, src)
  | _ -> ErrorMsg.impossible "Invalid move list"

let color_graph
    { interference; precolored; initial; degree; spill_cost; registers } =
  let igraph = interference.graph in
  let k = Colors.cardinal registers in
  let n = IGraph.nb_vertex igraph in
  let degree_of n = Hashtbl.find degree n in
  let move_list = interference.move_list in
  let alias = Hashtbl.create n in
  let color = Hashtbl.create n in
  let precolored =
    Hashtbl.fold
      (fun k v set ->
        Hashtbl.replace color k v;
        TemporarySet.add k set)
      precolored TemporarySet.empty
  in
  let simplify_worklist = ref TemporarySet.empty in
  let freeze_worklist = ref TemporarySet.empty in
  let spill_worklist = ref TemporarySet.empty in
  let spilled_nodes = ref TemporarySet.empty in
  let coalesced_nodes = ref TemporarySet.empty in
  let coalesced_moves = ref MoveSet.empty in
  let constrained_moves = ref MoveSet.empty in
  let frozen_moves = ref MoveSet.empty in
  let coalesceable_moves = ref (MoveSet.of_list interference.moves) in
  let active_moves = ref MoveSet.empty in
  let select_stack = ref [] in

  let check_invariants () =
    IGraph.iter_vertex
      (fun u ->
        let degree_invariant () =
          if
            TemporarySet.(
              mem u
                (union !simplify_worklist
                   (union !freeze_worklist !spill_worklist)))
          then
            assert (
              degree_of u
              = TemporarySet.(
                  cardinal
                    (inter
                       (of_list (IGraph.pred igraph u @ IGraph.succ igraph u))
                       (union precolored
                          (union !simplify_worklist
                             (union !freeze_worklist !spill_worklist))))))
        in
        let simplify_worklist_invariant () =
          if TemporarySet.mem u !simplify_worklist then
            assert (
              degree_of u < k
              && MoveSet.(
                   is_empty
                     (inter
                        (of_list (Hashtbl.find_all move_list u))
                        (union !active_moves !coalesceable_moves))))
        in
        let freeze_worklist_invariant () =
          if TemporarySet.mem u !freeze_worklist then
            assert (
              degree_of u < k
              && not
                   MoveSet.(
                     is_empty
                       (inter
                          (of_list (Hashtbl.find_all move_list u))
                          (union !active_moves !coalesceable_moves))))
        in
        let spill_worklist_invariant () =
          if TemporarySetRef.mem u spill_worklist then assert (degree_of u >= k)
        in

        degree_invariant ();
        simplify_worklist_invariant ();
        freeze_worklist_invariant ();
        spill_worklist_invariant ())
      igraph
  in
  let node_moves n =
    let move_list = Hashtbl.find_all move_list n |> MoveSet.of_list in
    MoveSet.inter move_list (MoveSet.union !active_moves !coalesceable_moves)
  in
  let move_related n = not (MoveSet.is_empty (node_moves n)) in
  let make_worklist initial =
    List.iter
      (fun t ->
        if degree_of t >= k then TemporarySetRef.add t spill_worklist
        else if move_related t then TemporarySetRef.add t freeze_worklist
        else TemporarySetRef.add t simplify_worklist)
      initial
  in

  let adjacent n =
    let adj = TemporarySet.of_list (IGraph.succ igraph n) in
    let select_stack = TemporarySet.of_list !select_stack in
    TemporarySet.(diff adj (union select_stack !coalesced_nodes))
  in
  let enable_moves nodes =
    TemporarySet.iter
      (fun n ->
        MoveSet.iter
          (fun m ->
            if MoveSet.mem m !active_moves then (
              MoveSetRef.remove m active_moves;
              MoveSetRef.add m coalesceable_moves))
          (node_moves n))
      nodes
  in
  let decrement_degree m =
    let d = degree_of m in
    Hashtbl.replace degree m (d - 1);
    if d = k then (
      enable_moves (TemporarySet.add m (adjacent m));
      TemporarySetRef.remove m spill_worklist;
      if move_related m then TemporarySetRef.add m freeze_worklist
      else TemporarySetRef.add m simplify_worklist)
  in

  let simplify () =
    let n = TemporarySetRef.choose simplify_worklist in
    TemporarySetRef.remove n simplify_worklist;
    ListRef.push n select_stack;
    TemporarySet.iter (fun m -> decrement_degree m) (adjacent n)
  in
  let rec get_alias n =
    if TemporarySet.mem n !coalesced_nodes then get_alias (Hashtbl.find alias n)
    else n
  in
  let assign_colors () =
    List.iter
      (fun n ->
        (* TODO separate the precolored nodes so they are never even considered *)
        if not (Hashtbl.mem color n) then (
          let ok_colors = ref registers in
          List.iter
            (fun w ->
              if Hashtbl.mem color (get_alias w) then
                ColorsRef.remove (Hashtbl.find color (get_alias w)) ok_colors)
            (IGraph.succ igraph n);
          if ColorsRef.is_empty ok_colors then
            TemporarySetRef.add n spilled_nodes
          else
            let c = ColorsRef.choose ok_colors in
            Hashtbl.replace color n c))
      !select_stack;
    TemporarySet.iter
      (fun n ->
        (* TODO bandaid? *)
        if Hashtbl.mem color (get_alias n) then
          Hashtbl.replace color n (Hashtbl.find color (get_alias n)))
      !coalesced_nodes
  in
  let add_worklist u =
    if
      (not (TemporarySet.mem u precolored))
      && (not (move_related u))
      && degree_of u < k
    then (
      TemporarySetRef.remove u freeze_worklist;
      TemporarySetRef.add u simplify_worklist)
  in
  let ok t r =
    degree_of t < k
    || TemporarySet.mem t precolored
    || IGraph.mem_edge igraph t r
  in
  let conservative nodes =
    let count =
      TemporarySet.fold
        (fun n j -> if degree_of n >= k then j + 1 else j)
        nodes 0
    in
    count < k
  in
  let combine u v =
    if TemporarySetRef.mem v freeze_worklist then
      TemporarySetRef.remove v freeze_worklist
    else TemporarySetRef.remove v spill_worklist;
    TemporarySetRef.add v coalesced_nodes;
    Hashtbl.replace alias v u;
    let v_moves = Hashtbl.find_all move_list v in
    List.iter (fun move -> Hashtbl.add move_list u move) v_moves;
    TemporarySet.iter
      (fun t ->
        IGraph.add_edge igraph t u;
        decrement_degree t)
      (adjacent v);
    if degree_of u >= k && TemporarySetRef.mem u freeze_worklist then (
      TemporarySetRef.remove u freeze_worklist;
      TemporarySetRef.add u spill_worklist)
  in
  let coalesce () =
    let m = MoveSetRef.choose coalesceable_moves in
    let x, y = get_move m in
    let x = get_alias x in
    let y = get_alias y in
    let u, v = if TemporarySet.mem y precolored then (y, x) else (x, y) in
    MoveSetRef.remove m coalesceable_moves;
    if Temp.equal u v then (
      MoveSetRef.add m coalesced_moves;
      add_worklist u)
    else if TemporarySet.mem v precolored || IGraph.mem_edge igraph u v then (
      MoveSetRef.add m constrained_moves;
      add_worklist u;
      add_worklist v)
    else if
      TemporarySet.mem u precolored
      && TemporarySet.for_all (fun t -> ok t u) (adjacent v)
      || (not (TemporarySet.mem u precolored))
         && conservative (TemporarySet.union (adjacent u) (adjacent v))
    then (
      MoveSetRef.add m coalesced_moves;
      combine u v;
      add_worklist u)
    else MoveSetRef.add m active_moves
  in
  let freeze_moves u =
    MoveSet.iter
      (fun m ->
        let x, y = get_move m in

        let v =
          if Temp.equal (get_alias y) (get_alias u) then get_alias x
          else get_alias y
        in
        MoveSetRef.remove m active_moves;
        MoveSetRef.add m frozen_moves;
        if MoveSet.is_empty (node_moves v) && degree_of v < k then (
          TemporarySetRef.remove v freeze_worklist;
          TemporarySetRef.add v simplify_worklist))
      (node_moves u)
  in
  let freeze () =
    let u = TemporarySetRef.choose freeze_worklist in
    TemporarySetRef.remove u freeze_worklist;
    TemporarySetRef.add u simplify_worklist;
    freeze_moves u
  in
  let select_spill () =
    (* TODO heuristic *)
    let m = TemporarySetRef.choose spill_worklist in
    TemporarySetRef.remove m spill_worklist;
    TemporarySetRef.add m simplify_worklist;
    freeze_moves m
  in
  check_invariants ();
  make_worklist initial;
  let rec aux () =
    if not (TemporarySetRef.is_empty simplify_worklist) then simplify ()
    else if not (MoveSetRef.is_empty coalesceable_moves) then coalesce ()
    else if not (TemporarySetRef.is_empty freeze_worklist) then freeze ()
    else if not (TemporarySetRef.is_empty spill_worklist) then select_spill ();
    if
      not
        (TemporarySetRef.is_empty simplify_worklist
        && MoveSetRef.is_empty coalesceable_moves
        && TemporarySetRef.is_empty freeze_worklist
        && TemporarySetRef.is_empty spill_worklist)
    then aux ()
  in
  aux ();
  assign_colors ();
  (color, !spilled_nodes, !coalesced_moves)
