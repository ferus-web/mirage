import std/hashes
import ../atom

type
  WarningKind* = enum
    wkUnused   ## Unused values (these are eliminated automatically when dead code elimination is turned on)
    wkWeakRef  ## Weak reference - can't find value on stack (up to the interpreter to decide what to do next)

  Warning* = object
    message*: string
    case kind*: WarningKind
    of wkUnused:
      uname*: string
    of wkWeakRef:
      wref*: string

  IROpts* = ref object
    deadCodeElimination*: bool = false
    unrollLoops*: bool = false

  IR* = ref object
    source*: string
    warnings*: seq[Warning]

  Call* = ref object
    name*: string
    arguments*: seq[MAtom]
    references*: seq[MAtom]

  OpKind* = enum
    okCall
    okRead
    okWrite
    okEnter
    okGetField
    okAdd
    okSub
    okMul
    okDiv
    okExit

  Operation* = ref object
    case kind*: OpKind
    of okCall:
      call*: Call
    of okRead:
      rname*: string
    of okWrite:
      wname*: string
      value*: MAtom
    of okEnter:
      enter*: string
    of okExit:
      exit*: string
    of okGetField:
      field*: string
    of okAdd, okSub, okMul, okDiv:
      arithmetics*: seq[MAtom] ## refs
      newIdx*: int

proc hash*(ir: IR): Hash {.inline.} =
  hash((ir.source, ir.warnings))

proc hash*(op: Operation): Hash {.inline.} =
  case op.kind
  of okCall:
    return hash((op.kind, op.call.name))
  of okRead:
    return hash((op.kind, op.rname))
  of okWrite:
    return hash((op.kind, op.wname))
  of okEnter:
    return hash((op.kind, op.enter))
  of okExit:
    return hash((op.kind, op.exit))
  of okGetField:
    return hash((op.kind, op.field))
  of okAdd, okSub, okMul, okDiv:
    return hash((op.kind, op.newIdx))

proc weakRefWarning*(msg, wref: string): Warning {.inline.} =
  Warning(
    kind: wkWeakRef,
    wref: wref,
    message: msg
  )

proc unusedWarning*(msg, uname: string): Warning {.inline.} =
  Warning(
    kind: wkUnused,
    uname: uname,
    message: msg
  )

proc warn*(ir: IR, warning: Warning) {.inline.} =
  ir.warnings.add(warning)
