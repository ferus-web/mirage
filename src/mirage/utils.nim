## Some basic shared code across all of Mirage.
##
## Copyright (C) Trayambak Rai 2024

import std/options

proc `*`*[T](opt: Option[T]): bool {.inline, noSideEffect, gcsafe.} =
  opt.isSome

proc `&`*[T](opt: Option[T]): T {.inline, noSideEffect, gcsafe.} =
  unsafeGet opt
