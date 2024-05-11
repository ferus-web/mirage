import mirage/[utils, atom, ir/generator]
import mirage/runtime/prelude
import pretty

# create IR generator
let gen = newIRGenerator("clause_callers")

# function "other_clause"
gen.newModule("other_clause")
gen.loadStr(
  0, "This was called from another function!"
)
gen.call("print", @[integer 0])
gen.returnFn(null())

# function "main"
gen.newModule("main")
gen.call("other_clause", @[])
gen.returnFn(null())

# emit IR
let ir = gen.emit()
echo ir

# create interpreter
let interpreter = newPulsarInterpreter(ir)

# analyze bytecode, create clauses
interpreter.analyze()

# set entry point clause to "main" that we created earlier
interpreter.setEntryPoint("main")

# begin execution cycle
interpreter.run()
