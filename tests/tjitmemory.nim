import mirage/runtime/pulsar/compiler/executable

var mem = jitAlloc(4096)
markExecutable(mem, 4096)
