import std/[options]
import ../atom, interpreter_type

proc print*(interpreter: Interpreter, args: seq[MAtom]) =
  for arg in args:
    if arg.kind == Ref:
      let solved = interpreter.resolveRef(arg.reference.get())
      solved
        .crush("")
        .echo()
    else:
      arg
        .crush("")
        .echo()
