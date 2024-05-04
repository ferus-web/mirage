import mirage/runtime/pulsar/[
  interpreter, operation
]
import mirage/atom

const
  MirageMajorVersion* {.intdefine.} = 0
  MirageMinorVersion* {.intdefine.} = 1
  MirageMicroVersion* {.intdefine.} = 0

export atom, interpreter, operation
