import ../shared
import ../../atom
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
    
    when not defined(mirageNoJit) and defined(amd64):
      called*: int ## How many times has this operation been called this clause execution? (used to determine if it should be JIT'd)
      compiled*: JITFunction ## The compiled representation of this operation

proc shouldCompile*(operation: Operation): bool {.inline, noSideEffect, gcsafe.} =
  operation.called >= MirageOperationJitThreshold

proc consume*(operation: Operation, kind: MAtomKind, expects: string): MAtom {.inline.} =
  let 
    raw = operation.rawArgs[0]
    rawType = case raw.kind
    of tkQuotedString, tkIdent: String
    of tkInteger: Integer
    else: Null
  
  operation.rawArgs.del(0)
  
  if rawType != kind:
    raise newException(ValueError, expects & ", got " & $rawType & " instead.")

  case raw.kind
  of tkQuotedString:
    return str raw.str
  of tkIdent:
    return str raw.ident
  of tkInteger:
    return integer raw.integer
  else: discard
