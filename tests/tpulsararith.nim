import std/[os, tables, options]
import mirage/atom
import mirage/runtime/pulsar/interpreter

let i = newPulsarInterpreter(readFile(paramStr(1)))

analyze i
i.setEntryPoint("main")
run i
