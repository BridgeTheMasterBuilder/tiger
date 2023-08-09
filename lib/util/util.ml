open Containers

let explode s = List.init (String.length s) (String.get s)
let implode l = String.of_seq (List.to_seq l)

module ListRef = struct
  let append x y = x := !x @ !y
  let map f list = List.map f !list

  let pop list =
    let x = List.hd !list in
    list := List.tl !list;
    x

  let push x list = list := x :: !list
end
