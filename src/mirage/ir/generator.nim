## IR generation utility. Helps with the manipulation of the IRGenerator state
## which can then be used by the MIR emitter to generate MIR.
##
## Copyright (C) 2024 Trayambak Rai

import std/[sequtils]
import ../runtime/shared, ../[atom, utils]
import ./[emitter, shared, caching]
import pretty

template ir*(gen: IRGenerator, body: untyped) =
  let generator {.inject.} = deepCopy gen
  body

proc newModule*(
  gen: IRGenerator, name: string
) {.inline.} =
  when not defined(danger):
    for i, module in gen.modules:
      if module.name == name:
        raise newException(
          ValueError,
          "Attempt to create duplicate module \"" &
          name & "\"; already exists at position " &
          $i
        )
  
  gen.modules.add(
    CodeModule(
      name: name,
      operations: @[]
    )
  )
  gen.currModule = name

proc addOp*(
  gen: IRGenerator,
  operation: IROperation
): uint {.inline.} =
  for i, _ in gen.modules:
    var module = gen.modules[i]
    if module.name == gen.currModule:
      module.operations &= operation
      gen.modules[i] = module
      return module.operations.len.uint

  raise newException(FieldDefect, "Cannot find any clause with name: " & gen.currModule)

proc loadInt*[V: SomeInteger](
  gen: IRGenerator,
  position: uint,
  value: V
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: LoadInt,
      arguments: @[
        uinteger position,
        integer value
      ]
    )
  )

proc loadList*(
  gen: IRGenerator,
  position: uint
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: LoadList,
      arguments: @[
        uinteger position
      ]
    )
  )

proc appendList*(
  gen: IRGenerator,
  dest, source: uint,
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: AddList,
      arguments: @[
        uinteger dest,
        uinteger source
      ]
    )
  )

proc jump*(
  gen: IRGenerator, 
  position: uint
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: Jump,
      arguments: @[
        uinteger position
      ]
    )
  )

proc loadStr*[P: SomeUnsignedInt](
  gen: IRGenerator,
  position: P,
  value: string
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: LoadStr,
      arguments: @[
        uinteger position,
        str value
      ]
    )
  )

proc loadUint*[P: SomeUnsignedInt](
  gen: IRGenerator,
  position, value: P
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: LoadUint,
      arguments: @[
        uinteger position, uinteger value
      ]
    )
  )

proc returnFn*(
  gen: IRGenerator,
  position: int = -1
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: Return,
      arguments: @[integer position]
    )
  )

proc loadBool*(
  gen: IRGenerator,
  position: uint,
  value: bool
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: LoadBool,
      arguments: @[
        uinteger position, 
        boolean value
      ]
    )
  )

proc castStr*(
  gen: IRGenerator,
  src, dest: uint
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: CastStr,
      arguments: @[uinteger src, uinteger dest]
    )
  )

proc castInt*(
  gen: IRGenerator,
  src, dest: uint
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: CastInt,
      arguments: @[uinteger src, uinteger dest]
    )
  )

proc call*(
  gen: IRGenerator,
  function: string,
  arguments: seq[MAtom]
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: Call,
      arguments: @[
        ident function
      ] & arguments
    )
  )

proc loadObject*(
  gen: IRGenerator,
  position: uint
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: LoadObject,
      arguments: @[uinteger position]
    )
  )

proc createField*(
  gen: IRGenerator,
  position: uint,
  index: int,
  name: string
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: CreateField,
      arguments: @[
        uinteger position, 
        integer index,
        str name
      ]
    )
  )

# "slow"
proc writeField*(
  gen: IRGenerator,
  position: uint,
  name: string,
  value: MAtom
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: WriteField,
      arguments: @[
        uinteger position,
        str name,
        value
      ]
    )
  )

# "fast"
proc writeField*(
  gen: IRGenerator,
  position: uint,
  index: int,
  value: MAtom
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: FastWriteField,
      arguments: @[
        uinteger position,
        integer index,
        value
      ]
    )
  )

proc incrementInt*(
  gen: IRGenerator,
  position: uint
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: Increment,
      arguments: @[uinteger position]
    )
  )

proc decrementInt*(
  gen: IRGenerator,
  position: uint
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: Decrement,
      arguments: @[uinteger position]
    )
  )

proc placeholder*(
  gen: IRGenerator,
  opCode: Ops
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: opCode
    )
  )

proc overrideArgs*(
  gen: IRGenerator,
  instruction: uint,
  arguments: seq[MAtom]
) {.inline.} =
  for i, _ in gen.modules:
    var module = gen.modules[i]
    if module.name == gen.currModule:
      module.operations[instruction.int].arguments = arguments
      gen.modules[i] = module
      return

  raise newException(FieldDefect, "Cannot find any clause with name: " & gen.currModule)

proc equate*(
  gen: IRGenerator,
  a, b: uint  
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: Equate,
      arguments: @[uinteger a, uinteger b]
    )
  )

proc addInt*(
  gen: IRGenerator,
  destination, source: uint  
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: AddInt,
      arguments: @[uinteger destination, uinteger source]
    )
  )

proc subInt*(
  gen: IRGenerator,
  destination, source: uint  
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: SubInt,
      arguments: @[uinteger destination, uinteger source]
    )
  )

proc mult2xBatch*(
  gen: IRGenerator,
  vec1, vec2: array[2, uint] # pos to vector
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: Mult2xBatch,
      arguments: @[
        uinteger vec1[0],
        uinteger vec1[1],

        uinteger vec2[0],
        uinteger vec2[1]
      ]
    )
  )

proc emit*(gen: IRGenerator): string {.inline.} =
  let cached = retrieve(gen.name, gen)
  if *cached:
    return &cached

  let ir = gen.emitIR()
  cache(gen.name, ir, gen)

  ir

proc emit*(
  gen: IRGenerator,
  destination: out string
) {.inline.} =
  destination = emit gen

proc emit*(
  gen: IRGenerator,
  destination: File
) {.inline.} =
  destination.write(emit gen)

proc newIRGenerator*(name: string): IRGenerator =
  IRGenerator(
    name: name,
    modules: @[]
  )

export shared, Ops
