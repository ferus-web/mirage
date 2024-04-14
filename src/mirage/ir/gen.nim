import std/[options, tables, times, strutils]
import ../atom, ./types
import pretty

const
  Version {.strdefine: "NimblePkgVersion".} = "???"

type
  CodeGenerator* = ref object
    register*: TableRef[string, int]
    stack*: seq[MAtom]
    operations*: seq[Operation]
    opts*: IROpts
    clause*: string

proc getReads*(gen: CodeGenerator, index: int): seq[Operation] {.inline.}

proc express*(gen: CodeGenerator, atom: MAtom, name: string, ir: IR): string {.inline.} =
  if atom.kind == Null:
    return

  let
    op = case atom.kind:
      of Integer: "LOADI"
      of String: "LOADS"
      of Sequence: "LOADL"
      of Ref: "LOADR"
      of Null: ""

    crushed = atom.crush(name)

  var idx = if name in gen.register: gen.register[name] else: gen.stack.len - 1

  if name notin gen.register:
    gen.stack.add(atom)

  if name in gen.register and gen.getReads(idx).len < 1:
    ir.warn(
      unusedWarning(
        '"' & name & "\" is never accessed. Initializing it is a waste.",
        name
      )
    )

  op & ' ' & $idx & ' ' & crushed

proc getReads*(gen: CodeGenerator, index: int): seq[Operation] {.inline.} =
  for op in gen.operations:
    if op.kind == okRead and
      op.rname in gen.register and
      gen.register[op.rname] == index:
      result &= op
      continue

    if op.kind == okWrite and 
      op.value.kind == Ref and 
      op.value.reference.isSome and
      op.value.reference.unsafeGet() == index:
      result &= op
      continue

    if op.kind == okCall:
      for arg in op.call.references:
        if arg.reference.isSome and
          arg.reference.unsafeGet() == index:
          result &= op
          continue

proc eliminateDeadCode*(gen: CodeGenerator) {.inline.} =
  var deleted = 0
  proc nuke(i: int) =
    # TODO: rename this (the name sounds funny though)
    gen.operations.delete(i - deleted)
    inc deleted

  for i, op in deepCopy(gen.operations): # this is dumb
    if op.kind == okWrite:
      if op.wname notin gen.register:
        continue

      let index = gen.register[op.wname]
      if gen.getReads(index).len < 1:
        # there's no reads to this index on the stack, feel free to nuke it :)))
        nuke i

proc compute*(gen: CodeGenerator) {.inline.} =
  if gen.opts.deadCodeElimination:
    gen.eliminateDeadCode()

proc generateIR*(gen: CodeGenerator): IR =
  var ir = IR()

  let start = cpuTime()
  var indentation: uint = 0

  proc add(s: string) =
    when not defined(release) or defined(mirageIndentedIR):
      ir.source &= repeat('\t', indentation) & s & '\n'
    else:
      ir.source &= s & '\n'

  proc comment(s: string) =
    when not defined(release) or defined(mirageIndentedIR):
      ir.source &= repeat('\t', indentation) & "# " & s & '\n'
    else:
      ir.source &= s & '\n'

  proc bump(indent: var uint) {.inline.} =
    indent += 2'u

  proc roll(indent: var uint) {.inline.} =
    indent -= 2'u

  for opidx, op in gen.operations:
    case op.kind
    of okRead:
      add "READ " & op.rname
    of okWrite:
      if op.value.kind == Ref and op.value.isWeak():
        #[ let msg = "\"" & op.value.link & "\" is a weak reference and will need to be resolved later."
        comment msg
        ir.warn(
          weakRefWarning(
            msg,
            op.value.link
          )
        ) ]#
        continue
      
      add gen.express(op.value, op.wname, ir)
    of okCall:
      var args: seq[int]
      for i, arg in op.call.arguments:
        add gen.express(arg, "arg_" & $opidx & '_' & $i, ir)
        args.add(gen.stack.len - 2)

      var op = "CALL " & op.call.name & ' '

      for arg in args:
        op &= $arg & ' '
      
      add op
    of okEnter:
      comment "enter clause " & op.enter
      add "CLAUSE " & op.enter
      bump indentation
    of okAdd:
      var ops = "ADD "
      for i, arith in op.arithmetics:
        add gen.express(arith, "arg_" & $opidx & '_' & $i, ir)
        ops &= $(gen.stack.len - 2) & ' '

      add ops & $(gen.stack.len - 1)
      gen.stack.setLen(gen.stack.len + 1) # ensure that nothing writes into the area where the calculated value will be at
    of okExit:
      roll indentation
      add "END " & op.exit
      comment "exit clause " & op.exit & '\n'
    of okMul:
      var ops = "MULT "
      for i, arith in op.arithmetics:
        add gen.express(arith, "arg_ " & $opidx & '_' & $i, ir)
        ops &= $(gen.stack.len - 2) & ' '

      add ops & $(gen.stack.len - 1)
      gen.stack.setLen(gen.stack.len + 1)
    of okSub:
      var ops = "SUB "
      for i, arith in op.arithmetics:
        add gen.express(arith, "arg_" & $opidx & '_' & $i, ir)
        ops &= $(gen.stack.len - 2) & ' '

      add ops & $(gen.stack.len - 1)
      gen.stack.setLen(gen.stack.len + 1)
    of okEquate:
      var ops = "EQUATE "
      for i, eq in op.eqRefs:
        ops &= $eq.reference.get() & ' '

      add ops
    of okLoopConditions:
      add "LOOP_CONDITIONS"
    of okLoopBody:
      add "LOOP_BODY"
    of okLoopEnd:
      add "LOOP_END"
    else:
      discard

  let preamble = "# Mirage version:$1 arch:$2 os:$3 cputime:$4\n" % [
    Version, hostCPU, hostOS, $(cpuTime() - start)
  ]
  
  ir.source = preamble & '\n' & ir.source

  ir

