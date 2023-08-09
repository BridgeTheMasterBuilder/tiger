open Agnostic
open Containers
open Graph

type venv = Env.enventry Symbol.table
type tenv = Types.ty Symbol.table
type expty = { exp : Translate.exp; ty : Types.ty }
type tables = venv * tenv * Translate.exp list

module A = Absyn

module TypeGraph = Imperative.Digraph.Abstract (struct
  type t = string
end)

module CycleChecker = Traverse.Dfs (TypeGraph)

let in_loop = ref false

let lookup env name pos format_string =
  match Symbol.look env name with
  | Some res -> res
  | None -> ErrorMsg.fatal_error pos format_string (Symbol.name name)

let lookup_type tenv name pos = lookup tenv name pos "Unknown type %s"

let lookup_name tenv ty pos =
  match ty with Types.Name (name, _) -> lookup_type tenv name pos | _ -> ty

let lookup_var venv name pos = lookup venv name pos "Undeclared identifier %s"

let rec types_equal tenv ty1 ty2 pos =
  match (ty1, ty2) with
  | Types.Record (_, id1), Types.Record (_, id2) -> Equal.physical id1 id2
  | Types.Record _, Types.Nil -> true
  | Types.Nil, Types.Record _ -> true
  | Types.Array (_, id1), Types.Array (_, id2) -> Equal.physical id1 id2
  | Types.Name (name, _), ty2 ->
      let ty1 = lookup_type tenv name pos in
      types_equal tenv ty1 ty2 pos
  | ty1, Types.Name (name, _) ->
      let ty2 = lookup_type tenv name pos in
      types_equal tenv ty1 ty2 pos
  | ty1, ty2 -> Equal.poly ty1 ty2

let types_inequal tenv ty1 ty2 pos = types_equal tenv ty1 ty2 pos |> not

let check_type { ty; _ } typ pos msg =
  if not (Equal.poly ty typ) then ErrorMsg.fatal_error pos msg

let check_int exp pos = check_type exp Types.Int pos "Expected integer"
let check_string exp pos = check_type exp Types.String pos "Expected string"

let check_record exp id1 pos =
  match exp.ty with
  | Types.Record (_, id2) ->
      if not (Equal.physical id1 id2) then
        ErrorMsg.fatal_error pos "Record types don't match"
  | Types.Nil -> ()
  | _ -> ErrorMsg.fatal_error pos "Expected record type"

let check_array exp id1 pos =
  match exp.ty with
  | Types.Array (_, id2) ->
      if not (Equal.physical id1 id2) then
        ErrorMsg.fatal_error pos "Array types don't match"
  | _ -> ErrorMsg.fatal_error pos "Expected array type"

