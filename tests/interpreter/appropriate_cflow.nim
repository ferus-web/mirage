import mirage/runtime/prelude

let content = readFile("tests/interpreter/001.mir")
echo content

let interp = newPulsarInterpreter(content)
interp.analyze()
interp.setEntryPoint("A")
interp.run()
