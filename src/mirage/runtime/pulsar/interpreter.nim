## This file contains the "Pulsar" MIR interpreter. It's a redesign of the previous bytecode analyzer (keyword: analyzer, not interpreter)
## into a more modular and efficient form. You shouldn't import this directly, import `mirage/interpreter/prelude` instead.
##
## Copyright (C) 2024 Trayambak Rai

import std/[tables, options]
import ../../[atom, utils]
import ../[shared, tokenizer, exceptions]
import ./[operation, bytecodeopsetconv]
import pretty

type
  Clause* = ref object
    name*: string
    operations*: seq[Operation]

    rollback*: ClauseRollback

  JumpPoint* {.union.} = ref object
    clause*: int
    index*: uint

  ClauseRollback* = ref object
    prev*: int = int.low
    index*: uint = 1

  PulsarInterpreter* = ref object
    tokenizer: Tokenizer
    currClause: int
    currIndex: uint = 1
    clauses: seq[Clause]
    currJumpOnErr: Option[uint]

    stack*: TableRef[uint, MAtom]
    locals*: TableRef[string, uint]
    builtins*: TableRef[string, proc(op: Operation)]
    errors*: seq[RuntimeException]
    halt*: bool = false
    trace: ExceptionTrace

proc find*(clause: Clause, id: uint): Option[Operation] {.inline.} =
  for op in clause.operations:
    if op.index == id:
      return some op

proc get*(interpreter: PulsarInterpreter, id: uint): Option[MAtom] {.inline.} =
  if interpreter.stack.contains(id):
    return some interpreter.stack[id]

proc getClause*(interpreter: PulsarInterpreter, id: Option[int] = none int): Option[Clause] {.inline.} =
  let id = if *id: &id else: interpreter.currClause
  if id <= interpreter.clauses.len-1 and id > -1:
    some(interpreter.clauses[id])
  else:
    none(Clause)

proc getClause*(interpreter: PulsarInterpreter, name: string): Option[Clause] {.inline.} =
  for clause in interpreter.clauses:
    if clause.name == name:
      return clause.some()

proc analyze*(interpreter: PulsarInterpreter) {.inline.} =
  var cTok = interpreter.tokenizer.deepCopy()
  while not interpreter.tokenizer.isEof:
    let 
      clause = interpreter.getClause()
      tok = cTok.maybeNext()

    if *tok and (&tok).kind == tkClause:
      interpreter.clauses.add(
        Clause(
          name: (&tok).clause,
          operations: @[],
          rollback: ClauseRollback()
        )
      )
      interpreter.currClause = interpreter.clauses.len-1
      interpreter.tokenizer.pos = cTok.pos
      continue
    
    let op = nextOperation interpreter.tokenizer

    if *clause and *op:
      interpreter.clauses[interpreter.currClause].operations.add(&op)
      cTok.pos = interpreter.tokenizer.pos
      continue

    if *tok and (&tok).kind == tkEnd and
      *clause:
      interpreter.tokenizer.pos = cTok.pos
      continue

proc addAtom*(interpreter: PulsarInterpreter, atom: MAtom, id: uint) {.inline.} =
  interpreter.stack[id] = atom
  interpreter.locals[interpreter.clauses[interpreter.currClause].name] = id

proc hasBuiltin*(interpreter: PulsarInterpreter, name: string): bool {.inline.} =
  name in interpreter.builtins

proc registerBuiltin*(interpreter: PulsarInterpreter, name: string, builtin: proc(op: Operation)) {.inline.} =
  interpreter.builtins[name] = builtin

proc callBuiltin*(interpreter: PulsarInterpreter, name: string, op: Operation) {.inline.} =
  interpreter.builtins[name](op)

proc throw*(interpreter: PulsarInterpreter, exception: RuntimeException) {.inline.} =
  if *interpreter.currJumpOnErr:
    return
  
  interpreter.errors.add(exception)
  interpreter.halt = true
  
  let clause = interpreter.getClause(exception.clause)

  if *clause:
    let rollback = (&clause).rollback

    var mException = deepCopy(exception)
    mException.operation = rollback.prev.int
    let prevClause = interpreter.getClause(rollback.index.int.some)
    print prevClause

    if not *prevClause:
      print rollback

    mException.clause = (&prevClause).name
    interpreter.throw(mException)

  interpreter.trace = ExceptionTrace(
    prev: if interpreter.trace != nil: 
      interpreter.trace.some()
    else: 
      none(ExceptionTrace),
    clause: interpreter.currClause,
    line: interpreter.currIndex.int,
    exception: exception
  )

