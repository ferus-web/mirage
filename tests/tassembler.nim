import mirage/compiler/prelude

proc main {.inline.} =
  var comp = newCompiler(Architectures.x86, autodetectABI(fallback = ABI.Linux64))
  
  comp.mov(EAX, 1)
  comp.ret()
