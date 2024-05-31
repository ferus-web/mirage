import mirage/ir/generator
import mirage/atom
import mirage/runtime/pulsar/interpreter

var gen = newIRGenerator("testing")
gen.newModule("main")

# struct "app_info"
gen.loadObject(0)
gen.createField(0, 0, "username")
gen.createField(0, 1, "password")
gen.createField(0, 2, "age")

gen.writeField(0, 0, str "xTrayambak")
gen.writeField(0, 1, str "mypassword")
gen.writeField(0, 2, integer 15)

gen.castStr(0, 1)
gen.call("print", @[integer 1])

let ir = gen.emit()
echo ir
let interp = newPulsarInterpreter(ir)

interp.analyze()
interp.run()
