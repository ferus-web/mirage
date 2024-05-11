import mirage/ir/[generator, dsl]

let includeCoolStuff = true

var generator = newIRGenerator()
var code =
  ir generator:
    main:
      LoadInt 0 0
      LoadStr 1 "This should never happen"

      if [0] == [0]:
        Call print 0
      else:
        Call print 1

if includeCoolStuff:
  code &=
    main:
      LoadStr 2 "Hello world"

      Call print 2

let bytecode = generator.generate(code)
