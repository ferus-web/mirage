import std/[options, tables, times, strutils]
import ../atom, ./types

const
  Version {.strdefine: "NimblePkgVersion".} = "???"

type
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

  CodeGenerator* = ref object
    register*: TableRef[string, int]
    stack*: seq[MAtom]
    operations*: seq[Operation]
    opts*: IROpts
    alive*: seq[int]   ## Indexes on the stack that have been accessed atleast once.

    clause*: string

proc getReads*(gen: CodeGenerator, index: int): seq[Operation] {.inline.}

proc express*(gen: CodeGenerator, atom: MAtom, name: string, ir: IR): string {.inline.} =
  let
    op = case atom.kind:
      of Integer: "LOADI"
      of String: "LOADS"
      of Sequence: "LOADL"
      of Ref: "LOADR"

    crushed = atom.crush(name)

    idx = if name in gen.register: gen.register[name] else: gen.stack.len - 1

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

import pretty

proc getReads*(gen: CodeGenerator, index: int): seq[Operation] {.inline.} =
  print gen.operations
  for op in gen.operations:
    if op.kind == okRead and
      op.rname in gen.register and
      gen.register[op.rname] == index:
      echo "guh its a read"
      result &= op
      continue

    echo "not a read"
    print op

    if op.kind == okWrite and 
      op.value.kind == Ref and 
      op.value.reference.isSome and
      op.value.reference.unsafeGet() == index:
      echo "guh its a write"
      result &= op
      continue

    echo "not a write"
    print op

    if op.kind == okCall:
      for arg in op.call.references:
        if arg.reference.isSome and
          arg.reference.unsafeGet() == index:
          echo "guh its a call"
          result &= op
          continue

    echo "not like the other girls"
    print op

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
      print gen.getReads(index)
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

  for op in gen.operations:
    case op.kind
    of okRead:
      add "READ " & op.rname
    of okWrite:
      if op.value.kind == Ref and op.value.isWeak():
        let msg = "\"" & op.value.link & "\" is a weak reference and will need to be resolved later."
        comment msg
        ir.warn(
          weakRefWarning(
            msg,
            op.value.link
          )
        )

      add gen.express(op.value, op.wname, ir)
    of okCall:
      var args: seq[int]
      for i, arg in op.call.arguments:
        add gen.express(arg, "arg_" & $i, ir) # immediate consts values passed are arguments
        args.add(gen.stack.len - 1)

      for i, reference in op.call.references:
        add gen.express(reference, "ref_" & $i, ir)

        if reference.reference.isSome:
          args.add(reference.reference.unsafeGet())
        else:
          args.add(gen.stack.len - 1)
      
      var op = "CALL " & op.call.name & ' '

      for arg in args:
        op &= $arg & ' '
      
      add op
    of okEnter:
      comment "enter clause " & op.enter
      add "CLAUSE " & op.enter
      bump indentation
    of okExit:
      roll indentation
      add "END " & op.exit
      comment "exit clause " & op.exit & '\n'
    of okGetField: discard

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

proc reference*(gen: CodeGenerator, name: string): MAtom {.inline.} =
  if name in gen.register:
    for idx, _ in gen.stack:
      if gen.register[name] == idx:
        let reference = strongRef idx
        gen.write(atom = reference)
        return reference
  
  # Couldn't find in stack - find it later (or throw an error)
  let reference = weakRef name
  gen.write(atom = reference)

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
