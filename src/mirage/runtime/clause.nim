import laser/photon_jit

type Clause* = ref object
  name*: string
  stackClosure*: seq[int]