let rec trans_exp venv tenv level break =
  let rec trexp break = function
    | A.VarExp var -> trvar var
    | A.NilExp -> { exp = Translate.nil_exp (); ty = Types.Nil }
    | A.IntExp i -> { exp = Translate.int_exp i; ty = Types.Int }
    | A.StringExp (s, _) -> { exp = Translate.string_exp s; ty = Types.String }
    | A.CallExp { func; args; pos } ->
        let formals, result, level_f, label =
          match lookup_var venv func pos with
          | Env.FunEntry { formals; result; level; label } ->
              (formals, result, level, label)
          | _ ->
              ErrorMsg.fatal_error pos "%s is not a function" (Symbol.name func)
        in
        let num_params = List.length formals in
        let num_args = List.length args in
        if num_params <> num_args then
          ErrorMsg.fatal_error pos
            "Insufficient arguments given to function %s, expected %d but got \
             %d"
            (Symbol.name func) num_params num_args;
        let args =
          List.map2
            (fun param arg ->
              let { exp; ty } = trexp break arg in
              if types_inequal tenv param ty pos then
                ErrorMsg.fatal_error pos
                  "Type %s of argument does not match declared type %s of \
                   parameter"
                  (Types.string_of_ty ty) (Types.string_of_ty param);
              exp)
            formals args
        in
        let formals = Translate.formals level_f in
        {
          exp =
            (if Option.is_some (Symbol.look Env.base_venv label) then
               Translate.external_call (Symbol.name label) args
             else Translate.call_exp label formals args level level_f);
          ty = result;
        }
    | A.OpExp { left; oper; right; pos } -> (
        match oper with
        | A.PlusOp | A.MinusOp | A.TimesOp | A.DivideOp ->
            let left = trexp break left in
            let right = trexp break right in
            check_int left pos;
            check_int right pos;
            {
              exp = Translate.arith_exp oper left.exp right.exp;
              ty = Types.Int;
            }
        | A.EqOp | A.NeqOp ->
            let left = trexp break left in
            let right = trexp break right in
            (match left.ty with
            | Types.Int -> check_int right pos
            | Types.String -> check_string right pos
            | Types.Array (_, id) -> check_array right id pos
            | Types.Record (_, id) -> check_record right id pos
            | Types.Nil -> check_record right (ref ()) pos
            | _ ->
                ErrorMsg.fatal_error pos "Can't compare %s with %s for equality"
                  (Types.string_of_ty left.ty)
                  (Types.string_of_ty right.ty));
            let exp =
              match left.ty with
              | Types.Int | Types.Array _ | Types.Record _ | Types.Nil ->
                  Translate.cond_exp oper left.exp right.exp
              | Types.String -> Translate.str_cond_exp oper left.exp right.exp
              | _ -> ErrorMsg.fatal_error pos "Unreachable"
            in
            { exp; ty = Types.Int }
        | A.GtOp | A.LtOp | A.GeOp | A.LeOp ->
            let left = trexp break left in
            let right = trexp break right in
            (match left.ty with
            | Types.Int -> check_int right pos
            | Types.String -> check_string right pos
            | _ ->
                if not (types_inequal tenv left.ty right.ty pos) then
                  ErrorMsg.fatal_error pos
                    "Type %s does not have a defined ordering"
                    (Types.string_of_ty left.ty)
                else
                  ErrorMsg.fatal_error pos "Can't compare %s with %s"
                    (Types.string_of_ty left.ty)
                    (Types.string_of_ty right.ty));
            let exp =
              match left.ty with
              | Types.Int -> Translate.cond_exp oper left.exp right.exp
              | Types.String -> Translate.str_cond_exp oper left.exp right.exp
              | _ -> ErrorMsg.fatal_error pos "Unreachable"
            in
            { exp; ty = Types.Int })
    | A.RecordExp { fields; typ; pos } -> (
        let ty = lookup_type tenv typ pos in
        match ty with
        | Types.Record (record_fields, _) ->
            let fields =
              List.mapi (fun i (field, exp, pos) -> (i, field, exp, pos)) fields
            in
            let sorted_fields1 =
              List.sort
                (fun (field1, _) (field2, _) ->
                  String.compare (Symbol.name field1) (Symbol.name field2))
                record_fields
            in
            let sorted_fields2 =
              List.sort
                (fun (_, field1, _, _) (_, field2, _, _) ->
                  String.compare (Symbol.name field1) (Symbol.name field2))
                fields
            in
            let exps =
              List.map2
                (fun (field1, ty1) (i, field2, exp, pos) ->
                  let field1 = Symbol.name field1 in
                  let field2 = Symbol.name field2 in
                  if not (String.equal field1 field2) then
                    ErrorMsg.fatal_error pos "Record fields don't match";
                  let { exp; ty } = trexp break exp in
                  if types_inequal tenv ty1 ty pos then
                    ErrorMsg.fatal_error pos
                      "Record field \"%s\" types differ - %s <> %s" field1
                      (Types.string_of_ty ty1) (Types.string_of_ty ty);
                  (i, exp))
                sorted_fields1 sorted_fields2
            in
            let exps =
              Iter.(
                sort
                  ~cmp:(fun (i, _) (j, _) -> Stdlib.compare i j)
                  (of_list exps)
                |> map snd |> to_list)
            in
            { exp = Translate.record_exp exps; ty }
        | _ ->
            ErrorMsg.fatal_error pos "%s is not a record type" (Symbol.name typ)
        )
    | A.SeqExp seqs ->
        let typ = ref Types.Unit in
        let seqs =
          List.map
            (fun (exp, _) ->
              let { exp; ty } = trexp break exp in
              typ := ty;
              exp)
            seqs
        in
        { exp = Translate.seq_exp seqs; ty = !typ }
    | A.AssignExp { var; exp; pos } ->
        let lvalue = trvar var in
        let exp = trexp break exp in
        if types_inequal tenv lvalue.ty exp.ty pos then
          ErrorMsg.fatal_error pos
            "Assigning value of type %s to a variable of type %s"
            (Types.string_of_ty lvalue.ty)
            (Types.string_of_ty exp.ty);
        { exp = Translate.assign_exp lvalue.exp exp.exp; ty = Types.Unit }
    | A.IfExp { test; then'; else'; pos } -> (
        let test = trexp break test in
        check_int test pos;
        let then' = trexp break then' in
        match else' with
        | Some exp ->
            let else' = trexp break exp in
            if types_inequal tenv then'.ty else'.ty pos then
              ErrorMsg.fatal_error pos "If arms have different types";
            {
              exp = Translate.if_exp test.exp then'.exp (Some else'.exp);
              ty = then'.ty;
            }
        | None ->
            if types_inequal tenv then'.ty Types.Unit pos then
              ErrorMsg.fatal_error pos "If-then returns non-unit";
            { exp = Translate.if_exp test.exp then'.exp None; ty = Types.Unit })
    | A.WhileExp { test; body; pos } ->
        let currently_in_loop = !in_loop in
        in_loop := true;

        let test = trexp break test in
        check_int test pos;
        let done_label = Temp.new_label () in
        let { exp; ty } = trexp done_label body in
        if types_inequal tenv ty Types.Unit pos then
          ErrorMsg.fatal_error pos "Body of while loop must produce no value";
        in_loop := currently_in_loop;

        { exp = Translate.while_exp test.exp exp done_label; ty = Types.Unit }
    | A.ForExp { var; lo; hi; body; pos; escape } ->
        let loop =
          A.LetExp
            {
              decs =
                [
                  VarDec
                    {
                      name = var;
                      escape;
                      typ = Some (Symbol.symbol "int", pos);
                      init = lo;
                      pos;
                    };
                  VarDec
                    {
                      name = Symbol.symbol "limit";
                      escape = ref true;
                      typ = Some (Symbol.symbol "int", pos);
                      init = hi;
                      pos;
                    };
                ];
              body =
                A.WhileExp
                  {
                    test =
                      A.OpExp
                        {
                          left = A.VarExp (A.SimpleVar (var, pos));
                          oper = A.LeOp;
                          right =
                            A.VarExp (A.SimpleVar (Symbol.symbol "limit", pos));
                          pos;
                        };
                    body =
                      A.SeqExp
                        [
                          (body, pos);
                          ( A.AssignExp
                              {
                                var = A.SimpleVar (var, pos);
                                exp =
                                  A.OpExp
                                    {
                                      left = A.VarExp (A.SimpleVar (var, pos));
                                      oper = A.PlusOp;
                                      right = A.IntExp 1;
                                      pos;
                                    };
                                pos;
                              },
                            pos );
                        ];
                    pos;
                  };
              pos;
            }
        in
        let result = trans_exp venv tenv level break loop in
        if types_inequal tenv result.ty Types.Unit pos then
          ErrorMsg.fatal_error pos "The body of for loops must produce no value"
        else result
    | A.BreakExp pos ->
        if !in_loop then { exp = Translate.break_exp break; ty = Types.Unit }
        else ErrorMsg.fatal_error pos "Break statement not inside loop"
    | A.LetExp { decs; body; _ } ->
        let venv', tenv', exps =
          transDecs transDec venv tenv level break decs
        in
        let { exp; ty } = trans_exp venv' tenv' level break body in
        { exp = Translate.let_exp exps exp; ty }
    | A.ArrayExp { typ; pos; size; init } -> (
        let ty = lookup_type tenv typ pos in
        let ty = lookup_name tenv ty pos in
        match ty with
        | Types.Array (typ, _) ->
            let size = trexp break size in
            check_int size pos;
            let init = trexp break init in
            let typ = lookup_name tenv typ pos in
            if types_inequal tenv init.ty typ pos then
              ErrorMsg.fatal_error pos
                "Array initializer has type %s but a value of type %s was \
                 expected "
                (Types.string_of_ty init.ty)
                (Types.string_of_ty typ);
            { exp = Translate.array_exp size.exp init.exp; ty }
        | _ ->
            ErrorMsg.fatal_error pos "%s is not an array type" (Symbol.name typ)
        )
    | A.UnitExp -> { exp = Translate.unit_exp (); ty = Types.Unit }
  and trvar var = trans_var venv tenv level break var in
  trexp break

and transDec venv tenv level break = function
  | A.VarDec { name; typ; init; escape; pos } ->
      let { exp; ty } = trans_exp venv tenv level break init in
      (match typ with
      | Some (typ, pos) ->
          let typ = lookup_type tenv typ pos in
          (* TODO record names *)
          if types_inequal tenv typ ty pos then
            ErrorMsg.fatal_error pos
              "Variable declared with type %s but the initializing expression \
               has type %s"
              (Types.string_of_ty typ) (Types.string_of_ty ty)
      | _ ->
          if Equal.poly ty Types.Nil then
            ErrorMsg.fatal_error pos
              "Nil expression not constrained by record type");
      let access = Translate.alloc_local level !escape in
      let venv' = Symbol.enter venv name (Env.VarEntry { access; ty }) in
      let var = Translate.simple_var access level in
      let exp = Translate.varDec var exp in
      (venv', tenv, Some exp)
  | A.TypeDec decs ->
      let declare_header venv tenv _ _ ({ td_name; _ } : A.td) =
        let tenv' =
          Symbol.enter tenv td_name (Types.Name (td_name, ref None))
        in
        (venv, tenv', None)
      in
      let declarations = Hashtbl.create (List.length decs) in
      let graph = TypeGraph.create () in
      let process_body venv tenv ({ td_name; ty; _ } : A.td) =
        (match ty with
        | NameTy (name, _) ->
            let get_or_insert graph typ =
              let name = Symbol.name typ in
              let vertex = ref (TypeGraph.V.create name) in
              let count =
                Hashtbl.find_opt declarations name
                |> Option.map_or ~default:1 (fun count -> count + 1)
              in
              Hashtbl.replace declarations name count;
              TypeGraph.iter_vertex
                (fun v ->
                  if String.equal (TypeGraph.V.label v) name then vertex := v)
                graph;
              !vertex
            in
            let src = get_or_insert graph td_name in
            let dest = get_or_insert graph name in
            TypeGraph.add_edge graph src dest
        | _ -> ());
        let tenv' = Symbol.enter tenv td_name (transTy tenv ty) in
        (venv, tenv')
      in
      let venv, tenv', _ =
        transDecs declare_header venv tenv level break decs
      in
      let venv, tenv'' =
        List.fold_left
          (fun (venv, tenv) dec -> process_body venv tenv dec)
          (venv, tenv') decs
      in
      (* TODO maybe find a better solution *)
      Hashtbl.iter
        (fun name count ->
          if count > 1 then
            ErrorMsg.fatal_error (0, 0) "Type %s redeclared" name)
        declarations;
      if CycleChecker.has_cycle graph then
        ErrorMsg.fatal_error (0, 0)
          "Illegal cycle detected in type declarations"
      else (venv, tenv'', None)
  | A.FunctionDec decs ->
      let levels = ref [] in
      let declarations = Hashtbl.create (List.length decs) in
      let declare_header venv tenv level _ = function
        | A.Fundec { name; params; result; _ } ->
            let count =
              Hashtbl.find_opt declarations (Symbol.name name)
              |> Option.map_or ~default:1 (fun count -> count + 1)
            in
            Hashtbl.replace declarations (Symbol.name name) count;
            let result_ty =
              match result with
              | Some (rt, pos) -> lookup_type tenv rt pos
              | None -> Types.Unit
            in
            let transparam ({ fd_name; typ; fd_pos; _ } : A.field) =
              let ty = lookup_type tenv typ fd_pos in
              (fd_name, ty)
            in
            let params' = List.map transparam params in
            let escapes =
              List.map (fun ({ escape; _ } : A.field) -> !escape) params
            in
            let label = Temp.named_label (Symbol.name name) in
            let level = Translate.new_level level label escapes in
            levels := level :: !levels;
            let venv' =
              let formals : Types.ty list =
                List.map (fun (_, ty) -> ty) params'
              in
              Symbol.enter venv name
                (Env.FunEntry { level; label; formals; result = result_ty })
            in

            (venv', tenv, None)
      in
      let process_body venv tenv level = function
        | A.Fundec { body; result; params; pos; _ } ->
            let result_ty =
              match result with
              | Some (rt, pos) -> lookup_type tenv rt pos
              | None -> Types.Unit
            in
            let transparam ({ fd_name; typ; fd_pos; _ } : A.field) =
              let ty = lookup_type tenv typ fd_pos in
              (fd_name, ty)
            in
            let params' = List.map transparam params in
            let enterparam venv ((name, ty), access) =
              Symbol.enter venv name (Env.VarEntry { access; ty })
            in
            let venv' =
              List.fold_left enterparam venv
                (List.combine params' (Translate.formals level))
            in
            let { ty; exp } = trans_exp venv' tenv level break body in
            Translate.proc_entry_exit level exp;
            if types_inequal tenv ty result_ty pos then
              ErrorMsg.fatal_error pos "Function returns incorrect type"
      in
      let venv', tenv, _ =
        transDecs declare_header venv tenv level break decs
      in
      List.iter2
        (fun dec level -> process_body venv' tenv level dec)
        decs (List.rev !levels);
      (* TODO maybe find a better solution *)
      Hashtbl.iter
        (fun name count ->
          if count > 1 then
            ErrorMsg.fatal_error (0, 0) "Function %s redeclared" name)
        declarations;

      (venv', tenv, None)

and transDecs :
      'a.
      (venv ->
      tenv ->
      Translate.level ->
      Temp.label ->
      'a ->
      venv * tenv * Translate.exp option) ->
      venv ->
      tenv ->
      Translate.level ->
      Temp.label ->
      'a list ->
      tables =
 fun f venv tenv level break decs ->
  let venv, tenv, exps =
    List.fold_left
      (fun (venv, tenv, exps) dec ->
        let venv', tenv', exp = f venv tenv level break dec in
        match exp with
        | Some exp -> (venv', tenv', exp :: exps)
        | None -> (venv', tenv', exps))
      (venv, tenv, []) decs
  in
  (venv, tenv, List.rev exps)

and trans_var venv tenv level break = function
  | A.SimpleVar (var, pos) -> (
      match lookup_var venv var pos with
      | Env.VarEntry { access; ty } ->
          { exp = Translate.simple_var access level; ty }
      | _ -> ErrorMsg.fatal_error pos "%s is not a variable" (Symbol.name var))
  | A.FieldVar (var, field, pos) -> (
      match trans_var venv tenv level break var with
      | { exp; ty = Types.Record (fields, _) } -> (
          match
            List.find_idx
              (fun (record_field, _) -> Symbol.equal record_field field)
              fields
          with
          | Some (i, (_, ty)) -> { exp = Translate.field_var exp i; ty }
          | None ->
              ErrorMsg.fatal_error pos "No field %s in record"
                (Symbol.name field))
      | _ -> ErrorMsg.fatal_error pos "Attempt to access field of a non-record")
  | A.SubscriptVar (var, idx, pos) -> (
      let var = trans_var venv tenv level break var in
      match var with
      | { exp; ty = Types.Array (typ, _) } ->
          let idx = trans_exp venv tenv level break idx in
          check_int idx pos;
          { exp = Translate.subscript_var exp idx.exp; ty = typ }
      | _ ->
          ErrorMsg.fatal_error pos "Attempt to subscript non-array expression")

and transTy tenv = function
  | A.NameTy (name, pos) ->
      Types.Name (name, ref (Some (lookup_type tenv name pos)))
  | A.RecordTy fields ->
      let fields =
        List.map
          (fun ({ fd_name; typ; fd_pos; _ } : A.field) ->
            let ty = lookup_type tenv typ fd_pos in
            (fd_name, ty))
          fields
      in
      Types.Record (fields, ref ())
  | A.ArrayTy (name, pos) -> Types.Array (lookup_type tenv name pos, ref ())

let transProg exp =
  let unused_label = Temp.new_label () in
  let { exp; _ } =
    trans_exp Env.base_venv Env.base_tenv Translate.outermost unused_label exp
  in
  Translate.proc_entry_exit Translate.outermost exp;
  Translate.get_result ()
