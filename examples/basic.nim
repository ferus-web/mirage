import mirage/[atom, ir/gen, runtime/interpreter]
import pretty

var generator = newCodeGenerator()
generator.opts.deadCodeElimination = false

generator.enter("main")

generator.write(
  name = "hello",
  atom = str "hehehehaw",
  mutable = false
)

generator.write(
  name = "thing",
  atom = integer 32,
  mutable = false
)

generator.write(
  name = "very_useful_value",
  atom = integer 1337,
  mutable = false
)

generator.write(
  name = "e",
  atom = str "uwu"
)

generator.call(
  "print",
  args = @[
    str "hello world!"
  ],
  refs = @[]
)

generator.add(
  @[
    generator.reference("very_useful_value"),
    generator.reference("thing")
  ]
)

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
