%{
      open struct module A = Absyn end
      open Agnostic
%}

%token EOF NIL
%token <string * (int * int) > ID STRING
%token <int> INT 
%token <int * int> COMMA COLON SEMICOLON LPAREN RPAREN LBRACK RBRACK LBRACE RBRACE DOT PLUS MINUS TIMES DIVIDE EQ NEQ LT LE GT GE AND OR ASSIGN ARRAY IF THEN ELSE WHILE FOR TO DO LET IN END OF BREAK FUNCTION VAR TYPE

%start program
%type <Absyn.exp> program

%nonassoc ID
%nonassoc LBRACK 
%nonassoc DECL
%nonassoc FUNCTION TYPE
%nonassoc DO THEN OF
%nonassoc ELSE
%nonassoc ASSIGN
%left AND OR
%nonassoc EQ NEQ GT LT GE LE
%left PLUS MINUS
%left TIMES DIVIDE
%left UMINUS

%%

program: exp EOF { $1 }

exp:  lvalue { A.VarExp($1) }
    | assignment {$1}
    | ifthenelse {$1}
    | ifthen {$1}
    | whileloop {$1}
    | forloop {$1}
    | seq {$1}
    | INT {A.IntExp $1}
    | STRING {let (s, pos) = $1 in A.StringExp (s, pos)}
    | funcall {$1}
    | arith {$1}
    | cmp {$1}
    | bool {$1}
    | letexp {$1}
    | LPAREN exp RPAREN {$2}
    | LPAREN RPAREN {A.UnitExp}
    | NIL {A.NilExp}
    | BREAK {A.BreakExp $1}
    | record {$1}
    | array {$1}

lvalue: ID {let (id, pos) = $1 in A.SimpleVar(Symbol.symbol id, pos)}
      | lvalue DOT ID {let (id, pos) = $3 in A.FieldVar($1, Symbol.symbol id, pos)}
      | lvalue LBRACK exp RBRACK {A.SubscriptVar($1, $3, $2)}
      | ID LBRACK exp RBRACK {let (id, pos) = $1 in A.SubscriptVar(A.SimpleVar (Symbol.symbol id, pos), $3, pos)}

seq: LPAREN exp SEMICOLON exp exps RPAREN {A.SeqExp (($2, $3) :: ($4, $3) :: $5)}

exps: SEMICOLON exp exps {($2, $1) :: $3}
      | {[]}

expseq: exp exps {($1, (-1,-1)) :: $2}
      | {[]}

funcall: ID LPAREN RPAREN {let (id, pos) = $1 in A.CallExp { func=Symbol.symbol id; args=[]; pos=pos }}
      |  ID LPAREN funargs RPAREN {let (id, pos) = $1 in A.CallExp { func=Symbol.symbol id; args=$3; pos=pos }}

funargs: exp COMMA funargs {$1 :: $3}
      | exp {[$1]}

arith:  exp PLUS exp {A.OpExp {left=$1; oper=A.PlusOp; right=$3; pos=$2}}
      | exp MINUS exp {A.OpExp {left=$1; oper=A.MinusOp; right=$3; pos=$2}}
      | exp TIMES exp {A.OpExp {left=$1; oper=A.TimesOp; right=$3; pos=$2}}
      | exp DIVIDE exp {A.OpExp {left=$1; oper=A.DivideOp; right=$3; pos=$2}}
      | MINUS exp %prec UMINUS {A.OpExp {left=A.IntExp 0; oper=A.MinusOp; right=$2; pos=$1}}

cmp:    exp EQ exp {A.OpExp {left=$1; oper=A.EqOp; right=$3; pos=$2}}
      | exp NEQ exp {A.OpExp {left=$1; oper=A.NeqOp; right=$3; pos=$2}}
      | exp GT exp {A.OpExp {left=$1; oper=A.GtOp; right=$3; pos=$2}}
      | exp LT exp {A.OpExp {left=$1; oper=A.LtOp; right=$3; pos=$2}}
      | exp GE exp {A.OpExp {left=$1; oper=A.GeOp; right=$3; pos=$2}}
      | exp LE exp {A.OpExp {left=$1; oper=A.LeOp; right=$3; pos=$2}}

bool:   exp AND exp {A.IfExp {test=$1; then'=$3; else'=Some (A.IntExp 0); pos=$2}}
      | exp OR exp {A.IfExp {test=$1; then'=A.IntExp 1; else'=Some $3; pos=$2}}

