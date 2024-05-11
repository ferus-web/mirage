import std/[strutils, times, tables, rdstdin]

import mirage/ir/generator
import mirage/atom
import mirage/runtime/[pulsar/interpreter, shared]

var gen = newIRGenerator("calculator")
var nameToStackIdx = newTable[string, uint]()
var numVals = -1
gen.newModule("main")

proc loadUp: tuple[sIrGen, eIrGen, sInterp, eInterp: float] {.inline.} =
  let startingIrGen = cpuTime()
  
  let ir = gen.emit()

  let endingIrGen = cpuTime()

  var interp = newPulsarInterpreter(ir)

  let startingInterp = cpuTime()
  interp.analyze()
  interp.run()

  let endingInterp = cpuTime()

  (startingIrGen, endingIrGen, startingInterp, endingInterp)

proc evaluate(data: string) =
  var
    terms: seq[int]
    op: Ops

  let 
    vals = data.split ' '
    valName = vals[0]
    o = vals[1]
    value = vals[2]
  
  inc numVals
  nameToStackIdx[valName] = numVals.uint

  gen.loadInt(numVals.uint, value.parseInt())

while true:
  let data = readLineFromStdin(">> ")

  if data == "quit":
    quit(0)

  if data == "load":
    let (sIr, eIr, sInterp, eInterp) = loadUp()

    echo "IR generation took: " & $(eIr - sIr) & " ms"
    echo "Interpretation took: " & $(eInterp - sInterp) & " ms"
  else:
    evaluate(data)
