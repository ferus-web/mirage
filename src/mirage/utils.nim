import std/options

proc `*`*[T](opt: Option[T]): bool {.inline, noSideEffect, gcsafe.} =
  opt.isSome

proc `&`*[T](opt: Option[T]): T {.inline, noSideEffect, gcsafe.} =
  unsafeGet opt
