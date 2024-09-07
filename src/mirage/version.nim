## Mirage's current version.
## Used by the MIR emitter to append to the IR file.
##
## Copyright (C) 2024 Trayambak Rai

const
  MirageMajorVersion* {.intdefine.} = 0
  MirageMinorVersion* {.intdefine.} = 1
  MirageMicroVersion* {.intdefine.} = 0
  MirageVersionString* =
    $MirageMajorVersion & '.' & $MirageMinorVersion & '.' & $MirageMicroVersion
