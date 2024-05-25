  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test10.tig
  test10.tig:2,1 - ERROR: Body of while loop must produce no value
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test11.tig
  test11.tig:2,5 - ERROR: Variable declared with type int but the initializing expression has type string
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test12.tig
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test13.tig
  test13.tig:3,3 - ERROR: Expected integer
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test14.tig
  test14.tig:12,9 - ERROR: Expected record type
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test15.tig
  test15.tig:3,1 - ERROR: If-then returns non-unit
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test16.tig
  test16.tig:0,0 - ERROR: Type a redeclared
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test17.tig
  test17.tig:4,23 - ERROR: Unknown type treelist
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test18.tig
  test18.tig:5,4 - ERROR: Undeclared identifier do_nothing2
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test19.tig
  test19.tig:8,16 - ERROR: Undeclared identifier a
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test1.tig
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test20.tig
  test20.tig:3,18 - ERROR: Undeclared identifier i
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test21.tig
  test21.tig:8,11 - ERROR: Expected integer
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test22.tig
  test22.tig:7,7 - ERROR: No field nam in record
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test23.tig
  test23.tig:7,12 - ERROR: Assigning value of type string to a variable of type int
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test24.tig
  test24.tig:5,2 - ERROR: Attempt to subscript non-array expression
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test25.tig
  test25.tig:5,4 - ERROR: Attempt to access field of a non-record
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test26.tig
  test26.tig:3,3 - ERROR: Expected integer
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test27.tig
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test28.tig
  test28.tig:7,12 - ERROR: Variable declared with type record but the initializing expression has type record
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test29.tig
  test29.tig:7,12 - ERROR: Variable declared with type array but the initializing expression has type array
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test2.tig
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test30.tig
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test31.tig
  test31.tig:3,8 - ERROR: Variable declared with type int but the initializing expression has type string
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test32.tig
  test32.tig:6,11 - ERROR: Array initializer has type string but a value of type int was expected 
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test33.tig
  test33.tig:3,10 - ERROR: Unknown type rectype
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test34.tig
  test34.tig:5,2 - ERROR: Type string of argument does not match declared type int of parameter
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test35.tig
  test35.tig:5,2 - ERROR: Insufficient arguments given to function g, expected 2 but got 1
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test36.tig
  test36.tig:5,2 - ERROR: Insufficient arguments given to function g, expected 2 but got 3
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test37.tig
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test38.tig
  test38.tig:0,0 - ERROR: Type a redeclared
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test39.tig
  test39.tig:0,0 - ERROR: Function g redeclared
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test3.tig
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test40.tig
  test40.tig:3,2 - ERROR: Function returns incorrect type
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test41.tig
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test42.tig
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test43.tig
  test43.tig:6,4 - ERROR: Expected integer
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test44.tig
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test45.tig
  test45.tig:5,2 - ERROR: Nil expression not constrained by record type
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test46.tig
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test47.tig
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test48.tig
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test49.tig
  Syntax error.
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test4.tig
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test5.tig
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test6.tig
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test7.tig
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test8.tig
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- test9.tig
  test9.tig:3,1 - ERROR: If arms have different types
  [1]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc -- ../../programs/queens.tig
  $ ./a.out
   O . . . . . . .
   . . . . O . . .
   . . . . . . . O
   . . . . . O . .
   . . O . . . . .
   . . . . . . O .
   . O . . . . . .
   . . . O . . . .
  
   O . . . . . . .
   . . . . . O . .
   . . . . . . . O
   . . O . . . . .
   . . . . . . O .
   . . . O . . . .
   . O . . . . . .
   . . . . O . . .
  
   O . . . . . . .
   . . . . . . O .
   . . . O . . . .
   . . . . . O . .
   . . . . . . . O
   . O . . . . . .
   . . . . O . . .
   . . O . . . . .
  
   O . . . . . . .
   . . . . . . O .
   . . . . O . . .
   . . . . . . . O
   . O . . . . . .
   . . . O . . . .
   . . . . . O . .
   . . O . . . . .
  
   . O . . . . . .
   . . . O . . . .
   . . . . . O . .
   . . . . . . . O
   . . O . . . . .
   O . . . . . . .
   . . . . . . O .
   . . . . O . . .
  
   . O . . . . . .
   . . . . O . . .
   . . . . . . O .
   O . . . . . . .
   . . O . . . . .
   . . . . . . . O
   . . . . . O . .
   . . . O . . . .
  
   . O . . . . . .
   . . . . O . . .
   . . . . . . O .
   . . . O . . . .
   O . . . . . . .
   . . . . . . . O
   . . . . . O . .
   . . O . . . . .
  
   . O . . . . . .
   . . . . . O . .
   O . . . . . . .
   . . . . . . O .
   . . . O . . . .
   . . . . . . . O
   . . O . . . . .
   . . . . O . . .
  
   . O . . . . . .
   . . . . . O . .
   . . . . . . . O
   . . O . . . . .
   O . . . . . . .
   . . . O . . . .
   . . . . . . O .
   . . . . O . . .
  
   . O . . . . . .
   . . . . . . O .
   . . O . . . . .
   . . . . . O . .
   . . . . . . . O
   . . . . O . . .
   O . . . . . . .
   . . . O . . . .
  
   . O . . . . . .
   . . . . . . O .
   . . . . O . . .
   . . . . . . . O
   O . . . . . . .
   . . . O . . . .
   . . . . . O . .
   . . O . . . . .
  
   . O . . . . . .
   . . . . . . . O
   . . . . . O . .
   O . . . . . . .
   . . O . . . . .
   . . . . O . . .
   . . . . . . O .
   . . . O . . . .
  
   . . O . . . . .
   O . . . . . . .
   . . . . . . O .
   . . . . O . . .
   . . . . . . . O
   . O . . . . . .
   . . . O . . . .
   . . . . . O . .
  
   . . O . . . . .
   . . . . O . . .
   . O . . . . . .
   . . . . . . . O
   O . . . . . . .
   . . . . . . O .
   . . . O . . . .
   . . . . . O . .
  
   . . O . . . . .
   . . . . O . . .
   . O . . . . . .
   . . . . . . . O
   . . . . . O . .
   . . . O . . . .
   . . . . . . O .
   O . . . . . . .
  
   . . O . . . . .
   . . . . O . . .
   . . . . . . O .
   O . . . . . . .
   . . . O . . . .
   . O . . . . . .
   . . . . . . . O
   . . . . . O . .
  
   . . O . . . . .
   . . . . O . . .
   . . . . . . . O
   . . . O . . . .
   O . . . . . . .
   . . . . . . O .
   . O . . . . . .
   . . . . . O . .
  
   . . O . . . . .
   . . . . . O . .
   . O . . . . . .
   . . . . O . . .
   . . . . . . . O
   O . . . . . . .
   . . . . . . O .
   . . . O . . . .
  
   . . O . . . . .
   . . . . . O . .
   . O . . . . . .
   . . . . . . O .
   O . . . . . . .
   . . . O . . . .
   . . . . . . . O
   . . . . O . . .
  
   . . O . . . . .
   . . . . . O . .
   . O . . . . . .
   . . . . . . O .
   . . . . O . . .
   O . . . . . . .
   . . . . . . . O
   . . . O . . . .
  
   . . O . . . . .
   . . . . . O . .
   . . . O . . . .
   O . . . . . . .
   . . . . . . . O
   . . . . O . . .
   . . . . . . O .
   . O . . . . . .
  
   . . O . . . . .
   . . . . . O . .
   . . . O . . . .
   . O . . . . . .
   . . . . . . . O
   . . . . O . . .
   . . . . . . O .
   O . . . . . . .
  
   . . O . . . . .
   . . . . . O . .
   . . . . . . . O
   O . . . . . . .
   . . . O . . . .
   . . . . . . O .
   . . . . O . . .
   . O . . . . . .
  
   . . O . . . . .
   . . . . . O . .
   . . . . . . . O
   O . . . . . . .
   . . . . O . . .
   . . . . . . O .
   . O . . . . . .
   . . . O . . . .
  
   . . O . . . . .
   . . . . . O . .
   . . . . . . . O
   . O . . . . . .
   . . . O . . . .
   O . . . . . . .
   . . . . . . O .
   . . . . O . . .
  
   . . O . . . . .
   . . . . . . O .
   . O . . . . . .
   . . . . . . . O
   . . . . O . . .
   O . . . . . . .
   . . . O . . . .
   . . . . . O . .
  
   . . O . . . . .
   . . . . . . O .
   . O . . . . . .
   . . . . . . . O
   . . . . . O . .
   . . . O . . . .
   O . . . . . . .
   . . . . O . . .
  
   . . O . . . . .
   . . . . . . . O
   . . . O . . . .
   . . . . . . O .
   O . . . . . . .
   . . . . . O . .
   . O . . . . . .
   . . . . O . . .
  
   . . . O . . . .
   O . . . . . . .
   . . . . O . . .
   . . . . . . . O
   . O . . . . . .
   . . . . . . O .
   . . O . . . . .
   . . . . . O . .
  
   . . . O . . . .
   O . . . . . . .
   . . . . O . . .
   . . . . . . . O
   . . . . . O . .
   . . O . . . . .
   . . . . . . O .
   . O . . . . . .
  
   . . . O . . . .
   . O . . . . . .
   . . . . O . . .
   . . . . . . . O
   . . . . . O . .
   O . . . . . . .
   . . O . . . . .
   . . . . . . O .
  
   . . . O . . . .
   . O . . . . . .
   . . . . . . O .
   . . O . . . . .
   . . . . . O . .
   . . . . . . . O
   O . . . . . . .
   . . . . O . . .
  
   . . . O . . . .
   . O . . . . . .
   . . . . . . O .
   . . O . . . . .
   . . . . . O . .
   . . . . . . . O
   . . . . O . . .
   O . . . . . . .
  
   . . . O . . . .
   . O . . . . . .
   . . . . . . O .
   . . . . O . . .
   O . . . . . . .
   . . . . . . . O
   . . . . . O . .
   . . O . . . . .
  
   . . . O . . . .
   . O . . . . . .
   . . . . . . . O
   . . . . O . . .
   . . . . . . O .
   O . . . . . . .
   . . O . . . . .
   . . . . . O . .
  
   . . . O . . . .
   . O . . . . . .
   . . . . . . . O
   . . . . . O . .
   O . . . . . . .
   . . O . . . . .
   . . . . O . . .
   . . . . . . O .
  
   . . . O . . . .
   . . . . . O . .
   O . . . . . . .
   . . . . O . . .
   . O . . . . . .
   . . . . . . . O
   . . O . . . . .
   . . . . . . O .
  
   . . . O . . . .
   . . . . . O . .
   . . . . . . . O
   . O . . . . . .
   . . . . . . O .
   O . . . . . . .
   . . O . . . . .
   . . . . O . . .
  
   . . . O . . . .
   . . . . . O . .
   . . . . . . . O
   . . O . . . . .
   O . . . . . . .
   . . . . . . O .
   . . . . O . . .
   . O . . . . . .
  
   . . . O . . . .
   . . . . . . O .
   O . . . . . . .
   . . . . . . . O
   . . . . O . . .
   . O . . . . . .
   . . . . . O . .
   . . O . . . . .
  
   . . . O . . . .
   . . . . . . O .
   . . O . . . . .
   . . . . . . . O
   . O . . . . . .
   . . . . O . . .
   O . . . . . . .
   . . . . . O . .
  
   . . . O . . . .
   . . . . . . O .
   . . . . O . . .
   . O . . . . . .
   . . . . . O . .
   O . . . . . . .
   . . O . . . . .
   . . . . . . . O
  
   . . . O . . . .
   . . . . . . O .
   . . . . O . . .
   . . O . . . . .
   O . . . . . . .
   . . . . . O . .
   . . . . . . . O
   . O . . . . . .
  
   . . . O . . . .
   . . . . . . . O
   O . . . . . . .
   . . O . . . . .
   . . . . . O . .
   . O . . . . . .
   . . . . . . O .
   . . . . O . . .
  
   . . . O . . . .
   . . . . . . . O
   O . . . . . . .
   . . . . O . . .
   . . . . . . O .
   . O . . . . . .
   . . . . . O . .
   . . O . . . . .
  
   . . . O . . . .
   . . . . . . . O
   . . . . O . . .
   . . O . . . . .
   O . . . . . . .
   . . . . . . O .
   . O . . . . . .
   . . . . . O . .
  
   . . . . O . . .
   O . . . . . . .
   . . . O . . . .
   . . . . . O . .
   . . . . . . . O
   . O . . . . . .
   . . . . . . O .
   . . O . . . . .
  
   . . . . O . . .
   O . . . . . . .
   . . . . . . . O
   . . . O . . . .
   . O . . . . . .
   . . . . . . O .
   . . O . . . . .
   . . . . . O . .
  
   . . . . O . . .
   O . . . . . . .
   . . . . . . . O
   . . . . . O . .
   . . O . . . . .
   . . . . . . O .
   . O . . . . . .
   . . . O . . . .
  
   . . . . O . . .
   . O . . . . . .
   . . . O . . . .
   . . . . . O . .
   . . . . . . . O
   . . O . . . . .
   O . . . . . . .
   . . . . . . O .
  
   . . . . O . . .
   . O . . . . . .
   . . . O . . . .
   . . . . . . O .
   . . O . . . . .
   . . . . . . . O
   . . . . . O . .
   O . . . . . . .
  
   . . . . O . . .
   . O . . . . . .
   . . . . . O . .
   O . . . . . . .
   . . . . . . O .
   . . . O . . . .
   . . . . . . . O
   . . O . . . . .
  
   . . . . O . . .
   . O . . . . . .
   . . . . . . . O
   O . . . . . . .
   . . . O . . . .
   . . . . . . O .
   . . O . . . . .
   . . . . . O . .
  
   . . . . O . . .
   . . O . . . . .
   O . . . . . . .
   . . . . . O . .
   . . . . . . . O
   . O . . . . . .
   . . . O . . . .
   . . . . . . O .
  
   . . . . O . . .
   . . O . . . . .
   O . . . . . . .
   . . . . . . O .
   . O . . . . . .
   . . . . . . . O
   . . . . . O . .
   . . . O . . . .
  
   . . . . O . . .
   . . O . . . . .
   . . . . . . . O
   . . . O . . . .
   . . . . . . O .
   O . . . . . . .
   . . . . . O . .
   . O . . . . . .
  
   . . . . O . . .
   . . . . . . O .
   O . . . . . . .
   . . O . . . . .
   . . . . . . . O
   . . . . . O . .
   . . . O . . . .
   . O . . . . . .
  
   . . . . O . . .
   . . . . . . O .
   O . . . . . . .
   . . . O . . . .
   . O . . . . . .
   . . . . . . . O
   . . . . . O . .
   . . O . . . . .
  
   . . . . O . . .
   . . . . . . O .
   . O . . . . . .
   . . . O . . . .
   . . . . . . . O
   O . . . . . . .
   . . O . . . . .
   . . . . . O . .
  
   . . . . O . . .
   . . . . . . O .
   . O . . . . . .
   . . . . . O . .
   . . O . . . . .
   O . . . . . . .
   . . . O . . . .
   . . . . . . . O
  
   . . . . O . . .
   . . . . . . O .
   . O . . . . . .
   . . . . . O . .
   . . O . . . . .
   O . . . . . . .
   . . . . . . . O
   . . . O . . . .
  
   . . . . O . . .
   . . . . . . O .
   . . . O . . . .
   O . . . . . . .
   . . O . . . . .
   . . . . . . . O
   . . . . . O . .
   . O . . . . . .
  
   . . . . O . . .
   . . . . . . . O
   . . . O . . . .
   O . . . . . . .
   . . O . . . . .
   . . . . . O . .
   . O . . . . . .
   . . . . . . O .
  
   . . . . O . . .
   . . . . . . . O
   . . . O . . . .
   O . . . . . . .
   . . . . . . O .
   . O . . . . . .
   . . . . . O . .
   . . O . . . . .
  
   . . . . . O . .
   O . . . . . . .
   . . . . O . . .
   . O . . . . . .
   . . . . . . . O
   . . O . . . . .
   . . . . . . O .
   . . . O . . . .
  
   . . . . . O . .
   . O . . . . . .
   . . . . . . O .
   O . . . . . . .
   . . O . . . . .
   . . . . O . . .
   . . . . . . . O
   . . . O . . . .
  
   . . . . . O . .
   . O . . . . . .
   . . . . . . O .
   O . . . . . . .
   . . . O . . . .
   . . . . . . . O
   . . . . O . . .
   . . O . . . . .
  
   . . . . . O . .
   . . O . . . . .
   O . . . . . . .
   . . . . . . O .
   . . . . O . . .
   . . . . . . . O
   . O . . . . . .
   . . . O . . . .
  
   . . . . . O . .
   . . O . . . . .
   O . . . . . . .
   . . . . . . . O
   . . . O . . . .
   . O . . . . . .
   . . . . . . O .
   . . . . O . . .
  
   . . . . . O . .
   . . O . . . . .
   O . . . . . . .
   . . . . . . . O
   . . . . O . . .
   . O . . . . . .
   . . . O . . . .
   . . . . . . O .
  
   . . . . . O . .
   . . O . . . . .
   . . . . O . . .
   . . . . . . O .
   O . . . . . . .
   . . . O . . . .
   . O . . . . . .
   . . . . . . . O
  
   . . . . . O . .
   . . O . . . . .
   . . . . O . . .
   . . . . . . . O
   O . . . . . . .
   . . . O . . . .
   . O . . . . . .
   . . . . . . O .
  
   . . . . . O . .
   . . O . . . . .
   . . . . . . O .
   . O . . . . . .
   . . . O . . . .
   . . . . . . . O
   O . . . . . . .
   . . . . O . . .
  
   . . . . . O . .
   . . O . . . . .
   . . . . . . O .
   . O . . . . . .
   . . . . . . . O
   . . . . O . . .
   O . . . . . . .
   . . . O . . . .
  
   . . . . . O . .
   . . O . . . . .
   . . . . . . O .
   . . . O . . . .
   O . . . . . . .
   . . . . . . . O
   . O . . . . . .
   . . . . O . . .
  
   . . . . . O . .
   . . . O . . . .
   O . . . . . . .
   . . . . O . . .
   . . . . . . . O
   . O . . . . . .
   . . . . . . O .
   . . O . . . . .
  
   . . . . . O . .
   . . . O . . . .
   . O . . . . . .
   . . . . . . . O
   . . . . O . . .
   . . . . . . O .
   O . . . . . . .
   . . O . . . . .
  
   . . . . . O . .
   . . . O . . . .
   . . . . . . O .
   O . . . . . . .
   . . O . . . . .
   . . . . O . . .
   . O . . . . . .
   . . . . . . . O
  
   . . . . . O . .
   . . . O . . . .
   . . . . . . O .
   O . . . . . . .
   . . . . . . . O
   . O . . . . . .
   . . . . O . . .
   . . O . . . . .
  
   . . . . . O . .
   . . . . . . . O
   . O . . . . . .
   . . . O . . . .
   O . . . . . . .
   . . . . . . O .
   . . . . O . . .
   . . O . . . . .
  
   . . . . . . O .
   O . . . . . . .
   . . O . . . . .
   . . . . . . . O
   . . . . . O . .
   . . . O . . . .
   . O . . . . . .
   . . . . O . . .
  
   . . . . . . O .
   . O . . . . . .
   . . . O . . . .
   O . . . . . . .
   . . . . . . . O
   . . . . O . . .
   . . O . . . . .
   . . . . . O . .
  
   . . . . . . O .
   . O . . . . . .
   . . . . . O . .
   . . O . . . . .
   O . . . . . . .
   . . . O . . . .
   . . . . . . . O
   . . . . O . . .
  
   . . . . . . O .
   . . O . . . . .
   O . . . . . . .
   . . . . . O . .
   . . . . . . . O
   . . . . O . . .
   . O . . . . . .
   . . . O . . . .
  
   . . . . . . O .
   . . O . . . . .
   . . . . . . . O
   . O . . . . . .
   . . . . O . . .
   O . . . . . . .
   . . . . . O . .
   . . . O . . . .
  
   . . . . . . O .
   . . . O . . . .
   . O . . . . . .
   . . . . O . . .
   . . . . . . . O
   O . . . . . . .
   . . O . . . . .
   . . . . . O . .
  
   . . . . . . O .
   . . . O . . . .
   . O . . . . . .
   . . . . . . . O
   . . . . . O . .
   O . . . . . . .
   . . O . . . . .
   . . . . O . . .
  
   . . . . . . O .
   . . . . O . . .
   . . O . . . . .
   O . . . . . . .
   . . . . . O . .
   . . . . . . . O
   . O . . . . . .
   . . . O . . . .
  
   . . . . . . . O
   . O . . . . . .
   . . . O . . . .
   O . . . . . . .
   . . . . . . O .
   . . . . O . . .
   . . O . . . . .
   . . . . . O . .
  
   . . . . . . . O
   . O . . . . . .
   . . . . O . . .
   . . O . . . . .
   O . . . . . . .
   . . . . . . O .
   . . . O . . . .
   . . . . . O . .
  
   . . . . . . . O
   . . O . . . . .
   O . . . . . . .
   . . . . . O . .
   . O . . . . . .
   . . . . O . . .
   . . . . . . O .
   . . . O . . . .
  
   . . . . . . . O
   . . . O . . . .
   O . . . . . . .
   . . O . . . . .
   . . . . . O . .
   . O . . . . . .
   . . . . . . O .
   . . . . O . . .
  
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc
  tigerc: required argument FILE is missing
  Usage: tigerc [-s] [OPTION]… FILE
  Try 'tigerc --help' for more information.
  [124]
  $ TIGERC_RUNTIME_DIR=/home/master/projects/tigerc/runtime/ tigerc ../../programs/merge.tig
  $ echo '' | ./a.out
  
  $ echo ';' | ./a.out
  
  $ echo ';;' | ./a.out
  
  $ echo '0' | ./a.out
  0 
  $ echo '0;1' | ./a.out
  0 1 
  $ echo '0;1;' | ./a.out
  0 1 
  $ echo '1;0' | ./a.out
  0 1 
  $ echo ';1 2 3' | ./a.out
  1 2 3 
  $ echo '3; 1 2' | ./a.out
  1 2 3 
  $ echo '1 2 3; 4 5 6' | ./a.out
  1 2 3 4 5 6 
  $ echo '1 3 5; 6 4 2' | ./a.out
  1 3 5 6 4 2 
  $ echo '4 5 6; 1 2 3' | ./a.out
  1 2 3 4 5 6 
