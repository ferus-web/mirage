import mirage/[atom, ir/generator]
import mirage/runtime/prelude

# create IR generator
let gen = newIRGenerator("clause_callers")

# function "add_until_beeg"
gen.newModule("add_until_beeg")
gen.readRegister(1, 1, CallArgument) # `value`
gen.readRegister(2, 2, CallArgument) # `beeg`

gen.equate(1, 2)
gen.jump(6)
gen.jump(11)

gen.loadInt(3, 1) # literal 1
gen.addInt(1, 3)
gen.resetArgs()
gen.passArgument(1)
gen.call("add_until_beeg")

gen.returnFn(1)

# function "main"
gen.newModule("main")
gen.loadInt(1, 1) # `value`
gen.loadInt(2, 32) # `beeg`

gen.passArgument(1)
gen.passArgument(2)

gen.call("add_until_beeg")

gen.readRegister(3, ReturnValue)
gen.call("print", @[integer 3])

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
