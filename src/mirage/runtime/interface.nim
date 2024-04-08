import ../atom

template foreign*(body: untyped) =
  var args {.inject.}: MAtomSeq
  args[0] = str "deine mutter"
  body

foreign:
  let name = args[0]
  echo "my name is: " & crush(name, "")
