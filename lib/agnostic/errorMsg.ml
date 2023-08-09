open Containers

exception Error

let filename = ref ""
let lineNum = ref 1
let linePos = ref [ 1 ]

let impossible f =
  Printf.ksprintf
    (fun msg ->
      prerr_string msg;
      flush stderr;
      raise Error)
    f

let aux pos msg =
  let rec look = function
    | a :: rest, n -> if a < pos then (n, pos - a) else look (rest, n - 1)
    | _ -> (0, 0)
  in
  let line, col = look (!linePos, !lineNum) in
  Printf.eprintf "%s:%d,%d - ERROR: %s\n" !filename line col msg

let error (beg, _) f = Printf.ksprintf (aux beg) f

let fatal_error (beg, _) f =
  Printf.ksprintf
    (fun msg ->
      aux beg msg;
      flush stderr;
      raise Error)
    f