proc generateTraceback*(interpreter: PulsarInterpreter): Option[string] {.inline.} =
  var 
    msg = "Traceback (most recent call last)"
    currTrace = interpreter.trace

  if currTrace == nil:
    return

  print interpreter.trace

  while true:
    let clause = interpreter.getClause(currTrace.clause.some)
    assert *clause, "No clause found with ID: " & $currTrace.clause

    print clause

    let operation = (&clause).find(currTrace.line.uint)
    assert *operation, "No operation found in clause " & $currTrace.clause & " with ID: " & $currTrace.line
    
    msg &= 
      "\n\tClause \"" & currTrace.exception.clause & "\", operation " & $currTrace.line & '\n' &
      "\t\t" & (&operation).expand() &
      '\n' & $typeof(currTrace.exception) & ": " & currTrace.exception.message & '\n'
    
    if *currTrace.prev:
      currTrace = &currTrace.prev
    else:
      break

  some(msg)

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
  of LoadInt, LoadUint:
    for x in 1 .. 2:
      op.arguments &=
        op.consume(Integer, OpCodeToString[op.opCode] & " expects an integer at position " & $x)
  of Equate:
    for x, _ in op.rawArgs.deepCopy():
      op.arguments &=
        op.consume(Integer, "EQU expects an integer at position " & $x)
  of GreaterThanInt, LesserThanInt:
    for x in 1 .. 2:
      op.arguments &=
        op.consume(Integer, OpCodeToString[op.opCode] & " expects an integer at position " & $x)
  of Call:
    op.arguments &=
      op.consume(String, "CALL expects an ident/string at position 1")
    
    for i, x in deepCopy(op.rawArgs):
      op.arguments &=
        op.consume(Integer, "CALL expects an integer at position " & $i)
  of Jump:
    op.arguments &=
      op.consume(Integer, "JUMP expects exactly one integer as an argument")
  of AddInt, AddStr, SubInt:
    for x in 1 .. 2:
      op.arguments &=
        op.consume(Integer, OpCodeToString[op.opCode] & " expects an integer at position " & $x)
  of CastStr, CastInt:
    for x in 1 .. 2:
      op.arguments &=
        op.consume(Integer, OpCodeToString[op.opCode] & " expects an integer at position " & $x)
  of LoadList:
    op.arguments &=
      op.consume(Integer, "LOADL expects an integer at position 1")
  of AddList:
    op.arguments &=
      op.consume(Integer, "ADDL expects an integer at position 1")

    op.arguments &=
      op.consume(Integer, "ADDL expects an integer at position 2")
  of LoadBool:
    op.arguments &=
      op.consume(Integer, "LOADB expects an integer at position 1")

    op.arguments &=
      op.consume(Boolean, "LOADB expects a boolean at position 2")
  of Swap:
    for x in 1 .. 2:
      op.arguments &=
        op.consume(Integer, "SWAP expects an integer at position " & $x)
  of Add, Mult, Div, Sub:
    for x in 1 .. 3:
      op.arguments &=
        op.consume(Integer, OpCodeToString[op.opCode] & " expects an integer at position " & $x)
  of Return:
    discard # TODO: implement (xTrayambak)
  of SetCapList:
    op.arguments &=
      op.consume(Integer, "SCAPL expects an integer at position 1")
  of JumpOnError:
    op.arguments &=
      op.consume(Integer, "JMPE expects an integer at position 1")
  of PopList, PopListPrefix:
    for x in 1 .. 2:
      op.arguments &=
        op.consume(Integer, OpCodeToString[op.opCode] & " expects an integer at position " & $x)
  of LoadObject:
    op.arguments &=
      op.consume(Integer, "LOADO expects an integer at position 1")
  of CreateField:
    for x in 1 .. 2:
      op.arguments &=
        op.consume(Integer, "CFIELD expects an integer at position " & $x)

    op.arguments &=
      op.consume(String, "CFIELD expects a string at position 3")
  of FastWriteField:
    for x in 1 .. 2:
      op.arguments &= 
        op.consume(Integer, "FWFIELD expects an integer at position " & $x)
  of WriteField:
    op.arguments &=
      op.consume(Integer, "WFIELD expects an integer at position 1")

    op.arguments &=
      op.consume(String, "WFIELD expects a string at position 2")
  of Increment, Decrement:
    op.arguments &=
      op.consume(Integer, OpCodeToString[op.opCode] & " expects an integer at position 1")
  of CrashInterpreter:
    discard

  op.rawArgs = mRawArgs

