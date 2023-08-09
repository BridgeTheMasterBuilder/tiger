exception Error

val filename : string ref
val lineNum : int ref
val linePos : int list ref
val impossible : ('b, unit, string, 'c) format4 -> 'b
val error : int * 'a -> ('b, unit, string, unit) format4 -> 'b
val fatal_error : int * 'a -> ('b, unit, string, 'c) format4 -> 'b
