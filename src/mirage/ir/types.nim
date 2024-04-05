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
