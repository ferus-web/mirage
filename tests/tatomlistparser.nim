import std/tables

import mirage/[utils, atom, ir/generator]
import mirage/runtime/prelude
import pretty

let gen = newIRGenerator("atomlist")
gen.newModule("main")
gen.loadList(1)
gen.loadStr(2, "hello")
gen.appendList(1, 2) # append [2] to [1]
gen.loadBool(3, true)
gen.call("print", @[integer 3])
print gen

let ir = gen.emit()
echo ir

let interpreter = newPulsarInterpreter(ir)
interpreter.analyze()
interpreter.run()

for i, item in interpreter.stack:
  print item
