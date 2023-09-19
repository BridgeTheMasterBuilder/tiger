open Cmdliner
open Tigerc_lib

(* TODO add arguments to print AST, IR, graphs etc. *)
let parse_args () =
  let source_file =
    Arg.(
      required
      & pos 0 (some string) None
      & info [] ~doc:"Tiger source code file to compile" ~docv:"FILE")
  in
  let output_assembly =
    Arg.(value & flag & info ~doc:"Emit assembly file and exit" [ "s" ])
  in
  let info = Cmd.info "tigerc" in
  let cmd =
    Cmd.v info Term.(const Driver.run $ source_file $ output_assembly)
  in
  exit (Cmd.eval cmd)

let () = parse_args ()
