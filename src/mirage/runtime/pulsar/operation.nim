## A basic operation object used by the Pulsar interpreter.
##
## Copyright (C) 2024 Trayambak Rai

import std/[options, tables]
import ../shared
import ../../[atom, utils]

when not defined(mirageNoJit):
  import laser/photon_jit

const MirageOperationJitThreshold* {.intdefine.} = 8 # FIXME: set this to something higher
const
  SequenceBasedRegisters* = [
    some(1)
  ]

type
  Clause* = object
    name*: string
    operations*: seq[Operation]

    rollback*: ClauseRollback

    when not defined(mirageNoJit):
      compiled*: Option[JitFunction]

  InvalidRegisterRead* = object of Defect

  ClauseRollback* = object
    clause*: int = int.low
    opIndex*: uint = 1

  Operation* = object
    index*: uint64

    opcode*: Ops
    rawArgs*: seq[Token] # should be zero'd out once `computeArgs` is called

    arguments*: seq[MAtom]
    consumed*: bool = false
    lastConsume: int = 0
    
    when not defined(mirageNoJit) and defined(amd64):
      called*: int ## How many times has this operation been called this clause execution? (used to determine if it should be JIT'd)

proc expand*(operation: Operation): string {.inline.} =
  assert operation.consumed, "Attempt to expand operation that hasn't been consumed. This was most likely caused by a badly initialized exception."
  var expanded = OpCodeToString[operation.opCode]

  for arg in operation.arguments:
    expanded &= ' ' & $arg.crush("")

  expanded

proc shouldCompile*(operation: Operation): bool {.inline, noSideEffect, gcsafe.} =
  operation.called >= MirageOperationJitThreshold

proc consume*(
  operation: var Operation, 
  kind: MAtomKind, expects: string, 
  enforce: bool = true,
  position: Option[int] = none(int)
): MAtom {.inline.} =
  operation.consumed = true

  let
    pos = if *position:
      &position
    else:
      0
    raw = operation.rawArgs[pos]
    rawType = case raw.kind
    of tkQuotedString: String
    of tkInteger: Integer
    else: Null

  if not *position and operation.rawArgs.len > 1:
    operation.rawArgs = deepCopy(operation.rawArgs[1 ..< operation.rawArgs.len])
  
  if rawType != kind and raw.kind != tkIdent and enforce:
    raise newException(ValueError, expects & ", got " & $rawType & " instead.")

  case raw.kind
  of tkQuotedString:
    return str raw.str
  of tkIdent:
    # if it is a boolean, return it as such
    # otherwise, return as a string
    let asBool = boolean(raw.ident)
    
    if *asBool:
      return &asBool
    
    return str raw.ident
  of tkInteger:
    return integer raw.integer
  else: discard

proc resolve*(
  clause: Clause, op: var Operation
) =
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
    op.arguments &=
      op.consume(Integer, "RETURN expects an integer at position 1")
  of SetCapList:
    op.arguments &=
      op.consume(Integer, "SCAPL expects an integer at position 1")   

    op.arguments &=
      op.consume(Integer, "SCAPL expects an integer at position 2")
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
  of Mult3xBatch:
    for i in 1 .. 7:
      op.arguments &=
        op.consume(Integer, "THREEMULT expects an integer at position " & $i)
  of Mult2xBatch:
    for i in 1 .. 5:
      op.arguments &=
        op.consume(Integer, "TWOMULT expects an integer at position " & $i)
  of MarkHomogenous:
    op.arguments &=
      op.consume(Integer, "MARKHOMO expects an integer at position 1")
  of LoadNull:
    op.arguments &=
      op.consume(Integer, "LOADN expects an integer at position 1")
  of MarkGlobal:
    op.arguments &=
      op.consume(Integer, "GLOB expects an integer at position 1")
  of ReadRegister:
    op.arguments &=
      op.consume(Integer, "RREG expects an integer at position 1")

    op.arguments &=
      op.consume(Integer, "RREG expects an integer at position 2")
    
    try:
      op.arguments &=
        op.consume(Integer, "RREG expects an integer at position 3 when accessing a sequence based register")
    except ValueError as exc:
      if op.arguments[1].getInt() in SequenceBasedRegisters:
        raise exc
  of PassArgument:
    op.arguments &=
      op.consume(Integer, "PARG expects an integer at position 1")
  of ResetArgs:
    discard
  
  op.rawArgs = mRawArgs
