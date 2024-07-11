type
  InstructionSet* {.pure.} = enum
    x86_64
  
  ABI* {.pure.} = enum
    Linux
    Darwin
    NT

  CodeGenOpts* = object
    enabled*: bool = true
    isa*: InstructionSet
    abi*: ABI

proc `$`*(isa: InstructionSet): string {.inline.} =
  case isa
  of x86_64:
    "amd64"
  else:
    ""

proc autodetectABI*: ABI {.inline.} =
  when defined(linux):
    return Linux

  when defined(macos):
    return Darwin

  when defined(win32) or defined(win64) or defined(windows):
    return NT
