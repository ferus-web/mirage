import mirage/[atom, ir/gen, runtime/interpreter]
import pretty

var generator = newCodeGenerator()
generator.opts.deadCodeElimination = false

generator.enter("main")

generator.write("very_useful_value", integer 0)

generator.loop(
  conditions = @[
    generator.equate(@["very_useful_value", "very_useful_value"])
  ]
)

generator.write("hello", str "hi there")

generator.call(
  "print",
  args = @[
    strongRef 0
  ]
)

generator.loopEnd()

generator.exit("main")

# Pass 1: basic optimizations (if enabled)
generator.compute()

# Pass 2: generate IR
let mir = generator.generateIR()

for warn in mir.warnings:
  echo "Warn: " & warn.message

echo mir.source

let interp = newInterpreter(mir.source)
interp.run()

