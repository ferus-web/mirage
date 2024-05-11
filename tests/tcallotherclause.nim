import mirage/[utils, atom, ir/generator]
import mirage/runtime/prelude
import pretty

let gen = newIRGenerator("atomlist")
gen.newModule("other_clause")
gen.loadStr(
  0, "This was called from another function!"
)
gen.call("print", @[integer 0])

gen.newModule("main")
gen.call("other_clause", @[])

let ir = gen.emit()
echo ir

let interpreter = newPulsarInterpreter(ir)
interpreter.analyze()
interpreter.setEntryPoint("main")
interpreter.run()
