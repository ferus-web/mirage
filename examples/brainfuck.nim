import mirage/ir/generator,
       mirage/runtime/prelude

# incomplete brainfuck -> MIR converter

const brainfuck = """
++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.
"""

let gen = newIRGenerator("brainfuck")
gen.newModule("main")
var
  loadedIndexes, reservedIndexes, jumpPoints: seq[uint]
  index: uint = 2

# reserved mem: zero
gen.loadInt(0, 0)

# reserved mem: one
gen.loadInt(1, 1)

proc incIndex {.inline.} =
  inc index

  if index in reservedIndexes:
    incIndex()

proc decIndex {.inline.} =
  dec index

  if index < 2:
    index = 2

  if index in reservedIndexes:
    decIndex()

proc lastReserve: uint {.inline.} =
  reservedIndexes.pop()

proc reserve(idx: uint) {.inline.} =
  reservedIndexes &= idx

for c in brainfuck:
  case c
  of '+':
    if index notin loadedIndexes:
      loadedIndexes &= index
      gen.loadInt(index, 1)
    else:
      gen.addInt(index, 1)
  of '-':
    if index notin loadedIndexes:
      loadedIndexes &= index
      gen.loadInt(index, 0)
    else:
      gen.subInt(index, 1)
  of '>':
    incIndex()
  of '<':
    decIndex()
  of '[':
    gen.equate(index, 0).reserve()
    gen.returnFn(null())
    jumpPoints &= gen.placeholder(Jump)
  of ']':
    let i = lastReserve()
    let closure = gen.equate(index, 0)
    gen.returnFn(null())
    gen.overrideArgs(
      jumpPoints.pop(),
      @[uinteger closure]
    )
    gen.jump(i)
  else: discard

let ir = gen.emit()
echo ir

let interp = newPulsarInterpreter(ir)
interp.analyze()
interp.run()
