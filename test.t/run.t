  $ dune exec tigerc -- test10.tig
  test10.tig:2,1 - ERROR: Body of while loop must produce no value
  [1]
  $ dune exec tigerc -- test11.tig
  test11.tig:2,5 - ERROR: Variable declared with type int but the initializing expression has type string
  [1]
  $ dune exec tigerc -- test12.tig
  $ dune exec tigerc -- test13.tig
  test13.tig:3,3 - ERROR: Expected integer
  [1]
  $ dune exec tigerc -- test14.tig
  test14.tig:12,9 - ERROR: Expected record type
  [1]
  $ dune exec tigerc -- test15.tig
  test15.tig:3,1 - ERROR: If-then returns non-unit
  [1]
  $ dune exec tigerc -- test16.tig
  test16.tig:0,0 - ERROR: Type a redeclared
  [1]
  $ dune exec tigerc -- test17.tig
  test17.tig:4,23 - ERROR: Unknown type treelist
  [1]
  $ dune exec tigerc -- test18.tig
  test18.tig:5,4 - ERROR: Undeclared identifier do_nothing2
  [1]
  $ dune exec tigerc -- test19.tig
  test19.tig:8,16 - ERROR: Undeclared identifier a
  [1]
  $ dune exec tigerc -- test1.tig
  $ dune exec tigerc -- test20.tig
  test20.tig:3,18 - ERROR: Undeclared identifier i
  [1]
  $ dune exec tigerc -- test21.tig
  test21.tig:8,11 - ERROR: Expected integer
  [1]
  $ dune exec tigerc -- test22.tig
  test22.tig:7,7 - ERROR: No field nam in record
  [1]
  $ dune exec tigerc -- test23.tig
  test23.tig:7,12 - ERROR: Assigning value of type string to a variable of type int
  [1]
  $ dune exec tigerc -- test24.tig
  test24.tig:5,2 - ERROR: Attempt to subscript non-array expression
  [1]
  $ dune exec tigerc -- test25.tig
  test25.tig:5,4 - ERROR: Attempt to access field of a non-record
  [1]
  $ dune exec tigerc -- test26.tig
  test26.tig:3,3 - ERROR: Expected integer
  [1]
  $ dune exec tigerc -- test27.tig
  $ dune exec tigerc -- test28.tig
  test28.tig:7,12 - ERROR: Variable declared with type record but the initializing expression has type record
  [1]
  $ dune exec tigerc -- test29.tig
  test29.tig:7,12 - ERROR: Variable declared with type array but the initializing expression has type array
  [1]
  $ dune exec tigerc -- test2.tig
  $ dune exec tigerc -- test30.tig
  $ dune exec tigerc -- test31.tig
  test31.tig:3,8 - ERROR: Variable declared with type int but the initializing expression has type string
  [1]
  $ dune exec tigerc -- test32.tig
  test32.tig:6,11 - ERROR: Array initializer has type string but a value of type int was expected 
  [1]
  $ dune exec tigerc -- test33.tig
  test33.tig:3,10 - ERROR: Unknown type rectype
  [1]
  $ dune exec tigerc -- test34.tig
  test34.tig:5,2 - ERROR: Type string of argument does not match declared type int of parameter
  [1]
  $ dune exec tigerc -- test35.tig
  test35.tig:5,2 - ERROR: Insufficient arguments given to function g, expected 2 but got 1
  [1]
  $ dune exec tigerc -- test36.tig
  test36.tig:5,2 - ERROR: Insufficient arguments given to function g, expected 2 but got 3
  [1]
  $ dune exec tigerc -- test37.tig
  $ dune exec tigerc -- test38.tig
  test38.tig:0,0 - ERROR: Type a redeclared
  [1]
  $ dune exec tigerc -- test39.tig
  test39.tig:0,0 - ERROR: Function g redeclared
  [1]
  $ dune exec tigerc -- test3.tig
  $ dune exec tigerc -- test40.tig
  test40.tig:3,2 - ERROR: Function returns incorrect type
  [1]
  $ dune exec tigerc -- test41.tig
  $ dune exec tigerc -- test42.tig
  $ dune exec tigerc -- test43.tig
  test43.tig:6,4 - ERROR: Expected integer
  [1]
  $ dune exec tigerc -- test44.tig
  $ dune exec tigerc -- test45.tig
  test45.tig:5,2 - ERROR: Nil expression not constrained by record type
  [1]
  $ dune exec tigerc -- test46.tig
  $ dune exec tigerc -- test47.tig
  $ dune exec tigerc -- test48.tig
  $ dune exec tigerc -- test49.tig
  Syntax error.
  [1]
  $ dune exec tigerc -- test4.tig
  $ dune exec tigerc -- test5.tig
  $ dune exec tigerc -- test6.tig
  $ dune exec tigerc -- test7.tig
  $ dune exec tigerc -- test8.tig
  $ dune exec tigerc -- test9.tig
  test9.tig:3,1 - ERROR: If arms have different types
  [1]
