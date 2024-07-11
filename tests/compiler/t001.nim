import std/[tables, importutils, strutils]
import mirage/runtime/compiler/prelude
import mirage/runtime/pulsar/[operation]
import mirage/atom
import pretty, laser/photon_jit
# requires: benchy
import benchy

let compiler = newCompiler()
let fn = compiler.compile(
  Clause(
    name: "main",
    operations: @[
      Operation(
        index: 0,
        opCode: LoadStr,
        arguments: @[
          uinteger 0,
          str "hello world"
        ]
      ),
    ]
  )
)

timeIt "load \"hello world\" onto `rdi` 100 times for absolutely no reason":
  call fn
