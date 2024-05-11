const
  MirageMajorVersion* {.intdefine.} = 0
  MirageMinorVersion* {.intdefine.} = 1
  MirageMicroVersion* {.intdefine.} = 0
  MirageVersionString* = $MirageMajorVersion & '.' & $MirageMinorVersion & '.' & $MirageMicroVersion
