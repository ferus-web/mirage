import mirage/runtime/compiler/x86/codegen
import mirage/atom
import mirage/runtime/pulsar/interpreter

let compiler = newCompiler()
let fn = compiler.compile(
  Clause(
    name: "main",
    operations:
      @[Operation(index: 0, args: @[str "hello from compiled land"], opcode: LoadStr)],
  )
)

fn()
