import mirage/ir/generator
import mirage/atom
import mirage/runtime/pulsar/interpreter

var gen = newIRGenerator("testing")
gen.newModule("main")
gen.loadStr(0, "Hello world\nhi")
gen.call("print", @[integer 0])

let ir = gen.emit()
echo ir
echo "Creating interpreter with bytecode and executing it."
let interp = newPulsarInterpreter(ir)

interp.analyze()
interp.run()
