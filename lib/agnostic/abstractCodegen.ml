module type Codegen = sig
  val codegen : Tree.stm -> Assem.insn list
end
