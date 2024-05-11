import std/[sequtils]
import ../runtime/shared, ../[atom, utils]
import ./[emitter, shared, caching]

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
        integer position,
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
  value: MAtom
): uint {.inline, discardable.} =
  gen.addOp(
    IROperation(
      opCode: Return,
      arguments: @[value]
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

proc emit*(gen: IRGenerator): string {.inline.} =
  when defined(release):
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

export shared