assignment: lvalue ASSIGN exp {A.AssignExp {var=$1; exp=$3; pos=$2}}

ifthenelse: IF exp THEN exp ELSE exp {A.IfExp {test=$2; then'=$4; else'=Some $6; pos=$1}}

ifthen: IF exp THEN exp {A.IfExp {test=$2; then'=$4; else'=None; pos=$1}}

whileloop: WHILE exp DO exp {A.WhileExp {test=$2; body=$4; pos=$1}}

forloop: FOR ID ASSIGN exp TO exp DO exp {let (id, pos) = $2 in A.ForExp {var=Symbol.symbol id; escape=ref true; lo=$4; hi=$6; body=$8; pos=pos}}

decs: dec decs {$1::$2}
    | {[]}

dec:  tydecs {A.TypeDec $1}
    | vardec {$1}
    | fundecs {A.FunctionDec $1}

tydecs: tydec tydec_list {$1 :: $2}
      
tydec_list: tydec tydec_list {$1 :: $2}
      | %prec DECL {[]}

tydec: TYPE ID EQ ty {let (id, pos) = $2 in ({td_name=Symbol.symbol id; ty=$4; td_pos=pos} : A.td)}

ty: ID {let (id, pos) = $1 in A.NameTy(Symbol.symbol id, pos)}
  | LBRACE tyfields RBRACE {A.RecordTy $2}
  | LBRACE RBRACE {A.RecordTy []}
  | ARRAY OF ID {let (id, _) = $3 in A.ArrayTy(Symbol.symbol id, $1)}

tyfields: tyfield COMMA tyfields {$1 :: $3}
        | tyfield {[$1]}

tyfield: ID COLON ID {let (id1, pos) = $1 in let (id2, _) = $3 in ({fd_name=Symbol.symbol id1; escape=ref true; typ=Symbol.symbol id2; fd_pos=pos} : A.field)}

vardec: VAR ID ASSIGN exp {let (id, _) = $2 in A.VarDec {name=Symbol.symbol id; escape=ref true; typ=None; init=$4; pos=$1}}
      | VAR ID COLON ID ASSIGN exp {let (id1, _) = $2 in let (id2, pos) = $4 in A.VarDec {name=Symbol.symbol id1; escape=ref true; typ=Some (Symbol.symbol id2, pos); init=$6; pos=$1}}

fundecs: fundec fundec_list {$1::$2}
       
fundec_list: fundec fundec_list {$1::$2}
      | %prec DECL {[]}

fundec: FUNCTION ID LPAREN RPAREN EQ exp {let (id, _) = $2 in (Fundec {name=Symbol.symbol id; params=[]; result=None; body=$6; pos=$1} : A.fundec)}
      | FUNCTION ID LPAREN RPAREN COLON ID EQ exp {let (id, _) = $2 in let (id2, pos) = $6 in (Fundec {name=Symbol.symbol id; params=[]; result=Some (Symbol.symbol id2, pos); body=$8; pos=$1} : A.fundec)}
      | FUNCTION ID LPAREN tyfields RPAREN EQ exp {let (id, _) = $2 in (Fundec {name=Symbol.symbol id; params=$4; result=None; body=$7; pos=$1} : A.fundec)}
      | FUNCTION ID LPAREN tyfields RPAREN COLON ID EQ exp {let (id1, _) = $2 in let (id2, pos) = $7 in (Fundec {name=Symbol.symbol id1; params=$4; result=Some (Symbol.symbol id2, pos); body=$9; pos=$1} : A.fundec)}

letexp: LET decs IN expseq END {A.LetExp {decs=$2; body=A.SeqExp $4; pos=$1}}

record: ID LBRACE RBRACE {let (id, pos) = $1 in A.RecordExp {fields=[]; typ=Symbol.symbol id; pos=pos}}
      | ID LBRACE field fields RBRACE {let (id, pos) = $1 in A.RecordExp {fields=($3::$4); typ=Symbol.symbol id; pos=pos}}

fields: COMMA field fields {$2::$3}
      | {[]}

field: ID EQ exp {let (id, pos) = $1 in (Symbol.symbol id, $3, pos)}

array: ID LBRACK exp RBRACK OF exp {let (id, pos) = $1 in A.ArrayExp {typ=Symbol.symbol id; size=$3; init=$6; pos=pos}}
