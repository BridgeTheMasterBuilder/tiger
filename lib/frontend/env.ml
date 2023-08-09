open Agnostic
open Containers

type ty = Types.ty

type enventry =
  | VarEntry of { access : Translate.access; ty : ty }
  | FunEntry of {
      level : Translate.level;
      label : Temp.label;
      formals : ty list;
      result : ty;
    }

let builtin_types = [ ("int", Types.Int); ("string", Types.String) ]

let builtin_functions =
  [
    ( "print",
      FunEntry
        {
          level = Translate.outermost;
          label = Temp.global_label "print";
          formals = [ Types.String ];
          result = Types.Unit;
        } );
    ( "flush",
      FunEntry
        {
          level = Translate.outermost;
          label = Temp.global_label "flush";
          formals = [];
          result = Types.Unit;
        } );
    ( "getchar",
      FunEntry
        {
          level = Translate.outermost;
          label = Temp.global_label "getchar";
          formals = [];
          result = Types.String;
        } );
    ( "ord",
      FunEntry
        {
          level = Translate.outermost;
          label = Temp.global_label "ord";
          formals = [ Types.String ];
          result = Types.Int;
        } );
    ( "chr",
      FunEntry
        {
          level = Translate.outermost;
          label = Temp.global_label "chr";
          formals = [ Types.Int ];
          result = Types.String;
        } );
    ( "size",
      FunEntry
        {
          level = Translate.outermost;
          label = Temp.global_label "size";
          formals = [ Types.String ];
          result = Types.Int;
        } );
    ( "substring",
      FunEntry
        {
          level = Translate.outermost;
          label = Temp.global_label "substring";
          formals = [ Types.String; Types.Int; Types.Int ];
          result = Types.String;
        } );
    ( "concat",
      FunEntry
        {
          level = Translate.outermost;
          label = Temp.global_label "concat";
          formals = [ Types.String; Types.String ];
          result = Types.String;
        } );
    ( "not",
      FunEntry
        {
          level = Translate.outermost;
          label = Temp.global_label "not";
          formals = [ Types.Int ];
          result = Types.Int;
        } );
    ( "exit",
      FunEntry
        {
          level = Translate.outermost;
          label = Temp.global_label "exit";
          formals = [ Types.Int ];
          result = Types.Unit;
        } );
  ]

let predefine (table : 'a Symbol.table) (entries : 'b list) =
  List.fold_left
    (fun table (name, typ) ->
      let symbol = Symbol.symbol name in
      Symbol.enter table symbol typ)
    table entries

let base_tenv =
  let tenv = Symbol.empty () in
  predefine tenv builtin_types

let base_venv =
  let venv = Symbol.empty () in
  predefine venv builtin_functions