proc appendAtom*(interpreter: PulsarInterpreter, src, dest: uint) {.inline.} =
  let 
    a = interpreter.get(src)
    b = interpreter.get(dest)

  if not *a or not *b:
    return

  var 
    satom = &a
    datom = &b
  
  case satom.kind
  of Integer:
    let
      n1 = &satom.getInt()
      n2 = &datom.getInt()
    
    # FIXME: remove this dumb check with something more sensible
    if n1 >= 4611686018427387904 or n2 >= 4611686018427387904:
      return

    var aiAtom = integer n1 + n2

    interpreter.addAtom(
      aiAtom,
      src
    )
  of String:
    let
      n1 = &satom.getStr()
      n2 = &datom.getStr()
    
    var asAtom = str n1 & n2

    interpreter.addAtom(asAtom, src)
  else:
    discard

proc swap*(interpreter: PulsarInterpreter, a, b: int) {.inline.} =
  var
    atomA = interpreter.get(a.uint)
    atomB = interpreter.get(b.uint)

  if not *atomA or not *atomB:
    return

  swap(atomA, atomB)
  interpreter.addAtom(&atomA, a.uint)
  interpreter.addAtom(&atomB, b.uint)

proc execute*(interpreter: PulsarInterpreter, op: Operation) {.inline.} =
  let oclause = interpreter.getClause()

  if *oclause:
    var clause = &oclause

    clause.rollback.prev = interpreter.currClause.int
    clause.rollback.index = op.index

  when not defined(mirageNoJit):
    inc op.called

  case op.opCode
  of LoadStr:
    interpreter.addAtom(
      op.arguments[1],
      (&op.arguments[0].getInt()).uint
    )
    inc interpreter.currIndex
  of LoadInt:
    interpreter.addAtom(
      op.arguments[1],
      (&op.arguments[0].getInt()).uint
    )
    inc interpreter.currIndex
  of AddInt, AddStr:
    interpreter.appendAtom(
      (&op.arguments[0].getInt()).uint,
      (&op.arguments[1].getInt()).uint
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
    if interpreter.hasBuiltin(&op.arguments[0].getStr()):
      interpreter.callBuiltin(&op.arguments[0].getStr(), op)
    else:
      let
        name = &op.arguments[0].getStr()
        resolver = (proc: tuple[index: int, clause: Option[Clause]] {.gcsafe.} =
          for i, cls in interpreter.clauses:
            if cls.name == name:
              return (index: i, clause: some cls)
        )

        (index, clause) = resolver()
      
      if *clause:
        let oldClause = &interpreter.getClause()
        var newClause = &clause

        newClause.rollback.prev = interpreter.currClause
        newClause.rollback.index = interpreter.currIndex

        interpreter.currClause = index
        interpreter.clauses[interpreter.currClause] = newClause
        interpreter.currIndex = 0
      
    inc interpreter.currIndex
  of CastStr:
    let atom = interpreter.get((
      &op.arguments[0].getInt()
    ).uint)
    
    if not *atom:
      inc interpreter.currIndex
      return

    interpreter.addAtom(
      (&atom).toString(),
      (&op.arguments[1].getInt()).uint
    )
    inc interpreter.currIndex
  of CastInt:
    let atom = interpreter.get((
      &op.arguments[0].getInt()
    ).uint)

    if not *atom:
      inc interpreter.currIndex
      return

    interpreter.addAtom(
      (&atom).toInt(),
      (&op.arguments[1].getInt()).uint
    )
    inc interpreter.currIndex
  of LoadUint:
    interpreter.addAtom(
      op.arguments[1],
      (&op.arguments[0].getInt()).uint
    )
    inc interpreter.currIndex
  of LoadList:
    interpreter.addAtom(
      sequence @[],
      (&op.arguments[0].getInt()).uint
    )
    inc interpreter.currIndex
  of AddList:
    let 
      pos = (&op.arguments[0].getInt()).uint
      curr = interpreter.get(pos)
      source = interpreter.get(
        (&op.arguments[1].getInt()).uint
      )
    
    if not *curr or not *source:
      inc interpreter.currIndex
      return

    var list = &curr

    if list.kind != Sequence:
      inc interpreter.currIndex
      return # TODO: type errors

    if *list.cap and list.sequence.len + 1 < &list.cap:
      inc interpreter.currIndex
      return

    list.sequence.add(&source)

    interpreter.stack[pos] = list
    inc interpreter.currIndex
  of PopList:
    let
      pos = (&op.arguments[0].getInt()).uint
      curr = interpreter.get(pos)
    
    if not *curr:
      inc interpreter.currIndex
      return

    var list = &curr

    if list.kind != Sequence or list.sequence.len < 1:
      inc interpreter.currIndex
      return

    let atom = list.sequence.pop()
    interpreter.addAtom(
      atom,
      (&op.arguments[1].getInt()).uint
    )
    interpreter.stack[pos] = list
    inc interpreter.currIndex
  of PopListPrefix:
    let
      pos = (&op.arguments[0].getInt()).uint
      curr = interpreter.get(pos)

    if not *curr:
      inc interpreter.currIndex
      return

    var list = &curr

    if list.kind != Sequence or list.sequence.len < 1:
      inc interpreter.currIndex
      return
    
    let atom = list.sequence[0]
    list.sequence.del(0)

    interpreter.addAtom(
      atom,
      (&op.arguments[1].getInt()).uint
    )
    interpreter.stack[pos] = list
    inc interpreter.currIndex
  of LoadBool:
    interpreter.addAtom(
      op.arguments[1],
      (&op.arguments[0].getInt()).uint
    )
    inc interpreter.currIndex
  of Swap:
    let
      a = &op.arguments[0].getInt()
      b = &op.arguments[1].getInt()
    
    interpreter.swap(a, b)
    inc interpreter.currIndex
  of SubInt:
    let
      aIdx = &op.arguments[0].getInt()
      bIdx = &op.arguments[1].getInt()

      a = interpreter.get(aIdx.uint)
      b = interpreter.get(bIdx.uint)

    if not *a or not *b:
      inc interpreter.currIndex
      return

    let
      aI = (&a).getInt()
      aB = (&b).getInt()

    interpreter.stack[aIdx.uint] = integer(&aI + &aB)
    inc interpreter.currIndex
  of JumpOnError:
    let beforeExecErrors = interpreter.errors.len
    
    interpreter.currJumpOnErr = some(interpreter.currIndex)
    inc interpreter.currIndex
  of GreaterThanInt:
    if op.arguments.len < 2:
      inc interpreter.currIndex
      return

    let
      a = interpreter.get((
        &op.arguments[0].getInt()
      ).uint)
      b = interpreter.get((
        &op.arguments[1].getInt()
      ).uint)

    if not *a or not *b:
      return

    let
      aI = (&a).getInt()
      bI = (&b).getInt()

    if not *aI or not *bI:
      return

    if &aI > &bI:
      inc interpreter.currIndex
    else:
      interpreter.currIndex += 2
  of LesserThanInt:
    if op.arguments.len < 2:
      inc interpreter.currIndex
      return

    let
      a = interpreter.get((
        &op.arguments[0].getInt()
      ).uint)
      b = interpreter.get((
        &op.arguments[1].getInt()
      ).uint)

    if not *a or not *b:
      return

    let
      aI = (&a).getInt()
      bI = (&b).getInt()

    if not *aI or not *bI:
      return

    if &aI < &bI:
      inc interpreter.currIndex
    else:
      interpreter.currIndex += 2
  of LoadObject:
    interpreter.addAtom(
      obj(),
      (&op.arguments[0].getInt()).uint
    )
    inc interpreter.currIndex
  of CreateField:
    let oatomIndex = (
      (&op.arguments[0].getInt()).uint
    )

    let oatomId = interpreter.get(oatomIndex)

    if not *oatomId:
      inc interpreter.currIndex
      return

    var atom = &oatomId
    let
      fieldIndex = (&op.arguments[1].getInt())
      fieldName = &op.arguments[2].getStr()

    atom.fields[fieldName] = fieldIndex
    atom.values.add(null())
    
    interpreter.addAtom(
      atom, oatomIndex
    )

    inc interpreter.currIndex
  of FastWriteField:
    let
      oatomIndex = (&op.arguments[0].getInt()).uint
      oatomId = interpreter.get(oatomIndex)

    if not *oatomId:
      inc interpreter.currIndex
      return

    var atom = &oatomId
    let fieldIndex = (&op.arguments[1].getInt())

    let toWrite = op.consume(Integer, "", enforce = false, some(op.rawArgs.len - 1))
    atom.values[fieldIndex] = toWrite
    
    interpreter.addAtom(atom, oatomIndex)
    inc interpreter.currIndex
  of WriteField:
    let
      oatomIndex = (&op.arguments[0].getInt()).uint
      oatomId = interpreter.get(oatomIndex)

    if not *oatomId:
      inc interpreter.currIndex
      return

    var 
      atom = &oatomId
      fieldIndex = none(int)

    for field, idx in atom.fields:
      if field == &(op.arguments[1].getStr()):
        fieldIndex = some(idx)

    if not *fieldIndex:
      inc interpreter.currIndex
      return
    
    let toWrite = op.consume(Integer, "", enforce = false, some(op.rawArgs.len - 1))
    atom.values[&fieldIndex] = toWrite

    interpreter.addAtom(atom, oatomIndex)
    inc interpreter.currIndex
  of Add:
    let
      a = &interpreter.get((&op.arguments[0].getInt()).uint)
      b = &interpreter.get((&op.arguments[1].getInt()).uint)
      storeIn = (&op.arguments[2].getInt()).uint

    if a.kind != Integer or b.kind != UnsignedInt:
      interpreter.throw(
        wrongType(op.index.int, interpreter.clauses[interpreter.currClause].name, a.kind, Integer)
      )
    
    if b.kind != Integer or b.kind != UnsignedInt:
      interpreter.throw(
        wrongType(op.index.int, interpreter.clauses[interpreter.currClause].name, a.kind, Integer)
      )
    
    # FIXME: properly handle this garbage
    let
      aI = case a.kind
      of Integer:
        &a.getInt()
      else:
        (&a.getUint()).int
      
      bI = case b.kind
      of Integer:
        &b.getInt()
      else: 
        (&b.getUint()).int

    interpreter.addAtom(
      integer(aI + bI),
      storeIn
    )
  of CrashInterpreter:
    when defined(release):
      raise newException(CatchableError, "Encountered `CRASHINTERP` during execution; abort!")
  of Increment:
    let atom = &interpreter.get(
      (&op.arguments[0].getInt()).uint
    )

    case atom.kind
    of Integer:
      interpreter.addAtom(integer(&atom.getInt() + 1), (&op.arguments[0].getInt()).uint)
    of UnsignedInt:
      interpreter.addAtom(uinteger(&atom.getUint() + 1), (&op.arguments[0].getInt()).uint)
    else: discard

    inc interpreter.currIndex
  of Decrement:
    let atom = &interpreter.get(
      (&op.arguments[0].getInt()).uint
    )

    case atom.kind
    of Integer:
      interpreter.addAtom(integer(&atom.getInt() - 1), (&op.arguments[0].getInt()).uint)
    of UnsignedInt:
      interpreter.addAtom(uinteger(&atom.getUint() - 1), (&op.arguments[0].getInt()).uint)
    else: discard

    inc interpreter.currIndex
  else:
    when defined(release):
      inc interpreter.currIndex
    else:
      echo "Unimplemented opcode: " & $op.opCode
      quit(1)

proc setEntryPoint*(interpreter: PulsarInterpreter, name: string) {.inline.} =
  for i, clause in interpreter.clauses:
    if clause.name == name:
      interpreter.currClause = i
      return

  raise newException(
    ValueError,
    "setEntryPoint(): cannot find clause \"" & name & "\""
  )

proc run*(interpreter: PulsarInterpreter) =
  while not interpreter.halt:
    let clause = interpreter.getClause()

    if not *clause:
      break

    let op = (&clause).find(interpreter.currIndex)
    
    if not *op:
      break

    interpreter.resolve(&clause, &op)
    interpreter.execute(&op)

proc newPulsarInterpreter*(source: string): PulsarInterpreter {.inline.} =
  var interp = PulsarInterpreter(
    tokenizer: newTokenizer(source),
    clauses: @[],
    builtins: newTable[string, proc(op: Operation)](),
    locals: newTable[string, uint](),
    stack: newTable[uint, MAtom]()
  )
  interp.registerBuiltin(
    "print", proc(op: Operation) =
      for i, x in op.arguments:
        if i == 0: continue

        let val = interp.get((&x.getInt()).uint)

        if *val:
          echo (&val).crush("", quote = false)
  )

  interp

export Operation
