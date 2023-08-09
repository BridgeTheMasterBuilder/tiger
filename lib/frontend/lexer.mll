{
open Parser
open Util
open Agnostic

type pos = int

exception IllegalEscape
exception Unimplemented

let lineNum = ErrorMsg.lineNum
let linePos = ErrorMsg.linePos

let expand_escapes s = 
  let isSpace = function ' ' | '\t' | '\n' -> true | _ -> false in
  let expand_code s =
    int_of_string s |> Char.chr
  in let expand_control _ =
       (* TODO *)
       raise Unimplemented
  in let expand_graphic = function
      'n' -> '\n'
      | 't' -> '\t'
      | '\"' -> '\"'
      | '\\' -> '\\'
      | _ -> raise IllegalEscape
  in let rec skip_whitespace = function 
      | '\\'::cs -> cs
      | c::cs -> if not (isSpace c) then
          raise IllegalEscape
        else skip_whitespace cs
      | _ -> raise IllegalEscape
  in let rec helper = function 
      | [] -> []
      | '\\'::'^'::c::cs ->
        expand_control c :: helper cs
      | '\\'::c::cs ->
        if c >= '0' && c <= '9' then
          let code =
            CCList.take 3 (c::cs)
          in let rest =
               CCList.drop 3 (c::cs)
          in
          expand_code (implode code) :: helper rest
        else if isSpace c 
        then helper (skip_whitespace cs)
        else expand_graphic c :: helper cs
      | c::cs -> c :: helper cs
  in
  implode (helper (explode s))
}

let ident=['A'-'Z' 'a'-'z']['A'-'Z' 'a'-'z' '0'-'9' '_']*
          let ws=['\t' ' ']
let string=[^'"']*

           rule initial =
           parse 
          | "type"       {TYPE(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "var"        {VAR(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "function"   {FUNCTION(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "break"      {BREAK(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "of"         {OF(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "end"        {END(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "in"         {IN(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "nil"        {NIL}
          | "let"        {LET(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "do"         {DO(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "to"         {TO(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "for"        {FOR(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "while"      {WHILE(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "else"       {ELSE(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "then"       {THEN(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "if"         {IF(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "array"      {ARRAY(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | ":="         {ASSIGN(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "|"          {OR(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "&"          {AND(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | ">="         {GE(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | ">"          {GT(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "<="         {LE(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "<"          {LT(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "<>"         {NEQ(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "="          {EQ(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "/"          {DIVIDE(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "*"          {TIMES(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "-"          {MINUS(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "+"          {PLUS(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "."          {DOT(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "}"          {RBRACE(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "{"          {LBRACE(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "]"          {RBRACK(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "["          {LBRACK(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | ")"          {RPAREN(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "("          {LPAREN(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | ";"          {SEMICOLON(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | ":"          {COLON(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | ","          {COMMA(Lexing.lexeme_start lexbuf,Lexing.lexeme_end lexbuf)}
          | "\""         {str "" lexbuf}
          | ['0'-'9']+   {INT(int_of_string (Lexing.lexeme lexbuf))}
          | ident        {ID(Lexing.lexeme lexbuf, (Lexing.lexeme_start lexbuf, Lexing.lexeme_end lexbuf))}
          | ws           {initial lexbuf}
          | "/*"         {comment 0 lexbuf}
          | '\n'         {Lexing.new_line lexbuf; incr lineNum; linePos := (Lexing.lexeme_start lexbuf) :: !linePos; initial lexbuf}
          | _            {error (Lexing.lexeme lexbuf) lexbuf}
          | eof          {EOF}
and str s =
  parse
| "\""         {STRING(expand_escapes s, (Lexing.lexeme_start lexbuf, Lexing.lexeme_end lexbuf))}
| string       {str (s ^ (Lexing.lexeme lexbuf)) lexbuf}
| eof          {ErrorMsg.error ((Lexing.lexeme_start lexbuf), (Lexing.lexeme_end lexbuf)) "Unterminated string"; raise ErrorMsg.Error }
and comment depth =
  parse
| "/*"         {comment (depth + 1) lexbuf}
| "*/"         {if depth = 0 then initial lexbuf else comment (depth - 1) lexbuf}
| '\n'         {Lexing.new_line lexbuf; incr lineNum; linePos := (Lexing.lexeme_start lexbuf) :: !linePos; comment depth lexbuf}
| _            {comment depth lexbuf}
| eof          {ErrorMsg.error ((Lexing.lexeme_start lexbuf), (Lexing.lexeme_end lexbuf)) "Unterminated comment"; raise ErrorMsg.Error }
and error buf =
  parse
| [^'\n' '\t' ]* {ErrorMsg.error ((Lexing.lexeme_start lexbuf), (Lexing.lexeme_end lexbuf)) "Illegal token %s%s" buf (Lexing.lexeme lexbuf); initial lexbuf}
