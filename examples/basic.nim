import mirage/[atom, ir/gen]

var generator = newCodeGenerator()
generator.opts.deadCodeElimination = false

generator.enter("main")
#generator.setReturnType("main", Integer)
#generator.setReturnValue("main", integer 0)

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

generator.call(
  "print",
  args = @[
    str "hello world!"
  ],
  refs = @[
    generator.reference("thinge") # doesn't exist lol
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
