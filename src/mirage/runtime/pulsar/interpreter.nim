import std/[options]
import ../../[atom, utils]
import ../[shared, tokenizer]
import ./[operation, bytecodeopsetconv]
import ./gc/[arena, cell]
import pretty

type
  Clause* = ref object
    name*: string
    operations*: seq[Operation]

    rollback*: ClauseRollback

  ClauseRollback* = ref object
    prev*: int = int.low
    index*: uint = 1

  PulsarInterpreter* = ref object
    tokenizer: Tokenizer
    currClause: int = -1
    currIndex: uint = 1
    clauses: seq[Clause]

    newestArena*, newArena*, oldArena*: Arena

proc find*(clause: Clause, id: uint): Option[Operation] {.inline.} =
  for op in clause.operations:
    if op.index == id:
      return some op

proc find*(interpreter: PulsarInterpreter, id: uint): Option[Cell] {.inline.} =
  let newest = interpreter.newestArena.find(id)
  if *newest:
    return newest

  let new = interpreter.newArena.find(id)
  if *new:
    return new

  let old = interpreter.oldArena.find(id)
  if *old:
    return old

proc get*(interpreter: PulsarInterpreter, id: uint): Option[MAtom] {.inline.} =
  let cell = interpreter.find(id)

  if *cell:
    return some (&cell).get()

proc getClause*(interpreter: PulsarInterpreter, id: Option[int] = none int): Option[Clause] {.inline.} =
  let id = if *id: &id else: interpreter.currClause
  if id <= interpreter.clauses.len-1 and 
    id > -1:
    some(interpreter.clauses[id])
  else:
    none Clause

proc analyze*(interpreter: PulsarInterpreter) {.inline.} =
  var cTok = interpreter.tokenizer.deepCopy()
  while not interpreter.tokenizer.isEof:
    let 
      clause = interpreter.getClause()
      tok = cTok.maybeNext()

    if *tok and (&tok).kind == tkClause and 
      not *clause:
      if interpreter.currClause > 0:
        inc interpreter.currClause
      else:
        interpreter.currClause += 2

      interpreter.clauses.add(
        Clause(
          name: (&tok).clause,
          operations: @[],
          rollback: ClauseRollback()
        )
      )
      interpreter.tokenizer.pos = cTok.pos
      continue
 
    let op = nextOperation interpreter.tokenizer

    if *clause and *op:
      interpreter.clauses[interpreter.currClause].operations.add(&op)
      cTok.pos = interpreter.tokenizer.pos
      continue

    if *tok and (&tok).kind == tkEnd and
      *clause:
      interpreter.currClause = -1
      interpreter.tokenizer.pos = cTok.pos
      continue

proc addAtom*(interpreter: PulsarInterpreter, atom: MAtom, id: int): Cell {.inline, discardable.} =
  var cell = newCell(atom)
  cell.id = id.uint
  interpreter.newestArena.add(cell)

proc resolve*(
  interpreter: PulsarInterpreter, 
  clause: Clause, op: Operation
) {.inline.} =
  let mRawArgs = deepCopy(op.rawArgs)
  op.arguments.reset()

  case op.opCode
  of LoadStr:
    op.arguments &= 
      op.consume(Integer, "LOADS expects an integer at position 1")

    op.arguments &=
      op.consume(String, "LOADS expects a string at position 2")
  of LoadInt:
    op.arguments &=
      op.consume(Integer, "LOADI expects an integer at position 1")

    op.arguments &=
      op.consume(Integer, "LOADI expects an integer at position 2")
  of Equate:
    for x, _ in op.rawArgs.deepCopy():
      op.arguments &=
        op.consume(Integer, "EQU expects an integer at position " & $x)
  of Call:
    op.arguments &=
      op.consume(String, "CALL expects an ident/string at position 1")
    
    for i, x in deepCopy(op.rawArgs):
      op.arguments &=
        op.consume(Integer, "CALL expects an integer at position " & $i)
  of Jump:
    op.arguments &=
      op.consume(Integer, "JUMP expects exactly one integer as an argument")
  else: discard

  op.rawArgs = mRawArgs

proc execute*(interpreter: PulsarInterpreter, op: Operation) {.inline.} =
  let oclause = interpreter.getClause()
  print oclause

  if *oclause:
    var clause = &oclause

    clause.rollback.prev = interpreter.currIndex.int
    clause.rollback.index = op.index

  case op.opCode
  of LoadStr:
    interpreter.addAtom(
      op.arguments[1],
      &op.arguments[0].getInt()
    )
    inc interpreter.currIndex
  of LoadInt:
    interpreter.addAtom(
      op.arguments[1],
      &op.arguments[0].getInt()
    )
    inc interpreter.currIndex
  of Equate:
    if op.arguments.len < 2:
      inc interpreter.currIndex
      return

    var 
      prev = interpreter.get(uint(&op.arguments[0].getInt()))
      accumulator = false

    for arg in op.arguments[1 ..< op.arguments.len]:
      let value = interpreter.get(uint(&arg.getInt()))

      if not *value:
        break
      
      accumulator = (&value).hash == (&prev).hash
      prev = value
      if not accumulator: break
    
    if accumulator:
      inc interpreter.currIndex
    else:
      interpreter.currIndex += 2
  of Jump:
    let pos = op.arguments[0].getInt()

    if not *pos:
      inc interpreter.currIndex
      return

    interpreter.currIndex = (&pos).uint
  of Return:
    let clause = interpreter.getClause()

    if not *clause:
      inc interpreter.currIndex
      return

    interpreter.currClause = (&clause).rollback.prev
    interpreter.currIndex = (&clause).rollback.index
  of Call:
    if op.arguments[0].getStr() == some "print":
      for i, x in op.arguments:
        if i == 0: continue

        let val = interpreter.get((&x.getInt()).uint)

        if *val:
          echo (&val).crush("", quote = false)

    inc interpreter.currIndex
  else:
    inc interpreter.currIndex

proc run*(interpreter: PulsarInterpreter) =
  while true:
    let clause = interpreter.getClause()

    if not *clause:
      break

    let op = (&clause).find(interpreter.currIndex)
    
    if not *op:
      break

    interpreter.resolve(&clause, &op)
    interpreter.execute(&op)

proc newPulsarInterpreter*(source: string): PulsarInterpreter {.inline.} =
  PulsarInterpreter(
    tokenizer: newTokenizer(source),
    clauses: @[],
    newestArena: Arena(kind: akNewest),
    newArena: Arena(kind: akNew),
    oldArena: Arena(kind: akOld)
  )
