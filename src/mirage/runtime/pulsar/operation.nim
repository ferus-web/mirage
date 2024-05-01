import ../shared, ./gc/cell
import ../../atom
import pretty

type
  Operation* = ref object
    index*: uint64

    opcode*: Ops
    rawArgs*: seq[Token] # should be zero'd out once `computeArgs` is called

    arguments*: seq[MAtom]

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
