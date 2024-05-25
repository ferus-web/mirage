## A basic operation object used by the Pulsar interpreter.
##
## Copyright (C) 2024 Trayambak Rai

import std/options
import ../shared
import ../../[atom, utils]
import pretty

when not defined(mirageNoJit) and defined(amd64):
  import laser/photon_jit

when not defined(mirageNoJit) and not defined(amd64):
  {.warning: "-d:mirageNoJit was not supplied on a non-AMD64 platform. The JIT compiler will automatically be disabled. Expect worsened performance.".}

const MirageOperationJitThreshold* {.intdefine.} = 8 # FIXME: set this to something higher

type
  Operation* = ref object
    index*: uint64

    opcode*: Ops
    rawArgs*: seq[Token] # should be zero'd out once `computeArgs` is called

    arguments*: seq[MAtom]
    consumed*: bool = false
    lastConsume: int = 0
    
    when not defined(mirageNoJit) and defined(amd64):
      called*: int ## How many times has this operation been called this clause execution? (used to determine if it should be JIT'd)
      compiled*: JITFunction ## The compiled representation of this operation

proc expand*(operation: Operation): string {.inline.} =
  assert operation.consumed
  var expanded = $operation.opcode

  for arg in operation.arguments:
    expanded &= ' ' & $arg.crush("")

  expanded

proc shouldCompile*(operation: Operation): bool {.inline, noSideEffect, gcsafe.} =
  operation.called >= MirageOperationJitThreshold

proc consume*(
  operation: Operation, 
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
  
  if not *position:
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
