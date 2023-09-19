open Agnostic
open Containers
module A = Absyn

let lookup_var env depth var =
  Symbol.look env var
  |> Option.map (fun (d, escape) -> if depth > d then escape := true)
  |> ignore

let rec traverse_var env depth = function
  | A.SimpleVar (name, _) -> lookup_var env depth name
  | A.FieldVar (var, _, _) -> traverse_var env depth var
  | A.SubscriptVar (var, exp, _) ->
      traverse_var env depth var;
      traverse_exp env depth exp

and traverse_exp env depth = function
  | A.VarExp var -> traverse_var env depth var
  | A.CallExp { args; _ } ->
      List.iter (fun arg -> traverse_exp env depth arg) args
  | A.OpExp { left; right; _ } ->
      traverse_exp env depth left;
      traverse_exp env depth right
  | A.SeqExp seqs -> List.iter (fun (exp, _) -> traverse_exp env depth exp) seqs
  | A.AssignExp { var; exp; _ } ->
      traverse_var env depth var;
      traverse_exp env depth exp
  | A.IfExp { test; then'; else'; _ } ->
      traverse_exp env depth test;
      traverse_exp env depth then';
      Option.iter (fun exp -> traverse_exp env depth exp) else'
  | A.WhileExp { test; body; _ } ->
      traverse_exp env depth test;
      traverse_exp env depth body
  | A.ForExp { var; escape; lo; hi; body; _ } ->
      let env' =
        escape := false;
        Symbol.enter env var (depth, escape)
      in
      traverse_exp env depth lo;
      traverse_exp env depth hi;
      traverse_exp env' depth body
  | A.LetExp { decs; body; _ } ->
      let env' = traverse_decs env depth decs in
      traverse_exp env' depth body
  | _ -> ()

and traverse_dec env depth = function
  | A.VarDec { name; escape; init; _ } ->
      let env' =
        escape := false;
        Symbol.enter env name (depth, escape)
      in
      traverse_exp env depth init;
      env'
  | A.FunctionDec decs ->
      (* TODO is this correct? *)
      List.iter
        (function
          | A.Fundec { body; params; _ } ->
              let env' =
                List.fold_left
                  (fun env ({ fd_name; escape; _ } : A.field) ->
                    escape := false;
                    Symbol.enter env fd_name (depth + 1, escape))
                  env params
              in
              traverse_exp env' (depth + 1) body)
        decs;
      env
  | _ -> env

and traverse_decs env depth decs =
  List.fold_left (fun env dec -> traverse_dec env depth dec) env decs

let find_escape =
  let env = Symbol.empty () in
  traverse_exp env 0
