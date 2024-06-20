import flatty/binny

when not defined(linux):
  {.error: "The JIT compiler only has safety measures for Linux. Running it on Windows would be unsafe.".}