proc write*(gen: CodeGenerator, name: string = "", atom: MAtom, mutable: bool = true) {.inline.} =
  gen.operations.add(
    Operation(
      kind: okWrite,
      wname: name,
      value: atom
    )
  )

  gen.stack.add(atom)

  if name.len > 0:
    gen.register[name] = gen.stack.len - 1

proc add*(gen: CodeGenerator, refs: seq[MAtom]) {.inline.} =
  gen.operations.add(
    Operation(
      kind: okAdd,
      arithmetics: refs,
      newIdx: gen.stack.len - 1
    )
  )

proc sub*(gen: CodeGenerator, refs: seq[MAtom]) {.inline.} =
  gen.operations.add(
    Operation(
      kind: okSub,
      arithmetics: refs,
      newIdx: gen.stack.len - 1
    )
  )

proc mult*(gen: CodeGenerator, refs: seq[MAtom]) {.inline.} =
  gen.operations.add(
    Operation(
      kind: okMul,
      arithmetics: refs,
      newIdx: gen.stack.len - 1
    )
  )

proc reference*(gen: CodeGenerator, name: string, write: bool = true): MAtom {.inline.} =
  if name in gen.register:
    for idx, _ in gen.stack:
      if gen.register[name] == idx:
        let reference = strongRef idx

        if write: gen.write(atom = reference)
        return reference
  
  # Couldn't find in stack - find it later (or throw an error)
  let reference = weakRef name
  if write: gen.write(atom = reference)

  reference

proc call*(gen: CodeGenerator, name: string, args: seq[MAtom] = @[], refs: seq[MAtom] = @[]) {.inline.} =
  for reference in refs:
    if reference.kind != Ref:
      raise newException(ValueError, "Non-Ref MAtom was passed into `refs`! (" & repr(reference) & ')')

  gen.operations.add(
    Operation(
      kind: okCall,
      call: Call(
        name: name,
        arguments: args,
        references: refs
      )
    )
  )

proc equate*(gen: CodeGenerator, refs: seq[string]): Operation {.inline.} =
  var atoms: seq[MAtom]

  for i, reference in refs:
    atoms.add(gen.reference(reference, write = false))

  Operation(
    kind: okEquate,
    eqRefs: atoms
  )

proc loopEnd*(gen: CodeGenerator) {.inline.} =
  gen.operations.add(
    Operation(
      kind: okLoopEnd
    )
  )

proc loop*(gen: CodeGenerator, conditions: seq[Operation]) =
  gen.operations.add(
    Operation(
      kind: okLoopConditions
    )
  )

  for cond in conditions:
    if cond.kind notin [okEquate]:
      raise newException(ValueError, "Attempt to add non-equatory operation as condition for a loop.")

    gen.operations.add(cond)

  gen.operations.add(
    Operation(
      kind: okLoopBody
    )
  )

proc enter*(gen: CodeGenerator, clause: string) {.inline.} =
  gen.operations.add(
    Operation(
      kind: okEnter,
      enter: clause
    )
  )

proc exit*(gen: CodeGenerator, clause: string) {.inline.} =
  gen.operations.add(
    Operation(
      kind: okExit,
      exit: clause
    )
  )

proc newCodeGenerator*: CodeGenerator {.inline.} =
  CodeGenerator(
    register: newTable[string, int](),
    stack: @[],
    operations: @[],
    opts: IROpts()
  )

export types
