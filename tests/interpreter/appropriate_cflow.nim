import mirage/runtime/prelude

let content = readFile("tests/interpreter/002.mir")
echo content

let interp = newPulsarInterpreter(content)
interp.analyze()
interp.setEntryPoint("outer")
interp.run()
